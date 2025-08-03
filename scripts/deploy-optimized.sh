#!/bin/bash

# Comprehensive deployment script for gaming microservices
# This script builds, pushes to ECR, and deploys to Kubernetes
#
# Prerequisites:
# - AWS CLI configured with appropriate permissions
# - Docker installed and running
# - kubectl installed
# - kustomize installed
# - Access to EKS cluster specified in EKS_CLUSTER_NAME variable
#
# Configuration:
# - EKS_CLUSTER_NAME: The name of your EKS cluster (currently: iit-test-dev-eks)
# - REGION: AWS region for ECR and EKS (currently: ap-southeast-1)
# - ECR_REGISTRY: Your ECR registry URL
# - NAMESPACE: Kubernetes namespace for deployment
# - REPO_PREFIX: Prefix for ECR repositories

set -e

# Configuration
REGION="ap-southeast-1"
ECR_REGISTRY="036160411895.dkr.ecr.ap-southeast-1.amazonaws.com"
NAMESPACE="gaming-microservices"
REPO_PREFIX="gaming-microservices"
EKS_CLUSTER_NAME="iit-test-dev-eks"

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
    
    # Check if dev overlay exists
    if [[ ! -d "kustomize/overlays/dev" ]]; then
        error "Dev overlay directory 'kustomize/overlays/dev' not found."
    fi
    
    if [[ ! -f "kustomize/overlays/dev/kustomization.yaml" ]]; then
        error "Dev overlay kustomization.yaml not found."
    fi
    
    # Check required tools
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
    
    log "✅ Prerequisites check passed!"
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

# Build and push images with multi-architecture support
build_and_push() {
    local service=$1
    local tag=$(generate_image_tag)
    local image_name="${ECR_REGISTRY}/${REPO_PREFIX}/${service}"
    
    log "Building ${service} with tag ${tag} for amd64 architecture..." >&2
    
    # Verify service directory exists
    if [[ ! -d "services/${service}" ]]; then
        error "Service directory 'services/${service}' not found"
    fi
    
    if [[ ! -f "services/${service}/Dockerfile" ]]; then
        error "Dockerfile not found in 'services/${service}/'"
    fi
    
    # Build the image for amd64 platform
    if ! docker build --platform linux/amd64 -t "${service}:${tag}" -t "${service}:latest" "services/${service}/" >&2; then
        error "Failed to build ${service}"
    fi
    
    # Tag for ECR
    docker tag "${service}:${tag}" "${image_name}:${tag}" >&2
    docker tag "${service}:latest" "${image_name}:latest" >&2
    
    # Push to ECR
    log "Pushing ${service} to ECR..." >&2
    if ! docker push "${image_name}:${tag}" >&2; then
        error "Failed to push ${service}:${tag} to ECR"
    fi
    
    if ! docker push "${image_name}:latest" >&2; then
        error "Failed to push ${service}:latest to ECR"
    fi
    
    log "Successfully pushed ${service}:${tag}" >&2
    echo "${tag}"
}

# Create base kustomization.yaml if missing
create_base_kustomization() {
    log "Creating base kustomization.yaml..."
    cat > kustomize/base/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - config.yaml
  - secrets.yaml
  - postgres.yaml
  - clickhouse.yaml
  - frontend.yaml
  - gaming-service.yaml
  - order-service.yaml
  - analytics-service.yaml
  - ingress.yaml
  - network-policy.yaml
  - health-check.yaml

labels:
- pairs:
    app: gaming-microservices
    version: v1.0.0

namespace: gaming-microservices
EOF
    log "Base kustomization.yaml created successfully!"
}

# Create dev overlay kustomization.yaml if missing
create_dev_overlay_kustomization() {
    log "Creating dev overlay kustomization.yaml..."
    cat > kustomize/overlays/dev/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: lugx-gaming

resources:
- ../../base

patches:
- path: config-patch.yaml

labels:
- pairs:
    environment: development
    app.kubernetes.io/instance: dev

images:
- name: 036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/gaming-microservices/frontend
  newTag: latest
- name: 036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/gaming-microservices/gaming-service
  newTag: latest
- name: 036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/gaming-microservices/order-service
  newTag: latest
- name: 036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/gaming-microservices/analytics-service
  newTag: latest

replicas:
- name: frontend
  count: 1
- name: gaming-service
  count: 1
- name: order-service
  count: 1
- name: analytics-service
  count: 1
EOF
    log "Dev overlay kustomization.yaml created successfully!"
}

# Update dev overlay kustomization with new image tags
update_kustomization() {
    local frontend_tag=$1
    local gaming_tag=$2
    local order_tag=$3
    local analytics_tag=$4
    
    log "Updating image tags in dev overlay kustomization..."
    
    # Check if dev overlay exists
    if [[ ! -f "kustomize/overlays/dev/kustomization.yaml" ]]; then
        error "Dev overlay kustomization.yaml not found at kustomize/overlays/dev/kustomization.yaml"
    fi
    
    # Update dev overlay kustomization.yaml with new image tags
    log "Updating dev overlay image tags..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Update frontend tag
        sed -i '' "s#- name: ${ECR_REGISTRY}/.*frontend.*#- name: ${ECR_REGISTRY}/${REPO_PREFIX}/frontend#g" kustomize/overlays/dev/kustomization.yaml
        sed -i '' "/- name: ${ECR_REGISTRY}\/${REPO_PREFIX}\/frontend/,/newTag:/ s/newTag: .*/newTag: ${frontend_tag}/" kustomize/overlays/dev/kustomization.yaml
        
        # Update gaming-service tag
        sed -i '' "s#- name: ${ECR_REGISTRY}/.*gaming-service.*#- name: ${ECR_REGISTRY}/${REPO_PREFIX}/gaming-service#g" kustomize/overlays/dev/kustomization.yaml
        sed -i '' "/- name: ${ECR_REGISTRY}\/${REPO_PREFIX}\/gaming-service/,/newTag:/ s/newTag: .*/newTag: ${gaming_tag}/" kustomize/overlays/dev/kustomization.yaml
        
        # Update order-service tag
        sed -i '' "s#- name: ${ECR_REGISTRY}/.*order-service.*#- name: ${ECR_REGISTRY}/${REPO_PREFIX}/order-service#g" kustomize/overlays/dev/kustomization.yaml
        sed -i '' "/- name: ${ECR_REGISTRY}\/${REPO_PREFIX}\/order-service/,/newTag:/ s/newTag: .*/newTag: ${order_tag}/" kustomize/overlays/dev/kustomization.yaml
        
        # Update analytics-service tag
        sed -i '' "s#- name: ${ECR_REGISTRY}/.*analytics-service.*#- name: ${ECR_REGISTRY}/${REPO_PREFIX}/analytics-service#g" kustomize/overlays/dev/kustomization.yaml
        sed -i '' "/- name: ${ECR_REGISTRY}\/${REPO_PREFIX}\/analytics-service/,/newTag:/ s/newTag: .*/newTag: ${analytics_tag}/" kustomize/overlays/dev/kustomization.yaml
    else
        # Update frontend tag
        sed -i "s#- name: ${ECR_REGISTRY}/.*frontend.*#- name: ${ECR_REGISTRY}/${REPO_PREFIX}/frontend#g" kustomize/overlays/dev/kustomization.yaml
        sed -i "/- name: ${ECR_REGISTRY}\/${REPO_PREFIX}\/frontend/,/newTag:/ s/newTag: .*/newTag: ${frontend_tag}/" kustomize/overlays/dev/kustomization.yaml
        
        # Update gaming-service tag
        sed -i "s#- name: ${ECR_REGISTRY}/.*gaming-service.*#- name: ${ECR_REGISTRY}/${REPO_PREFIX}/gaming-service#g" kustomize/overlays/dev/kustomization.yaml
        sed -i "/- name: ${ECR_REGISTRY}\/${REPO_PREFIX}\/gaming-service/,/newTag:/ s/newTag: .*/newTag: ${gaming_tag}/" kustomize/overlays/dev/kustomization.yaml
        
        # Update order-service tag
        sed -i "s#- name: ${ECR_REGISTRY}/.*order-service.*#- name: ${ECR_REGISTRY}/${REPO_PREFIX}/order-service#g" kustomize/overlays/dev/kustomization.yaml
        sed -i "/- name: ${ECR_REGISTRY}\/${REPO_PREFIX}\/order-service/,/newTag:/ s/newTag: .*/newTag: ${order_tag}/" kustomize/overlays/dev/kustomization.yaml
        
        # Update analytics-service tag
        sed -i "s#- name: ${ECR_REGISTRY}/.*analytics-service.*#- name: ${ECR_REGISTRY}/${REPO_PREFIX}/analytics-service#g" kustomize/overlays/dev/kustomization.yaml
        sed -i "/- name: ${ECR_REGISTRY}\/${REPO_PREFIX}\/analytics-service/,/newTag:/ s/newTag: .*/newTag: ${analytics_tag}/" kustomize/overlays/dev/kustomization.yaml
    fi
    
    # Verify the dev overlay kustomization is valid
    if ! kustomize build kustomize/overlays/dev/ > /dev/null 2>&1; then
        error "Dev overlay kustomization validation failed after updating image tags"
    fi
    
    log "Image tags updated successfully in dev overlay!"
    log "Updated tags: frontend=${frontend_tag}, gaming=${gaming_tag}, order=${order_tag}, analytics=${analytics_tag}"
}

# Deploy to Kubernetes using dev overlay
deploy_to_k8s() {
    log "Deploying to Kubernetes using dev overlay..."
    
    local kustomize_path="kustomize/overlays/dev"
    local deployment_namespace="lugx-gaming"
    
    # Check if dev overlay exists
    if [[ ! -d "${kustomize_path}" ]]; then
        error "Dev overlay not found at ${kustomize_path}. Please ensure the dev overlay exists."
    fi
    
    # Validate kustomization before applying
    log "Validating kustomization at ${kustomize_path}..."
    if ! kustomize build "${kustomize_path}/" > /dev/null; then
        error "Kustomization validation failed. Please check ${kustomize_path}/kustomization.yaml"
    fi
    
    # Apply kustomization
    log "Applying kustomization from ${kustomize_path}..."
    kubectl apply -k "${kustomize_path}/"
    
    # Wait for rollout
    log "Waiting for deployments to be ready in namespace ${deployment_namespace}..."
    kubectl rollout status deployment/frontend -n ${deployment_namespace} --timeout=300s
    kubectl rollout status deployment/gaming-service -n ${deployment_namespace} --timeout=300s
    kubectl rollout status deployment/order-service -n ${deployment_namespace} --timeout=300s
    kubectl rollout status deployment/analytics-service -n ${deployment_namespace} --timeout=300s
    
    log "Deployment completed successfully!"
}

# Verify deployment with simple validation
verify_deployment() {
    log "Verifying deployment..."
    
    local deployment_namespace="lugx-gaming"
    
    log "Checking deployment in namespace: ${deployment_namespace}"
    
    # Check if namespace exists
    if ! kubectl get namespace ${deployment_namespace} &> /dev/null; then
        error "Namespace ${deployment_namespace} does not exist"
    fi
    
    # Check pod status
    log "Listing pods in namespace ${deployment_namespace}:"
    kubectl get pods -n ${deployment_namespace}
    
    # Check deployment status
    log "Checking deployment status:"
    kubectl get deployments -n ${deployment_namespace}
    
    # Check services
    log "Checking services:"
    kubectl get services -n ${deployment_namespace}
    
    # Check ingress if exists
    log "Checking ingress:"
    kubectl get ingress -n ${deployment_namespace} 2>/dev/null || log "No ingress found in namespace ${deployment_namespace}"
    
    # Simple health check - count running pods
    local running_pods=$(kubectl get pods -n ${deployment_namespace} --field-selector=status.phase=Running --no-headers | wc -l | tr -d ' ')
    local total_pods=$(kubectl get pods -n ${deployment_namespace} --no-headers | wc -l | tr -d ' ')
    
    log "Pod Status: ${running_pods}/${total_pods} pods are running"
    
    if [[ ${running_pods} -gt 0 ]]; then
        log "✅ Deployment verification completed successfully!"
    else
        warn "⚠️  No pods are currently running. Check the deployment status above."
    fi
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

# Configure kubectl for EKS cluster
configure_eks_access() {
    log "Configuring kubectl for EKS cluster: ${EKS_CLUSTER_NAME}..."
    
    # Update kubeconfig for EKS cluster
    if ! aws eks update-kubeconfig --region ${REGION} --name ${EKS_CLUSTER_NAME}; then
        error "Failed to configure kubectl for EKS cluster '${EKS_CLUSTER_NAME}'. Please check cluster name and AWS credentials."
    fi
    
    # Verify connection to cluster
    log "Verifying connection to EKS cluster..."
    if ! kubectl cluster-info &> /dev/null; then
        error "Unable to connect to EKS cluster. Please verify cluster access and AWS credentials."
    fi
    
    # Show current context
    local current_context=$(kubectl config current-context)
    log "Successfully connected to EKS cluster. Current context: ${current_context}"
}

# Main deployment flow
main() {
    log "Starting gaming microservices deployment..."
    
    check_prerequisites
    
    # Login to ECR
    log "Logging in to ECR..."
    aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
    
    # Configure EKS access
    configure_eks_access
    
    # Build and push all services
    log "Building and pushing all services..."
    frontend_tag=$(build_and_push "frontend")
    gaming_tag=$(build_and_push "gaming-service")
    order_tag=$(build_and_push "order-service")
    analytics_tag=$(build_and_push "analytics-service")
    
    # Update dev overlay with new image tags
    update_kustomization "${frontend_tag}" "${gaming_tag}" "${order_tag}" "${analytics_tag}"
    
    # Deploy to Kubernetes using dev overlay
    deploy_to_k8s
    
    # Verify deployment
    verify_deployment
    
    # Cleanup local images
    cleanup_images
    
    log "🎉 Gaming microservices deployment completed successfully!"
    log "📦 Deployed Images:"
    log "  Frontend: ${ECR_REGISTRY}/${REPO_PREFIX}/frontend:${frontend_tag}"
    log "  Gaming Service: ${ECR_REGISTRY}/${REPO_PREFIX}/gaming-service:${gaming_tag}"
    log "  Order Service: ${ECR_REGISTRY}/${REPO_PREFIX}/order-service:${order_tag}"
    log "  Analytics Service: ${ECR_REGISTRY}/${REPO_PREFIX}/analytics-service:${analytics_tag}"
    log "🏗️  Deployed to namespace: lugx-gaming"
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
