require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const winston = require('winston');

// Import routes
// Commented out for now as they require MongoDB
// const authRoutes = require('./api/auth');
// const userRoutes = require('./api/users');
// const contentRoutes = require('./api/content');
// const queryRoutes = require('./api/queries');
// const subscriptionRoutes = require('./api/subscriptions');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 5000;

// Logger configuration
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS
app.use(express.json()); // Parse JSON bodies
app.use(morgan('combined')); // HTTP request logger

// Rate limiting
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many requests from this IP, please try again after 15 minutes'
});
app.use('/api', apiLimiter);

// Routes
// Commented out for now as they require MongoDB
// app.use('/api/auth', authRoutes);
// app.use('/api/users', userRoutes);
// app.use('/api/content', contentRoutes);
// app.use('/api/queries', queryRoutes);
// app.use('/api/subscriptions', subscriptionRoutes);

// Add a simple test route
app.get('/api/test', (req, res) => {
  res.status(200).json({ 
    success: true, 
    message: 'Atlas Intelligence API is running',
    note: 'MongoDB connection is disabled for testing purposes'
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Server is running' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error(`${err.status || 500} - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
  
  res.status(err.status || 500).json({
    error: {
      message: err.message || 'Internal Server Error',
      status: err.status || 500
    }
  });
});

// Start the server without MongoDB
app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT} (MongoDB connection disabled)`);
  logger.info(`Test the API at http://localhost:${PORT}/api/test`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

module.exports = app; // For testing purposes 