const { createClient } = require('@clickhouse/client');

const clickhouseClient = createClient({
  host: process.env.CLICKHOUSE_HOST || 'http://clickhouse:8123',
  username: process.env.CLICKHOUSE_USER || 'default',
  password: process.env.CLICKHOUSE_PASSWORD || '',
  database: process.env.CLICKHOUSE_DB || 'lugx_analytics',
  clickhouse_settings: {
    async_insert: 1,
    wait_for_async_insert: 0
  }
});

// Initialize analytics tables
const initializeTables = async () => {
  try {
    // Create database if not exists
    await clickhouseClient.exec({
      query: `CREATE DATABASE IF NOT EXISTS ${process.env.CLICKHOUSE_DB || 'lugx_analytics'}`
    });

    // Page views table
    await clickhouseClient.exec({
      query: `
        CREATE TABLE IF NOT EXISTS page_views (
          id String,
          session_id String,
          user_id String,
          timestamp DateTime64(3),
          url String,
          path String,
          referrer String,
          user_agent String,
          ip String,
          country String,
          city String,
          device_type String,
          browser String,
          os String,
          screen_resolution String,
          duration UInt32,
          date Date MATERIALIZED toDate(timestamp)
        ) ENGINE = MergeTree()
        PARTITION BY toYYYYMM(timestamp)
        ORDER BY (timestamp, session_id)
        TTL timestamp + INTERVAL 2 YEAR
      `
    });

    // Events table
    await clickhouseClient.exec({
      query: `
        CREATE TABLE IF NOT EXISTS events (
          id String,
          session_id String,
          user_id String,
          timestamp DateTime64(3),
          event_type String,
          event_name String,
          properties String,
          url String,
          user_agent String,
          ip String,
          country String,
          city String,
          date Date MATERIALIZED toDate(timestamp)
        ) ENGINE = MergeTree()
        PARTITION BY toYYYYMM(timestamp)
        ORDER BY (timestamp, session_id, event_type)
        TTL timestamp + INTERVAL 2 YEAR
      `
    });

    // E-commerce events table
    await clickhouseClient.exec({
      query: `
        CREATE TABLE IF NOT EXISTS ecommerce_events (
          id String,
          session_id String,
          user_id String,
          timestamp DateTime64(3),
          event_type Enum('product_view', 'add_to_cart', 'remove_from_cart', 'purchase', 'checkout_start'),
          product_id String,
          product_name String,
          product_category String,
          product_price Float64,
          quantity UInt32,
          total_value Float64,
          currency String DEFAULT 'USD',
          date Date MATERIALIZED toDate(timestamp)
        ) ENGINE = MergeTree()
        PARTITION BY toYYYYMM(timestamp)
        ORDER BY (timestamp, session_id, event_type)
        TTL timestamp + INTERVAL 2 YEAR
      `
    });

    console.log('ClickHouse tables initialized successfully');
  } catch (error) {
    console.error('Failed to initialize ClickHouse tables:', error);
  }
};

// Initialize tables on startup
initializeTables();

module.exports = clickhouseClient;
