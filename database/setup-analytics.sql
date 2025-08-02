-- Database Setup Script for Microservices Analytics Platform
-- This script creates all necessary databases, schemas, and tables
-- Run this script to set up the complete analytics infrastructure

-- ==============================
-- POSTGRESQL SETUP
-- ==============================

-- Create main application database (if not exists)
CREATE DATABASE IF NOT EXISTS lugx_gaming;

-- Switch to the main database
\c lugx_gaming;

-- Create analytics schema
CREATE SCHEMA IF NOT EXISTS analytics;

-- ==============================
-- ANALYTICS TABLES
-- ==============================

-- Page Visits Tracking Table
CREATE TABLE IF NOT EXISTS analytics.page_visits (
    id VARCHAR(255) PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    url TEXT NOT NULL,
    path VARCHAR(500),
    referrer TEXT,
    title VARCHAR(500),
    user_agent TEXT,
    ip_address INET,
    country VARCHAR(100),
    city VARCHAR(100),
    device_type VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    screen_resolution VARCHAR(50),
    duration_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Click Events Tracking Table  
CREATE TABLE IF NOT EXISTS analytics.click_events (
    id VARCHAR(255) PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    element_type VARCHAR(100) NOT NULL,
    element_id VARCHAR(255),
    element_class VARCHAR(255),
    element_text TEXT,
    page_url TEXT NOT NULL,
    x_coordinate INTEGER,
    y_coordinate INTEGER,
    timestamp_client TIMESTAMP,
    user_agent TEXT,
    ip_address INET,
    device_type VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Scroll Events Tracking Table
CREATE TABLE IF NOT EXISTS analytics.scroll_events (
    id VARCHAR(255) PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    page_url TEXT NOT NULL,
    scroll_depth_percent INTEGER NOT NULL,
    max_scroll_depth_percent INTEGER,
    page_height INTEGER,
    viewport_height INTEGER,
    scroll_time_seconds INTEGER,
    timestamp_client TIMESTAMP,
    user_agent TEXT,
    ip_address INET,
    device_type VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Session Data Tracking Table
CREATE TABLE IF NOT EXISTS analytics.session_data (
    id VARCHAR(255) PRIMARY KEY,
    session_id VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_start_time TIMESTAMP,
    session_end_time TIMESTAMP,
    total_page_views INTEGER DEFAULT 0,
    total_clicks INTEGER DEFAULT 0,
    max_scroll_depth INTEGER DEFAULT 0,
    session_duration_seconds INTEGER,
    pages_visited TEXT,
    entry_page TEXT,
    exit_page TEXT,
    bounce_rate DECIMAL(5,2),
    conversion_events INTEGER DEFAULT 0,
    total_scroll_events INTEGER DEFAULT 0,
    referrer TEXT,
    referrer_source VARCHAR(255),
    utm_source VARCHAR(255),
    utm_medium VARCHAR(255),
    utm_campaign VARCHAR(255),
    timestamp_client TIMESTAMP,
    user_agent TEXT,
    ip_address INET,
    device_type VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    country VARCHAR(100),
    city VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Custom Events Tracking Table
CREATE TABLE IF NOT EXISTS analytics.events (
    id VARCHAR(255) PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_type VARCHAR(100) NOT NULL,
    event_name VARCHAR(255) NOT NULL,
    page_url TEXT,
    event_data JSONB,
    user_agent TEXT,
    ip_address INET,
    device_type VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================
-- INDEXES FOR PERFORMANCE
-- ==============================

-- Page Visits Indexes
CREATE INDEX IF NOT EXISTS idx_page_visits_session_id ON analytics.page_visits(session_id);
CREATE INDEX IF NOT EXISTS idx_page_visits_user_id ON analytics.page_visits(user_id);
CREATE INDEX IF NOT EXISTS idx_page_visits_timestamp ON analytics.page_visits(timestamp);
CREATE INDEX IF NOT EXISTS idx_page_visits_url ON analytics.page_visits(url);
CREATE INDEX IF NOT EXISTS idx_page_visits_device_type ON analytics.page_visits(device_type);

-- Click Events Indexes
CREATE INDEX IF NOT EXISTS idx_click_events_session_id ON analytics.click_events(session_id);
CREATE INDEX IF NOT EXISTS idx_click_events_user_id ON analytics.click_events(user_id);
CREATE INDEX IF NOT EXISTS idx_click_events_timestamp ON analytics.click_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_click_events_element_type ON analytics.click_events(element_type);
CREATE INDEX IF NOT EXISTS idx_click_events_page_url ON analytics.click_events(page_url);

-- Scroll Events Indexes
CREATE INDEX IF NOT EXISTS idx_scroll_events_session_id ON analytics.scroll_events(session_id);
CREATE INDEX IF NOT EXISTS idx_scroll_events_user_id ON analytics.scroll_events(user_id);
CREATE INDEX IF NOT EXISTS idx_scroll_events_timestamp ON analytics.scroll_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_scroll_events_page_url ON analytics.scroll_events(page_url);

-- Session Data Indexes
CREATE INDEX IF NOT EXISTS idx_session_data_session_id ON analytics.session_data(session_id);
CREATE INDEX IF NOT EXISTS idx_session_data_user_id ON analytics.session_data(user_id);
CREATE INDEX IF NOT EXISTS idx_session_data_start_time ON analytics.session_data(session_start_time);
CREATE INDEX IF NOT EXISTS idx_session_data_is_active ON analytics.session_data(is_active);

-- Custom Events Indexes
CREATE INDEX IF NOT EXISTS idx_events_session_id ON analytics.events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_user_id ON analytics.events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON analytics.events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_event_type ON analytics.events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_event_name ON analytics.events(event_name);

-- ==============================
-- SAMPLE DATA INSERTION
-- ==============================

-- Insert sample page visits
INSERT INTO analytics.page_visits (id, session_id, user_id, url, path, device_type, browser, os) VALUES
('pv_1', 'session_demo_1', 'user_123', 'http://localhost:3000/', '/', 'desktop', 'Chrome', 'MacOS'),
('pv_2', 'session_demo_1', 'user_123', 'http://localhost:3000/gaming', '/gaming', 'desktop', 'Chrome', 'MacOS'),
('pv_3', 'session_demo_2', 'user_456', 'http://localhost:3000/orders', '/orders', 'mobile', 'Safari', 'iOS');

-- Insert sample click events
INSERT INTO analytics.click_events (id, session_id, user_id, element_type, page_url, element_text, x_coordinate, y_coordinate) VALUES
('ce_1', 'session_demo_1', 'user_123', 'button', 'http://localhost:3000/gaming', 'Shop Now', 150, 300),
('ce_2', 'session_demo_1', 'user_123', 'button', 'http://localhost:3000/gaming', 'Add to Cart', 200, 450),
('ce_3', 'session_demo_2', 'user_456', 'link', 'http://localhost:3000/orders', 'View Order', 100, 200);

-- Insert sample scroll events
INSERT INTO analytics.scroll_events (id, session_id, user_id, page_url, scroll_depth_percent, viewport_height, page_height) VALUES
('se_1', 'session_demo_1', 'user_123', 'http://localhost:3000/gaming', 75, 800, 2000),
('se_2', 'session_demo_1', 'user_123', 'http://localhost:3000/gaming', 90, 800, 2000),
('se_3', 'session_demo_2', 'user_456', 'http://localhost:3000/orders', 60, 600, 1500);

-- Insert sample session data
INSERT INTO analytics.session_data (id, session_id, user_id, session_start_time, total_page_views, total_clicks, max_scroll_depth, device_type, browser, os) VALUES
('sd_1', 'session_demo_1', 'user_123', NOW() - INTERVAL '30 minutes', 3, 5, 90, 'desktop', 'Chrome', 'MacOS'),
('sd_2', 'session_demo_2', 'user_456', NOW() - INTERVAL '15 minutes', 2, 2, 60, 'mobile', 'Safari', 'iOS');

-- Insert sample custom events
INSERT INTO analytics.events (id, session_id, user_id, event_type, event_name, page_url, event_data) VALUES
('ev_1', 'session_demo_1', 'user_123', 'product', 'Product View', 'http://localhost:3000/gaming', '{"product_id": "123", "product_name": "Gaming Laptop"}'),
('ev_2', 'session_demo_1', 'user_123', 'product', 'Add to Cart', 'http://localhost:3000/gaming', '{"product_id": "123", "quantity": 1}'),
('ev_3', 'session_demo_2', 'user_456', 'order', 'Order View', 'http://localhost:3000/orders', '{"order_id": "order_456"}');

-- ==============================
-- VERIFICATION QUERIES
-- ==============================

-- Check table counts
SELECT 
    'page_visits' as table_name, COUNT(*) as record_count FROM analytics.page_visits
UNION ALL
SELECT 
    'click_events' as table_name, COUNT(*) as record_count FROM analytics.click_events
UNION ALL
SELECT 
    'scroll_events' as table_name, COUNT(*) as record_count FROM analytics.scroll_events
UNION ALL
SELECT 
    'session_data' as table_name, COUNT(*) as record_count FROM analytics.session_data
UNION ALL
SELECT 
    'events' as table_name, COUNT(*) as record_count FROM analytics.events;

-- Show recent analytics data
SELECT 'Recent Page Visits:' as info;
SELECT url, COUNT(*) as visits FROM analytics.page_visits GROUP BY url ORDER BY visits DESC LIMIT 5;

SELECT 'Recent Click Events:' as info;
SELECT element_text, COUNT(*) as clicks FROM analytics.click_events WHERE element_text IS NOT NULL GROUP BY element_text ORDER BY clicks DESC LIMIT 5;

SELECT 'Recent Custom Events:' as info;
SELECT event_name, COUNT(*) as occurrences FROM analytics.events GROUP BY event_name ORDER BY occurrences DESC LIMIT 5;

-- ==============================
-- CLICKHOUSE SETUP (Optional)
-- ==============================

-- Note: ClickHouse setup requires ClickHouse server to be running
-- The following are ClickHouse SQL commands to create corresponding analytics tables

/*
-- ClickHouse Analytics Tables (Run these in ClickHouse client)

CREATE DATABASE IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS analytics.page_visits (
    id String,
    session_id String,
    user_id String,
    timestamp DateTime,
    url String,
    path String,
    referrer String,
    device_type String,
    browser String,
    os String,
    duration_seconds UInt32
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, session_id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS analytics.click_events (
    id String,
    session_id String,
    user_id String,
    timestamp DateTime,
    element_type String,
    page_url String,
    element_text String,
    x_coordinate UInt16,
    y_coordinate UInt16
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, session_id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS analytics.scroll_events (
    id String,
    session_id String,
    user_id String,
    timestamp DateTime,
    page_url String,
    scroll_depth_percent UInt8,
    viewport_height UInt16,
    page_height UInt16
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, session_id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS analytics.session_data (
    id String,
    session_id String,
    user_id String,
    timestamp DateTime,
    session_start_time DateTime,
    total_page_views UInt32,
    total_clicks UInt32,
    max_scroll_depth UInt8,
    device_type String,
    browser String,
    os String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, session_id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS analytics.events (
    id String,
    session_id String,
    user_id String,
    timestamp DateTime,
    event_type String,
    event_name String,
    page_url String,
    event_data String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, session_id)
SETTINGS index_granularity = 8192;
*/

-- ==============================
-- SETUP COMPLETE
-- ==============================

SELECT 'Database setup completed successfully!' as status;
