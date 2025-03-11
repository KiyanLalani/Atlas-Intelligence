const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const UserSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  password: {
    type: String,
    required: true,
    minlength: 8
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  role: {
    type: String,
    enum: ['student', 'teacher', 'admin'],
    default: 'student'
  },
  subscription: {
    type: {
      type: String,
      enum: ['free', 'premium'],
      default: 'free'
    },
    startDate: {
      type: Date,
      default: Date.now
    },
    endDate: {
      type: Date,
      default: function() {
        // Default to 100 years in the future for free tier
        const date = new Date();
        date.setFullYear(date.getFullYear() + 100);
        return date;
      }
    },
    autoRenew: {
      type: Boolean,
      default: false
    },
    paymentId: String
  },
  tokens: {
    balance: {
      type: Number,
      default: 15 // Default free tier tokens
    },
    lastRefreshed: {
      type: Date,
      default: Date.now
    }
  },
  preferences: {
    examBoard: {
      type: String,
      enum: ['Edexcel', 'AQA', 'OCR', 'WJEC', 'Cambridge', 'Other'],
      default: 'Edexcel'
    },
    examType: {
      type: String,
      enum: ['GCSE', 'IGCSE', 'A-level', 'Other'],
      default: 'GCSE'
    },
    subjects: [{
      type: String,
      trim: true
    }],
    darkMode: {
      type: Boolean,
      default: true
    }
  },
  bookmarks: [{
    contentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Content'
    },
    savedAt: {
      type: Date,
      default: Date.now
    }
  }],
  queryHistory: [{
    queryText: String,
    timestamp: {
      type: Date,
      default: Date.now
    },
    tokensUsed: Number
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  lastActive: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Pre-save hook to hash password
UserSchema.pre('save', async function(next) {
  const user = this;
  
  // Only hash the password if it's modified or new
  if (!user.isModified('password')) return next();
  
  try {
    // Generate salt and hash password
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(user.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare password for login
UserSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Method to refresh tokens weekly
UserSchema.methods.refreshTokens = function() {
  const now = new Date();
  const lastRefreshed = new Date(this.tokens.lastRefreshed);
  
  // Check if it's been at least a week since last refresh
  const oneWeek = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds
  if ((now - lastRefreshed) >= oneWeek) {
    // Reset tokens based on subscription type
    this.tokens.balance = this.subscription.type === 'premium' ? 50 : 15;
    this.tokens.lastRefreshed = now;
    return true;
  }
  
  return false;
};

// Method to use tokens
UserSchema.methods.useTokens = function(amount) {
  if (this.tokens.balance >= amount) {
    this.tokens.balance -= amount;
    return true;
  }
  return false;
};

const User = mongoose.model('User', UserSchema);

module.exports = User; 