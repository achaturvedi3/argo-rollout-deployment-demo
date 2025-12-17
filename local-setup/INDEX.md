# Local Setup - File Index

## 📂 Complete File List

### 🚀 Main Setup Script
- **`setup-local-cluster.sh`** - Complete automated setup (START HERE!)
  - Creates Kind cluster with 3 nodes
  - Installs NGINX Ingress, ArgoCD, Argo Rollouts
  - Connects GitHub repository
  - Deploys demo application
  - **Usage**: `./setup-local-cluster.sh`

### ✅ Pre-flight Check
- **`preflight-check.sh`** - Verify prerequisites before setup
  - Checks Docker, kubectl, kind installation
  - Verifies Docker is running
  - Checks port availability
  - Tests internet connectivity
  - **Usage**: `./preflight-check.sh`

### 🔧 Management Scripts
- **`status.sh`** - Check cluster and component health
  - Shows all pods, services, ingresses
  - Displays ArgoCD credentials
  - Lists quick commands
  - **Usage**: `./status.sh`

- **`restart.sh`** - Restart all cluster components
  - Restarts ArgoCD, Argo Rollouts, NGINX Ingress
  - Useful after configuration changes
  - **Usage**: `./restart.sh`

- **`cleanup.sh`** - Delete entire cluster
  - Removes Kind cluster
  - Cleans up credentials file
  - Provides instructions for /etc/hosts cleanup
  - **Usage**: `./cleanup.sh`

### 📦 Application Management
- **`deploy-new-version.sh`** - Deploy new application version
  - Interactive script for version updates
  - Updates rollout image
  - Watches deployment progress
  - **Usage**: `./deploy-new-version.sh`

- **`watch-rollout.sh`** - Watch rollout progress
  - Real-time rollout status
  - Shows canary weight distribution
  - Displays step progression
  - **Usage**: `./watch-rollout.sh`

- **`test-traffic.sh`** - Generate test traffic
  - Continuous HTTP requests to application
  - Shows version responses
  - Useful during canary rollout
  - **Usage**: `./test-traffic.sh [URL] [interval]`

### 🌐 Access Scripts
- **`argocd-ui.sh`** - Access ArgoCD via port-forward
  - Alternative to ingress access
  - Displays credentials
  - Port-forwards to localhost:8080
  - **Usage**: `./argocd-ui.sh`

### 🎁 Helm Deployment Scripts
- **`helm-deploy.sh`** - Deploy application using Helm chart
  - Creates local values file
  - Validates and deploys chart
  - Sets up ingress
  - **Usage**: `./helm-deploy.sh`

- **`helm-upgrade.sh`** - Upgrade Helm deployment
  - Multiple upgrade options
  - Image tag updates
  - Values file changes
  - **Usage**: `./helm-upgrade.sh`

- **`helm-status.sh`** - Check Helm deployment status
  - Release information
  - Rollout status
  - Resource details
  - **Usage**: `./helm-status.sh`

- **`helm-rollback.sh`** - Rollback Helm deployment
  - View release history
  - Rollback to any revision
  - **Usage**: `./helm-rollback.sh`

- **`helm-uninstall.sh`** - Remove Helm deployment
  - Safe uninstall with confirmation
  - Cleanup verification
  - **Usage**: `./helm-uninstall.sh`

### 📚 Documentation
- **`GETTING_STARTED.md`** - Quick start guide
  - Overview of entire setup
  - 5-minute quick start
  - Common tasks
  - Learning path

- **`README.md`** - Complete documentation
  - Detailed setup instructions
  - Prerequisites and requirements
  - All scripts explained
  - Troubleshooting basics

- **`QUICK_REFERENCE.md`** - Command cheat sheet
  - Essential commands
  - Debugging commands
  - Rollout control
  - Access information

- **`TROUBLESHOOTING.md`** - Problem-solving guide
  - Common issues and solutions
  - Debugging strategies
  - Reset procedures
  - Getting help resources

- **`HELM_GUIDE.md`** - Helm deployment guide
  - Helm-based deployment
  - Upgrade and rollback
  - Configuration management
  - Testing workflows

## 📋 Quick Start Workflow

```bash
# 1. Check prerequisites
./preflight-check.sh

# 2. Run setup (creates everything)
./setup-local-cluster.sh

# 3. Add to /etc/hosts
sudo bash -c 'echo "127.0.0.1 argocd.local canary-demo.local" >> /etc/hosts'

# 4. Check status
./status.sh

# 5. Access ArgoCD
open http://argocd.local:8080

# 6. Deploy new version
./deploy-new-version.sh

# 7. Watch rollout
./watch-rollout.sh
```

## 🎯 Script Categories

### Installation & Setup
- `preflight-check.sh` - Pre-installation checks
- `setup-local-cluster.sh` - Main installation

### Status & Monitoring
- `status.sh` - Overall health check
- `watch-rollout.sh` - Rollout monitoring
- `test-traffic.sh` - Traffic testing

### Management & Control
- `deploy-new-version.sh` - Version deployment
- `restart.sh` - Component restart
- `cleanup.sh` - Full cleanup

### Access & UI
- `argocd-ui.sh` - ArgoCD access

### Helm Deployment
- `helm-deploy.sh` - Deploy with Helm
- `helm-upgrade.sh` - Upgrade deployment
- `helm-status.sh` - Check Helm status
- `helm-rollback.sh` - Rollback deployment
- `helm-uninstall.sh` - Remove deployment

### Documentation
- `GETTING_STARTED.md` - Quick start
- `README.md` - Complete guide
- `QUICK_REFERENCE.md` - Command reference
- `TROUBLESHOOTING.md` - Problem solving

## 🔄 Common Workflows

### Initial Setup
```bash
./preflight-check.sh      # Check prerequisites
./setup-local-cluster.sh  # Install everything
./status.sh               # Verify installation
```

### Daily Development
```bash
./status.sh                    # Check health
./deploy-new-version.sh        # Deploy changes
./watch-rollout.sh             # Monitor deployment
```

### Troubleshooting
```bash
./status.sh                    # Check status
# Read TROUBLESHOOTING.md
./restart.sh                   # Try restart
./cleanup.sh                   # Last resort
./setup-local-cluster.sh       # Reinstall
```

### Testing Canary
```bash
# Terminal 1
./watch-rollout.sh

# Terminal 2
./test-traffic.sh

# Terminal 3
kubectl argo rollouts promote canary-demo-rollout -n default
```

## 📊 File Sizes

```
setup-local-cluster.sh    ~11KB  (main setup script)
preflight-check.sh        ~6KB   (prerequisite checker)
README.md                 ~19KB  (complete documentation)
TROUBLESHOOTING.md        ~16KB  (problem solutions)
GETTING_STARTED.md        ~13KB  (quick start guide)
QUICK_REFERENCE.md        ~6KB   (command reference)
status.sh                 ~3KB   (status checker)
deploy-new-version.sh     ~1.5KB (deployment script)
watch-rollout.sh          ~800B  (rollout watcher)
test-traffic.sh           ~1KB   (traffic tester)
argocd-ui.sh             ~500B  (UI access)
restart.sh               ~1KB   (restart script)
cleanup.sh               ~1.5KB (cleanup script)
```

## 🎓 Learning Path

### Beginner
1. Read `GETTING_STARTED.md`
2. Run `preflight-check.sh`
3. Run `setup-local-cluster.sh`
4. Explore ArgoCD UI
5. Use `status.sh` to understand components

### Intermediate
1. Read `README.md` completely
2. Practice with `deploy-new-version.sh`
3. Use `watch-rollout.sh` and `test-traffic.sh`
4. Experiment with rollout control
5. Review `QUICK_REFERENCE.md`

### Advanced
1. Read `TROUBLESHOOTING.md`
2. Modify setup script for custom needs
3. Customize rollout strategies
4. Integrate with CI/CD
5. Add your own applications

## 🆘 Need Help?

1. **Start here**: `GETTING_STARTED.md`
2. **Full docs**: `README.md`
3. **Commands**: `QUICK_REFERENCE.md`
4. **Problems**: `TROUBLESHOOTING.md`
5. **Status**: `./status.sh`

## ✅ All Scripts Are:
- ✓ Executable (chmod +x applied)
- ✓ Self-documenting with comments
- ✓ Error-checked with set -e
- ✓ Colored output for clarity
- ✓ Safe with confirmations for destructive actions

## 🚀 Next Steps

Ready to start?
```bash
./preflight-check.sh && ./setup-local-cluster.sh
```

Happy developing! 🎉
