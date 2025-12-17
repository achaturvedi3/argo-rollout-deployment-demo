#!/bin/bash

# Script to deploy a new version of the application

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo ""
echo "======================================================================"
echo "  Deploy New Version"
echo "======================================================================"
echo ""

# Get current version
CURRENT_IMAGE=$(kubectl get rollout canary-demo-rollout -n default -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "unknown")

print_info "Current image: ${CURRENT_IMAGE}"
echo ""

# Prompt for new version
read -p "Enter new image tag (e.g., v2.0.0): " NEW_TAG

if [ -z "$NEW_TAG" ]; then
    print_warn "No tag provided. Exiting."
    exit 0
fi

# Get image repository
IMAGE_REPO=$(echo $CURRENT_IMAGE | cut -d':' -f1)
NEW_IMAGE="${IMAGE_REPO}:${NEW_TAG}"

print_info "New image will be: ${NEW_IMAGE}"
echo ""

read -p "Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warn "Deployment cancelled"
    exit 0
fi

print_info "Updating rollout with new image..."

# Update the rollout
kubectl argo rollouts set image canary-demo-rollout -n default nginx="${NEW_IMAGE}"

print_info "✓ Rollout updated"
echo ""
print_info "Watching rollout progress..."
echo ""

# Watch the rollout
kubectl argo rollouts get rollout canary-demo-rollout -n default --watch
