#!/bin/bash

# Gaming Microservices - Amazon Linux Setup Script
# This script installs Docker, AWS CLI v2, Kubernetes tools, and Python on Amazon Linux

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

success() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
}

print_banner() {
    echo -e "${PURPLE}"
    echo "================================================================="
    echo "    Gaming Microservices - Amazon Linux Environment Setup      "
    echo "================================================================="
    echo -e "${NC}"
    echo -e "${BLUE}This script will install:${NC}"
    echo -e "  🐳 Docker & Docker Compose"
    echo -e "  ☁️  AWS CLI v2"
    echo -e "  ☸️  Kubernetes (kubectl, kustomize, helm)"
    echo -e "  🐍 Python 3.11 & pip"
    echo -e "  📦 Node.js & npm"
    echo -e "  🔧 Development tools"
    echo ""
}

# Check if running on Amazon Linux
check_amazon_linux() {
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot determine OS version"
    fi
    
    if ! grep -q "Amazon Linux" /etc/os-release; then
        error "This script is designed for Amazon Linux. Current OS: $(cat /etc/os-release | grep PRETTY_NAME)"
    fi
    
    # Check Amazon Linux version
    if grep -q "Amazon Linux 2" /etc/os-release; then
        log "Detected Amazon Linux 2"
        export AL_VERSION="2"
    elif grep -q "Amazon Linux release 2023" /etc/os-release; then
        log "Detected Amazon Linux 2023"
        export AL_VERSION="2023"
    else
        warn "Unknown Amazon Linux version, proceeding with AL2 commands"
        export AL_VERSION="2"
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    sudo yum update -y
    
    # Install essential packages
    log "Installing essential development tools..."
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y \
        curl \
        wget \
        unzip \
        git \
        vim \
        htop \
        tree \
        jq \
        yq \
        openssl \
        ca-certificates \
        gnupg \
        lsb-release
    
    success "System packages updated successfully"
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    # Remove any existing Docker installations
    sudo yum remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine 2>/dev/null || true
    
    # Install Docker
    if [[ "$AL_VERSION" == "2023" ]]; then
        sudo yum install -y docker
    else
        sudo amazon-linux-extras install -y docker
    fi
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Install Docker Compose
    log "Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Verify Docker installation
    if docker --version &>/dev/null; then
        success "Docker installed successfully: $(docker --version)"
    else
        error "Docker installation failed"
    fi
    
    if docker-compose --version &>/dev/null; then
        success "Docker Compose installed successfully: $(docker-compose --version)"
    else
        error "Docker Compose installation failed"
    fi
}

# Install AWS CLI v2
install_aws_cli() {
    log "Installing AWS CLI v2..."
    
    # Remove any existing AWS CLI v1
    sudo yum remove -y awscli 2>/dev/null || true
    sudo pip uninstall -y awscli 2>/dev/null || true
    
    # Download and install AWS CLI v2
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install --update
    
    # Create symlink if needed
    sudo ln -sf /usr/local/bin/aws /usr/bin/aws 2>/dev/null || true
    
    # Verify installation
    if aws --version &>/dev/null; then
        success "AWS CLI v2 installed successfully: $(aws --version)"
    else
        error "AWS CLI v2 installation failed"
    fi
    
    # Clean up
    rm -rf /tmp/aws /tmp/awscliv2.zip
}

# Install Python 3.11
install_python() {
    log "Installing Python 3.11..."
    
    if [[ "$AL_VERSION" == "2023" ]]; then
        # Amazon Linux 2023 approach
        sudo yum install -y python3.11 python3.11-pip python3.11-devel
        sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
        sudo alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.11 1
    else
        # Amazon Linux 2 approach
        sudo amazon-linux-extras install -y python3.8
        sudo yum install -y python3-pip python3-devel
        
        # Install Python 3.11 from source if needed
        if ! python3.11 --version &>/dev/null; then
            log "Building Python 3.11 from source..."
            cd /tmp
            wget https://www.python.org/ftp/python/3.11.8/Python-3.11.8.tgz
            tar xzf Python-3.11.8.tgz
            cd Python-3.11.8
            ./configure --enable-optimizations --prefix=/usr/local/python3.11
            make -j$(nproc)
            sudo make altinstall
            
            # Create symlinks
            sudo ln -sf /usr/local/python3.11/bin/python3.11 /usr/local/bin/python3.11
            sudo ln -sf /usr/local/python3.11/bin/pip3.11 /usr/local/bin/pip3.11
            
            # Clean up
            cd /
            rm -rf /tmp/Python-3.11.8*
        fi
    fi
    
    # Install common Python packages
    log "Installing common Python packages..."
    pip3 install --user --upgrade pip setuptools wheel
    pip3 install --user \
        requests \
        boto3 \
        pyyaml \
        jinja2 \
        ansible \
        docker-compose
    
    # Verify installation
    if python3 --version &>/dev/null; then
        success "Python 3 installed successfully: $(python3 --version)"
    else
        error "Python 3 installation failed"
    fi
    
    if pip3 --version &>/dev/null; then
        success "pip3 installed successfully: $(pip3 --version)"
    else
        error "pip3 installation failed"
    fi
}

# Install Node.js and npm
install_nodejs() {
    log "Installing Node.js and npm..."
    
    # Install using NodeSource repository for latest LTS
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
    sudo yum install -y nodejs
    
    # Install global packages
    log "Installing global npm packages..."
    sudo npm install -g \
        yarn \
        pm2 \
        nodemon \
        @aws-cdk/cli \
        serverless
    
    # Verify installation
    if node --version &>/dev/null; then
        success "Node.js installed successfully: $(node --version)"
    else
        error "Node.js installation failed"
    fi
    
    if npm --version &>/dev/null; then
        success "npm installed successfully: $(npm --version)"
    else
        error "npm installation failed"
    fi
}

# Install Kubernetes tools
install_kubernetes_tools() {
    log "Installing Kubernetes tools..."
    
    # Install kubectl
    log "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    # Install kustomize
    log "Installing kustomize..."
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    sudo mv kustomize /usr/local/bin/
    
    # Install Helm
    log "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Install k9s (Kubernetes CLI management tool)
    log "Installing k9s..."
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
    wget -q -O - https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz | tar -xzf - -C /tmp
    sudo mv /tmp/k9s /usr/local/bin/
    
    # Install kubectx and kubens
    log "Installing kubectx and kubens..."
    sudo curl -L https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx -o /usr/local/bin/kubectx
    sudo curl -L https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubens -o /usr/local/bin/kubens
    sudo chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens
    
    # Verify installations
    if kubectl version --client &>/dev/null; then
        success "kubectl installed successfully: $(kubectl version --client --short)"
    else
        error "kubectl installation failed"
    fi
    
    if kustomize version &>/dev/null; then
        success "kustomize installed successfully: $(kustomize version --short)"
    else
        error "kustomize installation failed"
    fi
    
    if helm version &>/dev/null; then
        success "Helm installed successfully: $(helm version --short)"
    else
        error "Helm installation failed"
    fi
}

# Install additional development tools
install_dev_tools() {
    log "Installing additional development tools..."
    
    # Install terraform
    log "Installing Terraform..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum install -y terraform
    
    # Install eksctl
    log "Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    
    # Install AWS Session Manager plugin
    log "Installing AWS Session Manager plugin..."
    cd /tmp
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
    sudo yum install -y session-manager-plugin.rpm
    rm session-manager-plugin.rpm
    
    # Verify installations
    if terraform version &>/dev/null; then
        success "Terraform installed successfully: $(terraform version | head -1)"
    else
        warn "Terraform installation may have failed"
    fi
    
    if eksctl version &>/dev/null; then
        success "eksctl installed successfully: $(eksctl version)"
    else
        warn "eksctl installation may have failed"
    fi
}

# Configure environment
configure_environment() {
    log "Configuring environment..."
    
    # Add paths to .bashrc
    cat >> ~/.bashrc << 'EOF'

# Gaming Microservices Environment
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Docker aliases
alias dps='docker ps'
alias dimg='docker images'
alias dlog='docker logs'
alias dexec='docker exec -it'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'

# AWS aliases
alias awsp='aws configure list-profiles'
alias awsc='aws configure list'

# Development aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd .../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

EOF
    
    # Create kubectl completion
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
    echo 'complete -F __start_kubectl k' >> ~/.bashrc
    
    # Create development directory structure
    mkdir -p ~/projects/gaming-microservices
    mkdir -p ~/.aws
    mkdir -p ~/.kube
    
    success "Environment configured successfully"
}

# Setup gaming microservices specific configuration
setup_gaming_microservices() {
    log "Setting up gaming microservices configuration..."
    
    # Create gaming microservices helper script
    cat > ~/.local/bin/gaming-setup << 'EOF'
#!/bin/bash
# Gaming Microservices Helper Script

case "$1" in
    "aws-configure")
        echo "Configuring AWS CLI for Singapore region..."
        aws configure set region ap-southeast-1
        aws configure set output json
        echo "AWS configuration completed!"
        ;;
    "ecr-login")
        echo "Logging into ECR..."
        aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 036160411895.dkr.ecr.ap-southeast-1.amazonaws.com
        ;;
    "k8s-context")
        echo "Setting up Kubernetes context for gaming microservices..."
        kubectl config set-context gaming-microservices --namespace=gaming-microservices
        kubectl config use-context gaming-microservices
        ;;
    *)
        echo "Gaming Microservices Helper"
        echo "Usage: gaming-setup [command]"
        echo ""
        echo "Commands:"
        echo "  aws-configure  - Configure AWS CLI for Singapore region"
        echo "  ecr-login      - Login to ECR registry"
        echo "  k8s-context    - Setup Kubernetes context"
        ;;
esac
EOF
    
    chmod +x ~/.local/bin/gaming-setup
    
    success "Gaming microservices configuration completed"
}

# Verify all installations
verify_installations() {
    log "Verifying all installations..."
    
    echo -e "${BLUE}=== Installation Verification ===${NC}"
    
    # Docker
    if docker --version &>/dev/null; then
        echo -e "✅ Docker: $(docker --version)"
    else
        echo -e "❌ Docker: Not installed or not working"
    fi
    
    # Docker Compose
    if docker-compose --version &>/dev/null; then
        echo -e "✅ Docker Compose: $(docker-compose --version)"
    else
        echo -e "❌ Docker Compose: Not installed or not working"
    fi
    
    # AWS CLI
    if aws --version &>/dev/null; then
        echo -e "✅ AWS CLI: $(aws --version)"
    else
        echo -e "❌ AWS CLI: Not installed or not working"
    fi
    
    # Python
    if python3 --version &>/dev/null; then
        echo -e "✅ Python: $(python3 --version)"
    else
        echo -e "❌ Python: Not installed or not working"
    fi
    
    # Node.js
    if node --version &>/dev/null; then
        echo -e "✅ Node.js: $(node --version)"
    else
        echo -e "❌ Node.js: Not installed or not working"
    fi
    
    # npm
    if npm --version &>/dev/null; then
        echo -e "✅ npm: $(npm --version)"
    else
        echo -e "❌ npm: Not installed or not working"
    fi
    
    # kubectl
    if kubectl version --client &>/dev/null; then
        echo -e "✅ kubectl: $(kubectl version --client --short)"
    else
        echo -e "❌ kubectl: Not installed or not working"
    fi
    
    # kustomize
    if kustomize version &>/dev/null; then
        echo -e "✅ kustomize: $(kustomize version --short)"
    else
        echo -e "❌ kustomize: Not installed or not working"
    fi
    
    # Helm
    if helm version &>/dev/null; then
        echo -e "✅ Helm: $(helm version --short)"
    else
        echo -e "❌ Helm: Not installed or not working"
    fi
    
    # Terraform
    if terraform version &>/dev/null; then
        echo -e "✅ Terraform: $(terraform version | head -1)"
    else
        echo -e "❌ Terraform: Not installed or not working"
    fi
    
    # eksctl
    if eksctl version &>/dev/null; then
        echo -e "✅ eksctl: $(eksctl version)"
    else
        echo -e "❌ eksctl: Not installed or not working"
    fi
}

# Print completion message
print_completion() {
    echo ""
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}=== Next Steps ===${NC}"
    echo -e "1. ${YELLOW}Log out and log back in${NC} to apply group changes (Docker)"
    echo -e "2. ${YELLOW}Source your bashrc:${NC} source ~/.bashrc"
    echo -e "3. ${YELLOW}Configure AWS:${NC} gaming-setup aws-configure"
    echo -e "4. ${YELLOW}Test Docker:${NC} docker run hello-world"
    echo -e "5. ${YELLOW}Clone your repository:${NC}"
    echo -e "   git clone https://github.com/smari-jr/iit-assignment-app.git"
    echo ""
    echo -e "${BLUE}=== Useful Commands ===${NC}"
    echo -e "• ${YELLOW}gaming-setup${NC} - Gaming microservices helper commands"
    echo -e "• ${YELLOW}k9s${NC} - Kubernetes cluster management UI"
    echo -e "• ${YELLOW}kubectl get nodes${NC} - Check Kubernetes cluster"
    echo -e "• ${YELLOW}docker ps${NC} - List running containers"
    echo -e "• ${YELLOW}aws configure${NC} - Configure AWS credentials"
    echo ""
    echo -e "${CYAN}Your Amazon Linux environment is now ready for gaming microservices development! 🚀${NC}"
}

# Main execution
main() {
    print_banner
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
    
    # Verify we're on Amazon Linux
    check_amazon_linux
    
    # Create local bin directory
    mkdir -p ~/.local/bin
    
    # Main installation steps
    update_system
    install_docker
    install_aws_cli
    install_python
    install_nodejs
    install_kubernetes_tools
    install_dev_tools
    configure_environment
    setup_gaming_microservices
    
    # Verify everything was installed correctly
    verify_installations
    
    # Print completion message
    print_completion
}

# Run main function
main "$@"
