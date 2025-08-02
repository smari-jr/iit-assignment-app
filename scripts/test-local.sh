#!/bin/bash

# Local testing script for gaming microservices
# This script builds and runs all services locally using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites for local testing..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker not found. Please install Docker."
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose not found. Please install Docker Compose."
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        error "Docker is not running. Please start Docker."
    fi
    
    log "Prerequisites check passed!"
}

# Clean up previous containers
cleanup() {
    log "Cleaning up previous containers..."
    docker-compose -f docker-compose.local.yml down -v 2>/dev/null || true
    docker system prune -f 2>/dev/null || true
    log "Cleanup completed!"
}

# Build all services
build_services() {
    log "Building all microservices..."
    
    # Build each service individually to show progress
    log "Building frontend service..."
    docker-compose -f docker-compose.local.yml build frontend
    
    log "Building gaming service..."
    docker-compose -f docker-compose.local.yml build gaming-service
    
    log "Building order service..."
    docker-compose -f docker-compose.local.yml build order-service
    
    log "Building analytics service..."
    docker-compose -f docker-compose.local.yml build analytics-service
    
    log "All services built successfully!"
}

# Start all services
start_services() {
    log "Starting all services..."
    docker-compose -f docker-compose.local.yml up -d
    
    # Wait a moment for services to start
    sleep 5
    
    log "Services started! Checking status..."
    docker-compose -f docker-compose.local.yml ps
}

# Wait for services to be healthy
wait_for_services() {
    log "Waiting for services to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "Health check attempt $attempt/$max_attempts..."
        
        # Check each service health endpoint
        if curl -s http://localhost:3001/health > /dev/null 2>&1; then
            log "✅ Gaming service is healthy"
        else
            warn "Gaming service not ready yet..."
        fi
        
        if curl -s http://localhost:3002/health > /dev/null 2>&1; then
            log "✅ Order service is healthy"
        else
            warn "Order service not ready yet..."
        fi
        
        if curl -s http://localhost:3003/health > /dev/null 2>&1; then
            log "✅ Analytics service is healthy"
        else
            warn "Analytics service not ready yet..."
        fi
        
        if curl -s http://localhost:8080/health > /dev/null 2>&1; then
            log "✅ Frontend service is healthy"
        else
            warn "Frontend service not ready yet..."
        fi
        
        # Check if all services are healthy
        if curl -s http://localhost:3001/health > /dev/null 2>&1 && \
           curl -s http://localhost:3002/health > /dev/null 2>&1 && \
           curl -s http://localhost:3003/health > /dev/null 2>&1 && \
           curl -s http://localhost:8080/health > /dev/null 2>&1; then
            log "🎉 All services are healthy!"
            break
        fi
        
        sleep 5
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        warn "Some services may not be fully ready. Check logs with: docker-compose -f docker-compose.local.yml logs"
    fi
}

# Test API endpoints
test_endpoints() {
    log "Testing API endpoints..."
    
    # Test gaming service endpoints
    log "Testing Gaming Service..."
    echo "Health check: $(curl -s http://localhost:3001/health | jq -r '.status' 2>/dev/null || echo 'Failed')"
    echo "Products endpoint: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3001/api/products)"
    
    # Test order service endpoints  
    log "Testing Order Service..."
    echo "Health check: $(curl -s http://localhost:3002/health | jq -r '.status' 2>/dev/null || echo 'Failed')"
    echo "Orders endpoint: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3002/api/orders)"
    
    # Test analytics service endpoints
    log "Testing Analytics Service..."
    echo "Health check: $(curl -s http://localhost:3003/health | jq -r '.status' 2>/dev/null || echo 'Failed')"
    echo "Analytics endpoint: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3003/analytics/track)"
    
    # Test frontend
    log "Testing Frontend..."
    echo "Frontend status: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080)"
    
    log "API testing completed!"
}

# Show service URLs
show_urls() {
    log "🌐 Service URLs:"
    echo "Frontend:         http://localhost:8080"
    echo "Gaming Service:   http://localhost:3001"
    echo "Order Service:    http://localhost:3002"
    echo "Analytics Service: http://localhost:3003"
    echo ""
    echo "Health Endpoints:"
    echo "Gaming:    http://localhost:3001/health"
    echo "Orders:    http://localhost:3002/health"  
    echo "Analytics: http://localhost:3003/health"
    echo "Frontend:  http://localhost:8080/health"
    echo ""
    echo "Database Connections:"
    echo "PostgreSQL: localhost:5432 (user: postgres, password: postgres123)"
    echo "ClickHouse: localhost:8123"
}

# Show logs
show_logs() {
    log "Recent logs from all services:"
    docker-compose -f docker-compose.local.yml logs --tail=10
}

# Main testing flow
main() {
    log "🚀 Starting local microservices testing..."
    
    check_prerequisites
    cleanup
    build_services
    start_services
    wait_for_services
    test_endpoints
    show_urls
    
    log "🎉 Local testing setup complete!"
    log "💡 Use 'docker-compose -f docker-compose.local.yml logs -f [service]' to view logs"
    log "💡 Use 'docker-compose -f docker-compose.local.yml down' to stop all services"
}

# Handle script arguments
case "${1:-start}" in
    "build")
        check_prerequisites
        build_services
        ;;
    "start")
        check_prerequisites
        start_services
        wait_for_services
        show_urls
        ;;
    "test")
        test_endpoints
        ;;
    "logs")
        show_logs
        ;;
    "urls")
        show_urls
        ;;
    "stop")
        log "Stopping all services..."
        docker-compose -f docker-compose.local.yml down
        ;;
    "cleanup")
        cleanup
        ;;
    "full"|*)
        main
        ;;
esac
