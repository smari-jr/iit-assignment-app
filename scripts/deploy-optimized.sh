#!/bin/bash

# Comprehensive deployment script for gaming microservices
# This script builds, pushes to ECR, and deploys to Kubernetes

set -e

# Configuration
REGION="ap-southeast-1"
ECR_REGISTRY="036160411895.dkr.ecr.ap-southeast-1.amazonaws.com"
NAMESPACE="gaming-microservices"
REPO_PREFIX="gaming-microservices"

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
    echo -e "${RED}Current directory: $(pwd)${NC}"
    echo -e "${RED}Required structure:${NC}"
    echo -e "${RED}  - services/frontend/${NC}"
    echo -e "${RED}  - services/gaming-service/${NC}"
    echo -e "${RED}  - services/order-service/${NC}"
    echo -e "${RED}  - services/analytics-service/${NC}"
    echo -e "${RED}  - kustomize/base/${NC}"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -d "services" ]]; then
        error "Services directory not found. Please run this script from the project root directory."
    fi
    
    # Check if all service directories exist
    local services=("frontend" "gaming-service" "order-service" "analytics-service")
    for service in "${services[@]}"; do
        if [[ ! -d "services/${service}" ]]; then
            error "Service directory 'services/${service}' not found."
        fi
        if [[ ! -f "services/${service}/Dockerfile" ]]; then
            error "Dockerfile not found in 'services/${service}/'."
        fi
    done
    
    # Check if kustomize directory exists
    if [[ ! -d "kustomize/base" ]]; then
        error "Kustomize directory 'kustomize/base' not found."
    fi
    
    if ! command -v aws &> /dev/null; then
        error "AWS CLI not found. Please install AWS CLI."
    fi
    
    if ! command -v docker &> /dev/null; then
        error "Docker not found. Please install Docker."
    fi
    
    # Check Docker permissions
    if ! docker ps &> /dev/null; then
        error "Docker permission denied. Please run: sudo usermod -aG docker \$USER && newgrp docker"
    fi
    
    if ! command -v kubectl &> /dev/null; then
        error "kubectl not found. Please install kubectl."
    fi
    
    if ! command -v kustomize &> /dev/null; then
        error "kustomize not found. Please install kustomize."
    fi
    
    log "Prerequisites check passed!"
}

# Generate image tag
generate_image_tag() {
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        local git_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "nogit")
        echo "v${timestamp}-${git_hash}"
    else
        echo "v${timestamp}"
    fi
}

# Build and push images
build_and_push() {
    local service=$1
    local tag=$(generate_image_tag)
    local image_name="${ECR_REGISTRY}/${REPO_PREFIX}/${service}"
    
    log "Building ${service} with tag ${tag}..."
    
    # Verify service directory exists
    if [[ ! -d "services/${service}" ]]; then
        error "Service directory 'services/${service}' not found"
    fi
    
    if [[ ! -f "services/${service}/Dockerfile" ]]; then
        error "Dockerfile not found in 'services/${service}/'"
    fi
    
    # Build the image
    if ! docker build -t "${service}:${tag}" -t "${service}:latest" "services/${service}/"; then
        error "Failed to build ${service}"
    fi
    
    # Tag for ECR
    docker tag "${service}:${tag}" "${image_name}:${tag}"
    docker tag "${service}:latest" "${image_name}:latest"
    
    # Push to ECR
    log "Pushing ${service} to ECR..."
    if ! docker push "${image_name}:${tag}"; then
        error "Failed to push ${service}:${tag} to ECR"
    fi
    
    if ! docker push "${image_name}:latest"; then
        error "Failed to push ${service}:latest to ECR"
    fi
    
    log "Successfully pushed ${service}:${tag}"
    echo "${tag}"
}

# Update kustomization with new image tags
update_kustomization() {
    local frontend_tag=$1
    local gaming_tag=$2
    local order_tag=$3
    local analytics_tag=$4
    
    log "Updating kustomization.yaml with new image tags..."
    
    # Create a backup
    cp kustomize/base/kustomization.yaml kustomize/base/kustomization.yaml.backup
    
    # Use awk for more precise replacement
    awk -v ftag="$frontend_tag" -v gtag="$gaming_tag" -v otag="$order_tag" -v atag="$analytics_tag" '
    BEGIN { in_images = 0; current_image = "" }
    /^images:/ { in_images = 1; print; next }
    in_images && /^- name: / { 
        if ($3 == "gaming-frontend") current_image = "frontend"
        else if ($3 == "gaming-service") current_image = "gaming"
        else if ($3 == "order-service") current_image = "order"
        else if ($3 == "analytics-service") current_image = "analytics"
        else current_image = ""
        print; next
    }
    in_images && /^  newTag: / {
        if (current_image == "frontend") print "  newTag: " ftag
        else if (current_image == "gaming") print "  newTag: " gtag
        else if (current_image == "order") print "  newTag: " otag
        else if (current_image == "analytics") print "  newTag: " atag
        else print
        next
    }
    /^[^ ]/ && in_images && !/^- name:/ && !/^  / { in_images = 0 }
    { print }
    ' kustomize/base/kustomization.yaml.backup > kustomize/base/kustomization.yaml
    
    # Remove backup
    rm kustomize/base/kustomization.yaml.backup
    
    log "Kustomization updated successfully!"
    log "Updated tags: frontend=${frontend_tag}, gaming=${gaming_tag}, order=${order_tag}, analytics=${analytics_tag}"
}

# Deploy to Kubernetes
deploy_to_k8s() {
    log "Deploying to Kubernetes..."
    
    # Apply kustomization
    kubectl apply -k kustomize/base/
    
    # Wait for rollout
    log "Waiting for deployments to be ready..."
    kubectl rollout status deployment/frontend -n ${NAMESPACE} --timeout=300s
    kubectl rollout status deployment/gaming-service -n ${NAMESPACE} --timeout=300s
    kubectl rollout status deployment/order-service -n ${NAMESPACE} --timeout=300s
    kubectl rollout status deployment/analytics-service -n ${NAMESPACE} --timeout=300s
    
    log "Deployment completed successfully!"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check pod status
    kubectl get pods -n ${NAMESPACE}
    
    # Check services
    kubectl get services -n ${NAMESPACE}
    
    # Check ingress
    kubectl get ingress -n ${NAMESPACE}
    
    log "Deployment verification completed!"
}

# Cleanup old images
cleanup_images() {
    log "Cleaning up old Docker images..."
    
    # Remove dangling images
    docker image prune -f
    
    # Remove old tagged images (keep latest)
    docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(frontend|gaming-service|order-service|analytics-service)" | grep -v latest | head -10 | xargs -r docker rmi 2>/dev/null || true
    
    log "Image cleanup completed!"
}

# Main deployment flow
main() {
    log "Starting gaming microservices deployment..."
    
    check_prerequisites
    
    # Login to ECR
    log "Logging in to ECR..."
    aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
    
    # Build and push all services
    log "Building and pushing all services..."
    frontend_tag=$(build_and_push "frontend")
    gaming_tag=$(build_and_push "gaming-service")
    order_tag=$(build_and_push "order-service")
    analytics_tag=$(build_and_push "analytics-service")
    
    # Update Kubernetes manifests
    update_kustomization "${frontend_tag}" "${gaming_tag}" "${order_tag}" "${analytics_tag}"
    
    # Deploy to Kubernetes
    deploy_to_k8s
    
    # Verify deployment
    verify_deployment
    
    # Cleanup
    cleanup_images
    
    log "Gaming microservices deployment completed successfully!"
    log "Frontend: ${ECR_REGISTRY}/${REPO_PREFIX}/frontend:${frontend_tag}"
    log "Gaming Service: ${ECR_REGISTRY}/${REPO_PREFIX}/gaming-service:${gaming_tag}"
    log "Order Service: ${ECR_REGISTRY}/${REPO_PREFIX}/order-service:${order_tag}"
    log "Analytics Service: ${ECR_REGISTRY}/${REPO_PREFIX}/analytics-service:${analytics_tag}"
}

# Handle script arguments
case "${1:-deploy}" in
    "build-only")
        check_prerequisites
        aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
        build_and_push "frontend"
        build_and_push "gaming-service"
        build_and_push "order-service"
        build_and_push "analytics-service"
        ;;
    "deploy-only")
        check_prerequisites
        deploy_to_k8s
        verify_deployment
        ;;
    "verify")
        verify_deployment
        ;;
    "cleanup")
        cleanup_images
        ;;
    "deploy"|*)
        main
        ;;
esac
