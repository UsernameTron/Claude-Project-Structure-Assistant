# PostgreSQL Schemas Reference

Reference for the **schema-designer** specialist — Domains 15-17
(SQL/PostgreSQL DDL, database migrations, data validation & gap analysis).

---

## Schema Conventions

### Naming Rules

| Object | Convention | Example |
|--------|-----------|---------|
| Schema | `ispn` | `CREATE SCHEMA ispn;` |
| Tables | snake_case, plural | `wcs_metrics`, `agent_schedules` |
| Columns | snake_case | `start_date`, `created_at` |
| Primary keys | `id` (bigint generated) | `id BIGINT GENERATED ALWAYS AS IDENTITY` |
| Foreign keys | `{table_singular}_id` | `queue_id`, `agent_id` |
| Indexes | `idx_{table}_{columns}` | `idx_wcs_metrics_date` |
| Constraints | `chk_{table}_{rule}` | `chk_wcs_metrics_date_range` |

### Standard Columns

Every ISPN table includes:

```sql
created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
```

---

## DDL Templates

### Skill Metrics Table

```sql
-- Core table for any ISPN skill that stores time-series metrics
CREATE TABLE ispn.{skill}_metrics (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    metric_date     DATE NOT NULL,
    metric_name     VARCHAR(100) NOT NULL,
    metric_value    NUMERIC(15, 4) NOT NULL,
    dimension_1     VARCHAR(255),          -- e.g., queue name, team name
    dimension_2     VARCHAR(255),          -- e.g., interval, shift
    metadata        JSONB DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_{skill}_metrics_date
    ON ispn.{skill}_metrics (metric_date);

CREATE INDEX idx_{skill}_metrics_name_date
    ON ispn.{skill}_metrics (metric_name, metric_date);

CREATE INDEX idx_{skill}_metrics_dim1
    ON ispn.{skill}_metrics (dimension_1)
    WHERE dimension_1 IS NOT NULL;

-- GIN index for JSONB queries
CREATE INDEX idx_{skill}_metrics_metadata
    ON ispn.{skill}_metrics USING GIN (metadata);

-- Comments
COMMENT ON TABLE ispn.{skill}_metrics IS 'Time-series metrics for {skill} skill';
COMMENT ON COLUMN ispn.{skill}_metrics.dimension_1 IS 'Primary grouping dimension (e.g., queue name)';
COMMENT ON COLUMN ispn.{skill}_metrics.metadata IS 'Flexible JSONB for skill-specific attributes';
```

### Analysis Results Table

```sql
-- Stores output from skill executions
CREATE TABLE ispn.analysis_results (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    skill_name      VARCHAR(100) NOT NULL,
    run_date        TIMESTAMPTZ NOT NULL DEFAULT now(),
    parameters      JSONB NOT NULL DEFAULT '{}',
    result_data     JSONB NOT NULL,
    duration_ms     INTEGER,
    success         BOOLEAN NOT NULL DEFAULT true,
    error_message   TEXT,
    request_id      VARCHAR(64),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_analysis_results_skill_date
    ON ispn.analysis_results (skill_name, run_date DESC);

CREATE INDEX idx_analysis_results_request_id
    ON ispn.analysis_results (request_id)
    WHERE request_id IS NOT NULL;
```

### Reference Data Table

```sql
-- Slowly changing dimension table (e.g., queue configs, team mappings)
CREATE TABLE ispn.{entity}_reference (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code            VARCHAR(50) NOT NULL UNIQUE,
    name            VARCHAR(255) NOT NULL,
    category        VARCHAR(100),
    properties      JSONB DEFAULT '{}',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    effective_from  DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to    DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_{entity}_ref_active_code
    ON ispn.{entity}_reference (code)
    WHERE is_active = true;
```

### Staging Table (for Excel Imports)

```sql
-- Raw import staging — loaded before validation
CREATE TABLE ispn.staging_{import_name} (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    import_batch_id VARCHAR(64) NOT NULL,
    row_number      INTEGER NOT NULL,
    raw_data        JSONB NOT NULL,
    is_valid        BOOLEAN,
    validation_errors TEXT[],
    imported_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_staging_{import_name}_batch
    ON ispn.staging_{import_name} (import_batch_id);
```

---

## Auto-Update Trigger

```sql
-- Reusable trigger function for updated_at
CREATE OR REPLACE FUNCTION ispn.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to any table
CREATE TRIGGER trg_{table}_updated
    BEFORE UPDATE ON ispn.{table}
    FOR EACH ROW
    EXECUTE FUNCTION ispn.update_timestamp();
```

---

## Alembic Migration Setup

### Initialize Alembic

```bash
pip install alembic asyncpg
alembic init -t async migrations
```

### alembic.ini

```ini
[alembic]
script_location = migrations
sqlalchemy.url = postgresql+asyncpg://ispn:devpassword@localhost:5432/ispn_dev
```

### migrations/env.py (async)

```python
import asyncio
from alembic import context
from sqlalchemy.ext.asyncio import create_async_engine
from app.config import settings

target_metadata = None  # Add your metadata here if using ORM


def run_migrations_offline():
    context.configure(url=settings.DATABASE_URL, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection):
    context.configure(connection=connection)
    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online():
    engine = create_async_engine(settings.DATABASE_URL)
    async with engine.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await engine.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())
```

### Common Migration Operations

```bash
# Create new migration
alembic revision --autogenerate -m "Add wcs_metrics table"

# Apply all pending migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# Show current version
alembic current

# Show migration history
alembic history --verbose

# Generate SQL without executing (for review)
alembic upgrade head --sql > migration.sql
```

### Migration Template

```python
"""Add {skill}_metrics table

Revision ID: abc123
Revises: def456
Create Date: 2025-03-04
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = "abc123"
down_revision = "def456"


def upgrade():
    op.execute("CREATE SCHEMA IF NOT EXISTS ispn")

    op.create_table(
        "{skill}_metrics",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("metric_date", sa.Date, nullable=False),
        sa.Column("metric_name", sa.String(100), nullable=False),
        sa.Column("metric_value", sa.Numeric(15, 4), nullable=False),
        sa.Column("dimension_1", sa.String(255)),
        sa.Column("metadata", JSONB, server_default="{}"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
        schema="ispn",
    )

    op.create_index(
        "idx_{skill}_metrics_date",
        "{skill}_metrics",
        ["metric_date"],
        schema="ispn",
    )


def downgrade():
    op.drop_table("{skill}_metrics", schema="ispn")
```

### Migration Rules

1. **Every schema change gets a migration** — no manual DDL in production
2. **Migrations must be reversible** — always implement `downgrade()`
3. **Test migrations against a copy** — never run untested migrations on prod
4. **Name migrations descriptively** — `"Add wcs_metrics table"` not `"update"`
5. **One logical change per migration** — don't bundle unrelated schema changes

---

## Data Validation

### Row-Level Validation (in staging)

```sql
-- Validate staged data before loading into production tables
UPDATE ispn.staging_{import_name}
SET
    is_valid = (
        (raw_data->>'date') IS NOT NULL
        AND (raw_data->>'value')::numeric IS NOT NULL
        AND (raw_data->>'value')::numeric >= 0
    ),
    validation_errors = ARRAY_REMOVE(ARRAY[
        CASE WHEN (raw_data->>'date') IS NULL
             THEN 'Missing date' END,
        CASE WHEN (raw_data->>'value') IS NULL
             THEN 'Missing value' END,
        CASE WHEN (raw_data->>'value')::numeric < 0
             THEN 'Negative value' END
    ], NULL)
WHERE import_batch_id = $1;
```

### Integrity Checks

```sql
-- Check for duplicate dates in metrics
SELECT metric_date, metric_name, COUNT(*)
FROM ispn.{skill}_metrics
GROUP BY metric_date, metric_name
HAVING COUNT(*) > 1;

-- Check for gaps in daily data
WITH date_series AS (
    SELECT generate_series(
        (SELECT MIN(metric_date) FROM ispn.{skill}_metrics),
        (SELECT MAX(metric_date) FROM ispn.{skill}_metrics),
        '1 day'::interval
    )::date AS expected_date
)
SELECT d.expected_date AS missing_date
FROM date_series d
LEFT JOIN ispn.{skill}_metrics m
    ON m.metric_date = d.expected_date
WHERE m.id IS NULL
ORDER BY d.expected_date;

-- Check referential integrity (metrics reference valid dimensions)
SELECT DISTINCT m.dimension_1
FROM ispn.{skill}_metrics m
LEFT JOIN ispn.queue_reference q ON q.code = m.dimension_1
WHERE q.id IS NULL
  AND m.dimension_1 IS NOT NULL;
```

---

## Gap Analysis Queries

### Date Coverage Report

```sql
-- Show data coverage by metric and month
SELECT
    metric_name,
    DATE_TRUNC('month', metric_date)::date AS month,
    COUNT(DISTINCT metric_date) AS days_with_data,
    EXTRACT(DAY FROM DATE_TRUNC('month', metric_date) + INTERVAL '1 month - 1 day') AS days_in_month,
    ROUND(
        COUNT(DISTINCT metric_date)::numeric /
        EXTRACT(DAY FROM DATE_TRUNC('month', metric_date) + INTERVAL '1 month - 1 day') * 100,
        1
    ) AS coverage_pct
FROM ispn.{skill}_metrics
GROUP BY metric_name, DATE_TRUNC('month', metric_date)
ORDER BY month DESC, metric_name;
```

### Volume Comparison (Current vs Previous Period)

```sql
-- Compare current period against previous period
WITH current_period AS (
    SELECT metric_name, AVG(metric_value) AS avg_value
    FROM ispn.{skill}_metrics
    WHERE metric_date BETWEEN $1 AND $2
    GROUP BY metric_name
),
previous_period AS (
    SELECT metric_name, AVG(metric_value) AS avg_value
    FROM ispn.{skill}_metrics
    WHERE metric_date BETWEEN ($1 - ($2 - $1)) AND ($1 - INTERVAL '1 day')
    GROUP BY metric_name
)
SELECT
    c.metric_name,
    ROUND(c.avg_value, 2) AS current_avg,
    ROUND(p.avg_value, 2) AS previous_avg,
    ROUND(((c.avg_value - p.avg_value) / NULLIF(p.avg_value, 0)) * 100, 1) AS change_pct
FROM current_period c
LEFT JOIN previous_period p USING (metric_name)
ORDER BY ABS(((c.avg_value - p.avg_value) / NULLIF(p.avg_value, 0))) DESC NULLS LAST;
```

### EXPLAIN ANALYZE (Performance Tuning)

```sql
-- Always check query plans for slow queries
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT metric_date, SUM(metric_value) AS total
FROM ispn.wcs_metrics
WHERE metric_date BETWEEN '2025-01-01' AND '2025-03-31'
  AND metric_name = 'call_volume'
GROUP BY metric_date
ORDER BY metric_date;
```

### What to Look For in EXPLAIN Output

| Warning Sign | Meaning | Fix |
|-------------|---------|-----|
| `Seq Scan` on large table | Missing index | Add index on filter/join columns |
| `Rows Removed by Filter: 99%` | Index not selective | Add composite or partial index |
| `Sort Method: external merge` | Sort spills to disk | Increase `work_mem` or add index |
| `Hash Join` with large build | Large join intermediate | Check join selectivity |
| `Nested Loop` with large outer | Quadratic behavior | Ensure inner has index |

---

## Init Script (for Docker Compose)

```sql
-- migrations/init.sql
-- Run by docker-entrypoint-initdb.d on first startup

CREATE SCHEMA IF NOT EXISTS ispn;

-- Create base tables
-- (Use alembic for real migrations; this is for local dev bootstrap only)
```

### Rule: init.sql for Local Dev Only

In production, always use Alembic migrations. The init.sql is a convenience
for `docker compose up` to create a usable schema immediately.
