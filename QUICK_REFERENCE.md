# Quick Reference Guide

Quick commands for common operations with the Argo Rollouts Canary Demo.

## 📦 Build & Push

```bash
# Build image locally
./scripts/build-image.sh v1

# Build and push to Docker Hub
docker build -t USERNAME/canary-demo:v1 ./app
docker push USERNAME/canary-demo:v1

# Build with specific build args
docker build \
  --build-arg APP_VERSION=v2 \
  --build-arg BUILD_TIME="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  -t USERNAME/canary-demo:v2 \
  ./app
```

## 🚀 Deploy

```bash
# Deploy via ArgoCD
kubectl apply -f argocd/application.yaml

# Sync ArgoCD app
argocd app sync canary-demo

# Deploy via kubectl
kubectl apply -f k8s/

# Update image version
kubectl argo rollouts set image canary-demo-rollout \
  nginx=USERNAME/canary-demo:v2
```

## 👀 Monitor

```bash
# Watch rollout progress
./scripts/watch-rollout.sh

# Or manually
kubectl argo rollouts get rollout canary-demo-rollout -w

# Check rollout status
kubectl argo rollouts status canary-demo-rollout

# Get rollout info
kubectl argo rollouts get rollout canary-demo-rollout

# View history
kubectl argo rollouts history canary-demo-rollout

# Test traffic distribution
./scripts/test-traffic.sh
```

## 🎮 Control Rollout

```bash
# Promote canary to stable
kubectl argo rollouts promote canary-demo-rollout

# Skip current pause
kubectl argo rollouts promote canary-demo-rollout --skip-current-step

# Abort rollout
kubectl argo rollouts abort canary-demo-rollout

# Retry rollout
kubectl argo rollouts retry canary-demo-rollout

# Restart rollout
kubectl argo rollouts restart canary-demo-rollout

# Pause rollout
kubectl argo rollouts pause canary-demo-rollout

# Resume rollout
kubectl argo rollouts resume canary-demo-rollout
```

## ⏮️ Rollback

```bash
# Undo to previous version
kubectl argo rollouts undo canary-demo-rollout

# Undo to specific revision
kubectl argo rollouts undo canary-demo-rollout --to-revision=2

# View rollout history
kubectl argo rollouts history canary-demo-rollout
```

## 📊 Debugging

```bash
# Get all resources
kubectl get all -l app=canary-demo

# Check pods
kubectl get pods -l app=canary-demo
kubectl describe pod POD_NAME

# Check services
kubectl get svc -l app=canary-demo
kubectl describe svc canary-demo-stable

# Check ingress
kubectl get ingress
kubectl describe ingress canary-demo-ingress

# View logs
kubectl logs -l app=canary-demo --tail=50
kubectl logs -f POD_NAME

# Check events
kubectl get events --sort-by='.lastTimestamp' | grep canary-demo

# Describe rollout
kubectl describe rollout canary-demo-rollout

# Check replica sets
kubectl get rs -l app=canary-demo
```

## 🔍 ArgoCD

```bash
# Login to ArgoCD
argocd login ARGOCD_SERVER

# Get app status
argocd app get canary-demo

# Sync app
argocd app sync canary-demo

# Force sync
argocd app sync canary-demo --force

# Delete app
argocd app delete canary-demo

# View app logs
argocd app logs canary-demo

# List apps
argocd app list

# Refresh app
argocd app refresh canary-demo
```

## 🌐 Access Application

```bash
# Via LoadBalancer
LB_URL=$(kubectl get svc canary-demo-root -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://${LB_URL}

# Via Ingress
INGRESS_URL=$(kubectl get ingress canary-demo-ingress -o jsonpath='{.spec.rules[0].host}')
curl http://${INGRESS_URL}

# Via port-forward
kubectl port-forward svc/canary-demo-stable 8080:80
curl http://localhost:8080

# Open in browser
open http://${LB_URL}  # macOS
xdg-open http://${LB_URL}  # Linux
```

## 🔧 Troubleshooting

```bash
# Check if pods are ready
kubectl wait --for=condition=Ready pods -l app=canary-demo --timeout=60s

# Get pod logs for errors
kubectl logs -l app=canary-demo --tail=100 | grep -i error

# Check image pull status
kubectl get events | grep -i "pull"

# Test service connectivity
kubectl run test --rm -it --image=curlimages/curl --restart=Never -- sh
# curl http://canary-demo-stable
# curl http://canary-demo-canary

# Check NGINX ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Validate manifests
kubectl apply -f k8s/ --dry-run=client

# Check ArgoCD sync status
argocd app get canary-demo --refresh
```

## 🧪 Testing

```bash
# Continuous traffic test
while true; do
  curl -s http://ENDPOINT | grep -oP 'v[0-9]+'
  sleep 1
done

# Load test with hey
hey -n 1000 -c 10 http://ENDPOINT

# Watch traffic distribution
./scripts/test-traffic.sh
```

## 📈 Dashboards

```bash
# Argo Rollouts Dashboard
kubectl argo rollouts dashboard
# Access at http://localhost:3100

# ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Access at https://localhost:8080

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

## 🗑️ Cleanup

```bash
# Delete deployment
kubectl delete -f k8s/

# Delete ArgoCD app
argocd app delete canary-demo --cascade

# Or via kubectl
kubectl delete -f argocd/application.yaml

# Delete namespace resources
kubectl delete all -l app=canary-demo
```

## 🔐 Secrets Management

```bash
# Create Docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=USERNAME \
  --docker-password=PASSWORD

# Create generic secret
kubectl create secret generic app-secret \
  --from-literal=key=value

# View secret
kubectl get secret SECRET_NAME -o yaml
```

## 📝 Configuration Updates

```bash
# Edit rollout
kubectl edit rollout canary-demo-rollout

# Update via patch
kubectl patch rollout canary-demo-rollout \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"USERNAME/canary-demo:v3"}]}}}}'

# Scale replicas
kubectl argo rollouts set replicas canary-demo-rollout 5
```

## 🎯 Version Deployment

```bash
# Deploy v1
git commit --allow-empty -m "deploy: v1"
git push origin main

# Deploy v2
git commit --allow-empty -m "deploy: v2"
git push origin main

# Deploy v3
git commit --allow-empty -m "deploy: v3"
git push origin main

# Or use workflow dispatch
gh workflow run ci.yml -f version=v2
```

## ⚙️ GitHub Actions

```bash
# Trigger CI workflow
gh workflow run ci.yml

# Trigger CI with version
gh workflow run ci.yml -f version=v2

# Trigger CD workflow
gh workflow run cd.yml

# View workflow runs
gh run list

# View workflow logs
gh run view RUN_ID --log

# Watch workflow
gh run watch RUN_ID
```

## 🐛 Common Issues

### Rollout Stuck

```bash
kubectl argo rollouts get rollout canary-demo-rollout
kubectl describe rollout canary-demo-rollout
kubectl logs -l app=canary-demo
```

### Image Pull Error

```bash
kubectl describe pod POD_NAME
# Check image name and registry credentials
```

### Ingress Not Working

```bash
kubectl get ingress
kubectl describe ingress canary-demo-ingress
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Traffic Not Splitting

```bash
kubectl get ingress canary-demo-ingress-canary -o yaml | grep canary
# Check canary-weight annotation
```

## 📚 Additional Resources

- [Argo Rollouts Docs](https://argoproj.github.io/argo-rollouts/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [NGINX Ingress Docs](https://kubernetes.github.io/ingress-nginx/)

---

**Tip**: Bookmark this page for quick command reference!
