#!/bin/bash

# Cleanup script to delete the local Kind cluster

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CLUSTER_NAME="${CLUSTER_NAME:-argo-rollouts-demo}"

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
echo "======================================================================"
echo "  Cleanup Local Kind Cluster"
echo "======================================================================"
echo ""

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    print_error "Cluster '${CLUSTER_NAME}' does not exist"
    exit 1
fi

print_warn "This will delete the Kind cluster '${CLUSTER_NAME}' and all its resources"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Cleanup cancelled"
    exit 0
fi

print_info "Deleting Kind cluster '${CLUSTER_NAME}'..."
kind delete cluster --name "${CLUSTER_NAME}"

print_info "✓ Cluster deleted successfully"

# Optional: Remove /etc/hosts entries
print_warn "You may want to remove these entries from /etc/hosts:"
echo "  127.0.0.1 argocd.local canary-demo.local"
echo ""
echo "Run: sudo sed -i '' '/argocd.local\\|canary-demo.local/d' /etc/hosts"
echo ""

# Remove credentials file
if [ -f "local-setup/argocd-credentials.txt" ]; then
    rm -f local-setup/argocd-credentials.txt
    print_info "✓ Removed credentials file"
fi

print_info "Cleanup complete!"
