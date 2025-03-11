const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const User = require('../models/User');

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
 * @route   GET /api/users/profile
 * @desc    Get user profile
 * @access  Private
 */
router.get('/profile', auth, async (req, res) => {
  try {
    const user = req.user;
    
    // Return user profile
    res.status(200).json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        subscription: user.subscription,
        tokens: user.tokens,
        preferences: user.preferences,
        createdAt: user.createdAt,
        lastActive: user.lastActive
      }
    });
  } catch (error) {
    console.error('Profile retrieval error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during profile retrieval',
      error: error.message
    });
  }
});

/**
 * @route   PUT /api/users/profile
 * @desc    Update user profile
 * @access  Private
 */
router.put('/profile', auth, async (req, res) => {
  try {
    const { name, email } = req.body;
    const user = req.user;
    
    // Update fields
    if (name) user.name = name;
    if (email && email !== user.email) {
      // Check if email is already in use
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ 
          success: false, 
          message: 'Email already in use' 
        });
      }
      user.email = email;
    }
    
    // Save user
    await user.save();
    
    // Return updated profile
    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during profile update',
      error: error.message
    });
  }
});

/**
 * @route   PUT /api/users/password
 * @desc    Update user password
 * @access  Private
 */
router.put('/password', auth, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = req.user;
    
    // Validate input
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide current and new password' 
      });
    }
    
    // Check current password
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(401).json({ 
        success: false, 
        message: 'Current password is incorrect' 
      });
    }
    
    // Update password
    user.password = newPassword;
    
    // Save user
    await user.save();
    
    // Return success
    res.status(200).json({
      success: true,
      message: 'Password updated successfully'
    });
  } catch (error) {
    console.error('Password update error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during password update',
      error: error.message
    });
  }
});

/**
 * @route   PUT /api/users/preferences
 * @desc    Update user preferences
 * @access  Private
 */
router.put('/preferences', auth, async (req, res) => {
  try {
    const { examBoard, examType, subjects, darkMode } = req.body;
    const user = req.user;
    
    // Update preferences
    if (examBoard) user.preferences.examBoard = examBoard;
    if (examType) user.preferences.examType = examType;
    if (subjects) user.preferences.subjects = subjects;
    if (darkMode !== undefined) user.preferences.darkMode = darkMode;
    
    // Save user
    await user.save();
    
    // Return updated preferences
    res.status(200).json({
      success: true,
      message: 'Preferences updated successfully',
      preferences: user.preferences
    });
  } catch (error) {
    console.error('Preferences update error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during preferences update',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/users/stats
 * @desc    Get user statistics
 * @access  Private
 */
router.get('/stats', auth, async (req, res) => {
  try {
    const user = req.user;
    
    // Get query count
    const queryCount = user.queryHistory.length;
    
    // Get total tokens used
    const tokensUsed = user.queryHistory.reduce((total, query) => total + (query.tokensUsed || 0), 0);
    
    // Get bookmark count
    const bookmarkCount = user.bookmarks.length;
    
    // Return stats
    res.status(200).json({
      success: true,
      stats: {
        queryCount,
        tokensUsed,
        bookmarkCount,
        tokensBalance: user.tokens.balance,
        subscriptionType: user.subscription.type,
        daysRemaining: user.subscription.type === 'premium' ? 
          Math.ceil((new Date(user.subscription.endDate) - new Date()) / (1000 * 60 * 60 * 24)) : 
          null
      }
    });
  } catch (error) {
    console.error('Stats retrieval error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during stats retrieval',
      error: error.message
    });
  }
});

/**
 * @route   DELETE /api/users/account
 * @desc    Delete user account
 * @access  Private
 */
router.delete('/account', auth, async (req, res) => {
  try {
    const user = req.user;
    
    // Delete user
    await User.findByIdAndDelete(user._id);
    
    // Return success
    res.status(200).json({
      success: true,
      message: 'Account deleted successfully'
    });
  } catch (error) {
    console.error('Account deletion error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during account deletion',
      error: error.message
    });
  }
});

module.exports = router; 