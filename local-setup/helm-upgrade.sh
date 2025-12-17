#!/bin/bash

# Upgrade Helm deployment with new version

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CLUSTER_NAME="${CLUSTER_NAME:-argo-rollouts-demo}"
RELEASE_NAME="${RELEASE_NAME:-canary-demo}"
NAMESPACE="${NAMESPACE:-default}"
CHART_PATH="../helm"
VALUES_FILE="${VALUES_FILE:-local-helm-values.yaml}"

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
echo "  Upgrade Helm Deployment"
echo "======================================================================"
echo ""

# Check if release exists
if ! helm list -n "${NAMESPACE}" | grep -q "^${RELEASE_NAME}"; then
    echo "Release '${RELEASE_NAME}' not found in namespace '${NAMESPACE}'"
    echo "Run ./helm-deploy.sh first to deploy"
    exit 1
fi

print_section "Current Deployment"
helm list -n "${NAMESPACE}" | grep "${RELEASE_NAME}"
echo ""
kubectl get rollout "${RELEASE_NAME}-rollout" -n "${NAMESPACE}" 2>/dev/null || echo "Rollout not found"

print_section "Upgrade Options"
echo "Choose upgrade method:"
echo "  1. Upgrade with new image tag"
echo "  2. Upgrade with values file changes"
echo "  3. Upgrade with inline values"
echo "  4. Reuse values and update specific fields"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        read -p "Enter new image tag: " image_tag
        if [ -z "$image_tag" ]; then
            echo "No tag provided. Exiting."
            exit 0
        fi
        
        print_info "Upgrading with image tag: ${image_tag}"
        helm upgrade "${RELEASE_NAME}" "${CHART_PATH}" \
            -n "${NAMESPACE}" \
            --reuse-values \
            --set image.tag="${image_tag}"
        ;;
    2)
        if [ ! -f "${VALUES_FILE}" ]; then
            echo "Values file not found: ${VALUES_FILE}"
            exit 1
        fi
        
        print_info "Upgrading with values file: ${VALUES_FILE}"
        helm upgrade "${RELEASE_NAME}" "${CHART_PATH}" \
            -n "${NAMESPACE}" \
            -f "${VALUES_FILE}"
        ;;
    3)
        read -p "Enter values (e.g., --set key=value): " inline_values
        if [ -z "$inline_values" ]; then
            echo "No values provided. Exiting."
            exit 0
        fi
        
        print_info "Upgrading with inline values"
        helm upgrade "${RELEASE_NAME}" "${CHART_PATH}" \
            -n "${NAMESPACE}" \
            --reuse-values \
            ${inline_values}
        ;;
    4)
        read -p "Enter field to update (e.g., rollout.replicas): " field
        read -p "Enter new value: " value
        
        if [ -z "$field" ] || [ -z "$value" ]; then
            echo "Field or value not provided. Exiting."
            exit 0
        fi
        
        print_info "Updating ${field} to ${value}"
        helm upgrade "${RELEASE_NAME}" "${CHART_PATH}" \
            -n "${NAMESPACE}" \
            --reuse-values \
            --set "${field}=${value}"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

print_info "✓ Upgrade initiated"
echo ""

print_section "Watching Rollout"
print_info "Monitoring rollout progress..."
echo ""

# Watch rollout for a bit
if command -v kubectl-argo-rollouts &> /dev/null; then
    kubectl argo rollouts get rollout "${RELEASE_NAME}-rollout" -n "${NAMESPACE}" --watch
else
    kubectl get rollout "${RELEASE_NAME}-rollout" -n "${NAMESPACE}" -w
fi
