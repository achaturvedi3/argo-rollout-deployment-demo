# Helm Chart Quick Reference

## Installation Commands

### Basic Installation
```bash
# Install with default values
helm install canary-demo ./helm -n default

# Install with custom values
helm install canary-demo ./helm -n production --create-namespace -f helm/examples/production-deployment.yaml

# Install with inline overrides
helm install canary-demo ./helm \
  --set image.tag=v1.2.0 \
  --set ingress.hosts[0].host=myapp.example.com \
  --set aws.certificate.arn=arn:aws:acm:us-east-1:123456789012:certificate/xxxxx
```

### Using Install Script
```bash
# Basic installation
./helm/install.sh

# With custom values
./helm/install.sh -n my-release -ns production -f myvalues.yaml --create-namespace

# Dry-run first
./helm/install.sh --dry-run -f helm/examples/production-deployment.yaml
```

## Upgrade Commands

```bash
# Upgrade release
helm upgrade canary-demo ./helm -n production -f helm/examples/production-deployment.yaml

# Upgrade with new image tag
helm upgrade canary-demo ./helm -n production --set image.tag=v2.0.0

# Force upgrade
helm upgrade canary-demo ./helm -n production --force -f helm/examples/production-deployment.yaml
```

## Rollback Commands

```bash
# List revisions
helm history canary-demo -n production

# Rollback to previous version
helm rollback canary-demo -n production

# Rollback to specific revision
helm rollback canary-demo 3 -n production
```

## Management Commands

```bash
# List releases
helm list -n production

# Get release status
helm status canary-demo -n production

# Get release values
helm get values canary-demo -n production

# Get all release information
helm get all canary-demo -n production

# Uninstall release
helm uninstall canary-demo -n production
```

## Verification Commands

### Check Rollout
```bash
# Watch rollout status
kubectl argo rollouts get rollout canary-demo-rollout -n production --watch

# Describe rollout
kubectl describe rollout canary-demo-rollout -n production

# Get rollout events
kubectl get events -n production --sort-by='.lastTimestamp' | grep canary-demo
```

### Check Services and Ingress
```bash
# Get services
kubectl get svc -n production -l app.kubernetes.io/instance=canary-demo

# Get ingress
kubectl get ingress -n production -l app.kubernetes.io/instance=canary-demo

# Get ALB hostname
kubectl get ingress -n production -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

### Check Pods and Logs
```bash
# Get pods
kubectl get pods -n production -l app.kubernetes.io/instance=canary-demo

# View logs
kubectl logs -n production -l app.kubernetes.io/instance=canary-demo -f

# Describe pod
kubectl describe pod <pod-name> -n production
```

## Argo Rollouts Commands

### Promote Canary
```bash
# Promote to next step
kubectl argo rollouts promote canary-demo-rollout -n production

# Full promotion
kubectl argo rollouts promote canary-demo-rollout -n production --full
```

### Abort Rollout
```bash
# Abort and rollback
kubectl argo rollouts abort canary-demo-rollout -n production
```

### Restart Rollout
```bash
# Restart rollout
kubectl argo rollouts restart canary-demo-rollout -n production
```

### Set Image
```bash
# Update image
kubectl argo rollouts set image canary-demo-rollout -n production \
  nginx=123456789012.dkr.ecr.us-east-1.amazonaws.com/canary-demo:v2.0.0
```

## Debugging Commands

### AWS Load Balancer Controller
```bash
# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=100 -f

# Check controller status
kubectl get deployment -n kube-system aws-load-balancer-controller

# Describe ingress for ALB details
kubectl describe ingress canary-demo-ingress -n production
```

### External DNS
```bash
# Check External DNS logs
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns --tail=100 -f

# Verify DNS records
dig canary-demo.example.com

# Check Route53 records
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890ABC
```

### Network Debugging
```bash
# Test connectivity from inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://canary-demo-root.production.svc.cluster.local

# Test ALB endpoint
curl -H "Host: canary-demo.example.com" http://<ALB-DNS-NAME>

# Check service endpoints
kubectl get endpoints -n production
```

## Helm Template Testing

```bash
# Render templates locally
helm template canary-demo ./helm -f helm/examples/production-deployment.yaml

# Render specific template
helm template canary-demo ./helm -s templates/rollout.yaml

# Debug template rendering
helm install canary-demo ./helm --dry-run --debug -f helm/examples/production-deployment.yaml
```

## Common Issues and Fixes

### Issue: ALB not created
```bash
# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Verify subnet tags
aws ec2 describe-subnets --subnet-ids subnet-12345678 --query 'Subnets[0].Tags'

# Check IAM role
kubectl describe sa aws-load-balancer-controller -n kube-system
```

### Issue: DNS records not created
```bash
# Check External DNS logs
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns

# Verify hosted zone
aws route53 get-hosted-zone --id Z1234567890ABC

# Check service account IAM
kubectl describe sa external-dns -n kube-system
```

### Issue: Rollout stuck
```bash
# Check rollout status
kubectl argo rollouts get rollout canary-demo-rollout -n production

# Check pod events
kubectl get events -n production --field-selector involvedObject.name=<pod-name>

# Force abort and retry
kubectl argo rollouts abort canary-demo-rollout -n production
kubectl argo rollouts restart canary-demo-rollout -n production
```

## Configuration Examples

### Update Image Tag
```bash
helm upgrade canary-demo ./helm -n production \
  --reuse-values \
  --set image.tag=v2.0.0
```

### Update Replicas
```bash
helm upgrade canary-demo ./helm -n production \
  --reuse-values \
  --set rollout.replicas=10
```

### Change Domain
```bash
helm upgrade canary-demo ./helm -n production \
  --reuse-values \
  --set ingress.hosts[0].host=newdomain.example.com \
  --set externalDns.annotations."external-dns\.alpha\.kubernetes\.io/hostname"=newdomain.example.com
```

### Enable WAF
```bash
helm upgrade canary-demo ./helm -n production \
  --reuse-values \
  --set aws.waf.enabled=true \
  --set aws.waf.arn=arn:aws:wafv2:region:account:regional/webacl/name/id
```

## Monitoring

### Watch Rollout Progress
```bash
# Terminal 1: Watch rollout
kubectl argo rollouts get rollout canary-demo-rollout -n production --watch

# Terminal 2: Watch pods
watch kubectl get pods -n production -l app.kubernetes.io/instance=canary-demo

# Terminal 3: Test traffic
while true; do curl -s http://canary-demo.example.com | grep version; sleep 1; done
```

### Check Metrics
```bash
# Get resource usage
kubectl top pods -n production -l app.kubernetes.io/instance=canary-demo

# Check HPA (if enabled)
kubectl get hpa -n production
```

## Backup and Restore

### Backup Release
```bash
# Export values
helm get values canary-demo -n production > backup-values.yaml

# Export all manifests
helm get manifest canary-demo -n production > backup-manifest.yaml
```

### Restore Release
```bash
# Install from backup
helm install canary-demo ./helm -n production -f backup-values.yaml
```
