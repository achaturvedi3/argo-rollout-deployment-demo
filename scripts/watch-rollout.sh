#!/bin/bash
# Script to watch rollout progress

set -e

ROLLOUT_NAME="canary-demo-rollout"
NAMESPACE="default"

echo "👀 Watching Argo Rollout: ${ROLLOUT_NAME}"
echo "=========================================="
echo ""

# Check if kubectl-argo-rollouts plugin is installed
if ! command -v kubectl-argo-rollouts &> /dev/null; then
    echo "⚠️  kubectl-argo-rollouts plugin not found. Installing..."
    
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ARCH="amd64"
    fi
    
    curl -LO "https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-${OS}-${ARCH}"
    chmod +x "kubectl-argo-rollouts-${OS}-${ARCH}"
    sudo mv "kubectl-argo-rollouts-${OS}-${ARCH}" /usr/local/bin/kubectl-argo-rollouts
    
    echo "✓ kubectl-argo-rollouts installed"
    echo ""
fi

# Watch the rollout
kubectl argo rollouts get rollout ${ROLLOUT_NAME} -n ${NAMESPACE} --watch
