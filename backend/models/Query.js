const mongoose = require('mongoose');

const QuerySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  originalQuery: {
    type: String,
    required: true,
    trim: true
  },
  parsedParameters: {
    examType: {
      type: String,
      enum: ['GCSE', 'IGCSE', 'A-level', 'Other', null],
      default: null
    },
    examBoard: {
      type: String,
      enum: ['Edexcel', 'AQA', 'OCR', 'WJEC', 'Cambridge', 'Other', null],
      default: null
    },
    subject: {
      type: String,
      trim: true,
      default: null
    },
    topic: {
      type: String,
      trim: true,
      default: null
    },
    requestType: {
      type: String,
      enum: ['notes', 'pastPaper', 'practiceQuestions', 'general', null],
      default: 'general'
    }
  },
  tokensUsed: {
    type: Number,
    required: true,
    min: 0
  },
  resultCount: {
    type: Number,
    default: 0
  },
  responseTime: {
    type: Number, // in milliseconds
    default: 0
  },
  successful: {
    type: Boolean,
    default: true
  },
  errorMessage: {
    type: String,
    default: null
  },
  contentIds: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Content'
  }],
  userFeedback: {
    rating: {
      type: Number,
      min: 1,
      max: 5,
      default: null
    },
    comment: {
      type: String,
      default: null
    },
    providedAt: {
      type: Date,
      default: null
    }
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for faster lookups
QuerySchema.index({ userId: 1, createdAt: -1 });
QuerySchema.index({ 'parsedParameters.subject': 1, 'parsedParameters.topic': 1 });

// Static method to find similar queries
QuerySchema.statics.findSimilarQueries = function(query, limit = 5) {
  return this.find({
    originalQuery: { $regex: new RegExp(query, 'i') }
  })
  .sort({ createdAt: -1 })
  .limit(limit);
};

// Static method to get popular topics by subject
QuerySchema.statics.getPopularTopicsBySubject = function(subject, limit = 10) {
  return this.aggregate([
    { 
      $match: { 
        'parsedParameters.subject': subject,
        'parsedParameters.topic': { $ne: null }
      } 
    },
    { 
      $group: { 
        _id: '$parsedParameters.topic', 
        count: { $sum: 1 } 
      } 
    },
    { $sort: { count: -1 } },
    { $limit: limit }
  ]);
};

// Static method to get user query statistics
QuerySchema.statics.getUserQueryStats = function(userId) {
  return this.aggregate([
    { $match: { userId: mongoose.Types.ObjectId(userId) } },
    { 
      $group: { 
        _id: null,
        totalQueries: { $sum: 1 },
        totalTokensUsed: { $sum: '$tokensUsed' },
        avgResponseTime: { $avg: '$responseTime' },
        successRate: { 
          $avg: { $cond: [{ $eq: ['$successful', true] }, 1, 0] } 
        }
      } 
    }
  ]);
};

const Query = mongoose.model('Query', QuerySchema);

module.exports = Query; 