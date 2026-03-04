# Logging & Observability Reference

Reference for the **deployer** specialist — Domain 25
(Structured JSON logs, CloudWatch, request metrics, correlation IDs, monitoring pipeline input).

---

## Structured JSON Logging

### Setup (Python/FastAPI)

```python
# app/logging_config.py
import logging
import json
import sys
from datetime import datetime, timezone


class JSONFormatter(logging.Formatter):
    """Structured JSON log formatter for CloudWatch."""

    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        # Add extra fields (request_id, duration_ms, etc.)
        for key in ("request_id", "method", "path", "status_code",
                     "duration_ms", "skill_name", "user_ip", "error_type"):
            value = getattr(record, key, None)
            if value is not None:
                log_entry[key] = value

        # Add exception info
        if record.exc_info and record.exc_info[0] is not None:
            log_entry["exception"] = {
                "type": record.exc_info[0].__name__,
                "message": str(record.exc_info[1]),
                "traceback": self.formatException(record.exc_info),
            }

        return json.dumps(log_entry, default=str)


def configure_logging(level: str = "INFO"):
    """Configure structured logging for the application."""
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JSONFormatter())

    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(handler)
    root_logger.setLevel(getattr(logging, level.upper()))

    # Quiet noisy libraries
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.error").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
```

### Wire Into App Startup

```python
from app.logging_config import configure_logging
from app.config import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    configure_logging(settings.LOG_LEVEL)
    yield
```

### Log Output Example

Every log line is a single JSON object — one per line, parsed natively by CloudWatch:

```json
{"timestamp":"2025-03-04T14:22:33.123456+00:00","level":"INFO","logger":"ispn.api","message":"request_completed","request_id":"abc-123","method":"POST","path":"/api/v1/wcs-trends/analyze","status_code":200,"duration_ms":142.5}
```

---

## Correlation IDs (Request ID Propagation)

### How It Works

```
Client → NGINX → FastAPI middleware → Service → Database
         │          │                    │          │
         │     generates UUID       propagates   logs with
         │     if missing            request_id  request_id
         │          │                    │          │
         └──────────┴────────────────────┴──────────┘
                    X-Request-ID header
```

### Middleware Implementation

```python
# app/middleware/request_id.py
import uuid
import contextvars
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

# Context variable — available everywhere in the async call chain
request_id_var: contextvars.ContextVar[str] = contextvars.ContextVar("request_id", default="")


class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Accept from upstream or generate
        rid = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        request_id_var.set(rid)
        request.state.request_id = rid

        response = await call_next(request)
        response.headers["X-Request-ID"] = rid
        return response
```

### Using Request ID in Service Code

```python
import logging
from app.middleware.request_id import request_id_var

logger = logging.getLogger("ispn.service")


async def execute_skill(params):
    rid = request_id_var.get()
    logger.info("skill_execution_start", extra={
        "request_id": rid,
        "skill_name": "wcs-trends",
    })

    result = await _run_computation(params)

    logger.info("skill_execution_complete", extra={
        "request_id": rid,
        "skill_name": "wcs-trends",
        "success": result.success,
    })
    return result
```

### Propagating to External HTTP Calls

```python
async def call_external_api(client: httpx.AsyncClient, url: str):
    rid = request_id_var.get()
    response = await client.get(url, headers={"X-Request-ID": rid})
    return response
```

---

## Request Metrics

### What to Log on Every Request

```python
# Logged by RequestLoggingMiddleware (see fastapi-patterns.md)
{
    "request_id": "abc-123",
    "method": "POST",
    "path": "/api/v1/wcs-trends/analyze",
    "status_code": 200,
    "duration_ms": 142.5,
    "user_ip": "10.0.1.15",
}
```

### Skill-Level Metrics

```python
# Logged by the service layer
{
    "request_id": "abc-123",
    "skill_name": "wcs-trends",
    "event": "skill_execution_complete",
    "duration_ms": 130.2,
    "success": true,
    "rows_processed": 1500,
    "cache_hit": false,
}
```

### Error Metrics

```python
# Logged by the error handler
{
    "request_id": "abc-123",
    "level": "ERROR",
    "error_type": "DatabaseError",
    "message": "connection refused",
    "path": "/api/v1/wcs-trends/analyze",
    "exception": {
        "type": "ConnectionRefusedError",
        "message": "...",
        "traceback": "..."
    }
}
```

---

## CloudWatch Integration

### Log Group Structure

```
/ispn/${EKS_DEV_NAMESPACE}/${SKILL_NAME}/api       # Application logs
/ispn/${EKS_DEV_NAMESPACE}/${SKILL_NAME}/nginx      # NGINX access/error logs
/ispn/${EKS_DEV_NAMESPACE}/${SKILL_NAME}/cronjob    # Scheduled task logs
```

### Kubernetes → CloudWatch (Fluent Bit)

EKS ships container stdout to CloudWatch via Fluent Bit (typically pre-installed
on managed node groups). Your JSON logs are parsed automatically.

If Fluent Bit is not configured, use the CloudWatch agent:

```yaml
# ConfigMap for Fluent Bit log routing
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: ${EKS_DEV_NAMESPACE}
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush         5
        Log_Level     info
        Parsers_File  parsers.conf

    [INPUT]
        Name              tail
        Tag               ispn.*
        Path              /var/log/containers/ispn-*.log
        Parser            docker
        Refresh_Interval  10

    [OUTPUT]
        Name              cloudwatch_logs
        Match             ispn.*
        region            ${AWS_REGION}
        log_group_name    /ispn/${EKS_DEV_NAMESPACE}
        log_stream_prefix ${SKILL_NAME}/
        auto_create_group true
```

### CloudWatch Insights Queries

#### Request Latency (P50/P95/P99)

```
fields @timestamp, duration_ms
| filter logger = "ispn.api" and message = "request_completed"
| stats percentile(duration_ms, 50) as p50,
        percentile(duration_ms, 95) as p95,
        percentile(duration_ms, 99) as p99
  by bin(5m)
```

#### Error Rate

```
fields @timestamp, level
| filter level = "ERROR"
| stats count() as error_count by bin(5m)
```

#### Slowest Endpoints

```
fields path, duration_ms
| filter message = "request_completed"
| stats avg(duration_ms) as avg_ms,
        max(duration_ms) as max_ms,
        count() as requests
  by path
| sort avg_ms desc
| limit 10
```

#### Trace a Request by ID

```
fields @timestamp, @message
| filter request_id = "abc-123"
| sort @timestamp asc
```

#### Skill Execution Success Rate

```
fields skill_name, success
| filter message = "skill_execution_complete"
| stats count() as total,
        sum(case when success = 1 then 1 else 0 end) as successes
  by skill_name
| display skill_name, successes, total,
          (successes * 100.0 / total) as success_pct
```

---

## CloudWatch Alarms

### High Error Rate

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "ispn-${SKILL_NAME}-high-error-rate" \
  --metric-name Errors \
  --namespace "ISPN/${SKILL_NAME}" \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions "${SNS_TOPIC_ARN}" \
  --tags Key=team,Value=ispn-workforce-intel
```

### High Latency (P95)

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "ispn-${SKILL_NAME}-high-latency" \
  --metric-name Duration \
  --namespace "ISPN/${SKILL_NAME}" \
  --extended-statistic p95 \
  --period 300 \
  --threshold 500 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 3 \
  --alarm-actions "${SNS_TOPIC_ARN}"
```

---

## Custom Metrics (Embedded Metric Format)

CloudWatch Embedded Metric Format lets you emit custom metrics via logs
without a separate metrics API call:

```python
import json


def emit_metric(
    namespace: str,
    metric_name: str,
    value: float,
    unit: str = "Milliseconds",
    dimensions: dict = None,
):
    """Emit a CloudWatch metric via Embedded Metric Format."""
    dims = dimensions or {}
    metric_doc = {
        "_aws": {
            "Timestamp": int(__import__("time").time() * 1000),
            "CloudWatchMetrics": [
                {
                    "Namespace": namespace,
                    "Dimensions": [list(dims.keys())],
                    "Metrics": [{"Name": metric_name, "Unit": unit}],
                }
            ],
        },
        metric_name: value,
        **dims,
    }
    # Print as single JSON line — Fluent Bit sends to CloudWatch
    print(json.dumps(metric_doc))
```

### Usage

```python
# After each request
emit_metric(
    namespace=f"ISPN/{settings.SKILL_NAME}",
    metric_name="RequestDuration",
    value=duration_ms,
    unit="Milliseconds",
    dimensions={"Path": path, "StatusCode": str(status_code)},
)

# After each skill execution
emit_metric(
    namespace=f"ISPN/{settings.SKILL_NAME}",
    metric_name="SkillExecutionDuration",
    value=skill_duration_ms,
    unit="Milliseconds",
    dimensions={"SkillName": skill_name, "Success": str(success)},
)
```

---

## Monitoring Pipeline Input

The deployer specialist uses this logging output as input to the monitoring pipeline:

```
Application logs (JSON)
    │
    ├── stdout → Fluent Bit → CloudWatch Logs
    │                              │
    │                    CloudWatch Insights (queries)
    │                    CloudWatch Alarms (alerts)
    │                    CloudWatch Metrics (dashboards)
    │
    └── Embedded Metric Format → CloudWatch Metrics
                                       │
                                 CloudWatch Dashboard
                                 Slack alerts (via SNS → Lambda → webhook)
```

### Key Metrics to Dashboard

| Metric | Source | Alert Threshold |
|--------|--------|----------------|
| Request rate (RPS) | Request logs | N/A (informational) |
| Error rate (%) | Request logs, status >= 400 | > 5% over 5 min |
| P95 latency (ms) | Request logs, duration_ms | > 500ms over 15 min |
| Skill success rate (%) | Skill execution logs | < 95% over 10 min |
| Pod restart count | K8s events | > 3 in 15 min |
| CPU utilization (%) | K8s metrics-server | > 80% sustained |
| Memory utilization (%) | K8s metrics-server | > 85% sustained |

---

## Log Level Guidelines

| Level | When to Use | Example |
|-------|------------|---------|
| **DEBUG** | Development only — verbose detail | SQL queries, cache operations |
| **INFO** | Normal operations — request flow | `request_completed`, `skill_execution_complete` |
| **WARNING** | Degraded but functional | Cache miss, retry attempt, slow query |
| **ERROR** | Failed operation, needs attention | Unhandled exception, DB connection failed |
| **CRITICAL** | System-level failure | Cannot start, all DB connections exhausted |

### Rule: INFO in Production

Set `LOG_LEVEL=info` in production. Never run `debug` in production — it logs
sensitive data and overwhelms CloudWatch.
