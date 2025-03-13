-- Users table for authentication
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    restaurant_id INTEGER REFERENCES restaurants(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Example user (password: 1234)
-- INSERT INTO users (email, password, restaurant_id) 
-- VALUES ('adilbaba@gmail.com', '$2b$10$3euPcmQFCiZiNkQgd5QYg.4LESu4cXczYOW.HdVlJVT2Z1Ty6xJce', 1);

-- Add updated_at column to dishes table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'dishes' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE dishes ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Remove is_available column from schema - it's not used anymore
