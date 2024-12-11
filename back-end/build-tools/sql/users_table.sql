-- File: create_users_table.sql

-- Create the users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,                     -- Auto-incremented unique identifier
    email VARCHAR(255) UNIQUE NOT NULL,        -- User's email (unique and not null)
    first_name VARCHAR(255),                   -- User's first name
    last_name VARCHAR(255),                    -- User's last name
    password VARCHAR(255) NOT NULL,            -- Encrypted user password
    user_active INT DEFAULT 1,                 -- Active status (1: active, 0: inactive)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Creation timestamp
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Update timestamp
);