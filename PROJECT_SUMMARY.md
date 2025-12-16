# Project Summary: Argo Rollout Deployment Demo

## What Has Been Created

This repository now contains a **complete, production-ready CI/CD pipeline** for demonstrating canary deployments using Argo Rollouts on AWS EKS.

## 📦 Deliverables

### 1. Application Files
- **`index.html`**: Beautiful, responsive web page that visualizes canary rollout
  - Shows current version prominently
  - Auto-refreshes every 5 seconds to show version changes
  - Explains canary deployment strategy
  - Displays deployment information
  
- **`Dockerfile`**: Optimized nginx-based container
  - Uses nginx:alpine for minimal size
  - Accepts VERSION build argument
  - Includes health check endpoint at `/health`
  - Configured for production use

### 2. Kubernetes Manifests (`k8s/`)
- **`rollout.yaml`**: Argo Rollout resource with canary strategy
  - Progressive traffic shifting: 20% → 40% → 60% → 80% → 100%
  - 30-second pause between each step
  - 4 replicas for high availability
  - Resource limits and requests configured
  - Health probes configured
  
- **`service.yaml`**: LoadBalancer service
  - Exposes the application on port 80
  - AWS EKS compatible
  
- **`ingress.yaml`**: Optional Ingress resource
  - Configured for AWS ALB Ingress Controller
  - Health check path configured

### 3. ArgoCD Configuration (`argocd/`)
- **`application.yaml`**: ArgoCD Application manifest
  - Points to k8s/ directory in this repository
  - Automated sync enabled
  - Self-healing enabled
  - Prune enabled for cleanup

### 4. CI/CD Pipelines (`.github/workflows/`)

#### **CI Pipeline** (`ci.yaml`)
- **Triggers**: On push to main branch (when Dockerfile or index.html changes)
- **Actions**:
  1. Builds Docker image with version tag
  2. Pushes to Docker Hub
  3. Uses caching for faster builds
  4. Generates semantic version from git SHA

#### **CD Pipeline** (`cd.yaml`)
- **Triggers**: After successful CI pipeline completion
- **Actions**:
  1. Updates Kubernetes manifests with new image tag
  2. Commits changes back to repository
  3. Configures AWS credentials
  4. Updates kubeconfig for EKS
  5. Logs into ArgoCD
  6. Syncs ArgoCD application
  7. Waits for deployment to complete
  8. Shows rollout status

### 5. Documentation
- **`README.md`**: Comprehensive documentation
  - Architecture overview
  - Prerequisites
  - Setup instructions
  - CI/CD pipeline details
  - Canary deployment explanation
  - Monitoring commands
  - Troubleshooting guide
  
- **`DEPLOYMENT_GUIDE.md`**: Step-by-step deployment guide
  - Quick start instructions
  - Detailed setup for each component
  - Testing canary deployment
  - Useful commands
  - Cleanup instructions
  - Troubleshooting common issues

### 6. Configuration Files
- **`.gitignore`**: Excludes build artifacts and temporary files

## 🔄 How It Works

### The Complete Flow

```
1. Developer pushes code change to main branch
   ↓
2. GitHub Actions CI Pipeline triggers
   ↓
3. Docker image is built with new version tag (v1.0.<git-sha>)
   ↓
4. Image is pushed to Docker Hub
   ↓
5. GitHub Actions CD Pipeline triggers automatically
   ↓
6. CD pipeline updates k8s/rollout.yaml with new image tag
   ↓
7. Changes are committed and pushed to repository
   ↓
8. CD pipeline logs into ArgoCD and triggers sync
   ↓
9. ArgoCD detects changes in Git and applies them to cluster
   ↓
10. Argo Rollouts Controller starts canary deployment
    ↓
11. Traffic is progressively shifted:
    - 20% to new version (30s pause)
    - 40% to new version (30s pause)
    - 60% to new version (30s pause)
    - 80% to new version (30s pause)
    - 100% to new version
    ↓
12. Old pods are terminated
    ↓
13. Deployment complete! ✅
```

## 🎯 Key Features

### Canary Deployment Visualization
- Users can refresh the webpage during deployment
- See both old and new versions based on traffic distribution
- Version badge clearly shows which version is serving the request

### Fully Automated
- Zero manual intervention required
- Commit → Build → Deploy → Monitor
- Self-healing with ArgoCD

### AWS EKS Ready
- Configured for AWS Load Balancer Controller
- EKS-compatible Service and Ingress
- IAM role integration ready

### Production Best Practices
- Health checks configured
- Resource limits set
- Multi-replica deployment
- Gradual rollout for safety
- Automatic rollback capability

## 📋 Required GitHub Secrets

For the pipelines to work, configure these secrets:

| Secret | Purpose |
|--------|---------|
| `DOCKER_USERNAME` | Docker Hub login |
| `DOCKER_PASSWORD` | Docker Hub authentication |
| `AWS_ACCESS_KEY_ID` | AWS access for EKS |
| `AWS_SECRET_ACCESS_KEY` | AWS secret for EKS |
| `ARGOCD_SERVER` | ArgoCD server URL |
| `ARGOCD_AUTH_TOKEN` | ArgoCD authentication |

## 🚀 Quick Start

### For First-Time Setup:
1. Follow `DEPLOYMENT_GUIDE.md` for complete setup
2. Create EKS cluster
3. Install Argo Rollouts
4. Install ArgoCD
5. Configure GitHub Secrets
6. Push code to trigger deployment

### For Subsequent Deployments:
1. Make changes to `index.html` or code
2. Commit and push to main branch
3. Watch GitHub Actions run
4. Monitor rollout with: `kubectl argo rollouts get rollout nginx-rollout-demo --watch`
5. Access application at LoadBalancer URL

## 📊 Monitoring Deployments

### During Deployment
```bash
# Watch rollout progress
kubectl argo rollouts get rollout nginx-rollout-demo --watch

# Watch pods
kubectl get pods -l app=nginx-rollout-demo --watch

# Access application and refresh to see version changes
curl http://<LOADBALANCER_URL>/
```

### Manual Control
```bash
# Promote to next step
kubectl argo rollouts promote nginx-rollout-demo

# Abort if issues detected
kubectl argo rollouts abort nginx-rollout-demo

# Rollback to previous version
kubectl argo rollouts undo nginx-rollout-demo
```

## ✅ Testing Checklist

To verify the complete system:

- [ ] EKS cluster created and accessible
- [ ] Argo Rollouts installed and running
- [ ] ArgoCD installed and accessible
- [ ] GitHub Secrets configured
- [ ] CI pipeline runs successfully
- [ ] Docker image pushed to registry
- [ ] CD pipeline runs successfully
- [ ] ArgoCD application synced
- [ ] Rollout progresses through canary stages
- [ ] Application accessible via LoadBalancer
- [ ] Version displayed correctly in webpage
- [ ] New deployment triggers canary rollout
- [ ] Traffic distribution visible during deployment

## 🔧 Customization Options

### Adjust Canary Steps
Edit `k8s/rollout.yaml` to change traffic percentages or pause durations:
```yaml
steps:
- setWeight: 10  # Start with 10% instead of 20%
- pause: {duration: 60s}  # Wait 60 seconds instead of 30
```

### Change Number of Replicas
Edit `k8s/rollout.yaml`:
```yaml
spec:
  replicas: 6  # Increase to 6 replicas
```

### Modify Application Content
Edit `index.html` to customize the webpage appearance and information.

### Use Different Container Registry
Update `.github/workflows/ci.yaml` to use ECR or another registry.

## 📈 Scaling and Production Considerations

For production use, consider:
1. **Use ECR instead of Docker Hub** for private images
2. **Implement IRSA** (IAM Roles for Service Accounts)
3. **Add analysis** to Argo Rollouts for automated decisions
4. **Set up monitoring** with Prometheus and Grafana
5. **Configure alerts** for deployment failures
6. **Use blue-green** strategy for zero-downtime
7. **Add multiple environments** (dev, staging, prod)
8. **Implement proper secrets management** (AWS Secrets Manager)

## 🎓 Learning Outcomes

By using this project, you will understand:
- GitOps workflow with ArgoCD
- Canary deployment strategy
- Progressive delivery with Argo Rollouts
- CI/CD automation with GitHub Actions
- Container orchestration on Kubernetes
- AWS EKS cluster management
- Docker image building and versioning
- Infrastructure as Code principles

## 🤝 Contributing

To contribute:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📚 Additional Resources

- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**This project is now ready for deployment!** 🎉

Follow the `DEPLOYMENT_GUIDE.md` for step-by-step instructions.
