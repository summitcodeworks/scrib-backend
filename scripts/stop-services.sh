#!/bin/bash

# Scrib Backend Services Shutdown Script
# This script stops all Scrib Backend microservices

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

# Function to stop a service by PID
stop_service_by_pid() {
    local service_name=$1
    local pid_file="$PID_DIR/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            print_status "Stopping $service_name (PID: $pid)..."
            kill "$pid"
            
            # Wait for graceful shutdown
            local count=0
            while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            
            # Force kill if still running
            if ps -p "$pid" > /dev/null 2>&1; then
                print_warning "Force killing $service_name..."
                kill -9 "$pid" 2>/dev/null || true
            fi
            
            print_success "$service_name stopped"
        else
            print_warning "$service_name was not running"
        fi
        
        # Remove PID file
        rm -f "$pid_file"
    else
        print_warning "No PID file found for $service_name"
    fi
}

# Function to stop a service by port
stop_service_by_port() {
    local service_name=$1
    local port=$2
    
    if check_service "$service_name" "$port"; then
        print_status "Stopping $service_name on port $port..."
        
        # Find and kill processes using the port
        local pids=$(lsof -Pi :$port -sTCP:LISTEN -t 2>/dev/null)
        if [ -n "$pids" ]; then
            echo "$pids" | xargs kill 2>/dev/null || true
            
            # Wait for graceful shutdown
            sleep 2
            
            # Force kill if still running
            local remaining_pids=$(lsof -Pi :$port -sTCP:LISTEN -t 2>/dev/null)
            if [ -n "$remaining_pids" ]; then
                print_warning "Force killing remaining processes on port $port..."
                echo "$remaining_pids" | xargs kill -9 2>/dev/null || true
            fi
            
            print_success "$service_name stopped"
        else
            print_warning "No processes found on port $port"
        fi
    else
        print_warning "$service_name is not running on port $port"
    fi
}

# Function to stop Redis
stop_redis() {
    print_status "Stopping Redis..."
    
    # Try to stop Redis Docker container
    if command -v docker &> /dev/null; then
        if docker ps -q -f name=scrib-redis | grep -q .; then
            docker stop scrib-redis
            docker rm scrib-redis
            print_success "Redis Docker container stopped"
        else
            print_warning "Redis Docker container not found"
        fi
    fi
    
    # Stop Redis if running on port 6379
    if check_service "Redis" 6379; then
        local redis_pids=$(lsof -Pi :6379 -sTCP:LISTEN -t 2>/dev/null)
        if [ -n "$redis_pids" ]; then
            echo "$redis_pids" | xargs kill 2>/dev/null || true
            print_success "Redis stopped"
        fi
    else
        print_warning "Redis is not running"
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Remove PID files
    if [ -d "$PID_DIR" ]; then
        rm -f "$PID_DIR"/*.pid
        print_success "PID files cleaned up"
    fi
    
    # Clean up any remaining processes
    local services=("user-service:9201" "note-service:9202" "search-service:9203" "gateway-service:9200")
    
    for service in "${services[@]}"; do
        local service_name=$(echo "$service" | cut -d':' -f1)
        local port=$(echo "$service" | cut -d':' -f2)
        
        if check_service "$service_name" "$port"; then
            print_warning "Found remaining $service_name process, stopping..."
            stop_service_by_port "$service_name" "$port"
        fi
    done
}

# Function to show status
show_status() {
    print_status "Checking service status..."
    
    local services=("user-service:9201" "note-service:9202" "search-service:9203" "gateway-service:9200")
    local all_stopped=true
    
    for service in "${services[@]}"; do
        local service_name=$(echo "$service" | cut -d':' -f1)
        local port=$(echo "$service" | cut -d':' -f2)
        
        if check_service "$service_name" "$port"; then
            print_warning "✗ $service_name is still running on port $port"
            all_stopped=false
        else
            print_success "✓ $service_name is stopped"
        fi
    done
    
    if [ "$all_stopped" = true ]; then
        print_success "All Scrib Backend services are stopped!"
    else
        print_warning "Some services are still running. You may need to force stop them."
    fi
}

# Main execution
main() {
    print_status "Stopping Scrib Backend Services..."
    
    # Stop services in reverse order
    print_status "Stopping microservices..."
    
    # Stop Gateway Service first
    stop_service_by_pid "gateway-service"
    stop_service_by_port "gateway-service" 9200
    
    # Stop Search Service
    stop_service_by_pid "search-service"
    stop_service_by_port "search-service" 9203
    
    # Stop Note Service
    stop_service_by_pid "note-service"
    stop_service_by_port "note-service" 9202
    
    # Stop User Service
    stop_service_by_pid "user-service"
    stop_service_by_port "user-service" 9201
    
    # Stop Redis
    stop_redis
    
    # Cleanup
    cleanup
    
    # Show final status
    show_status
}

# Handle script arguments
case "${1:-}" in
    --force)
        print_warning "Force stopping all services..."
        # Kill all Java processes (be careful with this!)
        pkill -f "spring-boot:run" 2>/dev/null || true
        pkill -f "scrib" 2>/dev/null || true
        cleanup
        show_status
        ;;
    --status)
        show_status
        ;;
    --help)
        echo "Usage: $0 [--force|--status|--help]"
        echo "  --force   Force stop all services"
        echo "  --status  Show service status"
        echo "  --help    Show this help message"
        ;;
    *)
        main
        ;;
esac
