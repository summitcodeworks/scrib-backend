#!/bin/bash

# Scrib Backend Master Control Script
# This script provides a unified interface for managing Scrib Backend services

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

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

print_header() {
    echo -e "${PURPLE}[SCRIB]${NC} $1"
}

# Function to show help
show_help() {
    echo "Scrib Backend Master Control Script"
    echo "=================================="
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  setup       Set up the complete development environment"
    echo "  start       Start all Scrib Backend services"
    echo "  stop        Stop all Scrib Backend services"
    echo "  restart     Restart all Scrib Backend services"
    echo "  status      Show status of all services"
    echo "  logs        Show logs for all services"
    echo "  clean       Clean up all services and resources"
    echo "  build       Build all services"
    echo "  test        Run tests for all services"
    echo "  deploy      Deploy services using Docker Compose"
    echo "  k8s         Deploy services to Kubernetes"
    echo
    echo "Options:"
    echo "  --help      Show this help message"
    echo "  --force     Force operation without confirmation"
    echo "  --verbose   Show detailed output"
    echo
    echo "Examples:"
    echo "  $0 setup                    # Set up development environment"
    echo "  $0 start                    # Start all services"
    echo "  $0 status --verbose         # Show detailed status"
    echo "  $0 clean --force            # Force cleanup without confirmation"
}

# Function to setup environment
setup_environment() {
    print_header "Setting up Scrib Backend environment..."
    "$SCRIPTS_DIR/setup-environment.sh"
}

# Function to start services
start_services() {
    print_header "Starting Scrib Backend services..."
    "$SCRIPTS_DIR/start-services.sh"
}

# Function to stop services
stop_services() {
    print_header "Stopping Scrib Backend services..."
    "$SCRIPTS_DIR/stop-services.sh"
}

# Function to restart services
restart_services() {
    print_header "Restarting Scrib Backend services..."
    "$SCRIPTS_DIR/restart-services.sh"
}

# Function to show status
show_status() {
    print_header "Scrib Backend services status..."
    "$SCRIPTS_DIR/status-services.sh"
}

# Function to show logs
show_logs() {
    print_header "Scrib Backend services logs..."
    local log_dir="$PROJECT_ROOT/logs"
    
    if [ -d "$log_dir" ]; then
        for log_file in "$log_dir"/*.log; do
            if [ -f "$log_file" ]; then
                local service_name=$(basename "$log_file" .log)
                echo "--- $service_name ---"
                tail -20 "$log_file" 2>/dev/null || echo "No logs available"
                echo
            fi
        done
    else
        print_warning "No log directory found"
    fi
}

# Function to clean up
clean_up() {
    print_header "Cleaning up Scrib Backend..."
    "$SCRIPTS_DIR/cleanup.sh"
}

# Function to build services
build_services() {
    print_header "Building Scrib Backend services..."
    
    cd "$PROJECT_ROOT"
    mvn clean install -DskipTests
    
    if [ $? -eq 0 ]; then
        print_success "All services built successfully!"
    else
        print_error "Build failed!"
        exit 1
    fi
}

# Function to run tests
run_tests() {
    print_header "Running tests for Scrib Backend services..."
    
    cd "$PROJECT_ROOT"
    mvn test
    
    if [ $? -eq 0 ]; then
        print_success "All tests passed!"
    else
        print_error "Some tests failed!"
        exit 1
    fi
}

# Function to deploy with Docker Compose
deploy_docker() {
    print_header "Deploying Scrib Backend with Docker Compose..."
    
    cd "$PROJECT_ROOT"
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        print_success "Services deployed with Docker Compose!"
    else
        print_error "Docker Compose deployment failed!"
        exit 1
    fi
}

# Function to deploy to Kubernetes
deploy_k8s() {
    print_header "Deploying Scrib Backend to Kubernetes..."
    
    cd "$PROJECT_ROOT"
    
    # Apply namespace
    kubectl apply -f k8s/namespace.yaml
    
    # Deploy database and cache
    kubectl apply -f k8s/postgres-deployment.yaml
    kubectl apply -f k8s/redis-deployment.yaml
    
    # Wait for database to be ready
    kubectl wait --for=condition=ready pod -l app=postgres -n scrib-backend --timeout=300s
    
    # Deploy microservices
    kubectl apply -f k8s/user-service-deployment.yaml
    kubectl apply -f k8s/note-service-deployment.yaml
    kubectl apply -f k8s/search-service-deployment.yaml
    kubectl apply -f k8s/gateway-service-deployment.yaml
    
    if [ $? -eq 0 ]; then
        print_success "Services deployed to Kubernetes!"
    else
        print_error "Kubernetes deployment failed!"
        exit 1
    fi
}

# Function to show service URLs
show_urls() {
    print_header "Scrib Backend Service URLs:"
    echo "================================"
    echo "Gateway Service:    http://localhost:9200"
    echo "User Service:       http://localhost:9201"
    echo "Note Service:       http://localhost:9202"
    echo "Search Service:     http://localhost:9203"
    echo
    echo "WebSocket:          ws://localhost:9200/ws"
    echo "API Documentation:  http://localhost:9200/api-docs"
    echo
    echo "Database:           localhost:5432/scrib"
    echo "Redis:              localhost:6379"
}

# Function to show quick start guide
show_quick_start() {
    print_header "Scrib Backend Quick Start Guide:"
    echo "====================================="
    echo
    echo "1. Setup environment:"
    echo "   $0 setup"
    echo
    echo "2. Start services:"
    echo "   $0 start"
    echo
    echo "3. Check status:"
    echo "   $0 status"
    echo
    echo "4. View logs:"
    echo "   $0 logs"
    echo
    echo "5. Stop services:"
    echo "   $0 stop"
    echo
    echo "6. Clean up:"
    echo "   $0 clean"
    echo
    echo "For more information, run: $0 --help"
}

# Main execution
main() {
    local command="${1:-}"
    local option="${2:-}"
    
    case "$command" in
        setup)
            setup_environment
            ;;
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        clean)
            if [ "$option" = "--force" ]; then
                clean_up --force
            else
                clean_up
            fi
            ;;
        build)
            build_services
            ;;
        test)
            run_tests
            ;;
        deploy)
            deploy_docker
            ;;
        k8s)
            deploy_k8s
            ;;
        urls)
            show_urls
            ;;
        quick-start)
            show_quick_start
            ;;
        --help|help)
            show_help
            ;;
        "")
            print_header "Scrib Backend Master Control"
            echo "============================="
            echo
            show_quick_start
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
