#!/bin/bash

# Quick access to ArgoCD UI using port-forward (alternative to ingress)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo ""
echo "======================================================================"
echo "  ArgoCD UI Access (Port Forward)"
echo "======================================================================"
echo ""

# Get password
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)

print_info "ArgoCD Credentials:"
echo "  URL: http://localhost:8080"
echo "  Username: admin"
echo "  Password: ${PASSWORD}"
echo ""
print_info "Starting port-forward to ArgoCD server..."
echo ""
echo "Press Ctrl+C to stop"
echo ""

kubectl port-forward svc/argocd-server -n argocd 8080:443
