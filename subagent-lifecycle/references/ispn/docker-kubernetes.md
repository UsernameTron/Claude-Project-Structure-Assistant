# Docker & Kubernetes Manifests Reference

Reference for the **infra-builder** specialist — Domains 9-11, 13-14
(Docker, Docker networking, Kubernetes manifests, NGINX/BFF, Dockerfile DSL).

---

## Dockerfile Templates

### Standard Python/FastAPI (Production)

```dockerfile
# ---- Build stage ----
FROM python:3.12-slim AS builder

WORKDIR /build

# Install dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Runtime stage ----
FROM python:3.12-slim AS runtime

# Security: non-root user
RUN groupadd -r appuser && useradd -r -g appuser -u 1000 appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY ./app ./app

# Security: no root
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/v1/health')" || exit 1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
```

### Dockerfile Rules

1. **Always multi-stage** — build dependencies stay out of runtime image
2. **Always non-root** — `USER appuser` (UID 1000) before CMD
3. **Always HEALTHCHECK** — K8s liveness probe can use it, but include it for Docker standalone too
4. **Copy requirements.txt before code** — maximizes layer cache hits
5. **No `--no-cache-dir` on runtime** — use it on builder to keep image small
6. **Pin base image tags** — `python:3.12-slim`, not `python:latest`
7. **No secrets in build args** — use runtime env vars or K8s Secrets

### .dockerignore

```
.git
.gitignore
__pycache__
*.pyc
*.pyo
.pytest_cache
.mypy_cache
.venv
venv
env
.env
.env.*
*.md
docs/
tests/
*.tar.gz
.DS_Store
.claude/
node_modules/
```

---

## Docker Compose (Local Development)

### Full Stack: API + PostgreSQL + NGINX

```yaml
version: "3.9"

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ispn-${SKILL_NAME}-api
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+asyncpg://ispn:devpassword@postgres:5432/ispn_dev
      - LOG_LEVEL=debug
      - ENVIRONMENT=development
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - ispn-net
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/v1/health')"]
      interval: 10s
      timeout: 5s
      retries: 3

  postgres:
    image: postgres:16-alpine
    container_name: ispn-${SKILL_NAME}-db
    environment:
      POSTGRES_USER: ispn
      POSTGRES_PASSWORD: devpassword
      POSTGRES_DB: ispn_dev
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./migrations/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - ispn-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ispn -d ispn_dev"]
      interval: 5s
      timeout: 3s
      retries: 5

  nginx:
    image: nginx:1.25-alpine
    container_name: ispn-${SKILL_NAME}-nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      api:
        condition: service_healthy
    networks:
      - ispn-net

networks:
  ispn-net:
    driver: bridge

volumes:
  pgdata:
```

---

## Docker Networking

### Bridge Networks

All ISPN services communicate on a shared bridge network (`ispn-net`).
Containers reference each other by service name (Docker DNS).

```bash
# Verify network
docker network inspect ispn-net

# Test DNS resolution from inside a container
docker exec ispn-${SKILL_NAME}-api ping postgres
```

### Multi-Service Local Dev

When running multiple skills locally, use a shared external network:

```bash
# Create shared network once
docker network create ispn-shared

# In each skill's docker-compose.yaml
networks:
  ispn-shared:
    external: true
```

This lets skill A call skill B's API by container name.

---

## Kubernetes Manifests

### Complete Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ispn-${SKILL_NAME}
  namespace: ${EKS_DEV_NAMESPACE}
  labels:
    app: ispn-${SKILL_NAME}
    team: ispn-workforce-intel
    owner: pete-connor
    phase: "2"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ispn-${SKILL_NAME}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: ispn-${SKILL_NAME}
        team: ispn-workforce-intel
    spec:
      serviceAccountName: ispn-${SKILL_NAME}-sa
      containers:
        - name: ${SKILL_NAME}
          image: ${ECR_REGISTRY}/ispn/${SKILL_NAME}:latest
          ports:
            - containerPort: 8000
              protocol: TCP
          env:
            - name: ENVIRONMENT
              value: "development"
            - name: LOG_LEVEL
              value: "info"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: ispn-${SKILL_NAME}-secrets
                  key: DATABASE_URL
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /api/v1/health
              port: 8000
            initialDelaySeconds: 10
            periodSeconds: 30
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /api/v1/health
              port: 8000
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3
          startupProbe:
            httpGet:
              path: /api/v1/health
              port: 8000
            failureThreshold: 30
            periodSeconds: 2
      restartPolicy: Always
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ispn-${SKILL_NAME}
  namespace: ${EKS_DEV_NAMESPACE}
  labels:
    app: ispn-${SKILL_NAME}
    team: ispn-workforce-intel
spec:
  type: ClusterIP
  selector:
    app: ispn-${SKILL_NAME}
  ports:
    - port: 80
      targetPort: 8000
      protocol: TCP
```

### ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ispn-${SKILL_NAME}-config
  namespace: ${EKS_DEV_NAMESPACE}
data:
  ENVIRONMENT: "development"
  LOG_LEVEL: "info"
  LOG_FORMAT: "json"
  CORS_ORIGINS: "http://localhost:3000"
  API_PREFIX: "/api/v1"
```

### Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ispn-${SKILL_NAME}-secrets
  namespace: ${EKS_DEV_NAMESPACE}
type: Opaque
stringData:
  DATABASE_URL: "postgresql+asyncpg://${DB_USER}:${DB_PASS}@${RDS_POSTGRES_HOST}:${RDS_POSTGRES_PORT}/${RDS_POSTGRES_DB}"
  GENESYS_CLIENT_SECRET: ""
  SLACK_WEBHOOK_URL: ""
```

### ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ispn-${SKILL_NAME}-sa
  namespace: ${EKS_DEV_NAMESPACE}
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/ispn-${SKILL_NAME}-role
  labels:
    app: ispn-${SKILL_NAME}
    team: ispn-workforce-intel
```

### Ingress (ALB Ingress Controller)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ispn-${SKILL_NAME}-ingress
  namespace: ${EKS_DEV_NAMESPACE}
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: ${ACM_CERT_ARN}
    alb.ingress.kubernetes.io/healthcheck-path: /api/v1/health
  labels:
    app: ispn-${SKILL_NAME}
spec:
  rules:
    - host: ${SKILL_NAME}.ispn.internal
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ispn-${SKILL_NAME}
                port:
                  number: 80
```

### NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ispn-${SKILL_NAME}-netpol
  namespace: ${EKS_DEV_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: ispn-${SKILL_NAME}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ${EKS_DEV_NAMESPACE}
      ports:
        - protocol: TCP
          port: 8000
  egress:
    # Allow DNS
    - to: []
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    # Allow RDS
    - to:
        - ipBlock:
            cidr: 10.0.0.0/8
      ports:
        - protocol: TCP
          port: 5432
    # Allow HTTPS outbound (external APIs)
    - to: []
      ports:
        - protocol: TCP
          port: 443
```

### HorizontalPodAutoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ispn-${SKILL_NAME}-hpa
  namespace: ${EKS_DEV_NAMESPACE}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ispn-${SKILL_NAME}
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### CronJob (Scheduled Tasks)

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ispn-${SKILL_NAME}-daily-refresh
  namespace: ${EKS_DEV_NAMESPACE}
spec:
  schedule: "0 6 * * *"  # 6 AM UTC daily
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      backoffLimit: 2
      template:
        metadata:
          labels:
            app: ispn-${SKILL_NAME}
            job-type: scheduled
        spec:
          serviceAccountName: ispn-${SKILL_NAME}-sa
          containers:
            - name: refresh
              image: ${ECR_REGISTRY}/ispn/${SKILL_NAME}:latest
              command: ["python", "-m", "app.tasks.daily_refresh"]
              env:
                - name: DATABASE_URL
                  valueFrom:
                    secretKeyRef:
                      name: ispn-${SKILL_NAME}-secrets
                      key: DATABASE_URL
              resources:
                requests:
                  cpu: 100m
                  memory: 256Mi
                limits:
                  cpu: 500m
                  memory: 512Mi
          restartPolicy: Never
```

---

## NGINX / BFF Configuration

### Reverse Proxy to FastAPI

```nginx
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format json_combined escape=json
        '{'
        '"time":"$time_iso8601",'
        '"remote_addr":"$remote_addr",'
        '"request":"$request",'
        '"status":$status,'
        '"body_bytes_sent":$body_bytes_sent,'
        '"request_time":$request_time,'
        '"upstream_response_time":"$upstream_response_time",'
        '"http_user_agent":"$http_user_agent"'
        '}';

    access_log /var/log/nginx/access.log json_combined;
    error_log /var/log/nginx/error.log warn;

    # Upstream: FastAPI backend
    upstream api_backend {
        server ispn-${SKILL_NAME}-api:8000;
        keepalive 32;
    }

    server {
        listen 80;
        server_name _;

        # Health check for NGINX itself
        location /nginx-health {
            access_log off;
            return 200 "ok";
            add_header Content-Type text/plain;
        }

        # API proxy
        location /api/ {
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Request-ID $request_id;

            # Timeouts
            proxy_connect_timeout 10s;
            proxy_send_timeout 30s;
            proxy_read_timeout 60s;

            # Buffering
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 4k;
        }

        # Static files (if serving frontend)
        location / {
            root /usr/share/nginx/html;
            try_files $uri $uri/ /index.html;
        }

        # Block dotfiles
        location ~ /\. {
            deny all;
            return 404;
        }
    }
}
```

### BFF Pattern (Backend for Frontend)

When the React frontend needs to call multiple ISPN skills, use NGINX as a BFF:

```nginx
# Route to different skill backends
location /api/v1/wcs/ {
    proxy_pass http://ispn-wcs-trends-api:8000/api/v1/;
}

location /api/v1/adherence/ {
    proxy_pass http://ispn-adherence-api:8000/api/v1/;
}

location /api/v1/forecasting/ {
    proxy_pass http://ispn-forecasting-api:8000/api/v1/;
}
```

The frontend calls one domain. NGINX routes to the correct skill backend.

---

## Dockerfile DSL Patterns

### Layer Optimization

```dockerfile
# BAD — breaks cache on every code change
COPY . .
RUN pip install -r requirements.txt

# GOOD — dependencies cached separately from code
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY ./app ./app
```

### Build Cache with BuildKit

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Build with cache mount (keeps pip cache between builds)
docker build --progress=plain -t ispn-${SKILL_NAME} .
```

```dockerfile
# BuildKit cache mount for pip
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt
```

### Multi-Architecture Builds

```bash
# Build for AMD64 (EKS nodes) from ARM Mac
docker buildx build --platform linux/amd64 \
  -t ${ECR_REGISTRY}/ispn/${SKILL_NAME}:latest \
  --push .
```

### Image Size Reduction

```dockerfile
# Use slim base
FROM python:3.12-slim

# Remove apt cache after install
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Use .dockerignore to exclude tests, docs, .git
```

### Security Scanning

```bash
# Scan image for vulnerabilities
docker scout cves ispn-${SKILL_NAME}:latest

# Or use ECR scanning results
aws ecr describe-image-scan-findings \
  --repository-name ispn/${SKILL_NAME} \
  --image-id imageTag=latest
```

---

## Manifest Organization

### Recommended File Structure

```
k8s/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── serviceaccount.yaml
│   └── networkpolicy.yaml
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   ├── secrets.yaml
│   │   └── ingress.yaml
│   └── prod/
│       ├── kustomization.yaml
│       ├── secrets.yaml
│       ├── ingress.yaml
│       └── hpa.yaml
└── kustomization.yaml
```

### Apply Manifests

```bash
# Apply all manifests in directory
kubectl apply -f k8s/base/ -n ${EKS_DEV_NAMESPACE}

# Apply with kustomize
kubectl apply -k k8s/overlays/dev/

# Dry run (validate without applying)
kubectl apply -f k8s/base/ --dry-run=client

# Diff against live state
kubectl diff -f k8s/base/
```

---

## Quick Reference: Label Convention

All ISPN resources use these labels consistently:

```yaml
labels:
  app: ispn-${SKILL_NAME}         # Required: identifies the skill
  team: ispn-workforce-intel      # Required: team ownership
  owner: pete-connor              # Required: individual owner
  phase: "2"                      # Required: Innovation Lab phase
  version: ${IMAGE_TAG}           # Optional: image version
  job-type: scheduled             # Optional: for CronJob pods
```
