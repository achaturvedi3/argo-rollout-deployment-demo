# Helm Chart for Canary Demo with AWS Load Balancer Controller

This Helm chart deploys the nginx canary-demo application with Argo Rollouts, AWS Load Balancer Controller, and External DNS support.

## Prerequisites

1. **Kubernetes Cluster**: AWS EKS cluster (v1.24+)
2. **Helm**: Version 3.x
3. **AWS Load Balancer Controller**: Installed in your cluster
4. **External DNS**: Installed and configured for Route53
5. **Argo Rollouts**: Installed in your cluster

### Install Prerequisites

```bash
# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Install External DNS
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm install external-dns external-dns/external-dns \
  -n kube-system \
  --set provider=aws \
  --set aws.region=us-east-1 \
  --set txtOwnerId=<your-hosted-zone-id>

# Install Argo Rollouts
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

## Configuration

### Basic Configuration

Create a `values-override.yaml` file:

```yaml
namespace: production

image:
  repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/canary-demo
  tag: "v1.0.0"

ingress:
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix

aws:
  region: us-east-1
  vpc:
    subnets: "subnet-12345678,subnet-87654321"
  certificate:
    arn: "arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"

externalDns:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.example.com

route53:
  hostedZoneId: "Z1234567890ABC"
  domainName: "example.com"
```

### Advanced Configuration

#### Enable WAF

```yaml
aws:
  waf:
    enabled: true
    arn: "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/example/xxxxx"
```

#### Custom Canary Strategy

```yaml
rollout:
  strategy:
    canary:
      steps:
        - setWeight: 20
          pause:
            duration: 1m
        - setWeight: 50
          pause:
            duration: 2m
        - setWeight: 80
          pause:
            duration: 2m
        - setWeight: 100
```

#### Multiple Hosts

```yaml
ingress:
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
    - host: app.example.com
      paths:
        - path: /api
          pathType: Prefix

externalDns:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.example.com,app.example.com
```

## Installation

### Install with Default Values

```bash
helm install canary-demo ./helm -n default
```

### Install with Custom Values

```bash
helm install canary-demo ./helm \
  -n production \
  --create-namespace \
  -f values-override.yaml
```

### Install with Command-Line Overrides

```bash
helm install canary-demo ./helm \
  --set image.repository=123456789012.dkr.ecr.us-east-1.amazonaws.com/canary-demo \
  --set image.tag=v1.0.0 \
  --set ingress.hosts[0].host=myapp.example.com \
  --set aws.certificate.arn=arn:aws:acm:us-east-1:123456789012:certificate/xxxxx \
  --set externalDns.annotations."external-dns\.alpha\.kubernetes\.io/hostname"=myapp.example.com
```

## Upgrade

```bash
# Upgrade to new version
helm upgrade canary-demo ./helm \
  -n production \
  -f values-override.yaml
```

## Uninstall

```bash
helm uninstall canary-demo -n production
```

## Verify Installation

### Check Rollout Status

```bash
kubectl argo rollouts get rollout canary-demo-rollout -n production --watch
```

### Check Services

```bash
kubectl get svc -n production -l app.kubernetes.io/name=canary-demo
```

### Check Ingress and ALB

```bash
kubectl get ingress -n production
kubectl describe ingress canary-demo-ingress -n production
```

### Check External DNS Logs

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns
```

### Get ALB URL

```bash
kubectl get ingress canary-demo-ingress -n production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Troubleshooting

### ALB Not Creating

1. Check AWS Load Balancer Controller logs:
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

2. Verify subnet tags:
```bash
# Public subnets should have:
kubernetes.io/role/elb=1

# Private subnets should have:
kubernetes.io/role/internal-elb=1
```

3. Verify IAM permissions for the Load Balancer Controller

### External DNS Not Creating Records

1. Check External DNS logs:
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns
```

2. Verify IAM permissions for External DNS
3. Check Route53 hosted zone ID matches

### Canary Rollout Issues

1. Check rollout status:
```bash
kubectl argo rollouts get rollout canary-demo-rollout -n production
```

2. Check rollout events:
```bash
kubectl describe rollout canary-demo-rollout -n production
```

3. View rollout logs:
```bash
kubectl logs -n production -l app=canary-demo
```

## IAM Permissions

### AWS Load Balancer Controller

The service account needs these permissions:
- elasticloadbalancing:*
- ec2:DescribeSubnets
- ec2:DescribeSecurityGroups
- ec2:DescribeVpcs
- iam:CreateServiceLinkedRole
- wafv2:AssociateWebACL (if using WAF)

### External DNS

The service account needs these permissions:
- route53:ChangeResourceRecordSets
- route53:ListResourceRecordSets
- route53:ListHostedZones

## Examples

See `examples/` directory for complete deployment scenarios:
- `examples/basic-deployment.yaml` - Basic setup
- `examples/production-deployment.yaml` - Production-ready configuration
- `examples/multi-environment.yaml` - Multiple environments

## Support

For issues and questions:
- GitHub Issues: [Your Repository]
- Documentation: [Your Docs Site]
