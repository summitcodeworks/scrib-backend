#!/bin/bash

# Scrib Backend Build Script

echo "🚀 Building Scrib Backend Services..."

# Build all modules
echo "📦 Building all modules..."
mvn clean install -DskipTests

# Build Docker images
echo "🐳 Building Docker images..."

# User Service
echo "Building user-service..."
docker build -t scrib/user-service:latest user-service/

# Note Service
echo "Building note-service..."
docker build -t scrib/note-service:latest note-service/

# Search Service
echo "Building search-service..."
docker build -t scrib/search-service:latest search-service/

# Gateway Service
echo "Building gateway-service..."
docker build -t scrib/gateway-service:latest gateway-service/

echo "✅ Build completed successfully!"
echo "📋 Available Docker images:"
docker images | grep scrib
