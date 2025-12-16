#!/bin/bash
# Quick setup script for local testing

set -e

echo "🚀 Argo Rollouts Canary Demo - Quick Setup"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi
echo "✓ Docker is installed"

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi
echo "✓ kubectl is installed"

# Check if kubectl can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please configure kubectl first."
    exit 1
fi
echo "✓ kubectl is configured and connected to cluster"

echo ""
echo "Checking for required components in cluster..."

# Check for ArgoCD
if ! kubectl get namespace argocd &> /dev/null; then
    echo "⚠️  ArgoCD namespace not found. Installing ArgoCD..."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo "✓ ArgoCD installed"
else
    echo "✓ ArgoCD namespace exists"
fi

# Check for Argo Rollouts
if ! kubectl get namespace argo-rollouts &> /dev/null; then
    echo "⚠️  Argo Rollouts namespace not found. Installing Argo Rollouts..."
    kubectl create namespace argo-rollouts
    kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    echo "✓ Argo Rollouts installed"
else
    echo "✓ Argo Rollouts namespace exists"
fi

# Check for NGINX Ingress Controller
if ! kubectl get namespace ingress-nginx &> /dev/null; then
    echo "⚠️  NGINX Ingress Controller not found. Do you want to install it? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
        echo "✓ NGINX Ingress Controller installed"
    else
        echo "⚠️  Skipping NGINX Ingress Controller installation"
    fi
else
    echo "✓ NGINX Ingress Controller namespace exists"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure your GitHub secrets (see README.md)"
echo "2. Update configuration in k8s/ and argocd/ directories"
echo "3. Deploy the ArgoCD application: kubectl apply -f argocd/application.yaml"
echo "4. Push to main branch to trigger CI/CD pipeline"
echo ""
echo "For detailed instructions, see DEPLOYMENT_GUIDE.md"
