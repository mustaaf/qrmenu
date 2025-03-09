-- You can run this file to create the restaurant_social table if it doesn't exist yet

CREATE TABLE IF NOT EXISTS restaurant_social (
    id SERIAL PRIMARY KEY,
    restaurant_id INTEGER NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    restaurant_name VARCHAR(100) NOT NULL,
    facebook VARCHAR(255),
    instagram VARCHAR(255),
    twitter VARCHAR(255),
    phone_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(restaurant_id)
);

-- Example insert:
-- INSERT INTO restaurant_social (restaurant_id, restaurant_name, facebook, instagram, twitter, phone_number) 
-- VALUES (1, 'adilbabanın restoranı', 'https://www.facebook.com/', 'https://www.instagram.com/', 'https://twitter.com/', '1234567890');
