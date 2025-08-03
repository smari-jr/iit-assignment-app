# LUGX Gaming Platform - Cloud-Native Microservices

A modern cloud-native gaming platform built with microservices architecture, featuring automated CI/CD pipelines, Kubernetes deployment with Kustomize, and comprehensive service-to-service communication.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Frontend      │    │  Gaming Service  │    │  Order Service  │
│   (React)       │    │   (Node.js)      │    │   (Node.js)     │
│   Port: 80      │    │   Port: 3001     │    │   Port: 3002    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────┐     │     ┌─────────────────┐
         │ Analytics Svc   │     │     │   PostgreSQL    │
         │  (Node.js)      │─────┼─────│   Database      │
         │  Port: 3003     │     │     │   Port: 5432    │
         └─────────────────┘     │     └─────────────────┘
                 │               │
                 │               │
         ┌─────────────────┐     │
         │   ClickHouse    │─────┘
         │   Analytics DB  │
         │   Port: 8123    │
         └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Docker & Docker Compose** - Container orchestration
- **kubectl** - Kubernetes CLI tool
- **kustomize** - Kubernetes configuration management
- **AWS CLI** - For EKS deployment (configured with credentials)
- **EKS Cluster Access** - Access to EKS cluster `iit-test-dev-eks` (or modify cluster name in script)
- **Node.js 18+** - For local development (optional)

### 1. Production Deployment (Recommended)

```bash
# Clone the repository
git clone https://github.com/smari-jr/iit-assignment-app.git
cd microservices

# Configure EKS cluster access (if different from default)
# Edit scripts/deploy-optimized.sh and change EKS_CLUSTER_NAME variable
# Current default: EKS_CLUSTER_NAME="iit-test-dev-eks"

# Deploy to Kubernetes (builds, pushes to ECR, and deploys)
./scripts/deploy-optimized.sh

# Or deploy specific components
./scripts/deploy-optimized.sh build-only    # Build and push images only
./scripts/deploy-optimized.sh deploy-only   # Deploy using existing images
./scripts/deploy-optimized.sh verify        # Verify deployment status
```

### 2. Local Development

```bash
# Start all services with Docker Compose
docker-compose up -d

# Access the application
# - Frontend: http://localhost:3000
# - Gaming Service: http://localhost:3001
# - Order Service: http://localhost:3002
# - Analytics Service: http://localhost:3003

# Stop services
docker-compose down
```

### 3. Verification

```bash
# Check Kubernetes deployment status
kubectl get pods -n gaming-microservices
kubectl get services -n gaming-microservices

# Or use the built-in verification
./scripts/deploy-optimized.sh verify
```

## 📦 Services

| Service | Port | Technology | Purpose | Database |
|---------|------|------------|---------|-----------|
| **Frontend** | 80 | React + Nginx | User interface and routing | - |
| **Gaming Service** | 3001 | Node.js + Express | Authentication, user management, products | PostgreSQL |
| **Order Service** | 3002 | Node.js + Express | Order processing and payments | PostgreSQL |
| **Analytics Service** | 3003 | Node.js + Express | Event tracking and analytics | PostgreSQL + ClickHouse |

### Service Communication

Services communicate via Kubernetes ClusterIP services using DNS-based service discovery:
- `gaming-service:3001` - Gaming service endpoint
- `order-service:3002` - Order service endpoint  
- `analytics-service:3003` - Analytics service endpoint
- `postgres-service:5432` - PostgreSQL database
- `clickhouse-service:8123` - ClickHouse analytics database

## 🛠️ Infrastructure

### Kubernetes Configuration

The platform uses **Kustomize** for Kubernetes configuration management:

```
kustomize/base/
├── namespace.yaml           # gaming-microservices namespace
├── secrets.yaml            # Secrets and ConfigMap
├── postgres.yaml           # PostgreSQL database + service
├── clickhouse.yaml         # ClickHouse analytics DB + service  
├── frontend.yaml           # React frontend + service
├── gaming-service.yaml     # Gaming microservice + service
├── order-service.yaml      # Order processing + service
├── analytics-service.yaml  # Analytics processing + service
├── ingress.yaml            # Ingress controller configuration
├── network-policy.yaml     # Service communication policies
├── health-check.yaml       # Health monitoring service
└── kustomization.yaml      # Kustomize configuration
```

### AWS Infrastructure

- **EKS Cluster**: `036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/gaming-microservices/`
- **ECR Registry**: Container image registry
- **Load Balancer**: AWS Application Load Balancer via Ingress
- **Persistent Storage**: EBS volumes for database persistence

##  ClickHouse Analytics Features

The Analytics Service provides:
- **Page Visit Tracking**: Real-time page view analytics
- **User Behavior**: Session tracking and user journey analysis
- **High Performance**: ClickHouse for fast analytical queries on large datasets
- **Data Retention**: Configurable TTL policies for data lifecycle management

### ClickHouse Schema
```sql
CREATE TABLE page_visits (
    id UUID DEFAULT generateUUIDv4(),
    user_id String,
    page_path String,
    timestamp DateTime,
    session_id String,
    user_agent String,
    ip_address String,
    referrer String,
    country String,
    device_type String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, user_id)
TTL timestamp + INTERVAL 12 MONTH;
```

## � API Documentation

### Gaming Service
- `GET /api/games` - List all games
- `POST /api/games` - Create new game
- `GET /api/games/:id` - Get game details
- `GET /health` - Health check

### Order Service
- `POST /api/orders` - Create new order
- `GET /api/orders/:id` - Get order status
- `PUT /api/orders/:id` - Update order
- `GET /health` - Health check

### Analytics Service
- `POST /api/analytics/track` - Track page visit
- `GET /api/analytics/stats` - Get analytics data
- `GET /api/analytics/visits` - Get page visit statistics
- `GET /health` - Health check

## 🔧 Development Workflow

### Local Testing

```bash
# Test individual services
docker-compose logs frontend
docker-compose logs gaming-service

# Access databases
docker-compose exec postgres psql -U postgres -d lugx_gaming
docker-compose exec clickhouse clickhouse-client
```

### Adding a New Service

1. Create service directory: `services/new-service/`
2. Add Dockerfile and application code
3. Create Kubernetes manifests in `kustomize/base/new-service.yaml`
4. Update `kustomize/base/kustomization.yaml`
5. Update deployment script if needed

## �️ Security

### Secrets Management
- Environment variables stored in Kubernetes secrets
- ECR authentication via IAM roles
- Database credentials managed through Kubernetes

### Network Security
- Services communicate internally via Kubernetes service discovery
- External access controlled via AWS ALB
- Database access restricted to internal services

## 🚀 Production Deployment

### Prerequisites

1. **AWS Setup**:
   ```bash
   aws configure
   aws eks update-kubeconfig --region ap-southeast-1 --name your-cluster-name
   ```

2. **Required AWS Permissions**:
   - EKS cluster access
   - ECR push/pull permissions

### Scaling Configuration

Production environment includes:
- **Frontend**: 2 replicas
- **Gaming Service**: 2 replicas  
- **Order Service**: 2 replicas
- **Analytics Service**: 2 replicas
- **Databases**: Single replicas with persistent storage

## 🛠️ Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check Docker daemon
docker info

# Clean up Docker resources
docker system prune -f
```

#### Deployment Issues
```bash
# Check Kubernetes cluster connection
kubectl cluster-info

# View pod status and logs
kubectl get pods -n gaming-microservices
kubectl describe pod <pod-name> -n gaming-microservices
kubectl logs <pod-name> -n gaming-microservices
```

#### Service Communication Issues
```bash
# Test service connectivity
kubectl exec -it <frontend-pod> -n gaming-microservices -- curl http://gaming-service:3001/health
```

## 🎯 Features Implemented

1. **Microservices Architecture**: Four independent services with clear separation of concerns
2. **ClickHouse Integration**: High-performance analytics database for tracking user behavior
3. **Containerization**: Complete Docker setup with Kubernetes orchestration
4. **Kustomize Templates**: Professional Kubernetes configuration management
5. **CI/CD Pipeline**: Automated deployment scripts
6. **AWS EKS Integration**: Production-ready cloud deployment
7. **Security**: JWT authentication, input validation, secure container practices
8. **Monitoring**: Health check endpoints and comprehensive logging
9. **Scalability**: Production-ready replica configurations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

**LUGX Gaming Platform** - Built with ❤️ for cloud-native gaming experiences 🚀
