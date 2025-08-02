const express = require('express');
const { Product, Review, User } = require('../models');
const { Op } = require('sequelize');
const router = express.Router();

// Health check
router.get('/health', (req, res) => {
    res.status(200).json({ 
        status: 'healthy', 
        service: 'gaming-service-products',
        timestamp: new Date().toISOString()
    });
});

// GET /api/products - Get all products with optional filtering
router.get('/', async (req, res) => {
    try {
        const { category, platform, search, limit = 50, offset = 0 } = req.query;
        
        const whereClause = { isActive: true };
        
        if (category) {
            whereClause.category = category;
        }
        
        if (platform) {
            whereClause.platform = platform;
        }
        
        if (search) {
            whereClause[Op.or] = [
                { name: { [Op.iLike]: `%${search}%` } },
                { description: { [Op.iLike]: `%${search}%` } }
            ];
        }

        const products = await Product.findAll({
            where: whereClause,
            include: [{
                model: Review,
                attributes: ['rating', 'comment'],
                limit: 3,
                required: false
            }],
            limit: parseInt(limit),
            offset: parseInt(offset),
            order: [['createdAt', 'DESC']]
        });

        console.log(`Fetched ${products.length} products from database`);
        
        res.status(200).json({
            success: true,
            data: products,
            count: products.length
        });
        
    } catch (error) {
        console.error('Error fetching products:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: 'Failed to fetch products'
        });
    }
});

// GET /api/products/:id - Get product by ID
router.get('/:id', async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.id, {
            include: [{
                model: Review,
                include: [{
                    model: User,
                    attributes: ['username']
                }],
                required: false
            }]
        });
        
        if (!product) {
            return res.status(404).json({ 
                success: false,
                error: 'Product not found' 
            });
        }
        
        res.json({
            success: true,
            data: product
        });
    } catch (error) {
        console.error('Get product error:', error);
        res.status(500).json({ 
            success: false,
            error: 'Failed to fetch product' 
        });
    }
});

// POST /api/products - Create new product (admin only)
router.post('/', async (req, res) => {
    try {
        const productData = req.body;
        
        const product = await Product.create(productData);
        
        res.status(201).json({
            success: true,
            data: product,
            message: 'Product created successfully'
        });
    } catch (error) {
        console.error('Create product error:', error);
        res.status(500).json({ 
            success: false,
            error: 'Failed to create product' 
        });
    }
});

module.exports = router;
