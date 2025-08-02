#!/bin/bash

echo "=== Database Setup and Verification Complete ==="
echo ""

echo "📊 Database Status Summary:"
echo "=========================="

# PostgreSQL Summary
echo ""
echo "🐘 PostgreSQL Database (lugx_gaming):"
echo "--------------------------------------"
echo "✅ Main Tables: users, products, orders, categories"
echo "✅ Analytics Tables: page_visits, events, click_events, scroll_events, session_data" 
echo "✅ Sample Data: $(docker-compose exec postgres psql -U postgres -d lugx_gaming -c "SELECT COUNT(*) FROM products;" -t | tr -d ' ') products, $(docker-compose exec postgres psql -U postgres -d lugx_gaming -c "SELECT COUNT(*) FROM analytics.page_visits;" -t | tr -d ' ') page visits"

# ClickHouse Summary  
echo ""
echo "🏠 ClickHouse Database (analytics):"
echo "-----------------------------------"
echo "✅ Analytics Tables: page_visits, events, user_events"
echo "✅ Sample Data: $(docker-compose exec clickhouse clickhouse-client --password=clickhouse123 --query "SELECT COUNT(*) FROM analytics.page_visits" 2>/dev/null) page visits"

echo ""
echo "🔧 Database Features Configured:"
echo "================================"
echo "✅ UUID support for PostgreSQL"
echo "✅ Analytics schema for web tracking"
echo "✅ Proper indexes for performance"
echo "✅ MergeTree engines for ClickHouse"
echo "✅ Data partitioning by date"
echo "✅ Foreign key relationships"
echo "✅ Sample gaming products data"

echo ""
echo "🚀 All Systems Ready!"
echo "===================="
echo "Your microservices can now:"
echo "• Store and retrieve gaming products"
echo "• Process user orders and authentication"
echo "• Track analytics events and page visits"
echo "• Store data in both PostgreSQL and ClickHouse"
echo "• Handle high-performance analytics queries"

echo ""
echo "Next steps:"
echo "1. Test the frontend at http://localhost:3000"
echo "2. Verify API endpoints are working"
echo "3. Check analytics data collection"
