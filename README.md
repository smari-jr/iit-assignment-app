# LUGX Gaming Platform - Cloud-Native Microservices

A modern cloud-native gaming platform built with microservices architecture, featuring automated CI/CD pipelines, Kubernetes deployment with Kustomize, and comprehensive developer tooling.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Frontend      │    │  Gaming Service  │    │  Order Service  │
│   (React)       │    │   (Node.js)      │    │   (Node.js)     │
│   Port: 80      │    │   Port: 3000     │    │   Port: 3000    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────┐     │     ┌─────────────────┐
         │ Analytics Svc   │     │     │   PostgreSQL    │
         │  (Node.js)      │─────┼─────│   Database      │
         │  Port: 3000     │     │     │   Port: 5432    │
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

- Docker & Docker Compose
- Node.js 16+ (for local development)
- kubectl (for Kubernetes deployment)
- AWS CLI (for EKS deployment)

### 1. Initial Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd microservices

# Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 2. Local Development

```bash
# Start all services locally
make dev
# or
./scripts/dev-helper.sh dev

# Build specific service
make build
./scripts/dev-helper.sh build frontend

# Run tests
make test
./scripts/dev-helper.sh test all

# Check status
make status
```

### 3. Kubernetes Deployment

```bash
# Deploy to development environment
make kustomize-dev

# Deploy to production environment
make kustomize-prod

# Build Kustomize manifests locally
./scripts/dev-helper.sh kustomize-build dev
```

## 📦 Services

### Frontend
- **Technology**: React.js with nginx
- **Port**: 80
- **Function**: User interface for the gaming platform
- **Location**: `services/frontend/`

### Gaming Service
- **Technology**: Node.js
- **Port**: 3000
- **Function**: Core gaming logic and game management
- **Database**: PostgreSQL
- **Location**: `services/gaming-service/`

### Order Service
- **Technology**: Node.js
- **Port**: 3000
- **Function**: Handle in-game purchases and transactions
- **Database**: PostgreSQL
- **Location**: `services/order-service/`

### Analytics Service
- **Technology**: Node.js
- **Port**: 3000
- **Function**: Process and analyze gaming metrics
- **Database**: ClickHouse (primary), PostgreSQL (metadata)
- **Location**: `services/analytics-service/`

## 🛠️ Infrastructure

### Kubernetes with Kustomize

The platform uses Kustomize for Kubernetes configuration management:

```
kustomize/
├── base/                 # Base Kubernetes manifests
│   ├── namespace.yaml
│   ├── config.yaml      # ConfigMaps and Secrets
│   ├── frontend.yaml
│   ├── gaming-service.yaml
│   ├── order-service.yaml
│   ├── analytics-service.yaml
│   ├── postgres.yaml
│   ├── clickhouse.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/             # Development environment
    │   ├── config-patch.yaml
    │   └── kustomization.yaml
    └── prod/            # Production environment
        └── kustomization.yaml
```

### AWS Infrastructure

- **EKS Cluster**: `lugx-gaming-cluster`
- **ECR Repositories**: 
  - `036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/lugx-gaming/frontend`
  - `036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/lugx-gaming/gaming-service`
  - `036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/lugx-gaming/order-service`
  - `036160411895.dkr.ecr.ap-southeast-1.amazonaws.com/lugx-gaming/analytics-service`
- **Load Balancer**: AWS Application Load Balancer
- **Storage**: EBS volumes for persistent data

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The CI/CD pipeline (`.github/workflows/deploy.yml`) includes:

1. **Build Stage**: 
   - Build Docker images for all services
   - Push images to Amazon ECR
   - Tag images based on branch/environment

2. **Deploy Stage**:
   - Use Kustomize to generate environment-specific manifests
   - Deploy to EKS cluster
   - Wait for rollout completion

3. **Health Check Stage**:
   - Verify all services are running
   - Run basic health checks

### Deployment Environments

- **Development** (`develop` branch): Single replicas, dev configurations
- **Production** (`main` branch): Multiple replicas, production configurations

### Triggering Deployments

```bash
# Push to develop branch (deploys to dev)
git push origin develop

# Push to main branch (deploys to prod)
git push origin main
```

## 🔧 Development Workflow

### Adding a New Service

1. Create service directory: `services/new-service/`
2. Add Dockerfile and application code
3. Create Kubernetes manifests in `kustomize/base/new-service.yaml`
4. Update `kustomize/base/kustomization.yaml`
5. Add environment-specific configurations in overlays
6. Update CI/CD pipeline if needed

### Local Testing

```bash
# Test specific service
./scripts/dev-helper.sh test gaming-service

# Build and test all
./scripts/dev-helper.sh build all
./scripts/dev-helper.sh test all

# Start development environment
./scripts/dev-helper.sh dev
```

### Database Management

#### PostgreSQL (Primary Database)
- **Development**: `localhost:5432`
- **Production**: Managed within Kubernetes cluster
- **Credentials**: Stored in Kubernetes secrets

#### ClickHouse (Analytics Database)  
- **Development**: `localhost:8123`
- **Production**: Managed within Kubernetes cluster
- **Use case**: High-performance analytics and metrics

## 📊 ClickHouse Analytics Features implemented in original assignment

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

## 📊 Monitoring and Observability

### Health Checks

All services expose health check endpoints:
- **Frontend**: `GET /` (returns 200 if healthy)
- **Backend Services**: `GET /health` (returns service status)

### Logging

```bash
# View logs for all services
make logs

# View logs for specific service
./scripts/dev-helper.sh logs gaming-service

# Kubernetes logs
kubectl logs -l app=gaming-service -n lugx-gaming
```

### Status Monitoring

```bash
# Check all services status
make status

# Kubernetes pod status
kubectl get pods -n lugx-gaming

# Service endpoints
kubectl get services -n lugx-gaming

# Ingress status
kubectl get ingress -n lugx-gaming
```

## 🔐 Security

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
   aws eks update-kubeconfig --region ap-southeast-1 --name lugx-gaming-cluster
   ```

2. **Required Secrets in GitHub**:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

### Deployment Process

1. **Push to main branch** triggers production deployment
2. **Images are built** and pushed to ECR
3. **Kustomize generates** production manifests
4. **kubectl applies** changes to EKS cluster
5. **Health checks verify** deployment success

### Scaling

Production environment includes:
- **Frontend**: 3 replicas
- **Gaming Service**: 3 replicas  
- **Order Service**: 2 replicas
- **Analytics Service**: 2 replicas
- **Databases**: Single replicas with persistent storage

## 📝 API Documentation from original assignment

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

## 🛠️ Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check Docker daemon
docker info

# Clean up Docker resources
make clean
```

#### Deployment Issues
```bash
# Check Kubernetes cluster connection
kubectl cluster-info

# View pod status and logs
kubectl get pods -n lugx-gaming
kubectl describe pod <pod-name> -n lugx-gaming
kubectl logs <pod-name> -n lugx-gaming
```

#### Service Communication Issues
```bash
# Test service connectivity
kubectl exec -it <frontend-pod> -n lugx-gaming -- curl http://gaming-service:3000/health
```

### Debug Commands

```bash
# Full system status
./scripts/dev-helper.sh status

# View recent logs
./scripts/dev-helper.sh logs all

# Rebuild everything
make clean
make build

# Reset Kubernetes deployment
kubectl delete namespace lugx-gaming
make kustomize-dev
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Docker Documentation](https://docs.docker.com/)

## 🎯 Features Implemented

1. **Microservices Architecture**: Four independent services with clear separation of concerns
2. **ClickHouse Integration**: High-performance analytics database for tracking user behavior
3. **Containerization**: Complete Docker setup with Kubernetes orchestration
4. **Kustomize Templates**: Professional Kubernetes configuration management
5. **CI/CD Pipeline**: Automated GitHub Actions workflow for build and deployment
6. **AWS EKS Integration**: Production-ready cloud deployment
7. **Developer Tooling**: Comprehensive scripts and automation for development workflow
8. **Security**: JWT authentication, input validation, secure container practices
9. **Monitoring**: Health check endpoints and comprehensive logging
10. **Scalability**: Environment-specific replica configurations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

**LUGX Gaming Platform** - Built with ❤️ for cloud-native gaming experiences 🚀

## 🏗️ Architecture

### Services
- **Frontend**: React-based gaming platform UI
- **Gaming Service**: Core gaming logic and game management  
- **Order Service**: Purchase and transaction handling
- **Analytics Service**: User analytics and tracking with ClickHouse integration

### Technology Stack
- **Frontend**: React 18, CSS3, Modern JavaScript
- **Backend**: Node.js, Express.js
- **Database**: PostgreSQL (primary), ClickHouse (analytics)
- **Containerization**: Docker, Docker Compose

## � Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for development)

### Run the Application

1. **Start all services**:
```bash
docker-compose up -d
```

2. **Access the application**:
- Frontend: http://localhost:3000
- Gaming Service: http://localhost:3001
- Order Service: http://localhost:3002
- Analytics Service: http://localhost:3003
- PostgreSQL: localhost:5432
- ClickHouse: localhost:8123

3. **Stop services**:
```bash
docker-compose down
```

## 📦 Services Overview

### Frontend Service (Port 3000)
- **Technology**: React 18, CSS3, nginx
- **Features**: Gaming platform UI, responsive design
- **Container**: Multi-stage build with Alpine Linux

### Gaming Service (Port 3001)
- **Technology**: Node.js, Express
- **Features**: Game management, user sessions, leaderboards
- **Database**: PostgreSQL

### Order Service (Port 3002)
- **Technology**: Node.js, Express
- **Features**: Purchase processing, payment handling, order tracking
- **Database**: PostgreSQL

### Analytics Service (Port 3003)
- **Technology**: Node.js, Express, ClickHouse
- **Features**: Real-time analytics, page tracking, user behavior analysis
- **Database**: PostgreSQL (metadata) + ClickHouse (time-series data)

## 🗄️ Database Configuration

### PostgreSQL
```yaml
Host: postgres
Port: 5432
Database: lugx_gaming
Username: postgres
Password: postgres123
```

### ClickHouse
```yaml
Host: clickhouse
Port: 8123
Database: analytics
Username: default
Password: clickhouse123
```

## 📊 ClickHouse Analytics Features

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

## 🔧 Development

### Local Development
```bash
# Start services in development mode
docker-compose up -d

# View logs
docker-compose logs -f

# Rebuild a specific service
docker-compose up -d --build frontend

# Stop and remove everything
docker-compose down -v
```

### Environment Variables
Configuration is stored in `deploy/.env.dev`:
- Database connections
- ClickHouse settings
- JWT secrets
- API URLs

## 🛡️ Security Features

### Container Security
- Non-root users in all containers
- Minimal Alpine Linux base images
- Multi-stage Docker builds
- Security hardening practices

### Application Security
- Input validation and sanitization
- JWT token authentication
- Environment-based configuration
- CORS configuration

## 📝 API Documentation

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

## � Monitoring and Troubleshooting

### Check Service Status
```bash
# View all containers
docker-compose ps

# Check specific service logs
docker-compose logs frontend
docker-compose logs analytics-service

# Access database
docker-compose exec postgres psql -U postgres -d lugx_gaming
docker-compose exec clickhouse clickhouse-client --password clickhouse123
```

### Common Issues

#### Database Connection Issues
```bash
# Restart database services
docker-compose restart postgres clickhouse

# Check database logs
docker-compose logs postgres
docker-compose logs clickhouse
```

#### Build Issues
```bash
# Clean rebuild
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

## 📈 Performance Features

### Database Optimization
- PostgreSQL connection pooling
- ClickHouse partitioning by month
- Optimized indexes for common queries
- Automated data cleanup policies

### Container Optimization
- Multi-stage Docker builds
- Layer caching for faster builds
- Resource-efficient Alpine Linux base images
- Proper health checks

## 🎯 Assignment Features Implemented

1. **Microservices Architecture**: Four independent services with clear separation of concerns
2. **ClickHouse Integration**: High-performance analytics database for tracking user behavior
3. **Containerization**: Complete Docker setup with compose orchestration
4. **Database Design**: PostgreSQL for transactional data, ClickHouse for analytics
5. **API Design**: RESTful APIs with proper error handling and validation
6. **Security**: JWT authentication, input validation, secure container practices
7. **Monitoring**: Health check endpoints and comprehensive logging

---

**Ready to run! 🚀 Use `docker-compose up -d` to start the entire platform.**
