-- Initialize Scrib database
CREATE DATABASE IF NOT EXISTS scrib_db;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_visibility ON notes(visibility);
CREATE INDEX IF NOT EXISTS idx_notes_code_language ON notes(code_language);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at);
CREATE INDEX IF NOT EXISTS idx_notes_deleted_at ON notes(deleted_at);

-- Create full-text search indexes
CREATE INDEX IF NOT EXISTS idx_notes_title_gin ON notes USING gin(to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_notes_content_gin ON notes USING gin(to_tsvector('english', content));

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_notes_visibility_created ON notes(visibility, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_user_created ON notes(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_language_visibility ON notes(code_language, visibility);
