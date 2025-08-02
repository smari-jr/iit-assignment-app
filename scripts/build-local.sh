#!/bin/bash

# LUGX Gaming - Local Development Build Script
# Simple build and test script for all services

set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the project root (parent directory of scripts)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Script directory: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🎮 LUGX Gaming - Local Build${NC}"
echo -e "${YELLOW}Building all services locally...${NC}"

# Check if we're in the right directory
if [[ ! -d "$PROJECT_ROOT/services" ]]; then
    echo -e "${RED}❌ Services directory not found at $PROJECT_ROOT/services${NC}"
    echo -e "${YELLOW}Current project root: $PROJECT_ROOT${NC}"
    exit 1
fi

# Check Docker
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker not running${NC}"
    exit 1
fi

# Clean up function
cleanup() {
    echo -e "\n${YELLOW}🧹 Stopping services...${NC}"
    docker-compose -f "$PROJECT_ROOT/docker-compose.local.yml" down -v 2>/dev/null || true
    docker system prune -f >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Build images
echo -e "${BLUE}🏗️ Building services...${NC}"
services=("frontend" "gaming-service" "order-service" "analytics-service")

for service in "${services[@]}"; do
    echo -e "${YELLOW}Building $service...${NC}"
    
    # Check if service directory exists
    if [[ ! -d "$PROJECT_ROOT/services/$service" ]]; then
        echo -e "${RED}❌ Service directory not found: $PROJECT_ROOT/services/$service${NC}"
        continue
    fi
    
    # Check if Dockerfile exists
    if [[ ! -f "$PROJECT_ROOT/services/$service/Dockerfile" ]]; then
        echo -e "${RED}❌ Dockerfile not found in: $PROJECT_ROOT/services/$service${NC}"
        continue
    fi
    
    # Build with error handling
    if docker build -t lugx-$service:local "$PROJECT_ROOT/services/$service/" > /tmp/docker-build-$service.log 2>&1; then
        echo -e "${GREEN}✅ $service${NC}"
    else
        echo -e "${RED}❌ Failed to build $service${NC}"
        echo -e "${YELLOW}Build log:${NC}"
        tail -n 10 /tmp/docker-build-$service.log
        exit 1
    fi
done

# Create simple docker-compose
cat > "$PROJECT_ROOT/docker-compose.local.yml" << 'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: lugx_gaming
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres123
    ports: ["5432:5432"]

  clickhouse:
    image: clickhouse/clickhouse-server:23
    environment:
      CLICKHOUSE_PASSWORD: clickhouse123
    ports: ["8123:8123"]

  gaming-service:
    image: lugx-gaming-service:local
    ports: ["3001:3000"]
    environment:
      DATABASE_URL: postgresql://postgres:postgres123@postgres:5432/lugx_gaming
    depends_on: [postgres]

  order-service:
    image: lugx-order-service:local
    ports: ["3002:3000"]
    environment:
      DATABASE_URL: postgresql://postgres:postgres123@postgres:5432/lugx_gaming
    depends_on: [postgres]

  analytics-service:
    image: lugx-analytics-service:local
    ports: ["3003:3000"]
    environment:
      DATABASE_URL: postgresql://postgres:postgres123@postgres:5432/lugx_gaming
      CLICKHOUSE_URL: http://clickhouse:8123
    depends_on: [postgres, clickhouse]

  frontend:
    image: lugx-frontend:local
    ports: ["3000:80"]
    depends_on: [gaming-service, order-service, analytics-service]
EOF

# Start services
echo -e "${BLUE}🚀 Starting services...${NC}"
if ! docker-compose -f "$PROJECT_ROOT/docker-compose.local.yml" up -d; then
    echo -e "${RED}❌ Failed to start services${NC}"
    echo -e "${YELLOW}Docker-compose logs:${NC}"
    docker-compose -f "$PROJECT_ROOT/docker-compose.local.yml" logs
    exit 1
fi

# Wait and test
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
for i in {1..15}; do
    echo -n "."
    sleep 1
done
echo ""

# Simple endpoint tests
echo -e "${BLUE}🧪 Testing endpoints...${NC}"

# Test Frontend
echo -n "  Frontend (port 3000): "
if curl -s --max-time 5 http://localhost:3000 >/dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test Gaming Service
echo -n "  Gaming Service (port 3001): "
if curl -s --max-time 5 http://localhost:3001/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test Order Service
echo -n "  Order Service (port 3002): "
if curl -s --max-time 5 http://localhost:3002/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

# Test Analytics Service
echo -n "  Analytics Service (port 3003): "
if curl -s --max-time 5 http://localhost:3003/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

echo -e "\n${GREEN}🎉 Services running!${NC}"
echo -e "${BLUE}Access URLs:${NC}"
echo -e "  Frontend:    ${YELLOW}http://localhost:3000${NC}"
echo -e "  Gaming API:  ${YELLOW}http://localhost:3001${NC}"
echo -e "  Order API:   ${YELLOW}http://localhost:3002${NC}"
echo -e "  Analytics:   ${YELLOW}http://localhost:3003${NC}"

echo -e "\n${BLUE}Running containers:${NC}"
docker-compose -f "$PROJECT_ROOT/docker-compose.local.yml" ps

echo -e "\n${YELLOW}Press Ctrl+C to stop${NC}"
docker-compose -f "$PROJECT_ROOT/docker-compose.local.yml" logs -f
