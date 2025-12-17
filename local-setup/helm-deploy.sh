#!/bin/bash

# Deploy application using Helm chart in local Kind cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-argo-rollouts-demo}"
RELEASE_NAME="${RELEASE_NAME:-canary-demo}"
NAMESPACE="${NAMESPACE:-default}"
CHART_PATH="../helm"
VALUES_FILE="${VALUES_FILE:-}"

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

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed"
        echo "Install with: brew install helm"
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
        echo "Run ./setup-local-cluster.sh first to create the cluster"
        exit 1
    fi
    print_info "✓ Connected to cluster: $(kubectl config current-context)"
    
    # Check if it's the right cluster
    current_context=$(kubectl config current-context)
    if [[ ! "$current_context" == "kind-${CLUSTER_NAME}" ]]; then
        print_warn "Current context is '${current_context}', expected 'kind-${CLUSTER_NAME}'"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Check if chart exists
    if [ ! -f "${CHART_PATH}/Chart.yaml" ]; then
        print_error "Helm chart not found at ${CHART_PATH}"
        exit 1
    fi
    print_info "✓ Helm chart found"
}

# Create namespace if needed
create_namespace() {
    print_section "Preparing Namespace"
    
    if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
        print_info "✓ Namespace '${NAMESPACE}' already exists"
    else
        print_info "Creating namespace '${NAMESPACE}'..."
        kubectl create namespace "${NAMESPACE}"
        print_info "✓ Namespace created"
    fi
}

# Prepare values file for local deployment
prepare_local_values() {
    print_section "Preparing Local Values"
    
    local values_file="local-helm-values.yaml"
    
    print_info "Creating local values file: ${values_file}"
    
    cat > "${values_file}" <<'EOF'
# Local Development Values for Helm Chart

namespace: default

image:
  repository: nginx
  tag: "latest"
  pullPolicy: IfNotPresent

rollout:
  enabled: true
  replicas: 2
  revisionHistoryLimit: 2
  
  resources:
    requests:
      memory: "32Mi"
      cpu: "50m"
    limits:
      memory: "64Mi"
      cpu: "100m"
  
  livenessProbe:
    httpGet:
      path: /
      port: 80
    initialDelaySeconds: 10
    periodSeconds: 10
    timeoutSeconds: 3
    failureThreshold: 3
  
  readinessProbe:
    httpGet:
      path: /
      port: 80
    initialDelaySeconds: 5
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 3
  
  strategy:
    canary:
      steps:
        - setWeight: 20
          pause:
            duration: 30s
        - setWeight: 50
          pause:
            duration: 30s
        - setWeight: 80
          pause:
            duration: 30s
        - setWeight: 100
          pause:
            duration: 10s
      
      autoPromotionEnabled: true
      autoPromotionSeconds: 10
      abortScaleDownDelaySeconds: 30
      scaleDownDelaySeconds: 30

service:
  type: ClusterIP
  port: 80
  targetPort: http
  protocol: TCP

ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: canary-demo.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

# Disable AWS-specific features for local deployment
externalDns:
  enabled: false

aws:
  region: us-east-1
  vpc:
    subnets: ""
  certificate:
    arn: ""
  waf:
    enabled: false

argoRollouts:
  enabled: true
  trafficRouting: nginx

podSecurityContext:
  runAsNonRoot: false
  runAsUser: 0
  fsGroup: 0

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
    add:
      - NET_BIND_SERVICE

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}
podLabels: {}

nodeSelector: {}
tolerations: []
affinity: {}
EOF
    
    print_info "✓ Local values file created: ${values_file}"
    VALUES_FILE="${values_file}"
}

# Validate Helm chart
validate_chart() {
    print_section "Validating Helm Chart"
    
    print_info "Linting Helm chart..."
    if helm lint "${CHART_PATH}" -f "${VALUES_FILE}"; then
        print_info "✓ Chart validation passed"
    else
        print_error "Chart validation failed"
        exit 1
    fi
}

# Dry run deployment
dry_run_deployment() {
    print_section "Dry Run Deployment"
    
    print_info "Running Helm dry-run..."
    helm install "${RELEASE_NAME}" "${CHART_PATH}" \
        -n "${NAMESPACE}" \
        -f "${VALUES_FILE}" \
        --dry-run --debug > /tmp/helm-dry-run-output.yaml
    
    print_info "✓ Dry-run successful"
    print_info "Output saved to: /tmp/helm-dry-run-output.yaml"
}

# Deploy with Helm
deploy_helm() {
    print_section "Deploying with Helm"
    
    # Check if release already exists
    if helm list -n "${NAMESPACE}" | grep -q "^${RELEASE_NAME}"; then
        print_warn "Release '${RELEASE_NAME}' already exists in namespace '${NAMESPACE}'"
        read -p "Upgrade existing release? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Upgrading release..."
            helm upgrade "${RELEASE_NAME}" "${CHART_PATH}" \
                -n "${NAMESPACE}" \
                -f "${VALUES_FILE}"
            print_info "✓ Release upgraded"
        else
            print_info "Skipping deployment"
            return 0
        fi
    else
        print_info "Installing release '${RELEASE_NAME}'..."
        helm install "${RELEASE_NAME}" "${CHART_PATH}" \
            -n "${NAMESPACE}" \
            -f "${VALUES_FILE}"
        print_info "✓ Release installed"
    fi
}

# Wait for rollout to be ready
wait_for_rollout() {
    print_section "Waiting for Rollout"
    
    print_info "Waiting for rollout to be healthy..."
    
    local timeout=120
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if kubectl get rollout "${RELEASE_NAME}-rollout" -n "${NAMESPACE}" &> /dev/null; then
            local status=$(kubectl get rollout "${RELEASE_NAME}-rollout" -n "${NAMESPACE}" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
            
            if [[ "$status" == "Healthy" ]]; then
                print_info "✓ Rollout is healthy"
                return 0
            fi
            
            echo -n "."
            sleep 5
            elapsed=$((elapsed + 5))
        else
            echo -n "."
            sleep 2
            elapsed=$((elapsed + 2))
        fi
    done
    
    echo ""
    print_warn "Timeout waiting for rollout to be healthy"
    print_info "Check status with: kubectl argo rollouts get rollout ${RELEASE_NAME}-rollout -n ${NAMESPACE}"
}

# Expose service
expose_service() {
    print_section "Exposing Service"
    
    # Check if ingress controller is running
    if ! kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller &> /dev/null; then
        print_warn "NGINX Ingress Controller not found"
        print_info "Installing NGINX Ingress Controller..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/kind/deploy.yaml
        
        print_info "Waiting for ingress controller to be ready..."
        kubectl wait --namespace ingress-nginx \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=90s
        print_info "✓ NGINX Ingress Controller ready"
    else
        print_info "✓ NGINX Ingress Controller is running"
    fi
    
    # Check /etc/hosts
    if ! grep -q "canary-demo.local" /etc/hosts 2>/dev/null; then
        print_warn "/etc/hosts does not contain 'canary-demo.local'"
        echo ""
        echo "Add to /etc/hosts with:"
        echo "  sudo bash -c 'echo \"127.0.0.1 canary-demo.local\" >> /etc/hosts'"
        echo ""
    else
        print_info "✓ canary-demo.local found in /etc/hosts"
    fi
}

# Display access information
display_access_info() {
    print_section "Access Information"
    
    # Get release info
    echo "Release Information:"
    helm list -n "${NAMESPACE}" | grep "${RELEASE_NAME}"
    echo ""
    
    # Get services
    echo "Services:"
    kubectl get svc -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}"
    echo ""
    
    # Get ingress
    echo "Ingress:"
    kubectl get ingress -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}"
    echo ""
    
    # Get rollout
    echo "Rollout:"
    kubectl get rollout -n "${NAMESPACE}" "${RELEASE_NAME}-rollout" 2>/dev/null || echo "  Rollout not found"
    echo ""
    
    print_info "Application URL: http://canary-demo.local:8080"
    echo ""
    
    # Save access info
    cat > helm-deployment-info.txt <<EOF
Helm Deployment Information
===========================

Release Name: ${RELEASE_NAME}
Namespace: ${NAMESPACE}
Chart: ${CHART_PATH}
Values File: ${VALUES_FILE}

Access URL: http://canary-demo.local:8080

Useful Commands:
----------------

# Check release status
helm status ${RELEASE_NAME} -n ${NAMESPACE}

# Get release values
helm get values ${RELEASE_NAME} -n ${NAMESPACE}

# Watch rollout
kubectl argo rollouts get rollout ${RELEASE_NAME}-rollout -n ${NAMESPACE} --watch

# View logs
kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/instance=${RELEASE_NAME} -f

# Upgrade release
helm upgrade ${RELEASE_NAME} ${CHART_PATH} -n ${NAMESPACE} -f ${VALUES_FILE}

# Rollback release
helm rollback ${RELEASE_NAME} -n ${NAMESPACE}

# Uninstall release
helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}

# Test application
curl http://canary-demo.local:8080
EOF
    
    print_info "Access information saved to: helm-deployment-info.txt"
}

# Display summary
display_summary() {
    print_section "Deployment Complete!"
    
    cat <<EOF

${GREEN}✓ Helm Deployment Successful${NC}

${BLUE}Deployment Details:${NC}
  Release: ${RELEASE_NAME}
  Namespace: ${NAMESPACE}
  Chart: ${CHART_PATH}

${BLUE}Access Application:${NC}
  URL: http://canary-demo.local:8080
  
  ${YELLOW}Note: Ensure '127.0.0.1 canary-demo.local' is in /etc/hosts${NC}

${BLUE}Quick Commands:${NC}
  # Check status
  helm status ${RELEASE_NAME} -n ${NAMESPACE}
  
  # Watch rollout
  kubectl argo rollouts get rollout ${RELEASE_NAME}-rollout -n ${NAMESPACE} --watch
  
  # View logs
  kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/instance=${RELEASE_NAME} -f
  
  # Test application
  curl http://canary-demo.local:8080
  
  # Upgrade with new image
  helm upgrade ${RELEASE_NAME} ${CHART_PATH} -n ${NAMESPACE} \\
    --reuse-values --set image.tag=v2.0.0

${BLUE}Management Scripts:${NC}
  ./helm-upgrade.sh      - Upgrade deployment
  ./helm-rollback.sh     - Rollback deployment
  ./helm-uninstall.sh    - Remove deployment
  ./helm-status.sh       - Check deployment status

EOF
}

# Main execution
main() {
    echo ""
    echo "======================================================================"
    echo "  Deploy Application with Helm - Local Kind Cluster"
    echo "======================================================================"
    echo ""
    
    check_prerequisites
    create_namespace
    prepare_local_values
    validate_chart
    
    # Ask for confirmation
    print_warn "Ready to deploy"
    echo "  Release: ${RELEASE_NAME}"
    echo "  Namespace: ${NAMESPACE}"
    echo "  Chart: ${CHART_PATH}"
    echo ""
    read -p "Continue? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
    
    dry_run_deployment
    deploy_helm
    wait_for_rollout
    expose_service
    display_access_info
    display_summary
    
    print_info "Deployment script completed!"
}

# Trap errors
trap 'print_error "An error occurred during deployment"; exit 1' ERR

# Run main
main "$@"
