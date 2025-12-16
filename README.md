# Argo Rollout Deployment Demo

A complete demonstration of canary deployments using Argo Rollouts, ArgoCD, and GitHub Actions on AWS EKS.

## 🚀 Overview

This repository showcases a production-ready CI/CD pipeline that implements:
- **Nginx-based web application** with visual canary deployment tracking
- **Automated CI pipeline** for building and pushing Docker images
- **Automated CD pipeline** using ArgoCD for GitOps-based deployments
- **Canary deployment strategy** with Argo Rollouts on AWS EKS
- **Progressive traffic shifting** (20% → 40% → 60% → 80% → 100%)

## 📋 Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [CI/CD Pipeline](#cicd-pipeline)
- [Canary Deployment](#canary-deployment)
- [Monitoring Deployments](#monitoring-deployments)
- [Troubleshooting](#troubleshooting)

## 🏗️ Architecture

```
GitHub Repository
    ↓
CI Pipeline (GitHub Actions)
    ↓
Build Docker Image → Push to Docker Hub
    ↓
CD Pipeline (GitHub Actions)
    ↓
Update K8s Manifests → Trigger ArgoCD Sync
    ↓
ArgoCD (on EKS)
    ↓
Argo Rollouts Controller
    ↓
Progressive Canary Deployment (20% → 40% → 60% → 80% → 100%)
    ↓
AWS EKS Cluster
```

## 📦 Prerequisites

### AWS Resources
- **AWS EKS Cluster** (recommended: 2-3 worker nodes, t3.medium or larger)
- **AWS CLI** configured with appropriate credentials
- **kubectl** configured to access your EKS cluster

### Kubernetes Components
- **Argo Rollouts Controller** installed in the cluster
- **ArgoCD** installed in the cluster
- **AWS Load Balancer Controller** (optional, for Ingress)

### GitHub Secrets
Configure the following secrets in your GitHub repository:

| Secret Name | Description |
|-------------|-------------|
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub password or access token |
| `AWS_ACCESS_KEY_ID` | AWS access key for EKS access |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for EKS access |
| `ARGOCD_SERVER` | ArgoCD server URL (e.g., `argocd.example.com`) |
| `ARGOCD_AUTH_TOKEN` | ArgoCD authentication token |

## 🛠️ Setup Instructions

### 1. Create EKS Cluster

```bash
# Create EKS cluster using eksctl
eksctl create cluster \
  --name argo-demo-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

# Configure kubectl
aws eks update-kubeconfig --name argo-demo-cluster --region us-east-1
```

### 2. Install Argo Rollouts

```bash
# Create namespace
kubectl create namespace argo-rollouts

# Install Argo Rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Install Argo Rollouts kubectl plugin
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Verify installation
kubectl argo rollouts version
```

### 3. Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Expose ArgoCD server (for external access)
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Get ArgoCD server URL
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 4. Configure ArgoCD

```bash
# Login to ArgoCD CLI
argocd login <ARGOCD_SERVER> --username admin --password <PASSWORD>

# Create ArgoCD application
kubectl apply -f argocd/application.yaml

# Generate auth token for GitHub Actions
argocd account generate-token --account admin
```

### 5. Configure GitHub Secrets

1. Go to your GitHub repository → Settings → Secrets and variables → Actions
2. Add all the required secrets listed in the [Prerequisites](#prerequisites) section

### 6. Deploy the Application

```bash
# Simply push to main branch to trigger CI/CD pipeline
git add .
git commit -m "Initial deployment"
git push origin main

# Or manually apply the manifests
kubectl apply -f k8s/
```

## 🔄 CI/CD Pipeline

### CI Pipeline (`ci.yaml`)
Triggers on push to `main` branch when these files change:
- `index.html`
- `Dockerfile`
- `.github/workflows/ci.yaml`

**Steps:**
1. Checkout code
2. Set up Docker Buildx
3. Login to Docker Hub
4. Generate version tag (based on git SHA)
5. Build Docker image with version
6. Push to Docker Hub
7. Trigger CD pipeline

### CD Pipeline (`cd.yaml`)
Triggers automatically after successful CI pipeline

**Steps:**
1. Get latest image tag
2. Update Kubernetes manifests with new image
3. Configure AWS credentials
4. Update kubeconfig for EKS access
5. Commit updated manifests to Git
6. Login to ArgoCD
7. Sync ArgoCD application
8. Monitor rollout status

## 🐤 Canary Deployment

The Argo Rollout strategy implements a progressive canary deployment:

```yaml
steps:
  - setWeight: 20   # 20% traffic to new version
  - pause: {duration: 30s}
  - setWeight: 40   # 40% traffic to new version
  - pause: {duration: 30s}
  - setWeight: 60   # 60% traffic to new version
  - pause: {duration: 30s}
  - setWeight: 80   # 80% traffic to new version
  - pause: {duration: 30s}
  - setWeight: 100  # 100% traffic to new version
```

### How to Test Canary Deployment

1. **Deploy initial version:**
   ```bash
   # Version will be automatically set from CI pipeline
   git push origin main
   ```

2. **Make a change to trigger new version:**
   ```bash
   # Edit index.html with a new message
   git add index.html
   git commit -m "Update to v1.0.1"
   git push origin main
   ```

3. **Watch the rollout:**
   ```bash
   kubectl argo rollouts get rollout nginx-rollout-demo --watch
   ```

4. **Access the application:**
   ```bash
   # Get the service URL
   kubectl get svc nginx-rollout-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

5. **During deployment, refresh the webpage multiple times** to see different versions based on traffic distribution

## 📊 Monitoring Deployments

### View Rollout Status

```bash
# Get rollout status
kubectl argo rollouts get rollout nginx-rollout-demo

# Watch rollout progress
kubectl argo rollouts get rollout nginx-rollout-demo --watch

# View rollout history
kubectl argo rollouts history nginx-rollout-demo
```

### ArgoCD UI

```bash
# Access ArgoCD UI
# Navigate to the LoadBalancer URL obtained during setup
# Login with admin credentials
```

### Rollout Dashboard (Optional)

```bash
# Install Argo Rollouts Dashboard
kubectl argo rollouts dashboard

# Access at http://localhost:3100
```

### Manually Control Rollout

```bash
# Promote rollout to next step
kubectl argo rollouts promote nginx-rollout-demo

# Abort rollout
kubectl argo rollouts abort nginx-rollout-demo

# Retry rollout
kubectl argo rollouts retry nginx-rollout-demo

# Rollback to previous version
kubectl argo rollouts undo nginx-rollout-demo
```

## 🔍 Troubleshooting

### Pipeline Issues

```bash
# Check GitHub Actions logs
# Go to Actions tab in GitHub repository

# Check if secrets are configured
# Settings → Secrets and variables → Actions
```

### ArgoCD Issues

```bash
# Check ArgoCD application status
argocd app get nginx-rollout-demo

# Check ArgoCD application logs
kubectl logs -n argocd deployment/argocd-server

# Sync manually
argocd app sync nginx-rollout-demo
```

### Rollout Issues

```bash
# Check rollout status
kubectl argo rollouts get rollout nginx-rollout-demo

# Check rollout events
kubectl describe rollout nginx-rollout-demo

# Check pod logs
kubectl logs -l app=nginx-rollout-demo

# Check replica sets
kubectl get rs -l app=nginx-rollout-demo
```

### Image Pull Issues

```bash
# Check if image exists in Docker Hub
# Verify DOCKER_USERNAME and DOCKER_PASSWORD secrets

# Check pod events
kubectl describe pod <pod-name>
```

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── ci.yaml              # CI pipeline for building Docker images
│       └── cd.yaml              # CD pipeline for deploying to EKS
├── argocd/
│   └── application.yaml         # ArgoCD Application manifest
├── k8s/
│   ├── rollout.yaml            # Argo Rollout with canary strategy
│   ├── service.yaml            # Kubernetes Service
│   └── ingress.yaml            # Kubernetes Ingress (optional)
├── Dockerfile                   # Multi-stage Docker build
├── index.html                   # Nginx application with version display
└── README.md                    # This file
```

## 🎯 Key Features

- ✅ **Progressive Canary Deployments** - Gradual traffic shifting with automatic rollback
- ✅ **GitOps Workflow** - ArgoCD syncs from Git repository
- ✅ **Automated CI/CD** - Fully automated from code commit to production
- ✅ **Version Visualization** - Web UI clearly shows current version
- ✅ **Health Checks** - Readiness and liveness probes
- ✅ **Auto-scaling Ready** - Resource limits and requests configured
- ✅ **AWS EKS Optimized** - Configured for EKS best practices

## 🔐 Security Considerations

- Store all sensitive data in GitHub Secrets
- Use IAM roles for service accounts (IRSA) for production
- Enable Pod Security Standards
- Use private Docker registries for production
- Implement network policies
- Enable audit logging

## 📝 Version Management

Versions are automatically generated using the format: `v1.0.<git-short-sha>`

Example: `v1.0.abc1234`

This ensures unique versions for every deployment and easy tracking.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open-source and available under the MIT License.

## 🙏 Acknowledgments

- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [Argo CD](https://argoproj.github.io/argo-cd/)
- [AWS EKS](https://aws.amazon.com/eks/)
- [GitHub Actions](https://github.com/features/actions)

## 📧 Support

For issues and questions:
- Open an issue in this repository
- Check the [troubleshooting](#troubleshooting) section
- Review Argo Rollouts and ArgoCD documentation

---

**Happy Deploying! 🚀**