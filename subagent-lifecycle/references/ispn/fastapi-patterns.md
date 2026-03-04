# FastAPI Patterns Reference

Reference for the **api-wrapper** specialist — Domains 1, 3, 4, 5, 6, 7
(Python/FastAPI, JSON schemas, packaging, middleware, file uploads, response caching).

---

## Project Structure

Every ISPN skill API follows this layout:

```
app/
├── __init__.py
├── main.py              # FastAPI app factory, router includes
├── config.py            # Settings via pydantic-settings
├── dependencies.py      # Shared dependencies (DB session, auth, etc.)
├── routers/
│   ├── __init__.py
│   ├── health.py        # /api/v1/health
│   └── {skill}.py       # /api/v1/{skill}/...
├── models/
│   ├── __init__.py
│   ├── requests.py      # Pydantic request models
│   └── responses.py     # Pydantic response models
├── services/
│   ├── __init__.py
│   └── {skill}.py       # Business logic (the actual skill)
├── middleware/
│   ├── __init__.py
│   ├── logging.py       # Request/response logging
│   ├── error_handler.py # Global exception handling
│   └── rate_limit.py    # Rate limiting
└── utils/
    ├── __init__.py
    └── cache.py          # Response caching
```

---

## App Factory

### main.py

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import health, skill_router
from app.middleware.logging import RequestLoggingMiddleware
from app.middleware.error_handler import register_exception_handlers


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: initialize DB pool, load models, warm caches
    yield
    # Shutdown: close DB pool, flush logs


def create_app() -> FastAPI:
    app = FastAPI(
        title=f"ISPN {settings.SKILL_NAME} API",
        version="0.1.0",
        docs_url="/api/v1/docs",
        openapi_url="/api/v1/openapi.json",
        lifespan=lifespan,
    )

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Custom middleware
    app.add_middleware(RequestLoggingMiddleware)

    # Exception handlers
    register_exception_handlers(app)

    # Routers
    app.include_router(health.router, prefix="/api/v1")
    app.include_router(skill_router.router, prefix="/api/v1")

    return app


app = create_app()
```

---

## Configuration

### config.py

```python
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    SKILL_NAME: str = "unnamed-skill"
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "info"
    LOG_FORMAT: str = "json"

    # Database
    DATABASE_URL: str = ""
    DB_POOL_SIZE: int = 5
    DB_MAX_OVERFLOW: int = 10

    # CORS
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]

    # Cache
    CACHE_TTL_SECONDS: int = 300
    CACHE_MAX_SIZE: int = 1000

    # API
    API_PREFIX: str = "/api/v1"
    RATE_LIMIT_PER_MINUTE: int = 60

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
```

---

## Health Check Endpoint

### routers/health.py

```python
import time
from fastapi import APIRouter, Response

router = APIRouter(tags=["health"])

START_TIME = time.time()


@router.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "uptime_seconds": round(time.time() - START_TIME, 1),
        "version": "0.1.0",
    }


@router.get("/health/ready")
async def readiness_check(response: Response):
    """Checks dependencies (DB, external APIs) are reachable."""
    checks = {}
    all_ok = True

    # Add dependency checks here:
    # checks["database"] = await check_db()
    # checks["redis"] = await check_redis()

    if not all_ok:
        response.status_code = 503

    return {"status": "ready" if all_ok else "degraded", "checks": checks}
```

---

## Pydantic Models

### Request Models (models/requests.py)

```python
from datetime import date
from pydantic import BaseModel, Field


class DateRangeRequest(BaseModel):
    """Standard date range input for ISPN skill queries."""
    start_date: date = Field(..., description="Start of analysis period")
    end_date: date = Field(..., description="End of analysis period")

    def model_post_init(self, __context):
        if self.start_date > self.end_date:
            raise ValueError("start_date must be before end_date")


class SkillExecutionRequest(BaseModel):
    """Wraps a skill execution with parameters."""
    skill_name: str = Field(..., min_length=1, max_length=100)
    parameters: dict = Field(default_factory=dict)
    include_metadata: bool = False
```

### Response Models (models/responses.py)

```python
from datetime import datetime
from pydantic import BaseModel, Field


class SkillResult(BaseModel):
    """Standard response envelope for all skill outputs."""
    success: bool
    data: dict | list | None = None
    error: str | None = None
    metadata: dict | None = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    request_id: str | None = None


class PaginatedResponse(BaseModel):
    """Paginated list response."""
    items: list
    total: int
    page: int
    page_size: int
    has_next: bool


class ErrorResponse(BaseModel):
    """Standard error response body."""
    error: str
    detail: str | None = None
    request_id: str | None = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
```

### Rule: Every Endpoint Returns a Typed Response

```python
# WRONG — untyped dict
@router.get("/results")
async def get_results():
    return {"data": [...]}

# RIGHT — typed model
@router.get("/results", response_model=SkillResult)
async def get_results():
    return SkillResult(success=True, data=[...])
```

---

## Skill Wrapper Pattern

### How to Wrap an Existing Python Skill

The core pattern: import the skill, call it in a service function, expose via router.

```python
# services/wcs_trends.py
from app.models.requests import DateRangeRequest
from app.models.responses import SkillResult

# Import the actual skill
from skills.wcs_volume_trends import analyze_trends


async def execute_wcs_trends(params: DateRangeRequest) -> SkillResult:
    """Wraps the WCS volume trends skill."""
    try:
        result = analyze_trends(
            start_date=params.start_date,
            end_date=params.end_date,
        )
        return SkillResult(success=True, data=result)
    except Exception as e:
        return SkillResult(success=False, error=str(e))
```

```python
# routers/wcs_trends.py
from fastapi import APIRouter
from app.models.requests import DateRangeRequest
from app.models.responses import SkillResult
from app.services.wcs_trends import execute_wcs_trends

router = APIRouter(prefix="/wcs-trends", tags=["WCS Trends"])


@router.post("/analyze", response_model=SkillResult)
async def analyze(params: DateRangeRequest):
    """Analyze WCS volume trends for a date range."""
    return await execute_wcs_trends(params)
```

---

## Middleware

### Request Logging (middleware/logging.py)

```python
import time
import uuid
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

logger = logging.getLogger("ispn.api")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        request.state.request_id = request_id

        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = round((time.perf_counter() - start) * 1000, 2)

        logger.info(
            "request_completed",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": duration_ms,
            },
        )

        response.headers["X-Request-ID"] = request_id
        response.headers["X-Response-Time-Ms"] = str(duration_ms)
        return response
```

### Global Error Handler (middleware/error_handler.py)

```python
import logging
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from app.models.responses import ErrorResponse

logger = logging.getLogger("ispn.api")


def register_exception_handlers(app: FastAPI):

    @app.exception_handler(ValueError)
    async def value_error_handler(request: Request, exc: ValueError):
        return JSONResponse(
            status_code=400,
            content=ErrorResponse(
                error="validation_error",
                detail=str(exc),
                request_id=getattr(request.state, "request_id", None),
            ).model_dump(mode="json"),
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        request_id = getattr(request.state, "request_id", None)
        logger.exception("unhandled_exception", extra={"request_id": request_id})
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(
                error="internal_error",
                detail="An unexpected error occurred",
                request_id=request_id,
            ).model_dump(mode="json"),
        )
```

### Rate Limiting (middleware/rate_limit.py)

```python
import time
from collections import defaultdict
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse
from app.config import settings


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Simple in-memory rate limiter. For production, use Redis."""

    def __init__(self, app):
        super().__init__(app)
        self.requests: dict[str, list[float]] = defaultdict(list)
        self.limit = settings.RATE_LIMIT_PER_MINUTE
        self.window = 60.0

    async def dispatch(self, request: Request, call_next):
        # Skip health checks
        if request.url.path.startswith("/api/v1/health"):
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        now = time.time()

        # Clean old entries
        self.requests[client_ip] = [
            t for t in self.requests[client_ip] if now - t < self.window
        ]

        if len(self.requests[client_ip]) >= self.limit:
            return JSONResponse(
                status_code=429,
                content={"error": "rate_limit_exceeded", "retry_after_seconds": 60},
            )

        self.requests[client_ip].append(now)
        return await call_next(request)
```

### CORS

Configured in the app factory via `CORSMiddleware` (see main.py above).
Default allows `http://localhost:3000` for local React dev.

---

## Dependency Injection

### Database Session

```python
# dependencies.py
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from app.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

```python
# Usage in router
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies import get_db


@router.get("/data")
async def get_data(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("SELECT * FROM metrics LIMIT 10"))
    return {"data": [dict(row._mapping) for row in result]}
```

---

## File Upload Endpoints

### Receiving Excel Files via API

```python
import io
import pandas as pd
from fastapi import APIRouter, UploadFile, File, HTTPException
from app.models.responses import SkillResult

router = APIRouter(prefix="/upload", tags=["Upload"])

ALLOWED_EXTENSIONS = {".xlsx", ".xls", ".csv"}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50 MB


@router.post("/excel", response_model=SkillResult)
async def upload_excel(file: UploadFile = File(...)):
    """Upload an Excel file for skill processing."""
    # Validate extension
    suffix = "." + file.filename.rsplit(".", 1)[-1].lower() if file.filename else ""
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(400, f"File type {suffix} not allowed. Use: {ALLOWED_EXTENSIONS}")

    # Read file
    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(413, f"File exceeds {MAX_FILE_SIZE // (1024*1024)} MB limit")

    # Parse
    try:
        if suffix == ".csv":
            df = pd.read_csv(io.BytesIO(contents))
        else:
            df = pd.read_excel(io.BytesIO(contents))
    except Exception as e:
        raise HTTPException(400, f"Failed to parse file: {e}")

    return SkillResult(
        success=True,
        data={"rows": len(df), "columns": list(df.columns)},
        metadata={"filename": file.filename, "size_bytes": len(contents)},
    )
```

---

## Response Caching

### In-Memory TTL Cache for Expensive Computations

```python
# utils/cache.py
import time
import hashlib
import json
from collections import OrderedDict
from app.config import settings


class TTLCache:
    """Simple TTL cache for skill computation results."""

    def __init__(self, max_size: int = None, ttl: int = None):
        self.max_size = max_size or settings.CACHE_MAX_SIZE
        self.ttl = ttl or settings.CACHE_TTL_SECONDS
        self._cache: OrderedDict[str, tuple[float, any]] = OrderedDict()

    def _make_key(self, *args, **kwargs) -> str:
        raw = json.dumps({"args": args, "kwargs": kwargs}, sort_keys=True, default=str)
        return hashlib.sha256(raw.encode()).hexdigest()

    def get(self, key: str):
        if key in self._cache:
            timestamp, value = self._cache[key]
            if time.time() - timestamp < self.ttl:
                self._cache.move_to_end(key)
                return value
            del self._cache[key]
        return None

    def set(self, key: str, value):
        if len(self._cache) >= self.max_size:
            self._cache.popitem(last=False)
        self._cache[key] = (time.time(), value)

    def clear(self):
        self._cache.clear()


# Singleton cache instance
skill_cache = TTLCache()
```

### Usage in Service Layer

```python
from app.utils.cache import skill_cache

async def execute_expensive_skill(params: DateRangeRequest) -> SkillResult:
    cache_key = skill_cache._make_key(
        start=str(params.start_date), end=str(params.end_date)
    )

    cached = skill_cache.get(cache_key)
    if cached is not None:
        return cached

    result = await _run_computation(params)
    skill_cache.set(cache_key, result)
    return result
```

### Cache Invalidation Endpoint

```python
@router.post("/cache/clear")
async def clear_cache():
    """Clear the skill computation cache."""
    skill_cache.clear()
    return {"status": "cache_cleared"}
```

---

## Python Packaging

### requirements.txt

```
fastapi>=0.115.0,<1.0.0
uvicorn[standard]>=0.30.0,<1.0.0
pydantic>=2.0.0,<3.0.0
pydantic-settings>=2.0.0,<3.0.0
sqlalchemy[asyncio]>=2.0.0,<3.0.0
asyncpg>=0.29.0,<1.0.0
httpx>=0.27.0,<1.0.0
pandas>=2.0.0,<3.0.0
openpyxl>=3.1.0,<4.0.0
python-multipart>=0.0.9
```

### Rules

1. **Pin major versions** — `>=X.Y.0,<X+1.0.0`
2. **No unpinned deps** — every dependency has version bounds
3. **Separate dev deps** — put pytest, mypy, ruff in `requirements-dev.txt`
4. **No unused deps** — if you remove a feature, remove its dependency
5. **Use `python-multipart`** — required for `UploadFile` to work

### Virtual Environment Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -r requirements-dev.txt  # for testing
```

---

## OpenAPI Customization

FastAPI auto-generates OpenAPI specs. Customize with:

```python
app = FastAPI(
    title="ISPN WCS Trends API",
    description="Workforce intelligence skill for WCS volume trend analysis",
    version="0.1.0",
    contact={"name": "ISPN Team", "email": "pete.connor@company.com"},
    license_info={"name": "Internal"},
    servers=[
        {"url": "http://localhost:8000", "description": "Local dev"},
        {"url": "https://wcs-trends.ispn.internal", "description": "Dev cluster"},
    ],
)
```

Access at:
- Swagger UI: `/api/v1/docs`
- ReDoc: `/api/v1/redoc`
- Raw JSON: `/api/v1/openapi.json`
