#!/bin/bash

# Pre-flight Check Script
# Run this before setup-local-cluster.sh to verify prerequisites

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_check() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    echo "----------------------------------------"
}

all_good=true

echo ""
echo "======================================================================"
echo "  Pre-flight Checklist for Local Infrastructure Setup"
echo "======================================================================"

print_section "Checking System"

# Check OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_check "Operating System: macOS"
else
    print_warn "OS is not macOS. Scripts are optimized for macOS."
    print_warn "You may need to adjust some commands."
fi

# Check available RAM
total_ram=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
total_ram_gb=$((total_ram / 1024 / 1024 / 1024))
if [ "$total_ram_gb" -ge 8 ]; then
    print_check "System RAM: ${total_ram_gb}GB (sufficient)"
else
    print_fail "System RAM: ${total_ram_gb}GB (minimum 8GB recommended)"
    all_good=false
fi

# Check available disk space
available_space=$(df -h / | awk 'NR==2 {print $4}')
print_check "Available disk space: $available_space"

print_section "Checking Required Tools"

# Check Docker
if command -v docker &> /dev/null; then
    docker_version=$(docker --version)
    print_check "Docker installed: $docker_version"
    
    # Check if Docker is running
    if docker info &> /dev/null; then
        print_check "Docker is running"
        
        # Check Docker resources
        if docker info 2>/dev/null | grep -q "CPUs"; then
            docker_cpus=$(docker info 2>/dev/null | grep "CPUs:" | awk '{print $2}')
            docker_mem=$(docker info 2>/dev/null | grep "Total Memory:" | awk '{print $3$4}')
            
            print_check "Docker CPUs: $docker_cpus"
            print_check "Docker Memory: $docker_mem"
            
            if [ "$docker_cpus" -lt 2 ]; then
                print_warn "Docker has less than 2 CPUs. Recommend 4 CPUs for better performance."
            fi
        fi
    else
        print_fail "Docker is installed but not running"
        echo "  → Start Docker Desktop and retry"
        all_good=false
    fi
else
    print_fail "Docker not installed"
    echo "  → Install from: https://www.docker.com/products/docker-desktop"
    all_good=false
fi

# Check kubectl
if command -v kubectl &> /dev/null; then
    kubectl_version=$(kubectl version --client --short 2>/dev/null || kubectl version --client)
    print_check "kubectl installed: $kubectl_version"
else
    print_fail "kubectl not installed"
    echo "  → Install with: brew install kubectl"
    all_good=false
fi

# Check Kind
if command -v kind &> /dev/null; then
    kind_version=$(kind version)
    print_check "Kind installed: $kind_version"
else
    print_fail "Kind not installed"
    echo "  → Install with: brew install kind"
    all_good=false
fi

# Check Helm (optional)
if command -v helm &> /dev/null; then
    helm_version=$(helm version --short)
    print_check "Helm installed: $helm_version (optional)"
else
    print_warn "Helm not installed (optional but recommended)"
    echo "  → Install with: brew install helm"
fi

# Check kubectl argo rollouts plugin (optional)
if command -v kubectl-argo-rollouts &> /dev/null; then
    print_check "kubectl argo rollouts plugin installed (optional)"
else
    print_warn "kubectl argo rollouts plugin not installed (optional)"
    echo "  → Install with: brew install argoproj/tap/kubectl-argo-rollouts"
fi

# Check ArgoCD CLI (optional)
if command -v argocd &> /dev/null; then
    print_check "ArgoCD CLI installed (optional)"
else
    print_warn "ArgoCD CLI not installed (optional)"
    echo "  → Install with: brew install argocd"
fi

print_section "Checking Network"

# Check internet connectivity
if ping -c 1 -W 2 github.com &> /dev/null; then
    print_check "Internet connectivity: OK"
else
    print_fail "Cannot reach github.com"
    echo "  → Check your internet connection"
    all_good=false
fi

# Check if ports are available
check_port() {
    if ! lsof -i :$1 &> /dev/null; then
        print_check "Port $1 available"
        return 0
    else
        process=$(lsof -i :$1 | tail -1 | awk '{print $1}')
        print_fail "Port $1 in use by: $process"
        return 1
    fi
}

if ! check_port 8080; then
    echo "  → Stop the process using port 8080 or it will conflict with ingress"
    all_good=false
fi

if ! check_port 8443; then
    print_warn "Port 8443 in use (this may be OK)"
fi

print_section "Checking Existing Resources"

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^argo-rollouts-demo$"; then
    print_warn "Cluster 'argo-rollouts-demo' already exists"
    echo "  → Setup script will prompt to delete and recreate it"
else
    print_check "No existing cluster found"
fi

# Check /etc/hosts
if grep -q "argocd.local" /etc/hosts 2>/dev/null; then
    print_check "argocd.local already in /etc/hosts"
else
    print_warn "argocd.local not in /etc/hosts"
    echo "  → You'll need to add: sudo bash -c 'echo \"127.0.0.1 argocd.local canary-demo.local\" >> /etc/hosts'"
fi

print_section "Summary"
echo ""

if [ "$all_good" = true ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You're ready to run the setup:"
    echo "  ./setup-local-cluster.sh"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Please fix the issues above before running setup."
    echo ""
    echo "Quick fixes:"
    echo "  1. Start Docker Desktop"
    echo "  2. Install missing tools with Homebrew"
    echo "  3. Free up ports 8080 and 8443"
    echo ""
    exit 1
fi
