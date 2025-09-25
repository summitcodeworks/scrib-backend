# Scrib Backend Database Documentation

## Overview

This directory contains all database-related scripts and documentation for the Scrib Backend application. The database is built on PostgreSQL and includes comprehensive schema, sample data, and maintenance scripts.

## Database Structure

### Tables
- **users**: User management and authentication
- **notes**: Note storage with rich text and code formatting

### Key Features
- UUID primary keys for all entities
- Soft delete functionality for notes
- Full-text search capabilities
- Comprehensive indexing for performance
- Real-time activity tracking
- Data validation and constraints

## Files Description

### 1. `schema.sql`
Complete database schema with:
- Table definitions with proper constraints
- Indexes for optimal performance
- Triggers for automatic timestamp updates
- Views for common queries
- Stored procedures for complex operations
- Sample data for testing

### 2. `init.sql`
Initialization script for Docker containers:
- Basic table creation
- Essential indexes
- Default admin user
- Sample welcome notes

### 3. `migrations.sql`
Database migration scripts for:
- Adding new indexes
- Creating triggers and functions
- Adding views and stored procedures
- Performance optimizations
- Data cleanup procedures

### 4. `sample_data.sql`
Comprehensive sample data including:
- Multiple test users
- Notes in various programming languages
- Public and private notes
- Rich text formatting examples
- Code snippets in multiple languages
- Deleted notes for testing

### 5. `backup_restore.sql`
Backup and restore procedures:
- Automated backup scripts
- Restore procedures
- Backup verification
- Disaster recovery
- Cloud backup integration

## Quick Start

### 1. Initialize Database
```bash
# Run the complete schema
psql -h localhost -U scrib_user -d scrib -f database/schema.sql

# Or run initialization only
psql -h localhost -U scrib_user -d scrib -f database/init.sql
```

### 2. Add Sample Data
```bash
# Add comprehensive sample data
psql -h localhost -U scrib_user -d scrib -f database/sample_data.sql
```

### 3. Run Migrations
```bash
# Apply database migrations
psql -h localhost -U scrib_user -d scrib -f database/migrations.sql
```

## Database Schema Details

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP
);
```

### Notes Table
```sql
CREATE TABLE notes (
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
```

## Performance Optimizations

### Indexes
- **Primary Keys**: UUID with default generation
- **Foreign Keys**: User ID references
- **Search Indexes**: Full-text search on title and content
- **Composite Indexes**: Multi-column indexes for common queries
- **Partial Indexes**: Active notes only

### Triggers
- **Auto-update**: `updated_at` timestamp on note changes
- **Activity Tracking**: User activity updates on note operations

### Views
- **active_notes**: Non-deleted notes with user information
- **public_notes**: Public notes only
- **user_notes**: User-specific notes

## Sample Data

The database includes comprehensive sample data:

### Users (5 users)
- john_doe, jane_smith, alex_dev, sarah_writer, mike_coder

### Notes (15+ notes)
- **JavaScript**: Fundamentals, React Hooks, Private notes
- **Python**: Data Analysis, Machine Learning
- **Java**: Spring Boot, Design Patterns
- **HTML/CSS**: Grid Layout, Semantic Elements
- **SQL**: Queries, Database Optimization
- **Mixed Content**: Full-stack development, Learning journey
- **Technical**: Docker, Git workflows

### Programming Languages Covered
- JavaScript, Python, Java, HTML, CSS, SQL
- Dockerfile, Bash, YAML
- Various code snippets with syntax highlighting

## Backup and Restore

### Automated Backups
```bash
# Daily backup
./backup_daily.sh

# Weekly backup
./backup_weekly.sh
```

### Manual Backup
```bash
# Full backup
pg_dump -h localhost -U scrib_user -d scrib > scrib_backup_$(date +%Y%m%d_%H%M%S).sql

# Compressed backup
pg_dump -h localhost -U scrib_user -d scrib | gzip > scrib_backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Restore
```bash
# Restore from backup
psql -h localhost -U scrib_user -d scrib < scrib_backup_20240115_103000.sql

# Restore from compressed backup
gunzip -c scrib_backup_20240115_103000.sql.gz | psql -h localhost -U scrib_user -d scrib
```

## Maintenance

### Regular Maintenance
```sql
-- Analyze tables for better performance
ANALYZE users;
ANALYZE notes;

-- Vacuum to reclaim space
VACUUM ANALYZE;
```

### Cleanup Old Data
```sql
-- Soft delete old notes
UPDATE notes 
SET deleted_at = CURRENT_TIMESTAMP 
WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '1 year'
  AND updated_at < CURRENT_TIMESTAMP - INTERVAL '6 months'
  AND deleted_at IS NULL;
```

## Monitoring

### Database Health Check
```sql
-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Performance Monitoring
```sql
-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

## Security

### User Permissions
```sql
-- Create application user
CREATE ROLE scrib_user WITH LOGIN PASSWORD 'scrib_password';

-- Grant permissions
GRANT CONNECT ON DATABASE scrib TO scrib_user;
GRANT USAGE ON SCHEMA public TO scrib_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO scrib_user;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO scrib_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO scrib_user;
```

### Data Validation
- Username length and format validation
- Content size limits (10MB max)
- Visibility enum constraints
- Foreign key constraints

## Troubleshooting

### Common Issues

1. **Connection Issues**
   - Check PostgreSQL service status
   - Verify connection parameters
   - Check firewall settings

2. **Performance Issues**
   - Run ANALYZE on tables
   - Check index usage
   - Monitor query execution plans

3. **Backup Issues**
   - Verify backup file integrity
   - Check disk space
   - Test restore procedures

### Useful Queries

```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('scrib'));

-- Check active connections
SELECT COUNT(*) FROM pg_stat_activity WHERE datname = 'scrib';

-- Check table statistics
SELECT 
    'Users' as table_name, 
    COUNT(*) as record_count,
    MAX(created_at) as latest_record
FROM users
UNION ALL
SELECT 
    'Notes' as table_name, 
    COUNT(*) as record_count,
    MAX(created_at) as latest_record
FROM notes
WHERE deleted_at IS NULL;
```

## Development

### Local Development
1. Start PostgreSQL service
2. Create database: `CREATE DATABASE scrib;`
3. Run schema: `psql -d scrib -f database/schema.sql`
4. Add sample data: `psql -d scrib -f database/sample_data.sql`

### Testing
- Use sample data for integration tests
- Test backup and restore procedures
- Verify all constraints and triggers
- Test performance with large datasets

## Production Deployment

### Pre-deployment Checklist
- [ ] Run complete schema setup
- [ ] Apply all migrations
- [ ] Set up automated backups
- [ ] Configure monitoring
- [ ] Test restore procedures
- [ ] Set up user permissions
- [ ] Configure connection pooling

### Post-deployment
- [ ] Monitor database performance
- [ ] Set up backup verification
- [ ] Configure log rotation
- [ ] Set up alerting
- [ ] Plan maintenance windows

---

This database setup provides a robust foundation for the Scrib Backend application with comprehensive features for note-taking, search, and real-time collaboration.
