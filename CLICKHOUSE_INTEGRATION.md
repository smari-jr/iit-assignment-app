# ClickHouse Analytics Integration

## Overview
This document describes the ClickHouse analytics integration for the Lugx Gaming Platform, providing high-performance analytics capabilities alongside the existing PostgreSQL infrastructure.

## Architecture

### Dual Database Setup
- **PostgreSQL**: Transactional data and traditional analytics
- **ClickHouse**: High-volume analytics data for real-time processing

### Components
1. **Analytics Service** (`analytics-service`)
   - Node.js service with dual database support
   - Routes: `/api/analytics/*`
   - Ports: 3003

2. **ClickHouse Database** (`clickhouse-service`)
   - Column-oriented database optimized for analytics
   - Database: `analytics_dev`
   - Port: 8123

3. **Interactive Demo** (`/api/demo`)
   - Browser-based demo interface
   - Real-time testing capabilities

## Database Schema

### ClickHouse Tables

#### page_visits
```sql
CREATE TABLE page_visits (
    id UUID DEFAULT generateUUIDv4(),
    session_id String,
    user_id Nullable(String),
    timestamp DateTime DEFAULT now(),
    url String,
    path String,
    referrer Nullable(String),
    device_type Nullable(String),
    browser Nullable(String),
    os Nullable(String),
    screen_resolution Nullable(String),
    duration_seconds UInt32 DEFAULT 0,
    country Nullable(String),
    city Nullable(String),
    ip_address String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, session_id)
TTL timestamp + INTERVAL 2 YEAR;
```

#### events
```sql
CREATE TABLE events (
    id UUID DEFAULT generateUUIDv4(),
    session_id String,
    user_id Nullable(String),
    timestamp DateTime DEFAULT now(),
    event_type String,
    event_data String,
    page_url String,
    device_type Nullable(String),
    browser Nullable(String),
    country Nullable(String),
    city Nullable(String)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, event_type, session_id)
TTL timestamp + INTERVAL 2 YEAR;
```

## API Endpoints

### Analytics Endpoints
- `GET /api/analytics/test-clickhouse` - Test ClickHouse connectivity
- `GET /api/analytics/clickhouse-dashboard` - Real-time analytics dashboard
- `GET /api/analytics/dashboard` - PostgreSQL analytics dashboard
- `POST /api/analytics/track/page-visit` - Track page visits
- `POST /api/analytics/track/event` - Track user events
- `POST /api/analytics/seed-sample-data` - Generate sample data

### Demo Interface
- `GET /api/demo` - Interactive demo page

## Deployment

### Production Images
- `analytics-service:clickhouse-production-20250818`
- `frontend:gaming-production-20250818`

### Environment Variables
```bash
# ClickHouse Configuration
CLICKHOUSE_HOST=clickhouse-service
CLICKHOUSE_PORT=8123
CLICKHOUSE_DATABASE=analytics_dev
CLICKHOUSE_USERNAME=default
CLICKHOUSE_PASSWORD=

# PostgreSQL Configuration
DB_HOST=<rds-endpoint>
DB_PORT=5432
DB_NAME=lugx_gaming
DB_USER=postgres
DB_PASSWORD=<password>
```

### Kubernetes Deployment
```bash
cd kustomize/overlays/dev
kubectl apply -k .
```

## Usage Examples

### Track Page Visit
```javascript
const pageVisit = {
  session_id: 'session_123',
  url: 'https://lugx-gaming.com/gaming',
  path: '/gaming',
  duration_seconds: 45,
  device_type: 'desktop',
  browser: 'Chrome'
};

fetch('/api/analytics/track/page-visit', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(pageVisit)
});
```

### Track User Event
```javascript
const userEvent = {
  session_id: 'session_123',
  event_type: 'purchase',
  event_data: JSON.stringify({
    product_id: '123',
    product_name: 'Call of Duty',
    price: 39.99
  }),
  page_url: 'https://lugx-gaming.com/gaming'
};

fetch('/api/analytics/track/event', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(userEvent)
});
```

## Performance Features

### ClickHouse Optimizations
- **Columnar Storage**: Optimized for analytical queries
- **Compression**: Efficient data storage
- **Partitioning**: Data partitioned by month
- **TTL**: Automatic data expiration after 2 years
- **MergeTree Engine**: Optimized for high-volume inserts

### Query Performance
- Real-time aggregations
- Complex analytical queries
- Geographic analysis
- Device and browser breakdowns

## Monitoring

### Health Checks
- `/health` - Service health status
- `/api/analytics/test-clickhouse` - ClickHouse connectivity

### Metrics Available
- Total page visits
- Unique sessions
- Device type breakdown
- Browser analysis
- Geographic distribution
- Real-time event tracking

## Security

### Data Protection
- TTL policies for data retention
- IP address anonymization
- User data encryption in transit

### Access Control
- Service-to-service communication
- Network policies in Kubernetes
- Secure database connections

## Troubleshooting

### Common Issues
1. **ClickHouse Connection Failed**
   - Check service discovery: `clickhouse-service:8123`
   - Verify pod status: `kubectl get pods -n lugx-gaming`

2. **Table Not Found**
   - Tables are auto-created on service startup
   - Check initialization logs in analytics service

3. **Query Performance**
   - Verify partition pruning
   - Check table indexes
   - Monitor resource usage

### Debug Commands
```bash
# Check ClickHouse logs
kubectl logs -n lugx-gaming clickhouse-xxx

# Test connectivity
kubectl exec -n lugx-gaming analytics-service-xxx -- curl http://clickhouse-service:8123/ping

# Check table status
kubectl exec -n lugx-gaming analytics-service-xxx -- curl "http://clickhouse-service:8123/?query=SHOW%20TABLES"
```

## Integration Points

### Gaming Platform
- Product view tracking
- Purchase event analytics
- User behavior analysis
- Cart abandonment tracking

### Frontend Integration
- Automatic page visit tracking
- User interaction events
- Performance metrics
- A/B testing support

## Future Enhancements

### Planned Features
- Real-time dashboards in frontend
- Advanced analytics queries
- Machine learning integration
- Predictive analytics
- Custom event types

### Scaling Considerations
- ClickHouse cluster setup
- Data replication
- Backup strategies
- Performance tuning

## Demo Access

**Interactive Demo URL:**
```
http://k8s-lugxgami-gamingmi-b3d3b374e8-1767752309.ap-southeast-1.elb.amazonaws.com/api/demo
```

The demo provides:
- System health checks
- Real-time analytics testing
- Data generation tools
- Gaming integration examples

---

*Last Updated: August 18, 2025*
*Version: 1.0.0*
