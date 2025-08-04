# Manual Deployment Runbook
## Gaming Microservices to AWS EKS

This runbook provides step-by-step instructions for manually deploying the gaming microservices system to AWS EKS, following the same process as the CI/CD pipeline.

---

## 📋 **Prerequisites**

### Required Tools
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Install Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect

# Install PostgreSQL client (for database operations)
# Ubuntu/Debian:
sudo apt-get update && sudo apt-get install -y postgresql-client
# macOS:
brew install postgresql
# CentOS/RHEL:
sudo yum install -y postgresql
```

### Required Access & Credentials
```bash
# AWS Credentials (set these environment variables)
export AWS_ACCESS_KEY_ID="your_access_key_here"
export AWS_SECRET_ACCESS_KEY="your_secret_key_here"
export AWS_DEFAULT_REGION="ap-southeast-1"

# Verify AWS access
aws sts get-caller-identity
```

### Environment Variables
```bash
# Deployment Configuration
export REGION="ap-southeast-1"
export ECR_REGISTRY="036160411895.dkr.ecr.ap-southeast-1.amazonaws.com"
export NAMESPACE="lugx-gaming"
export REPO_PREFIX="gaming-microservices"
export EKS_CLUSTER_NAME="iit-test-dev-eks"

# Database Configuration
export RDS_ENDPOINT="iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com"
export DB_NAME="app_database"
export DB_USER="dbadmin"
export DB_PASSWORD="LionKing1234"
export DB_PORT="5432"
```

---

## 🚀 **Step 1: Checkout Code from Repository**

```bash
# Clone the repository
git clone https://github.com/smari-jr/iit-assignment-app.git
cd iit-assignment-app

# Verify you're on the correct branch
git branch -a
git checkout main  # or develop for development deployment

# Verify repository structure
ls -la
echo "Repository structure verified ✅"
```

---

## 🔧 **Step 2: Configure AWS Access**

```bash
# Configure AWS CLI
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $REGION

# Verify AWS access
echo "Testing AWS connectivity..."
aws sts get-caller-identity

# Test ECR access
echo "Testing ECR access..."
aws ecr describe-repositories --region $REGION --repository-names gaming-microservices/frontend

# Configure EKS access
echo "Configuring EKS cluster access..."
aws eks update-kubeconfig --region $REGION --name $EKS_CLUSTER_NAME

# Verify kubectl connectivity
echo "Testing Kubernetes connectivity..."
kubectl get nodes
kubectl get namespaces
echo "AWS configuration complete ✅"
```

---

## 🐳 **Step 3: Build and Push Docker Images**

### Login to ECR
```bash
echo "Logging into Amazon ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
echo "ECR login successful ✅"
```

### Generate Image Tags
```bash
# Generate unique image tags
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
GIT_HASH=$(git rev-parse --short HEAD)
TAG="v${TIMESTAMP}-${GIT_HASH}"

echo "Generated image tag: $TAG"
export FRONTEND_TAG=$TAG
export GAMING_TAG=$TAG
export ORDER_TAG=$TAG
export ANALYTICS_TAG=$TAG
```

### Build Frontend Service
```bash
echo "Building Frontend Service..."
cd services/frontend

# Build for AMD64 platform (EKS compatibility)
docker build --platform linux/amd64 \
  -t $ECR_REGISTRY/gaming-microservices/frontend:$FRONTEND_TAG .

# Tag as latest
docker tag $ECR_REGISTRY/gaming-microservices/frontend:$FRONTEND_TAG \
  $ECR_REGISTRY/gaming-microservices/frontend:latest

# Push images
docker push $ECR_REGISTRY/gaming-microservices/frontend:$FRONTEND_TAG
docker push $ECR_REGISTRY/gaming-microservices/frontend:latest

echo "Frontend build complete ✅"
cd ../..
```

### Build Gaming Service
```bash
echo "Building Gaming Service..."
cd services/gaming-service

# Build and tag
docker build --platform linux/amd64 \
  -t $ECR_REGISTRY/gaming-microservices/gaming-service:$GAMING_TAG .

docker tag $ECR_REGISTRY/gaming-microservices/gaming-service:$GAMING_TAG \
  $ECR_REGISTRY/gaming-microservices/gaming-service:latest

# Push images
docker push $ECR_REGISTRY/gaming-microservices/gaming-service:$GAMING_TAG
docker push $ECR_REGISTRY/gaming-microservices/gaming-service:latest

echo "Gaming Service build complete ✅"
cd ../..
```

### Build Order Service
```bash
echo "Building Order Service..."
cd services/order-service

# Build and tag
docker build --platform linux/amd64 \
  -t $ECR_REGISTRY/gaming-microservices/order-service:$ORDER_TAG .

docker tag $ECR_REGISTRY/gaming-microservices/order-service:$ORDER_TAG \
  $ECR_REGISTRY/gaming-microservices/order-service:latest

# Push images
docker push $ECR_REGISTRY/gaming-microservices/order-service:$ORDER_TAG
docker push $ECR_REGISTRY/gaming-microservices/order-service:latest

echo "Order Service build complete ✅"
cd ../..
```

### Build Analytics Service
```bash
echo "Building Analytics Service..."
cd services/analytics-service

# Build and tag
docker build --platform linux/amd64 \
  -t $ECR_REGISTRY/gaming-microservices/analytics-service:$ANALYTICS_TAG .

docker tag $ECR_REGISTRY/gaming-microservices/analytics-service:$ANALYTICS_TAG \
  $ECR_REGISTRY/gaming-microservices/analytics-service:latest

# Push images
docker push $ECR_REGISTRY/gaming-microservices/analytics-service:$ANALYTICS_TAG
docker push $ECR_REGISTRY/gaming-microservices/analytics-service:latest

echo "Analytics Service build complete ✅"
cd ../..
```

### Verify All Images
```bash
echo "Verifying all images in ECR..."
aws ecr describe-images --repository-name gaming-microservices/frontend --image-ids imageTag=$FRONTEND_TAG --region $REGION
aws ecr describe-images --repository-name gaming-microservices/gaming-service --image-ids imageTag=$GAMING_TAG --region $REGION
aws ecr describe-images --repository-name gaming-microservices/order-service --image-ids imageTag=$ORDER_TAG --region $REGION
aws ecr describe-images --repository-name gaming-microservices/analytics-service --image-ids imageTag=$ANALYTICS_TAG --region $REGION
echo "All images verified in ECR ✅"
```

---

## 🗄️ **Step 4: Configure Database Security Groups**

```bash
echo "Configuring RDS security groups for EKS access..."

# Get security group and VPC information
RDS_SG_ID=$(aws rds describe-db-instances --region $REGION \
  --query "DBInstances[?DBInstanceIdentifier=='iit-test-dev-db'].VpcSecurityGroups[0].VpcSecurityGroupId" \
  --output text 2>/dev/null || echo "None")

EKS_SG_ID=$(aws eks describe-cluster --region $REGION --name $EKS_CLUSTER_NAME \
  --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" \
  --output text 2>/dev/null || echo "None")

VPC_ID=$(aws eks describe-cluster --region $REGION --name $EKS_CLUSTER_NAME \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text 2>/dev/null || echo "None")

VPC_CIDR=$(aws ec2 describe-vpcs --region $REGION --vpc-ids $VPC_ID \
  --query "Vpcs[0].CidrBlock" \
  --output text 2>/dev/null || echo "None")

echo "RDS Security Group: $RDS_SG_ID"
echo "EKS Security Group: $EKS_SG_ID"
echo "VPC ID: $VPC_ID"
echo "VPC CIDR: $VPC_CIDR"

# Add VPC CIDR rule to RDS security group
if [ "$RDS_SG_ID" != "None" ] && [ "$VPC_CIDR" != "None" ]; then
  echo "Adding VPC CIDR rule to RDS security group..."
  aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id $RDS_SG_ID \
    --protocol tcp \
    --port 5432 \
    --cidr $VPC_CIDR \
    2>/dev/null || echo "Rule may already exist"
  echo "Database security groups configured ✅"
else
  echo "⚠️ Could not configure security groups automatically"
fi
```

---

## 📝 **Step 5: Update Kustomization Configuration**

```bash
echo "Updating Kustomization with new image tags..."
cd kustomize/overlays/dev

# Create backup of current configuration
cp kustomization.yaml kustomization.yaml.backup.$(date +%Y%m%d-%H%M%S)

# Update image tags using awk
awk -v frontend="$FRONTEND_TAG" -v gaming="$GAMING_TAG" -v order="$ORDER_TAG" -v analytics="$ANALYTICS_TAG" '
/- name:.*\/frontend$/ { 
    print $0
    getline
    if ($0 ~ /newTag:/) {
        print "  newTag: " frontend
    } else {
        print $0
    }
    next
}
/- name:.*\/gaming-service$/ { 
    print $0
    getline
    if ($0 ~ /newTag:/) {
        print "  newTag: " gaming
    } else {
        print $0
    }
    next
}
/- name:.*\/order-service$/ { 
    print $0
    getline
    if ($0 ~ /newTag:/) {
        print "  newTag: " order
    } else {
        print $0
    }
    next
}
/- name:.*\/analytics-service$/ { 
    print $0
    getline
    if ($0 ~ /newTag:/) {
        print "  newTag: " analytics
    } else {
        print $0
    }
    next
}
{ print $0 }
' kustomization.yaml.backup > kustomization.yaml

# Verify updated configuration
echo "Updated kustomization.yaml:"
echo "=========================="
cat kustomization.yaml
echo "=========================="

# Test kustomize build
echo "Testing kustomize build..."
kustomize build . > /tmp/kustomize-output.yaml
echo "Kustomize build successful ✅"

cd ../../..
```

---

## 🚢 **Step 6: Deploy to Kubernetes**

### Create Namespace (if not exists)
```bash
echo "Creating namespace if it doesn't exist..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace ready ✅"
```

### Apply Kustomization
```bash
echo "Deploying to Kubernetes cluster: $EKS_CLUSTER_NAME"
echo "Applying kustomization..."
kubectl apply -k kustomize/overlays/dev/

echo "Deployment initiated ✅"
```

### Wait for Deployments to be Ready
```bash
echo "Waiting for deployments to be ready..."
echo "This may take several minutes..."

# Wait for each deployment with timeout
kubectl rollout status deployment/frontend -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/gaming-service -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/order-service -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/analytics-service -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/clickhouse -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/health-check -n $NAMESPACE --timeout=300s

echo "All deployments ready ✅"
```

---

## ✅ **Step 7: Verify Deployment**

### Check Pod Status
```bash
echo "Checking pod status..."
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "Pod status details:"
kubectl describe pods -n $NAMESPACE | grep -E "(Name:|Status:|Ready:|Restart|Image:)"
```

### Check Deployment Status
```bash
echo ""
echo "Deployment Status:"
kubectl get deployments -n $NAMESPACE

echo ""
echo "ReplicaSets Status:"
kubectl get replicasets -n $NAMESPACE
```

### Check Services
```bash
echo ""
echo "Services:"
kubectl get services -n $NAMESPACE

echo ""
echo "Service details:"
kubectl get services -n $NAMESPACE -o wide
```

### Verify All Pods Running
```bash
echo ""
echo "Verifying all pods are running..."

RUNNING_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running --no-headers | wc -l)
TOTAL_PODS=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)

echo "Status Summary: $RUNNING_PODS/$TOTAL_PODS pods running"

if [ $RUNNING_PODS -eq $TOTAL_PODS ] && [ $RUNNING_PODS -gt 0 ]; then
  echo "✅ All deployments are healthy!"
else
  echo "⚠️ Some pods may not be ready"
  echo "Non-running pods:"
  kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running
  
  echo ""
  echo "Pod logs for troubleshooting:"
  for pod in $(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running -o name); do
    echo "=== Logs for $pod ==="
    kubectl logs $pod -n $NAMESPACE --tail=50
  done
fi
```

---

## 🌐 **Step 8: Get Application URLs**

### Check LoadBalancer Services
```bash
echo "Getting application URLs..."

# Frontend Service
FRONTEND_SERVICE=$(kubectl get svc frontend-service -n $NAMESPACE \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")

# Health Check Service
HEALTH_SERVICE=$(kubectl get svc health-check-service -n $NAMESPACE \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")

# ALB Ingress (if configured)
ALB_HOSTNAME=$(kubectl get ingress gaming-ingress -n $NAMESPACE \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")

echo ""
echo "=== APPLICATION ACCESS ==="

if [ "$ALB_HOSTNAME" != "pending" ] && [ -n "$ALB_HOSTNAME" ]; then
  echo "🌐 Main Application (ALB): http://$ALB_HOSTNAME"
  echo "   - Frontend: http://$ALB_HOSTNAME/"
  echo "   - Gaming API: http://$ALB_HOSTNAME/api/products"
  echo "   - Order API: http://$ALB_HOSTNAME/api/orders"
  echo "   - Analytics API: http://$ALB_HOSTNAME/api/analytics"
else
  echo "🌐 ALB: LoadBalancer pending..."
fi

if [ "$FRONTEND_SERVICE" != "pending" ] && [ -n "$FRONTEND_SERVICE" ]; then
  echo "🎮 Frontend Service: http://$FRONTEND_SERVICE"
else
  echo "🎮 Frontend: Use port-forward: kubectl port-forward svc/frontend-service 3000:80 -n $NAMESPACE"
fi

if [ "$HEALTH_SERVICE" != "pending" ] && [ -n "$HEALTH_SERVICE" ]; then
  echo "🏥 Health Dashboard: http://$HEALTH_SERVICE"
else
  echo "🏥 Health Dashboard: Use port-forward: kubectl port-forward svc/health-check-service 8080:80 -n $NAMESPACE"
fi

echo ""
echo "=== PORT-FORWARD COMMANDS (if LoadBalancers are pending) ==="
echo "Frontend:        kubectl port-forward svc/frontend-service 3000:80 -n $NAMESPACE"
echo "Gaming Service:  kubectl port-forward svc/gaming-service 3001:3001 -n $NAMESPACE"
echo "Order Service:   kubectl port-forward svc/order-service 3002:3002 -n $NAMESPACE"
echo "Analytics:       kubectl port-forward svc/analytics-service 3003:3003 -n $NAMESPACE"
echo "Health Check:    kubectl port-forward svc/health-check-service 8080:80 -n $NAMESPACE"
echo "ClickHouse:      kubectl port-forward svc/clickhouse-service 8123:8123 -n $NAMESPACE"
```

---

## 📊 **Step 9: Test Application**

### Health Check Tests
```bash
echo ""
echo "=== HEALTH CHECK TESTS ==="

# Test health endpoints using port-forward if LoadBalancers are pending
echo "Testing health endpoints..."

# Start port-forward in background for testing
kubectl port-forward svc/gaming-service 3001:3001 -n $NAMESPACE &
PF_GAMING_PID=$!

kubectl port-forward svc/order-service 3002:3002 -n $NAMESPACE &
PF_ORDER_PID=$!

kubectl port-forward svc/analytics-service 3003:3003 -n $NAMESPACE &
PF_ANALYTICS_PID=$!

# Wait a moment for port-forwards to establish
sleep 5

# Test health endpoints
echo "Testing Gaming Service health..."
curl -f http://localhost:3001/health || echo "Gaming Service health check failed"

echo "Testing Order Service health..."
curl -f http://localhost:3002/health || echo "Order Service health check failed"

echo "Testing Analytics Service health..."
curl -f http://localhost:3003/health || echo "Analytics Service health check failed"

# Clean up port-forwards
kill $PF_GAMING_PID $PF_ORDER_PID $PF_ANALYTICS_PID 2>/dev/null || true
```

### Database Connectivity Test
```bash
echo ""
echo "=== DATABASE CONNECTIVITY TEST ==="

# Test PostgreSQL connectivity from a temporary pod
echo "Testing PostgreSQL connectivity..."
kubectl run postgres-test --image=postgres:13 --rm -it --restart=Never -n $NAMESPACE -- \
  psql "postgresql://$DB_USER:$DB_PASSWORD@$RDS_ENDPOINT:$DB_PORT/$DB_NAME?sslmode=require" \
  -c "SELECT 1 as connection_test;" || echo "Database connection failed"
```

---

## 📋 **Step 10: Post-Deployment Summary**

```bash
echo ""
echo "=== DEPLOYMENT SUMMARY ==="
echo "Deployment completed at: $(date)"
echo "Git commit: $(git rev-parse HEAD)"
echo "Image tags deployed:"
echo "  - Frontend: $FRONTEND_TAG"
echo "  - Gaming Service: $GAMING_TAG"
echo "  - Order Service: $ORDER_TAG"
echo "  - Analytics Service: $ANALYTICS_TAG"
echo ""
echo "Cluster: $EKS_CLUSTER_NAME"
echo "Namespace: $NAMESPACE"
echo "Region: $REGION"
echo ""
echo "🎉 DEPLOYMENT SUCCESSFUL! 🎉"
```

---

## 🚨 **Troubleshooting Guide**

### Common Issues and Solutions

#### 1. ECR Permission Denied
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Re-login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
```

#### 2. Pod ImagePullBackOff
```bash
# Check ECR repositories exist
aws ecr describe-repositories --region $REGION

# Verify image exists
aws ecr describe-images --repository-name gaming-microservices/frontend --region $REGION

# Check pod events
kubectl describe pod <pod-name> -n $NAMESPACE
```

#### 3. Database Connection Issues
```bash
# Check RDS security groups
aws rds describe-db-instances --region $REGION --query "DBInstances[?DBInstanceIdentifier=='iit-test-dev-db'].VpcSecurityGroups"

# Test from within cluster
kubectl run postgres-test --image=postgres:13 --rm -it --restart=Never -n $NAMESPACE -- \
  psql "postgresql://$DB_USER:$DB_PASSWORD@$RDS_ENDPOINT:$DB_PORT/$DB_NAME?sslmode=require" -c "SELECT version();"
```

#### 4. Pod Not Ready
```bash
# Check pod logs
kubectl logs <pod-name> -n $NAMESPACE

# Check pod events
kubectl describe pod <pod-name> -n $NAMESPACE

# Check resource constraints
kubectl top pods -n $NAMESPACE
kubectl describe nodes
```

#### 5. Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n $NAMESPACE

# Check ingress status
kubectl describe ingress -n $NAMESPACE

# Test service connectivity
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -n $NAMESPACE -- \
  curl http://frontend-service/health
```

### Log Collection for Support
```bash
# Collect all logs for support
mkdir -p /tmp/deployment-logs
kubectl get all -n $NAMESPACE > /tmp/deployment-logs/resources.txt
kubectl describe pods -n $NAMESPACE > /tmp/deployment-logs/pod-descriptions.txt
kubectl get events -n $NAMESPACE > /tmp/deployment-logs/events.txt

# Collect pod logs
for pod in $(kubectl get pods -n $NAMESPACE -o name); do
  kubectl logs $pod -n $NAMESPACE > /tmp/deployment-logs/${pod}.log
done

echo "Logs collected in /tmp/deployment-logs/"
```

---

## 🔄 **Rollback Procedure**

If deployment fails and you need to rollback:

```bash
# List previous deployments
kubectl rollout history deployment/frontend -n $NAMESPACE
kubectl rollout history deployment/gaming-service -n $NAMESPACE
kubectl rollout history deployment/order-service -n $NAMESPACE
kubectl rollout history deployment/analytics-service -n $NAMESPACE

# Rollback specific service
kubectl rollout undo deployment/frontend -n $NAMESPACE

# Or rollback to specific revision
kubectl rollout undo deployment/frontend --to-revision=2 -n $NAMESPACE

# Rollback all services
kubectl rollout undo deployment/frontend -n $NAMESPACE
kubectl rollout undo deployment/gaming-service -n $NAMESPACE
kubectl rollout undo deployment/order-service -n $NAMESPACE
kubectl rollout undo deployment/analytics-service -n $NAMESPACE
```

---

## 📚 **Additional Commands**

### Monitoring Commands
```bash
# Watch pod status
watch kubectl get pods -n $NAMESPACE

# Follow logs in real-time
kubectl logs -f deployment/frontend -n $NAMESPACE

# Get resource usage
kubectl top pods -n $NAMESPACE
kubectl top nodes
```

### Scaling Commands
```bash
# Scale specific service
kubectl scale deployment frontend --replicas=3 -n $NAMESPACE

# Update resources
kubectl patch deployment frontend -n $NAMESPACE -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

This runbook provides a complete manual deployment process that mirrors the automated CI/CD pipeline, ensuring consistent and reliable deployments.
