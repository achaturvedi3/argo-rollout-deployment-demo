#!/bin/bash

# Local Testing Script for Argo Rollout Demo
# This script helps you test the Docker image locally before deploying

set -e

echo "=================================="
echo "Argo Rollout Demo - Local Testing"
echo "=================================="
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."
if ! command_exists docker; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi
echo "✅ Docker found"

# Set version
VERSION=${1:-v1.0.local}
echo ""
echo "Building Docker image with version: $VERSION"

# Build Docker image
echo ""
echo "Step 1: Building Docker image..."
docker build --build-arg VERSION=$VERSION -t nginx-rollout-demo:$VERSION .
echo "✅ Image built successfully"

# Run container
echo ""
echo "Step 2: Starting container on port 8080..."
docker run -d -p 8080:80 --name nginx-rollout-demo-test nginx-rollout-demo:$VERSION
echo "✅ Container started"

# Wait for container to be ready
echo ""
echo "Step 3: Waiting for container to be ready..."
sleep 3

# Test health endpoint
echo ""
echo "Step 4: Testing health endpoint..."
if curl -s http://localhost:8080/health | grep -q "healthy"; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
    docker logs nginx-rollout-demo-test
    docker stop nginx-rollout-demo-test
    docker rm nginx-rollout-demo-test
    exit 1
fi

# Test main page
echo ""
echo "Step 5: Testing main page..."
if curl -s http://localhost:8080 | grep -q "$VERSION"; then
    echo "✅ Version $VERSION detected in page"
else
    echo "⚠️  Version not detected in page"
fi

# Display information
echo ""
echo "=================================="
echo "✅ Local testing complete!"
echo "=================================="
echo ""
echo "🌐 Access the application at: http://localhost:8080"
echo "❤️  Health endpoint: http://localhost:8080/health"
echo ""
echo "📊 Useful commands:"
echo "  - View logs: docker logs nginx-rollout-demo-test"
echo "  - Stop container: docker stop nginx-rollout-demo-test"
echo "  - Remove container: docker rm nginx-rollout-demo-test"
echo "  - View container: docker ps | grep nginx-rollout-demo"
echo ""
echo "🧹 To cleanup:"
echo "  docker stop nginx-rollout-demo-test && docker rm nginx-rollout-demo-test"
echo ""
echo "Press Ctrl+C to stop and cleanup, or leave running to test in browser."
echo ""

# Option to cleanup
read -p "Do you want to cleanup now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleaning up..."
    docker stop nginx-rollout-demo-test
    docker rm nginx-rollout-demo-test
    echo "✅ Cleanup complete"
else
    echo "Container left running. Access at http://localhost:8080"
    echo "Run 'docker stop nginx-rollout-demo-test && docker rm nginx-rollout-demo-test' to cleanup later."
fi
