# Contributing to Argo Rollouts Canary Demo

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/argo-rollout-deployment-demo.git
   cd argo-rollout-deployment-demo
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Testing Local Changes

#### Test Docker Image
```bash
# Build image
./scripts/build-image.sh v1

# Test locally
docker run -d -p 8080:80 --name test canary-demo:v1
curl http://localhost:8080
docker stop test && docker rm test
```

#### Test Kubernetes Manifests
```bash
# Validate YAML syntax
yamllint k8s/*.yaml argocd/*.yaml

# Dry-run apply
kubectl apply -f k8s/ --dry-run=client

# Apply to test cluster
kubectl apply -f k8s/
```

### Code Style

#### YAML Files
- Use 2-space indentation
- Keep lines under 120 characters when possible
- Add comments for complex configurations

#### Shell Scripts
- Use shellcheck for linting
- Follow Google Shell Style Guide
- Add comments for non-obvious operations

#### HTML/CSS
- Use semantic HTML
- Keep CSS organized by component
- Ensure responsive design

## Pull Request Process

1. Update documentation for any changed functionality
2. Test your changes thoroughly:
   - Build Docker images
   - Validate Kubernetes manifests
   - Test deployment flow
3. Update README.md if adding new features
4. Create a Pull Request with:
   - Clear title describing the change
   - Detailed description of what changed and why
   - Screenshots for UI changes
   - Test results

### PR Title Format
```
<type>: <description>

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Code style changes (formatting, etc.)
- refactor: Code refactoring
- test: Adding or updating tests
- chore: Maintenance tasks
```

### PR Description Template
```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Configuration change

## Testing
- [ ] Tested locally with Docker
- [ ] Tested on Kubernetes cluster
- [ ] Updated documentation
- [ ] All existing tests pass

## Screenshots (if applicable)
Add screenshots showing the changes

## Additional Notes
Any additional information
```

## Reporting Issues

When reporting issues, please include:

1. **Description**: Clear description of the issue
2. **Steps to Reproduce**: Detailed steps to reproduce the problem
3. **Expected Behavior**: What you expected to happen
4. **Actual Behavior**: What actually happened
5. **Environment**:
   - Kubernetes version
   - ArgoCD version
   - Argo Rollouts version
   - Cloud provider (AWS, GCP, Azure, etc.)
6. **Logs**: Relevant logs and error messages
7. **Screenshots**: If applicable

### Issue Template
```markdown
## Description
Clear description of the issue

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Kubernetes version:
- ArgoCD version:
- Argo Rollouts version:
- Cloud provider:

## Logs
```
Paste relevant logs here
```

## Screenshots
Add screenshots if applicable
```

## Feature Requests

Feature requests are welcome! Please include:

1. **Use Case**: Why is this feature needed?
2. **Proposed Solution**: How should it work?
3. **Alternatives**: Any alternative solutions considered?
4. **Additional Context**: Any other relevant information

## Development Setup

### Prerequisites
- Docker
- Kubernetes cluster (local or cloud)
- kubectl
- ArgoCD
- Argo Rollouts

### Installation
See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed setup instructions.

## Areas for Contribution

We welcome contributions in these areas:

### Application Enhancements
- Additional version styles
- Real-time metrics display
- WebSocket support for live updates
- Additional health check endpoints

### Deployment Features
- Support for different traffic routing methods (ALB, Istio, etc.)
- AnalysisTemplates for metrics-based promotion
- Notification integrations (Slack, email, etc.)
- Blue-green deployment strategy example

### CI/CD Improvements
- Support for additional container registries
- Multi-environment deployment (dev, staging, prod)
- Automated testing in pipeline
- Security scanning integration

### Documentation
- Video tutorials
- More examples
- Troubleshooting guides
- Architecture diagrams

### Testing
- Unit tests
- Integration tests
- End-to-end tests

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive experience for everyone.

### Our Standards

- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment or discrimination of any kind
- Trolling or insulting comments
- Public or private harassment
- Publishing others' private information
- Other conduct inappropriate in a professional setting

## Questions?

If you have questions:

1. Check existing documentation
2. Search existing issues
3. Create a new issue with the "question" label

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing! 🚀
