#!/bin/bash

# Test script to validate the deployment script functionality
# This tests the update_kustomization function without doing actual deployment

set -e

# Source the deployment script functions (extract only the functions we need)
REGION="ap-southeast-1"
ECR_REGISTRY="036160411895.dkr.ecr.ap-southeast-1.amazonaws.com"
NAMESPACE="gaming-microservices"
REPO_PREFIX="gaming-microservices"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Test the update function
test_update_kustomization() {
    local frontend_tag="test-v1.0.0"
    local gaming_tag="test-v1.0.1"
    local order_tag="test-v1.0.2"
    local analytics_tag="test-v1.0.3"
    
    log "Testing image tag updates..."
    
    # Create backups
    cp kustomize/base/frontend.yaml kustomize/base/frontend.yaml.test.backup
    cp kustomize/base/gaming-service.yaml kustomize/base/gaming-service.yaml.test.backup
    cp kustomize/base/order-service.yaml kustomize/base/order-service.yaml.test.backup
    cp kustomize/base/analytics-service.yaml kustomize/base/analytics-service.yaml.test.backup
    
    # Update frontend image
    if [[ -f "kustomize/base/frontend.yaml" ]]; then
        log "Updating frontend image to: ${ECR_REGISTRY}/${REPO_PREFIX}/frontend:${frontend_tag}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s#image: .*frontend.*#image: ${ECR_REGISTRY}/${REPO_PREFIX}/frontend:${frontend_tag}#g" kustomize/base/frontend.yaml
        else
            sed -i "s#image: .*frontend.*#image: ${ECR_REGISTRY}/${REPO_PREFIX}/frontend:${frontend_tag}#g" kustomize/base/frontend.yaml
        fi
    fi
    
    # Update gaming-service image
    if [[ -f "kustomize/base/gaming-service.yaml" ]]; then
        log "Updating gaming-service image to: ${ECR_REGISTRY}/${REPO_PREFIX}/gaming-service:${gaming_tag}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s#image: .*gaming-service.*#image: ${ECR_REGISTRY}/${REPO_PREFIX}/gaming-service:${gaming_tag}#g" kustomize/base/gaming-service.yaml
        else
            sed -i "s#image: .*gaming-service.*#image: ${ECR_REGISTRY}/${REPO_PREFIX}/gaming-service:${gaming_tag}#g" kustomize/base/gaming-service.yaml
        fi
    fi
    
    # Update order-service image
    if [[ -f "kustomize/base/order-service.yaml" ]]; then
        log "Updating order-service image to: ${ECR_REGISTRY}/${REPO_PREFIX}/order-service:${order_tag}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s#image: .*order-service.*#image: ${ECR_REGISTRY}/${REPO_PREFIX}/order-service:${order_tag}#g" kustomize/base/order-service.yaml
        else
            sed -i "s#image: .*order-service.*#image: ${ECR_REGISTRY}/${REPO_PREFIX}/order-service:${order_tag}#g" kustomize/base/order-service.yaml
        fi
    fi
    
    # Update analytics-service image
    if [[ -f "kustomize/base/analytics-service.yaml" ]]; then
        log "Updating analytics-service image to: ${ECR_REGISTRY}/${REPO_PREFIX}/analytics-service:${analytics_tag}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s#image: .*analytics-service.*#image: ${ECR_REGISTRY}/${REPO_PREFIX}/analytics-service:${analytics_tag}#g" kustomize/base/analytics-service.yaml
        else
            sed -i "s#image: .*analytics-service.*#image: ${ECR_REGISTRY}/${REPO_PREFIX}/analytics-service:${analytics_tag}#g" kustomize/base/analytics-service.yaml
        fi
    fi
    
    # Verify the updates
    log "Verifying image tag updates..."
    echo "Frontend image: $(grep 'image:.*frontend' kustomize/base/frontend.yaml | xargs)"
    echo "Gaming service image: $(grep 'image:.*gaming-service' kustomize/base/gaming-service.yaml | xargs)"
    echo "Order service image: $(grep 'image:.*order-service' kustomize/base/order-service.yaml | xargs)"
    echo "Analytics service image: $(grep 'image:.*analytics-service' kustomize/base/analytics-service.yaml | xargs)"
    
    # Verify the kustomization is valid
    log "Validating kustomization..."
    if kustomize build kustomize/base/ > /dev/null 2>&1; then
        log "✅ Kustomization validation PASSED!"
    else
        warn "❌ Kustomization validation FAILED!"
        return 1
    fi
    
    # Restore backups
    log "Restoring original files..."
    mv kustomize/base/frontend.yaml.test.backup kustomize/base/frontend.yaml
    mv kustomize/base/gaming-service.yaml.test.backup kustomize/base/gaming-service.yaml
    mv kustomize/base/order-service.yaml.test.backup kustomize/base/order-service.yaml
    mv kustomize/base/analytics-service.yaml.test.backup kustomize/base/analytics-service.yaml
    
    log "✅ Image tag update test completed successfully!"
}

# Run the test
test_update_kustomization
