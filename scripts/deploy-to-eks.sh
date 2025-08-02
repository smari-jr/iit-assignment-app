#!/bin/bash

# Complete EKS Deployment Script
# This script combines image building, pushing, and deployment

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

# Configuration
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
NAMESPACE="gaming-microservices"

# Help function
show_help() {
    echo "EKS Deployment Script for Gaming Microservices"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --build-only     Only build and push images to ECR"
    echo "  --deploy-only    Only deploy to EKS (assumes images are already in ECR)"
    echo "  --cleanup        Clean up repository before deployment"
    echo "  --help          Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION      AWS region (default: ap-southeast-1)"
    echo "  AWS_ACCOUNT_ID  AWS account ID (auto-detected if not set)"
    echo ""
    echo "Prerequisites:"
    echo "  - EKS cluster running and accessible"
    echo "  - AWS CLI configured"
    echo "  - kubectl configured for your EKS cluster"
    echo "  - Docker running"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "kubectl cannot connect to cluster"
        print_status "Make sure your kubectl is configured for your EKS cluster"
        exit 1
    fi
    
    # Check kustomize
    if ! command -v kustomize &> /dev/null; then
        print_warning "kustomize not found, using kubectl kustomize"
    fi
    
    print_success "Prerequisites check passed"
}

# Build and push images
build_and_push_images() {
    print_status "Building and pushing images to ECR..."
    
    if [ -f "./scripts/push-to-ecr.sh" ]; then
        ./scripts/push-to-ecr.sh
    else
        print_error "ECR push script not found"
        exit 1
    fi
    
    print_success "Images pushed to ECR successfully"
}

# Deploy to EKS
deploy_to_eks() {
    print_status "Deploying to EKS cluster..."
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_status "Creating namespace: $NAMESPACE"
        kubectl create namespace $NAMESPACE
    fi
    
    # Apply Kubernetes manifests
    print_status "Applying Kubernetes manifests..."
    if command -v kustomize &> /dev/null; then
        kustomize build kustomize/base | kubectl apply -f -
    else
        kubectl apply -k kustomize/base/
    fi
    
    print_success "Deployment applied successfully"
}

# Wait for deployment to be ready
wait_for_deployment() {
    print_status "Waiting for deployments to be ready..."
    
    deployments=("frontend" "gaming-service" "order-service" "analytics-service")
    
    for deployment in "${deployments[@]}"; do
        print_status "Waiting for $deployment to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/$deployment -n $NAMESPACE
    done
    
    print_success "All deployments are ready"
}

# Show deployment status
show_status() {
    print_status "Deployment Status:"
    echo ""
    
    print_status "Pods:"
    kubectl get pods -n $NAMESPACE
    echo ""
    
    print_status "Services:"
    kubectl get services -n $NAMESPACE
    echo ""
    
    print_status "Ingress:"
    kubectl get ingress -n $NAMESPACE
    echo ""
    
    # Get Load Balancer URL if available
    LB_URL=$(kubectl get ingress gaming-microservices-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not available yet")
    if [ "$LB_URL" != "Not available yet" ]; then
        print_success "Application URL: http://$LB_URL"
    else
        print_warning "Load Balancer URL not available yet. Check ingress status in a few minutes."
    fi
}

# Main execution
main() {
    BUILD_ONLY=false
    DEPLOY_ONLY=false
    CLEANUP=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --build-only)
                BUILD_ONLY=true
                shift
                ;;
            --deploy-only)
                DEPLOY_ONLY=true
                shift
                ;;
            --cleanup)
                CLEANUP=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "======================================="
    echo "  Gaming Microservices EKS Deployment"
    echo "======================================="
    echo ""
    
    print_status "AWS Region: $AWS_REGION"
    print_status "AWS Account ID: $AWS_ACCOUNT_ID"
    print_status "Namespace: $NAMESPACE"
    echo ""
    
    # Cleanup if requested
    if [ "$CLEANUP" = true ]; then
        print_status "Cleaning up repository..."
        if [ -f "./scripts/cleanup-for-eks.sh" ]; then
            ./scripts/cleanup-for-eks.sh
        fi
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Build and push images
    if [ "$DEPLOY_ONLY" = false ]; then
        build_and_push_images
    fi
    
    # Deploy to EKS
    if [ "$BUILD_ONLY" = false ]; then
        deploy_to_eks
        wait_for_deployment
        show_status
    fi
    
    echo ""
    echo "======================================="
    print_success "EKS Deployment Completed!"
    echo "======================================="
    echo ""
    
    if [ "$BUILD_ONLY" = false ]; then
        print_status "Next steps:"
        echo "1. Monitor the deployment: kubectl get pods -n $NAMESPACE"
        echo "2. Check logs if needed: kubectl logs <pod-name> -n $NAMESPACE"
        echo "3. Access the application via the Load Balancer URL above"
        echo "4. Scale services as needed: kubectl scale deployment <name> --replicas=N -n $NAMESPACE"
    fi
}

# Run main function
main "$@"
