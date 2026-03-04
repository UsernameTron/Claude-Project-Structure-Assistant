# AWS Security & IAM Reference

Reference for the **infra-builder** specialist — Domain 8 (AWS CLI & IAM).
Covers AWS CLI setup, IAM roles, VPC security posture, and the security argument for Charlie.

---

## AWS CLI Setup

### Initial Configuration

```bash
# Configure named profile for ISPN
aws configure --profile ispn-dev
# AWS Access Key ID: (from Ali)
# AWS Secret Access Key: (from Ali)
# Default region: (from env-context.md → AWS_REGION)
# Default output format: json

# Verify identity
aws sts get-caller-identity --profile ispn-dev

# Set as default for session
export AWS_PROFILE=ispn-dev
```

### ECR Authentication

```bash
# Login to ECR (required before docker push)
aws ecr get-login-password --region ${AWS_REGION} \
  | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Create repository if it doesn't exist
aws ecr create-repository \
  --repository-name ispn/${SKILL_NAME} \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256 \
  --tags Key=team,Value=ispn-workforce-intel Key=owner,Value=pete-connor
```

### EKS Cluster Access

```bash
# Update kubeconfig for the cluster
aws eks update-kubeconfig \
  --region ${AWS_REGION} \
  --name ${EKS_CLUSTER_NAME} \
  --profile ispn-dev

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

---

## IAM Roles & Policies

### Principle: Least Privilege Per Specialist

Each deployment gets its own IAM role. Never share roles across skills.

### EKS Pod Execution Role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### ECR Push Policy (for CI/CD or developer)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRPushPull",
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT_ID}:repository/ispn/*"
    },
    {
      "Sid": "ECRAuth",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}
```

### RDS Access Policy (for pods via IRSA)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RDSConnect",
      "Effect": "Allow",
      "Action": [
        "rds-db:connect"
      ],
      "Resource": "arn:aws:rds-db:${AWS_REGION}:${AWS_ACCOUNT_ID}:dbuser:*/ispn_app"
    }
  ]
}
```

### IRSA (IAM Roles for Service Accounts)

```yaml
# Kubernetes ServiceAccount with IAM role annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ispn-${SKILL_NAME}-sa
  namespace: ${EKS_DEV_NAMESPACE}
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/ispn-${SKILL_NAME}-role
  labels:
    team: ispn-workforce-intel
    owner: pete-connor
```

---

## VPC Security Posture

### Network Architecture Rules

1. **EKS cluster** runs in a private VPC with private subnets for worker nodes
2. **RDS** runs in private subnets, accessible only from within the VPC
3. **Public access** is via ALB/Ingress only — no direct pod exposure
4. **Inter-pod communication** restricted by NetworkPolicy (see docker-kubernetes.md)

### Security Groups

#### EKS Worker Nodes

```
Inbound:
  - Port 443 (HTTPS) from EKS control plane security group
  - Port 10250 (kubelet) from EKS control plane security group
  - All ports from self (node-to-node)

Outbound:
  - All traffic (required for pulling images, DNS, API calls)
```

#### RDS PostgreSQL

```
Inbound:
  - Port 5432 from EKS worker node security group ONLY
  - No public access

Outbound:
  - None required
```

#### ALB (Application Load Balancer)

```
Inbound:
  - Port 443 (HTTPS) from 0.0.0.0/0
  - Port 80 (HTTP) from 0.0.0.0/0 (redirect to HTTPS)

Outbound:
  - EKS worker node ports from target group
```

---

## Charlie's Security Argument

When presenting to Charlie for security approval, use this framework:

### 1. Attack Surface Minimization

- **No public endpoints** on pods — all traffic routes through ALB with WAF
- **No SSH access** to nodes — EKS managed node groups, debug via `kubectl exec`
- **No hardcoded secrets** — all credentials in K8s Secrets or AWS Secrets Manager
- **No root containers** — all Dockerfiles run as non-root user (UID 1000)
- **Image scanning** enabled on ECR push — blocks known CVEs

### 2. Access Control

- **IRSA** — pods authenticate to AWS via IAM roles, not access keys
- **RBAC** — namespace-scoped roles, no cluster-admin for application service accounts
- **Network policies** — pods can only talk to explicitly allowed services
- **RDS** — password auth + security group restriction to VPC only

### 3. Audit Trail

- **CloudTrail** — all AWS API calls logged
- **EKS audit logs** — all K8s API server requests logged
- **Application logs** — structured JSON to CloudWatch (see logging-observability.md)
- **ECR scan results** — vulnerability reports per image

### 4. Compliance Checklist for Charlie

```markdown
- [ ] All containers run as non-root (UID 1000)
- [ ] No AWS access keys in code, env vars, or ConfigMaps
- [ ] IRSA configured for AWS service access
- [ ] Network policies restrict inter-pod traffic
- [ ] ECR image scanning enabled with scanOnPush
- [ ] RDS accessible only from within VPC
- [ ] TLS termination at ALB (HTTPS only)
- [ ] K8s Secrets encrypted at rest (EKS default)
- [ ] No privileged containers or host networking
- [ ] CloudTrail and EKS audit logs enabled
```

---

## Secret Management

### Rule: Never Put Secrets in ConfigMaps

```yaml
# WRONG — secrets in ConfigMap
apiVersion: v1
kind: ConfigMap
data:
  DATABASE_URL: "postgres://user:password@host/db"  # NEVER

# RIGHT — use K8s Secret
apiVersion: v1
kind: Secret
metadata:
  name: ispn-${SKILL_NAME}-secrets
  namespace: ${EKS_DEV_NAMESPACE}
type: Opaque
stringData:
  DATABASE_URL: "postgres://user:password@host/db"
  GENESYS_CLIENT_SECRET: "..."
```

### For Production: AWS Secrets Manager

```bash
# Store secret
aws secretsmanager create-secret \
  --name ispn/${SKILL_NAME}/database-url \
  --secret-string "postgres://user:password@host/db" \
  --tags Key=team,Value=ispn-workforce-intel

# Retrieve in application
aws secretsmanager get-secret-value \
  --secret-id ispn/${SKILL_NAME}/database-url \
  --query SecretString --output text
```

### External Secrets Operator (if available on cluster)

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ispn-${SKILL_NAME}-secrets
  namespace: ${EKS_DEV_NAMESPACE}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: ispn-${SKILL_NAME}-secrets
  data:
    - secretKey: DATABASE_URL
      remoteRef:
        key: ispn/${SKILL_NAME}/database-url
```

---

## Tagging Strategy

All AWS resources created for ISPN skills MUST carry these tags:

```
team: ispn-workforce-intel
owner: pete-connor
phase: "2"
skill: ${SKILL_NAME}
environment: dev | staging | prod
managed-by: subagent-lifecycle
```

This enables cost tracking, resource cleanup, and audit filtering.
