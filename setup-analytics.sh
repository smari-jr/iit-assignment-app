#!/bin/bash

# Analytics Database Setup Script
# This script sets up the complete analytics database structure

echo "🚀 Setting up Analytics Database..."

# Check if PostgreSQL container is running
if ! docker ps | grep -q microservices_postgres_1; then
    echo "❌ PostgreSQL container is not running. Please start your services first with:"
    echo "   docker-compose up -d"
    exit 1
fi

echo "📊 Creating analytics tables in PostgreSQL..."

# Run the analytics setup SQL script
docker exec -i microservices_postgres_1 psql -U postgres -d lugx_gaming < database/setup-analytics.sql

if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL analytics setup completed successfully!"
else
    echo "❌ PostgreSQL setup failed!"
    exit 1
fi

# Check ClickHouse setup (optional)
if docker ps | grep -q microservices_clickhouse_1; then
    echo "🔄 ClickHouse detected, setting up analytics tables..."
    
    # Note: ClickHouse setup would go here when needed
    echo "ℹ️  ClickHouse setup is available but not automated in this script"
    echo "   See setup-analytics.sql for ClickHouse commands"
fi

echo ""
echo "🎉 Analytics Database Setup Complete!"
echo ""
echo "📈 Analytics Features Available:"
echo "   ✅ Page Visit Tracking"
echo "   ✅ Click Event Tracking"
echo "   ✅ Scroll Depth Tracking"
echo "   ✅ Session Management"
echo "   ✅ Custom Event Tracking"
echo ""
echo "🌐 Access your application:"
echo "   Frontend: http://localhost:3000"
echo "   Gaming Service: http://localhost:3001"
echo "   Order Service: http://localhost:3002"
echo "   Analytics Service: http://localhost:3003"
echo ""
echo "📊 Test Analytics Endpoints:"
echo "   curl http://localhost:3003/health"
echo "   curl http://localhost:3003/analytics/dashboard"
echo ""
