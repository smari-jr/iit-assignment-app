#!/bin/bash

# LUGX Gaming Platform - Setup Script
# This script sets up the development environment and prerequisites

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${BLUE}"
    echo "================================================="
    echo "  LUGX Gaming Platform - Environment Setup     "
    echo "================================================="
    echo -e "${NC}"
}

check_requirements() {
    echo -e "${BLUE}🔍 Checking system requirements...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
        echo "   Visit: https://docs.docker.com/get-docker/"
        exit 1
    else
        echo -e "${GREEN}✅ Docker found: $(docker --version)${NC}"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}⚠️ Docker Compose not found, checking if it's built into Docker...${NC}"
        if ! docker compose version &> /dev/null; then
            echo -e "${RED}❌ Docker Compose is not available. Please install Docker Compose.${NC}"
            exit 1
        else
            echo -e "${GREEN}✅ Docker Compose (built-in) found${NC}"
        fi
    else
        echo -e "${GREEN}✅ Docker Compose found: $(docker-compose --version)${NC}"
    fi
    
    # Check kubectl (optional)
    if ! command -v kubectl &> /dev/null; then
        echo -e "${YELLOW}⚠️ kubectl not found (optional for local development)${NC}"
        echo "   To deploy to Kubernetes, install kubectl: https://kubernetes.io/docs/tasks/tools/"
    else
        echo -e "${GREEN}✅ kubectl found: $(kubectl version --client --short 2>/dev/null || echo 'version check failed')${NC}"
    fi
    
    # Check kustomize (optional)
    if ! command -v kustomize &> /dev/null; then
        echo -e "${YELLOW}⚠️ kustomize not found (optional for local development)${NC}"
        echo "   To work with Kubernetes manifests, install kustomize: https://kustomize.io/"
    else
        echo -e "${GREEN}✅ kustomize found: $(kustomize version --short 2>/dev/null || echo 'version check failed')${NC}"
    fi
    
    # Check AWS CLI (optional)
    if ! command -v aws &> /dev/null; then
        echo -e "${YELLOW}⚠️ AWS CLI not found (optional for local development)${NC}"
        echo "   To interact with AWS services, install AWS CLI: https://aws.amazon.com/cli/"
    else
        echo -e "${GREEN}✅ AWS CLI found: $(aws --version 2>&1 | head -1)${NC}"
    fi
    
    # Check Node.js (for service development)
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}⚠️ Node.js not found (needed for service development)${NC}"
        echo "   Install Node.js: https://nodejs.org/"
    else
        echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        echo -e "${YELLOW}⚠️ npm not found (needed for service development)${NC}"
    else
        echo -e "${GREEN}✅ npm found: $(npm --version)${NC}"
    fi
}

setup_permissions() {
    echo -e "${BLUE}🔧 Setting up script permissions...${NC}"
    
    # Make dev helper script executable
    if [ -f "scripts/dev-helper.sh" ]; then
        chmod +x scripts/dev-helper.sh
        echo -e "${GREEN}✅ Made dev-helper.sh executable${NC}"
    fi
    
    # Make this setup script executable
    chmod +x scripts/setup.sh 2>/dev/null || true
}

create_env_files() {
    echo -e "${BLUE}📝 Creating environment configuration files...${NC}"
    
    # Create .env.example file
    cat > .env.example << 'EOF'
# LUGX Gaming Platform - Environment Variables
# Copy this file to .env and update the values

# Database Configuration
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/lugx_gaming_dev
POSTGRES_DB=lugx_gaming_dev
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# ClickHouse Configuration
CLICKHOUSE_URL=http://localhost:8123
CLICKHOUSE_DB=lugx_analytics_dev

# Service URLs (for frontend)
REACT_APP_GAMING_SERVICE_URL=http://localhost:3001
REACT_APP_ORDER_SERVICE_URL=http://localhost:3002
REACT_APP_ANALYTICS_SERVICE_URL=http://localhost:3003

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRES_IN=24h

# Redis Configuration (if needed)
REDIS_URL=redis://localhost:6379

# AWS Configuration (for production)
AWS_REGION=ap-southeast-1
ECR_REGISTRY=036160411895.dkr.ecr.ap-southeast-1.amazonaws.com
EKS_CLUSTER_NAME=lugx-gaming-cluster

# Environment
NODE_ENV=development
PORT=3000
EOF
    
    echo -e "${GREEN}✅ Created .env.example file${NC}"
    
    # Check if .env exists, create if not
    if [ ! -f ".env" ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ Created .env file from template${NC}"
        echo -e "${YELLOW}⚠️ Please review and update .env file with your specific values${NC}"
    else
        echo -e "${YELLOW}⚠️ .env file already exists, skipping...${NC}"
    fi
}

install_service_dependencies() {
    echo -e "${BLUE}📦 Installing service dependencies...${NC}"
    
    services=("frontend" "gaming-service" "order-service" "analytics-service")
    
    for service in "${services[@]}"; do
        if [ -d "services/$service" ]; then
            echo -e "${YELLOW}📦 Installing dependencies for $service...${NC}"
            cd "services/$service"
            
            if [ -f "package.json" ]; then
                npm install
                echo -e "${GREEN}✅ Dependencies installed for $service${NC}"
            else
                echo -e "${YELLOW}⚠️ No package.json found for $service${NC}"
            fi
            
            cd ../..
        else
            echo -e "${YELLOW}⚠️ Service directory services/$service not found${NC}"
        fi
    done
}

create_docker_ignore() {
    echo -e "${BLUE}🐳 Creating .dockerignore files...${NC}"
    
    # Global .dockerignore
    cat > .dockerignore << 'EOF'
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.env.local
.env.development
.env.test
.env.production
coverage
.nyc_output
*.log
.DS_Store
EOF
    
    echo -e "${GREEN}✅ Created global .dockerignore${NC}"
}

setup_git_hooks() {
    echo -e "${BLUE}🔀 Setting up git hooks (optional)...${NC}"
    
    if [ -d ".git" ]; then
        # Create pre-commit hook
        cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for LUGX Gaming Platform

echo "Running pre-commit checks..."

# Check if any service files were modified
if git diff --cached --name-only | grep -q "services/"; then
    echo "Service files modified, you may want to run tests..."
    echo "Run: ./scripts/dev-helper.sh test"
fi

# Check for secrets in staged files
if git diff --cached --name-only | xargs grep -l "password\|secret\|key" 2>/dev/null; then
    echo "⚠️ WARNING: Potential secrets detected in staged files"
    echo "Please review before committing"
fi

echo "Pre-commit checks completed"
EOF
        
        chmod +x .git/hooks/pre-commit
        echo -e "${GREEN}✅ Created git pre-commit hook${NC}"
    else
        echo -e "${YELLOW}⚠️ Not a git repository, skipping git hooks${NC}"
    fi
}

create_makefile() {
    echo -e "${BLUE}📋 Creating Makefile for common tasks...${NC}"
    
    cat > Makefile << 'EOF'
# LUGX Gaming Platform - Makefile
# Common development tasks

.PHONY: help build test dev push clean status logs local-build local-test

help: ## Show this help message
	@echo "LUGX Gaming Platform - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Local Development
local-build: ## Build all Docker images locally
	@./scripts/build-local.sh

local-test: ## Build and run all services locally for testing
	@./scripts/local-test.sh

build: ## Build all Docker images
	@./scripts/dev-helper.sh build all

test: ## Run tests for all services
	@./scripts/dev-helper.sh test all

dev: ## Start development environment
	@./scripts/dev-helper.sh dev

push: ## Build and push all images to ECR
	@./scripts/dev-helper.sh push all

clean: ## Clean up Docker resources
	@./scripts/dev-helper.sh clean

status: ## Show status of all services
	@./scripts/dev-helper.sh status

logs: ## Show logs for all services
	@./scripts/dev-helper.sh logs all

kustomize-dev: ## Apply dev Kustomize configuration
	@./scripts/dev-helper.sh kustomize-dev

kustomize-prod: ## Apply prod Kustomize configuration
	@./scripts/dev-helper.sh kustomize-prod

setup: ## Run the setup script
	@./scripts/setup.sh
EOF
    
    echo -e "${GREEN}✅ Created Makefile${NC}"
}

print_completion_message() {
    echo ""
    echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Review and update ${YELLOW}.env${NC} file with your configuration"
    echo -e "2. For quick local testing: ${YELLOW}./scripts/local-test.sh${NC}"
    echo -e "3. Or just build images: ${YELLOW}./scripts/build-local.sh${NC}"
    echo -e "4. Start development environment: ${YELLOW}./scripts/dev-helper.sh dev${NC}"
    echo -e "5. Or use Make commands: ${YELLOW}make dev${NC}"
    echo -e "6. Check status anytime: ${YELLOW}make status${NC}"
    echo ""
    echo -e "${BLUE}Available commands:${NC}"
    echo -e "  ${YELLOW}make help${NC}           - Show all available commands"
    echo -e "  ${YELLOW}make local-build${NC}    - Build Docker images locally"
    echo -e "  ${YELLOW}make local-test${NC}     - Run full local test environment"
    echo -e "  ${YELLOW}make build${NC}          - Build all services"
    echo -e "  ${YELLOW}make test${NC}           - Run tests"
    echo -e "  ${YELLOW}make dev${NC}            - Start development environment"
    echo -e "  ${YELLOW}make status${NC}         - Show services status"
    echo ""
    echo -e "${BLUE}For Kubernetes deployment:${NC}"
    echo -e "  ${YELLOW}make kustomize-dev${NC}  - Deploy to dev environment"
    echo -e "  ${YELLOW}make kustomize-prod${NC} - Deploy to prod environment"
    echo ""
    echo -e "${GREEN}Happy coding! 🚀${NC}"
}

# Main execution
main() {
    print_banner
    check_requirements
    setup_permissions
    create_env_files
    create_docker_ignore
    create_makefile
    
    # Optional setups
    read -p "Install service dependencies? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_service_dependencies
    fi
    
    read -p "Setup git hooks? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_git_hooks
    fi
    
    print_completion_message
}

# Run main function
main "$@"
