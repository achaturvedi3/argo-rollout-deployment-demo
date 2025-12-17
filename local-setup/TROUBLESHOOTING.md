# Troubleshooting Guide for Local Setup

## Common Issues and Solutions

### 1. Setup Script Fails

#### Docker Not Running
**Error**: `Cannot connect to Docker daemon`

**Solution**:
```bash
# Start Docker Desktop
open -a Docker

# Wait for Docker to start, then retry
./setup-local-cluster.sh
```

#### Kind Not Installed
**Error**: `kind: command not found`

**Solution**:
```bash
brew install kind
```

#### Kubectl Not Installed
**Error**: `kubectl: command not found`

**Solution**:
```bash
brew install kubectl
```

### 2. Cluster Creation Issues

#### Cluster Already Exists
**Error**: `Cluster 'argo-rollouts-demo' already exists`

**Solution**:
```bash
# Option 1: Delete and recreate
kind delete cluster --name argo-rollouts-demo
./setup-local-cluster.sh

# Option 2: Use existing cluster
export CLUSTER_NAME="argo-rollouts-demo"
kubectl config use-context kind-argo-rollouts-demo
```

#### Port Already in Use
**Error**: `port 8080 is already allocated`

**Solution**:
```bash
# Find what's using the port
lsof -i :8080

# Kill the process or change Kind port mapping
# Edit setup-local-cluster.sh and change hostPort values
```

#### Not Enough Resources
**Error**: `Failed to create cluster` or `Out of memory`

**Solution**:
```bash
# Increase Docker Desktop resources
# Docker Desktop → Preferences → Resources
# Increase CPUs to 4 and Memory to 8GB

# Or reduce cluster size (edit setup script to use 1 node)
```

### 3. ArgoCD Issues

#### Cannot Access ArgoCD UI
**Error**: Browser can't connect to http://argocd.local:8080

**Solution**:
```bash
# Check /etc/hosts
cat /etc/hosts | grep argocd
# If not found, add it:
sudo bash -c 'echo "127.0.0.1 argocd.local" >> /etc/hosts'

# Check ingress
kubectl get ingress -n argocd
kubectl describe ingress argocd-server-ingress -n argocd

# Alternative: Use port-forward
./argocd-ui.sh
# Then access: http://localhost:8080
```

#### Wrong Password
**Error**: `Invalid username or password`

**Solution**:
```bash
# Get the correct password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Or check saved credentials
cat local-setup/argocd-credentials.txt
```

#### ArgoCD Pods Not Running
**Error**: ArgoCD pods in CrashLoopBackOff or Pending

**Solution**:
```bash
# Check pod status
kubectl get pods -n argocd

# Check pod logs
kubectl logs -n argocd <pod-name>

# Check events
kubectl get events -n argocd --sort-by='.lastTimestamp'

# Restart ArgoCD
kubectl rollout restart deployment -n argocd
kubectl rollout status deployment -n argocd
```

### 4. Application Deployment Issues

#### Application Not Syncing
**Error**: Application shows "OutOfSync" in ArgoCD

**Solution**:
```bash
# Check application status
kubectl describe application canary-demo -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Force sync
kubectl patch application canary-demo -n argocd --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# Or use ArgoCD CLI
argocd app sync canary-demo
```

#### Repository Not Connected
**Error**: `Failed to connect to repository`

**Solution**:
```bash
# Check repository secret
kubectl get secret -n argocd repo-argo-rollout-demo

# Recreate repository connection
kubectl delete secret -n argocd repo-argo-rollout-demo
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: repo-argo-rollout-demo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/achaturvedi3/argo-rollout-deployment-demo.git
EOF
```

#### Health Check Failed
**Error**: Application shows "Degraded" health status

**Solution**:
```bash
# Check pod status
kubectl get pods -n default

# Check pod logs
kubectl logs -n default -l app=canary-demo

# Check events
kubectl get events -n default --sort-by='.lastTimestamp'

# Check rollout status
kubectl get rollout canary-demo-rollout -n default
```

### 5. Rollout Issues

#### Rollout Stuck at Pause
**Error**: Rollout paused and not progressing

**Solution**:
```bash
# Check rollout status
kubectl argo rollouts get rollout canary-demo-rollout -n default

# Promote manually
kubectl argo rollouts promote canary-demo-rollout -n default

# Or skip remaining steps
kubectl argo rollouts promote canary-demo-rollout -n default --full
```

#### Rollout Failed
**Error**: Rollout shows "Degraded" status

**Solution**:
```bash
# Check rollout status
kubectl argo rollouts get rollout canary-demo-rollout -n default

# Check pod status
kubectl get pods -n default -l app=canary-demo

# Abort and restart
kubectl argo rollouts abort canary-demo-rollout -n default
kubectl argo rollouts restart canary-demo-rollout -n default
```

#### Image Pull Error
**Error**: `ImagePullBackOff` or `ErrImagePull`

**Solution**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n default

# Verify image exists and is accessible
docker pull <image:tag>

# For private registries, create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n default
```

### 6. Ingress Issues

#### Cannot Access Application
**Error**: Browser can't connect to http://canary-demo.local:8080

**Solution**:
```bash
# Check /etc/hosts
cat /etc/hosts | grep canary-demo
# If not found:
sudo bash -c 'echo "127.0.0.1 canary-demo.local" >> /etc/hosts'

# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Check ingress resource
kubectl get ingress -n default
kubectl describe ingress canary-demo-ingress -n default

# Alternative: Use port-forward
kubectl port-forward svc/canary-demo-stable -n default 8080:80
# Then: curl http://localhost:8080
```

#### 503 Service Unavailable
**Error**: Ingress returns 503 error

**Solution**:
```bash
# Check service
kubectl get svc -n default

# Check service endpoints
kubectl get endpoints -n default

# Check pods are running
kubectl get pods -n default

# Check ingress backend
kubectl describe ingress canary-demo-ingress -n default
```

### 7. NGINX Ingress Controller Issues

#### Controller Not Running
**Error**: NGINX ingress controller pods not ready

**Solution**:
```bash
# Check controller status
kubectl get pods -n ingress-nginx

# Check logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Reinstall
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/kind/deploy.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/kind/deploy.yaml
```

### 8. Argo Rollouts Plugin Issues

#### Plugin Not Found
**Error**: `kubectl argo rollouts: command not found`

**Solution**:
```bash
# Install the plugin
brew install argoproj/tap/kubectl-argo-rollouts

# Verify installation
kubectl argo rollouts version

# Alternative: Use direct kubectl commands
kubectl get rollouts -n default
kubectl describe rollout canary-demo-rollout -n default
```

### 9. Performance Issues

#### Cluster Running Slow
**Symptoms**: Slow response times, timeouts

**Solution**:
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Increase Docker resources
# Docker Desktop → Preferences → Resources
# Set CPUs: 4, Memory: 8GB

# Restart cluster
./restart.sh
```

#### Out of Disk Space
**Error**: `No space left on device`

**Solution**:
```bash
# Clean Docker
docker system prune -a --volumes

# Clean Kind images
kind delete cluster --name argo-rollouts-demo

# Restart Docker Desktop
```

### 10. Complete Reset

If nothing works, perform a complete reset:

```bash
# 1. Delete the cluster
./cleanup.sh

# 2. Clean Docker
docker system prune -a --volumes

# 3. Restart Docker Desktop
# Docker Desktop → Restart

# 4. Remove /etc/hosts entries
sudo sed -i '' '/argocd.local\|canary-demo.local/d' /etc/hosts

# 5. Reinstall everything
./setup-local-cluster.sh
```

## Debugging Commands

### Check Everything
```bash
./status.sh
```

### View All Resources
```bash
kubectl get all -A
```

### Check Cluster Info
```bash
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### View Logs
```bash
# ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Argo Rollouts
kubectl logs -n argo-rollouts -l app.kubernetes.io/name=argo-rollouts -f

# Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f

# Application
kubectl logs -n default -l app=canary-demo -f
```

### Check Events
```bash
kubectl get events -A --sort-by='.lastTimestamp'
```

### Export Kind Logs
```bash
kind export logs --name argo-rollouts-demo /tmp/kind-logs
```

## Getting More Help

1. **Check Status**: Always run `./status.sh` first
2. **Review Logs**: Check component logs for errors
3. **Verify Prerequisites**: Ensure Docker is running and has enough resources
4. **Check Documentation**: Review README.md for detailed setup instructions
5. **GitHub Issues**: Check repository issues for similar problems
6. **Kind Documentation**: https://kind.sigs.k8s.io/docs/user/quick-start/
7. **ArgoCD Documentation**: https://argo-cd.readthedocs.io/
8. **Argo Rollouts Documentation**: https://argoproj.github.io/argo-rollouts/

## Prevention Tips

1. **Keep Docker running** with sufficient resources (4 CPU, 8GB RAM)
2. **Update /etc/hosts** immediately after setup
3. **Save ArgoCD password** from credentials file
4. **Run status checks** before and after changes
5. **Use version control** for all manifest changes
6. **Test in isolation** - one change at a time
7. **Monitor resources** regularly with `kubectl top`
8. **Clean up regularly** - don't leave multiple clusters running
