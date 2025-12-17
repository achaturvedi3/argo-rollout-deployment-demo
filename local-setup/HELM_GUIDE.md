# Helm Deployment Guide for Local Kind Cluster

Complete guide for deploying and managing the application using Helm charts in your local Kind cluster.

## 📦 Available Scripts

### Deployment Scripts
- **`helm-deploy.sh`** - Initial deployment with Helm
- **`helm-upgrade.sh`** - Upgrade existing deployment
- **`helm-status.sh`** - Check deployment status
- **`helm-rollback.sh`** - Rollback to previous version
- **`helm-uninstall.sh`** - Remove deployment

## 🚀 Quick Start

### 1. Deploy Application
```bash
# Deploy with default settings
./helm-deploy.sh
```

**What it does:**
- ✅ Checks prerequisites (Helm, kubectl, cluster)
- ✅ Creates namespace if needed
- ✅ Generates local values file
- ✅ Validates Helm chart
- ✅ Runs dry-run
- ✅ Deploys application
- ✅ Sets up NGINX ingress
- ✅ Displays access information

**Time:** ~2-3 minutes

### 2. Access Application
```bash
# Add to /etc/hosts if not already done
sudo bash -c 'echo "127.0.0.1 canary-demo.local" >> /etc/hosts'

# Access application
curl http://canary-demo.local:8080
# Or open in browser
open http://canary-demo.local:8080
```

## 📋 Prerequisites

Before running `helm-deploy.sh`:

1. **Kind cluster must be running**
   ```bash
   # If not created yet:
   ./setup-local-cluster.sh
   
   # Or just create Kind cluster:
   kind create cluster --name argo-rollouts-demo
   ```

2. **Required tools installed**
   ```bash
   helm version       # Helm 3.x
   kubectl version    # kubectl
   kind version       # Kind
   ```

3. **Argo Rollouts installed**
   ```bash
   # Install if not present:
   kubectl create namespace argo-rollouts
   kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
   ```

## 🔧 Detailed Usage

### Initial Deployment

```bash
./helm-deploy.sh
```

**Interactive prompts:**
1. Confirms cluster connection
2. Creates local values file automatically
3. Validates chart
4. Asks for deployment confirmation
5. Deploys application
6. Displays access information

**Generated files:**
- `local-helm-values.yaml` - Local configuration
- `helm-deployment-info.txt` - Access information

### Check Status

```bash
./helm-status.sh
```

**Shows:**
- Helm release status
- Release history
- Current values
- Rollout status
- Services, pods, ingress
- Access URLs

### Upgrade Deployment

```bash
./helm-upgrade.sh
```

**Upgrade options:**
1. **New image tag** - Update container image
2. **Values file** - Apply new values.yaml
3. **Inline values** - Quick field updates
4. **Specific field** - Update single value

**Examples:**
```bash
# Option 1: New image tag
./helm-upgrade.sh
# Select 1, enter: v2.0.0

# Option 4: Update replicas
./helm-upgrade.sh
# Select 4
# Field: rollout.replicas
# Value: 5
```

### Rollback Deployment

```bash
./helm-rollback.sh
```

**Options:**
- Rollback to previous version (press Enter)
- Rollback to specific revision (enter revision number)

**Example:**
```bash
./helm-rollback.sh
# Shows history
# Enter revision number or press Enter for previous
```

### Uninstall Deployment

```bash
./helm-uninstall.sh
```

**Safety features:**
- Shows current release
- Lists resources to be deleted
- Requires "yes" confirmation
- Verifies cleanup completion

## 📊 Configuration

### Local Values File

The `helm-deploy.sh` script automatically generates `local-helm-values.yaml`:

```yaml
# Optimized for local development
namespace: default

image:
  repository: nginx
  tag: "latest"
  pullPolicy: IfNotPresent

rollout:
  replicas: 2
  strategy:
    canary:
      steps:
        - setWeight: 20
          pause: {duration: 30s}
        - setWeight: 50
          pause: {duration: 30s}
        - setWeight: 80
          pause: {duration: 30s}
        - setWeight: 100
          pause: {duration: 10s}

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: canary-demo.local
      paths:
        - path: /
          pathType: Prefix

# AWS features disabled for local
externalDns:
  enabled: false
```

### Customize Values

```bash
# Edit the generated values file
vi local-helm-values.yaml

# Deploy with custom values
export VALUES_FILE="my-custom-values.yaml"
./helm-deploy.sh
```

### Environment Variables

```bash
# Custom release name
export RELEASE_NAME="my-app"
./helm-deploy.sh

# Custom namespace
export NAMESPACE="development"
./helm-deploy.sh

# Custom cluster
export CLUSTER_NAME="my-cluster"
./helm-deploy.sh
```

## 🎯 Common Workflows

### Workflow 1: Fresh Deployment
```bash
# 1. Ensure cluster is running
kind get clusters

# 2. Deploy application
./helm-deploy.sh

# 3. Check status
./helm-status.sh

# 4. Test application
curl http://canary-demo.local:8080
```

### Workflow 2: Update Image Version
```bash
# 1. Upgrade with new tag
./helm-upgrade.sh
# Choose option 1
# Enter: v2.0.0

# 2. Watch rollout
kubectl argo rollouts get rollout canary-demo-rollout --watch

# 3. Test new version
curl http://canary-demo.local:8080
```

### Workflow 3: Configuration Change
```bash
# 1. Edit values file
vi local-helm-values.yaml

# 2. Upgrade with new values
./helm-upgrade.sh
# Choose option 2

# 3. Verify changes
./helm-status.sh
```

### Workflow 4: Rollback After Issue
```bash
# 1. Check history
helm history canary-demo

# 2. Rollback
./helm-rollback.sh
# Enter revision number or press Enter

# 3. Verify rollback
./helm-status.sh
```

### Workflow 5: Clean Removal
```bash
# 1. Uninstall deployment
./helm-uninstall.sh
# Type: yes

# 2. Verify cleanup
kubectl get all -n default
```

## 🧪 Testing Canary Deployments

### Test Scenario 1: Automatic Promotion
```bash
# Terminal 1: Deploy and watch
./helm-upgrade.sh  # Deploy v2.0.0
kubectl argo rollouts get rollout canary-demo-rollout --watch

# Terminal 2: Generate traffic
while true; do curl -s http://canary-demo.local:8080; sleep 1; done

# Observe: 20% → 50% → 80% → 100% automatic progression
```

### Test Scenario 2: Manual Control
```bash
# 1. Edit values to disable auto-promotion
vi local-helm-values.yaml
# Set: autoPromotionEnabled: false

# 2. Upgrade
./helm-upgrade.sh

# 3. Deploy new version
./helm-upgrade.sh  # New image tag

# 4. Manual promotion
kubectl argo rollouts promote canary-demo-rollout

# 5. Or abort
kubectl argo rollouts abort canary-demo-rollout
```

### Test Scenario 3: Scale Testing
```bash
# 1. Scale up
./helm-upgrade.sh
# Choose option 4
# Field: rollout.replicas
# Value: 10

# 2. Watch pods scale
kubectl get pods -w

# 3. Scale down
./helm-upgrade.sh
# Field: rollout.replicas
# Value: 2
```

## 🔍 Debugging

### Check Helm Release
```bash
# List releases
helm list -n default

# Get release status
helm status canary-demo -n default

# Get release values
helm get values canary-demo -n default

# Get all release info
helm get all canary-demo -n default
```

### Check Kubernetes Resources
```bash
# Check rollout
kubectl get rollout canary-demo-rollout -n default
kubectl describe rollout canary-demo-rollout -n default

# Check pods
kubectl get pods -n default -l app.kubernetes.io/instance=canary-demo
kubectl logs -n default -l app.kubernetes.io/instance=canary-demo

# Check services
kubectl get svc -n default -l app.kubernetes.io/instance=canary-demo

# Check ingress
kubectl get ingress -n default
kubectl describe ingress canary-demo-ingress -n default
```

### Troubleshooting

#### Deployment Fails
```bash
# Check Helm chart
helm lint ../helm

# Dry-run to see what would be deployed
helm install canary-demo ../helm --dry-run --debug

# Check cluster resources
kubectl get nodes
kubectl top nodes
```

#### Can't Access Application
```bash
# Check /etc/hosts
cat /etc/hosts | grep canary-demo

# Check ingress controller
kubectl get pods -n ingress-nginx

# Port-forward directly to service
kubectl port-forward svc/canary-demo-stable -n default 8080:80
curl http://localhost:8080
```

#### Rollout Stuck
```bash
# Check rollout status
kubectl argo rollouts get rollout canary-demo-rollout

# Check pod events
kubectl get events -n default --sort-by='.lastTimestamp'

# Abort and restart
kubectl argo rollouts abort canary-demo-rollout
kubectl argo rollouts restart canary-demo-rollout
```

## 📚 Helm Commands Reference

### Installation
```bash
# Install with defaults
helm install canary-demo ../helm

# Install with custom values
helm install canary-demo ../helm -f my-values.yaml

# Install in specific namespace
helm install canary-demo ../helm -n production --create-namespace

# Dry-run
helm install canary-demo ../helm --dry-run --debug
```

### Upgrade
```bash
# Upgrade with new values
helm upgrade canary-demo ../helm -f my-values.yaml

# Upgrade with inline overrides
helm upgrade canary-demo ../helm --set image.tag=v2.0.0

# Reuse values and update one field
helm upgrade canary-demo ../helm --reuse-values --set rollout.replicas=5
```

### Status & History
```bash
# Get status
helm status canary-demo

# Get history
helm history canary-demo

# Get values
helm get values canary-demo

# Get manifest
helm get manifest canary-demo
```

### Rollback & Uninstall
```bash
# Rollback to previous
helm rollback canary-demo

# Rollback to specific revision
helm rollback canary-demo 3

# Uninstall
helm uninstall canary-demo
```

## 💡 Best Practices

1. **Always check status first**
   ```bash
   ./helm-status.sh
   ```

2. **Use dry-run before deployment**
   - Automatically done by `helm-deploy.sh`
   - Catches errors early

3. **Version your values files**
   ```bash
   cp local-helm-values.yaml local-helm-values-v1.yaml
   git add local-helm-values-v1.yaml
   ```

4. **Test locally before production**
   - Perfect environment for testing Helm charts
   - Validate all changes here first

5. **Monitor rollouts actively**
   ```bash
   kubectl argo rollouts get rollout canary-demo-rollout --watch
   ```

6. **Keep release history**
   ```bash
   helm history canary-demo > history-$(date +%Y%m%d).txt
   ```

## 🎓 Learning Resources

- **Helm Documentation**: https://helm.sh/docs/
- **Argo Rollouts Helm**: https://argoproj.github.io/argo-rollouts/
- **Parent Chart**: `../helm/README.md`

## 📋 Quick Reference

```bash
# Deploy
./helm-deploy.sh

# Check status
./helm-status.sh

# Upgrade
./helm-upgrade.sh

# Rollback
./helm-rollback.sh

# Uninstall
./helm-uninstall.sh

# Access app
curl http://canary-demo.local:8080

# Watch rollout
kubectl argo rollouts get rollout canary-demo-rollout --watch

# View logs
kubectl logs -n default -l app.kubernetes.io/instance=canary-demo -f
```

## ✅ Success Checklist

After running `helm-deploy.sh`:

- [ ] Helm release shows as "deployed"
- [ ] Rollout is "Healthy"
- [ ] All pods are "Running"
- [ ] Services have endpoints
- [ ] Ingress has address
- [ ] Application accessible at http://canary-demo.local:8080
- [ ] Can watch rollout with kubectl
- [ ] Can upgrade successfully
- [ ] Can rollback successfully

---

**Ready to deploy?**

```bash
./helm-deploy.sh
```

Happy deploying! 🚀
