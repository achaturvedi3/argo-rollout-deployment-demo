# Local Infrastructure Setup - Complete Guide

## 📦 What You Get

A complete local Kubernetes development environment with:

```
┌─────────────────────────────────────────────────────┐
│                  Local Machine                      │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │         Kind Cluster (Docker)                 │ │
│  │  ┌──────────────────────────────────────┐    │ │
│  │  │  Control Plane + 2 Worker Nodes      │    │ │
│  │  │  ┌────────────────┐                  │    │ │
│  │  │  │  ArgoCD        │  (GitOps)        │    │ │
│  │  │  └────────────────┘                  │    │ │
│  │  │  ┌────────────────┐                  │    │ │
│  │  │  │  Argo Rollouts │  (Canary)        │    │ │
│  │  │  └────────────────┘                  │    │ │
│  │  │  ┌────────────────┐                  │    │ │
│  │  │  │  NGINX Ingress │  (Traffic)       │    │ │
│  │  │  └────────────────┘                  │    │ │
│  │  │  ┌────────────────┐                  │    │ │
│  │  │  │  Your App      │  (Demo)          │    │ │
│  │  │  └────────────────┘                  │    │ │
│  │  └──────────────────────────────────────┘    │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  Ports: 8080 (HTTP), 8443 (HTTPS)                  │
└─────────────────────────────────────────────────────┘
         │                          │
    http://argocd.local:8080   http://canary-demo.local:8080
```

## 🚀 Quick Start (5 Minutes)

### 1. Prerequisites
```bash
# Verify you have these installed
docker --version      # Docker Desktop (must be running!)
kubectl version       # Kubernetes CLI
kind version          # Kind
helm version          # Helm (optional)
```

**Don't have them?**
```bash
# Install on macOS
brew install kubectl kind helm
# Download Docker Desktop from docker.com
```

### 2. Run Setup
```bash
cd local-setup
./setup-local-cluster.sh
```

**What happens:**
- ✅ Creates 3-node Kind cluster (1 control-plane, 2 workers)
- ✅ Installs NGINX Ingress Controller
- ✅ Installs Argo Rollouts
- ✅ Installs ArgoCD
- ✅ Connects your GitHub repository
- ✅ Deploys the demo application
- ✅ Sets up ingress routing
- ✅ Displays credentials

**Time:** ~3-5 minutes

### 3. Update /etc/hosts
```bash
sudo bash -c 'echo "127.0.0.1 argocd.local canary-demo.local" >> /etc/hosts'
```

### 4. Access Services
- **ArgoCD UI**: http://argocd.local:8080
- **Application**: http://canary-demo.local:8080
- **Credentials**: Check `argocd-credentials.txt`

## 📁 Directory Structure

```
local-setup/
├── setup-local-cluster.sh    # 🎯 Main setup script (START HERE)
├── status.sh                  # Check cluster health
├── cleanup.sh                 # Delete everything
├── restart.sh                 # Restart components
├── deploy-new-version.sh      # Deploy new app version
├── watch-rollout.sh           # Watch rollout progress
├── test-traffic.sh            # Test application traffic
├── argocd-ui.sh              # Access ArgoCD via port-forward
├── README.md                  # Full documentation
├── QUICK_REFERENCE.md         # Command cheat sheet
└── TROUBLESHOOTING.md         # Problem solving guide
```

## 🎯 Common Tasks

### Check Status
```bash
./status.sh
```
Shows health of all components, pods, services, and access info.

### Deploy New Version
```bash
./deploy-new-version.sh
# Enter new tag when prompted
# Watch automatic canary rollout
```

### Watch Canary Rollout
```bash
# Terminal 1: Watch rollout
./watch-rollout.sh

# Terminal 2: Generate traffic
./test-traffic.sh

# Terminal 3: Control rollout
kubectl argo rollouts promote canary-demo-rollout -n default
```

### Access ArgoCD
```bash
# Method 1: Using ingress
open http://argocd.local:8080

# Method 2: Port forwarding
./argocd-ui.sh
open http://localhost:8080
```

### View Logs
```bash
# Application logs
kubectl logs -n default -l app=canary-demo -f

# ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Rollout controller logs
kubectl logs -n argo-rollouts -l app.kubernetes.io/name=argo-rollouts -f
```

### Restart Everything
```bash
./restart.sh
```

### Delete Cluster
```bash
./cleanup.sh
```

## 🔧 Configuration

All scripts support environment variables:

```bash
# Custom cluster name
export CLUSTER_NAME="my-cluster"
./setup-local-cluster.sh

# Different GitHub repo
export GITHUB_REPO="https://github.com/yourorg/yourrepo.git"
./setup-local-cluster.sh

# Specific ArgoCD version
export ARGOCD_VERSION="v2.9.3"
./setup-local-cluster.sh
```

## 📊 Testing Canary Deployments

### Scenario 1: Auto Rollout
```bash
# Update k8s/rollout.yaml with new image
# Push to GitHub
# ArgoCD auto-syncs
# Canary automatically progresses: 10% → 30% → 60% → 100%
```

### Scenario 2: Manual Control
```bash
# Deploy new version
./deploy-new-version.sh

# Watch in separate terminals
./watch-rollout.sh    # Terminal 1
./test-traffic.sh     # Terminal 2

# Promote step by step
kubectl argo rollouts promote canary-demo-rollout -n default

# Or abort
kubectl argo rollouts abort canary-demo-rollout -n default
```

### Scenario 3: Full Promotion
```bash
# Deploy
./deploy-new-version.sh

# Skip all steps and promote immediately
kubectl argo rollouts promote canary-demo-rollout -n default --full
```

## 🐛 Troubleshooting

### Quick Fixes

**Can't access ArgoCD?**
```bash
# Check /etc/hosts
cat /etc/hosts | grep argocd

# Use port-forward instead
./argocd-ui.sh
```

**App not syncing?**
```bash
# Force sync
kubectl patch application canary-demo -n argocd --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

**Rollout stuck?**
```bash
kubectl argo rollouts promote canary-demo-rollout -n default --full
```

**Complete reset:**
```bash
./cleanup.sh && ./setup-local-cluster.sh
```

See **TROUBLESHOOTING.md** for detailed solutions.

## 📖 Learning Path

### Day 1: Setup and Explore
1. Run `./setup-local-cluster.sh`
2. Access ArgoCD UI
3. View the demo application
4. Explore rollout status
5. Read through ArgoCD application definition

### Day 2: Manual Deployments
1. Deploy new version with `./deploy-new-version.sh`
2. Watch canary rollout progress
3. Practice manual promotion
4. Practice aborting rollouts
5. Test traffic during rollout

### Day 3: GitOps Workflow
1. Modify k8s manifests
2. Push to GitHub
3. Watch ArgoCD auto-sync
4. Observe rollout behavior
5. Experiment with rollout strategy

### Day 4: Advanced Topics
1. Modify canary strategy (steps, weights, durations)
2. Add analysis templates
3. Configure health checks
4. Explore ArgoCD sync policies
5. Test failure scenarios

## 💡 Best Practices

1. **Always check status first**
   ```bash
   ./status.sh
   ```

2. **Monitor rollouts actively**
   ```bash
   ./watch-rollout.sh
   ```

3. **Test changes locally before pushing**
   - Make changes to manifests
   - Apply locally: `kubectl apply -f k8s/`
   - Verify behavior
   - Then push to GitHub

4. **Use descriptive commit messages**
   - ArgoCD shows these in the UI
   - Helps track what changed

5. **Save ArgoCD password immediately**
   - It's in `argocd-credentials.txt`
   - Or store in password manager

6. **Keep Docker Desktop running**
   - Allocate 4 CPUs and 8GB RAM
   - Cluster won't work if Docker stops

## 🔐 Security Notes

⚠️ **This is for LOCAL DEVELOPMENT ONLY**

- ArgoCD runs in insecure mode
- HTTP only (no TLS)
- Basic authentication only
- All services exposed
- **DO NOT USE IN PRODUCTION**

## 📚 Additional Resources

### Documentation
- [README.md](README.md) - Full setup guide
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Command cheat sheet
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problem solutions

### Official Docs
- [Kind](https://kind.sigs.k8s.io/)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/)

### Parent Project
- [Main README](../README.md)
- [Deployment Guide](../DEPLOYMENT_GUIDE.md)
- [Project Summary](../PROJECT_SUMMARY.md)

## 🆘 Need Help?

1. **Check status**: `./status.sh`
2. **Read troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. **Check logs**:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
   kubectl logs -n argo-rollouts -l app.kubernetes.io/name=argo-rollouts
   ```
4. **Reset everything**: `./cleanup.sh && ./setup-local-cluster.sh`

## ✅ Verification Checklist

After setup, verify:

- [ ] Kind cluster is running: `kind get clusters`
- [ ] Kubectl can connect: `kubectl cluster-info`
- [ ] ArgoCD UI accessible: http://argocd.local:8080
- [ ] Can login to ArgoCD with saved credentials
- [ ] Application is synced in ArgoCD
- [ ] Pods are running: `kubectl get pods -n default`
- [ ] Demo app accessible: http://canary-demo.local:8080
- [ ] Rollout exists: `kubectl get rollout -n default`
- [ ] Can watch rollout: `./watch-rollout.sh`

## 🎓 What You'll Learn

- ✅ Setting up local Kubernetes clusters with Kind
- ✅ Installing and configuring ArgoCD
- ✅ GitOps workflow and practices
- ✅ Canary deployment strategies
- ✅ Progressive delivery with Argo Rollouts
- ✅ Kubernetes ingress and routing
- ✅ Managing application lifecycles
- ✅ Troubleshooting Kubernetes applications
- ✅ Monitoring rollout progress
- ✅ Controlling deployment strategies

## 🚀 Next Steps

After successful setup:

1. ✅ Explore ArgoCD UI
2. ✅ View application sync status
3. ✅ Test the demo application
4. ✅ Deploy a new version
5. ✅ Watch canary rollout
6. ✅ Practice manual promotion/abort
7. ✅ Modify manifests and push changes
8. ✅ Experiment with rollout strategies
9. ✅ Add your own applications
10. ✅ Build your GitOps workflow

---

**Ready to start?**

```bash
cd local-setup
./setup-local-cluster.sh
```

**Happy testing!** 🎉
