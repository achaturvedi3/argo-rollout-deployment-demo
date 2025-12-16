# Deployment Guide

This guide walks you through deploying the Argo Rollouts Canary Demo from scratch.

## Table of Contents

1. [Prerequisites Setup](#prerequisites-setup)
2. [Infrastructure Setup](#infrastructure-setup)
3. [Repository Configuration](#repository-configuration)
4. [First Deployment](#first-deployment)
5. [Testing Canary Rollout](#testing-canary-rollout)
6. [Monitoring and Observability](#monitoring-and-observability)

## Prerequisites Setup

### 1. Install Required Tools

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argocd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Install Argo Rollouts kubectl plugin
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
# Enter your default output format (json)
```

### 3. Create or Use Existing EKS Cluster

```bash
# Create new cluster (optional)
eksctl create cluster \
  --name canary-demo-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

# Or update kubeconfig for existing cluster
aws eks update-kubeconfig --region us-east-1 --name your-cluster-name

# Verify connection
kubectl cluster-info
kubectl get nodes
```

## Infrastructure Setup

### 1. Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Access at https://localhost:8080
```

### 2. Install Argo Rollouts

```bash
# Create namespace
kubectl create namespace argo-rollouts

# Install Argo Rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Verify installation
kubectl get pods -n argo-rollouts

# Install dashboard (optional)
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/dashboard-install.yaml
```

### 3. Install NGINX Ingress Controller

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml

# Wait for Load Balancer to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Get Load Balancer URL
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

## Repository Configuration

### 1. Fork Repository

1. Go to https://github.com/achaturvedi3/argo-rollout-deployment-demo
2. Click "Fork" button
3. Clone your fork:

```bash
git clone https://github.com/YOUR_USERNAME/argo-rollout-deployment-demo.git
cd argo-rollout-deployment-demo
```

### 2. Configure GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

```
DOCKER_USERNAME: your-dockerhub-username
DOCKER_PASSWORD: your-dockerhub-token
AWS_ROLE_TO_ASSUME: arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
AWS_REGION: us-east-1
EKS_CLUSTER_NAME: your-cluster-name
```

### 3. Setup AWS IAM for GitHub Actions (OIDC)

```bash
# Create IAM OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com

# Create trust policy (save as trust-policy.json)
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/argo-rollout-deployment-demo:*"
        }
      }
    }
  ]
}
EOF

# Create IAM role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

### 4. Update Configuration Files

**Update k8s/rollout.yaml:**
```yaml
image: YOUR_DOCKER_USERNAME/canary-demo:latest
```

**Update k8s/ingress.yaml:**
```yaml
host: canary-demo.example.com  # Use your domain or LoadBalancer DNS
```

**Update argocd/application.yaml:**
```yaml
repoURL: https://github.com/YOUR_USERNAME/argo-rollout-deployment-demo.git
```

Commit and push changes:
```bash
git add .
git commit -m "chore: update configuration"
git push origin main
```

## First Deployment

### 1. Deploy ArgoCD Application

```bash
# Apply ArgoCD application
kubectl apply -f argocd/application.yaml

# Check application status
argocd app get canary-demo

# Sync application
argocd app sync canary-demo

# Wait for sync
argocd app wait canary-demo --health
```

### 2. Trigger CI Pipeline

Option A: Push to main branch
```bash
git commit --allow-empty -m "deploy: v1"
git push origin main
```

Option B: Manual workflow trigger
1. Go to Actions tab in GitHub
2. Select "CI - Build and Push Docker Image"
3. Click "Run workflow"
4. Enter version: v1
5. Click "Run workflow"

### 3. Monitor Deployment

```bash
# Watch rollout
kubectl argo rollouts get rollout canary-demo-rollout -w

# Check pods
kubectl get pods -l app=canary-demo

# Check services
kubectl get svc -l app=canary-demo

# Get application URL
kubectl get svc canary-demo-root
```

### 4. Access Application

```bash
# Get LoadBalancer URL
LB_URL=$(kubectl get svc canary-demo-root -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://${LB_URL}"

# Or use ingress
INGRESS_URL=$(kubectl get ingress canary-demo-ingress -o jsonpath='{.spec.rules[0].host}')
echo "Ingress URL: http://${INGRESS_URL}"

# Open in browser
curl http://${LB_URL}
```

## Testing Canary Rollout

### 1. Deploy New Version (v2)

```bash
# Trigger CI with v2
gh workflow run ci.yml -f version=v2

# Or commit with version in message
git commit --allow-empty -m "deploy: v2"
git push origin main
```

### 2. Monitor Rollout Progress

```bash
# Terminal 1: Watch rollout
kubectl argo rollouts get rollout canary-demo-rollout -w

# Terminal 2: Continuously test
while true; do
  curl -s http://${LB_URL} | grep -o "v[0-9]"
  sleep 1
done
```

Expected output during rollout:
```
v1    # 90% of requests
v1
v1
v2    # 10% of requests (Step 1: 10% canary)
v1
v1
...
v1    # 70% of requests
v2    # 30% of requests (Step 2: 30% canary)
v1
v2
...
v1    # 40% of requests
v2    # 60% of requests (Step 3: 60% canary)
v2
v2
...
v2    # 100% of requests (Step 4: full promotion)
v2
v2
```

### 3. Browser Testing

1. Open application URL in browser
2. Note the current version and color
3. Deploy new version
4. Refresh page multiple times
5. Observe traffic shifting:
   - Initially: Only old version (v1)
   - 10% canary: ~1 in 10 refreshes shows v2
   - 30% canary: ~3 in 10 refreshes shows v2
   - 60% canary: ~6 in 10 refreshes shows v2
   - 100%: All refreshes show v2

### 4. Argo Rollouts Dashboard

```bash
# Start dashboard
kubectl argo rollouts dashboard

# Access at http://localhost:3100
# View real-time rollout progress
```

## Monitoring and Observability

### 1. Rollout Status

```bash
# Get current status
kubectl argo rollouts status canary-demo-rollout

# Get detailed info
kubectl argo rollouts get rollout canary-demo-rollout

# View history
kubectl argo rollouts history canary-demo-rollout

# List rollouts
kubectl argo rollouts list rollouts
```

### 2. ArgoCD Monitoring

```bash
# Get application sync status
argocd app get canary-demo

# View application logs
argocd app logs canary-demo

# List applications
argocd app list
```

### 3. Kubernetes Resources

```bash
# Get all resources
kubectl get all -l app=canary-demo

# Check pod logs
kubectl logs -l app=canary-demo --tail=50

# Describe rollout
kubectl describe rollout canary-demo-rollout

# View events
kubectl get events --sort-by='.lastTimestamp' | grep canary-demo
```

### 4. Ingress Status

```bash
# Check ingress
kubectl get ingress

# Describe ingress
kubectl describe ingress canary-demo-ingress
kubectl describe ingress canary-demo-ingress-canary

# Check NGINX logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

## Advanced Operations

### Manual Promotion

```bash
# Promote immediately
kubectl argo rollouts promote canary-demo-rollout

# Skip current pause
kubectl argo rollouts promote canary-demo-rollout --skip-current-step
```

### Rollback

```bash
# Abort current rollout
kubectl argo rollouts abort canary-demo-rollout

# Undo to previous version
kubectl argo rollouts undo canary-demo-rollout

# Undo to specific revision
kubectl argo rollouts undo canary-demo-rollout --to-revision=2
```

### Restart Rollout

```bash
# Restart rollout
kubectl argo rollouts restart canary-demo-rollout
```

### Pause/Resume

```bash
# Pause rollout
kubectl argo rollouts pause canary-demo-rollout

# Resume rollout
kubectl argo rollouts resume canary-demo-rollout
```

## Cleanup

### Remove Application

```bash
# Delete via ArgoCD
argocd app delete canary-demo --cascade

# Or delete via kubectl
kubectl delete -f argocd/application.yaml
kubectl delete -f k8s/
```

### Remove Infrastructure

```bash
# Remove Argo Rollouts
kubectl delete -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl delete namespace argo-rollouts

# Remove ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd

# Remove NGINX Ingress
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml

# Delete EKS cluster (if created)
eksctl delete cluster --name canary-demo-cluster --region us-east-1
```

## Troubleshooting Common Issues

### Issue: Rollout not progressing

```bash
# Check rollout status
kubectl argo rollouts get rollout canary-demo-rollout

# Check pod status
kubectl get pods -l app=canary-demo

# Check events
kubectl describe rollout canary-demo-rollout

# Solution: Ensure pods are ready and healthy
kubectl logs -l app=canary-demo
```

### Issue: Traffic not splitting

```bash
# Check ingress annotations
kubectl get ingress canary-demo-ingress-canary -o yaml | grep canary

# Verify NGINX controller
kubectl get pods -n ingress-nginx

# Solution: Ensure NGINX ingress controller supports canary
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Issue: Image pull errors

```bash
# Check image exists
docker pull YOUR_USERNAME/canary-demo:v1

# Verify secrets
kubectl get secrets

# Solution: Update image pull credentials
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD
```

### Issue: ArgoCD sync failing

```bash
# Check app status
argocd app get canary-demo

# View logs
argocd app logs canary-demo

# Force sync
argocd app sync canary-demo --force --prune

# Solution: Check repository access and manifest validity
kubectl get events -n argocd
```

## Next Steps

1. **Add Monitoring**: Integrate Prometheus and Grafana
2. **Add Analysis**: Configure AnalysisTemplates for metrics-based promotion
3. **Add Notifications**: Setup Slack/email notifications for rollout events
4. **Add More Versions**: Deploy v3, v4 to test multiple rollouts
5. **Production Hardening**: Add rate limiting, security policies, and backups

## Support

For issues and questions:
- Open a GitHub issue
- Check Argo Rollouts documentation
- Review Kubernetes events and logs

---

**Happy Deploying!** 🚀
