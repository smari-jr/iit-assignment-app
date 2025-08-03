#!/bin/bash

# RDS Database Provisioning Script
# This script provisions and configures the RDS database for the gaming microservices
# Following AWS security best practices

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RDS_ENDPOINT="iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com"
DB_NAME="lugx_gaming_dev"
DB_USER="dbadmin"
DB_PASSWORD="LionKing1234"
DB_PORT="5432"
REGION="ap-southeast-1"

# EKS cluster configuration
EKS_CLUSTER_NAME="iit-test-dev-eks"
NAMESPACE="lugx-gaming"

# Function to print colored output
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

# Function to check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v psql &> /dev/null; then
        missing_tools+=("postgresql-client")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please install missing tools and try again"
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to get RDS security group ID
get_rds_security_group() {
    print_status "Getting RDS security group..."
    
    # Get RDS instance details
    local rds_sg_id=$(aws rds describe-db-instances \
        --region $REGION \
        --query "DBInstances[?DBInstanceIdentifier=='iit-test-dev-db'].VpcSecurityGroups[0].VpcSecurityGroupId" \
        --output text 2>/dev/null)
    
    if [ "$rds_sg_id" = "None" ] || [ -z "$rds_sg_id" ]; then
        print_error "Could not find RDS security group"
        return 1
    fi
    
    echo "$rds_sg_id"
}

# Function to get EKS node security group
get_eks_security_group() {
    print_status "Getting EKS node security group..."
    
    # Get EKS cluster security group
    local eks_sg_id=$(aws eks describe-cluster \
        --region $REGION \
        --name $EKS_CLUSTER_NAME \
        --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" \
        --output text 2>/dev/null)
    
    if [ "$eks_sg_id" = "None" ] || [ -z "$eks_sg_id" ]; then
        print_error "Could not find EKS cluster security group"
        return 1
    fi
    
    echo "$eks_sg_id"
}

# Function to configure RDS security group
configure_rds_security_group() {
    print_status "Configuring RDS security group for EKS access..."
    
    local rds_sg_id=$(get_rds_security_group)
    local eks_sg_id=$(get_eks_security_group)
    
    if [ -z "$rds_sg_id" ] || [ -z "$eks_sg_id" ]; then
        print_error "Failed to get security group IDs"
        return 1
    fi
    
    print_status "RDS Security Group: $rds_sg_id"
    print_status "EKS Security Group: $eks_sg_id"
    
    # Check if rule already exists
    local existing_rule=$(aws ec2 describe-security-groups \
        --region $REGION \
        --group-ids $rds_sg_id \
        --query "SecurityGroups[0].IpPermissions[?IpProtocol=='tcp' && FromPort==\`5432\` && ToPort==\`5432\` && UserIdGroupPairs[?GroupId==\`$eks_sg_id\`]]" \
        --output text 2>/dev/null)
    
    if [ -n "$existing_rule" ] && [ "$existing_rule" != "None" ]; then
        print_warning "Security group rule already exists"
    else
        print_status "Adding security group rule to allow EKS access to RDS..."
        aws ec2 authorize-security-group-ingress \
            --region $REGION \
            --group-id $rds_sg_id \
            --protocol tcp \
            --port 5432 \
            --source-group $eks_sg_id \
            2>/dev/null || {
            print_warning "Security group rule may already exist or insufficient permissions"
        }
        print_success "Security group configured"
    fi
}

# Function to test database connectivity
test_database_connection() {
    print_status "Testing database connectivity..."
    
    # Create a temporary connection test
    PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U $DB_USER -d postgres -p $DB_PORT -c "SELECT version();" &>/dev/null || {
        print_error "Cannot connect to RDS instance"
        print_status "Please check:"
        print_status "1. RDS instance is running"
        print_status "2. Security groups are properly configured"
        print_status "3. VPC and subnets are accessible"
        return 1
    }
    
    print_success "Database connection successful"
}

# Function to create database if it doesn't exist
create_database() {
    print_status "Creating database '$DB_NAME' if it doesn't exist..."
    
    # Check if database exists
    local db_exists=$(PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U $DB_USER -d postgres -p $DB_PORT -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null)
    
    if [ "$db_exists" = "1" ]; then
        print_warning "Database '$DB_NAME' already exists"
    else
        print_status "Creating database '$DB_NAME'..."
        PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U $DB_USER -d postgres -p $DB_PORT -c "CREATE DATABASE $DB_NAME;" || {
            print_error "Failed to create database"
            return 1
        }
        print_success "Database '$DB_NAME' created successfully"
    fi
}

# Function to initialize database schema
initialize_schema() {
    print_status "Initializing database schema..."
    
    local schema_file="../database/init-scripts/01-create-schema.sql"
    
    if [ ! -f "$schema_file" ]; then
        print_error "Schema file not found: $schema_file"
        return 1
    fi
    
    # Modify the schema file to use the correct database name
    local temp_schema="/tmp/schema-dev.sql"
    sed "s/lugx_gaming/$DB_NAME/g" "$schema_file" > "$temp_schema"
    
    print_status "Applying database schema..."
    PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME -p $DB_PORT -f "$temp_schema" || {
        print_error "Failed to apply database schema"
        rm -f "$temp_schema"
        return 1
    }
    
    rm -f "$temp_schema"
    print_success "Database schema initialized successfully"
}

# Function to create analytics tables for ClickHouse compatibility
create_analytics_tables() {
    print_status "Creating analytics tables..."
    
    local analytics_sql="/tmp/analytics-setup.sql"
    
    cat > "$analytics_sql" << 'EOF'
-- Analytics tables for PostgreSQL (compatible with ClickHouse integration)
CREATE TABLE IF NOT EXISTS user_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS page_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    page_url TEXT NOT NULL,
    referrer TEXT,
    session_id VARCHAR(100),
    view_duration INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS purchase_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    order_id UUID,
    product_id UUID,
    amount DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_events_user_id ON user_events(user_id);
CREATE INDEX IF NOT EXISTS idx_user_events_created_at ON user_events(created_at);
CREATE INDEX IF NOT EXISTS idx_page_views_user_id ON page_views(user_id);
CREATE INDEX IF NOT EXISTS idx_page_views_created_at ON page_views(created_at);
CREATE INDEX IF NOT EXISTS idx_purchase_events_user_id ON purchase_events(user_id);
CREATE INDEX IF NOT EXISTS idx_purchase_events_created_at ON purchase_events(created_at);
EOF
    
    PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME -p $DB_PORT -f "$analytics_sql" || {
        print_error "Failed to create analytics tables"
        rm -f "$analytics_sql"
        return 1
    }
    
    rm -f "$analytics_sql"
    print_success "Analytics tables created successfully"
}

# Function to verify database setup
verify_database_setup() {
    print_status "Verifying database setup..."
    
    # Check if all expected tables exist
    local tables=$(PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME -p $DB_PORT -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null)
    
    if [ "$tables" -gt 0 ]; then
        print_success "Database setup verified - $tables tables found"
        
        # List all tables
        print_status "Tables in database:"
        PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME -p $DB_PORT -c "\dt" 2>/dev/null || true
    else
        print_error "Database verification failed - no tables found"
        return 1
    fi
}

# Function to create database connection secret in Kubernetes
create_k8s_secret() {
    print_status "Creating Kubernetes secret for database connection..."
    
    # Check if secret already exists
    if kubectl get secret db-connection -n $NAMESPACE &>/dev/null; then
        print_warning "Kubernetes secret already exists, updating..."
        kubectl delete secret db-connection -n $NAMESPACE
    fi
    
    # Create new secret
    kubectl create secret generic db-connection \
        --from-literal=DB_HOST="$RDS_ENDPOINT" \
        --from-literal=DB_NAME="$DB_NAME" \
        --from-literal=DB_USER="$DB_USER" \
        --from-literal=DB_PASSWORD="$DB_PASSWORD" \
        --from-literal=DB_PORT="$DB_PORT" \
        -n $NAMESPACE || {
        print_error "Failed to create Kubernetes secret"
        return 1
    }
    
    print_success "Kubernetes secret created successfully"
}

# Function to restart deployments to pick up new configuration
restart_deployments() {
    print_status "Restarting microservices to apply new database configuration..."
    
    local deployments=("gaming-service" "order-service" "analytics-service")
    
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment $deployment -n $NAMESPACE &>/dev/null; then
            print_status "Restarting $deployment..."
            kubectl rollout restart deployment/$deployment -n $NAMESPACE
        else
            print_warning "Deployment $deployment not found, skipping..."
        fi
    done
    
    print_success "Deployments restarted"
}

# Main execution function
main() {
    print_status "Starting RDS database provisioning..."
    print_status "Target RDS: $RDS_ENDPOINT"
    print_status "Database: $DB_NAME"
    print_status "EKS Cluster: $EKS_CLUSTER_NAME"
    print_status "Namespace: $NAMESPACE"
    echo
    
    # Execute provisioning steps
    check_prerequisites
    configure_rds_security_group
    test_database_connection
    create_database
    initialize_schema
    create_analytics_tables
    verify_database_setup
    create_k8s_secret
    restart_deployments
    
    echo
    print_success "✅ RDS database provisioning completed successfully!"
    print_status "Your microservices should now be able to connect to the database"
    print_status "Monitor the logs with: kubectl logs -f <pod-name> -n $NAMESPACE"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
