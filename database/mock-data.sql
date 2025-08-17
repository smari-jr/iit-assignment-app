-- Mock Data for LugX Gaming Platform
-- This script inserts comprehensive mock data for testing and development

-- Connect to the database
\c app_database;

-- Clear existing data (in reverse order of dependencies)
TRUNCATE TABLE analytics.scroll_events CASCADE;
TRUNCATE TABLE analytics.click_events CASCADE;
TRUNCATE TABLE analytics.events CASCADE;
TRUNCATE TABLE analytics.page_visits CASCADE;
TRUNCATE TABLE analytics.session_data CASCADE;
TRUNCATE TABLE analytics_events CASCADE;
TRUNCATE TABLE wishlist CASCADE;
TRUNCATE TABLE shopping_cart CASCADE;
TRUNCATE TABLE user_sessions CASCADE;
TRUNCATE TABLE order_histories CASCADE;
TRUNCATE TABLE reviews CASCADE;
TRUNCATE TABLE order_items CASCADE;
TRUNCATE TABLE orders CASCADE;
TRUNCATE TABLE products CASCADE;
TRUNCATE TABLE categories CASCADE;
TRUNCATE TABLE users CASCADE;

-- Insert sample users
INSERT INTO users (id, username, email, password_hash, first_name, last_name, phone, date_of_birth, is_active, is_premium, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'johndoe', 'john.doe@email.com', '$2b$10$K5Z5Z5Z5Z5Z5Z5Z5Z5Z5ZuBqR5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5', 'John', 'Doe', '+1234567890', '1990-05-15', true, false, '2024-01-01 10:00:00'),
('550e8400-e29b-41d4-a716-446655440002', 'janedoe', 'jane.doe@email.com', '$2b$10$K5Z5Z5Z5Z5Z5Z5Z5Z5Z5ZuBqR5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5', 'Jane', 'Doe', '+1234567891', '1985-08-22', true, true, '2024-01-02 11:00:00'),
('550e8400-e29b-41d4-a716-446655440003', 'gamerpro', 'gamer.pro@email.com', '$2b$10$K5Z5Z5Z5Z5Z5Z5Z5Z5Z5ZuBqR5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5', 'Mike', 'Johnson', '+1234567892', '1995-12-10', true, true, '2024-01-03 12:00:00'),
('550e8400-e29b-41d4-a716-446655440004', 'casualplayer', 'casual.player@email.com', '$2b$10$K5Z5Z5Z5Z5Z5Z5Z5Z5Z5ZuBqR5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5', 'Sarah', 'Wilson', '+1234567893', '1992-03-18', true, false, '2024-01-04 13:00:00'),
('550e8400-e29b-41d4-a716-446655440005', 'retroplayer', 'retro.player@email.com', '$2b$10$K5Z5Z5Z5Z5Z5Z5Z5Z5Z5ZuBqR5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5', 'David', 'Brown', '+1234567894', '1988-07-25', true, false, '2024-01-05 14:00:00'),
('550e8400-e29b-41d4-a716-446655440006', 'speedracer', 'speed.racer@email.com', '$2b$10$K5Z5Z5Z5Z5Z5Z5Z5Z5Z5ZuBqR5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5', 'Lisa', 'Garcia', '+1234567895', '1993-11-08', true, true, '2024-01-06 15:00:00'),
('550e8400-e29b-41d4-a716-446655440007', 'strategist', 'strategist@email.com', '$2b$10$K5Z5Z5Z5Z5Z5Z5Z5Z5Z5ZuBqR5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5', 'Robert', 'Miller', '+1234567896', '1987-09-14', true, false, '2024-01-07 16:00:00'),
('550e8400-e29b-41d4-a716-446655440008', 'adventurer', 'adventurer@email.com', '$2b$10$K5Z5Z5Z5Z5Z5Z5Z5Z5Z5ZuBqR5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5', 'Emily', 'Davis', '+1234567897', '1994-04-30', true, true, '2024-01-08 17:00:00'),
('550e8400-e29b-41d4-a716-446655440009', 'puzzlemaster', 'puzzle.master@email.com', '$2b$10$K5Z5Z5Z5Z5Z5Z5Z5Z5Z5ZuBqR5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5', 'Chris', 'Anderson', '+1234567898', '1991-01-12', true, false, '2024-01-09 18:00:00'),
('550e8400-e29b-41d4-a716-446655440010', 'sportsfan', 'sports.fan@email.com', '$2b$10$K5Z5Z5Z5Z5Z5Z5Z5Z5Z5ZuBqR5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5', 'Amanda', 'Taylor', '+1234567899', '1989-06-07', true, false, '2024-01-10 19:00:00');

-- Insert game categories
INSERT INTO categories (id, name, description, image_url, is_active, created_at) VALUES
('650e8400-e29b-41d4-a716-446655440001', 'Action', 'Fast-paced games with combat, adventure, and excitement', '/images/categories/action.jpg', true, '2024-01-01 10:00:00'),
('650e8400-e29b-41d4-a716-446655440002', 'Adventure', 'Story-driven exploration games with rich narratives', '/images/categories/adventure.jpg', true, '2024-01-01 10:05:00'),
('650e8400-e29b-41d4-a716-446655440003', 'RPG', 'Role-playing games with character development and progression', '/images/categories/rpg.jpg', true, '2024-01-01 10:10:00'),
('650e8400-e29b-41d4-a716-446655440004', 'Strategy', 'Tactical and strategic thinking games', '/images/categories/strategy.jpg', true, '2024-01-01 10:15:00'),
('650e8400-e29b-41d4-a716-446655440005', 'Sports', 'Athletic and competitive sports simulations', '/images/categories/sports.jpg', true, '2024-01-01 10:20:00'),
('650e8400-e29b-41d4-a716-446655440006', 'Racing', 'High-speed racing and driving experiences', '/images/categories/racing.jpg', true, '2024-01-01 10:25:00'),
('650e8400-e29b-41d4-a716-446655440007', 'Simulation', 'Real-world simulation and management games', '/images/categories/simulation.jpg', true, '2024-01-01 10:30:00'),
('650e8400-e29b-41d4-a716-446655440008', 'Puzzle', 'Brain-teasing puzzle and logic games', '/images/categories/puzzle.jpg', true, '2024-01-01 10:35:00'),
('650e8400-e29b-41d4-a716-446655440009', 'Horror', 'Scary and suspenseful horror games', '/images/categories/horror.jpg', true, '2024-01-01 10:40:00'),
('650e8400-e29b-41d4-a716-446655440010', 'Indie', 'Independent games from small developers', '/images/categories/indie.jpg', true, '2024-01-01 10:45:00');

-- Insert products (games)
INSERT INTO products (id, name, description, price, category_id, developer, publisher, release_date, rating, platform, system_requirements, image_url, trailer_url, download_size_gb, tags, is_active, stock_quantity, created_at) VALUES
('750e8400-e29b-41d4-a716-446655440001', 'Cyber Warriors 2077', 'Experience the ultimate cyberpunk adventure in a dystopian future where technology and humanity collide. Make choices that shape the world around you.', 59.99, '650e8400-e29b-41d4-a716-446655440001', 'Future Games Studio', 'Mega Publisher', '2024-03-15', 'M', 'PC', '{"os": "Windows 10", "processor": "Intel i5-8400", "memory": "16 GB RAM", "graphics": "GTX 1060 6GB", "storage": "85 GB"}', '/images/games/cyber-warriors-2077.jpg', '/videos/cyber-warriors-2077-trailer.mp4', 85.5, ARRAY['cyberpunk', 'action', 'rpg', 'futuristic', 'open-world'], true, 500, '2024-01-01 10:00:00'),

('750e8400-e29b-41d4-a716-446655440002', 'Fantasy Quest Online', 'Embark on epic adventures in a massive multiplayer world filled with magic, monsters, and endless possibilities. Build your legend with friends.', 49.99, '650e8400-e29b-41d4-a716-446655440003', 'Epic Studios', 'RPG Masters', '2024-01-20', 'T', 'PC', '{"os": "Windows 10", "processor": "Intel i7-7700", "memory": "32 GB RAM", "graphics": "RTX 2070", "storage": "120 GB"}', '/images/games/fantasy-quest-online.jpg', '/videos/fantasy-quest-online-trailer.mp4', 120.0, ARRAY['mmorpg', 'fantasy', 'online', 'magic', 'adventure'], true, 1000, '2024-01-01 10:30:00'),

('750e8400-e29b-41d4-a716-446655440003', 'Street Racer X', 'Feel the adrenaline rush in the most realistic street racing experience. Customize your ride and dominate the underground racing scene.', 39.99, '650e8400-e29b-41d4-a716-446655440006', 'Speed Demons', 'Racing Corp', '2024-02-10', 'E', 'PC', '{"os": "Windows 10", "processor": "Intel i5-9400F", "memory": "8 GB RAM", "graphics": "GTX 1650", "storage": "45 GB"}', '/images/games/street-racer-x.jpg', '/videos/street-racer-x-trailer.mp4', 45.2, ARRAY['racing', 'cars', 'street', 'customization', 'multiplayer'], true, 750, '2024-01-01 11:00:00'),

('750e8400-e29b-41d4-a716-446655440004', 'Kingdom Builder', 'Build and manage your medieval kingdom from a small village to a mighty empire. Make strategic decisions that will shape your realm.', 34.99, '650e8400-e29b-41d4-a716-446655440004', 'Strategy Plus', 'Kingdom Games', '2024-01-05', 'E', 'PC', '{"os": "Windows 10", "processor": "Intel i3-8100", "memory": "4 GB RAM", "graphics": "GTX 1050", "storage": "12 GB"}', '/images/games/kingdom-builder.jpg', '/videos/kingdom-builder-trailer.mp4', 12.8, ARRAY['strategy', 'building', 'medieval', 'management', 'empire'], true, 300, '2024-01-01 11:30:00'),

('750e8400-e29b-41d4-a716-446655440005', 'Space Explorer', 'Journey through the cosmos and discover new worlds in this breathtaking space exploration adventure. Uncover the mysteries of the universe.', 44.99, '650e8400-e29b-41d4-a716-446655440002', 'Cosmic Games', 'Space Publishers', '2024-04-01', 'E', 'PC', '{"os": "Windows 10", "processor": "Intel i5-8600K", "memory": "16 GB RAM", "graphics": "RTX 2060", "storage": "67 GB"}', '/images/games/space-explorer.jpg', '/videos/space-explorer-trailer.mp4', 67.3, ARRAY['space', 'exploration', 'sci-fi', 'adventure', 'discovery'], true, 600, '2024-01-01 12:00:00'),

('750e8400-e29b-41d4-a716-446655440006', 'Horror Mansion', 'Survive the night in a haunted mansion filled with terrifying secrets. Can you escape before dawn breaks?', 29.99, '650e8400-e29b-41d4-a716-446655440009', 'Nightmare Studios', 'Horror House', '2024-02-28', 'M', 'PC', '{"os": "Windows 10", "processor": "Intel i5-7400", "memory": "8 GB RAM", "graphics": "GTX 1060", "storage": "25 GB"}', '/images/games/horror-mansion.jpg', '/videos/horror-mansion-trailer.mp4', 25.4, ARRAY['horror', 'survival', 'scary', 'atmospheric', 'single-player'], true, 400, '2024-01-01 12:30:00'),

('750e8400-e29b-41d4-a716-446655440007', 'Puzzle Master 3000', 'Challenge your mind with over 1000 unique puzzles. From simple brain teasers to complex logic challenges.', 19.99, '650e8400-e29b-41d4-a716-446655440008', 'Brain Games', 'Puzzle Corp', '2024-01-15', 'E', 'PC', '{"os": "Windows 10", "processor": "Intel i3-6100", "memory": "4 GB RAM", "graphics": "Integrated", "storage": "2 GB"}', '/images/games/puzzle-master-3000.jpg', '/videos/puzzle-master-3000-trailer.mp4', 2.1, ARRAY['puzzle', 'logic', 'brain-teaser', 'casual', 'family'], true, 200, '2024-01-01 13:00:00'),

('750e8400-e29b-41d4-a716-446655440008', 'Sports Championship 2024', 'Experience the thrill of professional sports with realistic gameplay and authentic team rosters.', 54.99, '650e8400-e29b-41d4-a716-446655440005', 'Sports Interactive', 'Athletic Games', '2024-03-01', 'E', 'PC', '{"os": "Windows 10", "processor": "Intel i5-9400F", "memory": "12 GB RAM", "graphics": "GTX 1660", "storage": "55 GB"}', '/images/games/sports-championship-2024.jpg', '/videos/sports-championship-2024-trailer.mp4', 55.8, ARRAY['sports', 'simulation', 'realistic', 'championship', 'multiplayer'], true, 800, '2024-01-01 13:30:00'),

('750e8400-e29b-41d4-a716-446655440009', 'Indie Adventure Tales', 'A heartwarming indie adventure about friendship, discovery, and the magic of storytelling.', 24.99, '650e8400-e29b-41d4-a716-446655440010', 'Small Studio Games', 'Indie Publishers', '2024-02-14', 'E', 'PC', '{"os": "Windows 10", "processor": "Intel i3-7100", "memory": "6 GB RAM", "graphics": "GTX 1050", "storage": "8 GB"}', '/images/games/indie-adventure-tales.jpg', '/videos/indie-adventure-tales-trailer.mp4', 8.2, ARRAY['indie', 'adventure', 'story', 'heartwarming', 'artistic'], true, 150, '2024-01-01 14:00:00'),

('750e8400-e29b-41d4-a716-446655440010', 'City Simulator Pro', 'Build the city of your dreams with advanced simulation mechanics and realistic urban planning challenges.', 42.99, '650e8400-e29b-41d4-a716-446655440007', 'Urban Developers', 'Simulation Masters', '2024-03-20', 'E', 'PC', '{"os": "Windows 10", "processor": "Intel i7-8700", "memory": "16 GB RAM", "graphics": "RTX 2070", "storage": "35 GB"}', '/images/games/city-simulator-pro.jpg', '/videos/city-simulator-pro-trailer.mp4', 35.6, ARRAY['simulation', 'city-building', 'management', 'realistic', 'strategy'], true, 450, '2024-01-01 14:30:00');

-- Insert sample orders
INSERT INTO orders (id, user_id, order_number, status, total_amount, currency, payment_method, payment_status, billing_address, shipping_address, notes, created_at, updated_at) VALUES
('850e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'LGX-20240101-000001', 'delivered', 109.98, 'USD', 'credit_card', 'completed', '{"street": "123 Main St", "city": "New York", "state": "NY", "zip": "10001", "country": "USA"}', '{"street": "123 Main St", "city": "New York", "state": "NY", "zip": "10001", "country": "USA"}', 'First order - welcome bonus applied', '2024-01-15 10:00:00', '2024-01-18 15:00:00'),

('850e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'LGX-20240102-000002', 'delivered', 59.99, 'USD', 'paypal', 'completed', '{"street": "456 Oak Ave", "city": "Los Angeles", "state": "CA", "zip": "90210", "country": "USA"}', '{"street": "456 Oak Ave", "city": "Los Angeles", "state": "CA", "zip": "90210", "country": "USA"}', 'Premium member discount applied', '2024-01-20 14:30:00', '2024-01-22 09:15:00'),

('850e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'LGX-20240103-000003', 'processing', 149.97, 'USD', 'credit_card', 'completed', '{"street": "789 Pine St", "city": "Chicago", "state": "IL", "zip": "60601", "country": "USA"}', '{"street": "789 Pine St", "city": "Chicago", "state": "IL", "zip": "60601", "country": "USA"}', 'Bulk order - multiple games', '2024-02-01 11:45:00', '2024-02-01 11:45:00'),

('850e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'LGX-20240104-000004', 'shipped', 64.98, 'USD', 'debit_card', 'completed', '{"street": "321 Elm St", "city": "Miami", "state": "FL", "zip": "33101", "country": "USA"}', '{"street": "321 Elm St", "city": "Miami", "state": "FL", "zip": "33101", "country": "USA"}', 'Express shipping requested', '2024-02-05 16:20:00', '2024-02-07 10:30:00'),

('850e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', 'LGX-20240105-000005', 'delivered', 39.99, 'USD', 'credit_card', 'completed', '{"street": "654 Maple Dr", "city": "Seattle", "state": "WA", "zip": "98101", "country": "USA"}', '{"street": "654 Maple Dr", "city": "Seattle", "state": "WA", "zip": "98101", "country": "USA"}', 'Gift order for friend', '2024-02-10 12:00:00', '2024-02-12 14:45:00');

-- Insert order items
INSERT INTO order_items (id, order_id, product_id, product_name, product_price, quantity, total_price, license_key, created_at) VALUES
('950e8400-e29b-41d4-a716-446655440001', '850e8400-e29b-41d4-a716-446655440001', '750e8400-e29b-41d4-a716-446655440001', 'Cyber Warriors 2077', 59.99, 1, 59.99, 'CW2077-XXXX-YYYY-ZZZZ-AAAA', '2024-01-15 10:00:00'),
('950e8400-e29b-41d4-a716-446655440002', '850e8400-e29b-41d4-a716-446655440001', '750e8400-e29b-41d4-a716-446655440002', 'Fantasy Quest Online', 49.99, 1, 49.99, 'FQO2024-BBBB-CCCC-DDDD-EEEE', '2024-01-15 10:00:00'),

('950e8400-e29b-41d4-a716-446655440003', '850e8400-e29b-41d4-a716-446655440002', '750e8400-e29b-41d4-a716-446655440001', 'Cyber Warriors 2077', 59.99, 1, 59.99, 'CW2077-FFFF-GGGG-HHHH-IIII', '2024-01-20 14:30:00'),

('950e8400-e29b-41d4-a716-446655440004', '850e8400-e29b-41d4-a716-446655440003', '750e8400-e29b-41d4-a716-446655440003', 'Street Racer X', 39.99, 1, 39.99, 'SRX2024-JJJJ-KKKK-LLLL-MMMM', '2024-02-01 11:45:00'),
('950e8400-e29b-41d4-a716-446655440005', '850e8400-e29b-41d4-a716-446655440003', '750e8400-e29b-41d4-a716-446655440004', 'Kingdom Builder', 34.99, 1, 34.99, 'KB2024-NNNN-OOOO-PPPP-QQQQ', '2024-02-01 11:45:00'),
('950e8400-e29b-41d4-a716-446655440006', '850e8400-e29b-41d4-a716-446655440003', '750e8400-e29b-41d4-a716-446655440005', 'Space Explorer', 44.99, 1, 44.99, 'SE2024-RRRR-SSSS-TTTT-UUUU', '2024-02-01 11:45:00'),
('950e8400-e29b-41d4-a716-446655440007', '850e8400-e29b-41d4-a716-446655440003', '750e8400-e29b-41d4-a716-446655440007', 'Puzzle Master 3000', 19.99, 1, 19.99, 'PM3000-VVVV-WWWW-XXXX-YYYY', '2024-02-01 11:45:00'),
('950e8400-e29b-41d4-a716-446655440008', '850e8400-e29b-41d4-a716-446655440003', '750e8400-e29b-41d4-a716-446655440009', 'Indie Adventure Tales', 24.99, 1, 24.99, 'IAT2024-ZZZZ-AAAA-BBBB-CCCC', '2024-02-01 11:45:00'),

('950e8400-e29b-41d4-a716-446655440009', '850e8400-e29b-41d4-a716-446655440004', '750e8400-e29b-41d4-a716-446655440006', 'Horror Mansion', 29.99, 1, 29.99, 'HM2024-DDDD-EEEE-FFFF-GGGG', '2024-02-05 16:20:00'),
('950e8400-e29b-41d4-a716-446655440010', '850e8400-e29b-41d4-a716-446655440004', 'City Simulator Pro', 42.99, 1, 34.99, 'CSP2024-HHHH-IIII-JJJJ-KKKK', '2024-02-05 16:20:00'),

('950e8400-e29b-41d4-a716-446655440011', '850e8400-e29b-41d4-a716-446655440005', '750e8400-e29b-41d4-a716-446655440003', 'Street Racer X', 39.99, 1, 39.99, 'SRX2024-LLLL-MMMM-NNNN-OOOO', '2024-02-10 12:00:00');

-- Insert product reviews
INSERT INTO reviews (id, user_id, product_id, rating, title, comment, is_verified_purchase, helpful_count, created_at) VALUES
('a50e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', '750e8400-e29b-41d4-a716-446655440001', 5, 'Amazing Game!', 'Cyber Warriors 2077 exceeded all my expectations. The graphics are stunning and the storyline is captivating. Highly recommended!', true, 15, '2024-01-20 10:00:00'),
('a50e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', '750e8400-e29b-41d4-a716-446655440001', 4, 'Great but buggy', 'Love the game concept but encountered some bugs. Still enjoyable overall.', true, 8, '2024-01-25 14:30:00'),
('a50e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', '750e8400-e29b-41d4-a716-446655440002', 5, 'Best MMO Ever!', 'Fantasy Quest Online brings back the magic of classic MMORPGs with modern graphics. The community is amazing!', true, 23, '2024-02-05 11:45:00'),
('a50e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', '750e8400-e29b-41d4-a716-446655440003', 4, 'Solid Racing Game', 'Street Racer X delivers on the adrenaline. Great customization options and smooth gameplay.', true, 12, '2024-02-08 16:20:00'),
('a50e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', '750e8400-e29b-41d4-a716-446655440003', 5, 'Perfect for Racing Fans', 'Best racing game I have played in years. The physics feel realistic and the tracks are well designed.', true, 7, '2024-02-15 12:00:00'),
('a50e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440006', '750e8400-e29b-41d4-a716-446655440004', 5, 'Strategy Masterpiece', 'Kingdom Builder is the perfect blend of complexity and accessibility. Hours of engaging gameplay.', false, 18, '2024-02-10 09:30:00'),
('a50e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440007', '750e8400-e29b-41d4-a716-446655440005', 4, 'Beautiful Space Adventure', 'Space Explorer offers a gorgeous and immersive space exploration experience. Minor navigation issues.', false, 11, '2024-02-12 15:45:00'),
('a50e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440008', '750e8400-e29b-41d4-a716-446655440006', 3, 'Too Scary for Me', 'Horror Mansion is genuinely terrifying. Great atmosphere but maybe too intense for casual players.', false, 5, '2024-02-14 20:15:00'),
('a50e8400-e29b-41d4-a716-446655440009', '550e8400-e29b-41d4-a716-446655440009', '750e8400-e29b-41d4-a716-446655440007', 5, 'Perfect Brain Training', 'Puzzle Master 3000 has the perfect difficulty curve. Great for daily brain training sessions.', false, 9, '2024-02-16 11:20:00'),
('a50e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440010', '750e8400-e29b-41d4-a716-446655440008', 4, 'Realistic Sports Action', 'Sports Championship 2024 delivers authentic sports action. The AI could be better but overall solid.', false, 6, '2024-02-18 16:40:00');

-- Insert shopping cart items
INSERT INTO shopping_cart (id, user_id, product_id, quantity, added_at) VALUES
('b50e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440006', '750e8400-e29b-41d4-a716-446655440008', 1, '2024-02-15 10:30:00'),
('b50e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440007', '750e8400-e29b-41d4-a716-446655440010', 1, '2024-02-16 14:20:00'),
('b50e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440008', '750e8400-e29b-41d4-a716-446655440002', 1, '2024-02-17 09:15:00'),
('b50e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440009', '750e8400-e29b-41d4-a716-446655440009', 1, '2024-02-18 16:45:00'),
('b50e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440010', '750e8400-e29b-41d4-a716-446655440005', 1, '2024-02-19 11:00:00');

-- Insert wishlist items
INSERT INTO wishlist (id, user_id, product_id, added_at) VALUES
('c50e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', '750e8400-e29b-41d4-a716-446655440008', '2024-02-10 10:00:00'),
('c50e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', '750e8400-e29b-41d4-a716-446655440010', '2024-02-11 14:30:00'),
('c50e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', '750e8400-e29b-41d4-a716-446655440006', '2024-02-12 11:45:00'),
('c50e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', '750e8400-e29b-41d4-a716-446655440009', '2024-02-13 16:20:00'),
('c50e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', '750e8400-e29b-41d4-a716-446655440007', '2024-02-14 12:00:00'),
('c50e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440006', '750e8400-e29b-41d4-a716-446655440001', '2024-02-15 09:30:00'),
('c50e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440007', '750e8400-e29b-41d4-a716-446655440002', '2024-02-16 15:45:00'),
('c50e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440008', '750e8400-e29b-41d4-a716-446655440004', '2024-02-17 13:10:00'),
('c50e8400-e29b-41d4-a716-446655440009', '550e8400-e29b-41d4-a716-446655440009', '750e8400-e29b-41d4-a716-446655440003', '2024-02-18 10:25:00'),
('c50e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440010', '750e8400-e29b-41d4-a716-446655440006', '2024-02-19 14:50:00');

-- Insert analytics events
INSERT INTO analytics_events (id, user_id, event_type, event_data, session_id, ip_address, user_agent, created_at) VALUES
('d50e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'page_view', '{"page": "/", "title": "Home Page"}', 'sess_001', '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '2024-02-01 10:00:00'),
('d50e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'product_view', '{"product_id": "750e8400-e29b-41d4-a716-446655440001", "product_name": "Cyber Warriors 2077"}', 'sess_001', '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '2024-02-01 10:05:00'),
('d50e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440002', 'purchase', '{"order_id": "850e8400-e29b-41d4-a716-446655440002", "amount": 59.99, "currency": "USD"}', 'sess_002', '192.168.1.101', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36', '2024-02-01 14:30:00'),
('d50e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440003', 'search', '{"query": "racing games", "results_count": 3}', 'sess_003', '192.168.1.102', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '2024-02-02 09:15:00'),
('d50e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440004', 'add_to_cart', '{"product_id": "750e8400-e29b-41d4-a716-446655440006", "product_name": "Horror Mansion"}', 'sess_004', '192.168.1.103', 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15', '2024-02-02 16:20:00'),
('d50e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440005', 'wishlist_add', '{"product_id": "750e8400-e29b-41d4-a716-446655440007", "product_name": "Puzzle Master 3000"}', 'sess_005', '192.168.1.104', 'Mozilla/5.0 (Android 11; Mobile; rv:68.0) Gecko/68.0 Firefox/88.0', '2024-02-03 12:00:00'),
('d50e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440006', 'review_submit', '{"product_id": "750e8400-e29b-41d4-a716-446655440004", "rating": 5}', 'sess_006', '192.168.1.105', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '2024-02-04 09:30:00'),
('d50e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440007', 'category_browse', '{"category": "Strategy", "category_id": "650e8400-e29b-41d4-a716-446655440004"}', 'sess_007', '192.168.1.106', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36', '2024-02-04 15:45:00'),
('d50e8400-e29b-41d4-a716-446655440009', '550e8400-e29b-41d4-a716-446655440008', 'download_start', '{"product_id": "750e8400-e29b-41d4-a716-446655440001", "download_size_gb": 85.5}', 'sess_008', '192.168.1.107', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '2024-02-05 13:10:00'),
('d50e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440009', 'user_registration', '{"source": "homepage", "referrer": "google.com"}', 'sess_009', '192.168.1.108', 'Mozilla/5.0 (iPad; CPU OS 15_0 like Mac OS X) AppleWebKit/605.1.15', '2024-02-05 10:25:00');

-- Insert analytics schema data for comprehensive tracking
INSERT INTO analytics.session_data (id, session_id, user_id, session_start_time, session_end_time, session_duration_seconds, pages_visited, total_clicks, total_scroll_events, bounce_rate, is_active, exit_page, referrer_source, user_agent, ip_address, device_type, browser, os, created_at) VALUES
('e50e8400-e29b-41d4-a716-446655440001', 'sess_001', '550e8400-e29b-41d4-a716-446655440001', '2024-02-01 10:00:00', '2024-02-01 10:45:00', 2700, 8, 15, 12, 0.0, false, '/checkout/success', 'google.com', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '192.168.1.100', 'desktop', 'Chrome', 'Windows', '2024-02-01 10:00:00'),
('e50e8400-e29b-41d4-a716-446655440002', 'sess_002', '550e8400-e29b-41d4-a716-446655440002', '2024-02-01 14:30:00', '2024-02-01 15:15:00', 2700, 6, 12, 8, 0.0, false, '/orders/history', 'facebook.com', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36', '192.168.1.101', 'desktop', 'Safari', 'macOS', '2024-02-01 14:30:00'),
('e50e8400-e29b-41d4-a716-446655440003', 'sess_003', '550e8400-e29b-41d4-a716-446655440003', '2024-02-02 09:15:00', '2024-02-02 09:50:00', 2100, 5, 10, 7, 0.0, false, '/products/racing', 'twitter.com', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '192.168.1.102', 'desktop', 'Chrome', 'Windows', '2024-02-02 09:15:00'),
('e50e8400-e29b-41d4-a716-446655440004', 'sess_004', '550e8400-e29b-41d4-a716-446655440004', '2024-02-02 16:20:00', '2024-02-02 16:35:00', 900, 3, 5, 4, 0.33, false, '/cart', 'direct', 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15', '192.168.1.103', 'mobile', 'Safari', 'iOS', '2024-02-02 16:20:00'),
('e50e8400-e29b-41d4-a716-446655440005', 'sess_005', '550e8400-e29b-41d4-a716-446655440005', '2024-02-03 12:00:00', '2024-02-03 12:25:00', 1500, 4, 8, 6, 0.25, false, '/wishlist', 'youtube.com', 'Mozilla/5.0 (Android 11; Mobile; rv:68.0) Gecko/68.0 Firefox/88.0', '192.168.1.104', 'mobile', 'Firefox', 'Android', '2024-02-03 12:00:00');

INSERT INTO analytics.page_visits (id, session_id, user_id, url, path, referrer, user_agent, ip_address, country, city, device_type, browser, os, screen_resolution, duration_seconds, created_at) VALUES
('f50e8400-e29b-41d4-a716-446655440001', 'sess_001', '550e8400-e29b-41d4-a716-446655440001', 'https://lugx-gaming.com/', '/', 'https://google.com/search?q=gaming+store', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '192.168.1.100', 'USA', 'New York', 'desktop', 'Chrome', 'Windows', '1920x1080', 120, '2024-02-01 10:00:00'),
('f50e8400-e29b-41d4-a716-446655440002', 'sess_001', '550e8400-e29b-41d4-a716-446655440001', 'https://lugx-gaming.com/products', '/products', 'https://lugx-gaming.com/', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '192.168.1.100', 'USA', 'New York', 'desktop', 'Chrome', 'Windows', '1920x1080', 180, '2024-02-01 10:02:00'),
('f50e8400-e29b-41d4-a716-446655440003', 'sess_001', '550e8400-e29b-41d4-a716-446655440001', 'https://lugx-gaming.com/products/cyber-warriors-2077', '/products/cyber-warriors-2077', 'https://lugx-gaming.com/products', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '192.168.1.100', 'USA', 'New York', 'desktop', 'Chrome', 'Windows', '1920x1080', 300, '2024-02-01 10:05:00'),
('f50e8400-e29b-41d4-a716-446655440004', 'sess_002', '550e8400-e29b-41d4-a716-446655440002', 'https://lugx-gaming.com/', '/', 'https://facebook.com/lugx-gaming', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36', '192.168.1.101', 'USA', 'Los Angeles', 'desktop', 'Safari', 'macOS', '2560x1440', 90, '2024-02-01 14:30:00'),
('f50e8400-e29b-41d4-a716-446655440005', 'sess_003', '550e8400-e29b-41d4-a716-446655440003', 'https://lugx-gaming.com/search?q=racing', '/search', 'https://twitter.com/lugx-gaming', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '192.168.1.102', 'USA', 'Chicago', 'desktop', 'Chrome', 'Windows', '1920x1080', 150, '2024-02-02 09:15:00');

INSERT INTO analytics.events (id, session_id, user_id, event_type, event_name, properties, url, user_agent, ip_address, country, city, created_at) VALUES
('g50e8400-e29b-41d4-a716-446655440001', 'sess_001', '550e8400-e29b-41d4-a716-446655440001', 'engagement', 'add_to_cart', '{"product_id": "750e8400-e29b-41d4-a716-446655440001", "product_name": "Cyber Warriors 2077", "price": 59.99, "category": "Action"}', 'https://lugx-gaming.com/products/cyber-warriors-2077', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '192.168.1.100', 'USA', 'New York', '2024-02-01 10:08:00'),
('g50e8400-e29b-41d4-a716-446655440002', 'sess_001', '550e8400-e29b-41d4-a716-446655440001', 'conversion', 'purchase', '{"order_id": "850e8400-e29b-41d4-a716-446655440001", "total": 109.98, "items_count": 2, "payment_method": "credit_card"}', 'https://lugx-gaming.com/checkout/success', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '192.168.1.100', 'USA', 'New York', '2024-02-01 10:40:00'),
('g50e8400-e29b-41d4-a716-446655440003', 'sess_002', '550e8400-e29b-41d4-a716-446655440002', 'engagement', 'newsletter_signup', '{"source": "footer", "email": "jane.doe@email.com"}', 'https://lugx-gaming.com/', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36', '192.168.1.101', 'USA', 'Los Angeles', '2024-02-01 14:35:00'),
('g50e8400-e29b-41d4-a716-446655440004', 'sess_003', '550e8400-e29b-41d4-a716-446655440003', 'engagement', 'search', '{"query": "racing games", "results_count": 3, "filters": {"category": "Racing", "price_range": "30-50"}}', 'https://lugx-gaming.com/search?q=racing', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', '192.168.1.102', 'USA', 'Chicago', '2024-02-02 09:18:00'),
('g50e8400-e29b-41d4-a716-446655440005', 'sess_004', '550e8400-e29b-41d4-a716-446655440004', 'engagement', 'review_submit', '{"product_id": "750e8400-e29b-41d4-a716-446655440006", "rating": 3, "has_comment": true}', 'https://lugx-gaming.com/products/horror-mansion', 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15', '192.168.1.103', 'USA', 'Miami', '2024-02-02 16:25:00');

-- Display summary of inserted data
SELECT 'Data insertion completed successfully!' as status;

SELECT 
    'users' as table_name, 
    COUNT(*) as record_count 
FROM users
UNION ALL
SELECT 
    'categories' as table_name, 
    COUNT(*) as record_count 
FROM categories
UNION ALL
SELECT 
    'products' as table_name, 
    COUNT(*) as record_count 
FROM products
UNION ALL
SELECT 
    'orders' as table_name, 
    COUNT(*) as record_count 
FROM orders
UNION ALL
SELECT 
    'order_items' as table_name, 
    COUNT(*) as record_count 
FROM order_items
UNION ALL
SELECT 
    'reviews' as table_name, 
    COUNT(*) as record_count 
FROM reviews
UNION ALL
SELECT 
    'shopping_cart' as table_name, 
    COUNT(*) as record_count 
FROM shopping_cart
UNION ALL
SELECT 
    'wishlist' as table_name, 
    COUNT(*) as record_count 
FROM wishlist
UNION ALL
SELECT 
    'analytics_events' as table_name, 
    COUNT(*) as record_count 
FROM analytics_events
UNION ALL
SELECT 
    'analytics.session_data' as table_name, 
    COUNT(*) as record_count 
FROM analytics.session_data
UNION ALL
SELECT 
    'analytics.page_visits' as table_name, 
    COUNT(*) as record_count 
FROM analytics.page_visits
UNION ALL
SELECT 
    'analytics.events' as table_name, 
    COUNT(*) as record_count 
FROM analytics.events
ORDER BY table_name;
