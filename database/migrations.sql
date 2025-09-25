-- Scrib Backend Database Migrations
-- This script contains all database migrations for version updates
-- Run these migrations in order when updating the database schema

-- ==============================================
-- MIGRATION 001: Add Full-Text Search Indexes
-- ==============================================

-- Add full-text search indexes for better search performance
CREATE INDEX IF NOT EXISTS idx_notes_title_gin ON notes USING gin(to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_notes_content_gin ON notes USING gin(to_tsvector('english', content));

-- Add trigram indexes for partial matching
CREATE INDEX IF NOT EXISTS idx_notes_title_trgm ON notes USING gin(title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_notes_content_trgm ON notes USING gin(content gin_trgm_ops);

-- ==============================================
-- MIGRATION 002: Add Composite Indexes
-- ==============================================

-- Add composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_notes_visibility_created ON notes(visibility, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_user_created ON notes(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_language_visibility ON notes(code_language, visibility);
CREATE INDEX IF NOT EXISTS idx_notes_user_visibility ON notes(user_id, visibility);

-- ==============================================
-- MIGRATION 003: Add Updated At Trigger
-- ==============================================

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for notes table
DROP TRIGGER IF EXISTS update_notes_updated_at ON notes;
CREATE TRIGGER update_notes_updated_at 
    BEFORE UPDATE ON notes 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ==============================================
-- MIGRATION 004: Add User Activity Tracking
-- ==============================================

-- Create function to update user activity
CREATE OR REPLACE FUNCTION update_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users 
    SET last_activity_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for user activity tracking
DROP TRIGGER IF EXISTS update_user_activity_on_note_change ON notes;
CREATE TRIGGER update_user_activity_on_note_change
    AFTER INSERT OR UPDATE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_user_activity();

-- ==============================================
-- MIGRATION 005: Add Database Views
-- ==============================================

-- Create view for active notes
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

-- Create view for public notes
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

-- ==============================================
-- MIGRATION 006: Add Search Functions
-- ==============================================

-- Create search function
CREATE OR REPLACE FUNCTION search_notes(
    search_query TEXT DEFAULT NULL,
    user_filter UUID DEFAULT NULL,
    visibility_filter VARCHAR(20) DEFAULT NULL,
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
    visibility VARCHAR(20),
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

-- ==============================================
-- MIGRATION 007: Add Statistics Function
-- ==============================================

-- Create statistics function
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
        COALESCE(
            jsonb_object_agg(
                COALESCE(code_language, 'none'), 
                language_count
            ) FILTER (WHERE code_language IS NOT NULL),
            '{}'::jsonb
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
-- MIGRATION 008: Add Performance Indexes
-- ==============================================

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notes_active_notes ON notes(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_last_activity ON users(last_activity_at);

-- ==============================================
-- MIGRATION 009: Add Data Validation
-- ==============================================

-- Add check constraints for data validation
ALTER TABLE notes ADD CONSTRAINT chk_notes_title_length CHECK (LENGTH(title) <= 255);
ALTER TABLE notes ADD CONSTRAINT chk_notes_content_size CHECK (LENGTH(content) <= 10485760); -- 10MB
ALTER TABLE notes ADD CONSTRAINT chk_notes_language_length CHECK (LENGTH(code_language) <= 50);

-- ==============================================
-- MIGRATION 010: Add Cleanup Procedures
-- ==============================================

-- Create cleanup function for old data
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Soft delete old notes (older than 1 year and not updated)
    UPDATE notes 
    SET deleted_at = CURRENT_TIMESTAMP 
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '1 year'
      AND updated_at < CURRENT_TIMESTAMP - INTERVAL '6 months'
      AND deleted_at IS NULL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Permanently delete soft-deleted notes (older than 6 months)
    DELETE FROM notes 
    WHERE deleted_at IS NOT NULL 
      AND deleted_at < CURRENT_TIMESTAMP - INTERVAL '6 months';
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- MIGRATION COMPLETION
-- ==============================================

-- Log migration completion
INSERT INTO users (id, username, created_at, last_activity_at) VALUES
    ('00000000-0000-0000-0000-000000000000', 'migration_system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (username) DO NOTHING;

-- Create migration log table
CREATE TABLE IF NOT EXISTS migration_log (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(255) NOT NULL,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS'
);

-- Log this migration
INSERT INTO migration_log (migration_name, status) VALUES 
    ('database_migrations_v1', 'SUCCESS');

-- ==============================================
-- END OF MIGRATIONS
-- ==============================================

SELECT 'All migrations completed successfully!' as status;
