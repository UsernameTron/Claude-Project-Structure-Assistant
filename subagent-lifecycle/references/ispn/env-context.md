# ISPN Environment Context

Shared environment configuration for all ISPN deployment specialists.
**Single update point** — when Ali provides credentials, update THIS FILE ONLY.

---

## AWS / EKS

```
AWS_ACCOUNT_ID: PENDING
AWS_REGION: PENDING
EKS_CLUSTER_NAME: PENDING
EKS_DEV_NAMESPACE: PENDING
ECR_REGISTRY: PENDING
```

## Database (RDS PostgreSQL)

```
RDS_POSTGRES_HOST: PENDING
RDS_POSTGRES_PORT: 5432
RDS_POSTGRES_DB: PENDING
```

## External APIs

```
GENESYS_API_BASE_URL: https://api.mypurecloud.com
GENESYS_CLIENT_ID: PENDING (requires Charlie's security approval)
SHAREPOINT_SITE_URL: PENDING
GRAPH_API_TENANT_ID: PENDING
SLACK_WEBHOOK_URL: PENDING
```

## Infrastructure

```
NGINX_UPSTREAM: PENDING
GIT_REPO_URL: PENDING
```

## Labels

```
LABELS:
  team: ispn-workforce-intel
  owner: pete-connor
  phase: "2"
```
