const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
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
 * @route   GET /api/subscriptions/status
 * @desc    Get user's subscription status
 * @access  Private
 */
router.get('/status', auth, async (req, res) => {
  try {
    const user = req.user;
    
    // Return subscription status
    res.status(200).json({
      success: true,
      subscription: {
        type: user.subscription.type,
        startDate: user.subscription.startDate,
        endDate: user.subscription.endDate,
        autoRenew: user.subscription.autoRenew
      },
      tokens: {
        balance: user.tokens.balance,
        lastRefreshed: user.tokens.lastRefreshed
      }
    });
  } catch (error) {
    console.error('Subscription status error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error while fetching subscription status',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/subscriptions/upgrade
 * @desc    Upgrade to premium subscription
 * @access  Private
 */
router.post('/upgrade', auth, async (req, res) => {
  try {
    const { paymentId } = req.body;
    const user = req.user;
    
    // Validate input
    if (!paymentId) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide payment information' 
      });
    }
    
    // Check if already premium
    if (user.subscription.type === 'premium') {
      return res.status(400).json({ 
        success: false, 
        message: 'User already has a premium subscription' 
      });
    }
    
    // Update subscription
    const now = new Date();
    const oneMonth = new Date();
    oneMonth.setMonth(oneMonth.getMonth() + 1);
    
    user.subscription = {
      type: 'premium',
      startDate: now,
      endDate: oneMonth,
      autoRenew: true,
      paymentId
    };
    
    // Update tokens
    user.tokens.balance = 50; // Premium tier tokens
    user.tokens.lastRefreshed = now;
    
    // Save user
    await user.save();
    
    // Return success
    res.status(200).json({
      success: true,
      message: 'Subscription upgraded to premium',
      subscription: {
        type: user.subscription.type,
        startDate: user.subscription.startDate,
        endDate: user.subscription.endDate,
        autoRenew: user.subscription.autoRenew
      },
      tokens: {
        balance: user.tokens.balance,
        lastRefreshed: user.tokens.lastRefreshed
      }
    });
  } catch (error) {
    console.error('Subscription upgrade error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during subscription upgrade',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/subscriptions/cancel
 * @desc    Cancel premium subscription
 * @access  Private
 */
router.post('/cancel', auth, async (req, res) => {
  try {
    const user = req.user;
    
    // Check if premium
    if (user.subscription.type !== 'premium') {
      return res.status(400).json({ 
        success: false, 
        message: 'User does not have a premium subscription' 
      });
    }
    
    // Update subscription
    user.subscription.autoRenew = false;
    
    // Save user
    await user.save();
    
    // Return success
    res.status(200).json({
      success: true,
      message: 'Subscription auto-renewal cancelled',
      subscription: {
        type: user.subscription.type,
        startDate: user.subscription.startDate,
        endDate: user.subscription.endDate,
        autoRenew: user.subscription.autoRenew
      }
    });
  } catch (error) {
    console.error('Subscription cancellation error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during subscription cancellation',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/subscriptions/renew
 * @desc    Renew premium subscription
 * @access  Private
 */
router.post('/renew', auth, async (req, res) => {
  try {
    const { paymentId } = req.body;
    const user = req.user;
    
    // Validate input
    if (!paymentId) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide payment information' 
      });
    }
    
    // Check if subscription expired
    const now = new Date();
    if (user.subscription.type === 'premium' && new Date(user.subscription.endDate) > now) {
      return res.status(400).json({ 
        success: false, 
        message: 'Subscription is still active' 
      });
    }
    
    // Update subscription
    const oneMonth = new Date();
    oneMonth.setMonth(oneMonth.getMonth() + 1);
    
    user.subscription = {
      type: 'premium',
      startDate: now,
      endDate: oneMonth,
      autoRenew: true,
      paymentId
    };
    
    // Save user
    await user.save();
    
    // Return success
    res.status(200).json({
      success: true,
      message: 'Subscription renewed',
      subscription: {
        type: user.subscription.type,
        startDate: user.subscription.startDate,
        endDate: user.subscription.endDate,
        autoRenew: user.subscription.autoRenew
      }
    });
  } catch (error) {
    console.error('Subscription renewal error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during subscription renewal',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/subscriptions/toggle-auto-renew
 * @desc    Toggle auto-renewal for premium subscription
 * @access  Private
 */
router.post('/toggle-auto-renew', auth, async (req, res) => {
  try {
    const user = req.user;
    
    // Check if premium
    if (user.subscription.type !== 'premium') {
      return res.status(400).json({ 
        success: false, 
        message: 'User does not have a premium subscription' 
      });
    }
    
    // Toggle auto-renewal
    user.subscription.autoRenew = !user.subscription.autoRenew;
    
    // Save user
    await user.save();
    
    // Return success
    res.status(200).json({
      success: true,
      message: `Auto-renewal ${user.subscription.autoRenew ? 'enabled' : 'disabled'}`,
      subscription: {
        type: user.subscription.type,
        startDate: user.subscription.startDate,
        endDate: user.subscription.endDate,
        autoRenew: user.subscription.autoRenew
      }
    });
  } catch (error) {
    console.error('Auto-renewal toggle error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error during auto-renewal toggle',
      error: error.message
    });
  }
});

module.exports = router; 