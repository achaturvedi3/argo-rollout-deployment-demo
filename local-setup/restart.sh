#!/bin/bash

# Restart ArgoCD and Argo Rollouts components

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
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
echo "  Restart Cluster Components"
echo "======================================================================"
echo ""

print_section "Restarting ArgoCD"
kubectl rollout restart deployment -n argocd
print_info "Waiting for ArgoCD deployments to be ready..."
kubectl rollout status deployment -n argocd --timeout=120s

print_section "Restarting Argo Rollouts"
kubectl rollout restart deployment -n argo-rollouts
print_info "Waiting for Argo Rollouts to be ready..."
kubectl rollout status deployment -n argo-rollouts --timeout=120s

print_section "Restarting NGINX Ingress"
kubectl rollout restart deployment -n ingress-nginx
print_info "Waiting for NGINX Ingress to be ready..."
kubectl rollout status deployment -n ingress-nginx --timeout=120s

print_info "✓ All components restarted successfully"
echo ""
