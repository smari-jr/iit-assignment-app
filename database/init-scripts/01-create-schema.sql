-- Create database if not exists
SELECT 'CREATE DATABASE lugx_gaming'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'lugx_gaming')\gexec

-- Connect to lugx_gaming database
\c lugx_gaming;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    date_of_birth DATE,
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    is_premium BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Categories table for games
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products (Games) table
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category_id UUID REFERENCES categories(id),
    developer VARCHAR(100),
    publisher VARCHAR(100),
    release_date DATE,
    rating VARCHAR(10), -- E, T, M, AO
    platform VARCHAR(50), -- PC, PS5, Xbox, etc.
    system_requirements JSONB,
    image_url TEXT,
    trailer_url TEXT,
    download_size_gb DECIMAL(5,2),
    tags TEXT[], -- Array of tags
    is_active BOOLEAN DEFAULT true,
    stock_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, processing, shipped, delivered, cancelled
    total_amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_method VARCHAR(50),
    payment_status VARCHAR(20) DEFAULT 'pending', -- pending, completed, failed, refunded
    payment_reference TEXT,
    billing_address JSONB,
    shipping_address JSONB,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP
);

-- Order Items table
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    product_name VARCHAR(200) NOT NULL, -- Store name at time of purchase
    product_price DECIMAL(10,2) NOT NULL, -- Store price at time of purchase
    quantity INTEGER NOT NULL DEFAULT 1,
    total_price DECIMAL(12,2) NOT NULL,
    license_key TEXT, -- For digital games
    download_url TEXT, -- For digital downloads
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    comment TEXT,
    is_verified_purchase BOOLEAN DEFAULT false,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, product_id) -- One review per user per product
);

-- Order History table for tracking changes
CREATE TABLE IF NOT EXISTS order_histories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL,
    notes TEXT,
    created_by VARCHAR(100), -- system, admin, user
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Sessions table for JWT management
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_agent TEXT,
    ip_address INET
);

-- Shopping Cart table
CREATE TABLE IF NOT EXISTS shopping_cart (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, product_id)
);

-- Wishlist table
CREATE TABLE IF NOT EXISTS wishlist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, product_id)
);

-- Analytics Events table (for ClickHouse sync)
CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_to_clickhouse BOOLEAN DEFAULT false
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_user ON shopping_cart(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_user ON wishlist(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_created ON analytics_events(created_at);

-- Insert default categories
INSERT INTO categories (name, description, image_url) VALUES
('Action', 'Fast-paced games with combat and adventure', '/images/categories/action.jpg'),
('Adventure', 'Story-driven exploration games', '/images/categories/adventure.jpg'),
('RPG', 'Role-playing games with character development', '/images/categories/rpg.jpg'),
('Strategy', 'Tactical and strategic thinking games', '/images/categories/strategy.jpg'),
('Sports', 'Athletic and competitive sports games', '/images/categories/sports.jpg'),
('Racing', 'High-speed racing and driving games', '/images/categories/racing.jpg'),
('Simulation', 'Real-world simulation games', '/images/categories/simulation.jpg'),
('Puzzle', 'Brain-teasing puzzle and logic games', '/images/categories/puzzle.jpg')
ON CONFLICT (name) DO NOTHING;

-- Insert sample products
DO $$
DECLARE
    action_cat_id UUID;
    adventure_cat_id UUID;
    rpg_cat_id UUID;
    strategy_cat_id UUID;
BEGIN
    SELECT id INTO action_cat_id FROM categories WHERE name = 'Action';
    SELECT id INTO adventure_cat_id FROM categories WHERE name = 'Adventure';
    SELECT id INTO rpg_cat_id FROM categories WHERE name = 'RPG';
    SELECT id INTO strategy_cat_id FROM categories WHERE name = 'Strategy';

    INSERT INTO products (name, description, price, category_id, developer, publisher, release_date, rating, platform, download_size_gb, tags, stock_quantity) VALUES
    ('Cyber Warriors 2077', 'Futuristic action game set in a cyberpunk world', 59.99, action_cat_id, 'Future Games', 'Mega Publisher', '2024-03-15', 'M', 'PC', 85.5, ARRAY['cyberpunk', 'action', 'futuristic'], 100),
    ('Fantasy Quest Online', 'Massive multiplayer RPG with epic adventures', 49.99, rpg_cat_id, 'Epic Studios', 'RPG Masters', '2024-01-20', 'T', 'PC', 120.0, ARRAY['mmorpg', 'fantasy', 'online'], 200),
    ('Street Racer X', 'High-octane street racing experience', 39.99, action_cat_id, 'Speed Demons', 'Racing Corp', '2024-02-10', 'E', 'PC', 45.2, ARRAY['racing', 'cars', 'street'], 150),
    ('Kingdom Builder', 'Build and manage your medieval kingdom', 34.99, strategy_cat_id, 'Strategy Plus', 'Kingdom Games', '2024-01-05', 'E', 'PC', 12.8, ARRAY['strategy', 'building', 'medieval'], 80),
    ('Space Explorer', 'Explore the vast cosmos in this adventure game', 44.99, adventure_cat_id, 'Cosmic Games', 'Space Publishers', '2024-04-01', 'E', 'PC', 67.3, ARRAY['space', 'exploration', 'sci-fi'], 120)
    ON CONFLICT DO NOTHING;
END $$;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cart_updated_at BEFORE UPDATE ON shopping_cart FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to generate order numbers
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
BEGIN
    RETURN 'LGX-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(nextval('order_number_seq')::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Create sequence for order numbers
CREATE SEQUENCE IF NOT EXISTS order_number_seq START 1;

-- Analytics schema for web analytics
CREATE SCHEMA IF NOT EXISTS analytics;

-- Page visits analytics table
CREATE TABLE IF NOT EXISTS analytics.page_visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(255) NOT NULL,
    user_id UUID REFERENCES users(id),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    url TEXT NOT NULL,
    path TEXT NOT NULL,
    referrer TEXT,
    user_agent TEXT,
    ip_address INET,
    country VARCHAR(100),
    city VARCHAR(100),
    device_type VARCHAR(20),
    browser VARCHAR(50),
    os VARCHAR(50),
    screen_resolution VARCHAR(20),
    duration_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Events analytics table (generic events)
CREATE TABLE IF NOT EXISTS analytics.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(255) NOT NULL,
    user_id UUID REFERENCES users(id),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_type VARCHAR(100) NOT NULL,
    event_name VARCHAR(200) NOT NULL,
    properties JSONB,
    url TEXT,
    user_agent TEXT,
    ip_address INET,
    country VARCHAR(100),
    city VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Click events analytics table
CREATE TABLE IF NOT EXISTS analytics.click_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(255) NOT NULL,
    user_id UUID REFERENCES users(id),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    element_type VARCHAR(100) NOT NULL,
    element_id VARCHAR(255),
    element_class VARCHAR(500),
    element_text TEXT,
    page_url TEXT NOT NULL,
    x_coordinate INTEGER,
    y_coordinate INTEGER,
    timestamp_client TIMESTAMP,
    user_agent TEXT,
    ip_address INET,
    device_type VARCHAR(20),
    browser VARCHAR(50),
    os VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Scroll events analytics table
CREATE TABLE IF NOT EXISTS analytics.scroll_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(255) NOT NULL,
    user_id UUID REFERENCES users(id),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    page_url TEXT NOT NULL,
    scroll_depth_percent INTEGER NOT NULL,
    max_scroll_depth_percent INTEGER,
    page_height INTEGER,
    viewport_height INTEGER,
    scroll_time_seconds INTEGER DEFAULT 0,
    timestamp_client TIMESTAMP,
    user_agent TEXT,
    ip_address INET,
    device_type VARCHAR(20),
    browser VARCHAR(50),
    os VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Session data analytics table
CREATE TABLE IF NOT EXISTS analytics.session_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(255) NOT NULL UNIQUE,
    user_id UUID REFERENCES users(id),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_start_time TIMESTAMP NOT NULL,
    session_end_time TIMESTAMP,
    session_duration_seconds INTEGER,
    pages_visited INTEGER DEFAULT 0,
    total_clicks INTEGER DEFAULT 0,
    total_scroll_events INTEGER DEFAULT 0,
    bounce_rate DECIMAL(5,2),
    is_active BOOLEAN DEFAULT true,
    exit_page TEXT,
    referrer_source TEXT,
    user_agent TEXT,
    ip_address INET,
    device_type VARCHAR(20),
    browser VARCHAR(50),
    os VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for analytics tables for better performance
CREATE INDEX IF NOT EXISTS idx_page_visits_session_id ON analytics.page_visits(session_id);
CREATE INDEX IF NOT EXISTS idx_page_visits_user_id ON analytics.page_visits(user_id);
CREATE INDEX IF NOT EXISTS idx_page_visits_timestamp ON analytics.page_visits(timestamp);
CREATE INDEX IF NOT EXISTS idx_page_visits_path ON analytics.page_visits(path);

CREATE INDEX IF NOT EXISTS idx_events_session_id ON analytics.events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_user_id ON analytics.events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON analytics.events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_type ON analytics.events(event_type);

CREATE INDEX IF NOT EXISTS idx_click_events_session_id ON analytics.click_events(session_id);
CREATE INDEX IF NOT EXISTS idx_click_events_user_id ON analytics.click_events(user_id);
CREATE INDEX IF NOT EXISTS idx_click_events_timestamp ON analytics.click_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_click_events_element_type ON analytics.click_events(element_type);

CREATE INDEX IF NOT EXISTS idx_scroll_events_session_id ON analytics.scroll_events(session_id);
CREATE INDEX IF NOT EXISTS idx_scroll_events_user_id ON analytics.scroll_events(user_id);
CREATE INDEX IF NOT EXISTS idx_scroll_events_timestamp ON analytics.scroll_events(timestamp);

CREATE INDEX IF NOT EXISTS idx_session_data_session_id ON analytics.session_data(session_id);
CREATE INDEX IF NOT EXISTS idx_session_data_user_id ON analytics.session_data(user_id);
CREATE INDEX IF NOT EXISTS idx_session_data_timestamp ON analytics.session_data(timestamp);
