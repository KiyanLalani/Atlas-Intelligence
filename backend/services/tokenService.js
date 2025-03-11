const User = require('../models/User');
const cron = require('node-cron');

// Token costs for different operations
const TOKEN_COSTS = {
  basicSearch: 1,
  pastPaper: 2,
  practiceQuestions: 3,
  bookmark: 0
};

/**
 * Check if a user has enough tokens for an operation
 * @param {string} userId - The user's ID
 * @param {string} operationType - The type of operation
 * @returns {Promise<boolean>} - Whether the user has enough tokens
 */
async function hasEnoughTokens(userId, operationType) {
  try {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    
    // Refresh tokens if needed
    user.refreshTokens();
    
    // Check if user has enough tokens
    return user.tokens.balance >= TOKEN_COSTS[operationType];
  } catch (error) {
    console.error('Error checking token balance:', error);
    return false;
  }
}

/**
 * Use tokens for an operation
 * @param {string} userId - The user's ID
 * @param {string} operationType - The type of operation
 * @returns {Promise<Object>} - Result of the operation
 */
async function useTokens(userId, operationType) {
  try {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    
    // Refresh tokens if needed
    user.refreshTokens();
    
    // Get token cost
    const cost = TOKEN_COSTS[operationType];
    
    // Check if user has enough tokens
    if (user.tokens.balance < cost) {
      return {
        success: false,
        message: 'Insufficient tokens',
        tokensRequired: cost,
        tokensAvailable: user.tokens.balance
      };
    }
    
    // Use tokens
    user.tokens.balance -= cost;
    await user.save();
    
    return {
      success: true,
      tokensUsed: cost,
      tokensRemaining: user.tokens.balance
    };
  } catch (error) {
    console.error('Error using tokens:', error);
    return {
      success: false,
      message: 'Error processing tokens',
      error: error.message
    };
  }
}

/**
 * Get token cost for an operation
 * @param {string} operationType - The type of operation
 * @returns {number} - The token cost
 */
function getTokenCost(operationType) {
  return TOKEN_COSTS[operationType] || 0;
}

/**
 * Get token cost based on request type
 * @param {string} requestType - The type of request from parsed query
 * @returns {string} - The operation type for token calculation
 */
function getOperationTypeFromRequestType(requestType) {
  switch (requestType) {
    case 'pastPaper':
      return 'pastPaper';
    case 'practiceQuestions':
      return 'practiceQuestions';
    case 'notes':
    case 'general':
    default:
      return 'basicSearch';
  }
}

/**
 * Refresh tokens for all users on a weekly schedule (Sunday at midnight)
 */
function scheduleTokenRefresh() {
  // Schedule to run at midnight on Sunday (0 0 * * 0)
  cron.schedule('0 0 * * 0', async () => {
    try {
      console.log('Running weekly token refresh...');
      
      // Find all users
      const users = await User.find({});
      
      // Update token balances based on subscription type
      for (const user of users) {
        // Reset tokens based on subscription
        user.tokens.balance = user.subscription.type === 'premium' ? 50 : 15;
        user.tokens.lastRefreshed = new Date();
        await user.save();
      }
      
      console.log(`Token refresh completed for ${users.length} users`);
    } catch (error) {
      console.error('Error refreshing tokens:', error);
    }
  });
  
  console.log('Token refresh scheduler initialized');
}

module.exports = {
  hasEnoughTokens,
  useTokens,
  getTokenCost,
  getOperationTypeFromRequestType,
  scheduleTokenRefresh,
  TOKEN_COSTS
}; 