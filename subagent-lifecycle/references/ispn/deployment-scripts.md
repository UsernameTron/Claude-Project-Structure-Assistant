# Deployment Scripts Reference

Reference for the **deployer** specialist — Domain 21
(Bash/Shell build/push/deploy scripts, ECR auth, cluster setup, CI/CD, Git workflow).

---

## ECR Build & Push

### Full Build-Push Script

```bash
#!/bin/bash
# scripts/build-push.sh — Build Docker image and push to ECR
# Usage: ./scripts/build-push.sh [TAG]
set -euo pipefail

# Load from env-context or environment
: "${AWS_REGION:?AWS_REGION not set}"
: "${ECR_REGISTRY:?ECR_REGISTRY not set}"
: "${SKILL_NAME:?SKILL_NAME not set}"

TAG="${1:-$(git rev-parse --short HEAD)}"
IMAGE="${ECR_REGISTRY}/ispn/${SKILL_NAME}"

echo "=== Building ${IMAGE}:${TAG} ==="

# 1. ECR login
echo "Authenticating with ECR..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# 2. Ensure repository exists
aws ecr describe-repositories --repository-names "ispn/${SKILL_NAME}" 2>/dev/null || \
  aws ecr create-repository \
    --repository-name "ispn/${SKILL_NAME}" \
    --image-scanning-configuration scanOnPush=true \
    --tags Key=team,Value=ispn-workforce-intel Key=owner,Value=pete-connor

# 3. Build (multi-platform for EKS amd64 nodes)
echo "Building image..."
DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/amd64 \
  -t "${IMAGE}:${TAG}" \
  -t "${IMAGE}:latest" \
  --push \
  .

echo "=== Pushed ${IMAGE}:${TAG} ==="

# 4. Wait for scan results
echo "Waiting for vulnerability scan..."
aws ecr wait image-scan-complete \
  --repository-name "ispn/${SKILL_NAME}" \
  --image-id imageTag="${TAG}" \
  --region "${AWS_REGION}" 2>/dev/null || true

# 5. Report scan findings
CRITICAL=$(aws ecr describe-image-scan-findings \
  --repository-name "ispn/${SKILL_NAME}" \
  --image-id imageTag="${TAG}" \
  --query 'imageScanFindings.findingSeverityCounts.CRITICAL' \
  --output text 2>/dev/null || echo "0")

if [ "${CRITICAL}" != "0" ] && [ "${CRITICAL}" != "None" ]; then
  echo "WARNING: ${CRITICAL} critical vulnerabilities found!"
  echo "Run: aws ecr describe-image-scan-findings --repository-name ispn/${SKILL_NAME} --image-id imageTag=${TAG}"
fi

echo "Done."
```

### Quick Build (Local Only)

```bash
#!/bin/bash
# scripts/build-local.sh — Build for local testing only
set -euo pipefail

SKILL_NAME="${SKILL_NAME:-my-skill}"
docker build -t "ispn-${SKILL_NAME}:dev" .
echo "Built ispn-${SKILL_NAME}:dev"
echo "Run: docker compose up"
```

---

## kubectl Deploy

### Full Deploy Script

```bash
#!/bin/bash
# scripts/deploy.sh — Deploy to EKS
# Usage: ./scripts/deploy.sh [TAG] [NAMESPACE]
set -euo pipefail

: "${AWS_REGION:?AWS_REGION not set}"
: "${EKS_CLUSTER_NAME:?EKS_CLUSTER_NAME not set}"
: "${ECR_REGISTRY:?ECR_REGISTRY not set}"
: "${SKILL_NAME:?SKILL_NAME not set}"

TAG="${1:-latest}"
NAMESPACE="${2:-${EKS_DEV_NAMESPACE:-ispn-dev}}"
IMAGE="${ECR_REGISTRY}/ispn/${SKILL_NAME}:${TAG}"

echo "=== Deploying ${SKILL_NAME} to ${NAMESPACE} ==="

# 1. Ensure kubeconfig is current
aws eks update-kubeconfig \
  --region "${AWS_REGION}" \
  --name "${EKS_CLUSTER_NAME}" \
  --alias ispn-dev 2>/dev/null

# 2. Verify cluster access
kubectl cluster-info > /dev/null 2>&1 || {
  echo "ERROR: Cannot reach cluster ${EKS_CLUSTER_NAME}"
  exit 1
}

# 3. Create namespace if it doesn't exist
kubectl get namespace "${NAMESPACE}" > /dev/null 2>&1 || \
  kubectl create namespace "${NAMESPACE}"

# 4. Apply manifests
echo "Applying manifests..."
kubectl apply -f k8s/base/ -n "${NAMESPACE}"

# 5. Update image tag
echo "Setting image to ${IMAGE}..."
kubectl set image "deployment/ispn-${SKILL_NAME}" \
  "${SKILL_NAME}=${IMAGE}" \
  -n "${NAMESPACE}"

# 6. Wait for rollout
echo "Waiting for rollout..."
kubectl rollout status "deployment/ispn-${SKILL_NAME}" \
  -n "${NAMESPACE}" \
  --timeout=120s

# 7. Verify
echo ""
echo "=== Deployment Status ==="
kubectl get pods -l "app=ispn-${SKILL_NAME}" -n "${NAMESPACE}"
echo ""

# 8. Quick health check via port-forward
echo "Running health check..."
kubectl port-forward "svc/ispn-${SKILL_NAME}" 8080:80 -n "${NAMESPACE}" &
PF_PID=$!
sleep 3

HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/health 2>/dev/null || echo "000")
kill $PF_PID 2>/dev/null || true

if [ "${HEALTH}" = "200" ]; then
  echo "Health check: PASS"
else
  echo "Health check: FAIL (HTTP ${HEALTH})"
  echo "Check logs: kubectl logs -l app=ispn-${SKILL_NAME} -n ${NAMESPACE}"
  exit 1
fi

echo ""
echo "=== Deployed ${SKILL_NAME}:${TAG} to ${NAMESPACE} ==="
```

### Rollback Script

```bash
#!/bin/bash
# scripts/rollback.sh — Rollback to previous deployment
set -euo pipefail

NAMESPACE="${1:-${EKS_DEV_NAMESPACE:-ispn-dev}}"

echo "Rolling back ispn-${SKILL_NAME} in ${NAMESPACE}..."
kubectl rollout undo "deployment/ispn-${SKILL_NAME}" -n "${NAMESPACE}"
kubectl rollout status "deployment/ispn-${SKILL_NAME}" -n "${NAMESPACE}" --timeout=60s

echo "Current pods:"
kubectl get pods -l "app=ispn-${SKILL_NAME}" -n "${NAMESPACE}"
```

---

## kubectl Cheatsheet

### Daily Operations

```bash
# Status
kubectl get all -n ${NS}
kubectl get pods -l app=ispn-${SKILL} -n ${NS}
kubectl describe pod ${POD} -n ${NS}

# Logs
kubectl logs -f -l app=ispn-${SKILL} -n ${NS}
kubectl logs ${POD} --previous -n ${NS}

# Debug
kubectl exec -it ${POD} -n ${NS} -- /bin/sh
kubectl port-forward svc/ispn-${SKILL} 8080:80 -n ${NS}

# Scale
kubectl scale deployment/ispn-${SKILL} --replicas=3 -n ${NS}
kubectl scale deployment/ispn-${SKILL} --replicas=0 -n ${NS}

# Rollout
kubectl rollout status deployment/ispn-${SKILL} -n ${NS}
kubectl rollout undo deployment/ispn-${SKILL} -n ${NS}
kubectl rollout history deployment/ispn-${SKILL} -n ${NS}

# Cleanup
kubectl delete deployment ispn-${SKILL} -n ${NS}
kubectl delete all -l app=ispn-${SKILL} -n ${NS}
```

### Useful One-Liners

```bash
# Get pod names for a skill
kubectl get pods -l app=ispn-${SKILL} -n ${NS} -o name

# Watch pods in real time
kubectl get pods -n ${NS} -w

# Events sorted by time
kubectl get events --sort-by='.lastTimestamp' -n ${NS}

# Resource usage
kubectl top pods -n ${NS}

# Export current deployment YAML
kubectl get deployment ispn-${SKILL} -n ${NS} -o yaml > deployment-snapshot.yaml

# Diff manifest against live state
kubectl diff -f k8s/base/deployment.yaml

# Force restart all pods (no config change needed)
kubectl rollout restart deployment/ispn-${SKILL} -n ${NS}
```

---

## CI/CD Patterns

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yaml
name: Build & Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  AWS_REGION: ${{ vars.AWS_REGION }}
  ECR_REGISTRY: ${{ vars.ECR_REGISTRY }}
  EKS_CLUSTER_NAME: ${{ vars.EKS_CLUSTER_NAME }}
  SKILL_NAME: ${{ vars.SKILL_NAME }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt -r requirements-dev.txt
      - run: ruff check app/
      - run: pytest --cov=app --cov-report=term-missing

  build-push:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}
      - uses: aws-actions/amazon-ecr-login@v2
      - name: Build & push
        run: |
          TAG="${{ github.sha }}"
          docker build -t ${ECR_REGISTRY}/ispn/${SKILL_NAME}:${TAG} \
                        -t ${ECR_REGISTRY}/ispn/${SKILL_NAME}:latest .
          docker push ${ECR_REGISTRY}/ispn/${SKILL_NAME}:${TAG}
          docker push ${ECR_REGISTRY}/ispn/${SKILL_NAME}:latest

  deploy:
    needs: build-push
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}
      - run: |
          aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
          kubectl set image deployment/ispn-${SKILL_NAME} \
            ${SKILL_NAME}=${ECR_REGISTRY}/ispn/${SKILL_NAME}:${{ github.sha }} \
            -n ispn-dev
          kubectl rollout status deployment/ispn-${SKILL_NAME} -n ispn-dev --timeout=120s
```

### Manual Deploy Gate

For skills not ready for full CI/CD, use a manual approval:

```yaml
  deploy:
    needs: build-push
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval in GitHub settings
    steps:
      - ...
```

---

## Git Workflow for ISPN Skills

### Branch Strategy

```
main                    — latest stable, deploys to dev cluster
release/v{X.Y.Z}       — production release candidate
feat/{feature-name}     — feature development
fix/{bug-name}          — bug fixes
```

### Commit Conventions

```
feat: Add WCS volume trend endpoint
fix: Handle empty date range in analysis
refactor: Extract DB queries to service layer
docs: Update API documentation
test: Add integration tests for upload endpoint
chore: Update requirements.txt dependencies
deploy: Bump image tag to v0.3.1
```

### Release Script

```bash
#!/bin/bash
# scripts/release.sh — Tag and prepare a release
set -euo pipefail

VERSION="${1:?Usage: ./scripts/release.sh v0.1.0}"

echo "=== Releasing ${VERSION} ==="

# Verify clean state
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working directory not clean"
  exit 1
fi

# Verify tests pass
echo "Running tests..."
pytest --tb=short || { echo "Tests failed"; exit 1; }

# Tag
git tag -a "${VERSION}" -m "Release ${VERSION}"
echo "Tagged ${VERSION}"

# Build and push with version tag
./scripts/build-push.sh "${VERSION}"

echo ""
echo "=== Release ${VERSION} ready ==="
echo "Push tag:  git push origin ${VERSION}"
echo "Deploy:    ./scripts/deploy.sh ${VERSION}"
```

---

## Environment Setup Script

### scripts/setup-env.sh

```bash
#!/bin/bash
# One-time environment setup for a new developer
set -euo pipefail

echo "=== ISPN Dev Environment Setup ==="

# 1. Python virtual environment
if [ ! -d ".venv" ]; then
  echo "Creating virtual environment..."
  python3 -m venv .venv
fi
source .venv/bin/activate

# 2. Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt -r requirements-dev.txt

# 3. Copy env template
if [ ! -f ".env" ]; then
  echo "Creating .env from template..."
  cat > .env << 'ENVEOF'
SKILL_NAME=my-skill
ENVIRONMENT=development
LOG_LEVEL=debug
DATABASE_URL=postgresql+asyncpg://ispn:devpassword@localhost:5432/ispn_dev
CORS_ORIGINS=["http://localhost:3000"]
ENVEOF
  echo "Edit .env with your settings"
fi

# 4. Start local services
echo "Starting local PostgreSQL..."
docker compose up -d postgres
sleep 3

# 5. Verify
echo ""
echo "=== Setup Complete ==="
echo "Activate:  source .venv/bin/activate"
echo "Run API:   uvicorn app.main:app --reload"
echo "Run tests: pytest"
echo "Local DB:  postgresql://ispn:devpassword@localhost:5432/ispn_dev"
```
