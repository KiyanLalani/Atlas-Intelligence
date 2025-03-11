const Content = require('../models/Content');
const { createClient } = require('redis');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Redis client for caching
let redisClient;
if (process.env.REDIS_URL) {
  redisClient = createClient({
    url: process.env.REDIS_URL
  });
  
  redisClient.on('error', (err) => {
    console.error('Redis Client Error:', err);
  });
  
  // Connect to Redis
  (async () => {
    await redisClient.connect();
    console.log('Connected to Redis');
  })();
}

// Initialize Gemini API
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Cache TTL in seconds (24 hours)
const CACHE_TTL = 24 * 60 * 60;

/**
 * Search for content based on parsed query parameters
 * @param {Object} params - The parsed query parameters
 * @param {number} limit - Maximum number of results to return
 * @param {number} page - Page number for pagination
 * @returns {Promise<Array>} - Array of content items
 */
async function searchContent(params, limit = 10, page = 1) {
  try {
    const { examType, examBoard, subject, topic, requestType } = params;
    
    // Create cache key
    const cacheKey = `search:${examType || 'any'}:${examBoard || 'any'}:${subject || 'any'}:${topic || 'any'}:${requestType || 'any'}:${page}:${limit}`;
    
    // Try to get from cache first
    if (redisClient) {
      const cachedResults = await redisClient.get(cacheKey);
      if (cachedResults) {
        return JSON.parse(cachedResults);
      }
    }
    
    // Build query
    const query = {};
    
    if (examType) query.examType = examType;
    if (examBoard) query.examBoard = examBoard;
    if (subject) query.subject = { $regex: new RegExp(subject, 'i') };
    
    // Handle topic search
    if (topic) {
      query.$or = [
        { topics: { $regex: new RegExp(topic, 'i') } },
        { title: { $regex: new RegExp(topic, 'i') } },
        { description: { $regex: new RegExp(topic, 'i') } }
      ];
    }
    
    // Handle request type
    if (requestType && requestType !== 'general') {
      let contentType;
      switch (requestType) {
        case 'notes':
          contentType = 'notes';
          break;
        case 'pastPaper':
          contentType = 'pastPaper';
          break;
        case 'practiceQuestions':
          contentType = 'practiceQuestions';
          break;
        default:
          contentType = null;
      }
      
      if (contentType) {
        query.contentType = contentType;
      }
    }
    
    // Execute query with pagination
    const skip = (page - 1) * limit;
    const results = await Content.find(query)
      .sort({ 'popularity.views': -1 })
      .skip(skip)
      .limit(limit);
    
    // Cache results
    if (redisClient) {
      await redisClient.set(cacheKey, JSON.stringify(results), {
        EX: CACHE_TTL
      });
    }
    
    return results;
  } catch (error) {
    console.error('Error searching content:', error);
    throw error;
  }
}

/**
 * Generate practice questions for a topic using Gemini API
 * @param {Object} params - The parsed query parameters
 * @param {number} count - Number of questions to generate
 * @returns {Promise<Object>} - Generated practice questions
 */
async function generatePracticeQuestions(params, count = 5) {
  try {
    const { examType, examBoard, subject, topic } = params;
    
    // Create cache key
    const cacheKey = `genQuestions:${examType || 'any'}:${examBoard || 'any'}:${subject || 'any'}:${topic || 'any'}:${count}`;
    
    // Try to get from cache first
    if (redisClient) {
      const cachedResults = await redisClient.get(cacheKey);
      if (cachedResults) {
        return JSON.parse(cachedResults);
      }
    }
    
    // Create prompt for Gemini
    const prompt = `
    Generate ${count} practice questions for ${examType || 'GCSE/A-level'} ${subject || 'subject'} 
    ${topic ? `on the topic of ${topic}` : ''} 
    ${examBoard ? `following the ${examBoard} exam board specifications` : ''}.
    
    For each question, provide:
    1. The question text
    2. Four possible answers (for multiple choice)
    3. The correct answer
    4. A detailed explanation of the solution
    
    Format the response as a JSON array of question objects with the following structure:
    [
      {
        "question": "Question text",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correctAnswer": "Correct option",
        "explanation": "Explanation of the solution"
      }
    ]
    `;
    
    // Get the Gemini model
    const model = genAI.getGenerativeModel({ model: "gemini-pro" });
    
    // Generate content
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    // Extract JSON from the response
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      throw new Error('Failed to generate practice questions');
    }
    
    const questions = JSON.parse(jsonMatch[0]);
    
    // Cache results
    if (redisClient) {
      await redisClient.set(cacheKey, JSON.stringify(questions), {
        EX: CACHE_TTL
      });
    }
    
    return questions;
  } catch (error) {
    console.error('Error generating practice questions:', error);
    throw error;
  }
}

/**
 * Get content by ID
 * @param {string} contentId - The content ID
 * @returns {Promise<Object>} - The content object
 */
async function getContentById(contentId) {
  try {
    // Create cache key
    const cacheKey = `content:${contentId}`;
    
    // Try to get from cache first
    if (redisClient) {
      const cachedContent = await redisClient.get(cacheKey);
      if (cachedContent) {
        return JSON.parse(cachedContent);
      }
    }
    
    // Get content from database
    const content = await Content.findById(contentId);
    if (!content) {
      throw new Error('Content not found');
    }
    
    // Increment view count
    content.incrementViews();
    
    // Cache content
    if (redisClient) {
      await redisClient.set(cacheKey, JSON.stringify(content), {
        EX: CACHE_TTL
      });
    }
    
    return content;
  } catch (error) {
    console.error('Error getting content by ID:', error);
    throw error;
  }
}

/**
 * Get popular content
 * @param {number} limit - Maximum number of results to return
 * @returns {Promise<Array>} - Array of popular content items
 */
async function getPopularContent(limit = 10) {
  try {
    // Create cache key
    const cacheKey = `popularContent:${limit}`;
    
    // Try to get from cache first
    if (redisClient) {
      const cachedResults = await redisClient.get(cacheKey);
      if (cachedResults) {
        return JSON.parse(cachedResults);
      }
    }
    
    // Get popular content from database
    const popularContent = await Content.find({})
      .sort({ 'popularity.views': -1 })
      .limit(limit);
    
    // Cache results
    if (redisClient) {
      await redisClient.set(cacheKey, JSON.stringify(popularContent), {
        EX: CACHE_TTL
      });
    }
    
    return popularContent;
  } catch (error) {
    console.error('Error getting popular content:', error);
    throw error;
  }
}

/**
 * Bookmark content for a user
 * @param {string} userId - The user's ID
 * @param {string} contentId - The content ID
 * @returns {Promise<Object>} - Result of the operation
 */
async function bookmarkContent(userId, contentId) {
  try {
    // Get content
    const content = await Content.findById(contentId);
    if (!content) {
      throw new Error('Content not found');
    }
    
    // Increment bookmark count
    await content.incrementBookmarks();
    
    return { success: true };
  } catch (error) {
    console.error('Error bookmarking content:', error);
    throw error;
  }
}

/**
 * Clear cache for a specific key
 * @param {string} key - The cache key to clear
 * @returns {Promise<boolean>} - Whether the operation was successful
 */
async function clearCache(key) {
  try {
    if (redisClient) {
      await redisClient.del(key);
    }
    return true;
  } catch (error) {
    console.error('Error clearing cache:', error);
    return false;
  }
}

module.exports = {
  searchContent,
  generatePracticeQuestions,
  getContentById,
  getPopularContent,
  bookmarkContent,
  clearCache
}; 