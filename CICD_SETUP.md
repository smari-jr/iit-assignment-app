# GitHub Actions CI/CD Setup Guide

## Overview
This repository includes comprehensive GitHub Actions workflows for automated deployment of the gaming microservices to Amazon EKS.

## Workflows

### 1. Main Deployment Pipeline (`.github/workflows/deploy.yml`)
- **Triggers**: Push to main/develop branches, manual dispatch
- **Jobs**: Test → Build → Deploy → Notify
- **Features**:
  - Automated testing of all services
  - Docker image building and pushing to ECR
  - Kubernetes deployment with kustomize
  - Database security group configuration
  - Deployment verification

### 2. Rollback Pipeline (`.github/workflows/rollback.yml`)
- **Trigger**: Manual dispatch only
- **Purpose**: Emergency rollback to previous versions
- **Features**:
  - Rollback specific services or all services
  - Image verification before rollback
  - Automated deployment verification

## Required GitHub Secrets

Add these secrets to your GitHub repository settings (`Settings > Secrets and variables > Actions`):

```bash
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
```

## AWS IAM Permissions

The AWS user/role needs the following permissions:

### ECR Permissions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage",
                "ecr:DescribeImages",
                "ecr:DescribeRepositories"
            ],
            "Resource": "*"
        }
    ]
}
```

### EKS Permissions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
```

### EC2/VPC Permissions (for security groups)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeSecurityGroups",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DescribeVpcs",
                "rds:DescribeDBInstances"
            ],
            "Resource": "*"
        }
    ]
}
```

## Environment Configuration

### GitHub Environments
Create these environments in GitHub (`Settings > Environments`):

1. **dev** - Development environment
2. **staging** - Staging environment (optional)
3. **prod** - Production environment
4. **rollback** - For rollback operations

### Environment Protection Rules
For production environment, consider adding:
- Required reviewers
- Deployment branches (only main branch)
- Environment secrets

## Usage

### Automatic Deployment
1. **Development**: Push to `develop` branch → Automatic deployment to dev environment
2. **Production**: Push to `main` branch → Automatic deployment to prod environment

### Manual Deployment
1. Go to `Actions` tab in GitHub
2. Select "Deploy Gaming Microservices to EKS"
3. Click "Run workflow"
4. Choose environment and trigger deployment

### Rollback
1. Go to `Actions` tab in GitHub
2. Select "Rollback Deployment"
3. Click "Run workflow"
4. Specify:
   - **rollback_to**: Image tag to rollback to (e.g., `v20250803-171506-fa20cda`)
   - **service**: Service to rollback (`all` or specific service name)

## Monitoring Deployments

### View Deployment Status
```bash
# Check workflow status
gh workflow list

# View specific workflow run
gh run view <run-id>

# Check Kubernetes deployment
kubectl get pods -n lugx-gaming
kubectl get deployments -n lugx-gaming
```

### Get Application URLs
After successful deployment, check the workflow logs for:
- Frontend URL
- Health Dashboard URL
- Port-forward commands if LoadBalancers are pending

## Troubleshooting

### Common Issues

1. **ECR Permission Denied**
   - Verify AWS credentials in GitHub secrets
   - Check ECR repository exists and permissions

2. **kubectl Connection Failed**
   - Verify EKS cluster name in workflow environment variables
   - Check AWS EKS permissions

3. **Image Pull Errors**
   - Ensure ECR images are pushed successfully
   - Verify image tags in kustomization.yaml

4. **Pod Scheduling Issues**
   - Check node capacity and resources
   - Verify PVC storage classes (ClickHouse uses emptyDir now)

### Debug Commands for Local Testing
```bash
# Build and test locally
./scripts/deploy-optimized.sh build-only

# Deploy only (assumes images exist)
./scripts/deploy-optimized.sh deploy-only

# Check deployment status
./scripts/deploy-optimized.sh status
```

## Customization

### Modify Environments
To add staging environment:
1. Create `kustomize/overlays/staging/` directory
2. Update workflow environment references
3. Add staging-specific configuration

### Change Image Registry
Update these values in workflow files:
- `ECR_REGISTRY`: Your ECR registry URL
- `EKS_CLUSTER_NAME`: Your EKS cluster name
- `AWS_REGION`: Your AWS region

### Add Additional Services
1. Add service to build steps in `deploy.yml`
2. Update kustomization update logic
3. Add rollout status check in deployment verification

## Security Best Practices

1. **Use least privilege IAM permissions**
2. **Enable branch protection rules**
3. **Require PR reviews for main branch**
4. **Use environment-specific secrets**
5. **Enable GitHub secret scanning**
6. **Regularly rotate AWS credentials**

## Cost Optimization

The pipeline includes:
- Parallel job execution to reduce runtime
- Image layer caching
- Cleanup of temporary resources
- Efficient Docker builds with platform targeting

## Support

For issues with the CI/CD pipeline:
1. Check workflow logs in GitHub Actions
2. Verify AWS resources and permissions
3. Test deployment script locally
4. Check Kubernetes cluster status
