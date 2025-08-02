const express = require('express');
const { Pool } = require('pg');
const router = express.Router();

// PostgreSQL connection
const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'lugx_gaming',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres123',
});

// Health check
router.get('/health', async (req, res) => {
    try {
        const result = await pool.query('SELECT COUNT(*) as order_count FROM orders');
        const orderCount = result.rows[0].order_count;
        
        res.status(200).json({ 
            status: 'healthy', 
            service: 'order-service',
            timestamp: new Date().toISOString(),
            totalOrders: parseInt(orderCount)
        });
    } catch (error) {
        res.status(500).json({ 
            status: 'unhealthy', 
            service: 'order-service',
            error: error.message
        });
    }
});

// POST /orders - Create new order (John's purchase scenario)
router.post('/', async (req, res) => {
    const client = await pool.connect();
    
    try {
        await client.query('BEGIN');
        
        const {
            userId,
            items, // Array of cart items: [{gameId, quantity, unitPrice}]
            totalAmount,
            currency = 'USD',
            paymentMethod = 'credit_card',
            shippingAddress,
            billingAddress
        } = req.body;

        console.log(`🛒 Processing order for user ID: ${userId}, Total: $${totalAmount}`);

        // Generate unique order number
        const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 5).toUpperCase()}`;

        // Create main order record
        const orderResult = await client.query(`
            INSERT INTO orders (
                user_id, order_number, total_amount, currency, 
                status, payment_method, payment_status,
                shipping_address, billing_address
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING id, order_number, total_amount, status, created_at
        `, [
            userId, orderNumber, totalAmount, currency,
            'pending', paymentMethod, 'pending',
            JSON.stringify(shippingAddress), JSON.stringify(billingAddress || shippingAddress)
        ]);

        const order = orderResult.rows[0];
        console.log(`✅ Created order: ${order.order_number}`);

        // Create order items
        const orderItems = [];
        for (const item of items) {
            const itemResult = await client.query(`
                INSERT INTO order_items (order_id, game_id, quantity, unit_price, total_price)
                VALUES ($1, $2, $3, $4, $5)
                RETURNING id, game_id, quantity, unit_price, total_price
            `, [
                order.id,
                item.gameId || item.id,
                item.quantity,
                item.unitPrice || item.price,
                item.totalPrice || (item.quantity * (item.unitPrice || item.price))
            ]);
            
            orderItems.push(itemResult.rows[0]);
        }

        await client.query('COMMIT');

        res.status(201).json({
            success: true,
            message: `Order ${order.order_number} created successfully`,
            data: {
                id: order.id,
                orderNumber: order.order_number,
                totalAmount: parseFloat(order.total_amount),
                status: order.status,
                items: orderItems,
                createdAt: order.created_at
            }
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('❌ Error creating order:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create order',
            error: error.message
        });
    } finally {
        client.release();
    }
});

// GET /orders/user/:userId - Get orders for specific user
router.get('/user/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        console.log(`📋 Fetching orders for user ID: ${userId}`);

        const result = await pool.query(`
            SELECT 
                o.id, o.order_number, o.total_amount, o.currency,
                o.status, o.payment_status, o.payment_method,
                o.shipping_address, o.created_at, o.updated_at,
                json_agg(
                    json_build_object(
                        'id', oi.id,
                        'gameId', oi.game_id,
                        'gameName', g.name,
                        'quantity', oi.quantity,
                        'unitPrice', oi.unit_price,
                        'totalPrice', oi.total_price
                    )
                ) as items
            FROM orders o
            LEFT JOIN order_items oi ON o.id = oi.order_id
            LEFT JOIN games g ON oi.game_id = g.id
            WHERE o.user_id = $1
            GROUP BY o.id
            ORDER BY o.created_at DESC
        `, [userId]);

        const orders = result.rows.map(row => ({
            id: row.id,
            orderNumber: row.order_number,
            totalAmount: parseFloat(row.total_amount),
            currency: row.currency,
            status: row.status,
            paymentStatus: row.payment_status,
            paymentMethod: row.payment_method,
            shippingAddress: row.shipping_address,
            items: row.items.filter(item => item.gameId !== null),
            createdAt: row.created_at,
            updatedAt: row.updated_at
        }));

        res.json({
            success: true,
            data: orders,
            count: orders.length
        });

    } catch (error) {
        console.error('❌ Error fetching user orders:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch orders',
            error: error.message
        });
    }
});

// GET /orders/:id - Get single order details
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(`
            SELECT 
                o.*, 
                json_agg(
                    json_build_object(
                        'id', oi.id,
                        'gameId', oi.game_id,
                        'gameName', g.name,
                        'quantity', oi.quantity,
                        'unitPrice', oi.unit_price,
                        'totalPrice', oi.total_price
                    )
                ) as items
            FROM orders o
            LEFT JOIN order_items oi ON o.id = oi.order_id
            LEFT JOIN games g ON oi.game_id = g.id
            WHERE o.id = $1
            GROUP BY o.id
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: `Order with ID ${id} not found`
            });
        }

        const order = result.rows[0];
        res.json({
            success: true,
            data: {
                ...order,
                items: order.items.filter(item => item.gameId !== null)
            }
        });

    } catch (error) {
        console.error('❌ Error fetching order:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch order',
            error: error.message
        });
    }
});

module.exports = router;
