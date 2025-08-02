#!/bin/bash

# Repository Cleanup Script for EKS Deployment
# This script removes unnecessary files and cleans up the repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Files and directories to remove
CLEANUP_ITEMS=(
    # Documentation files (keep essential ones)
    "502_ERROR_FIXED.md"
    "GAMING_SCENARIO.md" 
    "IMPLEMENTATION_COMPLETE.md"
    "TESTING_GUIDE.md"
    
    # Development files
    "docker-compose.local.yml"
    "setup-analytics.sh"
    "start.sh"
    
    # Database setup scripts (keep for reference but not needed in production)
    "scripts/database-setup-complete.sh"
    "scripts/verify-databases.sh"
    
    # Duplicate Kubernetes directories
    "k8s/"
    
    # Development artifacts
    "image_uris.env"
    
    # GitHub workflows (optional - comment out if you want to keep CI/CD)
    ".github/"
)

# Create backup of important files
create_backup() {
    print_status "Creating backup of important files..."
    
    mkdir -p backup
    
    # Backup docker-compose for local development reference
    if [ -f "docker-compose.yml" ]; then
        cp docker-compose.yml backup/
        print_status "Backed up docker-compose.yml"
    fi
    
    # Backup README
    if [ -f "README.md" ]; then
        cp README.md backup/
        print_status "Backed up README.md"
    fi
    
    print_success "Backup created in backup/ directory"
}

# Clean up unnecessary files
cleanup_files() {
    print_status "Starting repository cleanup..."
    
    for item in "${CLEANUP_ITEMS[@]}"; do
        if [ -f "$item" ] || [ -d "$item" ]; then
            print_status "Removing: $item"
            rm -rf "$item"
        else
            print_warning "Item not found: $item"
        fi
    done
    
    print_success "File cleanup completed"
}

# Update .gitignore for production deployment
update_gitignore() {
    print_status "Updating .gitignore for production deployment..."
    
    cat >> .gitignore << EOF

# EKS Deployment artifacts
image_uris.env
*.log
backup/

# Production secrets (never commit these)
kustomize/overlays/prod/secrets.yaml
*.pem
*.key

# Local development
docker-compose.override.yml
.env.local
EOF

    print_success "Updated .gitignore"
}

# Create production-ready README
create_production_readme() {
    print_status "Creating production-ready README..."
    
    cat > README.md << 'EOF'
# Gaming Microservices - EKS Deployment

A cloud-native gaming platform built with microservices architecture, designed for deployment on Amazon EKS.

## Architecture

- **Frontend**: React-based web application served via Nginx
- **Gaming Service**: Product catalog and gaming content management
- **Order Service**: Order processing and management
- **Analytics Service**: Real-time analytics and reporting
- **Databases**: PostgreSQL for transactional data, ClickHouse for analytics

## Prerequisites

- Amazon EKS cluster
- AWS CLI configured
- kubectl configured for your EKS cluster
- Docker installed (for building images)
- Kustomize

## Quick Start

### 1. Push Images to ECR

```bash
# Set your AWS account ID and region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-west-2

# Build and push images to ECR
./scripts/push-to-ecr.sh
```

### 2. Deploy to EKS

```bash
# Deploy using Kustomize
kubectl apply -k kustomize/base/

# Check deployment status
kubectl get pods -n gaming-microservices
kubectl get services -n gaming-microservices
```

### 3. Access the Application

```bash
# Get ingress URL
kubectl get ingress -n gaming-microservices

# Port forward for local access (development)
kubectl port-forward svc/frontend-service 8080:80 -n gaming-microservices
```

## Configuration

Update the configuration in `kustomize/base/config.yaml` for your environment:

- Database credentials
- JWT secrets
- External service URLs
- Resource limits

## Monitoring

The application includes health checks and is ready for monitoring with:
- Prometheus metrics
- Kubernetes liveness/readiness probes
- Centralized logging

## Scaling

Scale services based on load:

```bash
kubectl scale deployment gaming-service --replicas=5 -n gaming-microservices
kubectl scale deployment order-service --replicas=3 -n gaming-microservices
```

## Support

For deployment issues, check:
1. Pod logs: `kubectl logs <pod-name> -n gaming-microservices`
2. Service status: `kubectl get svc -n gaming-microservices`
3. Ingress configuration: `kubectl describe ingress -n gaming-microservices`
EOF

    print_success "Created production-ready README.md"
}

# Create deployment checklist
create_deployment_checklist() {
    print_status "Creating deployment checklist..."
    
    cat > DEPLOYMENT_CHECKLIST.md << 'EOF'
# EKS Deployment Checklist

## Pre-deployment

- [ ] EKS cluster is running and accessible
- [ ] AWS CLI configured with appropriate permissions
- [ ] kubectl configured for your EKS cluster
- [ ] ECR repositories exist or will be created
- [ ] Load Balancer Controller installed (for ingress)

## Build and Push Images

- [ ] Run `./scripts/push-to-ecr.sh`
- [ ] Verify all images pushed successfully
- [ ] Check that kustomization.yaml was updated with ECR URIs

## Deploy Application

- [ ] Review configuration in `kustomize/base/config.yaml`
- [ ] Update secrets with production values
- [ ] Run `kubectl apply -k kustomize/base/`
- [ ] Verify all pods are running: `kubectl get pods -n gaming-microservices`

## Post-deployment Verification

- [ ] All services are running and healthy
- [ ] Database connections are working
- [ ] Frontend is accessible
- [ ] API endpoints respond correctly
- [ ] Analytics service is collecting data

## Production Readiness

- [ ] Configure monitoring and alerting
- [ ] Set up backup procedures for databases
- [ ] Configure auto-scaling policies
- [ ] Set up CI/CD pipeline
- [ ] Review security settings and network policies

## Troubleshooting

Common issues and solutions:

1. **Pods not starting**: Check resource limits and node capacity
2. **Database connection errors**: Verify service discovery and credentials
3. **Ingress not working**: Ensure Load Balancer Controller is installed
4. **Image pull errors**: Check ECR permissions and image URIs
EOF

    print_success "Created DEPLOYMENT_CHECKLIST.md"
}

# Main execution
main() {
    echo "======================================="
    echo "  Repository Cleanup for EKS"
    echo "======================================="
    echo ""
    
    print_status "Starting cleanup process..."
    
    create_backup
    cleanup_files
    update_gitignore
    create_production_readme
    create_deployment_checklist
    
    echo ""
    echo "======================================="
    print_success "Repository cleanup completed!"
    echo "======================================="
    echo ""
    print_status "Repository is now ready for EKS deployment"
    print_status "Next steps:"
    echo "1. Review DEPLOYMENT_CHECKLIST.md"
    echo "2. Run ./scripts/push-to-ecr.sh to build and push images"
    echo "3. Deploy with: kubectl apply -k kustomize/base/"
    echo ""
    print_status "Backup of original files created in backup/ directory"
}

# Run main function
main "$@"
