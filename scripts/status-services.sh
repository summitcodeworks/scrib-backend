#!/bin/bash

# Scrib Backend Services Status Script
# This script shows the status of all Scrib Backend microservices

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

# Function to check if a service is running
check_service() {
    local service_name=$1
    local port=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to get service PID
get_service_pid() {
    local service_name=$1
    local pid_file="$PID_DIR/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        cat "$pid_file"
    else
        echo "N/A"
    fi
}

# Function to get service memory usage
get_service_memory() {
    local service_name=$1
    local pid_file="$PID_DIR/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            ps -p "$pid" -o rss= | awk '{print $1/1024 " MB"}'
        else
            echo "N/A"
        fi
    else
        echo "N/A"
    fi
}

# Function to get service uptime
get_service_uptime() {
    local service_name=$1
    local pid_file="$PID_DIR/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            ps -p "$pid" -o etime= | awk '{print $1}'
        else
            echo "N/A"
        fi
    else
        echo "N/A"
    fi
}

# Function to check database connection
check_database() {
    if command -v psql &> /dev/null; then
        if psql -h localhost -U scrib_user -d scrib -c "SELECT 1;" &> /dev/null; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Function to check Redis connection
check_redis() {
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping | grep -q "PONG"; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Function to show service status
show_service_status() {
    local service_name=$1
    local port=$2
    local pid=$(get_service_pid "$service_name")
    local memory=$(get_service_memory "$service_name")
    local uptime=$(get_service_uptime "$service_name")
    
    if check_service "$service_name" "$port"; then
        print_success "✓ $service_name"
        echo "    Port: $port"
        echo "    PID: $pid"
        echo "    Memory: $memory"
        echo "    Uptime: $uptime"
        echo "    URL: http://localhost:$port"
    else
        print_error "✗ $service_name"
        echo "    Port: $port (not listening)"
        echo "    PID: $pid"
        echo "    Status: Not running"
    fi
}

# Function to show database status
show_database_status() {
    print_status "Database Status:"
    echo "=================="
    
    if check_database; then
        print_success "✓ PostgreSQL"
        echo "    Host: localhost:5432"
        echo "    Database: scrib"
        echo "    User: scrib_user"
        
        # Get database size
        if command -v psql &> /dev/null; then
            local db_size=$(psql -h localhost -U scrib_user -d scrib -t -c "SELECT pg_size_pretty(pg_database_size('scrib'));" 2>/dev/null | xargs)
            echo "    Size: $db_size"
        fi
    else
        print_error "✗ PostgreSQL"
        echo "    Status: Not accessible"
    fi
}

# Function to show Redis status
show_redis_status() {
    print_status "Redis Status:"
    echo "============="
    
    if check_redis; then
        print_success "✓ Redis"
        echo "    Host: localhost:6379"
        
        # Get Redis info
        if command -v redis-cli &> /dev/null; then
            local redis_version=$(redis-cli info server | grep redis_version | cut -d: -f2 | xargs)
            echo "    Version: $redis_version"
        fi
    else
        print_error "✗ Redis"
        echo "    Status: Not accessible"
    fi
}

# Function to show system resources
show_system_resources() {
    print_status "System Resources:"
    echo "==================="
    
    # CPU usage
    local cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | cut -d% -f1)
    echo "CPU Usage: ${cpu_usage}%"
    
    # Memory usage
    local memory_info=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    local memory_total=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    echo "Memory: $(echo "scale=2; $memory_info * 4096 / 1024 / 1024" | bc) MB free"
    
    # Disk usage
    local disk_usage=$(df -h . | tail -1 | awk '{print $5}')
    echo "Disk Usage: $disk_usage"
}

# Function to show logs
show_logs() {
    local log_dir="$PROJECT_ROOT/logs"
    
    if [ -d "$log_dir" ]; then
        print_status "Recent Logs:"
        echo "============="
        
        for log_file in "$log_dir"/*.log; do
            if [ -f "$log_file" ]; then
                local service_name=$(basename "$log_file" .log)
                echo "--- $service_name ---"
                tail -5 "$log_file" 2>/dev/null || echo "No recent logs"
                echo
            fi
        done
    else
        print_warning "No log directory found"
    fi
}

# Function to show network connections
show_network_connections() {
    print_status "Network Connections:"
    echo "======================"
    
    local ports=(9200 9201 9202 9203 5432 6379)
    
    for port in "${ports[@]}"; do
        local connections=$(lsof -Pi :$port -sTCP:LISTEN 2>/dev/null | wc -l)
        if [ "$connections" -gt 0 ]; then
            print_success "Port $port: $connections connection(s)"
        else
            print_warning "Port $port: No connections"
        fi
    done
}

# Main execution
main() {
    print_status "Scrib Backend Services Status"
    echo "================================="
    echo
    
    # Show service status
    print_status "Microservices Status:"
    echo "======================="
    show_service_status "gateway-service" 9200
    echo
    show_service_status "user-service" 9201
    echo
    show_service_status "note-service" 9202
    echo
    show_service_status "search-service" 9203
    echo
    
    # Show database status
    show_database_status
    echo
    
    # Show Redis status
    show_redis_status
    echo
    
    # Show system resources
    show_system_resources
    echo
    
    # Show network connections
    show_network_connections
    echo
    
    # Show recent logs
    show_logs
}

# Handle script arguments
case "${1:-}" in
    --services)
        print_status "Microservices Status:"
        echo "======================="
        show_service_status "gateway-service" 9200
        show_service_status "user-service" 9201
        show_service_status "note-service" 9202
        show_service_status "search-service" 9203
        ;;
    --database)
        show_database_status
        ;;
    --redis)
        show_redis_status
        ;;
    --logs)
        show_logs
        ;;
    --network)
        show_network_connections
        ;;
    --help)
        echo "Usage: $0 [--services|--database|--redis|--logs|--network|--help]"
        echo "  --services  Show only microservices status"
        echo "  --database  Show only database status"
        echo "  --redis     Show only Redis status"
        echo "  --logs      Show only recent logs"
        echo "  --network   Show only network connections"
        echo "  --help      Show this help message"
        ;;
    *)
        main
        ;;
esac
