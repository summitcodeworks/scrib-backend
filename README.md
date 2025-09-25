# Scrib Backend

A comprehensive note-taking application backend built with Spring Boot microservices architecture, supporting rich text formatting, code snippets, and real-time saving functionality.

## 🚀 Features

- **User Management**: Simple username-based authentication
- **Note Management**: Create, edit, delete notes with rich text and code formatting
- **Real-time Saving**: WebSocket-based auto-save functionality
- **Search & Filtering**: Advanced search capabilities with language filtering
- **Public Notes**: Unauthenticated access to public notes
- **Microservices Architecture**: Scalable and maintainable design
- **High Performance**: Redis caching and optimized database queries
- **Security**: Input validation, rate limiting, and data sanitization

## 🏗️ Architecture

### Microservices

1. **User Service** (Port 8081)
   - User creation and validation
   - Username uniqueness checks
   - User activity tracking

2. **Note Service** (Port 8082)
   - Note CRUD operations
   - Rich text and code formatting
   - WebSocket real-time saving
   - Redis caching

3. **Search Service** (Port 8083)
   - Advanced search and filtering
   - Full-text search capabilities
   - Language-based filtering
   - Cached search results

4. **Gateway Service** (Port 8080)
   - API routing and load balancing
   - Rate limiting
   - Cross-origin resource sharing

### Technology Stack

- **Backend**: Spring Boot 3.2.0, Java 17
- **Database**: PostgreSQL 15
- **Caching**: Redis 7
- **Message Broker**: WebSocket (STOMP)
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **Monitoring**: Prometheus, Grafana
- **Logging**: ELK Stack (Elasticsearch, Logstash, Kibana)

## 📋 Prerequisites

- Java 17+
- Maven 3.8+
- Docker & Docker Compose
- PostgreSQL 15
- Redis 7

## 🚀 Quick Start

### Using Docker Compose

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd scrib-backend
   ```

2. **Start all services**
   ```bash
   docker-compose up -d
   ```

3. **Access the application**
   - API Gateway: http://localhost:9200
   - User Service: http://localhost:9201
   - Note Service: http://localhost:9202
   - Search Service: http://localhost:9203

### Manual Setup

1. **Start PostgreSQL and Redis**
   ```bash
   # PostgreSQL
   docker run -d --name postgres -e POSTGRES_DB=scrib_db -e POSTGRES_USER=scrib_user -e POSTGRES_PASSWORD=scrib_password -p 5432:5432 postgres:15
   
   # Redis
   docker run -d --name redis -p 6379:6379 redis:7-alpine
   ```

2. **Build and run services**
   ```bash
   # Build all modules
   mvn clean install
   
   # Run User Service
   cd user-service && mvn spring-boot:run
   
   # Run Note Service (in another terminal)
   cd note-service && mvn spring-boot:run
   
   # Run Search Service (in another terminal)
   cd search-service && mvn spring-boot:run
   
   # Run Gateway Service (in another terminal)
   cd gateway-service && mvn spring-boot:run
   ```

## 📚 API Documentation

### User Service Endpoints

- `POST /api/users` - Create a new user
- `GET /api/users/{username}/exists` - Check if username exists
- `GET /api/users/{username}` - Get user by username
- `PUT /api/users/{username}/activity` - Update last activity

### Note Service Endpoints

- `POST /api/notes` - Create a new note
- `PUT /api/notes/{id}` - Update a note
- `DELETE /api/notes/{id}` - Delete a note
- `GET /api/notes/{id}` - Get a note by ID
- `GET /api/notes` - List notes with filtering
- `GET /api/notes/search` - Search notes
- `GET /api/notes/languages` - Get available code languages

### WebSocket Endpoints

- `/ws` - WebSocket connection endpoint
- `/app/note.save` - Save note changes
- `/app/note.auto-save` - Auto-save note changes
- `/topic/note.saved` - Note saved confirmation
- `/queue/note.saved` - User-specific note saved notification

### Search Service Endpoints

- `GET /api/search/notes` - Search notes
- `GET /api/search/notes/user/{userId}` - Search user notes
- `GET /api/search/notes/public` - Get public notes
- `GET /api/search/notes/user/{userId}/all` - Get all user notes
- `GET /api/search/notes/language/{language}` - Get notes by language
- `GET /api/search/languages` - Get available languages

## 🗄️ Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL,
    last_activity_at TIMESTAMP
);
```

### Notes Table
```sql
CREATE TABLE notes (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    title VARCHAR(255),
    content TEXT,
    visibility ENUM('PUBLIC', 'PRIVATE') NOT NULL,
    code_language VARCHAR(50),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP
);
```

## 🔧 Configuration

### Environment Variables

- `SPRING_DATASOURCE_URL`: Database connection URL
- `SPRING_DATASOURCE_USERNAME`: Database username
- `SPRING_DATASOURCE_PASSWORD`: Database password
- `SPRING_REDIS_HOST`: Redis host
- `SPRING_REDIS_PORT`: Redis port

### Application Properties

Each service has its own `application.yml` file with specific configurations for:
- Server ports
- Database connections
- Redis settings
- Logging levels
- Cache configurations

## 🚀 Deployment

### Kubernetes Deployment

1. **Create namespace**
   ```bash
   kubectl apply -f k8s/namespace.yaml
   ```

2. **Deploy database and cache**
   ```bash
   kubectl apply -f k8s/postgres-deployment.yaml
   kubectl apply -f k8s/redis-deployment.yaml
   ```

3. **Deploy microservices**
   ```bash
   kubectl apply -f k8s/user-service-deployment.yaml
   kubectl apply -f k8s/note-service-deployment.yaml
   kubectl apply -f k8s/search-service-deployment.yaml
   kubectl apply -f k8s/gateway-service-deployment.yaml
   ```

### Docker Deployment

1. **Build Docker images**
   ```bash
   docker build -t scrib/user-service:latest user-service/
   docker build -t scrib/note-service:latest note-service/
   docker build -t scrib/search-service:latest search-service/
   docker build -t scrib/gateway-service:latest gateway-service/
   ```

2. **Deploy with Docker Compose**
   ```bash
   docker-compose up -d
   ```

## 📊 Monitoring

### Prometheus Metrics

- HTTP request metrics
- JVM memory usage
- Database connection metrics
- Cache hit/miss ratios
- WebSocket connection metrics

### Grafana Dashboards

- Service health monitoring
- Performance metrics
- Error rate tracking
- Resource utilization

## 🔒 Security

- Input validation and sanitization
- Rate limiting (100 requests/minute per IP)
- SQL injection prevention
- XSS protection
- CORS configuration
- Data encryption at rest

## 🧪 Testing

### Unit Tests
```bash
mvn test
```

### Integration Tests
```bash
mvn verify
```

### Load Testing
```bash
# Using Apache Bench
ab -n 1000 -c 10 http://localhost:9200/api/notes
```

## 📈 Performance

- **Target**: 10,000 concurrent users
- **Response Time**: <500ms for API calls
- **Real-time Saving**: <100ms for WebSocket updates
- **Availability**: 99.9% uptime target
- **Scalability**: Horizontal scaling support

## 🔄 Real-time Features

### WebSocket Implementation

- **Connection**: `/ws` endpoint with SockJS support
- **Auto-save**: Debounced saving every 500ms
- **Live Updates**: Real-time note synchronization
- **Error Handling**: Graceful error recovery

### Supported Code Languages

- Python, Java, JavaScript, C++, SQL
- HTML, CSS, TypeScript, Go, Rust
- And many more with syntax highlighting

## 🛠️ Development

### Project Structure
```
scrib-backend/
├── common/                 # Shared DTOs and utilities
├── user-service/          # User management service
├── note-service/          # Note management with WebSocket
├── search-service/        # Search and filtering service
├── gateway-service/       # API Gateway
├── k8s/                   # Kubernetes configurations
├── monitoring/            # Prometheus and Grafana configs
└── docker-compose.yml     # Local development setup
```

### Code Quality

- **Linting**: Checkstyle, SpotBugs
- **Testing**: JUnit 5, TestContainers
- **Documentation**: OpenAPI/Swagger
- **Code Coverage**: JaCoCo

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📞 Support

For support and questions, please open an issue in the repository or contact the development team.

---

**Scrib Backend** - Enterprise-grade note-taking application with real-time collaboration and rich formatting support.
