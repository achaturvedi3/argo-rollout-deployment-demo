#!/bin/bash

# Complete Local Infrastructure Setup Script
# This script creates a Kind cluster with ArgoCD, Argo Rollouts, and connects to GitHub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-argo-rollouts-demo}"
GITHUB_REPO="${GITHUB_REPO:-https://github.com/achaturvedi3/argo-rollout-deployment-demo.git}"
ARGOCD_VERSION="${ARGOCD_VERSION:-stable}"
NGINX_INGRESS_VERSION="${NGINX_INGRESS_VERSION:-v1.9.5}"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    local missing_tools=()
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    else
        print_info "✓ Docker is installed: $(docker --version)"
        # Check if Docker is running
        if ! docker info &> /dev/null; then
            print_error "Docker is installed but not running. Please start Docker."
            exit 1
        fi
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    else
        print_info "✓ kubectl is installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
    fi
    
    # Check Kind
    if ! command -v kind &> /dev/null; then
        missing_tools+=("kind")
    else
        print_info "✓ Kind is installed: $(kind version)"
    fi
    
    # Check helm (optional but recommended)
    if ! command -v helm &> /dev/null; then
        print_warn "⚠ Helm is not installed (optional but recommended)"
    else
        print_info "✓ Helm is installed: $(helm version --short)"
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Installation instructions:"
        for tool in "${missing_tools[@]}"; do
            case $tool in
                docker)
                    echo "  Docker: https://docs.docker.com/get-docker/"
                    ;;
                kubectl)
                    echo "  kubectl: brew install kubectl"
                    ;;
                kind)
                    echo "  Kind: brew install kind"
                    ;;
            esac
        done
        exit 1
    fi
    
    print_info "✓ All prerequisites are satisfied"
}

# Function to create Kind cluster
create_kind_cluster() {
    print_section "Creating Kind Cluster"
    
    # Check if cluster already exists
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        print_warn "Cluster '${CLUSTER_NAME}' already exists"
        read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deleting existing cluster..."
            kind delete cluster --name "${CLUSTER_NAME}"
        else
            print_info "Using existing cluster"
            kubectl cluster-info --context "kind-${CLUSTER_NAME}"
            return 0
        fi
    fi
    
    print_info "Creating Kind cluster '${CLUSTER_NAME}' with custom configuration..."
    
    # Create Kind cluster with extra port mappings for ingress
    cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
- role: worker
- role: worker
EOF
    
    print_info "✓ Kind cluster created successfully"
    
    # Set kubectl context
    kubectl config use-context "kind-${CLUSTER_NAME}"
    kubectl cluster-info
}

# Function to install NGINX Ingress Controller
install_nginx_ingress() {
    print_section "Installing NGINX Ingress Controller"
    
    print_info "Deploying NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${NGINX_INGRESS_VERSION}/deploy/static/provider/kind/deploy.yaml
    
    print_info "Waiting for NGINX Ingress Controller to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s
    
    print_info "✓ NGINX Ingress Controller installed successfully"
}

# Function to install Argo Rollouts
install_argo_rollouts() {
    print_section "Installing Argo Rollouts"
    
    # Create namespace
    kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
    
    print_info "Installing Argo Rollouts..."
    kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    
    print_info "Waiting for Argo Rollouts to be ready..."
    kubectl wait --namespace argo-rollouts \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/name=argo-rollouts \
        --timeout=90s
    
    print_info "✓ Argo Rollouts installed successfully"
    
    # Install kubectl argo rollouts plugin if not present
    if ! kubectl argo rollouts version &> /dev/null; then
        print_warn "kubectl argo rollouts plugin not found"
        print_info "Install with: brew install argoproj/tap/kubectl-argo-rollouts"
    else
        print_info "✓ kubectl argo rollouts plugin is available"
    fi
}

# Function to install ArgoCD
install_argocd() {
    print_section "Installing ArgoCD"
    
    # Create namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    print_info "Installing ArgoCD..."
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml
    
    print_info "Waiting for ArgoCD to be ready..."
    kubectl wait --namespace argocd \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/name=argocd-server \
        --timeout=180s
    
    print_info "✓ ArgoCD installed successfully"
    
    # Patch ArgoCD server for insecure mode (for local development)
    print_info "Configuring ArgoCD server for local access..."
    kubectl patch configmap argocd-cmd-params-cm -n argocd \
        --type merge \
        -p '{"data":{"server.insecure":"true"}}'
    
    kubectl rollout restart deployment argocd-server -n argocd
    kubectl rollout status deployment argocd-server -n argocd --timeout=120s
}

# Function to expose ArgoCD UI
expose_argocd_ui() {
    print_section "Exposing ArgoCD UI"
    
    # Create ingress for ArgoCD
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF
    
    print_info "✓ ArgoCD UI exposed at http://argocd.local:8080"
    
    # Get initial admin password
    print_info "Retrieving ArgoCD admin password..."
    sleep 5  # Wait for secret to be created
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "password")
    
    echo ""
    print_info "ArgoCD Credentials:"
    echo "  URL: http://argocd.local:8080"
    echo "  Username: admin"
    echo "  Password: ${ARGOCD_PASSWORD}"
    echo ""
    
    # Save credentials to file
    cat > local-setup/argocd-credentials.txt <<EOF
ArgoCD Access Information
========================

URL: http://argocd.local:8080
Username: admin
Password: ${ARGOCD_PASSWORD}

Note: Add '127.0.0.1 argocd.local' to your /etc/hosts file

To access ArgoCD UI:
1. Add to /etc/hosts: echo "127.0.0.1 argocd.local" | sudo tee -a /etc/hosts
2. Open browser: http://argocd.local:8080
3. Login with credentials above

To use ArgoCD CLI:
argocd login argocd.local:8080 --username admin --password ${ARGOCD_PASSWORD} --insecure
EOF
    
    print_info "Credentials saved to local-setup/argocd-credentials.txt"
}

# Function to configure ArgoCD with GitHub repository
configure_argocd_repo() {
    print_section "Configuring ArgoCD Repository"
    
    print_info "Adding GitHub repository to ArgoCD..."
    
    # Wait for ArgoCD to be fully ready
    sleep 10
    
    # Add repository (public repo, no credentials needed)
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: repo-argo-rollout-demo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${GITHUB_REPO}
EOF
    
    print_info "✓ GitHub repository configured"
}

# Function to create ArgoCD application
create_argocd_application() {
    print_section "Creating ArgoCD Application"
    
    print_info "Creating ArgoCD application for canary-demo..."
    
    # Apply the application manifest
    kubectl apply -f argocd/application.yaml
    
    print_info "✓ ArgoCD application created"
    
    # Trigger initial sync
    print_info "Triggering initial sync..."
    sleep 5
    kubectl patch application canary-demo -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
}

# Function to create application ingress
create_app_ingress() {
    print_section "Creating Application Ingress"
    
    print_info "Creating ingress for canary-demo application..."
    
    # Wait for application to be deployed
    sleep 10
    
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary-demo-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: canary-demo.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: canary-demo-stable
            port:
              number: 80
EOF
    
    print_info "✓ Application ingress created at http://canary-demo.local:8080"
}

# Function to update /etc/hosts
update_hosts_file() {
    print_section "Updating /etc/hosts"
    
    # Check if entries already exist
    if grep -q "argocd.local" /etc/hosts && grep -q "canary-demo.local" /etc/hosts; then
        print_info "✓ /etc/hosts already configured"
        return 0
    fi
    
    print_warn "Need to add entries to /etc/hosts file"
    echo ""
    echo "Please run the following command:"
    echo ""
    echo "  sudo bash -c 'echo \"127.0.0.1 argocd.local canary-demo.local\" >> /etc/hosts'"
    echo ""
    read -p "Press Enter after updating /etc/hosts or 's' to skip: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        # Verify the update
        if grep -q "argocd.local" /etc/hosts && grep -q "canary-demo.local" /etc/hosts; then
            print_info "✓ /etc/hosts updated successfully"
        else
            print_warn "Could not verify /etc/hosts update. You may need to add entries manually."
        fi
    fi
}

# Function to display summary
display_summary() {
    print_section "Setup Complete!"
    
    cat <<EOF

${GREEN}✓ Local Infrastructure Setup Successful${NC}

${BLUE}Cluster Information:${NC}
  Name: ${CLUSTER_NAME}
  Context: kind-${CLUSTER_NAME}
  Nodes: $(kubectl get nodes --no-headers | wc -l | tr -d ' ')

${BLUE}Installed Components:${NC}
  ✓ NGINX Ingress Controller
  ✓ Argo Rollouts
  ✓ ArgoCD
  ✓ Canary Demo Application

${BLUE}Access URLs:${NC}
  ArgoCD UI:        http://argocd.local:8080
  Application:      http://canary-demo.local:8080

${BLUE}ArgoCD Credentials:${NC}
  Username: admin
  Password: (see local-setup/argocd-credentials.txt)

${BLUE}Quick Commands:${NC}
  # Watch rollout status
  kubectl argo rollouts get rollout canary-demo-rollout --watch

  # View ArgoCD applications
  kubectl get applications -n argocd

  # View all resources
  kubectl get all -n default

  # Access ArgoCD CLI
  argocd login argocd.local:8080 --insecure

  # Port-forward ArgoCD (alternative to ingress)
  kubectl port-forward svc/argocd-server -n argocd 8080:443

${BLUE}Next Steps:${NC}
  1. Ensure /etc/hosts has entries for argocd.local and canary-demo.local
  2. Open http://argocd.local:8080 in your browser
  3. Login to ArgoCD with credentials above
  4. View the canary-demo application
  5. Make changes to k8s manifests and push to trigger deployment

${BLUE}Useful Scripts:${NC}
  ./local-setup/status.sh              - Check cluster status
  ./local-setup/restart.sh             - Restart the cluster
  ./local-setup/cleanup.sh             - Delete the cluster
  ./local-setup/deploy-new-version.sh  - Deploy a new version

${YELLOW}Note: This is a local development environment. Not for production use.${NC}

EOF
}

# Main execution
main() {
    echo ""
    echo "======================================================================"
    echo "  Argo Rollouts Demo - Local Infrastructure Setup"
    echo "======================================================================"
    echo ""
    
    check_prerequisites
    create_kind_cluster
    install_nginx_ingress
    install_argo_rollouts
    install_argocd
    expose_argocd_ui
    configure_argocd_repo
    create_argocd_application
    create_app_ingress
    update_hosts_file
    display_summary
    
    echo ""
    print_info "Setup script completed successfully!"
    echo ""
}

# Trap errors
trap 'print_error "An error occurred. Setup failed."; exit 1' ERR

# Run main
main "$@"
