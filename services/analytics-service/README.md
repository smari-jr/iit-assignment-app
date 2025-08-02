# 📊 Lugx Gaming Analytics Service

A high-performance analytics service that integrates with both **PostgreSQL** and **ClickHouse** to capture and analyze page visits, user interactions, and gaming events for the Lugx Gaming platform.

## 🏗️ Architecture Overview

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│     Frontend        │    │  Analytics Service   │    │    PostgreSQL       │
│  (React/JavaScript) │────│   (Node.js/Express)  │────│ (Transactional Data)│
│                     │    │      Port 3003       │    │     Port 5432       │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
                                        │
                                        │
                           ┌──────────────────────┐
                           │     ClickHouse       │
                           │ (Analytics Storage)  │
                           │     Port 8123        │
                           └──────────────────────┘
```

## 🚀 Features

### **Dual Database Integration**
- **PostgreSQL**: Stores transactional analytics data for ACID compliance
- **ClickHouse**: High-performance analytics storage for large-scale data analysis
- **Automatic Fallback**: If ClickHouse is unavailable, falls back to PostgreSQL

### **Page Visit Tracking**
- Captures detailed page visit information
- User session tracking with unique session IDs
- Device, browser, and OS detection
- Geographic information (country, city)
- Page duration tracking
- Screen resolution detection

### **Event Tracking**
- Custom event tracking with flexible properties
- Gaming-specific events (game_started, level_completed, etc.)
- E-commerce events (purchases, cart actions)
- User interaction events (clicks, form submissions)

### **Analytics Dashboard**
- Real-time metrics and KPIs
- Top pages and popular content
- Device and browser breakdowns
- Time-based analytics with date ranges

## 📦 Installation & Setup

### 1. **Dependencies**

```bash
cd services/analytics-service
npm install
```

### 2. **Environment Variables**

```bash
# Server Configuration
PORT=3003
NODE_ENV=development

# PostgreSQL Database
DB_HOST=postgres
DB_PORT=5432
DB_NAME=lugx_gaming
DB_USER=postgres
DB_PASSWORD=your_password

# ClickHouse Configuration
CLICKHOUSE_URL=http://clickhouse:8123
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=
CLICKHOUSE_DATABASE=analytics

# Security
JWT_SECRET=your_jwt_secret
```

### 3. **Database Setup**

The service automatically creates the required database schemas and tables:

**PostgreSQL Tables:**
- `analytics.page_visits` - Page visit tracking
- `analytics.events` - Custom event tracking

**ClickHouse Tables:**
- `analytics.page_visits` - High-volume page visit analytics
- `analytics.events` - High-volume event analytics

## 🔌 API Endpoints

### **Page Visit Tracking**
```http
POST /analytics/track/page-visit
Content-Type: application/json

{
  "session_id": "uuid-here",
  "user_id": "user123",
  "url": "https://lugx-gaming.com/games",
  "path": "/games",
  "referrer": "https://google.com",
  "screen_resolution": "1920x1080",
  "duration_seconds": 45,
  "country": "US",
  "city": "New York"
}
```

### **Event Tracking**
```http
POST /analytics/track/event
Content-Type: application/json

{
  "session_id": "uuid-here",
  "user_id": "user123",
  "event_type": "gaming",
  "event_name": "game_started",
  "properties": {
    "game_id": "call_of_duty",
    "level": 1,
    "difficulty": "normal"
  },
  "url": "https://lugx-gaming.com/games/cod"
}
```

### **Analytics Retrieval**
```http
GET /analytics/page-visits?start_date=2025-01-01&end_date=2025-01-31&limit=100
GET /analytics/dashboard?date_range=7d
```

## 🌐 Frontend Integration

### **1. Include Analytics Script**

```html
<script src="/analytics/lugx-analytics.js"></script>
```

### **2. Initialize Analytics**

```javascript
// Initialize with your analytics service URL
const analytics = new LugxAnalytics({
    analyticsUrl: 'http://localhost:3003/analytics',
    userId: null, // Set when user logs in
    autoTrack: true // Automatically track page views
});

// Set user ID when user logs in
analytics.setUserId('user123');
```

### **3. Track Events**

```javascript
// Gaming events
analytics.trackGameEvent('game_started', {
    game_id: 'call_of_duty',
    level: 1
});

// Purchase events
analytics.trackPurchaseEvent('purchase_completed', {
    item_id: 'game123',
    price: 59.99,
    currency: 'USD'
});

// Custom events
analytics.trackEvent('user_action', 'button_click', {
    button_name: 'play_game',
    location: 'homepage'
});
```

## 🐳 Docker & Kubernetes Deployment

### **Using Kustomize** (Recommended)

```bash
# Deploy to development
kubectl apply -k kustomize/overlays/development

# Check status
kubectl get pods -n lugx-gaming-dev

# Port forward for testing
kubectl port-forward svc/analytics-service 3003:3003 -n lugx-gaming-dev
```

### **Manual Docker**

```bash
# Build image
docker build -t lugx/analytics-service:latest .

# Run with dependencies
docker-compose up analytics-service
```

## 📊 ClickHouse Integration

### **Table Structure**

**Page Visits Table:**
```sql
CREATE TABLE analytics.page_visits (
    id UUID DEFAULT generateUUIDv4(),
    session_id String,
    user_id Nullable(String),
    timestamp DateTime64(3) DEFAULT now64(),
    url String,
    path String,
    referrer Nullable(String),
    user_agent Nullable(String),
    ip_address Nullable(IPv4),
    country Nullable(String),
    city Nullable(String),
    device_type Nullable(String),
    browser Nullable(String),
    os Nullable(String),
    screen_resolution Nullable(String),
    duration_seconds Int32 DEFAULT 0,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (timestamp, session_id)
PARTITION BY toYYYYMM(timestamp)
TTL timestamp + INTERVAL 1 YEAR;
```

### **Performance Features**
- **Partitioning**: Data partitioned by month for efficient queries
- **TTL**: Automatic data cleanup after 1 year
- **Compression**: Built-in compression for storage efficiency
- **Ordered Storage**: Optimized for time-series queries

### **Sample Queries**

```sql
-- Top pages by visit count
SELECT path, COUNT(*) as visits
FROM analytics.page_visits 
WHERE timestamp >= today() - 7
GROUP BY path 
ORDER BY visits DESC 
LIMIT 10;

-- User sessions over time
SELECT 
    toDate(timestamp) as date,
    COUNT(DISTINCT session_id) as unique_sessions
FROM analytics.page_visits 
WHERE timestamp >= today() - 30
GROUP BY date 
ORDER BY date;

-- Device breakdown
SELECT 
    device_type,
    COUNT(*) as count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as percentage
FROM analytics.page_visits 
WHERE timestamp >= today() - 7
GROUP BY device_type;
```

## 🔧 Health Checks & Monitoring

### **Health Endpoints**
- `GET /health` - Overall service health
- `GET /ready` - Kubernetes readiness check
- `GET /metrics` - Prometheus metrics

### **Logging**
The service provides structured logging for:
- Page visit tracking
- Event processing
- Database operations
- Error handling

### **Metrics**
Prometheus metrics include:
- Request duration
- Request count by endpoint
- Database connection status
- ClickHouse availability

## 🧪 Testing

### **Unit Tests**
```bash
npm test
```

### **Integration Testing**
```bash
# Start test environment
docker-compose -f docker-compose.test.yml up -d

# Run integration tests
npm run test:integration
```

### **Load Testing**
```bash
# Test page visit tracking
ab -n 1000 -c 10 -p page-visit.json -T application/json http://localhost:3003/analytics/track/page-visit
```

## 🛡️ Security & Privacy

### **Data Protection**
- IP address hashing for privacy
- Configurable data retention policies
- GDPR compliance features
- User data anonymization options

### **API Security**
- Rate limiting (1000 requests/minute)
- CORS configuration
- Helmet.js security headers
- Input validation and sanitization

## 📈 Performance Considerations

### **Scalability**
- Horizontal scaling with Kubernetes
- Database connection pooling
- Async processing for high-volume events
- ClickHouse for analytical workloads

### **Optimization**
- Database indexes for common queries
- Connection pooling for PostgreSQL
- Batch processing for ClickHouse inserts
- Caching for frequently accessed data

## 🔍 Troubleshooting

### **Common Issues**

1. **ClickHouse Connection Failed**
   ```bash
   # Check ClickHouse service
   kubectl get pods -l app=clickhouse -n lugx-gaming-dev
   
   # Check logs
   kubectl logs deployment/clickhouse -n lugx-gaming-dev
   ```

2. **Database Schema Issues**
   ```bash
   # Recreate tables
   kubectl exec -it deployment/analytics-service -n lugx-gaming-dev -- npm run db:setup
   ```

3. **High Memory Usage**
   ```bash
   # Check resource usage
   kubectl top pods -n lugx-gaming-dev
   
   # Adjust resource limits in Kustomize
   ```

## 📚 Documentation

- [API Documentation](./docs/api.md)
- [Database Schema](./docs/schema.md)
- [Deployment Guide](./docs/deployment.md)
- [Monitoring Setup](./docs/monitoring.md)

---

**💡 Pro Tip**: Use the included `demo.html` file to test analytics integration in your browser. It provides a complete example of how to implement tracking in your frontend application.

For production deployments, consider using a managed ClickHouse service (like ClickHouse Cloud) for better performance and maintenance.
