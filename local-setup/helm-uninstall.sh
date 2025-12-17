#!/bin/bash

# Uninstall Helm deployment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

RELEASE_NAME="${RELEASE_NAME:-canary-demo}"
NAMESPACE="${NAMESPACE:-default}"

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo ""
echo "======================================================================"
echo "  Uninstall Helm Deployment"
echo "======================================================================"
echo ""

# Check if release exists
if ! helm list -n "${NAMESPACE}" | grep -q "^${RELEASE_NAME}"; then
    echo "Release '${RELEASE_NAME}' not found in namespace '${NAMESPACE}'"
    exit 1
fi

# Show what will be deleted
echo "Current release:"
helm list -n "${NAMESPACE}" | grep "${RELEASE_NAME}"
echo ""

echo "Resources to be deleted:"
kubectl get all -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}"
echo ""

print_warn "This will delete the Helm release '${RELEASE_NAME}' and all its resources"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    print_info "Uninstall cancelled"
    exit 0
fi

print_info "Uninstalling release..."
helm uninstall "${RELEASE_NAME}" -n "${NAMESPACE}"

print_info "✓ Release uninstalled"
echo ""

# Check for remaining resources
echo "Checking for remaining resources..."
remaining=$(kubectl get all -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" 2>/dev/null | grep -v "No resources found" || echo "")

if [ -z "$remaining" ]; then
    print_info "✓ All resources cleaned up"
else
    print_warn "Some resources may still exist:"
    kubectl get all -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}"
fi
