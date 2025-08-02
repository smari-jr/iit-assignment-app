const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const promMiddleware = require('express-prometheus-middleware');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const productsRoutes = require('./routes/products');
const usersRoutes = require('./routes/users');
const { sequelize } = require('./models');

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet());
app.use(cors());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000 // Higher limit for gaming service
});
app.use(limiter);

// Prometheus metrics
app.use(promMiddleware({
  metricsPath: '/metrics',
  collectDefaultMetrics: true
}));

app.use(express.json());
app.use(express.static('public')); // For serving game images

// Health check
app.get('/health', async (req, res) => {
  try {
    await sequelize.authenticate();
    res.status(200).json({
      status: 'healthy',
      service: 'gaming-service',
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      service: 'gaming-service',
      database: 'disconnected',
      error: error.message
    });
  }
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productsRoutes);
app.use('/api/users', usersRoutes);

// Error handling
app.use((error, req, res, next) => {
  console.error('Gaming Service Error:', error);
  res.status(error.status || 500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// Database connection and server start
sequelize.sync().then(() => {
  app.listen(PORT, () => {
    console.log(`Gaming Service running on port ${PORT}`);
  });
}).catch(error => {
  console.error('Database connection failed:', error);
  process.exit(1);
});

module.exports = app;
