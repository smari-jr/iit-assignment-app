# Gaming Microservices - Service Communication Guide

## Service Architecture Overview

This document outlines how the Kubernetes services communicate with each other in the gaming microservices architecture.

## Service Endpoints

### Frontend Service
- **Service Name**: `frontend-service`
- **Port**: 80
- **Type**: ClusterIP
- **Connects to**: 
  - Gaming Service (gaming-service:3001)
  - Order Service (order-service:3002)
  - Analytics Service (analytics-service:3003)

### Gaming Service
- **Service Name**: `gaming-service`
- **Port**: 3001
- **Type**: ClusterIP
- **Connects to**:
  - PostgreSQL Database (postgres-service:5432)
  - Order Service (order-service:3002)
  - Analytics Service (analytics-service:3003)

### Order Service
- **Service Name**: `order-service`
- **Port**: 3002
- **Type**: ClusterIP
- **Connects to**:
  - PostgreSQL Database (postgres-service:5432)
  - Gaming Service (gaming-service:3001)
  - Analytics Service (analytics-service:3003)

### Analytics Service
- **Service Name**: `analytics-service`
- **Port**: 3003
- **Type**: ClusterIP
- **Connects to**:
  - PostgreSQL Database (postgres-service:5432)
  - ClickHouse Database (clickhouse-service:8123)
  - Gaming Service (gaming-service:3001)
  - Order Service (order-service:3002)

### Database Services

#### PostgreSQL Service
- **Service Name**: `postgres-service`
- **Port**: 5432
- **Type**: ClusterIP
- **Used by**: Gaming Service, Order Service, Analytics Service

#### ClickHouse Service
- **Service Name**: `clickhouse-service`
- **Ports**: 
  - HTTP: 8123
  - Native: 9000
- **Type**: ClusterIP
- **Used by**: Analytics Service

## Configuration Management

### ConfigMap (app-config)
Contains non-sensitive configuration:
- `NODE_ENV`: production
- `DB_HOST`: postgres-service
- `DB_PORT`: 5432
- `DB_NAME`: lugx_gaming
- `CLICKHOUSE_URL`: http://clickhouse-service:8123
- `CLICKHOUSE_USER`: default
- `CLICKHOUSE_DATABASE`: analytics
- Service URLs for inter-service communication

### Secrets (app-secrets)
Contains sensitive information:
- `DB_USER`: PostgreSQL username (base64 encoded)
- `DB_PASSWORD`: PostgreSQL password (base64 encoded)
- `CLICKHOUSE_PASSWORD`: ClickHouse password (base64 encoded)
- `JWT_SECRET`: JWT signing secret (base64 encoded)

## Network Policies

### Internal Communication Policy
- Allows all pods within the namespace to communicate with each other
- Permits DNS resolution (port 53 TCP/UDP)

### Database Access Policy
- Restricts database access to authorized services only
- PostgreSQL (5432): Gaming, Order, Analytics services
- ClickHouse (8123, 9000): Analytics service only

### Frontend to Backend Policy
- Allows frontend to communicate with all backend services
- Permits DNS resolution for service discovery

## Service Discovery

Services use Kubernetes built-in DNS for service discovery:
- Format: `<service-name>.<namespace>.svc.cluster.local`
- Simplified: `<service-name>` (within same namespace)

Examples:
- `postgres-service` resolves to PostgreSQL pod
- `gaming-service:3001` connects to Gaming Service
- `http://clickhouse-service:8123` connects to ClickHouse HTTP API

## Health Checks

### Application Health Endpoints
- Gaming Service: `/health` on port 3001
- Order Service: `/health` on port 3002
- Analytics Service: `/health` on port 3003

### Database Health Checks
- PostgreSQL: `pg_isready` command
- ClickHouse: HTTP GET `/ping` on port 8123

## Security Considerations

1. **Network Segmentation**: Network policies restrict unnecessary communication
2. **Secret Management**: Sensitive data stored in Kubernetes secrets
3. **Service Account**: Each service runs with appropriate permissions
4. **Internal Traffic**: All service-to-service communication stays within cluster

## Deployment Notes

1. Services are deployed as ClusterIP (internal only)
2. External access managed through Ingress controller
3. Persistent storage for databases using PVCs
4. Resource limits and requests defined for each service
5. Liveness and readiness probes configured for reliability

## Environment Variables Injection

Each service receives configuration through:
- **ConfigMap references**: Non-sensitive config (DB hosts, ports, service URLs)
- **Secret references**: Sensitive data (passwords, JWT secrets)
- **Direct values**: Static configuration (port numbers)

This ensures secure and manageable service-to-service communication within the Kubernetes cluster.
