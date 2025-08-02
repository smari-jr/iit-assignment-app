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

        // Validation
        if (!userId || !items || !Array.isArray(items) || items.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'User ID and items array are required'
            });
        }

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
        
        console.log(`🎉 Order ${order.order_number} created successfully with ${orderItems.length} items`);

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

// GET /orders/user/:userId - Get orders for specific user (John's order history)
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
            GROUP BY o.id, o.order_number, o.total_amount, o.currency,
                     o.status, o.payment_status, o.payment_method,
                     o.shipping_address, o.created_at, o.updated_at
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
            items: row.items.filter(item => item.gameId !== null), // Remove null items
            createdAt: row.created_at,
            updatedAt: row.updated_at
        }));

        console.log(`✅ Found ${orders.length} orders for user ${userId}`);

        res.json({
            success: true,
            data: orders,
            count: orders.length,
            message: `Found ${orders.length} orders for user`
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
        console.log(`🔍 Fetching order details for ID: ${id}`);

        const result = await pool.query(`
            SELECT 
                o.id, o.user_id, o.order_number, o.total_amount, o.currency,
                o.status, o.payment_status, o.payment_method,
                o.shipping_address, o.billing_address, o.created_at, o.updated_at,
                json_agg(
                    json_build_object(
                        'id', oi.id,
                        'gameId', oi.game_id,
                        'gameName', g.name,
                        'gamePrice', g.price,
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

        const row = result.rows[0];
        const order = {
            id: row.id,
            userId: row.user_id,
            orderNumber: row.order_number,
            totalAmount: parseFloat(row.total_amount),
            currency: row.currency,
            status: row.status,
            paymentStatus: row.payment_status,
            paymentMethod: row.payment_method,
            shippingAddress: row.shipping_address,
            billingAddress: row.billing_address,
            items: row.items.filter(item => item.gameId !== null),
            createdAt: row.created_at,
            updatedAt: row.updated_at
        };

        console.log(`✅ Found order: ${order.orderNumber}`);

        res.json({
            success: true,
            data: order
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

// PUT /orders/:id/status - Update order status
router.put('/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        // Valid statuses: pending, processing, shipped, delivered, cancelled
        const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                message: `Invalid status. Valid statuses: ${validStatuses.join(', ')}`
            });
        }

        console.log(`📝 Updating order ${id} status to: ${status}`);

        const result = await pool.query(`
            UPDATE orders 
            SET status = $1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $2
            RETURNING id, order_number, status, updated_at
        `, [status, id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: `Order with ID ${id} not found`
            });
        }

        const order = result.rows[0];
        console.log(`✅ Order ${order.order_number} status updated to: ${order.status}`);

        res.json({
            success: true,
            message: `Order status updated to ${status}`,
            data: {
                id: order.id,
                orderNumber: order.order_number,
                status: order.status,
                updatedAt: order.updated_at
            }
        });

    } catch (error) {
        console.error('❌ Error updating order status:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update order status',
            error: error.message
        });
    }
});

// GET /orders - Get all orders (admin view)
router.get('/', async (req, res) => {
    try {
        const { page = 1, limit = 10, status } = req.query;
        const offset = (page - 1) * limit;

        let whereClause = '';
        let queryParams = [limit, offset];
        
        if (status) {
            whereClause = 'WHERE o.status = $3';
            queryParams.push(status);
        }

        console.log(`📊 Fetching orders (page ${page}, limit ${limit})`);

        const result = await pool.query(`
            SELECT 
                o.id, o.user_id, o.order_number, o.total_amount, o.currency,
                o.status, o.payment_status, o.created_at,
                u.username, u.email,
                COUNT(oi.id) as item_count
            FROM orders o
            LEFT JOIN users u ON o.user_id = u.id
            LEFT JOIN order_items oi ON o.id = oi.order_id
            ${whereClause}
            GROUP BY o.id, u.username, u.email
            ORDER BY o.created_at DESC
            LIMIT $1 OFFSET $2
        `, queryParams);

        const orders = result.rows.map(row => ({
            id: row.id,
            userId: row.user_id,
            orderNumber: row.order_number,
            totalAmount: parseFloat(row.total_amount),
            currency: row.currency,
            status: row.status,
            paymentStatus: row.payment_status,
            customerInfo: {
                username: row.username,
                email: row.email
            },
            itemCount: parseInt(row.item_count),
            createdAt: row.created_at
        }));

        // Get total count for pagination
        const countResult = await pool.query(`
            SELECT COUNT(*) as total FROM orders o ${whereClause}
        `, status ? [status] : []);
        
        const totalOrders = parseInt(countResult.rows[0].total);

        console.log(`✅ Found ${orders.length} orders (${totalOrders} total)`);

        res.json({
            success: true,
            data: orders,
            pagination: {
                current_page: parseInt(page),
                per_page: parseInt(limit),
                total: totalOrders,
                total_pages: Math.ceil(totalOrders / limit)
            }
        });

    } catch (error) {
        console.error('❌ Error fetching orders:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch orders',
            error: error.message
        });
    }
});

module.exports = router;

        if (!userId || !productId || !quantity || !totalAmount) {
            return res.status(400).json({ 
                error: 'Missing required fields: userId, productId, quantity, totalAmount' 
            });
        }

        const order = await Order.create({
            userId,
            productId,
            quantity,
            totalAmount,
            status
        });

        res.status(201).json({
            success: true,
            data: order
        });
    } catch (error) {
        console.error('Create order error:', error);
        res.status(500).json({ error: 'Failed to create order' });
    }
});

// Update order status
router.put('/:id', async (req, res) => {
    try {
        const order = await Order.findByPk(req.params.id);
        if (!order) {
            return res.status(404).json({ error: 'Order not found' });
        }

        // Only allow updating certain fields
        const allowedFields = ['status', 'quantity', 'totalAmount'];
        const updateData = {};
        
        allowedFields.forEach(field => {
            if (req.body[field] !== undefined) {
                updateData[field] = req.body[field];
            }
        });

        await order.update(updateData);
        
        res.json({
            success: true,
            data: order
        });
    } catch (error) {
        console.error('Update order error:', error);
        res.status(500).json({ error: 'Failed to update order' });
    }
});

// Cancel order
router.delete('/:id', async (req, res) => {
    try {
        const order = await Order.findByPk(req.params.id);
        if (!order) {
            return res.status(404).json({ error: 'Order not found' });
        }

        // Update status to cancelled instead of deleting
        await order.update({ status: 'cancelled' });
        
        res.json({
            success: true,
            message: 'Order cancelled successfully',
            data: order
        });
    } catch (error) {
        console.error('Cancel order error:', error);
        res.status(500).json({ error: 'Failed to cancel order' });
    }
});

// Get orders by user ID
router.get('/user/:userId', async (req, res) => {
    try {
        const orders = await Order.findAll({
            where: { userId: req.params.userId },
            order: [['createdAt', 'DESC']]
        });
        
        res.json({
            success: true,
            data: orders
        });
    } catch (error) {
        console.error('Get user orders error:', error);
        res.status(500).json({ error: 'Failed to fetch user orders' });
    }
});

module.exports = router;
