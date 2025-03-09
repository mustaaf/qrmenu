const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const app = express();
const port = 3000;

// Enable CORS if you're testing with Flutter web or on a different device
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// Database connection setup
const pool = new Pool({
    user: 'postgres',
    host: '127.0.0.1',
    database: 'retorandb',
    password: 'adil1234', // Replace with your actual password
    port: 5432,
});

// Endpoint to get restaurant info
app.get('/restaurant/:slug', async(req, res) => {
    try {
        const { slug } = req.params;
        const result = await pool.query(
            'SELECT * FROM restaurants WHERE slug = $1', [slug]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Restaurant not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Endpoint to get menu categories
app.get('/categories', async(req, res) => {
    try {
        const restaurantId = req.query.restaurantId;

        if (!restaurantId) {
            return res.status(400).json({ error: 'Restaurant ID is required' });
        }

        const result = await pool.query(
            'SELECT * FROM categories WHERE restaurant_id = $1', [restaurantId]
        );

        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Endpoint to get social media data for a restaurant
app.get('/settings/social/:restaurantId', async(req, res) => {
    try {
        const { restaurantId } = req.params;

        const result = await pool.query(
            'SELECT * FROM restaurant_social WHERE restaurant_id = $1', [restaurantId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Social data not found for this restaurant' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Maintain backwards compatibility with the old endpoint
app.get('/settings/social', async(req, res) => {
    try {
        const restaurantId = req.query.restaurantId;

        if (!restaurantId) {
            return res.status(400).json({ error: 'Restaurant ID is required' });
        }

        const result = await pool.query(
            'SELECT * FROM restaurant_social WHERE restaurant_id = $1', [restaurantId]
        );

        if (result.rows.length === 0) {
            // Return default data if not found
            return res.json({
                restaurantName: 'Restaurant Name Not Found',
                facebook: '',
                instagram: '',
                twitter: '',
                phoneNumber: ''
            });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Add social data for a restaurant
app.post('/settings/social', async(req, res) => {
    try {
        const { restaurant_id, restaurant_name, facebook, instagram, twitter, phone_number } = req.body;

        // Check if entry exists first
        const checkResult = await pool.query(
            'SELECT * FROM restaurant_social WHERE restaurant_id = $1', [restaurant_id]
        );

        let result;
        if (checkResult.rows.length > 0) {
            // Update existing record
            result = await pool.query(
                'UPDATE restaurant_social SET restaurant_name = $1, facebook = $2, instagram = $3, twitter = $4, phone_number = $5 WHERE restaurant_id = $6 RETURNING *', [restaurant_name, facebook, instagram, twitter, phone_number, restaurant_id]
            );
        } else {
            // Insert new record
            result = await pool.query(
                'INSERT INTO restaurant_social (restaurant_id, restaurant_name, facebook, instagram, twitter, phone_number) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *', [restaurant_id, restaurant_name, facebook, instagram, twitter, phone_number]
            );
        }

        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Endpoint to get dishes for a given category
app.get('/categories/:categoryId/dishes', async(req, res) => {
    try {
        const categoryId = req.params.categoryId;

        const result = await pool.query(
            'SELECT * FROM dishes WHERE category_id = $1', [categoryId]
        );

        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Add a new restaurant
app.post('/restaurants', async(req, res) => {
    try {
        const { name, slug, address } = req.body;
        const result = await pool.query(
            'INSERT INTO restaurants (name, slug, address) VALUES ($1, $2, $3) RETURNING *', [name, slug, address]
        );

        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Add a new category
app.post('/categories', async(req, res) => {
    try {
        const { restaurant_id, name, description } = req.body;
        const result = await pool.query(
            'INSERT INTO categories (restaurant_id, name, description) VALUES ($1, $2, $3) RETURNING *', [restaurant_id, name, description]
        );

        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Add a new dish
app.post('/dishes', async(req, res) => {
    try {
        const { restaurant_id, category_id, name, description, price, image_url, is_available } = req.body;
        const result = await pool.query(
            'INSERT INTO dishes (restaurant_id, category_id, name, description, price, image_url, is_available) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *', [restaurant_id, category_id, name, description, price, image_url, is_available]
        );

        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.listen(port, () => {
    console.log(`API server running on http://localhost:${port}`);
});