#!/bin/bash

# Scrib Backend Environment Setup Script
# This script sets up the complete development environment

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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

# Function to setup PostgreSQL
setup_postgresql() {
    print_status "Setting up PostgreSQL..."
    
    if command_exists docker; then
        # Start PostgreSQL with Docker
        docker run -d \
            --name scrib-postgres \
            -e POSTGRES_DB=scrib \
            -e POSTGRES_USER=scrib_user \
            -e POSTGRES_PASSWORD=scrib_password \
            -p 5432:5432 \
            postgres:15
        
        # Wait for PostgreSQL to be ready
        print_status "Waiting for PostgreSQL to be ready..."
        sleep 10
        
        # Test connection
        if docker exec scrib-postgres psql -U scrib_user -d scrib -c "SELECT 1;" &> /dev/null; then
            print_success "PostgreSQL is ready"
        else
            print_error "PostgreSQL failed to start"
            exit 1
        fi
    else
        print_error "Docker not found. Please install Docker or PostgreSQL manually."
        exit 1
    fi
}

# Function to setup Redis
setup_redis() {
    print_status "Setting up Redis..."
    
    if command_exists docker; then
        # Start Redis with Docker
        docker run -d \
            --name scrib-redis \
            -p 6379:6379 \
            redis:7-alpine
        
        # Wait for Redis to be ready
        print_status "Waiting for Redis to be ready..."
        sleep 5
        
        # Test connection
        if docker exec scrib-redis redis-cli ping | grep -q "PONG"; then
            print_success "Redis is ready"
        else
            print_error "Redis failed to start"
            exit 1
        fi
    else
        print_error "Docker not found. Please install Docker or Redis manually."
        exit 1
    fi
}

# Function to setup database schema
setup_database_schema() {
    print_status "Setting up database schema..."
    
    # Wait for PostgreSQL to be ready
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec scrib-postgres psql -U scrib_user -d scrib -c "SELECT 1;" &> /dev/null; then
            break
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "PostgreSQL is not ready after 60 seconds"
        exit 1
    fi
    
    # Run database schema
    if [ -f "$PROJECT_ROOT/database/schema.sql" ]; then
        docker exec -i scrib-postgres psql -U scrib_user -d scrib < "$PROJECT_ROOT/database/schema.sql"
        print_success "Database schema created"
    else
        print_warning "Database schema file not found"
    fi
    
    # Add sample data
    if [ -f "$PROJECT_ROOT/database/sample_data.sql" ]; then
        docker exec -i scrib-postgres psql -U scrib_user -d scrib < "$PROJECT_ROOT/database/sample_data.sql"
        print_success "Sample data added"
    else
        print_warning "Sample data file not found"
    fi
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p "$LOG_DIR"
    mkdir -p "$PID_DIR"
    mkdir -p "$PROJECT_ROOT/tmp"
    
    print_success "Directories created"
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
    
    print_success "All prerequisites are available"
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

# Function to build project
build_project() {
    print_status "Building Scrib Backend project..."
    
    cd "$PROJECT_ROOT"
    
    # Clean and build
    mvn clean install -DskipTests
    
    if [ $? -eq 0 ]; then
        print_success "Project built successfully"
    else
        print_error "Project build failed"
        exit 1
    fi
}

# Function to show environment status
show_status() {
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
    if docker ps | grep -q scrib-postgres; then
        print_success "✓ PostgreSQL: Running"
    else
        print_error "✗ PostgreSQL: Not running"
    fi
    
    # Check Redis
    if docker ps | grep -q scrib-redis; then
        print_success "✓ Redis: Running"
    else
        print_error "✗ Redis: Not running"
    fi
}

# Main execution
main() {
    print_status "Setting up Scrib Backend Environment..."
    print_status "Project root: $PROJECT_ROOT"
    
    # Create directories
    create_directories
    
    # Check prerequisites
    if ! check_prerequisites; then
        print_status "Installing missing dependencies..."
        install_dependencies
    fi
    
    # Setup PostgreSQL
    setup_postgresql
    
    # Setup Redis
    setup_redis
    
    # Setup database schema
    setup_database_schema
    
    # Build project
    build_project
    
    # Show final status
    show_status
    
    print_success "Environment setup completed!"
    print_status "You can now start the services with: ./scripts/start-services.sh"
}

# Handle script arguments
case "${1:-}" in
    --status)
        show_status
        ;;
    --help)
        echo "Usage: $0 [--status|--help]"
        echo "  --status  Show environment status"
        echo "  --help    Show this help message"
        ;;
    *)
        main
        ;;
esac
