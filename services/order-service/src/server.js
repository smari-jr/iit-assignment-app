const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const promMiddleware = require('express-prometheus-middleware');
require('dotenv').config();

const orderRoutes = require('./routes/orders');
const { sequelize } = require('./models');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 500
});
app.use(limiter);

// Prometheus metrics
app.use(promMiddleware({
  metricsPath: '/metrics',
  collectDefaultMetrics: true
}));

app.use(express.json());

// Health check
app.get('/health', async (req, res) => {
  try {
    await sequelize.authenticate();
    res.status(200).json({
      status: 'healthy',
      service: 'order-service',
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      service: 'order-service',
      database: 'disconnected',
      error: error.message
    });
  }
});

// Routes
app.use('/api/orders', orderRoutes);

// Error handling
app.use((error, req, res, next) => {
  console.error('Order Service Error:', error);
  res.status(error.status || 500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// Database connection and server start
sequelize.sync().then(() => {
  app.listen(PORT, () => {
    console.log(`Order Service running on port ${PORT}`);
  });
}).catch(error => {
  console.error('Database connection failed:', error);
  process.exit(1);
});

module.exports = app;
