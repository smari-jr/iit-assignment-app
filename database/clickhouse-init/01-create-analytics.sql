-- ClickHouse database initialization for analytics
-- This script creates the analytics database structure

-- Create database
CREATE DATABASE IF NOT EXISTS analytics;

-- Use the analytics database
USE analytics;

-- Page visits table for web analytics
CREATE TABLE IF NOT EXISTS page_visits (
    id String,
    session_id String,
    user_id String,
    timestamp DateTime,
    url String,
    path String,
    referrer String,
    user_agent String,
    ip_address String,
    country String,
    city String,
    device_type String,
    browser String,
    os String,
    screen_resolution String,
    duration_seconds UInt32,
    created_at DateTime
) ENGINE = MergeTree()
ORDER BY (toDate(timestamp), timestamp, session_id)
PARTITION BY toYYYYMM(timestamp)
TTL timestamp + INTERVAL 2 YEAR;

-- Events table for custom events
CREATE TABLE IF NOT EXISTS events (
    id String,
    session_id String,
    user_id String,
    timestamp DateTime,
    event_type String,
    event_name String,
    properties String, -- JSON string
    url String,
    user_agent String,
    ip_address String,
    country String,
    city String,
    created_at DateTime
) ENGINE = MergeTree()
ORDER BY (toDate(timestamp), timestamp, session_id)
PARTITION BY toYYYYMM(timestamp)
TTL timestamp + INTERVAL 2 YEAR;

-- Click events table
CREATE TABLE IF NOT EXISTS click_events (
    id String,
    session_id String,
    user_id String,
    timestamp DateTime,
    element_type String,
    element_id String,
    element_class String,
    element_text String,
    page_url String,
    x_coordinate UInt32,
    y_coordinate UInt32,
    timestamp_client DateTime,
    user_agent String,
    ip_address String,
    device_type String,
    browser String,
    os String,
    created_at DateTime
) ENGINE = MergeTree()
ORDER BY (toDate(timestamp), timestamp, session_id)
PARTITION BY toYYYYMM(timestamp)
TTL timestamp + INTERVAL 1 YEAR;

-- Scroll events table
CREATE TABLE IF NOT EXISTS scroll_events (
    id String,
    session_id String,
    user_id String,
    timestamp DateTime,
    page_url String,
    scroll_depth_percent UInt8,
    max_scroll_depth_percent UInt8,
    page_height UInt32,
    viewport_height UInt32,
    scroll_time_seconds UInt32,
    timestamp_client DateTime,
    user_agent String,
    ip_address String,
    device_type String,
    browser String,
    os String,
    created_at DateTime
) ENGINE = MergeTree()
ORDER BY (toDate(timestamp), timestamp, session_id)
PARTITION BY toYYYYMM(timestamp)
TTL timestamp + INTERVAL 1 YEAR;

-- Session data table
CREATE TABLE IF NOT EXISTS session_data (
    id String,
    session_id String,
    user_id String,
    timestamp DateTime,
    session_start_time DateTime,
    session_end_time DateTime,
    session_duration_seconds UInt32,
    pages_visited UInt32,
    total_clicks UInt32,
    total_scroll_events UInt32,
    bounce_rate Float32,
    is_active UInt8,
    exit_page String,
    referrer_source String,
    user_agent String,
    ip_address String,
    device_type String,
    browser String,
    os String,
    created_at DateTime
) ENGINE = MergeTree()
ORDER BY (toDate(timestamp), timestamp, session_id)
PARTITION BY toYYYYMM(timestamp)
TTL timestamp + INTERVAL 2 YEAR;

-- User activity events table
CREATE TABLE IF NOT EXISTS user_events (
    id String,
    user_id String,
    event_type String,
    event_data String, -- JSON string
    session_id String,
    ip_address String,
    user_agent String,
    page_url String,
    referrer_url String,
    device_type String,
    browser String,
    os String,
    country String,
    city String,
    timestamp DateTime DEFAULT now(),
    date Date DEFAULT toDate(timestamp)
) ENGINE = MergeTree()
ORDER BY (date, timestamp, user_id)
PARTITION BY toYYYYMM(date)
TTL date + INTERVAL 2 YEAR;

-- Product interactions table
CREATE TABLE IF NOT EXISTS product_events (
    id String,
    user_id String,
    product_id String,
    event_type String, -- view, add_to_cart, remove_cart, purchase, wishlist
    product_name String,
    product_category String,
    product_price Float64,
    quantity Int32 DEFAULT 1,
    session_id String,
    timestamp DateTime DEFAULT now(),
    date Date DEFAULT toDate(timestamp)
) ENGINE = MergeTree()
ORDER BY (date, timestamp, product_id)
PARTITION BY toYYYYMM(date)
TTL date + INTERVAL 2 YEAR;

-- Order analytics table
CREATE TABLE IF NOT EXISTS order_events (
    id String,
    user_id String,
    order_id String,
    order_number String,
    event_type String, -- created, paid, shipped, delivered, cancelled
    total_amount Float64,
    currency String,
    payment_method String,
    item_count Int32,
    timestamp DateTime DEFAULT now(),
    date Date DEFAULT toDate(timestamp)
) ENGINE = MergeTree()
ORDER BY (date, timestamp, order_id)
PARTITION BY toYYYYMM(date)
TTL date + INTERVAL 5 YEAR; -- Keep order data longer

-- Page views table
CREATE TABLE IF NOT EXISTS page_views (
    id String,
    user_id String,
    session_id String,
    page_url String,
    page_title String,
    referrer_url String,
    load_time Float64, -- in milliseconds
    bounce Boolean DEFAULT false,
    ip_address String,
    user_agent String,
    timestamp DateTime DEFAULT now(),
    date Date DEFAULT toDate(timestamp)
) ENGINE = MergeTree()
ORDER BY (date, timestamp, user_id)
PARTITION BY toYYYYMM(date)
TTL date + INTERVAL 1 YEAR;

-- Revenue tracking table
CREATE TABLE IF NOT EXISTS revenue_events (
    id String,
    user_id String,
    order_id String,
    product_id String,
    product_name String,
    product_category String,
    revenue Float64,
    currency String,
    quantity Int32,
    unit_price Float64,
    discount_amount Float64 DEFAULT 0,
    tax_amount Float64 DEFAULT 0,
    timestamp DateTime DEFAULT now(),
    date Date DEFAULT toDate(timestamp),
    year Int32 DEFAULT toYear(date),
    month Int32 DEFAULT toMonth(date),
    day Int32 DEFAULT toDayOfMonth(date)
) ENGINE = MergeTree()
ORDER BY (date, timestamp, product_id)
PARTITION BY toYYYYMM(date)
TTL date + INTERVAL 5 YEAR;

-- Error tracking table
CREATE TABLE IF NOT EXISTS error_events (
    id String,
    user_id String,
    session_id String,
    error_type String,
    error_message String,
    error_stack String,
    page_url String,
    user_agent String,
    timestamp DateTime DEFAULT now(),
    date Date DEFAULT toDate(timestamp)
) ENGINE = MergeTree()
ORDER BY (date, timestamp, error_type)
PARTITION BY toYYYYMM(date)
TTL date + INTERVAL 6 MONTH;

-- Performance metrics table
CREATE TABLE IF NOT EXISTS performance_events (
    id String,
    user_id String,
    session_id String,
    metric_name String, -- page_load, api_response, etc.
    metric_value Float64,
    page_url String,
    timestamp DateTime DEFAULT now(),
    date Date DEFAULT toDate(timestamp)
) ENGINE = MergeTree()
ORDER BY (date, timestamp, metric_name)
PARTITION BY toYYYYMM(date)
TTL date + INTERVAL 3 MONTH;

-- Create materialized views for common aggregations

-- Daily user activity summary
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_user_activity_mv
ENGINE = SummingMergeTree()
ORDER BY (date, user_id)
AS SELECT
    date,
    user_id,
    count() as event_count,
    uniq(session_id) as session_count,
    min(timestamp) as first_activity,
    max(timestamp) as last_activity
FROM user_events
GROUP BY date, user_id;

-- Daily product popularity
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_product_popularity_mv
ENGINE = SummingMergeTree()
ORDER BY (date, product_id)
AS SELECT
    date,
    product_id,
    product_name,
    product_category,
    countIf(event_type = 'view') as views,
    countIf(event_type = 'add_to_cart') as cart_adds,
    countIf(event_type = 'purchase') as purchases,
    sumIf(quantity, event_type = 'purchase') as total_sold
FROM product_events
GROUP BY date, product_id, product_name, product_category;

-- Daily revenue summary
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_revenue_mv
ENGINE = SummingMergeTree()
ORDER BY (date, currency)
AS SELECT
    date,
    currency,
    sum(revenue) as total_revenue,
    count() as transaction_count,
    uniq(user_id) as unique_customers,
    avg(revenue) as avg_transaction_value
FROM revenue_events
GROUP BY date, currency;

-- Hourly page views summary
CREATE MATERIALIZED VIEW IF NOT EXISTS hourly_pageviews_mv
ENGINE = SummingMergeTree()
ORDER BY (date, hour, page_url)
AS SELECT
    date,
    toHour(timestamp) as hour,
    page_url,
    count() as page_views,
    uniq(user_id) as unique_visitors,
    avg(load_time) as avg_load_time
FROM page_views
GROUP BY date, hour, page_url;
