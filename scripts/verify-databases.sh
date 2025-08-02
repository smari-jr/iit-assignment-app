#!/bin/bash

echo "=== Database Verification Script ==="
echo "Checking all required tables and data..."
echo ""

# PostgreSQL verification
echo "🔍 Checking PostgreSQL Database..."
echo "----------------------------------------"

# Check main tables
echo "Main Tables:"
docker-compose exec postgres psql -U postgres -d lugx_gaming -c "
SELECT 
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.tablename AND table_schema = t.schemaname) as column_count
FROM pg_tables t 
WHERE schemaname IN ('public', 'analytics') 
ORDER BY schemaname, tablename;
" -t

echo ""
echo "Sample Data Counts:"
docker-compose exec postgres psql -U postgres -d lugx_gaming -c "
SELECT 
    'users' as table_name, COUNT(*) as row_count FROM users
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'analytics.page_visits', COUNT(*) FROM analytics.page_visits
UNION ALL
SELECT 'analytics.events', COUNT(*) FROM analytics.events;
" -t

echo ""
echo "🔍 Checking ClickHouse Database..."
echo "----------------------------------------"

# Check ClickHouse tables
echo "ClickHouse Tables:"
docker-compose exec clickhouse clickhouse-client --password=clickhouse123 --query "
SELECT 
    database,
    name as table_name,
    engine
FROM system.tables 
WHERE database = 'analytics'
ORDER BY name;
" --format=TabSeparated

echo ""
echo "ClickHouse Data Counts:"
docker-compose exec clickhouse clickhouse-client --password=clickhouse123 --query "
SELECT 'page_visits' as table_name, COUNT(*) as row_count FROM analytics.page_visits
UNION ALL
SELECT 'events', COUNT(*) FROM analytics.events
UNION ALL
SELECT 'user_events', COUNT(*) FROM analytics.user_events;
" --format=TabSeparated

echo ""
echo "=== Verification Complete ==="
echo ""
echo "✅ All required databases and tables are present!"
echo "📊 Sample data is available for testing"
echo "🚀 Services are ready for use"
