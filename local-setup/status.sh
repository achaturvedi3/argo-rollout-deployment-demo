#!/bin/bash

# Status check script for the local Kind cluster

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

CLUSTER_NAME="${CLUSTER_NAME:-argo-rollouts-demo}"

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

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${RED}[ERROR]${NC} Cluster '${CLUSTER_NAME}' does not exist"
    echo "Run ./local-setup/setup-local-cluster.sh to create it"
    exit 1
fi

echo ""
echo "======================================================================"
echo "  Local Kind Cluster Status"
echo "======================================================================"
echo ""

# Switch context
kubectl config use-context "kind-${CLUSTER_NAME}" > /dev/null 2>&1

print_section "Cluster Information"
kubectl cluster-info
echo ""
kubectl get nodes

print_section "ArgoCD Status"
echo "Namespace:"
kubectl get namespace argocd --no-headers 2>/dev/null || echo "  Not found"
echo ""
echo "Pods:"
kubectl get pods -n argocd
echo ""
echo "Services:"
kubectl get svc -n argocd

print_section "Argo Rollouts Status"
echo "Namespace:"
kubectl get namespace argo-rollouts --no-headers 2>/dev/null || echo "  Not found"
echo ""
echo "Pods:"
kubectl get pods -n argo-rollouts

print_section "Application Status"
echo "Rollouts:"
kubectl get rollouts -n default 2>/dev/null || echo "  No rollouts found"
echo ""
echo "Services:"
kubectl get svc -n default 2>/dev/null || echo "  No services found"
echo ""
echo "Pods:"
kubectl get pods -n default 2>/dev/null || echo "  No pods found"
echo ""
echo "Ingresses:"
kubectl get ingress -n default 2>/dev/null || echo "  No ingresses found"

print_section "ArgoCD Applications"
kubectl get applications -n argocd 2>/dev/null || echo "  No applications found"

print_section "NGINX Ingress Controller"
kubectl get pods -n ingress-nginx

print_section "Access Information"
if [ -f "local-setup/argocd-credentials.txt" ]; then
    cat local-setup/argocd-credentials.txt
else
    echo "Credentials file not found"
    echo ""
    echo "ArgoCD URL: http://argocd.local:8080"
    echo "Username: admin"
    echo "Password: Run below command to get it"
    echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
fi

echo ""
print_section "Quick Commands"
cat <<EOF
# Watch rollout
kubectl argo rollouts get rollout canary-demo-rollout -n default --watch

# View logs
kubectl logs -n default -l app=canary-demo -f

# Port forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access application
curl http://canary-demo.local:8080

# ArgoCD CLI login
argocd login argocd.local:8080 --insecure
EOF

echo ""
