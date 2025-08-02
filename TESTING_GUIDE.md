# 🎮 Test Your Lugx Gaming Platform - Step by Step

## **Quick Test Guide for Non-Developers**

### **✅ What You Have Now:**
- **Frontend**: http://localhost:3000 (React web app)
- **Game Service**: http://localhost:3001 (Browse & add games)
- **Order Service**: http://localhost:3002 (Process purchases)
- **Analytics Service**: http://localhost:3003 (Track activity)
- **PostgreSQL Database**: All data is stored here
- **ClickHouse Database**: Analytics data

---

## **🧪 Simple Test Scenarios**

### **Test 1: Browse Games (Game Service → PostgreSQL)**

**What to do:**
1. Open http://localhost:3000/gaming
2. You should see 5 sample games:
   - Cyberpunk 2077 ($59.99)
   - The Witcher 3 ($39.99)
   - Call of Duty: Modern Warfare ($49.99)
   - Minecraft ($26.95)
   - Among Us ($4.99)

**What happens behind the scenes:**
```
Your Browser → Frontend → Gaming Service API → PostgreSQL Database
```

**Test the API directly:**
- Open http://localhost:3001/api/products in a new tab
- You'll see the raw JSON data from PostgreSQL

---

### **Test 2: Create Account (Authentication)**

**What to do:**
1. Click "Login" button on http://localhost:3000
2. Click "Register" tab
3. Fill in:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `password123`
4. Click "Register"

**What happens:**
```
Registration Form → Gaming Service → PostgreSQL users table
```

---

### **Test 3: Add Games to Cart & Purchase (Order Service)**

**What to do:**
1. After logging in, go to "Games" page
2. Click "Add to Cart" on 2-3 games
3. Click "Cart" button (shows total)
4. Fill in shipping address
5. Click "Place Order"

**What happens:**
```
Cart Data → Order Service → PostgreSQL orders & order_items tables
```

**Check your order:**
- Go to "Orders" page to see your purchase history

---

### **Test 4: View Analytics Dashboard**

**What to do:**
1. Click "Analytics" in navigation
2. See dashboard with:
   - Total users, games, orders
   - Charts and popular games
   - Recent activity

**What happens:**
```
Dashboard → Analytics Service → PostgreSQL + ClickHouse databases
```

---

## **🔍 Test the Database Storage**

### **Check PostgreSQL Data:**

```bash
# Connect to database
docker-compose exec postgres psql -U postgres -d lugx_gaming

# Check games table
SELECT id, name, price, category FROM games;

# Check users table  
SELECT id, username, email, created_at FROM users;

# Check orders table
SELECT id, order_number, user_id, total_amount, status FROM orders;

# Check order items with game names
SELECT oi.*, g.name as game_name 
FROM order_items oi 
JOIN games g ON oi.game_id = g.id;
```

---

## **📝 Test Scenario: "John's Complete Journey"**

### **Step 1: Registration**
- John visits http://localhost:3000
- Registers with username: `john_gamer`
- **Result**: New record in PostgreSQL `users` table

### **Step 2: Browse Games**
- Clicks "Games" → sees 5 games from PostgreSQL
- **API Call**: `GET /api/products` → returns games from database

### **Step 3: Shopping**
- Adds "Cyberpunk 2077" ($59.99) to cart
- Adds "Minecraft" ($26.95) to cart
- **Total**: $86.94

### **Step 4: Checkout**
- Fills shipping address
- Clicks "Place Order"
- **Result**: 
  - New record in `orders` table
  - 2 new records in `order_items` table
  - Order number like: `ORD-1722614400-ABC12`

### **Step 5: Order Tracking**
- Goes to "Orders" page
- Sees order history with status "pending"
- **API Call**: `GET /api/orders/user/1` → joins orders + order_items + games tables

### **Step 6: Analytics**
- System automatically tracks:
  - User registration event
  - Purchase event ($86.94)
  - Page view events
- **Result**: Events stored in ClickHouse for analytics

---

## **🧩 Test Each Microservice Individually**

### **Game Service APIs:**
- `GET` http://localhost:3001/api/products - List all games
- `GET` http://localhost:3001/api/products/[id] - Get specific game
- `POST` http://localhost:3001/api/products - Add new game (admin)

### **Order Service APIs:**
- `GET` http://localhost:3002/api/orders/user/[id] - User's orders
- `POST` http://localhost:3002/api/orders - Create new order
- `GET` http://localhost:3002/api/orders/[id] - Get specific order

### **Analytics Service APIs:**
- `GET` http://localhost:3003/analytics/dashboard - Dashboard data
- `POST` http://localhost:3003/analytics/track - Track event

---

## **✨ What Makes This Special**

### **Real Database Storage:**
- Every action saves to PostgreSQL
- No fake/mock data - it's all real
- Data persists between restarts

### **Microservices Architecture:**
- **Game Service**: Manages catalog, authentication
- **Order Service**: Handles purchases, order tracking  
- **Analytics Service**: Collects usage data, reports
- **Frontend**: User interface that connects all services

### **Complete Data Flow:**
```
User Actions → Frontend → Microservice APIs → PostgreSQL Database
                                         ↘ ClickHouse (Analytics)
```

---

## **🚀 Next Steps to Try:**

1. **Add More Games**: Use the "Add Product" form on the Gaming page
2. **Place Multiple Orders**: Test the complete purchase flow
3. **Check Database**: Use the PostgreSQL commands above
4. **View Analytics**: See how your actions show up in analytics
5. **Test APIs**: Visit the API URLs directly to see raw data

**Your Lugx Gaming platform is now fully functional with real database storage!** 🎉
