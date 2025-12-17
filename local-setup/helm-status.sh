#!/bin/bash

# Check Helm deployment status

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

RELEASE_NAME="${RELEASE_NAME:-canary-demo}"
NAMESPACE="${NAMESPACE:-default}"

print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

echo ""
echo "======================================================================"
echo "  Helm Deployment Status"
echo "======================================================================"
echo ""

# Check if release exists
if ! helm list -n "${NAMESPACE}" | grep -q "^${RELEASE_NAME}"; then
    echo "Release '${RELEASE_NAME}' not found in namespace '${NAMESPACE}'"
    exit 1
fi

print_section "Helm Release Status"
helm status "${RELEASE_NAME}" -n "${NAMESPACE}"

print_section "Release History"
helm history "${RELEASE_NAME}" -n "${NAMESPACE}"

print_section "Current Values"
helm get values "${RELEASE_NAME}" -n "${NAMESPACE}"

print_section "Rollout Status"
if kubectl get rollout "${RELEASE_NAME}-rollout" -n "${NAMESPACE}" &> /dev/null; then
    kubectl get rollout "${RELEASE_NAME}-rollout" -n "${NAMESPACE}"
    echo ""
    
    if command -v kubectl-argo-rollouts &> /dev/null; then
        echo "Detailed rollout status:"
        kubectl argo rollouts get rollout "${RELEASE_NAME}-rollout" -n "${NAMESPACE}"
    fi
else
    echo "Rollout not found"
fi

print_section "Services"
kubectl get svc -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}"

print_section "Pods"
kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}"

print_section "Ingress"
kubectl get ingress -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}"

print_section "Access Information"
echo "Application URL: http://canary-demo.local:8080"
echo ""
echo "Test with: curl http://canary-demo.local:8080"
echo ""
