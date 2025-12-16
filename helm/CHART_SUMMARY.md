# Helm Chart Summary

## Overview

A production-ready Helm chart for deploying the nginx canary-demo application with:
- ✅ **Argo Rollouts** for progressive canary deployments
- ✅ **AWS Load Balancer Controller** for ALB-based ingress
- ✅ **External DNS** for automatic Route53 record management
- ✅ **Complete security** with pod security contexts and RBAC
- ✅ **Multi-environment** support (dev, staging, production)

## Chart Structure

```
helm/
├── Chart.yaml                  # Chart metadata
├── values.yaml                 # Default configuration values
├── values.schema.json          # Values validation schema
├── .helmignore                 # Files to ignore when packaging
├── README.md                   # Detailed documentation
├── QUICK_REFERENCE.md          # Command reference guide
├── install.sh                  # Automated installation script
├── templates/                  # Kubernetes manifest templates
│   ├── _helpers.tpl           # Template helper functions
│   ├── NOTES.txt              # Post-installation notes
│   ├── serviceaccount.yaml    # Service account
│   ├── rollout.yaml           # Argo Rollout resource
│   ├── service.yaml           # Three services (stable, canary, root)
│   └── ingress.yaml           # ALB ingress with External DNS
└── examples/                   # Example values files
    ├── basic-deployment.yaml
    ├── production-deployment.yaml
    └── multi-environment.yaml
```

## Key Features

### 1. AWS Load Balancer Controller Integration
- Internet-facing or internal ALB
- Target type: IP (for EKS with Fargate compatibility)
- Custom health checks
- SSL/TLS termination with ACM certificates
- WAF integration support
- Access logging to S3
- Custom tags for cost allocation
- Load balancer grouping support

### 2. External DNS Integration
- Automatic Route53 record creation
- Custom TTL configuration
- Support for multiple hostnames
- Alias record support

### 3. Argo Rollouts Canary Strategy
- Progressive traffic shifting (10% → 30% → 60% → 100%)
- Configurable pause durations
- Auto-promotion or manual approval
- Automatic rollback on failure
- Integration with ALB target groups

### 4. Security Features
- Pod security context (non-root user)
- Read-only root filesystem
- Dropped all capabilities except NET_BIND_SERVICE
- Service account with IRSA support
- Network policies ready

### 5. Production Features
- Health probes (liveness and readiness)
- Resource requests and limits
- Pod anti-affinity for high availability
- Node selectors and tolerations
- Revision history management
- Configurable replica count

## Installation

### Quick Install
```bash
# Using the automated script
./helm/install.sh -n my-release -ns production -f helm/examples/production-deployment.yaml --create-namespace

# Or using Helm directly
helm install canary-demo ./helm \
  -n production \
  --create-namespace \
  -f helm/examples/production-deployment.yaml
```

### Prerequisites Checklist
- [ ] AWS EKS cluster running
- [ ] kubectl configured and connected
- [ ] Helm 3.x installed
- [ ] AWS Load Balancer Controller deployed
- [ ] External DNS deployed and configured
- [ ] Argo Rollouts installed
- [ ] IAM roles configured (IRSA)
- [ ] Subnet tags configured
- [ ] Route53 hosted zone created
- [ ] ACM certificate (for HTTPS)

## Configuration Examples

### Minimum Required Values
```yaml
namespace: production
image:
  repository: YOUR_ECR_REPO/canary-demo
  tag: v1.0.0
ingress:
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
aws:
  region: us-east-1
  vpc:
    subnets: "subnet-xxx,subnet-yyy"
externalDns:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.example.com
route53:
  hostedZoneId: "ZXXXXXXXXXXXXX"
  domainName: "example.com"
```

### Production Configuration
See `helm/examples/production-deployment.yaml` for a complete production setup including:
- HTTPS with ACM certificate
- WAF protection
- S3 access logs
- Pod anti-affinity
- Resource limits
- Security contexts
- Multiple replicas
- Manual canary promotion

## Deployment Workflow

1. **Install Prerequisites**
   ```bash
   # AWS Load Balancer Controller
   # External DNS
   # Argo Rollouts
   ```

2. **Prepare Values**
   ```bash
   cp helm/examples/basic-deployment.yaml my-values.yaml
   # Edit my-values.yaml with your settings
   ```

3. **Validate Configuration**
   ```bash
   helm install canary-demo ./helm -f my-values.yaml --dry-run --debug
   ```

4. **Deploy Application**
   ```bash
   helm install canary-demo ./helm -n production --create-namespace -f my-values.yaml
   ```

5. **Monitor Rollout**
   ```bash
   kubectl argo rollouts get rollout canary-demo-rollout -n production --watch
   ```

6. **Verify DNS**
   ```bash
   dig myapp.example.com
   ```

7. **Test Application**
   ```bash
   curl https://myapp.example.com/health
   ```

## Upgrade Process

### Update Image Version
```bash
# Update image tag
helm upgrade canary-demo ./helm -n production \
  --reuse-values \
  --set image.tag=v2.0.0

# Watch canary rollout
kubectl argo rollouts get rollout canary-demo-rollout -n production --watch

# Promote manually (if auto-promotion is disabled)
kubectl argo rollouts promote canary-demo-rollout -n production
```

### Rollback
```bash
# Abort current rollout
kubectl argo rollouts abort canary-demo-rollout -n production

# Or rollback Helm release
helm rollback canary-demo -n production
```

## Monitoring and Observability

### Check Rollout Status
```bash
kubectl argo rollouts get rollout canary-demo-rollout -n production --watch
```

### View Logs
```bash
kubectl logs -n production -l app.kubernetes.io/instance=canary-demo -f
```

### Check ALB Status
```bash
kubectl get ingress -n production
kubectl describe ingress canary-demo-ingress -n production
```

### Verify DNS Records
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns
```

## Troubleshooting

### Common Issues

1. **ALB Not Created**
   - Check AWS Load Balancer Controller logs
   - Verify subnet tags
   - Check IAM permissions

2. **DNS Records Not Created**
   - Check External DNS logs
   - Verify Route53 permissions
   - Check hosted zone ID

3. **Rollout Stuck**
   - Check pod status
   - Review rollout events
   - Verify health checks

See `QUICK_REFERENCE.md` for detailed debugging commands.

## IAM Requirements

### Load Balancer Controller Service Account
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs",
        "iam:CreateServiceLinkedRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### External DNS Service Account
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets",
        "route53:ListHostedZones"
      ],
      "Resource": "*"
    }
  ]
}
```

## Best Practices

1. **Use HTTPS in Production**
   - Always configure ACM certificate
   - Enable SSL redirect

2. **Enable WAF**
   - Protect against common attacks
   - Configure rate limiting

3. **Configure Access Logs**
   - Enable ALB access logs to S3
   - Use for debugging and auditing

4. **Set Resource Limits**
   - Define CPU and memory limits
   - Prevent resource exhaustion

5. **Use Manual Promotion in Production**
   - Set `autoPromotionEnabled: false`
   - Review metrics before promoting

6. **Tag Resources**
   - Use meaningful tags
   - Enable cost allocation

7. **Test in Lower Environments**
   - Use staging environment first
   - Validate configuration

8. **Monitor Rollouts**
   - Watch canary metrics
   - Set up alerts

## Next Steps

1. Customize values for your environment
2. Set up IAM roles with IRSA
3. Configure CI/CD pipeline
4. Set up monitoring and alerts
5. Document runbooks
6. Train team on rollout procedures

## Support

- **Documentation**: See `README.md` for detailed guide
- **Examples**: Check `examples/` directory
- **Quick Reference**: See `QUICK_REFERENCE.md` for commands
- **Installation**: Use `install.sh` for automated setup

## Version History

- **v1.0.0** - Initial release
  - Argo Rollouts support
  - AWS Load Balancer Controller integration
  - External DNS integration
  - Production-ready configuration
