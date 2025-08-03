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
    
    # Check if kustomize directory exists
    if [[ ! -d "kustomize/base" ]]; then
        error "Kustomize directory 'kustomize/base' not found."
    fi
    
    # Ensure base kustomization.yaml exists
    if [[ ! -f "kustomize/base/kustomization.yaml" ]]; then
        warn "Base kustomization.yaml not found. Creating it..."
        create_base_kustomization
    fi
    
    # Ensure dev overlay kustomization.yaml exists if dev directory exists
    if [[ -d "kustomize/overlays/dev" ]] && [[ ! -f "kustomize/overlays/dev/kustomization.yaml" ]]; then
        warn "Dev overlay kustomization.yaml not found. Creating it..."
        create_dev_overlay_kustomization
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
    
    log "Building ${service} with tag ${tag}..." >&2
    
    # Verify service directory exists
    if [[ ! -d "services/${service}" ]]; then
        error "Service directory 'services/${service}' not found"
    fi
    
    if [[ ! -f "services/${service}/Dockerfile" ]]; then
        error "Dockerfile not found in 'services/${service}/'"
    fi
    
    # Build the image
    if ! docker build -t "${service}:${tag}" -t "${service}:latest" "services/${service}/" >&2; then
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
    
    # Also create all required base YAML files if they don't exist
    create_base_yaml_files
}

# Create all base YAML files if missing
create_base_yaml_files() {
    log "Checking and creating missing base YAML files..."
    
    # Create namespace.yaml
    if [[ ! -f "kustomize/base/namespace.yaml" ]]; then
        log "Creating namespace.yaml..."
        cat > kustomize/base/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: gaming-microservices
  labels:
    name: gaming-microservices
EOF
    fi
    
    # Create secrets.yaml
    if [[ ! -f "kustomize/base/secrets.yaml" ]]; then
        log "Creating secrets.yaml..."
        cat > kustomize/base/secrets.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # Database credentials
  DB_USER: cG9zdGdyZXM=  # postgres (base64 encoded)
  DB_PASSWORD: cG9zdGdyZXMxMjM=  # postgres123 (base64 encoded)
  # ClickHouse credentials
  CLICKHOUSE_PASSWORD: ""  # empty password for default user (base64 encoded)
  # JWT secret
  JWT_SECRET: eW91ci1qd3Qtc2VjcmV0LWNoYW5nZS10aGlzLWluLXByb2R1Y3Rpb24=  # your-jwt-secret-change-this-in-production (base64 encoded)
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  NODE_ENV: "production"
  CORS_ORIGIN: "*"
  LOG_LEVEL: "info"
  # Database configuration
  DB_HOST: "postgres-service"
  DB_PORT: "5432"
  DB_NAME: "lugx_gaming"
  # ClickHouse configuration
  CLICKHOUSE_URL: "http://clickhouse-service:8123"
  CLICKHOUSE_USER: "default"
  CLICKHOUSE_USERNAME: "default"
  CLICKHOUSE_DATABASE: "analytics"
  # Microservices endpoints
  GAMING_SERVICE_URL: "http://gaming-service:3001"
  ORDER_SERVICE_URL: "http://order-service:3002"
  ANALYTICS_SERVICE_URL: "http://analytics-service:3003"
  FRONTEND_SERVICE_URL: "http://frontend-service:80"
  # Rate limiting
  RATE_LIMIT_WINDOW_MS: "900000"
  # JWT configuration
  JWT_EXPIRES_IN: "7d"
EOF
    fi
    
    # Create postgres.yaml
    if [[ ! -f "kustomize/base/postgres.yaml" ]]; then
        log "Creating postgres.yaml..."
        cat > kustomize/base/postgres.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  labels:
    app: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DB_NAME
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASSWORD
        ports:
        - containerPort: 5432
        volumeMounts:
        - mountPath: /var/lib/postgresql/data
          name: postgres-storage
      volumes:
      - name: postgres-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  type: ClusterIP
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: postgres
EOF
    fi
    
    # Create clickhouse.yaml
    if [[ ! -f "kustomize/base/clickhouse.yaml" ]]; then
        log "Creating clickhouse.yaml..."
        cat > kustomize/base/clickhouse.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: clickhouse
  labels:
    app: clickhouse
spec:
  replicas: 1
  selector:
    matchLabels:
      app: clickhouse
  template:
    metadata:
      labels:
        app: clickhouse
    spec:
      containers:
      - name: clickhouse
        image: clickhouse/clickhouse-server:latest
        ports:
        - containerPort: 8123
        - containerPort: 9000
        volumeMounts:
        - mountPath: /var/lib/clickhouse
          name: clickhouse-storage
      volumes:
      - name: clickhouse-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: clickhouse-service
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 8123
    targetPort: 8123
  - name: native
    port: 9000
    targetPort: 9000
  selector:
    app: clickhouse
EOF
    fi
    
    # Create frontend.yaml
    if [[ ! -f "kustomize/base/frontend.yaml" ]]; then
        log "Creating frontend.yaml..."
        cat > kustomize/base/frontend.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: 036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/gaming-microservices/frontend:latest
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: app-config
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: frontend
EOF
    fi
    
    # Create gaming-service.yaml
    if [[ ! -f "kustomize/base/gaming-service.yaml" ]]; then
        log "Creating gaming-service.yaml..."
        cat > kustomize/base/gaming-service.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gaming-service
  labels:
    app: gaming-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gaming-service
  template:
    metadata:
      labels:
        app: gaming-service
    spec:
      containers:
      - name: gaming-service
        image: 036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/gaming-microservices/gaming-service:latest
        ports:
        - containerPort: 3001
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
---
apiVersion: v1
kind: Service
metadata:
  name: gaming-service
spec:
  type: ClusterIP
  ports:
  - port: 3001
    targetPort: 3001
  selector:
    app: gaming-service
EOF
    fi
    
    # Create order-service.yaml
    if [[ ! -f "kustomize/base/order-service.yaml" ]]; then
        log "Creating order-service.yaml..."
        cat > kustomize/base/order-service.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  labels:
    app: order-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
      - name: order-service
        image: 036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/gaming-microservices/order-service:latest
        ports:
        - containerPort: 3002
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  type: ClusterIP
  ports:
  - port: 3002
    targetPort: 3002
  selector:
    app: order-service
EOF
    fi
    
    # Create analytics-service.yaml
    if [[ ! -f "kustomize/base/analytics-service.yaml" ]]; then
        log "Creating analytics-service.yaml..."
        cat > kustomize/base/analytics-service.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: analytics-service
  labels:
    app: analytics-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: analytics-service
  template:
    metadata:
      labels:
        app: analytics-service
    spec:
      containers:
      - name: analytics-service
        image: 036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/gaming-microservices/analytics-service:latest
        ports:
        - containerPort: 3003
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
---
apiVersion: v1
kind: Service
metadata:
  name: analytics-service
spec:
  type: ClusterIP
  ports:
  - port: 3003
    targetPort: 3003
  selector:
    app: analytics-service
EOF
    fi
    
    # Create ingress.yaml
    if [[ ! -f "kustomize/base/ingress.yaml" ]]; then
        log "Creating ingress.yaml..."
        cat > kustomize/base/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gaming-microservices-ingress
  annotations:
    kubernetes.io/ingress.class: "alb"
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api/gaming
        pathType: Prefix
        backend:
          service:
            name: gaming-service
            port:
              number: 3001
      - path: /api/orders
        pathType: Prefix
        backend:
          service:
            name: order-service
            port:
              number: 3002
      - path: /api/analytics
        pathType: Prefix
        backend:
          service:
            name: analytics-service
            port:
              number: 3003
EOF
    fi
    
    # Create network-policy.yaml
    if [[ ! -f "kustomize/base/network-policy.yaml" ]]; then
        log "Creating network-policy.yaml..."
        cat > kustomize/base/network-policy.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: gaming-microservices-network-policy
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}
EOF
    fi
    
    # Create health-check.yaml
    if [[ ! -f "kustomize/base/health-check.yaml" ]]; then
        log "Creating health-check.yaml..."
        cat > kustomize/base/health-check.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-check
  labels:
    app: health-check
spec:
  replicas: 1
  selector:
    matchLabels:
      app: health-check
  template:
    metadata:
      labels:
        app: health-check
    spec:
      containers:
      - name: health-check
        image: nginx:alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
---
apiVersion: v1
kind: Service
metadata:
  name: health-check-service
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: health-check
EOF
    fi
    
    log "All base YAML files created successfully!"
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

# Update kustomization with new image tags
update_kustomization() {
    local frontend_tag=$1
    local gaming_tag=$2
    local order_tag=$3
    local analytics_tag=$4
    
    log "Updating image tags in individual YAML files..."
    
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
    
    # Update dev overlay kustomization.yaml with new image tags
    if [[ -f "kustomize/overlays/dev/kustomization.yaml" ]]; then
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
    fi
    
    # Verify the kustomization is valid
    if ! kustomize build kustomize/base/ > /dev/null 2>&1; then
        error "Base kustomization validation failed after updating image tags"
    fi
    
    # Verify the dev overlay kustomization is valid
    if [[ -d "kustomize/overlays/dev" ]] && ! kustomize build kustomize/overlays/dev/ > /dev/null 2>&1; then
        error "Dev overlay kustomization validation failed after updating image tags"
    fi
    
    log "Image tags updated successfully in all YAML files!"
    log "Updated tags: frontend=${frontend_tag}, gaming=${gaming_tag}, order=${order_tag}, analytics=${analytics_tag}"
}

# Deploy to Kubernetes
deploy_to_k8s() {
    log "Deploying to Kubernetes..."
    
    # Use dev overlay instead of base for deployment
    local kustomize_path="kustomize/overlays/dev"
    
    # Check if dev overlay exists, otherwise fall back to base
    if [[ ! -d "${kustomize_path}" ]]; then
        warn "Dev overlay not found, using base kustomization"
        kustomize_path="kustomize/base"
    fi
    
    # Validate kustomization before applying
    log "Validating kustomization at ${kustomize_path}..."
    if ! kustomize build "${kustomize_path}/" > /dev/null; then
        error "Kustomization validation failed. Please check ${kustomize_path}/kustomization.yaml"
    fi
    
    # Apply kustomization
    log "Applying kustomization from ${kustomize_path}..."
    kubectl apply -k "${kustomize_path}/"
    
    # Determine namespace based on overlay or base
    local deployment_namespace="${NAMESPACE}"
    if [[ "${kustomize_path}" == "kustomize/overlays/dev" ]]; then
        deployment_namespace="lugx-gaming"
    fi
    
    # Wait for rollout
    log "Waiting for deployments to be ready in namespace ${deployment_namespace}..."
    kubectl rollout status deployment/frontend -n ${deployment_namespace} --timeout=300s
    kubectl rollout status deployment/gaming-service -n ${deployment_namespace} --timeout=300s
    kubectl rollout status deployment/order-service -n ${deployment_namespace} --timeout=300s
    kubectl rollout status deployment/analytics-service -n ${deployment_namespace} --timeout=300s
    
    log "Deployment completed successfully!"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Use the dev overlay namespace if it exists, otherwise use base namespace
    local deployment_namespace="lugx-gaming"
    if [[ ! -d "kustomize/overlays/dev" ]]; then
        deployment_namespace="${NAMESPACE}"
    fi
    
    log "Checking deployment in namespace: ${deployment_namespace}"
    
    # Check pod status
    kubectl get pods -n ${deployment_namespace}
    
    # Check services
    kubectl get services -n ${deployment_namespace}
    
    # Check ingress
    kubectl get ingress -n ${deployment_namespace} 2>/dev/null || log "No ingress found in namespace ${deployment_namespace}"
    
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
