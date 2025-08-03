#!/bin/bash

# Database Migration and Maintenance Script
# This script handles database migrations and maintenance tasks

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RDS_ENDPOINT="iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com"
DB_NAME="lugx_gaming_dev"
DB_USER="dbadmin"
DB_PASSWORD="LionKing1234"
DB_PORT="5432"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to execute SQL query
execute_sql() {
    local query="$1"
    PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME -p $DB_PORT -c "$query"
}

# Function to execute SQL file
execute_sql_file() {
    local file="$1"
    PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME -p $DB_PORT -f "$file"
}

# Function to backup database
backup_database() {
    print_status "Creating database backup..."
    local backup_file="backup_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
    
    PGPASSWORD=$DB_PASSWORD pg_dump -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME -p $DB_PORT > "$backup_file" || {
        print_error "Backup failed"
        return 1
    }
    
    print_success "Backup created: $backup_file"
    echo "$backup_file"
}

# Function to seed test data
seed_test_data() {
    print_status "Seeding test data..."
    
    local seed_sql="/tmp/seed-data.sql"
    
    cat > "$seed_sql" << 'EOF'
-- Insert test categories
INSERT INTO categories (name, description, image_url) VALUES
('Action', 'Fast-paced games with combat and adventure', 'https://example.com/action.jpg'),
('RPG', 'Role-playing games with character development', 'https://example.com/rpg.jpg'),
('Strategy', 'Games requiring tactical thinking and planning', 'https://example.com/strategy.jpg'),
('Sports', 'Sports simulation and arcade games', 'https://example.com/sports.jpg'),
('Racing', 'Racing and driving simulation games', 'https://example.com/racing.jpg')
ON CONFLICT (name) DO NOTHING;

-- Insert test products
INSERT INTO products (name, description, price, developer, publisher, rating, platform) VALUES
('Epic Adventure Quest', 'An epic fantasy adventure game', 59.99, 'GameStudio', 'BigPublisher', 'T', 'PC'),
('Racing Thunder', 'High-speed racing game', 39.99, 'SpeedDev', 'RacePublisher', 'E', 'PC'),
('Strategy Masters', 'Turn-based strategy game', 49.99, 'TacticStudio', 'StrategyPub', 'T', 'PC'),
('Sports Champion', 'Multi-sport simulation', 54.99, 'SportsDev', 'SportsPub', 'E', 'PC'),
('Space Explorer', 'Sci-fi exploration game', 44.99, 'SpaceDev', 'SciFiPub', 'T', 'PC')
ON CONFLICT (name) DO NOTHING;

-- Insert test users
INSERT INTO users (username, email, password_hash, first_name, last_name, is_active) VALUES
('john_doe', 'john@example.com', '$2b$10$example_hash', 'John', 'Doe', true),
('jane_smith', 'jane@example.com', '$2b$10$example_hash', 'Jane', 'Smith', true),
('gamer123', 'gamer@example.com', '$2b$10$example_hash', 'Pro', 'Gamer', true)
ON CONFLICT (email) DO NOTHING;
EOF
    
    execute_sql_file "$seed_sql" || {
        print_error "Failed to seed test data"
        rm -f "$seed_sql"
        return 1
    }
    
    rm -f "$seed_sql"
    print_success "Test data seeded successfully"
}

# Function to check database health
check_database_health() {
    print_status "Checking database health..."
    
    # Check connection
    execute_sql "SELECT version();" >/dev/null || {
        print_error "Database connection failed"
        return 1
    }
    
    # Check table counts
    local table_count=$(execute_sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tail -n +3 | head -n 1 | xargs)
    print_status "Tables found: $table_count"
    
    # Check for key tables
    local key_tables=("users" "products" "categories" "orders")
    for table in "${key_tables[@]}"; do
        local exists=$(execute_sql "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '$table');" | tail -n +3 | head -n 1 | xargs)
        if [ "$exists" = "t" ]; then
            local count=$(execute_sql "SELECT COUNT(*) FROM $table;" | tail -n +3 | head -n 1 | xargs)
            print_status "Table '$table': $count records"
        else
            print_warning "Table '$table' not found"
        fi
    done
    
    print_success "Database health check completed"
}

# Function to show database statistics
show_statistics() {
    print_status "Database Statistics:"
    echo
    
    execute_sql "
    SELECT 
        schemaname,
        tablename,
        attname,
        n_distinct,
        correlation
    FROM pg_stats 
    WHERE schemaname = 'public'
    ORDER BY tablename, attname;
    " 2>/dev/null || print_warning "Could not retrieve statistics"
    
    print_status "Database Size:"
    execute_sql "
    SELECT 
        pg_size_pretty(pg_database_size('$DB_NAME')) as database_size;
    " 2>/dev/null || print_warning "Could not retrieve database size"
}

# Function to cleanup old data
cleanup_old_data() {
    print_status "Cleaning up old data..."
    
    # Clean up old analytics data (older than 90 days)
    execute_sql "DELETE FROM user_events WHERE created_at < NOW() - INTERVAL '90 days';" || print_warning "Could not clean user_events"
    execute_sql "DELETE FROM page_views WHERE created_at < NOW() - INTERVAL '90 days';" || print_warning "Could not clean page_views"
    
    # Vacuum tables
    execute_sql "VACUUM ANALYZE;" || print_warning "Could not vacuum database"
    
    print_success "Cleanup completed"
}

# Function to create database indexes
create_indexes() {
    print_status "Creating performance indexes..."
    
    local index_sql="/tmp/create-indexes.sql"
    
    cat > "$index_sql" << 'EOF'
-- Performance indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_price ON products(price);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
EOF
    
    execute_sql_file "$index_sql" || {
        print_error "Failed to create indexes"
        rm -f "$index_sql"
        return 1
    }
    
    rm -f "$index_sql"
    print_success "Performance indexes created"
}

# Function to show usage
show_usage() {
    echo "Database Migration and Maintenance Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  backup          Create a database backup"
    echo "  seed            Seed test data"
    echo "  health          Check database health"
    echo "  stats           Show database statistics"
    echo "  cleanup         Clean up old data"
    echo "  indexes         Create performance indexes"
    echo "  help            Show this help message"
    echo
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        backup)
            backup_database
            ;;
        seed)
            seed_test_data
            ;;
        health)
            check_database_health
            ;;
        stats)
            show_statistics
            ;;
        cleanup)
            cleanup_old_data
            ;;
        indexes)
            create_indexes
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
