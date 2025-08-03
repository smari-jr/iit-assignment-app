# Database Provisioning Guide

This guide provides comprehensive instructions for provisioning and managing the RDS PostgreSQL database for the gaming microservices platform.

## Overview

The gaming microservices platform uses AWS RDS PostgreSQL as the primary database with the following configuration:
- **Endpoint**: `iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com`
- **Database**: `lugx_gaming_dev`
- **User**: `dbadmin`
- **Port**: `5432`

## Prerequisites

Before running the provisioning scripts, ensure you have the following tools installed:

### Required Tools
```bash
# AWS CLI
aws --version

# kubectl (for EKS access)
kubectl version --client

# PostgreSQL client
psql --version

# Check if you're authenticated with AWS
aws sts get-caller-identity

# Check if you can access the EKS cluster
kubectl get nodes
```

### AWS Permissions Required
Your AWS user/role needs the following permissions:
- `ec2:DescribeSecurityGroups`
- `ec2:AuthorizeSecurityGroupIngress`
- `rds:DescribeDBInstances`
- `eks:DescribeCluster`

## Quick Start

### 1. Provision the Database
Run the main provisioning script to set up the database:

```bash
./scripts/provision-rds-database.sh
```

This script will:
- ✅ Configure RDS security groups to allow EKS access
- ✅ Test database connectivity
- ✅ Create the `lugx_gaming_dev` database
- ✅ Initialize database schema with all required tables
- ✅ Create analytics tables for tracking
- ✅ Create Kubernetes secrets for database connection
- ✅ Restart microservices to apply new configuration

### 2. Verify Database Setup
Check that everything is working:

```bash
./scripts/manage-database.sh health
```

### 3. Seed Test Data (Optional)
Add sample data for testing:

```bash
./scripts/manage-database.sh seed
```

## Database Schema

### Core Tables
- **users** - User accounts and profiles
- **categories** - Game categories
- **products** - Games/products catalog
- **orders** - Purchase orders
- **order_items** - Order line items
- **cart_items** - Shopping cart contents
- **reviews** - Product reviews
- **user_sessions** - User login sessions

### Analytics Tables
- **user_events** - User behavior tracking
- **page_views** - Page view analytics
- **purchase_events** - Purchase tracking events

## Management Commands

### Database Health Check
```bash
./scripts/manage-database.sh health
```

### Create Database Backup
```bash
./scripts/manage-database.sh backup
```

### View Database Statistics
```bash
./scripts/manage-database.sh stats
```

### Clean Up Old Data
```bash
./scripts/manage-database.sh cleanup
```

### Create Performance Indexes
```bash
./scripts/manage-database.sh indexes
```

## Troubleshooting

### Connection Issues

If you see the error: `no pg_hba.conf entry for host`, it means the security groups are not properly configured.

**Solution:**
```bash
# Re-run the provisioning script to fix security groups
./scripts/provision-rds-database.sh
```

### Database Does Not Exist

If services can't find the database `lugx_gaming_dev`:

**Solution:**
```bash
# The provisioning script will create it automatically
./scripts/provision-rds-database.sh
```

### Pod Connection Failures

Check if pods can resolve the RDS endpoint:

```bash
# Test from within a pod
kubectl exec -it <pod-name> -n lugx-gaming -- nslookup iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com

# Check security groups
aws ec2 describe-security-groups --group-ids <rds-security-group-id>
```

### Manual Database Connection

Connect directly to test:

```bash
# From your local machine (if security groups allow)
PGPASSWORD=LionKing1234 psql -h iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com -U dbadmin -d lugx_gaming_dev -p 5432

# From within the EKS cluster
kubectl run psql-client --rm -i --tty --image postgres:15-alpine -- bash
# Then inside the pod:
PGPASSWORD=LionKing1234 psql -h iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com -U dbadmin -d lugx_gaming_dev -p 5432
```

## Security Best Practices

### Network Security
- ✅ RDS is in private subnets
- ✅ Security groups restrict access to EKS cluster only
- ✅ No public internet access to database

### Access Control
- ✅ Dedicated database user (`dbadmin`)
- ✅ Strong password stored in Kubernetes secrets
- ✅ Principle of least privilege

### Data Protection
- ✅ Encryption at rest enabled on RDS
- ✅ Encryption in transit using SSL
- ✅ Regular automated backups

## Monitoring and Maintenance

### Database Monitoring
```bash
# Check database performance
./scripts/manage-database.sh stats

# Monitor connection counts
kubectl logs -f <analytics-service-pod> -n lugx-gaming

# Check RDS metrics in CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=iit-test-dev-db \
  --start-time 2025-08-03T00:00:00Z \
  --end-time 2025-08-03T23:59:59Z \
  --period 300 \
  --statistics Average
```

### Regular Maintenance
1. **Weekly**: Check database health and performance
2. **Monthly**: Clean up old analytics data
3. **Quarterly**: Review and optimize indexes
4. **Before releases**: Create database backup

## Architecture Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   EKS Cluster   │    │  RDS Security   │    │   RDS Instance  │
│                 │    │     Group       │    │                 │
│  ┌─────────────┐│    │                 │    │ ┌─────────────┐ │
│  │Gaming Pods  ││────┤Port 5432       ├────┤ │PostgreSQL   │ │
│  └─────────────┘│    │EKS SG -> RDS SG │    │ │Database     │ │
│                 │    │                 │    │ └─────────────┘ │
│  ┌─────────────┐│    └─────────────────┘    └─────────────────┘
│  │Analytics    ││
│  │Pods         ││
│  └─────────────┘│
└─────────────────┘
```

## Configuration Files

### Kubernetes ConfigMap
The database configuration is stored in the `app-config` ConfigMap:
```yaml
data:
  DB_HOST: "iit-test-dev-db.cv0gc48uo7w1.ap-southeast-1.rds.amazonaws.com"
  DB_NAME: "lugx_gaming_dev"
  DB_PORT: "5432"
```

### Kubernetes Secret
Database credentials are stored in the `app-secrets` Secret:
```yaml
stringData:
  DB_USER: "dbadmin"
  DB_PASSWORD: "LionKing1234"
```

## Support

If you encounter issues not covered in this guide:

1. Check the microservice logs: `kubectl logs -f <pod-name> -n lugx-gaming`
2. Verify security group rules
3. Test manual database connection
4. Check AWS RDS console for instance status
5. Review CloudWatch logs for detailed error messages

For additional help, refer to:
- AWS RDS Documentation
- PostgreSQL Documentation
- EKS Networking Guide
