#!/bin/bash

# Quick manual script to load mock data using psql client pod
# This script assumes you have kubectl configured and connected to your cluster

set -e

NAMESPACE=${NAMESPACE:-default}

echo "🚀 Starting mock data deployment to RDS..."

echo "📝 Step 1: Applying psql client pod configuration..."
kubectl apply -f /Users/sumudumari/Documents/cloud_computing/microservices/kustomize/psql-client.yaml

echo "⏳ Step 2: Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/psql-client --namespace="$NAMESPACE" --timeout=120s

echo "🔍 Step 3: Testing database connectivity..."
kubectl exec -it psql-client --namespace="$NAMESPACE" -- psql -c "SELECT version();"

echo "💾 Step 4: Executing mock data script..."
kubectl exec -it psql-client --namespace="$NAMESPACE" -- psql -f /scripts/mock-data.sql

echo "✅ Step 5: Verifying data insertion..."
kubectl exec -it psql-client --namespace="$NAMESPACE" -- psql -c "
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

echo ""
echo "🎉 Mock data has been successfully loaded into RDS!"
echo ""
echo "📌 To access the database manually:"
echo "   kubectl exec -it psql-client --namespace=$NAMESPACE -- psql"
echo ""
echo "🧹 To clean up when done:"
echo "   kubectl delete -f /Users/sumudumari/Documents/cloud_computing/microservices/kustomize/psql-client.yaml"
