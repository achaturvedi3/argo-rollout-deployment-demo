#!/bin/bash

# Rollback Helm deployment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

RELEASE_NAME="${RELEASE_NAME:-canary-demo}"
NAMESPACE="${NAMESPACE:-default}"

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

echo ""
echo "======================================================================"
echo "  Rollback Helm Deployment"
echo "======================================================================"
echo ""

# Check if release exists
if ! helm list -n "${NAMESPACE}" | grep -q "^${RELEASE_NAME}"; then
    echo "Release '${RELEASE_NAME}' not found in namespace '${NAMESPACE}'"
    exit 1
fi

print_section "Release History"
helm history "${RELEASE_NAME}" -n "${NAMESPACE}"

echo ""
read -p "Enter revision number to rollback to (or press Enter for previous): " revision

print_warn "This will rollback the deployment"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Rollback cancelled"
    exit 0
fi

print_info "Rolling back..."

if [ -z "$revision" ]; then
    # Rollback to previous revision
    helm rollback "${RELEASE_NAME}" -n "${NAMESPACE}"
else
    # Rollback to specific revision
    helm rollback "${RELEASE_NAME}" "${revision}" -n "${NAMESPACE}"
fi

print_info "✓ Rollback complete"
echo ""

print_section "Current Status"
helm status "${RELEASE_NAME}" -n "${NAMESPACE}"
