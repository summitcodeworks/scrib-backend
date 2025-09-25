#!/bin/bash

# Scrib Backend Complete Startup Script
# This script handles everything from environment setup to service deployment

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
LOG_DIR="$PROJECT_ROOT/logs"
PID_DIR="$PROJECT_ROOT/pids"

# Create necessary directories
mkdir -p "$LOG_DIR"
mkdir -p "$PID_DIR"

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to be ready on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if check_service "$service_name" "$port"; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start within 60 seconds"
    return 1
}

# Function to install Java
install_java() {
    print_status "Installing Java 17..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install openjdk@17
            print_success "Java 17 installed via Homebrew"
        else
            print_error "Homebrew not found. Please install Java 17 manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y openjdk-17-jdk
            print_success "Java 17 installed via apt"
        elif command_exists yum; then
            sudo yum install -y java-17-openjdk-devel
            print_success "Java 17 installed via yum"
        else
            print_error "Package manager not found. Please install Java 17 manually."
            exit 1
        fi
    else
        print_error "Unsupported operating system. Please install Java 17 manually."
        exit 1
    fi
}

# Function to install Maven
install_maven() {
    print_status "Installing Maven..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install maven
            print_success "Maven installed via Homebrew"
        else
            print_error "Homebrew not found. Please install Maven manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists apt-get; then
            sudo apt-get install -y maven
            print_success "Maven installed via apt"
        elif command_exists yum; then
            sudo yum install -y maven
            print_success "Maven installed via yum"
        else
            print_error "Package manager not found. Please install Maven manually."
            exit 1
        fi
    else
        print_error "Unsupported operating system. Please install Maven manually."
        exit 1
    fi
}

# Function to install Docker
install_docker() {
    print_status "Installing Docker..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        print_warning "Please install Docker Desktop for macOS from https://www.docker.com/products/docker-desktop"
        print_status "Or install via Homebrew: brew install --cask docker"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists curl; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            print_success "Docker installed"
            print_warning "Please log out and log back in for Docker group changes to take effect"
        else
            print_error "curl not found. Please install Docker manually."
            exit 1
        fi
    else
        print_error "Unsupported operating system. Please install Docker manually."
        exit 1
    fi
}

# Function to start Redis
start_redis() {
    print_status "Starting Redis..."
    
    # Try to start Redis with Docker if available
    if command_exists docker; then
        docker run -d --name scrib-redis -p 6379:6379 redis:7-alpine
        print_success "Redis started with Docker"
    else
        print_error "Redis is not running and Docker is not available. Please start Redis manually."
        exit 1
    fi
}

# Function to check PostgreSQL connection
check_postgresql() {
    print_status "Checking PostgreSQL connection..."
    
    # Test connection to existing PostgreSQL server
    if command_exists psql; then
        if psql -h ec2-65-1-185-194.ap-south-1.compute.amazonaws.com -p 5432 -U summitcodeworks -d scrib -c "SELECT 1;" &> /dev/null; then
            print_success "PostgreSQL connection successful"
            return 0
        else
            print_error "Cannot connect to PostgreSQL. Please ensure PostgreSQL is running and accessible."
            print_status "Connection details:"
            print_status "  Host: ec2-65-1-185-194.ap-south-1.compute.amazonaws.com"
            print_status "  Port: 5432"
            print_status "  Database: scrib"
            print_status "  User: summitcodeworks"
            exit 1
        fi
    else
        print_error "psql command not found. Please install PostgreSQL client tools."
        exit 1
    fi
}

# Function to setup database schema
setup_database_schema() {
    print_status "Setting up database schema..."
    
    # Run database schema
    if [ -f "$PROJECT_ROOT/database/schema.sql" ]; then
        psql -h ec2-65-1-185-194.ap-south-1.compute.amazonaws.com -p 5432 -U summitcodeworks -d scrib -f "$PROJECT_ROOT/database/schema.sql"
        print_success "Database schema created"
    else
        print_warning "Database schema file not found"
    fi
    
    # Add sample data
    if [ -f "$PROJECT_ROOT/database/sample_data.sql" ]; then
        psql -h ec2-65-1-185-194.ap-south-1.compute.amazonaws.com -p 5432 -U summitcodeworks -d scrib -f "$PROJECT_ROOT/database/sample_data.sql"
        print_success "Sample data added"
    else
        print_warning "Sample data file not found"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check Java
    if ! command_exists java; then
        missing_deps+=("java")
    else
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
        if [ "$java_version" -lt 17 ]; then
            print_warning "Java version $java_version found, but Java 17+ is required"
            missing_deps+=("java")
        fi
    fi
    
    # Check Maven
    if ! command_exists mvn; then
        missing_deps+=("maven")
    fi
    
    # Check Docker
    if ! command_exists docker; then
        missing_deps+=("docker")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    print_success "All prerequisites are met!"
    return 0
}

# Function to install missing dependencies
install_dependencies() {
    print_status "Installing missing dependencies..."
    
    # Install Java if missing
    if ! command_exists java; then
        install_java
    fi
    
    # Install Maven if missing
    if ! command_exists mvn; then
        install_maven
    fi
    
    # Install Docker if missing
    if ! command_exists docker; then
        install_docker
    fi
}

# Function to build all services
build_services() {
    print_status "Building all services..."
    
    cd "$PROJECT_ROOT"
    
    # Clean and build
    mvn clean install -DskipTests
    
    if [ $? -eq 0 ]; then
        print_success "All services built successfully!"
    else
        print_error "Project build failed"
        exit 1
    fi
}

# Function to start a service
start_service() {
    local service_name=$1
    local service_dir=$2
    local port=$3
    local log_file="$LOG_DIR/${service_name}.log"
    local pid_file="$PID_DIR/${service_name}.pid"
    
    print_status "Starting $service_name..."
    
    # Check if service is already running
    if check_service "$service_name" "$port"; then
        print_warning "$service_name is already running on port $port"
        return 0
    fi
    
    # Change to service directory
    cd "$PROJECT_ROOT/$service_dir"
    
    # Start the service
    nohup mvn spring-boot:run > "$log_file" 2>&1 &
    local pid=$!
    echo $pid > "$pid_file"
    
    # Wait for service to be ready
    if wait_for_service "$service_name" "$port"; then
        print_success "$service_name started successfully (PID: $pid)"
    else
        print_error "Failed to start $service_name"
        return 1
    fi
}

# Function to show service status
show_service_status() {
    local service_name=$1
    local port=$2
    
    if check_service "$service_name" "$port"; then
        print_success "✓ $service_name (Port: $port)"
    else
        print_error "✗ $service_name (Port: $port)"
    fi
}

# Function to show environment status
show_environment_status() {
    print_status "Environment Status:"
    echo "===================="
    
    # Check Java
    if command_exists java; then
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        print_success "✓ Java: $java_version"
    else
        print_error "✗ Java: Not installed"
    fi
    
    # Check Maven
    if command_exists mvn; then
        mvn_version=$(mvn -version | head -n1 | cut -d' ' -f3)
        print_success "✓ Maven: $mvn_version"
    else
        print_error "✗ Maven: Not installed"
    fi
    
    # Check Docker
    if command_exists docker; then
        docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_success "✓ Docker: $docker_version"
    else
        print_error "✗ Docker: Not installed"
    fi
    
    # Check PostgreSQL
    if psql -h ec2-65-1-185-194.ap-south-1.compute.amazonaws.com -p 5432 -U summitcodeworks -d scrib -c "SELECT 1;" &> /dev/null; then
        print_success "✓ PostgreSQL: Connected"
    else
        print_error "✗ PostgreSQL: Not accessible"
    fi
    
    # Check Redis
    if docker ps | grep -q scrib-redis; then
        print_success "✓ Redis: Running"
    else
        print_error "✗ Redis: Not running"
    fi
}

# Function to show service URLs
show_service_urls() {
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

# Function to deploy with Docker Compose
deploy_docker_compose() {
    print_status "Deploying with Docker Compose..."
    
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
deploy_kubernetes() {
    print_status "Deploying to Kubernetes..."
    
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

# Function to show help
show_help() {
    echo "Scrib Backend Complete Startup Script"
    echo "===================================="
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --setup-only     Only setup environment (no services)"
    echo "  --build-only     Only build services (no start)"
    echo "  --docker         Deploy with Docker Compose"
    echo "  --k8s            Deploy to Kubernetes"
    echo "  --status         Show environment and service status"
    echo "  --urls           Show service URLs"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Complete setup and start"
    echo "  $0 --setup-only       # Setup environment only"
    echo "  $0 --build-only       # Build services only"
    echo "  $0 --docker           # Deploy with Docker Compose"
    echo "  $0 --k8s              # Deploy to Kubernetes"
    echo "  $0 --status            # Show status"
}

# Main execution
main() {
    local setup_only=false
    local build_only=false
    local docker_deploy=false
    local k8s_deploy=false
    local show_status=false
    local show_urls=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --setup-only)
                setup_only=true
                shift
                ;;
            --build-only)
                build_only=true
                shift
                ;;
            --docker)
                docker_deploy=true
                shift
                ;;
            --k8s)
                k8s_deploy=true
                shift
                ;;
            --status)
                show_status=true
                shift
                ;;
            --urls)
                show_urls=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_header "Scrib Backend Complete Startup"
    echo "================================="
    print_status "Project root: $PROJECT_ROOT"
    echo
    
    # Show status if requested
    if [ "$show_status" = true ]; then
        show_environment_status
        echo
        print_status "Service Status:"
        echo "================"
        show_service_status "gateway-service" 9200
        show_service_status "user-service" 9201
        show_service_status "note-service" 9202
        show_service_status "search-service" 9203
        exit 0
    fi
    
    # Show URLs if requested
    if [ "$show_urls" = true ]; then
        show_service_urls
        exit 0
    fi
    
    # Check prerequisites
    if ! check_prerequisites; then
        print_status "Installing missing dependencies..."
        install_dependencies
    fi
    
    # Setup PostgreSQL
    check_postgresql
    
    # Setup Redis
    start_redis
    
    # Setup database schema
    setup_database_schema
    
    # Build services
    build_services
    
    # Exit if build-only
    if [ "$build_only" = true ]; then
        print_success "Build completed successfully!"
        exit 0
    fi
    
    # Exit if setup-only
    if [ "$setup_only" = true ]; then
        print_success "Environment setup completed!"
        exit 0
    fi
    
    # Deploy with Docker Compose if requested
    if [ "$docker_deploy" = true ]; then
        deploy_docker_compose
        exit 0
    fi
    
    # Deploy to Kubernetes if requested
    if [ "$k8s_deploy" = true ]; then
        deploy_kubernetes
        exit 0
    fi
    
    # Start services in order
    print_status "Starting microservices..."
    
    # Start User Service
    start_service "user-service" "user-service" 9201
    
    # Start Note Service
    start_service "note-service" "note-service" 9202
    
    # Start Search Service
    start_service "search-service" "search-service" 9203
    
    # Start Gateway Service
    start_service "gateway-service" "gateway-service" 9200
    
    # Final status check
    print_status "Checking all services..."
    
    local all_services_ready=true
    
    if check_service "user-service" 9201; then
        print_success "✓ User Service (9201)"
    else
        print_error "✗ User Service (9201)"
        all_services_ready=false
    fi
    
    if check_service "note-service" 9202; then
        print_success "✓ Note Service (9202)"
    else
        print_error "✗ Note Service (9202)"
        all_services_ready=false
    fi
    
    if check_service "search-service" 9203; then
        print_success "✓ Search Service (9203)"
    else
        print_error "✗ Search Service (9203)"
        all_services_ready=false
    fi
    
    if check_service "gateway-service" 9200; then
        print_success "✓ Gateway Service (9200)"
    else
        print_error "✗ Gateway Service (9200)"
        all_services_ready=false
    fi
    
    if [ "$all_services_ready" = true ]; then
        print_success "All Scrib Backend services are running!"
        echo
        show_service_urls
        echo
        print_status "Logs: $LOG_DIR"
        print_status "PIDs: $PID_DIR"
    else
        print_error "Some services failed to start. Check logs in $LOG_DIR"
        exit 1
    fi
}

# Run main function
main "$@"