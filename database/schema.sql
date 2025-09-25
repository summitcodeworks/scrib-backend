-- Scrib Backend Database Schema
-- PostgreSQL Database Setup Script
-- Version: 1.0.0
-- Created: 2024-01-15

-- ==============================================
-- DATABASE CREATION
-- ==============================================

-- Create database if it doesn't exist
-- Note: This requires superuser privileges
-- CREATE DATABASE scrib;

-- Connect to the scrib database
-- \c scrib;

-- ==============================================
-- EXTENSIONS
-- ==============================================

-- Enable UUID extension for generating UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable full-text search extension
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ==============================================
-- ENUMS
-- ==============================================

-- Create visibility enum for notes
CREATE TYPE visibility_enum AS ENUM ('PUBLIC', 'PRIVATE');

-- ==============================================
-- TABLES
-- ==============================================

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP
);

-- Notes table
CREATE TABLE IF NOT EXISTS notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    title VARCHAR(255),
    content TEXT,
    visibility visibility_enum NOT NULL DEFAULT 'PRIVATE',
    code_language VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    CONSTRAINT fk_notes_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ==============================================
-- INDEXES
-- ==============================================

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_last_activity ON users(last_activity_at);

-- Notes table indexes
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_visibility ON notes(visibility);
CREATE INDEX IF NOT EXISTS idx_notes_code_language ON notes(code_language);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at);
CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at);
CREATE INDEX IF NOT EXISTS idx_notes_deleted_at ON notes(deleted_at);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_notes_visibility_created ON notes(visibility, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_user_created ON notes(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_language_visibility ON notes(code_language, visibility);
CREATE INDEX IF NOT EXISTS idx_notes_user_visibility ON notes(user_id, visibility);
CREATE INDEX IF NOT EXISTS idx_notes_active_notes ON notes(deleted_at) WHERE deleted_at IS NULL;

-- Full-text search indexes
CREATE INDEX IF NOT EXISTS idx_notes_title_gin ON notes USING gin(to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_notes_content_gin ON notes USING gin(to_tsvector('english', content));
CREATE INDEX IF NOT EXISTS idx_notes_title_trgm ON notes USING gin(title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_notes_content_trgm ON notes USING gin(content gin_trgm_ops);

-- ==============================================
-- FUNCTIONS AND TRIGGERS
-- ==============================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at on notes table
CREATE TRIGGER update_notes_updated_at 
    BEFORE UPDATE ON notes 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update user last activity
CREATE OR REPLACE FUNCTION update_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users 
    SET last_activity_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update user activity when note is created/updated
CREATE TRIGGER update_user_activity_on_note_change
    AFTER INSERT OR UPDATE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_user_activity();

-- ==============================================
-- VIEWS
-- ==============================================

-- View for active (non-deleted) notes
CREATE OR REPLACE VIEW active_notes AS
SELECT 
    n.id,
    n.user_id,
    u.username,
    n.title,
    n.content,
    n.visibility,
    n.code_language,
    n.created_at,
    n.updated_at
FROM notes n
JOIN users u ON n.user_id = u.id
WHERE n.deleted_at IS NULL;

-- View for public notes only
CREATE OR REPLACE VIEW public_notes AS
SELECT 
    n.id,
    n.user_id,
    u.username,
    n.title,
    n.content,
    n.code_language,
    n.created_at,
    n.updated_at
FROM notes n
JOIN users u ON n.user_id = u.id
WHERE n.deleted_at IS NULL 
  AND n.visibility = 'PUBLIC';

-- View for user notes (private + public)
CREATE OR REPLACE VIEW user_notes AS
SELECT 
    n.id,
    n.user_id,
    u.username,
    n.title,
    n.content,
    n.visibility,
    n.code_language,
    n.created_at,
    n.updated_at
FROM notes n
JOIN users u ON n.user_id = u.id
WHERE n.deleted_at IS NULL;

-- ==============================================
-- STORED PROCEDURES
-- ==============================================

-- Function to search notes with full-text search
CREATE OR REPLACE FUNCTION search_notes(
    search_query TEXT DEFAULT NULL,
    user_filter UUID DEFAULT NULL,
    visibility_filter visibility_enum DEFAULT NULL,
    language_filter VARCHAR(50) DEFAULT NULL,
    page_offset INTEGER DEFAULT 0,
    page_size INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    username VARCHAR(50),
    title VARCHAR(255),
    content TEXT,
    visibility visibility_enum,
    code_language VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n.user_id,
        u.username,
        n.title,
        n.content,
        n.visibility,
        n.code_language,
        n.created_at,
        n.updated_at,
        CASE 
            WHEN search_query IS NOT NULL THEN 
                ts_rank(
                    to_tsvector('english', COALESCE(n.title, '') || ' ' || COALESCE(n.content, '')),
                    plainto_tsquery('english', search_query)
                )
            ELSE 0
        END as rank
    FROM notes n
    JOIN users u ON n.user_id = u.id
    WHERE n.deleted_at IS NULL
      AND (user_filter IS NULL OR n.user_id = user_filter)
      AND (visibility_filter IS NULL OR n.visibility = visibility_filter)
      AND (language_filter IS NULL OR n.code_language = language_filter)
      AND (search_query IS NULL OR 
           to_tsvector('english', COALESCE(n.title, '') || ' ' || COALESCE(n.content, '')) 
           @@ plainto_tsquery('english', search_query))
    ORDER BY 
        CASE WHEN search_query IS NOT NULL THEN rank END DESC,
        n.updated_at DESC
    LIMIT page_size
    OFFSET page_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to get note statistics
CREATE OR REPLACE FUNCTION get_note_statistics(user_id_param UUID DEFAULT NULL)
RETURNS TABLE (
    total_notes BIGINT,
    public_notes BIGINT,
    private_notes BIGINT,
    notes_by_language JSONB,
    recent_activity TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_notes,
        COUNT(*) FILTER (WHERE visibility = 'PUBLIC') as public_notes,
        COUNT(*) FILTER (WHERE visibility = 'PRIVATE') as private_notes,
        jsonb_object_agg(
            COALESCE(code_language, 'none'), 
            language_count
        ) as notes_by_language,
        MAX(updated_at) as recent_activity
    FROM (
        SELECT 
            visibility,
            code_language,
            updated_at,
            COUNT(*) OVER (PARTITION BY code_language) as language_count
        FROM notes
        WHERE deleted_at IS NULL
          AND (user_id_param IS NULL OR user_id = user_id_param)
    ) stats;
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- SAMPLE DATA
-- ==============================================

-- Insert sample users
INSERT INTO users (id, username, created_at, last_activity_at) VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'john_doe', '2024-01-15T10:00:00', '2024-01-15T10:30:00'),
    ('550e8400-e29b-41d4-a716-446655440001', 'jane_smith', '2024-01-15T10:05:00', '2024-01-15T10:25:00'),
    ('550e8400-e29b-41d4-a716-446655440002', 'alex_dev', '2024-01-15T10:10:00', '2024-01-15T10:20:00')
ON CONFLICT (username) DO NOTHING;

-- Insert sample notes
INSERT INTO notes (id, user_id, title, content, visibility, code_language, created_at, updated_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440000', 
     'JavaScript Tutorial', 
     '<p>Learn <strong>JavaScript</strong> basics with this comprehensive tutorial.</p><pre><code class="language-javascript">function hello() {\n  console.log("Hello World!");\n}</code></pre>', 
     'PUBLIC', 'javascript', '2024-01-15T10:15:00', '2024-01-15T10:15:00'),
    
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', 
     'My Private Notes', 
     '<p>These are my <em>private</em> thoughts and ideas.</p><ul><li>Important task 1</li><li>Important task 2</li></ul>', 
     'PRIVATE', NULL, '2024-01-15T10:20:00', '2024-01-15T10:20:00'),
    
    ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 
     'Python Data Analysis', 
     '<p>Working with <strong>pandas</strong> and <strong>numpy</strong> for data analysis.</p><pre><code class="language-python">import pandas as pd\nimport numpy as np\n\ndf = pd.read_csv("data.csv")\nprint(df.head())</code></pre>', 
     'PUBLIC', 'python', '2024-01-15T10:25:00', '2024-01-15T10:25:00'),
    
    ('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440002', 
     'React Components', 
     '<p>Building reusable <strong>React</strong> components.</p><pre><code class="language-javascript">const Button = ({ children, onClick }) => {\n  return (\n    <button onClick={onClick}>\n      {children}\n    </button>\n  );\n};</code></pre>', 
     'PUBLIC', 'javascript', '2024-01-15T10:30:00', '2024-01-15T10:30:00')
ON CONFLICT (id) DO NOTHING;

-- ==============================================
-- PERMISSIONS
-- ==============================================

-- Create application user (if not exists)
-- DO $$ 
-- BEGIN
--     IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'scrib_user') THEN
--         CREATE ROLE scrib_user WITH LOGIN PASSWORD 'scrib_password';
--     END IF;
-- END $$;

-- Grant permissions to application user
-- GRANT CONNECT ON DATABASE scrib TO scrib_user;
-- GRANT USAGE ON SCHEMA public TO scrib_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO scrib_user;
-- GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO scrib_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO scrib_user;

-- ==============================================
-- MAINTENANCE QUERIES
-- ==============================================

-- Query to check database health
-- SELECT 
--     'Users' as table_name, 
--     COUNT(*) as record_count,
--     MAX(created_at) as latest_record
-- FROM users
-- UNION ALL
-- SELECT 
--     'Notes' as table_name, 
--     COUNT(*) as record_count,
--     MAX(created_at) as latest_record
-- FROM notes
-- WHERE deleted_at IS NULL;

-- Query to find inactive users (no activity in last 30 days)
-- SELECT 
--     username,
--     last_activity_at,
--     EXTRACT(DAYS FROM CURRENT_TIMESTAMP - last_activity_at) as days_inactive
-- FROM users
-- WHERE last_activity_at < CURRENT_TIMESTAMP - INTERVAL '30 days'
-- ORDER BY last_activity_at ASC;

-- Query to find most active users
-- SELECT 
--     u.username,
--     COUNT(n.id) as note_count,
--     MAX(n.updated_at) as last_note_update
-- FROM users u
-- LEFT JOIN notes n ON u.id = n.user_id AND n.deleted_at IS NULL
-- GROUP BY u.id, u.username
-- ORDER BY note_count DESC, last_note_update DESC;

-- Query to find popular programming languages
-- SELECT 
--     code_language,
--     COUNT(*) as note_count,
--     COUNT(*) FILTER (WHERE visibility = 'PUBLIC') as public_count
-- FROM notes
-- WHERE deleted_at IS NULL 
--   AND code_language IS NOT NULL
-- GROUP BY code_language
-- ORDER BY note_count DESC;

-- ==============================================
-- BACKUP AND RESTORE COMMANDS
-- ==============================================

-- Backup database
-- pg_dump -h localhost -U scrib_user -d scrib > scrib_backup_$(date +%Y%m%d_%H%M%S).sql

-- Restore database
-- psql -h localhost -U scrib_user -d scrib < scrib_backup_20240115_103000.sql

-- ==============================================
-- PERFORMANCE MONITORING
-- ==============================================

-- Query to check table sizes
-- SELECT 
--     schemaname,
--     tablename,
--     pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
-- FROM pg_tables 
-- WHERE schemaname = 'public'
-- ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Query to check index usage
-- SELECT 
--     schemaname,
--     tablename,
--     indexname,
--     idx_scan,
--     idx_tup_read,
--     idx_tup_fetch
-- FROM pg_stat_user_indexes
-- ORDER BY idx_scan DESC;

-- ==============================================
-- CLEANUP SCRIPTS
-- ==============================================

-- Soft delete old notes (older than 1 year and not updated)
-- UPDATE notes 
-- SET deleted_at = CURRENT_TIMESTAMP 
-- WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '1 year'
--   AND updated_at < CURRENT_TIMESTAMP - INTERVAL '6 months'
--   AND deleted_at IS NULL;

-- Permanently delete soft-deleted notes (older than 6 months)
-- DELETE FROM notes 
-- WHERE deleted_at IS NOT NULL 
--   AND deleted_at < CURRENT_TIMESTAMP - INTERVAL '6 months';

-- ==============================================
-- END OF SCHEMA
-- ==============================================

-- Schema creation completed successfully
-- Database is ready for Scrib Backend application
