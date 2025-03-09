const express = require('express');
const cors = require('cors');
const app = express();
const port = 3000;

// Enable CORS if you're testing with Flutter web or on a different device
app.use(cors());

app.use('/uploads', express.static('uploads'));


// Sample data for demo purposes
const menuData = {
    categories: [
        { id: 'varieties', name: 'Varieties', imageUrl: 'http://localhost:3000/uploads/pide.jpg', description: 'A tasty dish with onions bla bla blac.', },
        { id: 'desserts', name: 'Desserts', description: 'A tasty dish with onions bla bla blac.', imageUrl: 'http://example.com/dish2.jpg', },
        { id: 'main_courses', name: 'Main Courses' }
    ],
    dishes: {
        varieties: [{
                id: 1,
                name: 'Dish 1',
                description: 'Contrary to 32',

                price: 9.99,
                imageUrl: 'http://localhost:3000/uploads/pide.jpg',
                categoryId: 'varieties',
                isAvailable: true
            },
            {
                id: 2,
                name: 'Dish 2',
                description: 'Another tasty dish.',
                price: 12.99,
                imageUrl: 'http://example.com/dish2.jpg',
                categoryId: 'varieties',
                isAvailable: true
            },
            {
                id: 2,
                name: 'Dish 3',
                description: 'Another tasty dish.',
                price: 12.99,
                imageUrl: 'http://example.com/dish2.jpg',
                categoryId: 'varieties',
                isAvailable: true
            }, {
                id: 2,
                name: 'Dish 4',
                description: 'Another tasty dish.',
                price: 12.99,
                imageUrl: 'http://example.com/dish2.jpg',
                categoryId: 'varieties',
                isAvailable: true
            }
        ],
        desserts: [{
            id: 3,
            name: 'Chocolate Cake',
            description: 'Delicious chocolate cake.',
            price: 5.99,
            imageUrl: 'http://example.com/chocolatecake.jpg',
            categoryId: 'desserts',
            isAvailable: true
        }],
        main_courses: [{
            id: 4,
            name: 'Steak',
            description: 'Juicy grilled steak.',
            price: 19.99,
            imageUrl: 'http://example.com/steak.jpg',
            categoryId: 'main_courses',
            isAvailable: true
        }]
    }
};

// Endpoint to get menu categories
app.get('/categories', (req, res) => {
    res.json(menuData.categories);
});


const socialdata = {
    restaurantName: 'adilbabanın restoranı',
    facebook: 'https://www.facebook.com/',
    instagram: 'https://www.instagram.com/',
    twitter: 'https://twitter.com/',
    phoneNumber: '1234567890',
}


app.get('/settings/social', (req, res) => {
    res.json(socialdata);
});


// Endpoint to get dishes for a given category
app.get('/categories/:category/dishes', (req, res) => {
    const category = req.params.category;
    const dishes = menuData.dishes[category];
    if (dishes) {
        res.json(dishes);
    } else {
        res.status(404).json({ error: 'Category not found' });
    }
});

app.listen(port, () => {
    console.log(`API server running on http://localhost:${port}`);
});