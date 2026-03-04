# API Testing & Production Promotion Reference

Reference for the **quality-tester** specialist — Domains 26-27
(API testing, production promotion).

---

## Test Structure

```
tests/
├── conftest.py          # Shared fixtures (client, DB, test data)
├── test_health.py       # Health endpoint tests
├── test_{skill}.py      # Skill endpoint tests
├── test_middleware.py    # Middleware behavior tests
├── test_integration.py  # Full-stack integration tests
└── scripts/
    ├── curl_smoke.sh    # Quick curl smoke tests
    ├── compare.sh       # Compare output against baseline
    └── load_test.py     # Simple load testing
```

---

## pytest Configuration

### pyproject.toml

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
filterwarnings = ["ignore::DeprecationWarning"]
markers = [
    "integration: full-stack tests requiring database",
    "slow: tests that take more than 5 seconds",
]
```

### requirements-dev.txt

```
pytest>=8.0.0,<9.0.0
pytest-asyncio>=0.24.0,<1.0.0
httpx>=0.27.0,<1.0.0
pytest-cov>=5.0.0,<6.0.0
```

---

## Fixtures (conftest.py)

```python
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import create_app


@pytest.fixture
def app():
    """Create a fresh app instance for each test."""
    return create_app()


@pytest.fixture
async def client(app):
    """Async test client using httpx."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.fixture
def sample_date_range():
    """Standard test date range."""
    return {
        "start_date": "2025-01-01",
        "end_date": "2025-01-31",
    }
```

---

## Health Endpoint Tests

```python
import pytest


@pytest.mark.asyncio
async def test_health_returns_200(client):
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "uptime_seconds" in data
    assert "version" in data


@pytest.mark.asyncio
async def test_readiness_returns_200(client):
    response = await client.get("/api/v1/health/ready")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] in ("ready", "degraded")
```

---

## Skill Endpoint Tests

### Standard Request/Response Tests

```python
@pytest.mark.asyncio
async def test_analyze_valid_request(client, sample_date_range):
    response = await client.post("/api/v1/wcs-trends/analyze", json=sample_date_range)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"] is not None
    assert data["timestamp"] is not None


@pytest.mark.asyncio
async def test_analyze_invalid_date_range(client):
    response = await client.post("/api/v1/wcs-trends/analyze", json={
        "start_date": "2025-02-01",
        "end_date": "2025-01-01",  # end before start
    })
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_analyze_missing_fields(client):
    response = await client.post("/api/v1/wcs-trends/analyze", json={})
    assert response.status_code == 422  # Pydantic validation error
```

### Response Shape Validation

```python
@pytest.mark.asyncio
async def test_response_matches_schema(client, sample_date_range):
    response = await client.post("/api/v1/wcs-trends/analyze", json=sample_date_range)
    data = response.json()

    # Verify SkillResult envelope
    assert "success" in data
    assert "data" in data
    assert "timestamp" in data

    # Verify request_id propagation
    assert "X-Request-ID" in response.headers
```

### Error Response Tests

```python
@pytest.mark.asyncio
async def test_404_returns_json(client):
    response = await client.get("/api/v1/nonexistent")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_error_includes_request_id(client):
    response = await client.post("/api/v1/wcs-trends/analyze", json={
        "start_date": "not-a-date",
        "end_date": "also-not-a-date",
    })
    assert response.status_code == 422
```

---

## Middleware Tests

```python
@pytest.mark.asyncio
async def test_request_id_header_set(client):
    response = await client.get("/api/v1/health")
    assert "X-Request-ID" in response.headers
    assert len(response.headers["X-Request-ID"]) > 0


@pytest.mark.asyncio
async def test_custom_request_id_preserved(client):
    custom_id = "test-request-123"
    response = await client.get(
        "/api/v1/health",
        headers={"X-Request-ID": custom_id},
    )
    assert response.headers["X-Request-ID"] == custom_id


@pytest.mark.asyncio
async def test_response_time_header(client):
    response = await client.get("/api/v1/health")
    assert "X-Response-Time-Ms" in response.headers
    ms = float(response.headers["X-Response-Time-Ms"])
    assert ms >= 0


@pytest.mark.asyncio
async def test_cors_headers(client):
    response = await client.options(
        "/api/v1/health",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert "access-control-allow-origin" in response.headers
```

---

## Integration Tests

These require a running database. Mark them and skip in CI if DB is unavailable.

```python
import pytest


@pytest.mark.integration
@pytest.mark.asyncio
async def test_full_analysis_pipeline(client, sample_date_range):
    """End-to-end: upload data → analyze → verify results stored."""
    # 1. Upload test data
    with open("tests/fixtures/sample_wcs_data.xlsx", "rb") as f:
        upload_response = await client.post(
            "/api/v1/upload/excel",
            files={"file": ("test.xlsx", f, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")},
        )
    assert upload_response.status_code == 200

    # 2. Run analysis
    analysis_response = await client.post(
        "/api/v1/wcs-trends/analyze",
        json=sample_date_range,
    )
    assert analysis_response.status_code == 200
    assert analysis_response.json()["success"] is True

    # 3. Verify results endpoint returns data
    results_response = await client.get("/api/v1/wcs-trends/results")
    assert results_response.status_code == 200
    assert len(results_response.json()["data"]) > 0
```

---

## Curl Smoke Tests

### scripts/curl_smoke.sh

```bash
#!/bin/bash
# Quick smoke tests against a running API
# Usage: ./scripts/curl_smoke.sh [BASE_URL]

BASE="${1:-http://localhost:8000}"
PASS=0
FAIL=0

check() {
    local name="$1"
    local expected_status="$2"
    local actual_status="$3"

    if [ "$actual_status" -eq "$expected_status" ]; then
        echo "  PASS: $name (HTTP $actual_status)"
        ((PASS++))
    else
        echo "  FAIL: $name (expected $expected_status, got $actual_status)"
        ((FAIL++))
    fi
}

echo "Smoke tests against $BASE"
echo "========================="

# Health
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/v1/health")
check "GET /health" 200 "$STATUS"

# Readiness
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/v1/health/ready")
check "GET /health/ready" 200 "$STATUS"

# OpenAPI spec
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/v1/openapi.json")
check "GET /openapi.json" 200 "$STATUS"

# Valid skill request
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE/api/v1/wcs-trends/analyze" \
    -H "Content-Type: application/json" \
    -d '{"start_date":"2025-01-01","end_date":"2025-01-31"}')
check "POST /analyze (valid)" 200 "$STATUS"

# Invalid request
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE/api/v1/wcs-trends/analyze" \
    -H "Content-Type: application/json" \
    -d '{}')
check "POST /analyze (empty body)" 422 "$STATUS"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
```

---

## Comparison Tests

### Compare Current Output Against Baseline

```bash
#!/bin/bash
# scripts/compare.sh — Compare API output against known-good baseline
# Usage: ./scripts/compare.sh [BASE_URL]

BASE="${1:-http://localhost:8000}"
BASELINE_DIR="tests/baselines"

echo "Comparing API output against baselines..."

# Fetch current output
curl -s -X POST "$BASE/api/v1/wcs-trends/analyze" \
    -H "Content-Type: application/json" \
    -d '{"start_date":"2025-01-01","end_date":"2025-01-31"}' \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
# Remove volatile fields
data.pop('timestamp', None)
data.pop('request_id', None)
json.dump(data, sys.stdout, indent=2, sort_keys=True)
" > /tmp/current_output.json

# Compare
if diff -u "$BASELINE_DIR/analyze_jan2025.json" /tmp/current_output.json; then
    echo "PASS: Output matches baseline"
else
    echo "FAIL: Output differs from baseline"
    echo "  To update baseline: cp /tmp/current_output.json $BASELINE_DIR/analyze_jan2025.json"
    exit 1
fi
```

### Creating Baselines

```bash
# Generate baseline from known-good output
mkdir -p tests/baselines
curl -s -X POST http://localhost:8000/api/v1/wcs-trends/analyze \
    -H "Content-Type: application/json" \
    -d '{"start_date":"2025-01-01","end_date":"2025-01-31"}' \
    | python3 -m json.tool > tests/baselines/analyze_jan2025.json
```

---

## Load Tests

### scripts/load_test.py

```python
"""Simple load test using asyncio + httpx.
Usage: python scripts/load_test.py [URL] [CONCURRENT] [TOTAL]
"""

import asyncio
import sys
import time
import httpx


async def send_request(client: httpx.AsyncClient, url: str, payload: dict) -> float:
    start = time.perf_counter()
    response = await client.post(url, json=payload)
    duration = (time.perf_counter() - start) * 1000
    return duration, response.status_code


async def run_load_test(base_url: str, concurrent: int, total: int):
    url = f"{base_url}/api/v1/wcs-trends/analyze"
    payload = {"start_date": "2025-01-01", "end_date": "2025-01-31"}

    sem = asyncio.Semaphore(concurrent)
    results = []

    async def bounded_request(client):
        async with sem:
            return await send_request(client, url, payload)

    async with httpx.AsyncClient(timeout=30.0) as client:
        start = time.perf_counter()
        tasks = [bounded_request(client) for _ in range(total)]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        total_time = time.perf_counter() - start

    # Analyze results
    durations = []
    errors = 0
    for r in results:
        if isinstance(r, Exception):
            errors += 1
        else:
            duration, status = r
            durations.append(duration)
            if status >= 400:
                errors += 1

    durations.sort()
    print(f"\nLoad Test Results")
    print(f"=================")
    print(f"Total requests:  {total}")
    print(f"Concurrency:     {concurrent}")
    print(f"Total time:      {total_time:.2f}s")
    print(f"Requests/sec:    {total / total_time:.1f}")
    print(f"Errors:          {errors}")
    print(f"")
    if durations:
        print(f"Latency (ms):")
        print(f"  Min:    {durations[0]:.1f}")
        print(f"  Median: {durations[len(durations)//2]:.1f}")
        print(f"  P95:    {durations[int(len(durations)*0.95)]:.1f}")
        print(f"  P99:    {durations[int(len(durations)*0.99)]:.1f}")
        print(f"  Max:    {durations[-1]:.1f}")


if __name__ == "__main__":
    base = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"
    concurrent = int(sys.argv[2]) if len(sys.argv) > 2 else 10
    total = int(sys.argv[3]) if len(sys.argv) > 3 else 100
    asyncio.run(run_load_test(base, concurrent, total))
```

---

## Running Tests

```bash
# All tests
pytest

# With coverage
pytest --cov=app --cov-report=term-missing

# Skip integration tests
pytest -m "not integration"

# Only integration tests (requires running DB)
pytest -m integration

# Verbose with stdout
pytest -v -s

# Single test file
pytest tests/test_health.py

# Stop on first failure
pytest -x
```

---

## Production Promotion Workflow

### Innovation Lab Gate Progression

```
Development → Dev Cluster → Staging Review → Production
     │              │              │              │
     │              │              │              │
  Unit tests    Integration    Charlie's        Change
  pass locally  tests pass     security         advisory
                on EKS         review           board
```

### Pre-Promotion Checklist

Run this before requesting production deployment:

```markdown
## ISPN Skill Promotion Checklist: ${SKILL_NAME}

### Code Quality
- [ ] All unit tests pass (`pytest --cov=app`)
- [ ] Coverage above 80% on business logic
- [ ] No lint warnings (`ruff check app/`)
- [ ] No type errors (`mypy app/`)

### API Contract
- [ ] OpenAPI spec is current (`/api/v1/openapi.json`)
- [ ] All endpoints return typed Pydantic responses
- [ ] Error responses use ErrorResponse model
- [ ] Health check endpoint returns correct version

### Integration
- [ ] Smoke tests pass against dev cluster (`curl_smoke.sh`)
- [ ] Comparison tests match baselines (`compare.sh`)
- [ ] Load test shows acceptable latency (P95 < 500ms at 10 RPS)
- [ ] Database migrations run cleanly

### Security (Charlie's Requirements)
- [ ] No hardcoded secrets in code or config
- [ ] Container runs as non-root (UID 1000)
- [ ] ECR image scan shows no critical CVEs
- [ ] Network policies restrict pod communication
- [ ] IRSA configured (no AWS access keys)

### Infrastructure
- [ ] Dockerfile builds successfully
- [ ] K8s manifests apply without errors (`kubectl apply --dry-run=client`)
- [ ] HPA configured with sane min/max
- [ ] Resource requests/limits set
- [ ] Liveness and readiness probes configured

### Observability
- [ ] Structured JSON logging configured
- [ ] Request ID propagation working
- [ ] CloudWatch log group exists
- [ ] Key metrics logged (duration, status, errors)

### Sign-off
- [ ] Pete: Functional review
- [ ] Charlie: Security review
- [ ] Ali: Infrastructure capacity confirmation
```

### Readiness Assessment Template

```markdown
# Production Readiness: ${SKILL_NAME} v${VERSION}

## Summary
- **Skill**: ${SKILL_NAME}
- **Version**: ${VERSION}
- **Date**: ${DATE}
- **Author**: ${AUTHOR}

## Test Results
| Category | Result | Details |
|----------|--------|---------|
| Unit tests | PASS/FAIL | X/Y passed, Z% coverage |
| Integration tests | PASS/FAIL | X/Y passed |
| Smoke tests | PASS/FAIL | X/Y passed |
| Load test | PASS/FAIL | P95=${X}ms at ${Y} RPS |
| Security scan | PASS/FAIL | X critical, Y high, Z medium |

## Known Issues
- (List any known issues or limitations)

## Rollback Plan
1. `kubectl rollout undo deployment/ispn-${SKILL_NAME}`
2. Verify rollback: `kubectl rollout status deployment/ispn-${SKILL_NAME}`
3. Notify team via Slack

## Approval
- [ ] Developer sign-off
- [ ] Security sign-off
- [ ] Infrastructure sign-off
```
