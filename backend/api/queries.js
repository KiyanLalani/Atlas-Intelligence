const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Query = require('../models/Query');
const { parseQuery, enhanceWithUserPreferences } = require('../services/queryParser');
const { searchContent, generatePracticeQuestions } = require('../services/contentService');
const { useTokens, getOperationTypeFromRequestType } = require('../services/tokenService');

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'atlas-ai-secret';

// Middleware to authenticate user
const auth = async (req, res, next) => {
  try {
    // Get token from header
    const token = req.header('x-auth-token');
    if (!token) {
      return res.status(401).json({ 
        success: false, 
        message: 'No token, authorization denied' 
      });
    }
    
    // Verify token
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Find user by ID
    const user = await User.findById(decoded.id);
    if (!user) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }
    
    // Add user to request
    req.user = user;
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid token' 
      });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        success: false, 
        message: 'Token expired' 
      });
    }
    res.status(500).json({ 
      success: false, 
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * @route   POST /api/queries/search
 * @desc    Process a natural language query and return search results
 * @access  Private
 */
router.post('/search', auth, async (req, res) => {
  try {
    const { query } = req.body;
    const user = req.user;
    
    // Validate input
    if (!query) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide a query' 
      });
    }
    
    // Start timer for response time tracking
    const startTime = Date.now();
    
    // Parse query
    const parsedQuery = await parseQuery(query);
    
    // Enhance with user preferences
    const enhancedQuery = enhanceWithUserPreferences(parsedQuery, user.preferences);
    
    // Determine operation type for token calculation
    const operationType = getOperationTypeFromRequestType(enhancedQuery.requestType);
    
    // Use tokens
    const tokenResult = await useTokens(user._id, operationType);
    if (!tokenResult.success) {
      return res.status(403).json({
        success: false,
        message: tokenResult.message,
        tokensRequired: tokenResult.tokensRequired,
        tokensAvailable: tokenResult.tokensAvailable
      });
    }
    
    // Search for content
    const searchResults = await searchContent(enhancedQuery);
    
    // Calculate response time
    const responseTime = Date.now() - startTime;
    
    // Create query record
    const queryRecord = new Query({
      userId: user._id,
      originalQuery: query,
      parsedParameters: enhancedQuery,
      tokensUsed: tokenResult.tokensUsed,
      resultCount: searchResults.length,
      responseTime,
      contentIds: searchResults.map(result => result._id)
    });
    
    // Save query record
    await queryRecord.save();
    
    // Add query to user's history
    user.queryHistory.push({
      queryText: query,
      timestamp: Date.now(),
      tokensUsed: tokenResult.tokensUsed
    });
    await user.save();
    
    // Return results
    res.status(200).json({
      success: true,
      message: 'Query processed successfully',
      parsedQuery: enhancedQuery,
      results: searchResults,
      tokensUsed: tokenResult.tokensUsed,
      tokensRemaining: tokenResult.tokensRemaining
    });
  } catch (error) {
    console.error('Query processing error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during query processing',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/queries/generate-questions
 * @desc    Generate practice questions based on a query
 * @access  Private
 */
router.post('/generate-questions', auth, async (req, res) => {
  try {
    const { query, count = 5 } = req.body;
    const user = req.user;
    
    // Validate input
    if (!query) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide a query' 
      });
    }
    
    // Start timer for response time tracking
    const startTime = Date.now();
    
    // Parse query
    const parsedQuery = await parseQuery(query);
    
    // Enhance with user preferences
    const enhancedQuery = enhanceWithUserPreferences(parsedQuery, user.preferences);
    
    // Use tokens for practice questions
    const tokenResult = await useTokens(user._id, 'practiceQuestions');
    if (!tokenResult.success) {
      return res.status(403).json({
        success: false,
        message: tokenResult.message,
        tokensRequired: tokenResult.tokensRequired,
        tokensAvailable: tokenResult.tokensAvailable
      });
    }
    
    // Generate practice questions
    const questions = await generatePracticeQuestions(enhancedQuery, count);
    
    // Calculate response time
    const responseTime = Date.now() - startTime;
    
    // Create query record
    const queryRecord = new Query({
      userId: user._id,
      originalQuery: query,
      parsedParameters: enhancedQuery,
      tokensUsed: tokenResult.tokensUsed,
      resultCount: questions.length,
      responseTime
    });
    
    // Save query record
    await queryRecord.save();
    
    // Add query to user's history
    user.queryHistory.push({
      queryText: query,
      timestamp: Date.now(),
      tokensUsed: tokenResult.tokensUsed
    });
    await user.save();
    
    // Return results
    res.status(200).json({
      success: true,
      message: 'Practice questions generated successfully',
      parsedQuery: enhancedQuery,
      questions,
      tokensUsed: tokenResult.tokensUsed,
      tokensRemaining: tokenResult.tokensRemaining
    });
  } catch (error) {
    console.error('Question generation error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during question generation',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/queries/history
 * @desc    Get user's query history
 * @access  Private
 */
router.get('/history', auth, async (req, res) => {
  try {
    const { limit = 10, page = 1 } = req.query;
    const user = req.user;
    
    // Get query history
    const skip = (page - 1) * limit;
    const queries = await Query.find({ userId: user._id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    
    // Get total count
    const total = await Query.countDocuments({ userId: user._id });
    
    // Return results
    res.status(200).json({
      success: true,
      queries,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Query history error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error while fetching query history',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/queries/feedback
 * @desc    Submit feedback for a query
 * @access  Private
 */
router.post('/feedback', auth, async (req, res) => {
  try {
    const { queryId, rating, comment } = req.body;
    const user = req.user;
    
    // Validate input
    if (!queryId || !rating) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide queryId and rating' 
      });
    }
    
    // Find query
    const query = await Query.findById(queryId);
    if (!query) {
      return res.status(404).json({ 
        success: false, 
        message: 'Query not found' 
      });
    }
    
    // Check if query belongs to user
    if (query.userId.toString() !== user._id.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Unauthorized to provide feedback for this query' 
      });
    }
    
    // Update feedback
    query.userFeedback = {
      rating,
      comment: comment || null,
      providedAt: Date.now()
    };
    
    // Save query
    await query.save();
    
    // Return success
    res.status(200).json({
      success: true,
      message: 'Feedback submitted successfully'
    });
  } catch (error) {
    console.error('Feedback submission error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during feedback submission',
      error: error.message
    });
  }
});

module.exports = router; 