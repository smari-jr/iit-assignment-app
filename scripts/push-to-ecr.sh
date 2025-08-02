#!/bin/bash

# ECR Push Script for Gaming Microservices
# This script builds Docker images and pushes them to Amazon ECR

set -e

# Configuration - Singapore region
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
PROJECT_NAME="gaming-microservices"

# Generate image tag based on timestamp and git commit (if available)
generate_image_tag() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local git_commit=""
    
    # Try to get git commit hash (short version)
    if git rev-parse --short HEAD &> /dev/null; then
        git_commit="-$(git rev-parse --short HEAD)"
    fi
    
    echo "v${timestamp}${git_commit}"
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
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
    exit 1
}

# Get AWS Account ID
get_aws_account_id() {
    local account_id
    account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    if [ -z "$account_id" ]; then
        print_error "Could not get AWS Account ID. Please check your AWS credentials."
    fi
    echo "$account_id"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run: aws configure"
    fi
    
    print_success "Prerequisites check passed"
}

# Login to ECR
ecr_login() {
    print_status "Logging in to Amazon ECR..."
    local aws_account_id=$(get_aws_account_id)
    
    if ! aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com; then
        print_error "Failed to login to ECR"
    fi
    
    print_success "Successfully logged in to ECR"
}

# Create ECR repository if it doesn't exist
create_ecr_repo() {
    local repo_name=$1
    print_status "Ensuring ECR repository exists: $repo_name"
    
    if aws ecr describe-repositories --repository-names $repo_name --region $AWS_REGION &> /dev/null; then
        print_status "Repository $repo_name already exists"
    else
        if aws ecr create-repository --repository-name $repo_name --region $AWS_REGION &> /dev/null; then
            print_success "Created repository: $repo_name"
        else
            print_error "Failed to create repository: $repo_name"
        fi
    fi
}

# Build and push image
build_and_push() {
    local service_name=$1
    local service_path=$2
    local aws_account_id=$(get_aws_account_id)
    local repo_name="$PROJECT_NAME/$service_name"
    local image_tag="${IMAGE_TAG:-$(generate_image_tag)}"
    local full_image_name="$aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$repo_name:$image_tag"
    
    print_status "Building and pushing $service_name (tag: $image_tag)..."
    
    # Check if service directory exists
    if [ ! -d "$service_path" ]; then
        print_error "Service directory not found: $service_path"
    fi
    
    # Check if Dockerfile exists
    if [ ! -f "$service_path/Dockerfile" ]; then
        print_error "Dockerfile not found in: $service_path"
    fi
    
    # Create ECR repository
    create_ecr_repo $repo_name
    
    # Build image
    print_status "Building Docker image for $service_name..."
    if ! docker build -t $repo_name:$image_tag $service_path; then
        print_error "Failed to build Docker image for $service_name"
    fi
    
    # Tag image for ECR
    docker tag $repo_name:$image_tag $full_image_name
    
    # Push image
    print_status "Pushing $full_image_name..."
    if ! docker push $full_image_name; then
        print_error "Failed to push Docker image for $service_name"
    fi
    
    print_success "Successfully pushed $service_name: $full_image_name"
    echo "$service_name=$full_image_name" >> image_uris.env
    
    # Also tag as latest for convenience
    local latest_image_name="$aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$repo_name:latest"
    docker tag $repo_name:$image_tag $latest_image_name
    
    print_status "Pushing latest tag: $latest_image_name..."
    if ! docker push $latest_image_name; then
        print_warning "Failed to push latest tag, but versioned tag succeeded"
    else
        print_success "Also pushed as latest: $latest_image_name"
    fi
}

# Update Kustomization with ECR image URIs
update_kustomization() {
    print_status "Updating Kustomization files with ECR image URIs..."
    
    local kustomization_file="kustomize/base/kustomization.yaml"
    local aws_account_id=$(get_aws_account_id)
    local image_tag="${IMAGE_TAG:-$(generate_image_tag)}"
    
    # Check if kustomization file exists
    if [ ! -f "$kustomization_file" ]; then
        print_error "Kustomization file not found: $kustomization_file"
    fi
    
    # Create backup
    cp "$kustomization_file" "${kustomization_file}.backup"
    print_status "Created backup: ${kustomization_file}.backup"
    
    # Update image references using sed (cross-platform compatible)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|newName: gaming-frontend|newName: $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME/frontend|g" "$kustomization_file"
        sed -i '' "s|newName: gaming-service|newName: $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME/gaming-service|g" "$kustomization_file"
        sed -i '' "s|newName: order-service|newName: $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME/order-service|g" "$kustomization_file"
        sed -i '' "s|newName: analytics-service|newName: $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME/analytics-service|g" "$kustomization_file"
        
        # Update tags to use the versioned tag
        sed -i '' "s|newTag: latest|newTag: $image_tag|g" "$kustomization_file"
    else
        # Linux
        sed -i "s|newName: gaming-frontend|newName: $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME/frontend|g" "$kustomization_file"
        sed -i "s|newName: gaming-service|newName: $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME/gaming-service|g" "$kustomization_file"
        sed -i "s|newName: order-service|newName: $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME/order-service|g" "$kustomization_file"
        sed -i "s|newName: analytics-service|newName: $aws_account_id.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME/analytics-service|g" "$kustomization_file"
        
        # Update tags to use the versioned tag
        sed -i "s|newTag: latest|newTag: $image_tag|g" "$kustomization_file"
    fi
    
    print_success "Updated $kustomization_file with ECR image URIs (tag: $image_tag)"
}

# Main execution
main() {
    local aws_account_id=$(get_aws_account_id)
    local image_tag="${IMAGE_TAG:-$(generate_image_tag)}"
    
    print_status "=== ECR Push Script for Gaming Microservices ==="
    print_status "AWS Region: $AWS_REGION"
    print_status "AWS Account ID: $aws_account_id"
    print_status "Project: $PROJECT_NAME"
    print_status "Image Tag: $image_tag"
    echo ""
    
    # Clean up previous run
    rm -f image_uris.env
    
    # Check prerequisites
    check_prerequisites
    
    # Login to ECR
    ecr_login
    
    # Build and push each service
    print_status "Building and pushing microservices..."
    echo ""
    
    # Build and push each service (using simple arrays for compatibility)
    build_and_push "frontend" "./services/frontend"
    echo ""
    
    build_and_push "gaming-service" "./services/gaming-service"
    echo ""
    
    build_and_push "order-service" "./services/order-service"
    echo ""
    
    build_and_push "analytics-service" "./services/analytics-service"
    echo ""
    
    # Update Kustomization files
    update_kustomization
    
    echo ""
    print_success "🎉 All images pushed successfully!"
    
    if [ -f "image_uris.env" ]; then
        echo ""
        print_status "=== Image URIs ==="
        cat image_uris.env
    fi
    
    echo ""
    print_status "=== Next Steps ==="
    echo "1. Review the updated kustomization.yaml file"
    echo "2. Deploy to EKS: kubectl apply -k kustomize/base/"
    echo "3. Verify deployment: kubectl get pods -n gaming-microservices"
}

# Handle script arguments
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "🚀 ECR Push Script for Gaming Microservices"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION      AWS region for ECR (default: ap-southeast-1 - Singapore)"
    echo "  IMAGE_TAG       Custom image tag (default: auto-generated timestamp + git commit)"
    echo ""
    echo "Examples:"
    echo "  $0                           # Use auto-generated tag (e.g., v20250803-143052-a1b2c3d)"
    echo "  IMAGE_TAG=v1.0.0 $0          # Use custom tag v1.0.0"
    echo "  IMAGE_TAG=release-2024 $0    # Use custom tag release-2024"
    echo ""
    echo "Prerequisites:"
    echo "  - AWS CLI configured with ECR permissions"
    echo "  - Docker installed and running"
    echo "  - Git (optional, for commit hash in auto-generated tags)"
    echo ""
    echo "This script will:"
    echo "  1. Generate a proper image tag (timestamp + git commit or custom)"
    echo "  2. Build Docker images for all microservices"
    echo "  3. Create ECR repositories if they don't exist"
    echo "  4. Push images with versioned tag AND latest tag"
    echo "  5. Update kustomization.yaml with versioned ECR image URIs"
    exit 0
fi

# Run main function
main "$@"
