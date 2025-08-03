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
- User session tracking with unique session IDs
- Device, browser, and OS detection
- Geographic information (country, city)
- Page duration tracking
- Screen resolution detection

### **Event Tracking**
- Custom event tracking with flexible properties
- Gaming-specific events (game_started, level_completed, etc.)
- User interaction events (clicks, form submissions)

### **Analytics Dashboard**
- Real-time metrics and KPIs
- Top pages and popular content
- Device and browser breakdowns
- Time-based analytics with date ranges

##  API Endpoints

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
  "country": "US"
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
  }
}
```

### **Analytics Retrieval**
```http
GET /analytics/page-visits?start_date=2025-01-01&end_date=2025-01-31&limit=100
GET /analytics/dashboard?date_range=7d
GET /health
```

## 🌐 Frontend Integration

### **1. Include Analytics Script**
```html
<script src="/analytics/lugx-analytics.js"></script>
```

### **2. Initialize Analytics**
```javascript
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

// Custom events
analytics.trackEvent('user_action', 'button_click', {
    button_name: 'play_game',
    location: 'homepage'
});
```

##  ClickHouse Integration

### **Table Structure**
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
    device_type Nullable(String),
    browser Nullable(String),
    screen_resolution Nullable(String),
    duration_seconds Int32 DEFAULT 0
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
```

## 🐳 Deployment

### **Kubernetes (Recommended)**
```bash
# Deploy to development
kubectl apply -k kustomize/overlays/development

# Check status
kubectl get pods -n gaming-microservices

# Port forward for testing
kubectl port-forward svc/analytics-service 3003:3003 -n gaming-microservices
```

### **Docker Compose**
```bash
# Start with dependencies
docker-compose up analytics-service postgres clickhouse
```

## 🔧 Environment Configuration

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

## 🔧 Health Checks & Monitoring

### **Health Endpoints**
- `GET /health` - Overall service health
- `GET /ready` - Kubernetes readiness check
- `GET /metrics` - Prometheus metrics

### **Performance Metrics**
- Request duration and count
- Database connection status
- ClickHouse availability
- Memory and CPU usage

## 🛡️ Security & Privacy

### **Data Protection**
- IP address hashing for privacy
- Configurable data retention policies
- GDPR compliance features
- User data anonymization options

### **API Security**
- Rate limiting (1000 requests/minute)
- CORS configuration
- Input validation and sanitization
- Helmet.js security headers

## 🧪 Testing

```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# Load testing
ab -n 1000 -c 10 -p page-visit.json -T application/json http://localhost:3003/analytics/track/page-visit
```

## 🔍 Troubleshooting

### **Common Issues**

1. **ClickHouse Connection Failed**
   ```bash
   kubectl get pods -l app=clickhouse -n gaming-microservices
   kubectl logs deployment/clickhouse -n gaming-microservices
   ```

2. **Database Schema Issues**
   ```bash
   kubectl exec -it deployment/analytics-service -n gaming-microservices -- npm run db:setup
   ```

3. **High Memory Usage**
   ```bash
   kubectl top pods -n gaming-microservices
   ```

---

**💡 Pro Tip**: Use the included `demo.html` file to test analytics integration in your browser. It provides a complete example of how to implement tracking in your frontend application.
