-- Scrib Backend Database Initialization Script
-- This script is run when the database container starts
-- It sets up the basic database structure and initial data

-- ==============================================
-- DATABASE SETUP
-- ==============================================

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE scrib'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'scrib')\gexec

-- Connect to the scrib database
\c scrib;

-- ==============================================
-- EXTENSIONS
-- ==============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ==============================================
-- BASIC TABLES SETUP
-- ==============================================

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP
);

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    title VARCHAR(255),
    content TEXT,
    visibility VARCHAR(20) NOT NULL DEFAULT 'PRIVATE' CHECK (visibility IN ('PUBLIC', 'PRIVATE')),
    code_language VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    CONSTRAINT fk_notes_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ==============================================
-- BASIC INDEXES
-- ==============================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Notes indexes
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_visibility ON notes(visibility);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at);
CREATE INDEX IF NOT EXISTS idx_notes_deleted_at ON notes(deleted_at);

-- ==============================================
-- INITIAL DATA
-- ==============================================

-- Insert default admin user
INSERT INTO users (id, username, created_at, last_activity_at) VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (username) DO NOTHING;

-- Insert sample notes
INSERT INTO notes (id, user_id, title, content, visibility, code_language, created_at, updated_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440000', 
     'Welcome to Scrib', 
     '<p>Welcome to <strong>Scrib</strong> - your note-taking application!</p><p>This is a sample note to get you started.</p>', 
     'PUBLIC', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', 
     'Getting Started', 
     '<p>Here are some tips to get started:</p><ul><li>Create your first note</li><li>Try different formatting options</li><li>Add code snippets</li></ul>', 
     'PUBLIC', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- ==============================================
-- COMPLETION MESSAGE
-- ==============================================

SELECT 'Database initialization completed successfully!' as status;
