# Kubernetes Operations Reference

Reference for the **infra-builder** specialist — Domain 12 (Kubernetes operations).
Covers kubeconfig, namespaces, RBAC, port-forward, log streaming, pod debugging,
rollback, and scaling.

---

## Kubeconfig Setup

### Connect to EKS Cluster

```bash
# Update kubeconfig (values from env-context.md)
aws eks update-kubeconfig \
  --region ${AWS_REGION} \
  --name ${EKS_CLUSTER_NAME} \
  --alias ispn-dev

# Verify connection
kubectl cluster-info
kubectl get namespaces

# Set default namespace for session
kubectl config set-context --current --namespace=${EKS_DEV_NAMESPACE}
```

### Context Management

```bash
# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context ispn-dev

# View current context
kubectl config current-context
```

---

## Namespace Management

### Create Namespace for ISPN

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${EKS_DEV_NAMESPACE}
  labels:
    team: ispn-workforce-intel
    owner: pete-connor
    phase: "2"
```

### Resource Quotas (prevent runaway pods)

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ispn-dev-quota
  namespace: ${EKS_DEV_NAMESPACE}
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
    services: "10"
    persistentvolumeclaims: "5"
```

### LimitRange (sane defaults for pods without explicit limits)

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: ispn-default-limits
  namespace: ${EKS_DEV_NAMESPACE}
spec:
  limits:
    - type: Container
      default:
        cpu: 250m
        memory: 256Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
      max:
        cpu: "2"
        memory: 2Gi
```

---

## RBAC

### Namespace-Scoped Role for Developers

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ispn-developer
  namespace: ${EKS_DEV_NAMESPACE}
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log", "pods/exec", "services", "configmaps", "secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses", "networkpolicies"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: ["autoscaling"]
    resources: ["horizontalpodautoscalers"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
```

### RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ispn-developer-binding
  namespace: ${EKS_DEV_NAMESPACE}
subjects:
  - kind: User
    name: pete.connor
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ispn-developer
  apiGroup: rbac.authorization.k8s.io
```

### Rule: No cluster-admin for Application Service Accounts

Application pods use namespace-scoped ServiceAccounts with IRSA. Never bind
cluster-admin to a pod's service account.

---

## Pod Debugging

### Quick Status Check

```bash
# Overview of all resources in namespace
kubectl get all -n ${EKS_DEV_NAMESPACE}

# Pod status with restart counts
kubectl get pods -n ${EKS_DEV_NAMESPACE} -o wide

# Describe pod for events and conditions
kubectl describe pod ${POD_NAME} -n ${EKS_DEV_NAMESPACE}
```

### Common Failure Diagnosis

| Symptom | Command | Likely Cause |
|---------|---------|-------------|
| `CrashLoopBackOff` | `kubectl logs ${POD} --previous` | App crash — check logs from previous container |
| `ImagePullBackOff` | `kubectl describe pod ${POD}` | Wrong image tag, ECR auth expired, or image doesn't exist |
| `Pending` | `kubectl describe pod ${POD}` | Insufficient resources, node selector mismatch, or PVC not bound |
| `OOMKilled` | `kubectl describe pod ${POD}` | Memory limit too low — increase `resources.limits.memory` |
| `CreateContainerConfigError` | `kubectl describe pod ${POD}` | Missing ConfigMap or Secret referenced in env |
| `Init:Error` | `kubectl logs ${POD} -c init-${NAME}` | Init container failing — check migration or health check |

### Exec Into Running Pod

```bash
# Interactive shell
kubectl exec -it ${POD_NAME} -n ${EKS_DEV_NAMESPACE} -- /bin/sh

# Run a specific command
kubectl exec ${POD_NAME} -n ${EKS_DEV_NAMESPACE} -- python -c "import app; print(app.__version__)"

# If multiple containers in pod
kubectl exec -it ${POD_NAME} -c ${CONTAINER_NAME} -n ${EKS_DEV_NAMESPACE} -- /bin/sh
```

### Ephemeral Debug Container (when no shell in image)

```bash
kubectl debug -it ${POD_NAME} \
  --image=busybox:1.36 \
  --target=${CONTAINER_NAME} \
  -n ${EKS_DEV_NAMESPACE}
```

---

## Log Streaming

### Single Pod

```bash
# Current logs
kubectl logs ${POD_NAME} -n ${EKS_DEV_NAMESPACE}

# Follow (stream) logs
kubectl logs -f ${POD_NAME} -n ${EKS_DEV_NAMESPACE}

# Last 100 lines
kubectl logs --tail=100 ${POD_NAME} -n ${EKS_DEV_NAMESPACE}

# Logs from previous crashed container
kubectl logs ${POD_NAME} --previous -n ${EKS_DEV_NAMESPACE}

# Since timestamp
kubectl logs --since=1h ${POD_NAME} -n ${EKS_DEV_NAMESPACE}
```

### All Pods in Deployment

```bash
# Stream logs from all pods with a label
kubectl logs -f -l app=ispn-${SKILL_NAME} -n ${EKS_DEV_NAMESPACE}

# With timestamps
kubectl logs -f -l app=ispn-${SKILL_NAME} --timestamps -n ${EKS_DEV_NAMESPACE}

# All containers (including sidecars)
kubectl logs -f -l app=ispn-${SKILL_NAME} --all-containers -n ${EKS_DEV_NAMESPACE}
```

---

## Port Forwarding

### Access a Service Locally

```bash
# Forward service port to localhost
kubectl port-forward svc/ispn-${SKILL_NAME} 8080:80 -n ${EKS_DEV_NAMESPACE}

# Forward specific pod
kubectl port-forward pod/${POD_NAME} 8080:8000 -n ${EKS_DEV_NAMESPACE}

# Access RDS via port-forward through a debug pod
kubectl run pg-tunnel --rm -it --image=alpine/socat \
  -- TCP-LISTEN:5432,fork TCP:${RDS_POSTGRES_HOST}:5432
```

### Test After Port Forward

```bash
# Health check
curl http://localhost:8080/api/v1/health

# API endpoint
curl http://localhost:8080/api/v1/${SKILL_NAME}/status
```

---

## Deployments & Rollbacks

### Check Deployment Status

```bash
# Rollout status
kubectl rollout status deployment/ispn-${SKILL_NAME} -n ${EKS_DEV_NAMESPACE}

# Rollout history
kubectl rollout history deployment/ispn-${SKILL_NAME} -n ${EKS_DEV_NAMESPACE}

# View specific revision
kubectl rollout history deployment/ispn-${SKILL_NAME} --revision=3 -n ${EKS_DEV_NAMESPACE}
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/ispn-${SKILL_NAME} -n ${EKS_DEV_NAMESPACE}

# Rollback to specific revision
kubectl rollout undo deployment/ispn-${SKILL_NAME} --to-revision=2 -n ${EKS_DEV_NAMESPACE}

# Verify rollback
kubectl rollout status deployment/ispn-${SKILL_NAME} -n ${EKS_DEV_NAMESPACE}
kubectl get pods -l app=ispn-${SKILL_NAME} -n ${EKS_DEV_NAMESPACE}
```

### Update Image (trigger new rollout)

```bash
kubectl set image deployment/ispn-${SKILL_NAME} \
  ${SKILL_NAME}=${ECR_REGISTRY}/ispn/${SKILL_NAME}:${NEW_TAG} \
  -n ${EKS_DEV_NAMESPACE}
```

---

## Scaling

### Manual Scaling

```bash
# Scale replicas
kubectl scale deployment/ispn-${SKILL_NAME} --replicas=3 -n ${EKS_DEV_NAMESPACE}

# Scale to zero (stop without deleting)
kubectl scale deployment/ispn-${SKILL_NAME} --replicas=0 -n ${EKS_DEV_NAMESPACE}
```

### Horizontal Pod Autoscaler

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
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
        - type: Pods
          value: 2
          periodSeconds: 60
```

### Check HPA Status

```bash
kubectl get hpa -n ${EKS_DEV_NAMESPACE}
kubectl describe hpa ispn-${SKILL_NAME}-hpa -n ${EKS_DEV_NAMESPACE}
```

---

## Resource Inspection

### Quick Cheatsheet

```bash
# All resources in namespace
kubectl get all -n ${EKS_DEV_NAMESPACE}

# Pods with labels
kubectl get pods --show-labels -n ${EKS_DEV_NAMESPACE}

# Services and endpoints
kubectl get svc,endpoints -n ${EKS_DEV_NAMESPACE}

# ConfigMaps and Secrets (names only)
kubectl get configmaps,secrets -n ${EKS_DEV_NAMESPACE}

# Ingress rules
kubectl get ingress -n ${EKS_DEV_NAMESPACE}

# Events sorted by time (useful for debugging)
kubectl get events --sort-by='.lastTimestamp' -n ${EKS_DEV_NAMESPACE}

# Resource usage (requires metrics-server)
kubectl top pods -n ${EKS_DEV_NAMESPACE}
kubectl top nodes
```

### YAML Export (for inspection or backup)

```bash
# Export current deployment YAML
kubectl get deployment ispn-${SKILL_NAME} -n ${EKS_DEV_NAMESPACE} -o yaml > deployment-backup.yaml

# Dry-run apply to diff against current state
kubectl diff -f deployment.yaml
```

---

## Troubleshooting Workflow

When a deployment fails, follow this sequence:

```
1. kubectl get pods -n ${NS}           → Check pod status
2. kubectl describe pod ${POD} -n ${NS} → Check events & conditions
3. kubectl logs ${POD} -n ${NS}        → Check application logs
4. kubectl logs ${POD} --previous      → Check crash logs (if CrashLoopBackOff)
5. kubectl get events --sort-by='.lastTimestamp' -n ${NS} → Cluster events
6. kubectl top pods -n ${NS}           → Resource pressure
7. kubectl exec -it ${POD} -- /bin/sh  → Interactive debugging
```

If the pod never starts (Pending), check:
- `kubectl describe pod` for scheduling failures
- `kubectl get nodes` for node capacity
- `kubectl get pvc` for unbound persistent volume claims
