#!/bin/bash

# Scrib Backend Cleanup Script
# This script cleans up all Scrib Backend services and resources

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
PID_DIR="$PROJECT_ROOT/pids"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to stop all services
stop_all_services() {
    print_status "Stopping all services..."
    
    # Stop services using the stop script
    if [ -f "$PROJECT_ROOT/scripts/stop-services.sh" ]; then
        "$PROJECT_ROOT/scripts/stop-services.sh" --force
    else
        print_warning "Stop script not found, manually stopping services..."
        
        # Kill any remaining Java processes
        pkill -f "spring-boot:run" 2>/dev/null || true
        pkill -f "scrib" 2>/dev/null || true
        
        # Kill processes on specific ports
        local ports=(9200 9201 9202 9203)
        for port in "${ports[@]}"; do
            local pids=$(lsof -Pi :$port -sTCP:LISTEN -t 2>/dev/null)
            if [ -n "$pids" ]; then
                echo "$pids" | xargs kill -9 2>/dev/null || true
            fi
        done
    fi
    
    print_success "All services stopped"
}

# Function to stop Docker containers
stop_docker_containers() {
    print_status "Stopping Docker containers..."
    
    if command -v docker &> /dev/null; then
        # Stop Scrib containers
        docker stop scrib-postgres scrib-redis 2>/dev/null || true
        docker rm scrib-postgres scrib-redis 2>/dev/null || true
        
        print_success "Docker containers stopped and removed"
    else
        print_warning "Docker not found, skipping container cleanup"
    fi
}

# Function to clean up files and directories
cleanup_files() {
    print_status "Cleaning up files and directories..."
    
    # Remove log files
    if [ -d "$LOG_DIR" ]; then
        rm -rf "$LOG_DIR"/*
        print_success "Log files cleaned"
    fi
    
    # Remove PID files
    if [ -d "$PID_DIR" ]; then
        rm -rf "$PID_DIR"/*
        print_success "PID files cleaned"
    fi
    
    # Remove temporary files
    if [ -d "$PROJECT_ROOT/tmp" ]; then
        rm -rf "$PROJECT_ROOT/tmp"/*
        print_success "Temporary files cleaned"
    fi
    
    # Remove Maven target directories
    find "$PROJECT_ROOT" -name "target" -type d -exec rm -rf {} + 2>/dev/null || true
    print_success "Maven target directories cleaned"
    
    # Remove compiled classes
    find "$PROJECT_ROOT" -name "*.class" -delete 2>/dev/null || true
    print_success "Compiled classes cleaned"
}

# Function to clean up Docker resources
cleanup_docker() {
    print_status "Cleaning up Docker resources..."
    
    if command -v docker &> /dev/null; then
        # Remove unused containers
        docker container prune -f
        
        # Remove unused images
        docker image prune -f
        
        # Remove unused volumes
        docker volume prune -f
        
        # Remove unused networks
        docker network prune -f
        
        print_success "Docker resources cleaned"
    else
        print_warning "Docker not found, skipping Docker cleanup"
    fi
}

# Function to clean up database
cleanup_database() {
    print_status "Cleaning up database..."
    
    if command -v docker &> /dev/null; then
        # Check if PostgreSQL container exists
        if docker ps -a | grep -q scrib-postgres; then
            print_warning "PostgreSQL container found. Do you want to remove it? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                docker stop scrib-postgres
                docker rm scrib-postgres
                print_success "PostgreSQL container removed"
            else
                print_warning "PostgreSQL container kept"
            fi
        fi
    else
        print_warning "Docker not found, skipping database cleanup"
    fi
}

# Function to clean up Redis
cleanup_redis() {
    print_status "Cleaning up Redis..."
    
    if command -v docker &> /dev/null; then
        # Check if Redis container exists
        if docker ps -a | grep -q scrib-redis; then
            print_warning "Redis container found. Do you want to remove it? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                docker stop scrib-redis
                docker rm scrib-redis
                print_success "Redis container removed"
            else
                print_warning "Redis container kept"
            fi
        fi
    else
        print_warning "Docker not found, skipping Redis cleanup"
    fi
}

# Function to clean up logs
cleanup_logs() {
    print_status "Cleaning up logs..."
    
    # Remove old log files (older than 7 days)
    find "$PROJECT_ROOT" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    # Remove old backup files (older than 30 days)
    find "$PROJECT_ROOT" -name "*.backup" -mtime +30 -delete 2>/dev/null || true
    
    print_success "Old logs cleaned"
}

# Function to reset database
reset_database() {
    print_status "Resetting database..."
    
    if command -v docker &> /dev/null; then
        # Stop and remove PostgreSQL container
        docker stop scrib-postgres 2>/dev/null || true
        docker rm scrib-postgres 2>/dev/null || true
        
        # Start fresh PostgreSQL container
        docker run -d \
            --name scrib-postgres \
            -e POSTGRES_DB=scrib \
            -e POSTGRES_USER=scrib_user \
            -e POSTGRES_PASSWORD=scrib_password \
            -p 5432:5432 \
            postgres:15
        
        # Wait for PostgreSQL to be ready
        sleep 10
        
        # Setup database schema
        if [ -f "$PROJECT_ROOT/database/schema.sql" ]; then
            docker exec -i scrib-postgres psql -U scrib_user -d scrib < "$PROJECT_ROOT/database/schema.sql"
            print_success "Database schema recreated"
        fi
        
        # Add sample data
        if [ -f "$PROJECT_ROOT/database/sample_data.sql" ]; then
            docker exec -i scrib-postgres psql -U scrib_user -d scrib < "$PROJECT_ROOT/database/sample_data.sql"
            print_success "Sample data added"
        fi
    else
        print_warning "Docker not found, skipping database reset"
    fi
}

# Function to show cleanup summary
show_summary() {
    print_status "Cleanup Summary:"
    echo "================"
    
    # Check if services are running
    local services_running=false
    local ports=(9200 9201 9202 9203)
    
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            services_running=true
            break
        fi
    done
    
    if [ "$services_running" = true ]; then
        print_warning "Some services are still running"
    else
        print_success "All services are stopped"
    fi
    
    # Check Docker containers
    if command -v docker &> /dev/null; then
        local containers=$(docker ps -a | grep -c scrib- || true)
        if [ "$containers" -gt 0 ]; then
            print_warning "$containers Scrib containers found"
        else
            print_success "No Scrib containers found"
        fi
    fi
    
    # Check log files
    local log_count=$(find "$PROJECT_ROOT" -name "*.log" 2>/dev/null | wc -l)
    if [ "$log_count" -gt 0 ]; then
        print_warning "$log_count log files found"
    else
        print_success "No log files found"
    fi
}

# Main execution
main() {
    print_status "Scrib Backend Cleanup"
    echo "====================="
    echo
    
    # Confirm cleanup
    print_warning "This will clean up all Scrib Backend services and resources."
    print_warning "Are you sure you want to continue? (y/N)"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
    
    # Stop all services
    stop_all_services
    
    # Clean up files
    cleanup_files
    
    # Clean up Docker resources
    cleanup_docker
    
    # Clean up logs
    cleanup_logs
    
    # Show summary
    show_summary
    
    print_success "Cleanup completed!"
}

# Handle script arguments
case "${1:-}" in
    --services)
        stop_all_services
        ;;
    --docker)
        stop_docker_containers
        cleanup_docker
        ;;
    --database)
        cleanup_database
        ;;
    --redis)
        cleanup_redis
        ;;
    --files)
        cleanup_files
        ;;
    --logs)
        cleanup_logs
        ;;
    --reset-db)
        reset_database
        ;;
    --force)
        print_warning "Force cleanup without confirmation..."
        stop_all_services
        cleanup_files
        cleanup_docker
        cleanup_logs
        print_success "Force cleanup completed!"
        ;;
    --help)
        echo "Usage: $0 [--services|--docker|--database|--redis|--files|--logs|--reset-db|--force|--help]"
        echo "  --services  Stop all services only"
        echo "  --docker    Clean up Docker resources only"
        echo "  --database  Clean up database only"
        echo "  --redis     Clean up Redis only"
        echo "  --files     Clean up files only"
        echo "  --logs      Clean up logs only"
        echo "  --reset-db  Reset database completely"
        echo "  --force     Force cleanup without confirmation"
        echo "  --help      Show this help message"
        ;;
    *)
        main
        ;;
esac
