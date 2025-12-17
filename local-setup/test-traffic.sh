#!/bin/bash

# Test traffic to the canary demo application

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

URL="${1:-http://canary-demo.local:8080}"
INTERVAL="${2:-1}"

echo ""
echo "======================================================================"
echo "  Testing Traffic to: ${URL}"
echo "======================================================================"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Test if using ingress with hostname
if [[ $URL == *".local"* ]]; then
    # Check if hostname is in /etc/hosts
    if ! grep -q "canary-demo.local" /etc/hosts 2>/dev/null; then
        echo "Warning: canary-demo.local not found in /etc/hosts"
        echo "Add it with: sudo bash -c 'echo \"127.0.0.1 canary-demo.local\" >> /etc/hosts'"
        echo ""
    fi
fi

while true; do
    RESPONSE=$(curl -s -w "\n%{http_code}" "${URL}" 2>/dev/null || echo "000")
    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | head -1)
    
    if [ "$HTTP_CODE" == "200" ]; then
        # Try to extract version from response
        VERSION=$(echo "$BODY" | grep -o "version [^<]*" | head -1 || echo "unknown")
        echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} HTTP ${HTTP_CODE} - ${VERSION}"
    else
        echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} HTTP ${HTTP_CODE}"
    fi
    
    sleep "$INTERVAL"
done
