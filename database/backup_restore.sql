-- Scrib Backend Database Backup and Restore Scripts
-- This file contains scripts for backing up and restoring the database

-- ==============================================
-- BACKUP SCRIPTS
-- ==============================================

-- Full database backup (run from command line)
-- pg_dump -h localhost -U scrib_user -d scrib > scrib_backup_$(date +%Y%m%d_%H%M%S).sql

-- Schema only backup
-- pg_dump -h localhost -U scrib_user -d scrib --schema-only > scrib_schema_backup_$(date +%Y%m%d_%H%M%S).sql

-- Data only backup
-- pg_dump -h localhost -U scrib_user -d scrib --data-only > scrib_data_backup_$(date +%Y%m%d_%H%M%S).sql

-- Compressed backup
-- pg_dump -h localhost -U scrib_user -d scrib | gzip > scrib_backup_$(date +%Y%m%d_%H%M%S).sql.gz

-- ==============================================
-- RESTORE SCRIPTS
-- ==============================================

-- Restore from full backup
-- psql -h localhost -U scrib_user -d scrib < scrib_backup_20240115_103000.sql

-- Restore from compressed backup
-- gunzip -c scrib_backup_20240115_103000.sql.gz | psql -h localhost -U scrib_user -d scrib

-- Restore schema only
-- psql -h localhost -U scrib_user -d scrib < scrib_schema_backup_20240115_103000.sql

-- Restore data only
-- psql -h localhost -U scrib_user -d scrib < scrib_data_backup_20240115_103000.sql

-- ==============================================
-- BACKUP VERIFICATION
-- ==============================================

-- Verify backup integrity
-- pg_dump -h localhost -U scrib_user -d scrib --schema-only | grep -c "CREATE TABLE"

-- Check backup file size
-- ls -lh scrib_backup_*.sql

-- ==============================================
-- AUTOMATED BACKUP SCRIPT
-- ==============================================

-- Create backup directory
-- mkdir -p /backups/scrib

-- Daily backup script (save as backup_daily.sh)
-- #!/bin/bash
-- BACKUP_DIR="/backups/scrib"
-- DB_NAME="scrib"
-- DB_USER="scrib_user"
-- DB_HOST="localhost"
-- DATE=$(date +%Y%m%d_%H%M%S)
-- 
-- # Create backup
-- pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME | gzip > $BACKUP_DIR/scrib_backup_$DATE.sql.gz
-- 
-- # Keep only last 7 days of backups
-- find $BACKUP_DIR -name "scrib_backup_*.sql.gz" -mtime +7 -delete
-- 
-- echo "Backup completed: scrib_backup_$DATE.sql.gz"

-- Weekly backup script (save as backup_weekly.sh)
-- #!/bin/bash
-- BACKUP_DIR="/backups/scrib"
-- DB_NAME="scrib"
-- DB_USER="scrib_user"
-- DB_HOST="localhost"
-- DATE=$(date +%Y%m%d_%H%M%S)
-- 
-- # Create full backup with schema and data
-- pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME --verbose --format=custom --file=$BACKUP_DIR/scrib_full_backup_$DATE.dump
-- 
-- # Keep only last 4 weeks of weekly backups
-- find $BACKUP_DIR -name "scrib_full_backup_*.dump" -mtime +28 -delete
-- 
-- echo "Weekly backup completed: scrib_full_backup_$DATE.dump"

-- ==============================================
-- RESTORE FROM CUSTOM FORMAT
-- ==============================================

-- Restore from custom format backup
-- pg_restore -h localhost -U scrib_user -d scrib --verbose scrib_full_backup_20240115_103000.dump

-- Restore with data only (skip schema)
-- pg_restore -h localhost -U scrib_user -d scrib --data-only --verbose scrib_full_backup_20240115_103000.dump

-- Restore specific tables
-- pg_restore -h localhost -U scrib_user -d scrib --table=users --table=notes scrib_full_backup_20240115_103000.dump

-- ==============================================
-- DATABASE MAINTENANCE
-- ==============================================

-- Analyze tables for better query performance
ANALYZE users;
ANALYZE notes;

-- Update table statistics
UPDATE pg_stat_user_tables SET n_tup_ins = 0, n_tup_upd = 0, n_tup_del = 0;

-- Vacuum database to reclaim space
VACUUM ANALYZE;

-- Full vacuum (requires exclusive lock)
-- VACUUM FULL;

-- ==============================================
-- BACKUP MONITORING
-- ==============================================

-- Create backup log table
CREATE TABLE IF NOT EXISTS backup_log (
    id SERIAL PRIMARY KEY,
    backup_name VARCHAR(255) NOT NULL,
    backup_size BIGINT,
    backup_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
    error_message TEXT
);

-- Function to log backup operations
CREATE OR REPLACE FUNCTION log_backup(
    backup_name_param VARCHAR(255),
    backup_size_param BIGINT,
    status_param VARCHAR(20) DEFAULT 'SUCCESS',
    error_message_param TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO backup_log (backup_name, backup_size, status, error_message)
    VALUES (backup_name_param, backup_size_param, status_param, error_message_param);
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- BACKUP VERIFICATION QUERIES
-- ==============================================

-- Check backup log
SELECT 
    backup_name,
    backup_size,
    backup_date,
    status,
    error_message
FROM backup_log
ORDER BY backup_date DESC
LIMIT 10;

-- Check database size
SELECT 
    pg_size_pretty(pg_database_size('scrib')) as database_size;

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ==============================================
-- DISASTER RECOVERY
-- ==============================================

-- Create disaster recovery checklist
-- 1. Stop application services
-- 2. Backup current database state
-- 3. Restore from latest backup
-- 4. Verify data integrity
-- 5. Restart application services
-- 6. Test application functionality

-- Emergency restore procedure
-- 1. Drop existing database
-- DROP DATABASE IF EXISTS scrib;
-- 
-- 2. Create new database
-- CREATE DATABASE scrib;
-- 
-- 3. Restore from backup
-- psql -h localhost -U scrib_user -d scrib < scrib_backup_20240115_103000.sql
-- 
-- 4. Verify restore
-- \c scrib;
-- SELECT COUNT(*) FROM users;
-- SELECT COUNT(*) FROM notes;

-- ==============================================
-- BACKUP RETENTION POLICY
-- ==============================================

-- Daily backups: Keep for 7 days
-- Weekly backups: Keep for 4 weeks
-- Monthly backups: Keep for 12 months
-- Yearly backups: Keep indefinitely

-- Cleanup old backups script
-- #!/bin/bash
-- BACKUP_DIR="/backups/scrib"
-- 
-- # Remove daily backups older than 7 days
-- find $BACKUP_DIR -name "scrib_backup_*.sql.gz" -mtime +7 -delete
-- 
-- # Remove weekly backups older than 4 weeks
-- find $BACKUP_DIR -name "scrib_full_backup_*.dump" -mtime +28 -delete
-- 
-- # Remove monthly backups older than 12 months
-- find $BACKUP_DIR -name "scrib_monthly_backup_*.sql.gz" -mtime +365 -delete
-- 
-- echo "Backup cleanup completed"

-- ==============================================
-- BACKUP TESTING
-- ==============================================

-- Test backup integrity
-- pg_dump -h localhost -U scrib_user -d scrib --schema-only | grep -c "CREATE TABLE"
-- Expected result: Should return the number of tables created

-- Test restore to temporary database
-- CREATE DATABASE scrib_test;
-- psql -h localhost -U scrib_user -d scrib_test < scrib_backup_20240115_103000.sql
-- 
-- -- Verify restore
-- \c scrib_test;
-- SELECT COUNT(*) FROM users;
-- SELECT COUNT(*) FROM notes;
-- 
-- -- Cleanup test database
-- DROP DATABASE scrib_test;

-- ==============================================
-- BACKUP ENCRYPTION
-- ==============================================

-- Encrypt backup files
-- gpg --symmetric --cipher-algo AES256 scrib_backup_20240115_103000.sql

-- Decrypt backup files
-- gpg --decrypt scrib_backup_20240115_103000.sql.gpg > scrib_backup_20240115_103000.sql

-- ==============================================
-- CLOUD BACKUP
-- ==============================================

-- Upload to AWS S3
-- aws s3 cp scrib_backup_20240115_103000.sql.gz s3://my-backup-bucket/scrib/

-- Download from AWS S3
-- aws s3 cp s3://my-backup-bucket/scrib/scrib_backup_20240115_103000.sql.gz ./

-- Upload to Google Cloud Storage
-- gsutil cp scrib_backup_20240115_103000.sql.gz gs://my-backup-bucket/scrib/

-- Download from Google Cloud Storage
-- gsutil cp gs://my-backup-bucket/scrib/scrib_backup_20240115_103000.sql.gz ./

-- ==============================================
-- END OF BACKUP AND RESTORE SCRIPTS
-- ==============================================

SELECT 'Backup and restore scripts ready!' as status;
