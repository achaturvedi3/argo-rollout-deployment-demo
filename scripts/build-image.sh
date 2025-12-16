#!/bin/bash
# Script to build and test the Docker image locally

set -e

VERSION=${1:-v1}
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "🐳 Building Docker image for version: ${VERSION}"
echo "=============================================="

cd "$(dirname "$0")/../app"

docker build \
    --build-arg APP_VERSION="${VERSION}" \
    --build-arg BUILD_TIME="${BUILD_TIME}" \
    --build-arg VERSION_TYPE="stable" \
    -t canary-demo:${VERSION} \
    -t canary-demo:latest \
    .

echo ""
echo "✅ Image built successfully!"
echo ""
echo "To test the image locally, run:"
echo "  docker run -d -p 8080:80 --name canary-demo-test canary-demo:${VERSION}"
echo "  curl http://localhost:8080"
echo "  docker stop canary-demo-test && docker rm canary-demo-test"
echo ""
echo "To push to registry:"
echo "  docker tag canary-demo:${VERSION} YOUR_USERNAME/canary-demo:${VERSION}"
echo "  docker push YOUR_USERNAME/canary-demo:${VERSION}"
