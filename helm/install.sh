#!/bin/bash

# Helm Chart Installation Script for Canary Demo
# This script helps you install the canary-demo Helm chart with proper validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install Helm 3.x"
        exit 1
    fi
    print_info "✓ Helm is installed: $(helm version --short)"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_info "✓ kubectl is installed"
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_info "✓ Connected to Kubernetes cluster"
    
    # Check if AWS Load Balancer Controller is installed
    if ! kubectl get deployment -n kube-system aws-load-balancer-controller &> /dev/null; then
        print_warn "AWS Load Balancer Controller is not installed"
        print_warn "Install it with: helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system"
    else
        print_info "✓ AWS Load Balancer Controller is installed"
    fi
    
    # Check if External DNS is installed
    if ! kubectl get deployment -n kube-system external-dns &> /dev/null; then
        print_warn "External DNS is not installed"
        print_warn "Install it with: helm install external-dns external-dns/external-dns -n kube-system"
    else
        print_info "✓ External DNS is installed"
    fi
    
    # Check if Argo Rollouts is installed
    if ! kubectl get deployment -n argo-rollouts argo-rollouts &> /dev/null; then
        print_warn "Argo Rollouts is not installed"
        print_warn "Install it with: kubectl apply -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml"
    else
        print_info "✓ Argo Rollouts is installed"
    fi
}

# Validate values file
validate_values() {
    local values_file=$1
    
    print_info "Validating values file: $values_file"
    
    if [ ! -f "$values_file" ]; then
        print_error "Values file not found: $values_file"
        exit 1
    fi
    
    # Check for required fields
    if ! grep -q "image:" "$values_file"; then
        print_error "Missing 'image' configuration in values file"
        exit 1
    fi
    
    if ! grep -q "ingress:" "$values_file"; then
        print_error "Missing 'ingress' configuration in values file"
        exit 1
    fi
    
    print_info "✓ Values file is valid"
}

# Dry run installation
dry_run() {
    local release_name=$1
    local namespace=$2
    local values_file=$3
    
    print_info "Performing dry-run..."
    
    helm install "$release_name" ./helm \
        -n "$namespace" \
        -f "$values_file" \
        --dry-run --debug > /tmp/helm-dry-run.yaml
    
    print_info "✓ Dry-run successful. Output saved to /tmp/helm-dry-run.yaml"
}

# Install chart
install_chart() {
    local release_name=$1
    local namespace=$2
    local values_file=$3
    local create_namespace=$4
    
    print_info "Installing Helm chart..."
    
    if [ "$create_namespace" = true ]; then
        helm install "$release_name" ./helm \
            -n "$namespace" \
            --create-namespace \
            -f "$values_file"
    else
        helm install "$release_name" ./helm \
            -n "$namespace" \
            -f "$values_file"
    fi
    
    print_info "✓ Chart installed successfully"
}

# Verify installation
verify_installation() {
    local release_name=$1
    local namespace=$2
    
    print_info "Verifying installation..."
    
    # Check release status
    if ! helm status "$release_name" -n "$namespace" &> /dev/null; then
        print_error "Release not found"
        exit 1
    fi
    
    # Check rollout
    print_info "Checking Rollout..."
    kubectl get rollout -n "$namespace" -l app.kubernetes.io/instance="$release_name"
    
    # Check services
    print_info "Checking Services..."
    kubectl get svc -n "$namespace" -l app.kubernetes.io/instance="$release_name"
    
    # Check ingress
    print_info "Checking Ingress..."
    kubectl get ingress -n "$namespace" -l app.kubernetes.io/instance="$release_name"
    
    print_info "✓ Verification complete"
}

# Main script
main() {
    echo "=========================================="
    echo "Canary Demo Helm Chart Installation"
    echo "=========================================="
    echo ""
    
    # Default values
    RELEASE_NAME="canary-demo"
    NAMESPACE="default"
    VALUES_FILE="helm/examples/basic-deployment.yaml"
    CREATE_NAMESPACE=false
    SKIP_CHECKS=false
    DRY_RUN=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                RELEASE_NAME="$2"
                shift 2
                ;;
            -ns|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -f|--values)
                VALUES_FILE="$2"
                shift 2
                ;;
            --create-namespace)
                CREATE_NAMESPACE=true
                shift
                ;;
            --skip-checks)
                SKIP_CHECKS=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -n, --name NAME              Release name (default: canary-demo)"
                echo "  -ns, --namespace NAMESPACE   Kubernetes namespace (default: default)"
                echo "  -f, --values FILE            Values file (default: helm/examples/basic-deployment.yaml)"
                echo "  --create-namespace           Create namespace if it doesn't exist"
                echo "  --skip-checks                Skip prerequisite checks"
                echo "  --dry-run                    Perform dry-run only"
                echo "  -h, --help                   Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Run checks
    if [ "$SKIP_CHECKS" = false ]; then
        check_prerequisites
        echo ""
    fi
    
    # Validate values
    validate_values "$VALUES_FILE"
    echo ""
    
    # Dry run if requested
    if [ "$DRY_RUN" = true ]; then
        dry_run "$RELEASE_NAME" "$NAMESPACE" "$VALUES_FILE"
        echo ""
        print_info "Dry-run complete. Review /tmp/helm-dry-run.yaml and run without --dry-run to install"
        exit 0
    fi
    
    # Install chart
    install_chart "$RELEASE_NAME" "$NAMESPACE" "$VALUES_FILE" "$CREATE_NAMESPACE"
    echo ""
    
    # Wait for resources
    print_info "Waiting for resources to be ready..."
    sleep 5
    
    # Verify installation
    verify_installation "$RELEASE_NAME" "$NAMESPACE"
    echo ""
    
    echo "=========================================="
    print_info "Installation complete!"
    echo "=========================================="
    echo ""
    print_info "Next steps:"
    echo "  1. Check rollout status: kubectl argo rollouts get rollout $RELEASE_NAME-rollout -n $NAMESPACE --watch"
    echo "  2. Get ALB URL: kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'"
    echo "  3. View logs: kubectl logs -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME -f"
}

# Run main function
main "$@"
