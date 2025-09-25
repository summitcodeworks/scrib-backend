#!/bin/bash

# Scrib Backend Deployment Script

echo "🚀 Deploying Scrib Backend to Kubernetes..."

# Create namespace
echo "📁 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Deploy database and cache
echo "🗄️ Deploying PostgreSQL..."
kubectl apply -f k8s/postgres-deployment.yaml

echo "🔴 Deploying Redis..."
kubectl apply -f k8s/redis-deployment.yaml

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n scrib-backend --timeout=300s

# Deploy microservices
echo "👤 Deploying User Service..."
kubectl apply -f k8s/user-service-deployment.yaml

echo "📝 Deploying Note Service..."
kubectl apply -f k8s/note-service-deployment.yaml

echo "🔍 Deploying Search Service..."
kubectl apply -f k8s/search-service-deployment.yaml

echo "🌐 Deploying Gateway Service..."
kubectl apply -f k8s/gateway-service-deployment.yaml

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
kubectl wait --for=condition=ready pod -l app=gateway-service -n scrib-backend --timeout=300s

echo "✅ Deployment completed successfully!"
echo "🌐 Services are available at:"
kubectl get services -n scrib-backend

echo "📊 To check pod status:"
echo "kubectl get pods -n scrib-backend"

echo "🔍 To view logs:"
echo "kubectl logs -f deployment/gateway-service -n scrib-backend"
