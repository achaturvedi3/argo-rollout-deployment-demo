# Argo Rollouts Canary Deployment Demo 🚀

A complete production-ready demonstration of canary deployments using Argo Rollouts, ArgoCD, NGINX, and AWS EKS with fully automated CI/CD pipelines.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [CI/CD Pipeline](#cicd-pipeline)
- [Observing Canary Deployments](#observing-canary-deployments)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## 🎯 Overview

This project demonstrates a complete canary deployment strategy using:

- **Application**: Simple NGINX-based web application with visual version indicators
- **Container Registry**: Docker Hub (configurable for AWS ECR)
- **Kubernetes**: AWS EKS cluster
- **Deployment**: Argo Rollouts for progressive delivery
- **GitOps**: ArgoCD for continuous deployment
- **CI/CD**: GitHub Actions for automated build and deployment

The application displays different colored pages for each version (v1, v2, v3, v4), making it easy to observe traffic splitting during canary rollouts.

## 🏗️ Architecture

```
┌─────────────────┐
│  GitHub Repo    │
│  (Source Code)  │
└────────┬────────┘
         │
         │ Push to main/develop
         ↓
┌─────────────────┐
│   CI Pipeline   │
│ (GitHub Actions)│
├─────────────────┤
│ 1. Build Image  │
│ 2. Tag Version  │
│ 3. Push to ECR  │
└────────┬────────┘
         │
         │ Trigger CD
         ↓
┌─────────────────┐
│   CD Pipeline   │
│ (GitHub Actions)│
├─────────────────┤
│ 1. Update K8s   │
│ 2. ArgoCD Sync  │
│ 3. Monitor      │
└────────┬────────┘
         │
         ↓
┌─────────────────────────────────┐
│         AWS EKS Cluster         │
├─────────────────────────────────┤
│  ┌──────────┐   ┌────────────┐ │
│  │  ArgoCD  │   │   Argo     │ │
│  │          │   │  Rollouts  │ │
│  └──────────┘   └────────────┘ │
│                                 │
│  ┌──────────────────────────┐  │
│  │    Canary Rollout        │  │
│  ├──────────────────────────┤  │
│  │ Stable:  ████████  80%   │  │
│  │ Canary:  ██        20%   │  │
│  └──────────────────────────┘  │
│                                 │
│  ┌────────┐     ┌────────┐     │
│  │ Stable │────▶│ Canary │     │
│  │ Service│     │Service │     │
│  └────────┘     └────────┘     │
└─────────────────────────────────┘
         │
         ↓
┌─────────────────┐
│  NGINX Ingress  │
│  (Traffic Split)│
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   End Users     │
│   (Browser)     │
└─────────────────┘
```

## ✨ Features

### Application
- ✅ Visual version indicators with distinct colors
- ✅ Real-time traffic distribution information
- ✅ Responsive design
- ✅ Health check endpoints
- ✅ Cache-busting for instant updates

### Deployment Strategy
- ✅ Progressive canary rollout (10% → 30% → 60% → 100%)
- ✅ Automated promotion
- ✅ Rollback on failure
- ✅ Traffic weight-based routing
- ✅ Zero-downtime deployments

### CI/CD
- ✅ Fully automated CI pipeline
- ✅ Separate CD pipeline
- ✅ Multi-arch Docker builds (amd64/arm64)
- ✅ Semantic versioning support
- ✅ Build provenance attestation
- ✅ Artifact management

## 📦 Prerequisites

### Infrastructure
- AWS EKS cluster (running and accessible)
- ArgoCD installed in the cluster (namespace: `argocd`)
- Argo Rollouts controller installed
- NGINX Ingress Controller installed

### Tools
- `kubectl` configured for your EKS cluster
- `aws-cli` configured with appropriate credentials
- Docker Hub account (or AWS ECR repository)

### GitHub Secrets
Configure the following secrets in your GitHub repository:

```bash
DOCKER_USERNAME          # Docker Hub username
DOCKER_PASSWORD          # Docker Hub password/token
AWS_ROLE_TO_ASSUME      # AWS IAM role ARN for GitHub OIDC
AWS_REGION              # AWS region (e.g., us-east-1)
EKS_CLUSTER_NAME        # Name of your EKS cluster
```

## 📁 Repository Structure

```
.
├── app/
│   ├── Dockerfile           # Container image definition
│   ├── index.html          # Application HTML page
│   └── nginx.conf          # NGINX configuration
├── k8s/
│   ├── rollout.yaml        # Argo Rollout manifest
│   ├── service.yaml        # Kubernetes services (stable + canary)
│   └── ingress.yaml        # Ingress configuration
├── argocd/
│   └── application.yaml    # ArgoCD Application manifest
├── .github/
│   └── workflows/
│       ├── ci.yml          # CI pipeline
│       └── cd.yml          # CD pipeline
└── README.md
```

## 🚀 Quick Start

### 1. Fork and Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/argo-rollout-deployment-demo.git
cd argo-rollout-deployment-demo
```

### 2. Configure Secrets

Add the required GitHub secrets via Settings → Secrets and variables → Actions.

### 3. Update Configuration

Edit the following files with your specific values:

**k8s/rollout.yaml**:
```yaml
image: YOUR_DOCKER_USERNAME/canary-demo:latest
```

**k8s/ingress.yaml**:
```yaml
host: your-domain.example.com  # Your domain or use LoadBalancer IP
```

**argocd/application.yaml**:
```yaml
repoURL: https://github.com/YOUR_USERNAME/argo-rollout-deployment-demo.git
```

### 4. Deploy ArgoCD Application

```bash
kubectl apply -f argocd/application.yaml
```

### 5. Trigger First Deployment

Push to main branch or manually trigger the CI workflow:

```bash
git commit --allow-empty -m "deploy: v1"
git push origin main
```

### 6. Access the Application

Get the application URL:

```bash
# Via LoadBalancer
kubectl get svc canary-demo-root -n default

# Via Ingress
kubectl get ingress canary-demo-ingress -n default
```

## 🔄 How It Works

### Traffic Splitting During Canary Rollout

When a new version is deployed, Argo Rollouts progressively shifts traffic:

1. **Initial State**: 100% traffic to stable (v1)
2. **Step 1**: 10% to canary (v2), 90% to stable (v1) - pause 30s
3. **Step 2**: 30% to canary (v2), 70% to stable (v1) - pause 30s
4. **Step 3**: 60% to canary (v2), 40% to stable (v1) - pause 30s
5. **Step 4**: 100% to canary (v2) - canary becomes stable

```
Time:     0s      30s     60s     90s     100s
         ────────────────────────────────────────
Stable:  ████████ ███████ ████    █       
Canary:           █       ███     ██████  ████████
Weight:  100%     90/10%  70/30%  40/60%  100%
```

### How Argo Rollouts Works

1. **Rollout CRD**: Extends Kubernetes Deployment with progressive delivery capabilities
2. **ReplicaSet Management**: Creates new ReplicaSet for canary while maintaining stable
3. **Traffic Shaping**: Updates NGINX Ingress annotations to control traffic weights
4. **Progressive Steps**: Follows defined steps with pauses and analysis
5. **Auto-Promotion**: Automatically promotes canary to stable after all steps succeed
6. **Rollback**: Can automatically rollback if analysis or health checks fail

## 🔧 CI/CD Pipeline

### CI Pipeline (`.github/workflows/ci.yml`)

**Triggers**:
- Push to `main` or `develop` branches
- Manual workflow dispatch

**Steps**:
1. Checkout code
2. Determine version from commit message or input
3. Setup Docker Buildx
4. Login to container registry
5. Build multi-arch image (amd64/arm64)
6. Tag with version and SHA
7. Push to registry
8. Generate provenance attestation
9. Upload metadata artifacts

**Version Detection**:
- Manual: Via workflow dispatch input
- Automatic: Extracted from commit message (e.g., `deploy: v2`)
- Default: `v1`

### CD Pipeline (`.github/workflows/cd.yml`)

**Triggers**:
- Successful completion of CI pipeline
- Manual workflow dispatch

**Steps**:
1. Download CI artifacts
2. Configure AWS credentials
3. Setup kubectl and ArgoCD CLI
4. Update kubeconfig for EKS
5. Update rollout manifest with new image
6. Commit and push changes
7. Login to ArgoCD
8. Sync ArgoCD application
9. Monitor rollout progress
10. Verify deployment
11. Output application URLs

### Pipeline Separation

- **CI**: Builds and publishes artifacts (container images)
- **CD**: Deploys artifacts to Kubernetes cluster
- **Communication**: Via artifacts and workflow triggers
- **Independence**: Each can be run separately

## 👀 Observing Canary Deployments

### Via Browser

1. Open the application URL in your browser
2. Note the current version and color
3. Deploy a new version (e.g., v2)
4. Refresh the page multiple times during rollout
5. Observe different versions appearing based on traffic weight

**Expected Behavior**:
- At 10% canary: ~1 in 10 refreshes shows new version
- At 30% canary: ~3 in 10 refreshes shows new version
- At 60% canary: ~6 in 10 refreshes shows new version
- At 100%: All refreshes show new version

### Via kubectl

```bash
# Watch rollout status
kubectl argo rollouts get rollout canary-demo-rollout -w

# Check rollout status
kubectl argo rollouts status canary-demo-rollout

# List rollout history
kubectl argo rollouts history canary-demo-rollout

# Get detailed rollout info
kubectl describe rollout canary-demo-rollout
```

### Via Argo Rollouts Dashboard

```bash
# Port forward to dashboard
kubectl argo rollouts dashboard

# Access at http://localhost:3100
```

### Via ArgoCD UI

```bash
# Port forward to ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login at https://localhost:8080
# Username: admin
# Password: (get from secret)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## ⚙️ Configuration

### Adjusting Canary Steps

Edit `k8s/rollout.yaml`:

```yaml
steps:
- setWeight: 10    # Change traffic percentages
- pause: {duration: 30s}  # Adjust pause duration
- setWeight: 50
- pause: {duration: 1m}
- setWeight: 100
```

### Changing Auto-Promotion

```yaml
autoPromotionEnabled: true     # Enable/disable
autoPromotionSeconds: 10       # Delay before promotion
```

### Adding Analysis

```yaml
steps:
- setWeight: 20
- pause: {duration: 30s}
- analysis:
    templates:
    - templateName: success-rate
    args:
    - name: service-name
      value: canary-demo-canary
```

### Using AWS ECR Instead of Docker Hub

1. Update `.github/workflows/ci.yml`:

```yaml
# Uncomment AWS ECR sections
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
    aws-region: ${{ env.AWS_REGION }}

- name: Login to Amazon ECR
  id: login-ecr
  uses: aws-actions/amazon-ecr-login@v2
```

2. Update `ECR_REPOSITORY` environment variable
3. Update image references in `k8s/rollout.yaml`

## 🐛 Troubleshooting

### Common Issues

#### 1. Rollout Stuck in Progressing

```bash
# Check rollout status
kubectl argo rollouts get rollout canary-demo-rollout

# Check pods
kubectl get pods -l app=canary-demo

# Check events
kubectl describe rollout canary-demo-rollout
```

#### 2. Traffic Not Splitting

```bash
# Check ingress annotations
kubectl get ingress canary-demo-ingress-canary -o yaml

# Verify NGINX ingress controller
kubectl get pods -n ingress-nginx

# Check service endpoints
kubectl get endpoints -l app=canary-demo
```

#### 3. ArgoCD Sync Issues

```bash
# Check application status
argocd app get canary-demo

# Force sync
argocd app sync canary-demo --force

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

#### 4. Image Pull Errors

```bash
# Verify image exists
docker pull YOUR_USERNAME/canary-demo:v1

# Check image pull secrets
kubectl get secrets

# Verify registry credentials
kubectl describe pod <pod-name>
```

### Debugging Commands

```bash
# Get all resources
kubectl get all -l app=canary-demo

# Check rollout analysis
kubectl argo rollouts get rollout canary-demo-rollout --watch

# View rollout events
kubectl get events --sort-by='.lastTimestamp' | grep canary-demo

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Test service connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- sh
# curl http://canary-demo-stable
# curl http://canary-demo-canary
```

## 🚀 Advanced Usage

### Manual Promotion

```bash
# Promote canary to stable
kubectl argo rollouts promote canary-demo-rollout
```

### Manual Rollback

```bash
# Abort rollout
kubectl argo rollouts abort canary-demo-rollout

# Rollback to previous version
kubectl argo rollouts undo canary-demo-rollout
```

### Deploying Specific Versions

```bash
# Via GitHub Actions
gh workflow run ci.yml -f version=v3

# Via kubectl
kubectl argo rollouts set image canary-demo-rollout \
  nginx=YOUR_USERNAME/canary-demo:v3
```

### Adding Metrics-Based Analysis

Create an AnalysisTemplate:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  metrics:
  - name: success-rate
    interval: 1m
    successCondition: result >= 0.95
    provider:
      prometheus:
        address: http://prometheus:9090
        query: |
          sum(rate(http_requests_total{status=~"2.."}[5m]))
          /
          sum(rate(http_requests_total[5m]))
```

### Blue-Green Deployment

Modify `k8s/rollout.yaml`:

```yaml
strategy:
  blueGreen:
    activeService: canary-demo-active
    previewService: canary-demo-preview
    autoPromotionEnabled: false
```

## 📚 Additional Resources

- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Canary Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#canary-pattern)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This project is licensed under the MIT License.

## 👏 Acknowledgments

- Argo Project for Rollouts and ArgoCD
- Kubernetes community
- NGINX team

---

**Happy Deploying! 🚀**

For questions or issues, please open a GitHub issue.
