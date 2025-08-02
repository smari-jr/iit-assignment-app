# ECR Push Guide

## Overview
The `push-to-ecr.sh` script has been simplified and optimized for pushing Docker images to Amazon ECR in the Singapore region.

## Prerequisites
1. **AWS CLI**: Install and configure with ECR permissions
   ```bash
   aws configure
   ```

2. **Docker**: Install Docker and ensure it's running
   ```bash
   docker --version
   ```

3. **AWS Permissions**: Ensure your AWS credentials have the following permissions:
   - `ecr:GetAuthorizationToken`
   - `ecr:BatchCheckLayerAvailability`
   - `ecr:GetDownloadUrlForLayer`
   - `ecr:BatchGetImage`
   - `ecr:BatchImportLayerPart`
   - `ecr:CreateRepository`
   - `ecr:InitiateLayerUpload`
   - `ecr:UploadLayerPart`
   - `ecr:CompleteLayerUpload`
   - `ecr:PutImage`

## Usage

### Basic Usage
```bash
# Navigate to project directory
cd /path/to/microservices

# Run the script
./scripts/push-to-ecr.sh
```

### With Custom Region (if needed)
```bash
# Set region environment variable
export AWS_REGION=ap-southeast-1  # Singapore (default)

# Run the script
./scripts/push-to-ecr.sh
```

### Help
```bash
./scripts/push-to-ecr.sh --help
```

## What the Script Does

1. **Prerequisites Check**: Verifies AWS CLI, Docker, and credentials
2. **ECR Login**: Authenticates Docker with Amazon ECR
3. **Repository Creation**: Creates ECR repositories if they don't exist
4. **Image Building**: Builds Docker images for all services:
   - frontend
   - gaming-service
   - order-service
   - analytics-service
5. **Image Pushing**: Pushes images to ECR with latest tag
6. **Kustomization Update**: Updates `kustomize/base/kustomization.yaml` with ECR image URIs

## Output Files

- `image_uris.env`: Contains the ECR image URIs for each service
- `kustomize/base/kustomization.yaml.backup`: Backup of original kustomization file

## Troubleshooting

### Common Issues

1. **AWS Credentials Not Configured**
   ```bash
   aws configure
   # Enter your Access Key ID, Secret Access Key, and region
   ```

2. **Docker Not Running**
   ```bash
   # Start Docker Desktop or Docker service
   sudo systemctl start docker  # Linux
   # Or start Docker Desktop app on Mac/Windows
   ```

3. **Insufficient ECR Permissions**
   - Check IAM user/role has ECR permissions
   - Verify the AWS region is correct

4. **Build Failures**
   - Check Dockerfile syntax in each service
   - Ensure all dependencies are available

### Verification

After successful push, verify images in ECR:
```bash
aws ecr list-images --repository-name gaming-microservices/frontend --region ap-southeast-1
aws ecr list-images --repository-name gaming-microservices/gaming-service --region ap-southeast-1
aws ecr list-images --repository-name gaming-microservices/order-service --region ap-southeast-1
aws ecr list-images --repository-name gaming-microservices/analytics-service --region ap-southeast-1
```

## Next Steps

After successful ECR push:

1. **Review Updated Files**:
   ```bash
   cat kustomize/base/kustomization.yaml
   cat image_uris.env
   ```

2. **Deploy to EKS**:
   ```bash
   kubectl apply -k kustomize/base/
   ```

3. **Verify Deployment**:
   ```bash
   kubectl get pods -n gaming-microservices
   kubectl get services -n gaming-microservices
   ```

## Region Configuration

The script defaults to Singapore region (`ap-southeast-1`). To use a different region:

```bash
export AWS_REGION=us-west-2  # Example: US West (Oregon)
./scripts/push-to-ecr.sh
```

Available ECR regions: https://docs.aws.amazon.com/general/latest/gr/ecr.html
