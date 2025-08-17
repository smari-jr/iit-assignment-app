#!/bin/bash

# Script to rebuild frontend with yellow color scheme and deploy to Kubernetes
# Run this from the microservices root directory

set -e

# Configuration
ECR_REGISTRY="036160411895.dkr.ecr.ap-southeast-1.amazonaws.com"
REPO_PREFIX="gaming-microservices"
REGION="ap-southeast-1"
NAMESPACE="lugx-gaming"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🎨 Rebuilding Frontend with Yellow Theme...${NC}"

# Step 1: Build the frontend Docker image
echo -e "${GREEN}📦 Building frontend Docker image...${NC}"
cd services/frontend
docker build -t ${ECR_REGISTRY}/${REPO_PREFIX}/frontend:yellow-theme-$(date +%Y%m%d-%H%M%S) .
cd ../..

# Step 2: Get the image tag
IMAGE_TAG=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep frontend | grep yellow-theme | head -1 | cut -d':' -f2)
FULL_IMAGE_NAME="${ECR_REGISTRY}/${REPO_PREFIX}/frontend:${IMAGE_TAG}"

echo -e "${GREEN}🏷️  Built image: ${FULL_IMAGE_NAME}${NC}"

# Step 3: Login to ECR
echo -e "${GREEN}🔐 Logging into ECR...${NC}"
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Step 4: Push the image
echo -e "${GREEN}📤 Pushing image to ECR...${NC}"
docker push ${FULL_IMAGE_NAME}

# Step 5: Update the deployment
echo -e "${GREEN}🚀 Updating Kubernetes deployment...${NC}"
kubectl set image deployment/frontend frontend=${FULL_IMAGE_NAME} -n ${NAMESPACE}

# Step 6: Wait for rollout
echo -e "${GREEN}⏳ Waiting for deployment to complete...${NC}"
kubectl rollout status deployment/frontend -n ${NAMESPACE}

echo -e "${YELLOW}✨ Frontend with yellow theme deployed successfully!${NC}"
echo -e "${GREEN}🌐 You can now access the application with the new yellow color scheme.${NC}"

# Step 7: Get the service URL
FRONTEND_SERVICE=$(kubectl get svc frontend-service -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
if [ -n "$FRONTEND_SERVICE" ]; then
    echo -e "${GREEN}🔗 Frontend URL: http://${FRONTEND_SERVICE}${NC}"
else
    echo -e "${YELLOW}💡 To access the frontend locally:${NC}"
    echo "kubectl port-forward -n ${NAMESPACE} svc/frontend-service 3000:80"
fi
