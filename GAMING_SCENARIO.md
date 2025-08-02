# 🎮 Lugx Gaming Platform - Complete User Scenario

## **Simple Story: John's Gaming Journey**

### **Characters:**
- **John** - A gamer who wants to buy games
- **Alice** - Another gamer for comparison

### **The Journey:**

---

## **Step 1: Browse Games (Game Service)**
**What happens:** John visits the website and wants to see available games

**User Action:** 
- Opens http://localhost:3000
- Clicks "Games" in navigation
- Sees a list of games with prices

**Technical Flow:**
```
User Browser → Frontend (React) → Game Service API → PostgreSQL Database
```

**Data Flow:**
1. Frontend requests: `GET /api/games`
2. Game Service queries PostgreSQL: `SELECT * FROM games`
3. Returns: List of games with prices, descriptions, ratings

**Sample Data Returned:**
```json
[
  {
    "id": 1,
    "name": "Cyberpunk 2077",
    "description": "Open-world action-adventure game",
    "price": 59.99,
    "category": "RPG",
    "rating": 4.2,
    "developer": "CD Projekt RED"
  },
  {
    "id": 2,
    "name": "The Witcher 3",
    "price": 39.99,
    "category": "RPG",
    "rating": 4.8
  }
]
```

---

## **Step 2: User Registration/Login (Game Service)**
**What happens:** John creates an account to purchase games

**User Action:**
- Clicks "Login" button
- Fills registration form: username, email, password
- Submits form

**Technical Flow:**
```
User Browser → Frontend Form → Game Service API → PostgreSQL (users table)
```

**Data Flow:**
1. Frontend sends: `POST /api/auth/register`
2. Game Service hashes password and saves to PostgreSQL
3. Returns JWT token for authentication

**Database Action:**
```sql
INSERT INTO users (username, email, password_hash, full_name) 
VALUES ('john_gamer', 'john@example.com', 'hashed_password', 'John Smith');
```

---

## **Step 3: Add Games to Cart (Frontend State)**
**What happens:** John selects games he wants to buy

**User Action:**
- Clicks "Add to Cart" on "Cyberpunk 2077" ($59.99)
- Clicks "Add to Cart" on "Minecraft" ($26.95)
- Cart shows: Total $86.94

**Technical Flow:**
```
User Browser → Frontend (React Context) → Local State Management
```

**Cart Data Structure:**
```json
{
  "items": [
    {
      "gameId": 1,
      "name": "Cyberpunk 2077",
      "price": 59.99,
      "quantity": 1
    },
    {
      "gameId": 4,
      "name": "Minecraft",
      "price": 26.95,
      "quantity": 1
    }
  ],
  "total": 86.94
}
```

---

## **Step 4: Place Order (Order Service)**
**What happens:** John decides to purchase the games in his cart

**User Action:**
- Clicks "Checkout" button
- Fills shipping address form
- Clicks "Place Order"

**Technical Flow:**
```
User Browser → Frontend → Order Service API → PostgreSQL (orders + order_items tables)
```

**Data Flow:**
1. Frontend sends: `POST /api/orders` with cart data and shipping info
2. Order Service creates order record in PostgreSQL
3. Order Service creates order_items for each game
4. Returns order confirmation with order number

**Database Actions:**
```sql
-- Create main order
INSERT INTO orders (user_id, order_number, total_amount, status, shipping_address) 
VALUES (1, 'ORD-2025-001', 86.94, 'pending', '{"street": "123 Main St", "city": "New York"}');

-- Create order items
INSERT INTO order_items (order_id, game_id, quantity, unit_price, total_price) VALUES 
(1, 1, 1, 59.99, 59.99),  -- Cyberpunk 2077
(1, 4, 1, 26.95, 26.95);  -- Minecraft
```

---

## **Step 5: Track Order (Order Service)**
**What happens:** John wants to see his order status

**User Action:**
- Clicks "Orders" in navigation
- Sees order history with status

**Technical Flow:**
```
User Browser → Frontend → Order Service API → PostgreSQL (orders JOIN order_items JOIN games)
```

**Data Flow:**
1. Frontend requests: `GET /api/orders/user/1`
2. Order Service joins tables to get complete order info
3. Returns order history with game details

**Database Query:**
```sql
SELECT o.*, oi.*, g.name as game_name 
FROM orders o 
JOIN order_items oi ON o.id = oi.order_id 
JOIN games g ON oi.game_id = g.id 
WHERE o.user_id = 1;
```

---

## **Step 6: Analytics Tracking (Analytics Service)**
**What happens:** System tracks John's activity for business insights

**Automatic Actions:**
- When John registers → Track "user_registration" event
- When John views games → Track "page_view" event  
- When John purchases → Track "purchase" event
- When John downloads → Track "download" event

**Technical Flow:**
```
Frontend/Services → Analytics Service API → ClickHouse Database
```

**Data Flow:**
1. Various actions trigger: `POST /api/analytics/track`
2. Analytics Service stores events in ClickHouse
3. Analytics Service aggregates data for dashboard

**Sample Analytics Events:**
```json
[
  {
    "event_type": "user_registration",
    "user_id": 1,
    "timestamp": "2025-08-02T10:30:00Z",
    "metadata": {"source": "web"}
  },
  {
    "event_type": "purchase",
    "user_id": 1,
    "game_id": 1,
    "timestamp": "2025-08-02T11:45:00Z",
    "metadata": {"amount": 59.99, "payment_method": "credit_card"}
  }
]
```

---

## **Step 7: View Analytics Dashboard (Analytics Service)**
**What happens:** Business owner (or John) views platform statistics

**User Action:**
- Clicks "Analytics" in navigation
- Sees dashboard with charts and metrics

**Technical Flow:**
```
User Browser → Frontend → Analytics Service API → ClickHouse + PostgreSQL
```

**Dashboard Metrics:**
- **Total Users:** Count from PostgreSQL users table
- **Total Games:** Count from PostgreSQL games table  
- **Total Orders:** Count from PostgreSQL orders table
- **Revenue:** Sum from PostgreSQL orders table
- **Popular Games:** Analysis from order_items + games tables
- **User Activity:** Time-series data from ClickHouse

---

## **Complete Data Flow Summary**

### **Game Service (Yellow Box):**
- Manages game catalog (PostgreSQL games table)
- Handles user authentication (PostgreSQL users table)
- Provides game browsing and search APIs

### **Order Service (Yellow Box):**
- Processes purchases (PostgreSQL orders + order_items tables)
- Manages order status and tracking
- Handles payment processing integration

### **Analytics Service (Purple Box):**
- Collects user behavior events (ClickHouse)
- Aggregates business metrics
- Provides dashboard and reporting APIs

### **Frontend (Blue Box):**
- React web application
- User interface for all interactions
- Communicates with all three services

### **Databases:**
- **PostgreSQL (Pink Box):** Main business data (users, games, orders)
- **ClickHouse (Pink Box):** Analytics and event tracking data

---

## **Simple Form Example for Testing**

You can test this scenario by:

1. **Browse Games:** Visit http://localhost:3000/gaming
2. **Register User:** Fill the registration form
3. **Add to Cart:** Click "Add to Cart" on games
4. **Place Order:** Go through checkout process
5. **View Orders:** Check your order history
6. **See Analytics:** View the analytics dashboard

Each step demonstrates how the three microservices work together according to your solution architecture!
