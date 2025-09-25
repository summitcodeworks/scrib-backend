#!/bin/bash

# Scrib Backend Services Restart Script
# This script restarts all Scrib Backend microservices

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

# Main execution
main() {
    print_status "Restarting Scrib Backend Services..."
    
    # Stop all services
    print_status "Stopping all services..."
    "$PROJECT_ROOT/scripts/stop-services.sh"
    
    # Wait a moment
    sleep 3
    
    # Start all services
    print_status "Starting all services..."
    "$PROJECT_ROOT/scripts/start-services.sh"
    
    print_success "Services restarted successfully!"
}

# Run main function
main "$@"
