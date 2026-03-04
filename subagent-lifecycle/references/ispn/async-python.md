# Async Python Reference

Reference for the **api-wrapper** specialist — Domain 2
(asyncio, httpx async, asyncpg, BackgroundTasks, connection pooling).

---

## asyncio Fundamentals for FastAPI

FastAPI runs on an async event loop. All I/O-bound operations (database queries,
HTTP calls, file reads) MUST be async to avoid blocking the loop.

### Rule: Never Block the Event Loop

```python
# WRONG — blocks the entire server while waiting
import requests
response = requests.get("https://api.example.com/data")  # sync HTTP

# RIGHT — yields control while waiting
import httpx
async with httpx.AsyncClient() as client:
    response = await client.get("https://api.example.com/data")  # async HTTP
```

```python
# WRONG — sync database call
import psycopg2
conn = psycopg2.connect(DATABASE_URL)  # blocks

# RIGHT — async database call
import asyncpg
conn = await asyncpg.connect(DATABASE_URL)  # non-blocking
```

### When to Use `async def` vs `def`

```python
# Use async def when the function does I/O
@router.get("/data")
async def get_data():
    result = await db.fetch("SELECT * FROM metrics")
    return result

# Use plain def for CPU-bound work (FastAPI runs it in a threadpool)
@router.get("/compute")
def compute_heavy():
    return heavy_cpu_computation()
```

### Running Sync Code in Async Context

When wrapping a sync skill that does CPU-heavy work:

```python
import asyncio
from functools import partial


async def run_sync_skill(skill_func, *args, **kwargs):
    """Run a synchronous skill function without blocking the event loop."""
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, partial(skill_func, *args, **kwargs))


# Usage
@router.post("/analyze")
async def analyze(params: DateRangeRequest):
    result = await run_sync_skill(
        analyze_trends,
        start_date=params.start_date,
        end_date=params.end_date,
    )
    return SkillResult(success=True, data=result)
```

---

## httpx Async Client

### Singleton Client with Connection Pooling

```python
# dependencies.py
import httpx

# Create ONE client for the app lifetime (connection pooling)
_http_client: httpx.AsyncClient | None = None


async def get_http_client() -> httpx.AsyncClient:
    global _http_client
    if _http_client is None:
        _http_client = httpx.AsyncClient(
            timeout=httpx.Timeout(
                connect=5.0,
                read=30.0,
                write=10.0,
                pool=5.0,
            ),
            limits=httpx.Limits(
                max_connections=100,
                max_keepalive_connections=20,
                keepalive_expiry=30,
            ),
            headers={"User-Agent": "ISPN-Skill-API/0.1.0"},
        )
    return _http_client


async def close_http_client():
    global _http_client
    if _http_client:
        await _http_client.aclose()
        _http_client = None
```

### Wire Into App Lifespan

```python
from app.dependencies import close_http_client

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await close_http_client()
```

### Making Async HTTP Calls

```python
from fastapi import Depends
from app.dependencies import get_http_client


@router.get("/external-data")
async def fetch_external(client: httpx.AsyncClient = Depends(get_http_client)):
    response = await client.get("https://api.external.com/data")
    response.raise_for_status()
    return response.json()
```

### Parallel Requests

```python
async def fetch_multiple_sources(client: httpx.AsyncClient):
    """Fetch from multiple APIs concurrently."""
    results = await asyncio.gather(
        client.get("https://api.genesys.com/queues"),
        client.get("https://graph.microsoft.com/v1.0/sites"),
        client.get("https://api.internal.com/metrics"),
        return_exceptions=True,
    )

    data = {}
    for i, result in enumerate(results):
        if isinstance(result, Exception):
            data[f"source_{i}"] = {"error": str(result)}
        else:
            data[f"source_{i}"] = result.json()
    return data
```

### Retry with Backoff

```python
async def fetch_with_retry(
    client: httpx.AsyncClient,
    url: str,
    max_retries: int = 3,
    backoff_factor: float = 0.5,
) -> httpx.Response:
    """Fetch with exponential backoff on transient failures."""
    for attempt in range(max_retries):
        try:
            response = await client.get(url)
            response.raise_for_status()
            return response
        except (httpx.ConnectTimeout, httpx.ReadTimeout, httpx.HTTPStatusError) as e:
            if attempt == max_retries - 1:
                raise
            if isinstance(e, httpx.HTTPStatusError) and e.response.status_code < 500:
                raise  # Don't retry client errors
            wait = backoff_factor * (2 ** attempt)
            await asyncio.sleep(wait)
```

---

## asyncpg (PostgreSQL)

### Connection Pool

```python
# dependencies.py
import asyncpg
from app.config import settings

_pool: asyncpg.Pool | None = None


async def init_db_pool():
    global _pool
    _pool = await asyncpg.create_pool(
        dsn=settings.DATABASE_URL.replace("+asyncpg", ""),  # asyncpg wants plain postgres://
        min_size=2,
        max_size=settings.DB_POOL_SIZE,
        max_inactive_connection_lifetime=300,
        command_timeout=30,
    )


async def close_db_pool():
    global _pool
    if _pool:
        await _pool.close()
        _pool = None


async def get_pool() -> asyncpg.Pool:
    if _pool is None:
        await init_db_pool()
    return _pool
```

### Wire Into Lifespan

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db_pool()
    yield
    await close_db_pool()
    await close_http_client()
```

### Query Patterns

```python
async def fetch_metrics(pool: asyncpg.Pool, start_date, end_date):
    """Fetch metrics using the connection pool."""
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT date, volume, trend_score
            FROM wcs_metrics
            WHERE date BETWEEN $1 AND $2
            ORDER BY date
            """,
            start_date,
            end_date,
        )
        return [dict(row) for row in rows]


async def insert_results(pool: asyncpg.Pool, results: list[dict]):
    """Batch insert using executemany."""
    async with pool.acquire() as conn:
        await conn.executemany(
            """
            INSERT INTO analysis_results (skill_name, run_date, result_json)
            VALUES ($1, $2, $3)
            """,
            [(r["skill"], r["date"], r["json"]) for r in results],
        )
```

### Transactions

```python
async def transfer_with_transaction(pool: asyncpg.Pool):
    async with pool.acquire() as conn:
        async with conn.transaction():
            await conn.execute("UPDATE accounts SET balance = balance - 100 WHERE id = 1")
            await conn.execute("UPDATE accounts SET balance = balance + 100 WHERE id = 2")
            # Rolls back automatically if either statement fails
```

---

## SQLAlchemy Async (Alternative to asyncpg)

When using SQLAlchemy ORM instead of raw asyncpg:

```python
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy import text
from app.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,  # postgresql+asyncpg://user:pass@host/db
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    pool_timeout=30,
    pool_recycle=300,
    echo=settings.ENVIRONMENT == "development",
)

async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_db():
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

### Rule: Choose One

- **asyncpg directly** — faster, less overhead, good for read-heavy skills with raw SQL
- **SQLAlchemy async** — better for complex models, migrations (Alembic), ORM patterns

Don't mix both in the same project.

---

## BackgroundTasks

For operations that should happen after the response is sent:

```python
from fastapi import BackgroundTasks


async def log_skill_execution(skill_name: str, duration_ms: float, success: bool):
    """Write execution record to DB (runs after response)."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(
            "INSERT INTO execution_log (skill, duration_ms, success) VALUES ($1, $2, $3)",
            skill_name, duration_ms, success,
        )


@router.post("/analyze", response_model=SkillResult)
async def analyze(
    params: DateRangeRequest,
    background_tasks: BackgroundTasks,
):
    start = time.perf_counter()
    result = await execute_skill(params)
    duration = (time.perf_counter() - start) * 1000

    # This runs AFTER the response is sent to the client
    background_tasks.add_task(
        log_skill_execution,
        skill_name="wcs-trends",
        duration_ms=duration,
        success=result.success,
    )

    return result
```

### When to Use BackgroundTasks vs a Job Queue

| Use BackgroundTasks | Use a Job Queue (Celery, etc.) |
|---------------------|-------------------------------|
| Logging, metrics | Long-running computations (>30s) |
| Cache warming | Scheduled/recurring tasks |
| Webhook notifications | Tasks that must survive server restart |
| Lightweight DB writes | Distributed processing |

For ISPN skills, BackgroundTasks covers most needs. Only use a job queue
if skill computation exceeds 30 seconds.

---

## Connection Pooling Summary

| Resource | Library | Pool Config |
|----------|---------|-------------|
| PostgreSQL | asyncpg | `min_size=2, max_size=DB_POOL_SIZE` |
| PostgreSQL (ORM) | SQLAlchemy async | `pool_size=DB_POOL_SIZE, max_overflow=DB_MAX_OVERFLOW` |
| HTTP clients | httpx | `max_connections=100, max_keepalive_connections=20` |

### Rules

1. **One pool per resource** — create at startup, close at shutdown
2. **Never create connections per request** — always use the pool
3. **Set timeouts** — `command_timeout` for DB, `Timeout` for HTTP
4. **Monitor pool exhaustion** — log when pool is at max capacity
5. **Graceful shutdown** — close pools in the lifespan `yield` block

---

## Async Patterns Cheatsheet

```python
# Run multiple independent tasks concurrently
results = await asyncio.gather(task_a(), task_b(), task_c())

# Run with timeout
result = await asyncio.wait_for(slow_operation(), timeout=10.0)

# Run sync function in threadpool (for CPU-bound or blocking libs)
result = await asyncio.get_event_loop().run_in_executor(None, sync_func, arg1)

# Create task that runs in background (fire-and-forget)
task = asyncio.create_task(background_operation())

# Semaphore to limit concurrency
sem = asyncio.Semaphore(5)
async with sem:
    await limited_operation()
```
