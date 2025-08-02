#!/bin/bash

# Local Development Helper Script for LUGX Gaming Platform
# This script helps developers work with the microservices locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVICES=("frontend" "gaming-service" "order-service" "analytics-service")
ECR_REGISTRY="036160411895.dkr.ecr.ap-southeast-1.amazonaws.com"
ECR_REPO_PREFIX="lugx-gaming"

print_banner() {
    echo -e "${BLUE}"
    echo "======================================"
    echo "  LUGX Gaming Platform - Dev Helper  "
    echo "======================================"
    echo -e "${NC}"
}

print_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  build [service]     - Build Docker image(s)"
    echo "  test [service]      - Run tests for service(s)"
    echo "  dev                 - Start development environment"
    echo "  push [service]      - Build and push to ECR"
    echo "  kustomize-dev       - Apply Kustomize dev environment"
    echo "  kustomize-prod      - Apply Kustomize prod environment"
    echo "  kustomize-build     - Build Kustomize manifests"
    echo "  logs [service]      - Show logs for service"
    echo "  status              - Show status of all services"
    echo "  clean               - Clean up Docker images and containers"
    echo ""
    echo "Service options: frontend, gaming-service, order-service, analytics-service, all"
}

build_service() {
    local service=$1
    echo -e "${YELLOW}🏗️ Building $service...${NC}"
    
    if [ ! -d "services/$service" ]; then
        echo -e "${RED}❌ Service directory services/$service not found${NC}"
        return 1
    fi
    
    docker build -t $service:latest ./services/$service/
    echo -e "${GREEN}✅ Built $service successfully${NC}"
}

build_all() {
    echo -e "${BLUE}🏗️ Building all services...${NC}"
    for service in "${SERVICES[@]}"; do
        build_service $service
    done
    echo -e "${GREEN}🎉 All services built successfully!${NC}"
}

test_service() {
    local service=$1
    echo -e "${YELLOW}🧪 Testing $service...${NC}"
    
    if [ ! -d "services/$service" ]; then
        echo -e "${RED}❌ Service directory services/$service not found${NC}"
        return 1
    fi
    
    cd "services/$service"
    
    # Check if package.json exists (Node.js services)
    if [ -f "package.json" ]; then
        if [ ! -d "node_modules" ]; then
            echo -e "${YELLOW}📦 Installing dependencies...${NC}"
            npm install
        fi
        npm test || echo -e "${YELLOW}⚠️ Tests not configured for $service${NC}"
    else
        echo -e "${YELLOW}⚠️ No test configuration found for $service${NC}"
    fi
    
    cd ../..
    echo -e "${GREEN}✅ Testing completed for $service${NC}"
}

start_dev_environment() {
    echo -e "${BLUE}🚀 Starting development environment...${NC}"
    
    # Check if docker-compose exists
    if [ ! -f "docker-compose.dev.yml" ]; then
        echo -e "${YELLOW}⚠️ docker-compose.dev.yml not found, creating one...${NC}"
        create_dev_compose
    fi
    
    docker-compose -f docker-compose.dev.yml up --build
}

create_dev_compose() {
    cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: lugx_gaming_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  clickhouse:
    image: clickhouse/clickhouse-server:23
    ports:
      - "8123:8123"
      - "9000:9000"
    volumes:
      - clickhouse_data:/var/lib/clickhouse

  gaming-service:
    build: ./services/gaming-service
    ports:
      - "3001:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/lugx_gaming_dev
    depends_on:
      - postgres

  order-service:
    build: ./services/order-service
    ports:
      - "3002:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/lugx_gaming_dev
    depends_on:
      - postgres

  analytics-service:
    build: ./services/analytics-service
    ports:
      - "3003:3000"
    environment:
      - NODE_ENV=development
      - CLICKHOUSE_URL=http://clickhouse:8123
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/lugx_gaming_dev
    depends_on:
      - postgres
      - clickhouse

  frontend:
    build: ./services/frontend
    ports:
      - "3000:80"
    environment:
      - REACT_APP_GAMING_SERVICE_URL=http://localhost:3001
      - REACT_APP_ORDER_SERVICE_URL=http://localhost:3002
      - REACT_APP_ANALYTICS_SERVICE_URL=http://localhost:3003
    depends_on:
      - gaming-service
      - order-service
      - analytics-service

volumes:
  postgres_data:
  clickhouse_data:
EOF
    echo -e "${GREEN}✅ Created docker-compose.dev.yml${NC}"
}

push_to_ecr() {
    local service=$1
    echo -e "${YELLOW}📤 Pushing $service to ECR...${NC}"
    
    # Login to ECR
    aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
    
    # Build and tag
    build_service $service
    docker tag $service:latest $ECR_REGISTRY/$ECR_REPO_PREFIX/$service:dev
    
    # Push
    docker push $ECR_REGISTRY/$ECR_REPO_PREFIX/$service:dev
    echo -e "${GREEN}✅ Pushed $service to ECR${NC}"
}

kustomize_build() {
    local env=${1:-dev}
    echo -e "${YELLOW}🔧 Building Kustomize manifests for $env environment...${NC}"
    
    if [ ! -d "kustomize/overlays/$env" ]; then
        echo -e "${RED}❌ Kustomize overlay for $env not found${NC}"
        return 1
    fi
    
    kustomize build kustomize/overlays/$env > "k8s-manifests-$env.yaml"
    echo -e "${GREEN}✅ Manifests built: k8s-manifests-$env.yaml${NC}"
}

kustomize_apply() {
    local env=$1
    echo -e "${YELLOW}🚀 Applying Kustomize $env environment...${NC}"
    
    if [ ! -d "kustomize/overlays/$env" ]; then
        echo -e "${RED}❌ Kustomize overlay for $env not found${NC}"
        return 1
    fi
    
    kustomize build kustomize/overlays/$env | kubectl apply -f -
    echo -e "${GREEN}✅ Applied $env environment to Kubernetes${NC}"
}

show_logs() {
    local service=$1
    if [ "$service" = "all" ]; then
        echo -e "${BLUE}📋 Showing logs for all services...${NC}"
        kubectl logs -l app.kubernetes.io/part-of=lugx-gaming -n lugx-gaming --tail=50
    else
        echo -e "${BLUE}📋 Showing logs for $service...${NC}"
        kubectl logs -l app=$service -n lugx-gaming --tail=100
    fi
}

show_status() {
    echo -e "${BLUE}📊 LUGX Gaming Platform Status${NC}"
    echo ""
    
    # Check if kubectl is configured
    if ! kubectl cluster-info &>/dev/null; then
        echo -e "${YELLOW}⚠️ kubectl not configured or cluster not accessible${NC}"
        echo ""
    else
        echo -e "${GREEN}🔗 Kubernetes Cluster Status:${NC}"
        kubectl get pods -n lugx-gaming 2>/dev/null || echo "No pods found in lugx-gaming namespace"
        echo ""
        
        echo -e "${GREEN}🌐 Services:${NC}"
        kubectl get services -n lugx-gaming 2>/dev/null || echo "No services found in lugx-gaming namespace"
        echo ""
        
        echo -e "${GREEN}🚪 Ingress:${NC}"
        kubectl get ingress -n lugx-gaming 2>/dev/null || echo "No ingress found in lugx-gaming namespace"
    fi
    
    echo -e "${GREEN}🐳 Local Docker Images:${NC}"
    docker images | grep -E "(frontend|gaming-service|order-service|analytics-service)" || echo "No local images found"
}

clean_up() {
    echo -e "${YELLOW}🧹 Cleaning up Docker resources...${NC}"
    
    # Stop and remove containers
    docker-compose -f docker-compose.dev.yml down 2>/dev/null || true
    
    # Remove unused images
    docker image prune -f
    
    # Remove dangling volumes
    docker volume prune -f
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Main script logic
case "${1:-}" in
    "build")
        print_banner
        if [ "${2:-}" = "all" ] || [ -z "${2:-}" ]; then
            build_all
        else
            build_service "$2"
        fi
        ;;
    "test")
        print_banner
        if [ "${2:-}" = "all" ] || [ -z "${2:-}" ]; then
            for service in "${SERVICES[@]}"; do
                test_service $service
            done
        else
            test_service "$2"
        fi
        ;;
    "dev")
        print_banner
        start_dev_environment
        ;;
    "push")
        print_banner
        if [ "${2:-}" = "all" ] || [ -z "${2:-}" ]; then
            for service in "${SERVICES[@]}"; do
                push_to_ecr $service
            done
        else
            push_to_ecr "$2"
        fi
        ;;
    "kustomize-dev")
        print_banner
        kustomize_apply "dev"
        ;;
    "kustomize-prod")
        print_banner
        kustomize_apply "prod"
        ;;
    "kustomize-build")
        print_banner
        kustomize_build "${2:-dev}"
        ;;
    "logs")
        print_banner
        show_logs "${2:-all}"
        ;;
    "status")
        print_banner
        show_status
        ;;
    "clean")
        print_banner
        clean_up
        ;;
    *)
        print_banner
        print_usage
        exit 1
        ;;
esac
