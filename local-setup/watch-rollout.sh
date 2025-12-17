#!/bin/bash

# Watch rollout progress for the canary demo

set -e

NAMESPACE="${1:-default}"
ROLLOUT_NAME="${2:-canary-demo-rollout}"

echo ""
echo "======================================================================"
echo "  Watching Rollout: ${ROLLOUT_NAME}"
echo "======================================================================"
echo ""

# Check if kubectl argo rollouts is available
if ! command -v kubectl-argo-rollouts &> /dev/null; then
    echo "kubectl argo rollouts plugin not found"
    echo "Install with: brew install argoproj/tap/kubectl-argo-rollouts"
    echo ""
    echo "Falling back to kubectl get rollout..."
    watch kubectl get rollout "${ROLLOUT_NAME}" -n "${NAMESPACE}"
else
    kubectl argo rollouts get rollout "${ROLLOUT_NAME}" -n "${NAMESPACE}" --watch
fi
