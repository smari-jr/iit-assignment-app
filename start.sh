#!/bin/bash

# LUGX Gaming Microservices - Simple Start Script

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 LUGX Gaming Microservices Platform${NC}"
echo "========================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo -e "${GREEN}✅ Docker is running${NC}"

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed"
    exit 1
fi

echo -e "${GREEN}✅ docker-compose is available${NC}"
echo ""

# Start the services
echo "Starting all services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service status
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "🌐 Application URLs:"
echo "  Frontend:         http://localhost:3000"
echo "  Gaming Service:   http://localhost:3001"
echo "  Order Service:    http://localhost:3002"
echo "  Analytics Service: http://localhost:3003"
echo "  PostgreSQL:       localhost:5432"
echo "  ClickHouse:       localhost:8123"
echo ""
echo "📋 Useful Commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop services: docker-compose down"
echo "  Rebuild: docker-compose up -d --build"
echo ""
echo -e "${GREEN}🎮 LUGX Gaming Platform is ready!${NC}"
