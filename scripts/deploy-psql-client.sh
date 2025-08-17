#!/bin/bash

# Script to deploy PostgreSQL client pod and load mock data into RDS
# Usage: ./deploy-psql-client.sh

set -e

# Configuration
NAMESPACE=${NAMESPACE:-default}
POD_NAME="psql-client-$(date +%s)"
MOCK_DATA_FILE="../database/mock-data.sql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Not connected to a Kubernetes cluster"
    exit 1
fi

# Check if mock data file exists
if [ ! -f "$MOCK_DATA_FILE" ]; then
    print_error "Mock data file not found at $MOCK_DATA_FILE"
    exit 1
fi

print_info "Starting PostgreSQL client pod deployment..."

# Create ConfigMap with the mock data SQL script
print_info "Creating ConfigMap with mock data script..."
kubectl create configmap mock-data-sql \
    --from-file=mock-data.sql="$MOCK_DATA_FILE" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Create the PostgreSQL client pod
print_info "Creating PostgreSQL client pod: $POD_NAME"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: $NAMESPACE
  labels:
    app: psql-client
    purpose: data-migration
spec:
  restartPolicy: Never
  containers:
  - name: psql-client
    image: postgres:15-alpine
    command: ["sleep", "3600"]  # Keep pod running for 1 hour
    env:
    - name: PGHOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_HOST
    - name: PGPORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_PORT
    - name: PGDATABASE
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_NAME
    - name: PGUSER
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: DB_USER
    - name: PGPASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: DB_PASSWORD
    volumeMounts:
    - name: mock-data-volume
      mountPath: /scripts
      readOnly: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
  volumes:
  - name: mock-data-volume
    configMap:
      name: mock-data-sql
EOF

# Wait for pod to be ready
print_info "Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/$POD_NAME --namespace="$NAMESPACE" --timeout=120s

if [ $? -eq 0 ]; then
    print_info "Pod is ready!"
else
    print_error "Pod failed to become ready"
    kubectl describe pod/$POD_NAME --namespace="$NAMESPACE"
    exit 1
fi

# Test database connectivity
print_info "Testing database connectivity..."
kubectl exec -it $POD_NAME --namespace="$NAMESPACE" -- psql -c "SELECT version();"

if [ $? -eq 0 ]; then
    print_info "Database connection successful!"
else
    print_error "Failed to connect to database"
    kubectl logs $POD_NAME --namespace="$NAMESPACE"
    exit 1
fi

# Execute the mock data script
print_info "Executing mock data script..."
kubectl exec -it $POD_NAME --namespace="$NAMESPACE" -- psql -f /scripts/mock-data.sql

if [ $? -eq 0 ]; then
    print_info "Mock data inserted successfully!"
else
    print_error "Failed to insert mock data"
    kubectl logs $POD_NAME --namespace="$NAMESPACE"
    exit 1
fi

# Verify data insertion
print_info "Verifying data insertion..."
kubectl exec -it $POD_NAME --namespace="$NAMESPACE" -- psql -c "
SELECT 
    'users' as table_name, count(*) as row_count FROM users
UNION ALL
SELECT 
    'categories' as table_name, count(*) as row_count FROM categories
UNION ALL
SELECT 
    'products' as table_name, count(*) as row_count FROM products
UNION ALL
SELECT 
    'orders' as table_name, count(*) as row_count FROM orders;
"

print_info "Data verification completed!"

# Provide instructions for cleanup
echo ""
print_warning "Pod $POD_NAME is still running for debugging purposes."
print_warning "To clean up resources, run:"
echo "kubectl delete pod $POD_NAME --namespace=$NAMESPACE"
echo "kubectl delete configmap mock-data-sql --namespace=$NAMESPACE"

# Provide instructions for manual access
echo ""
print_info "To manually access the database from this pod, run:"
echo "kubectl exec -it $POD_NAME --namespace=$NAMESPACE -- psql"

print_info "Script completed successfully!"
