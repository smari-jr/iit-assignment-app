const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const promMiddleware = require('express-prometheus-middleware');
const { createClient } = require('@clickhouse/client');
const { Pool } = require('pg');
require('dotenv').config();

const analyticsRoutes = require('./routes/analytics');

const app = express();
const PORT = process.env.PORT || 3003;

// PostgreSQL connection for primary data storage
const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'lugx_gaming',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres123',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
  ssl: process.env.NODE_ENV === 'production' || (process.env.DB_HOST && (process.env.DB_HOST.includes('rds.amazonaws.com') || process.env.DB_HOST.includes('amazonaws.com'))) ? {
    rejectUnauthorized: false
  } : false
});

// ClickHouse client for analytics data collection
const clickhouseClient = createClient({
  url: `http://${process.env.CLICKHOUSE_HOST || 'clickhouse-service'}:${process.env.CLICKHOUSE_PORT || '8123'}`,
  username: process.env.CLICKHOUSE_USERNAME || 'default',
  password: process.env.CLICKHOUSE_PASSWORD || '',
  database: process.env.CLICKHOUSE_DATABASE || 'analytics',
  request_timeout: 30000,
  clickhouse_settings: {
    async_insert: 1,
    wait_for_async_insert: 0
  }
});

// Security middleware
app.use(helmet());
app.use(cors({
  origin: '*', // Analytics endpoint needs to accept from all origins
  methods: ['GET', 'POST', 'OPTIONS']
}));

// Rate limiting - more lenient for analytics
const limiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 1000 // Allow more requests for analytics
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
    // Test PostgreSQL connection
    const result = await pool.query('SELECT 1 as status');
    
    // Test ClickHouse connection
    let clickhouseStatus = 'connected';
    try {
      await clickhouseClient.ping();
    } catch (clickhouseError) {
      clickhouseStatus = 'disconnected';
      console.warn('ClickHouse connection failed:', clickhouseError.message);
    }
    
    res.status(200).json({
      status: 'healthy',
      database: 'connected',
      clickhouse: clickhouseStatus,
      timestamp: new Date().toISOString(),
      service: 'analytics-service'
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message,
      service: 'analytics-service'
    });
  }
});

// Ready check for Kubernetes
app.get('/ready', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'ready' });
  } catch (error) {
    res.status(503).json({ status: 'not ready', error: error.message });
  }
});

// Routes
app.use('/analytics', analyticsRoutes);
app.use('/api/analytics', analyticsRoutes); // Add support for ALB routing

// Initialize database tables for both PostgreSQL and ClickHouse
const initializeDatabase = async () => {
  try {
    // PostgreSQL: Create analytics schema and tables
    await pool.query('CREATE SCHEMA IF NOT EXISTS analytics');
    
    // Create page_visits table in PostgreSQL
    await pool.query(`
      CREATE TABLE IF NOT EXISTS analytics.page_visits (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        session_id VARCHAR(255) NOT NULL,
        user_id VARCHAR(255),
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        url TEXT NOT NULL,
        path VARCHAR(500) NOT NULL,
        referrer TEXT,
        user_agent TEXT,
        ip_address INET,
        country VARCHAR(100),
        city VARCHAR(100),
        device_type VARCHAR(50),
        browser VARCHAR(100),
        os VARCHAR(100),
        screen_resolution VARCHAR(50),
        duration_seconds INTEGER DEFAULT 0,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      )
    `);

    // Create events table for user actions
    await pool.query(`
      CREATE TABLE IF NOT EXISTS analytics.events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        session_id VARCHAR(255) NOT NULL,
        user_id VARCHAR(255),
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        event_type VARCHAR(100) NOT NULL,
        event_name VARCHAR(200) NOT NULL,
        properties JSONB,
        url TEXT,
        user_agent TEXT,
        ip_address INET,
        country VARCHAR(100),
        city VARCHAR(100),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      )
    `);

    // Create indexes for better performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_page_visits_timestamp 
      ON analytics.page_visits (timestamp DESC)
    `);
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_page_visits_session 
      ON analytics.page_visits (session_id, timestamp DESC)
    `);

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_events_timestamp 
      ON analytics.events (timestamp DESC)
    `);

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_events_type 
      ON analytics.events (event_type, timestamp DESC)
    `);

    console.log('✅ PostgreSQL analytics database tables initialized successfully');

    // ClickHouse: Initialize analytics tables
    try {
      // Create database if it doesn't exist
      await clickhouseClient.exec({
        query: 'CREATE DATABASE IF NOT EXISTS analytics'
      });

      // Create page_visits table in ClickHouse for high-volume analytics
      await clickhouseClient.exec({
        query: `
          CREATE TABLE IF NOT EXISTS analytics.page_visits (
            id UUID DEFAULT generateUUIDv4(),
            session_id String,
            user_id Nullable(String),
            timestamp DateTime64(3) DEFAULT now64(),
            url String,
            path String,
            referrer Nullable(String),
            user_agent Nullable(String),
            ip_address Nullable(IPv4),
            country Nullable(String),
            city Nullable(String),
            device_type Nullable(String),
            browser Nullable(String),
            os Nullable(String),
            screen_resolution Nullable(String),
            duration_seconds Int32 DEFAULT 0,
            created_at DateTime DEFAULT now()
          ) ENGINE = MergeTree()
          ORDER BY (timestamp, session_id)
          PARTITION BY toYYYYMM(timestamp)
          TTL timestamp + INTERVAL 1 YEAR
        `
      });

      // Create events table in ClickHouse
      await clickhouseClient.exec({
        query: `
          CREATE TABLE IF NOT EXISTS analytics.events (
            id UUID DEFAULT generateUUIDv4(),
            session_id String,
            user_id Nullable(String),
            timestamp DateTime64(3) DEFAULT now64(),
            event_type String,
            event_name String,
            properties Nullable(String),
            url Nullable(String),
            user_agent Nullable(String),
            ip_address Nullable(IPv4),
            country Nullable(String),
            city Nullable(String),
            created_at DateTime DEFAULT now()
          ) ENGINE = MergeTree()
          ORDER BY (timestamp, event_type)
          PARTITION BY toYYYYMM(timestamp)
          TTL timestamp + INTERVAL 1 YEAR
        `
      });

      console.log('✅ ClickHouse analytics tables initialized successfully');
    } catch (clickhouseError) {
      console.warn('⚠️ ClickHouse initialization failed, will use PostgreSQL only:', clickhouseError.message);
    }

  } catch (error) {
    console.error('❌ Failed to initialize analytics database:', error);
  }
};

// Initialize database on startup
initializeDatabase();

// Make pool and clickhouse client available to routes
app.set('db', pool);
app.set('clickhouse', clickhouseClient);

// Error handling
app.use((error, req, res, next) => {
  console.error('Analytics Service Error:', error);
  res.status(error.status || 500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

app.listen(PORT, () => {
  console.log(`Analytics Service running on port ${PORT}`);
});

module.exports = app;
