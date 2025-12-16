#!/bin/bash
# Script to test traffic splitting by continuously curling the application

set -e

# Get service endpoint
NAMESPACE="default"
SERVICE_NAME="canary-demo-root"

echo "🔄 Testing traffic distribution..."
echo "===================================="
echo ""

# Try to get LoadBalancer endpoint
LB_ENDPOINT=$(kubectl get svc ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$LB_ENDPOINT" ]; then
    LB_ENDPOINT=$(kubectl get svc ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
fi

if [ -z "$LB_ENDPOINT" ]; then
    echo "⚠️  LoadBalancer endpoint not found. Using port-forward..."
    kubectl port-forward -n ${NAMESPACE} svc/${SERVICE_NAME} 8080:80 &
    PF_PID=$!
    sleep 3
    ENDPOINT="localhost:8080"
    CLEANUP_PF=true
else
    ENDPOINT="${LB_ENDPOINT}"
    CLEANUP_PF=false
fi

echo "Testing endpoint: http://${ENDPOINT}"
echo ""
echo "Version distribution (press Ctrl+C to stop):"
echo "--------------------------------------------"

# Trap to cleanup port-forward
cleanup() {
    if [ "$CLEANUP_PF" = true ]; then
        kill $PF_PID 2>/dev/null || true
    fi
    echo ""
    echo "Summary:"
    echo "--------"
    for version in "${!version_counts[@]}"; do
        count=${version_counts[$version]}
        percentage=$(awk "BEGIN {printf \"%.1f\", ($count / $total_requests) * 100}")
        echo "${version}: ${count} requests (${percentage}%)"
    done
}
trap cleanup EXIT

# Track versions
declare -A version_counts
total_requests=0

while true; do
    # Extract version from response
    version=$(curl -s "http://${ENDPOINT}" | grep -oP 'v[0-9]+' | head -1 2>/dev/null || echo "unknown")
    
    if [ "$version" != "unknown" ]; then
        ((total_requests++))
        ((version_counts[$version]++))
        
        # Print current distribution every 10 requests
        if (( total_requests % 10 == 0 )); then
            echo -n "Total: ${total_requests} | "
            for v in $(echo "${!version_counts[@]}" | tr ' ' '\n' | sort); do
                count=${version_counts[$v]}
                percentage=$(awk "BEGIN {printf \"%.1f\", ($count / $total_requests) * 100}")
                echo -n "${v}: ${percentage}% | "
            done
            echo ""
        fi
    fi
    
    sleep 0.5
done
