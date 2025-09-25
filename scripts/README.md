# Scrib Backend Scripts

This directory contains all the shell scripts for managing the Scrib Backend application.

## Scripts Overview

### Master Control Script
- **`scrib.sh`** - Master control script for all operations

### Service Management
- **`start-services.sh`** - Start all Scrib Backend services
- **`stop-services.sh`** - Stop all Scrib Backend services
- **`restart-services.sh`** - Restart all Scrib Backend services
- **`status-services.sh`** - Show status of all services

### Environment Setup
- **`setup-environment.sh`** - Set up complete development environment
- **`build.sh`** - Build all services
- **`deploy.sh`** - Deploy services to Kubernetes

### Maintenance
- **`cleanup.sh`** - Clean up all services and resources

## Quick Start

### Using the Master Script (Recommended)

```bash
# Set up the complete environment
./scripts/scrib.sh setup

# Start all services
./scripts/scrib.sh start

# Check status
./scripts/scrib.sh status

# View logs
./scripts/scrib.sh logs

# Stop all services
./scripts/scrib.sh stop

# Clean up everything
./scripts/scrib.sh clean
```

### Using Individual Scripts

```bash
# Set up environment
./scripts/setup-environment.sh

# Start services
./scripts/start-services.sh

# Check status
./scripts/status-services.sh

# Stop services
./scripts/stop-services.sh

# Clean up
./scripts/cleanup.sh
```

## Script Details

### 1. `scrib.sh` - Master Control Script

The main script that provides a unified interface for all operations.

**Usage:**
```bash
./scripts/scrib.sh <command> [options]
```

**Commands:**
- `setup` - Set up the complete development environment
- `start` - Start all Scrib Backend services
- `stop` - Stop all Scrib Backend services
- `restart` - Restart all Scrib Backend services
- `status` - Show status of all services
- `logs` - Show logs for all services
- `clean` - Clean up all services and resources
- `build` - Build all services
- `test` - Run tests for all services
- `deploy` - Deploy services using Docker Compose
- `k8s` - Deploy services to Kubernetes
- `urls` - Show service URLs
- `quick-start` - Show quick start guide

**Options:**
- `--help` - Show help message
- `--force` - Force operation without confirmation
- `--verbose` - Show detailed output

### 2. `start-services.sh` - Start Services

Starts all Scrib Backend microservices in the correct order.

**Features:**
- Checks prerequisites (Java, Maven, PostgreSQL, Redis)
- Builds all services
- Sets up database schema
- Starts services in order: User → Note → Search → Gateway
- Waits for each service to be ready
- Provides status feedback

**Usage:**
```bash
./scripts/start-services.sh
```

### 3. `stop-services.sh` - Stop Services

Stops all Scrib Backend microservices gracefully.

**Features:**
- Stops services in reverse order
- Graceful shutdown with timeout
- Force kill if necessary
- Cleans up PID files
- Shows final status

**Usage:**
```bash
./scripts/stop-services.sh [--force|--status|--help]
```

**Options:**
- `--force` - Force stop all services
- `--status` - Show service status
- `--help` - Show help message

### 4. `setup-environment.sh` - Environment Setup

Sets up the complete development environment.

**Features:**
- Checks and installs prerequisites (Java, Maven, Docker)
- Sets up PostgreSQL with Docker
- Sets up Redis with Docker
- Creates database schema
- Adds sample data
- Builds the project

**Usage:**
```bash
./scripts/setup-environment.sh [--status|--help]
```

**Options:**
- `--status` - Show environment status
- `--help` - Show help message

### 5. `status-services.sh` - Service Status

Shows comprehensive status of all services and resources.

**Features:**
- Service status (running/stopped)
- Process information (PID, memory, uptime)
- Database status
- Redis status
- System resources
- Network connections
- Recent logs

**Usage:**
```bash
./scripts/status-services.sh [--services|--database|--redis|--logs|--network|--help]
```

**Options:**
- `--services` - Show only microservices status
- `--database` - Show only database status
- `--redis` - Show only Redis status
- `--logs` - Show only recent logs
- `--network` - Show only network connections
- `--help` - Show help message

### 6. `cleanup.sh` - Cleanup

Cleans up all services and resources.

**Features:**
- Stops all services
- Removes log files
- Removes PID files
- Cleans up Docker resources
- Removes temporary files
- Resets database (optional)

**Usage:**
```bash
./scripts/cleanup.sh [--services|--docker|--database|--redis|--files|--logs|--reset-db|--force|--help]
```

**Options:**
- `--services` - Stop all services only
- `--docker` - Clean up Docker resources only
- `--database` - Clean up database only
- `--redis` - Clean up Redis only
- `--files` - Clean up files only
- `--logs` - Clean up logs only
- `--reset-db` - Reset database completely
- `--force` - Force cleanup without confirmation
- `--help` - Show help message

## Service URLs

When all services are running, they are available at:

- **Gateway Service**: http://localhost:9200
- **User Service**: http://localhost:9201
- **Note Service**: http://localhost:9202
- **Search Service**: http://localhost:9203
- **WebSocket**: ws://localhost:9200/ws
- **Database**: localhost:5432/scrib
- **Redis**: localhost:6379

## Prerequisites

### Required Software
- **Java 17+** - For running Spring Boot applications
- **Maven 3.8+** - For building the project
- **Docker** - For PostgreSQL and Redis
- **PostgreSQL** - Database (can be run with Docker)
- **Redis** - Caching (can be run with Docker)

### Optional Software
- **Kubernetes** - For production deployment
- **kubectl** - For Kubernetes management

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using the port
   lsof -i :9200
   
   # Kill the process
   kill -9 <PID>
   ```

2. **Database Connection Issues**
   ```bash
   # Check PostgreSQL status
   docker ps | grep postgres
   
   # Restart PostgreSQL
   docker restart scrib-postgres
   ```

3. **Service Won't Start**
   ```bash
   # Check logs
   ./scripts/scrib.sh logs
   
   # Check status
   ./scripts/scrib.sh status
   ```

4. **Build Issues**
   ```bash
   # Clean and rebuild
   mvn clean install -DskipTests
   ```

### Log Files

Log files are stored in the `logs/` directory:
- `user-service.log`
- `note-service.log`
- `search-service.log`
- `gateway-service.log`

### PID Files

PID files are stored in the `pids/` directory for process management.

## Development Workflow

### Daily Development
```bash
# Start your day
./scripts/scrib.sh setup
./scripts/scrib.sh start

# Check status
./scripts/scrib.sh status

# View logs
./scripts/scrib.sh logs

# Stop when done
./scripts/scrib.sh stop
```

### Testing
```bash
# Run tests
./scripts/scrib.sh test

# Check specific service
./scripts/status-services.sh --services
```

### Deployment
```bash
# Deploy with Docker Compose
./scripts/scrib.sh deploy

# Deploy to Kubernetes
./scripts/scrib.sh k8s
```

### Cleanup
```bash
# Clean up everything
./scripts/scrib.sh clean

# Force cleanup
./scripts/scrib.sh clean --force
```

## Best Practices

1. **Always use the master script** (`scrib.sh`) for common operations
2. **Check status** before starting services
3. **View logs** when troubleshooting
4. **Clean up** regularly to avoid resource issues
5. **Use Docker** for database and Redis to avoid conflicts
6. **Check prerequisites** before setup

## Support

For issues or questions:
1. Check the logs: `./scripts/scrib.sh logs`
2. Check status: `./scripts/scrib.sh status`
3. Clean up and restart: `./scripts/scrib.sh clean && ./scripts/scrib.sh setup`
4. Check the main README.md for more information
