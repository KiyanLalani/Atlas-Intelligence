const mongoose = require('mongoose');

const ContentSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  contentType: {
    type: String,
    enum: ['notes', 'pastPaper', 'practiceQuestions', 'flashcards', 'video', 'other'],
    required: true
  },
  examBoard: {
    type: String,
    enum: ['Edexcel', 'AQA', 'OCR', 'WJEC', 'Cambridge', 'Other'],
    required: true
  },
  examType: {
    type: String,
    enum: ['GCSE', 'IGCSE', 'A-level', 'Other'],
    required: true
  },
  subject: {
    type: String,
    required: true,
    trim: true
  },
  topics: [{
    type: String,
    required: true,
    trim: true
  }],
  difficulty: {
    type: String,
    enum: ['beginner', 'intermediate', 'advanced'],
    default: 'intermediate'
  },
  tokenCost: {
    type: Number,
    required: true,
    min: 0,
    default: 1
  },
  content: {
    text: String,
    fileUrl: String,
    videoUrl: String,
    questions: [{
      question: String,
      options: [String],
      correctAnswer: String,
      explanation: String
    }]
  },
  metadata: {
    year: Number,
    season: {
      type: String,
      enum: ['Spring', 'Summer', 'Autumn', 'Winter', 'N/A'],
      default: 'N/A'
    },
    paperNumber: String,
    duration: Number, // in minutes
    totalMarks: Number
  },
  tags: [{
    type: String,
    trim: true
  }],
  popularity: {
    views: {
      type: Number,
      default: 0
    },
    downloads: {
      type: Number,
      default: 0
    },
    bookmarks: {
      type: Number,
      default: 0
    }
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Create text indexes for search functionality
ContentSchema.index({
  title: 'text',
  description: 'text',
  subject: 'text',
  topics: 'text',
  tags: 'text'
});

// Method to increment view count
ContentSchema.methods.incrementViews = function() {
  this.popularity.views += 1;
  return this.save();
};

// Method to increment download count
ContentSchema.methods.incrementDownloads = function() {
  this.popularity.downloads += 1;
  return this.save();
};

// Method to increment bookmark count
ContentSchema.methods.incrementBookmarks = function() {
  this.popularity.bookmarks += 1;
  return this.save();
};

// Method to decrement bookmark count
ContentSchema.methods.decrementBookmarks = function() {
  if (this.popularity.bookmarks > 0) {
    this.popularity.bookmarks -= 1;
    return this.save();
  }
  return this;
};

// Static method to find content by topic
ContentSchema.statics.findByTopic = function(topic) {
  return this.find({ topics: { $regex: new RegExp(topic, 'i') } });
};

// Static method to find content by exam board and subject
ContentSchema.statics.findByExamBoardAndSubject = function(examBoard, subject) {
  return this.find({ 
    examBoard: examBoard,
    subject: { $regex: new RegExp(subject, 'i') }
  });
};

const Content = mongoose.model('Content', ContentSchema);

module.exports = Content; 