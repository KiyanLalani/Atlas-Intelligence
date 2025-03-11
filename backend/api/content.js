const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Content = require('../models/Content');
const { getContentById, getPopularContent, bookmarkContent } = require('../services/contentService');
const { useTokens } = require('../services/tokenService');

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
 * @route   GET /api/content/:id
 * @desc    Get content by ID
 * @access  Private
 */
router.get('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const user = req.user;
    
    // Get content
    const content = await getContentById(id);
    
    // Return content
    res.status(200).json({
      success: true,
      content
    });
  } catch (error) {
    console.error('Content retrieval error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during content retrieval',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/content/popular
 * @desc    Get popular content
 * @access  Private
 */
router.get('/popular', auth, async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    
    // Get popular content
    const popularContent = await getPopularContent(parseInt(limit));
    
    // Return content
    res.status(200).json({
      success: true,
      content: popularContent
    });
  } catch (error) {
    console.error('Popular content retrieval error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during popular content retrieval',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/content/:id/bookmark
 * @desc    Bookmark content
 * @access  Private
 */
router.post('/:id/bookmark', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const user = req.user;
    
    // Check if content exists
    const content = await Content.findById(id);
    if (!content) {
      return res.status(404).json({ 
        success: false, 
        message: 'Content not found' 
      });
    }
    
    // Check if already bookmarked
    const alreadyBookmarked = user.bookmarks.some(bookmark => 
      bookmark.contentId.toString() === id
    );
    
    if (alreadyBookmarked) {
      return res.status(400).json({ 
        success: false, 
        message: 'Content already bookmarked' 
      });
    }
    
    // Add bookmark
    user.bookmarks.push({
      contentId: id,
      savedAt: Date.now()
    });
    await user.save();
    
    // Update content bookmark count
    await bookmarkContent(user._id, id);
    
    // Return success
    res.status(200).json({
      success: true,
      message: 'Content bookmarked successfully'
    });
  } catch (error) {
    console.error('Bookmark error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during bookmarking',
      error: error.message
    });
  }
});

/**
 * @route   DELETE /api/content/:id/bookmark
 * @desc    Remove bookmark
 * @access  Private
 */
router.delete('/:id/bookmark', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const user = req.user;
    
    // Check if bookmarked
    const bookmarkIndex = user.bookmarks.findIndex(bookmark => 
      bookmark.contentId.toString() === id
    );
    
    if (bookmarkIndex === -1) {
      return res.status(400).json({ 
        success: false, 
        message: 'Content not bookmarked' 
      });
    }
    
    // Remove bookmark
    user.bookmarks.splice(bookmarkIndex, 1);
    await user.save();
    
    // Update content bookmark count
    const content = await Content.findById(id);
    if (content) {
      await content.decrementBookmarks();
    }
    
    // Return success
    res.status(200).json({
      success: true,
      message: 'Bookmark removed successfully'
    });
  } catch (error) {
    console.error('Bookmark removal error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during bookmark removal',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/content/bookmarks
 * @desc    Get user's bookmarked content
 * @access  Private
 */
router.get('/bookmarks', auth, async (req, res) => {
  try {
    const user = req.user;
    
    // Get bookmarks with populated content
    const populatedUser = await User.findById(user._id).populate({
      path: 'bookmarks.contentId',
      model: 'Content'
    });
    
    // Extract bookmarks
    const bookmarks = populatedUser.bookmarks.map(bookmark => ({
      savedAt: bookmark.savedAt,
      content: bookmark.contentId
    }));
    
    // Return bookmarks
    res.status(200).json({
      success: true,
      bookmarks
    });
  } catch (error) {
    console.error('Bookmarks retrieval error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during bookmarks retrieval',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/content/filter
 * @desc    Filter content by parameters
 * @access  Private
 */
router.get('/filter', auth, async (req, res) => {
  try {
    const { 
      examType, 
      examBoard, 
      subject, 
      contentType,
      limit = 10,
      page = 1
    } = req.query;
    
    // Build query
    const query = {};
    if (examType) query.examType = examType;
    if (examBoard) query.examBoard = examBoard;
    if (subject) query.subject = { $regex: new RegExp(subject, 'i') };
    if (contentType) query.contentType = contentType;
    
    // Execute query with pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const content = await Content.find(query)
      .sort({ 'popularity.views': -1 })
      .skip(skip)
      .limit(parseInt(limit));
    
    // Get total count
    const total = await Content.countDocuments(query);
    
    // Return content
    res.status(200).json({
      success: true,
      content,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Content filtering error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during content filtering',
      error: error.message
    });
  }
});

module.exports = router; 