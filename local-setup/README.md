# Local Development Infrastructure Setup

This directory contains scripts to set up a complete local Kubernetes environment with ArgoCD and Argo Rollouts for testing canary deployments.

## 🎯 What Gets Installed

- **Kind Cluster**: 3-node local Kubernetes cluster (1 control-plane, 2 workers)
- **NGINX Ingress Controller**: For local ingress support
- **Argo Rollouts**: Progressive delivery controller
- **ArgoCD**: GitOps continuous delivery tool
- **GitHub Repository Connection**: Your repository connected to ArgoCD
- **Demo Application**: Automatically deployed via ArgoCD

## 📋 Prerequisites

Before running the setup, ensure you have these tools installed:

### Required Tools
```bash
# Docker Desktop (must be running)
# Download from: https://www.docker.com/products/docker-desktop

# kubectl
brew install kubectl

# Kind (Kubernetes in Docker)
brew install kind

# Optional but recommended
brew install helm
brew install argoproj/tap/kubectl-argo-rollouts
brew install argocd  # ArgoCD CLI
```

### System Requirements
- macOS (Intel or Apple Silicon)
- 8GB RAM minimum (16GB recommended)
- 20GB free disk space
- Docker Desktop with at least 4GB memory allocated

## 🚀 Quick Start

### 1. Run the Setup Script
```bash
cd local-setup
chmod +x *.sh
./setup-local-cluster.sh
```

The script will:
1. ✅ Check all prerequisites
2. ✅ Create a 3-node Kind cluster
3. ✅ Install NGINX Ingress Controller
4. ✅ Install Argo Rollouts
5. ✅ Install ArgoCD
6. ✅ Configure GitHub repository
7. ✅ Create ArgoCD application
8. ✅ Expose services via ingress
9. ✅ Display access credentials

### 2. Update /etc/hosts

Add these entries to your `/etc/hosts` file:
```bash
sudo bash -c 'echo "127.0.0.1 argocd.local canary-demo.local" >> /etc/hosts'
```

### 3. Access ArgoCD UI

Open your browser and navigate to:
- **URL**: http://argocd.local:8080
- **Username**: `admin`
- **Password**: See `argocd-credentials.txt` or run:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

### 4. Access the Application

Once ArgoCD deploys the application:
- **URL**: http://canary-demo.local:8080

## 📜 Available Scripts

### Setup and Configuration
```bash
# Initial setup - creates entire infrastructure
./setup-local-cluster.sh

# Check cluster and component status
./status.sh

# Restart all cluster components
./restart.sh

# Delete the entire cluster
./cleanup.sh
```

### Application Management
```bash
# Deploy a new version of the application
./deploy-new-version.sh

# Watch rollout progress
./watch-rollout.sh

# Test application traffic
./test-traffic.sh
```

### ArgoCD Access
```bash
# Access ArgoCD UI via port-forward (alternative to ingress)
./argocd-ui.sh
# Then open: http://localhost:8080
```

## 🔧 Customization

### Change Cluster Name
```bash
export CLUSTER_NAME="my-custom-cluster"
./setup-local-cluster.sh
```

### Use Different GitHub Repository
```bash
export GITHUB_REPO="https://github.com/your-org/your-repo.git"
./setup-local-cluster.sh
```

### Specify ArgoCD Version
```bash
export ARGOCD_VERSION="v2.9.3"
./setup-local-cluster.sh
```

## 📊 Monitoring and Observability

### Watch Rollout Status
```bash
# Using the script
./watch-rollout.sh

# Or directly
kubectl argo rollouts get rollout canary-demo-rollout -n default --watch
```

### View Application Logs
```bash
# All pods
kubectl logs -n default -l app=canary-demo -f

# Specific pod
kubectl logs -n default <pod-name> -f
```

### Check ArgoCD Sync Status
```bash
# Using ArgoCD CLI
argocd login argocd.local:8080 --insecure
argocd app list
argocd app get canary-demo
argocd app sync canary-demo

# Using kubectl
kubectl get applications -n argocd
kubectl describe application canary-demo -n argocd
```

## 🧪 Testing Canary Deployments

### 1. Update Application Image
```bash
# Method 1: Use the deploy script
./deploy-new-version.sh

# Method 2: Manually update
kubectl argo rollouts set image canary-demo-rollout \
  -n default \
  nginx=your-registry/canary-demo:v2.0.0
```

### 2. Watch Traffic Distribution
```bash
# Terminal 1: Watch rollout
./watch-rollout.sh

# Terminal 2: Generate traffic
./test-traffic.sh
```

### 3. Control Rollout
```bash
# Promote to next step
kubectl argo rollouts promote canary-demo-rollout -n default

# Full promotion
kubectl argo rollouts promote canary-demo-rollout -n default --full

# Abort rollout
kubectl argo rollouts abort canary-demo-rollout -n default

# Restart rollout
kubectl argo rollouts restart canary-demo-rollout -n default
```

## 🔍 Troubleshooting

### Cluster Won't Start
```bash
# Check Docker is running
docker info

# Delete and recreate cluster
kind delete cluster --name argo-rollouts-demo
./setup-local-cluster.sh
```

### Can't Access ArgoCD UI
```bash
# Check /etc/hosts
cat /etc/hosts | grep argocd

# Use port-forward instead
./argocd-ui.sh
# Then access: http://localhost:8080

# Check ingress
kubectl get ingress -n argocd
kubectl describe ingress argocd-server-ingress -n argocd
```

### ArgoCD App Not Syncing
```bash
# Check application status
kubectl get application canary-demo -n argocd
kubectl describe application canary-demo -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Manual sync
kubectl patch application canary-demo -n argocd --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

### Rollout Stuck
```bash
# Check rollout status
kubectl argo rollouts get rollout canary-demo-rollout -n default

# Check pod status
kubectl get pods -n default -l app=canary-demo

# Check events
kubectl get events -n default --sort-by='.lastTimestamp'

# Abort and restart
kubectl argo rollouts abort canary-demo-rollout -n default
kubectl argo rollouts restart canary-demo-rollout -n default
```

### Ingress Not Working
```bash
# Check NGINX ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Check ingress resources
kubectl get ingress -n default
kubectl describe ingress canary-demo-ingress -n default

# Test with port-forward
kubectl port-forward svc/canary-demo-stable -n default 8080:80
# Then: curl http://localhost:8080
```

### Reset Everything
```bash
# Complete cleanup and restart
./cleanup.sh
./setup-local-cluster.sh
```

## 📖 Understanding the Setup

### Cluster Architecture
```
┌─────────────────────────────────────────┐
│         Kind Cluster (Docker)           │
├─────────────────────────────────────────┤
│  ┌─────────────┐  ┌────────┐           │
│  │ Control     │  │ Worker │           │
│  │ Plane       │  │ Node 1 │           │
│  └─────────────┘  └────────┘           │
│                   ┌────────┐            │
│                   │ Worker │            │
│                   │ Node 2 │            │
│                   └────────┘            │
└─────────────────────────────────────────┘
         │                    │
    Port 8080            Port 8443
         │                    │
    ┌────▼────────────────────▼────┐
    │     Your Local Machine        │
    │  http://argocd.local:8080     │
    │  http://canary-demo.local:8080│
    └───────────────────────────────┘
```

### Component Interactions
```
GitHub Repo ─────► ArgoCD ─────► Kubernetes Manifests
                     │
                     ├─────► Rollout Resource
                     │
                     └─────► Services & Ingress
                               │
                               ▼
                          NGINX Ingress
                               │
                               ▼
                         Your Browser
```

## 🔐 Security Notes

⚠️ **Important**: This setup is for LOCAL DEVELOPMENT ONLY

- ArgoCD runs in insecure mode (no TLS)
- No authentication beyond basic admin login
- All services exposed via HTTP (no HTTPS)
- Not suitable for production use

## 🧹 Cleanup

### Remove Everything
```bash
# Delete cluster and all resources
./cleanup.sh

# Remove /etc/hosts entries (optional)
sudo sed -i '' '/argocd.local\|canary-demo.local/d' /etc/hosts

# Remove saved credentials
rm -f argocd-credentials.txt
```

## 📚 Additional Resources

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

## 💡 Tips and Best Practices

1. **Always check status before making changes**
   ```bash
   ./status.sh
   ```

2. **Use watch mode to monitor rollouts**
   ```bash
   ./watch-rollout.sh
   ```

3. **Test changes in the local cluster first**
   - Make changes to k8s manifests
   - Push to GitHub
   - Watch ArgoCD auto-sync
   - Verify rollout behavior

4. **Save ArgoCD password immediately**
   - It's in `argocd-credentials.txt`
   - Or get it from the secret before it expires

5. **Use ArgoCD UI for visual monitoring**
   - Better than CLI for understanding app state
   - Real-time sync status
   - Visual diff of changes

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Run `./status.sh` to see component health
3. Check logs:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
   kubectl logs -n argo-rollouts -l app.kubernetes.io/name=argo-rollouts
   ```
4. Review Kind cluster logs:
   ```bash
   kind get logs --name argo-rollouts-demo
   ```

## 📝 Next Steps

After successful setup:

1. ✅ Explore ArgoCD UI at http://argocd.local:8080
2. ✅ View the canary-demo application sync status
3. ✅ Access the app at http://canary-demo.local:8080
4. ✅ Try deploying a new version with `./deploy-new-version.sh`
5. ✅ Watch the canary rollout in action
6. ✅ Experiment with manual promotion/abort
7. ✅ Make changes to k8s manifests and push to GitHub
8. ✅ Watch ArgoCD auto-sync your changes

Happy testing! 🚀
