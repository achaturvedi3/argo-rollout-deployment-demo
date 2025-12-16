# Quick Deployment Guide

This guide provides step-by-step instructions to deploy the Argo Rollout demo application.

## Prerequisites Checklist

- [ ] AWS Account with EKS permissions
- [ ] Docker Hub account
- [ ] kubectl installed locally
- [ ] AWS CLI installed and configured
- [ ] eksctl installed (for cluster creation)

## Step-by-Step Deployment

### Step 1: Create EKS Cluster (15-20 minutes)

```bash
# Create cluster
eksctl create cluster \
  --name argo-demo-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

# Verify cluster
kubectl get nodes
```

### Step 2: Install Argo Rollouts (2-3 minutes)

```bash
# Create namespace and install
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Install kubectl plugin
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Verify
kubectl argo rollouts version
```

### Step 3: Install ArgoCD (5 minutes)

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Expose ArgoCD server
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get initial password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Password: $ARGOCD_PASSWORD"

# Get server URL (wait a minute for LoadBalancer)
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ArgoCD Server: $ARGOCD_SERVER"
```

### Step 4: Install ArgoCD CLI (2 minutes)

```bash
# Download and install
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# Login
argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PASSWORD --insecure

# Generate token for GitHub Actions
ARGOCD_TOKEN=$(argocd account generate-token --account admin)
echo "ArgoCD Token: $ARGOCD_TOKEN"
echo "Save this token - you'll need it for GitHub Secrets"
```

### Step 5: Configure GitHub Secrets (3 minutes)

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:

1. **DOCKER_USERNAME**: Your Docker Hub username
2. **DOCKER_PASSWORD**: Your Docker Hub password/token
3. **AWS_ACCESS_KEY_ID**: Your AWS access key
4. **AWS_SECRET_ACCESS_KEY**: Your AWS secret key
5. **ARGOCD_SERVER**: The ArgoCD server URL (from Step 3)
6. **ARGOCD_AUTH_TOKEN**: The ArgoCD token (from Step 4)

### Step 6: Create ArgoCD Application (2 minutes)

```bash
# Apply the ArgoCD application manifest
kubectl apply -f argocd/application.yaml

# Verify application is created
argocd app get nginx-rollout-demo
```

### Step 7: Trigger First Deployment (5 minutes)

```bash
# Update the repository URL in argocd/application.yaml if needed
# Then commit and push to trigger CI/CD

git add .
git commit -m "Initial deployment"
git push origin main

# Monitor GitHub Actions
# Go to: https://github.com/YOUR_USERNAME/argo-rollout-deployment-demo/actions

# Watch the rollout
kubectl argo rollouts get rollout nginx-rollout-demo --watch
```

### Step 8: Access the Application (2 minutes)

```bash
# Get the LoadBalancer URL
APP_URL=$(kubectl get svc nginx-rollout-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$APP_URL"

# Wait a minute for LoadBalancer DNS to propagate, then open in browser
```

## Testing Canary Deployment

### Test 1: Make a Change

```bash
# Edit index.html - change the emoji or add some text
# Commit and push
git add index.html
git commit -m "Update to test canary deployment"
git push origin main
```

### Test 2: Watch the Rollout

```bash
# In terminal 1: Watch rollout progress
kubectl argo rollouts get rollout nginx-rollout-demo --watch

# In terminal 2: Watch pods
kubectl get pods -l app=nginx-rollout-demo --watch

# In browser: Refresh the application URL multiple times
# You should see both old and new versions during canary deployment
```

### Test 3: Monitor in ArgoCD UI

```bash
# Open ArgoCD UI
echo "http://$ARGOCD_SERVER"

# Login with admin and your password
# Navigate to the nginx-rollout-demo application
# Watch the sync status
```

## Useful Commands

### View Rollout Status
```bash
kubectl argo rollouts get rollout nginx-rollout-demo
kubectl argo rollouts status nginx-rollout-demo
kubectl argo rollouts history nginx-rollout-demo
```

### Control Rollout
```bash
# Promote to next step
kubectl argo rollouts promote nginx-rollout-demo

# Skip all steps and go to 100%
kubectl argo rollouts promote nginx-rollout-demo --full

# Abort rollout
kubectl argo rollouts abort nginx-rollout-demo

# Rollback
kubectl argo rollouts undo nginx-rollout-demo
```

### Debugging
```bash
# View logs
kubectl logs -l app=nginx-rollout-demo --tail=50

# Describe rollout
kubectl describe rollout nginx-rollout-demo

# View events
kubectl get events --sort-by='.lastTimestamp' | grep nginx-rollout-demo
```

## Cleanup

When you're done testing:

```bash
# Delete the application
kubectl delete -f k8s/

# Delete ArgoCD application
kubectl delete -f argocd/application.yaml

# Delete ArgoCD
kubectl delete namespace argocd

# Delete Argo Rollouts
kubectl delete namespace argo-rollouts

# Delete EKS cluster (this will take 10-15 minutes)
eksctl delete cluster --name argo-demo-cluster --region us-east-1
```

## Troubleshooting Common Issues

### Issue: LoadBalancer pending
```bash
# Check AWS Load Balancer Controller is installed
kubectl get deployment -n kube-system aws-load-balancer-controller

# If not installed, install it:
# Follow: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
```

### Issue: Image pull error
```bash
# Check if image exists in Docker Hub
# Verify Docker Hub credentials in GitHub Secrets
# Check if image tag matches in rollout.yaml
```

### Issue: ArgoCD not syncing
```bash
# Check ArgoCD application status
argocd app get nginx-rollout-demo

# Force sync
argocd app sync nginx-rollout-demo --force

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-server
```

### Issue: Rollout stuck
```bash
# Check rollout status
kubectl argo rollouts get rollout nginx-rollout-demo

# Check pod status
kubectl get pods -l app=nginx-rollout-demo

# Promote manually if needed
kubectl argo rollouts promote nginx-rollout-demo
```

## Next Steps

1. **Set up monitoring**: Add Prometheus and Grafana for metrics
2. **Add analysis**: Configure Argo Rollouts analysis for automated rollback
3. **Configure notifications**: Set up Slack/email notifications for deployments
4. **Add more environments**: Create staging and production environments
5. **Implement blue-green**: Try blue-green deployment strategy

## Additional Resources

- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

Need help? Open an issue in the repository!
