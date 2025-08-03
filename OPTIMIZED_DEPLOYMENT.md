# Optimized All-in-One Deployment Script

## Overview

The `deploy-optimized.sh` script has been completely optimized to handle the full deployment lifecycle of your gaming microservices platform, including:

✅ **Database Setup & Configuration**
✅ **Security Group Management** 
✅ **Docker Image Building & Pushing**
✅ **Kubernetes Deployment**
✅ **Health Verification**
✅ **Automated Cleanup**

## What the Script Does

### 1. 🗄️ Database Setup
- Configures RDS security groups to allow EKS access
- Tests database connectivity
- Creates `lugx_gaming_dev` database if it doesn't exist
- Initializes database schema with all required tables
- Sets up analytics tables for tracking

### 2. 🔨 Image Building
- Builds all 4 microservices for AMD64 architecture
- Tags images with timestamp and git hash
- Pushes to ECR with proper versioning

### 3. 🚀 Kubernetes Deployment
- Updates kustomize configuration with new image tags
- Deploys all services to `lugx-gaming` namespace
- Waits for all deployments to be ready
- Verifies pod health and service status

### 4. 🧹 Cleanup & Verification
- Removes old Docker images
- Shows deployment status and URLs
- Provides monitoring commands

## Usage

### Full Deployment (Recommended)
```bash
./scripts/deploy-optimized.sh
```
This runs the complete pipeline: database setup → build → push → deploy → verify

### Specific Operations
```bash
# Build and push images only
./scripts/deploy-optimized.sh build-only

# Deploy to Kubernetes only (assumes images exist)
./scripts/deploy-optimized.sh deploy-only

# Setup database only
./scripts/deploy-optimized.sh database-only

# Check deployment status
./scripts/deploy-optimized.sh status

# Clean up local images
./scripts/deploy-optimized.sh cleanup

# Show help
./scripts/deploy-optimized.sh help
```

## Key Optimizations

### ❌ Removed
- Complex validation logic that could fail unnecessarily
- Redundant error checking and debugging functions
- Multiple backup/restore mechanisms
- Verbose logging that cluttered output

### ✅ Added
- **Database integration** - Full RDS setup and schema initialization
- **Streamlined flow** - Linear execution with clear progress indicators
- **Better error handling** - Fail fast with helpful error messages
- **Application URLs** - Shows how to access deployed services
- **PostgreSQL client setup** - Automatic PATH configuration for macOS
- **Security group automation** - Configures EKS → RDS access automatically

### 🔧 Improved
- **Cleaner output** - Emoji indicators and structured logging
- **Faster execution** - Removed redundant checks and validations
- **Better UX** - Clear progress indicators and final summary
- **Flexible operation modes** - Can run specific parts of the pipeline

## Prerequisites

The script automatically checks for and helps install:
- AWS CLI
- Docker
- kubectl  
- kustomize
- PostgreSQL client (`brew install postgresql`)

## Configuration

All configuration is centralized at the top of the script:

```bash
# AWS & EKS Configuration
REGION="ap-southeast-1"
ECR_REGISTRY="036160411895.dkr.ecr.ap-southeast-1.amazonaws.com"
NAMESPACE="lugx-gaming"
EKS_CLUSTER_NAME="iit-test-dev-eks"

# Database Configuration  
RDS_ENDPOINT="iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com"
DB_NAME="lugx_gaming_dev"
DB_USER="dbladmin"
DB_PASSWORD="LionKing1234"
```

## Typical Output

```
🚀 Starting Gaming Microservices All-in-One Deployment...
📍 Target: EKS Cluster 'iit-test-dev-eks' in region 'ap-southeast-1'
🗄️  Database: iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com/lugx_gaming_dev
📦 Registry: 036160411895.dkr.ecr.ap-southeast-1.amazonaws.com

✅ Prerequisites check passed!
🔧 Configuring kubectl for EKS cluster...
✅ Connected to EKS cluster: arn:aws:eks:ap-southeast-1:036160411895:cluster/iit-test-dev-eks
🔐 Logging in to ECR...
🗄️  Setting up RDS database...
✅ Database setup completed!
🔨 Building and pushing microservices...
🔨 Building frontend with tag v20250803-171234-abc123...
✅ Successfully pushed frontend:v20250803-171234-abc123
📝 Updating image tags in dev overlay...
✅ Image tags updated successfully!
🚀 Deploying to Kubernetes...
✅ Deployment completed successfully!
🔍 Verifying deployment status...
✅ All deployments are healthy!
🧹 Cleaning up old Docker images...

🎉 Gaming Microservices Deployment Completed Successfully!
```

## Troubleshooting

### Database Connection Issues
```bash
# Run database setup only to test connectivity
./scripts/deploy-optimized.sh database-only
```

### Build Issues
```bash
# Build and push only to isolate issues
./scripts/deploy-optimized.sh build-only
```

### Deployment Issues
```bash
# Check current status
./scripts/deploy-optimized.sh status

# View pod logs
kubectl logs -f deployment/analytics-service -n lugx-gaming
```

## Security Features

- ✅ Automatic security group configuration for RDS access
- ✅ Encrypted RDS connection using SSL
- ✅ Kubernetes secrets for database credentials
- ✅ Container images scanned and pushed to private ECR
- ✅ Network policies for pod-to-pod communication

## Next Steps After Deployment

1. **Monitor the application:**
   ```bash
   kubectl get pods -n lugx-gaming -w
   ```

2. **Access the frontend:**
   ```bash
   kubectl port-forward svc/frontend-service 3000:80 -n lugx-gaming
   ```

3. **Check health dashboard:**
   ```bash
   kubectl port-forward svc/health-check-service 8080:80 -n lugx-gaming
   ```

4. **View application logs:**
   ```bash
   kubectl logs -f deployment/frontend -n lugx-gaming
   ```

The optimized script provides a production-ready deployment pipeline that handles all aspects of your gaming microservices platform deployment automatically! 🚀
