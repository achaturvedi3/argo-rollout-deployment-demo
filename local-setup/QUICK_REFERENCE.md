# Local Development Quick Reference

## 🚀 Initial Setup
```bash
cd local-setup
./setup-local-cluster.sh

# Add to /etc/hosts
sudo bash -c 'echo "127.0.0.1 argocd.local canary-demo.local" >> /etc/hosts'
```

## 🌐 Access URLs
- **ArgoCD**: http://argocd.local:8080
- **Application**: http://canary-demo.local:8080
- **Credentials**: See `argocd-credentials.txt`

## 📜 Essential Commands

### Cluster Management
```bash
./status.sh                    # Check everything
./restart.sh                   # Restart components
./cleanup.sh                   # Delete cluster
```

### Application Deployment
```bash
./deploy-new-version.sh        # Deploy new version
./watch-rollout.sh             # Watch progress
./test-traffic.sh              # Test traffic
```

### ArgoCD
```bash
./argocd-ui.sh                 # Port-forward to UI
argocd app list                # List applications
argocd app sync canary-demo    # Manual sync
argocd app get canary-demo     # Get app details
```

### Rollout Control
```bash
# Watch rollout
kubectl argo rollouts get rollout canary-demo-rollout -n default --watch

# Promote
kubectl argo rollouts promote canary-demo-rollout -n default

# Full promotion
kubectl argo rollouts promote canary-demo-rollout -n default --full

# Abort
kubectl argo rollouts abort canary-demo-rollout -n default

# Restart
kubectl argo rollouts restart canary-demo-rollout -n default

# Set image
kubectl argo rollouts set image canary-demo-rollout -n default \
  nginx=registry/image:tag
```

### Debugging
```bash
# Check pods
kubectl get pods -n default

# View logs
kubectl logs -n default -l app=canary-demo -f

# Check events
kubectl get events -n default --sort-by='.lastTimestamp'

# ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Argo Rollouts logs
kubectl logs -n argo-rollouts -l app.kubernetes.io/name=argo-rollouts -f

# Ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f
```

### Port Forwarding (Alternative Access)
```bash
# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Application
kubectl port-forward svc/canary-demo-stable -n default 8080:80
```

## 🔧 Troubleshooting

### Reset Cluster
```bash
./cleanup.sh && ./setup-local-cluster.sh
```

### Fix Sync Issues
```bash
# Force sync
kubectl patch application canary-demo -n argocd --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

### Check Component Health
```bash
kubectl get pods -n argocd
kubectl get pods -n argo-rollouts
kubectl get pods -n ingress-nginx
kubectl get pods -n default
```

## 📊 Testing Canary Rollout

### Terminal 1: Watch rollout
```bash
./watch-rollout.sh
```

### Terminal 2: Generate traffic
```bash
./test-traffic.sh
```

### Terminal 3: Control rollout
```bash
# Promote step by step
kubectl argo rollouts promote canary-demo-rollout -n default

# Or abort
kubectl argo rollouts abort canary-demo-rollout -n default
```

## 🎯 Common Workflows

### Deploy New Version
1. Update image in k8s manifests
2. Push to GitHub
3. ArgoCD auto-syncs
4. Watch rollout progress
5. Promote or abort as needed

### Manual Deployment
1. Run `./deploy-new-version.sh`
2. Enter new image tag
3. Watch automatic rollout
4. Control with promote/abort

### Test Application
1. Access http://canary-demo.local:8080
2. Or run `./test-traffic.sh`
3. See version information in response

## 🔑 Default Credentials

**ArgoCD**
- Username: `admin`
- Password: Check `argocd-credentials.txt` or run:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d
  ```

## 📁 File Locations
- Scripts: `local-setup/`
- K8s Manifests: `k8s/`
- ArgoCD App: `argocd/application.yaml`
- Helm Chart: `helm/`

## 💾 Cluster Info
- **Name**: argo-rollouts-demo
- **Nodes**: 3 (1 control-plane, 2 workers)
- **Context**: kind-argo-rollouts-demo
- **Ports**: 8080 (HTTP), 8443 (HTTPS)

## 🔄 Update Workflow

```
Local Changes → Git Push → ArgoCD Detects → Auto Sync → Rollout Triggered
                                                            ↓
                                                   Canary Deployment
                                                            ↓
                                                    10% → 30% → 60% → 100%
```
