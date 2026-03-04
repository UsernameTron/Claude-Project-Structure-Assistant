# React Patterns Reference

Reference for the **frontend-dev** specialist — Domains 18-20
(JavaScript/React, HTML/CSS, Vanilla JS → React migration).

---

## Project Structure

```
frontend/
├── public/
│   └── index.html
├── src/
│   ├── index.tsx
│   ├── App.tsx
│   ├── api/
│   │   └── client.ts          # BFF-aware fetch client
│   ├── components/
│   │   ├── common/
│   │   │   ├── LoadingSpinner.tsx
│   │   │   ├── ErrorBanner.tsx
│   │   │   └── DataTable.tsx
│   │   └── {skill}/
│   │       ├── Dashboard.tsx
│   │       ├── MetricsChart.tsx
│   │       └── DateRangePicker.tsx
│   ├── hooks/
│   │   ├── useApi.ts          # Generic data fetching hook
│   │   └── use{Skill}.ts     # Skill-specific hook
│   ├── types/
│   │   └── api.ts             # TypeScript types matching Pydantic models
│   └── styles/
│       └── theme.css          # Obsidian dark-mode aesthetic
├── package.json
└── tsconfig.json
```

---

## API Client (BFF-Aware Fetch)

### api/client.ts

```typescript
const API_BASE = import.meta.env.VITE_API_BASE || '/api/v1';

interface ApiResponse<T> {
  success: boolean;
  data: T | null;
  error: string | null;
  timestamp: string;
  request_id: string | null;
}

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string = API_BASE) {
    this.baseUrl = baseUrl;
  }

  async request<T>(
    path: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const url = `${this.baseUrl}${path}`;

    const response = await fetch(url, {
      credentials: 'include',  // Send cookies for auth
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({
        error: `HTTP ${response.status}`,
      }));
      return {
        success: false,
        data: null,
        error: error.error || error.detail || `HTTP ${response.status}`,
        timestamp: new Date().toISOString(),
        request_id: response.headers.get('X-Request-ID'),
      };
    }

    return response.json();
  }

  async get<T>(path: string): Promise<ApiResponse<T>> {
    return this.request<T>(path, { method: 'GET' });
  }

  async post<T>(path: string, body: unknown): Promise<ApiResponse<T>> {
    return this.request<T>(path, {
      method: 'POST',
      body: JSON.stringify(body),
    });
  }
}

export const api = new ApiClient();
```

### BFF Routing

When NGINX routes to multiple skill backends (see docker-kubernetes.md BFF section),
the frontend calls one base URL. NGINX fans out:

```
Frontend → /api/v1/wcs/analyze     → NGINX → ispn-wcs-api:8000
Frontend → /api/v1/adherence/data  → NGINX → ispn-adherence-api:8000
```

The frontend doesn't know about individual skill backends.

---

## Data Fetching Hook

### hooks/useApi.ts

```typescript
import { useState, useEffect, useCallback } from 'react';
import { api } from '../api/client';

interface UseApiState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  refetch: () => void;
}

export function useApi<T>(path: string): UseApiState<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    const response = await api.get<T>(path);

    if (response.success) {
      setData(response.data);
    } else {
      setError(response.error);
    }

    setLoading(false);
  }, [path]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}
```

### Skill-Specific Hook

```typescript
// hooks/useWcsTrends.ts
import { useState } from 'react';
import { api } from '../api/client';

interface TrendsParams {
  startDate: string;
  endDate: string;
}

interface TrendsResult {
  dates: string[];
  volumes: number[];
  trendLine: number[];
}

export function useWcsTrends() {
  const [data, setData] = useState<TrendsResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function analyze(params: TrendsParams) {
    setLoading(true);
    setError(null);

    const response = await api.post<TrendsResult>('/wcs-trends/analyze', {
      start_date: params.startDate,
      end_date: params.endDate,
    });

    if (response.success) {
      setData(response.data);
    } else {
      setError(response.error);
    }

    setLoading(false);
  }

  return { data, loading, error, analyze };
}
```

---

## Component Templates

### Dashboard Layout

```tsx
// components/{skill}/Dashboard.tsx
import { useState } from 'react';
import { useWcsTrends } from '../../hooks/useWcsTrends';
import { DateRangePicker } from './DateRangePicker';
import { MetricsChart } from './MetricsChart';
import { DataTable } from '../common/DataTable';
import { LoadingSpinner } from '../common/LoadingSpinner';
import { ErrorBanner } from '../common/ErrorBanner';

export function Dashboard() {
  const [dateRange, setDateRange] = useState({
    startDate: '2025-01-01',
    endDate: '2025-01-31',
  });

  const { data, loading, error, analyze } = useWcsTrends();

  function handleAnalyze() {
    analyze(dateRange);
  }

  return (
    <div className="dashboard">
      <h1>WCS Volume Trends</h1>

      <div className="controls">
        <DateRangePicker
          value={dateRange}
          onChange={setDateRange}
        />
        <button onClick={handleAnalyze} disabled={loading}>
          {loading ? 'Analyzing...' : 'Analyze'}
        </button>
      </div>

      {error && <ErrorBanner message={error} />}
      {loading && <LoadingSpinner />}

      {data && (
        <>
          <MetricsChart data={data} />
          <DataTable
            columns={['Date', 'Volume', 'Trend']}
            rows={data.dates.map((d, i) => [
              d,
              data.volumes[i].toLocaleString(),
              data.trendLine[i].toFixed(1),
            ])}
          />
        </>
      )}
    </div>
  );
}
```

### Common Components

#### LoadingSpinner

```tsx
export function LoadingSpinner() {
  return (
    <div className="loading-spinner">
      <div className="spinner" />
      <span>Loading...</span>
    </div>
  );
}
```

#### ErrorBanner

```tsx
interface ErrorBannerProps {
  message: string;
  onDismiss?: () => void;
}

export function ErrorBanner({ message, onDismiss }: ErrorBannerProps) {
  return (
    <div className="error-banner" role="alert">
      <span>{message}</span>
      {onDismiss && (
        <button onClick={onDismiss} aria-label="Dismiss">×</button>
      )}
    </div>
  );
}
```

#### DataTable

```tsx
interface DataTableProps {
  columns: string[];
  rows: (string | number)[][];
  onRowClick?: (index: number) => void;
}

export function DataTable({ columns, rows, onRowClick }: DataTableProps) {
  return (
    <div className="table-container">
      <table>
        <thead>
          <tr>
            {columns.map((col) => (
              <th key={col}>{col}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr
              key={i}
              onClick={() => onRowClick?.(i)}
              className={onRowClick ? 'clickable' : ''}
            >
              {row.map((cell, j) => (
                <td key={j}>{cell}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

---

## TypeScript Types (Matching Pydantic Models)

### types/api.ts

```typescript
// Mirror the Pydantic models from fastapi-patterns.md

export interface DateRangeRequest {
  start_date: string;  // YYYY-MM-DD
  end_date: string;
}

export interface SkillResult<T = unknown> {
  success: boolean;
  data: T | null;
  error: string | null;
  metadata: Record<string, unknown> | null;
  timestamp: string;
  request_id: string | null;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  page_size: number;
  has_next: boolean;
}

export interface ErrorResponse {
  error: string;
  detail: string | null;
  request_id: string | null;
  timestamp: string;
}
```

---

## Obsidian Dark-Mode Aesthetic

### styles/theme.css

```css
:root {
  /* Obsidian-inspired dark palette */
  --bg-primary: #1e1e1e;
  --bg-secondary: #252525;
  --bg-tertiary: #2d2d2d;
  --bg-hover: #363636;

  --text-primary: #dcddde;
  --text-secondary: #a7a9ab;
  --text-muted: #6c6e70;

  --accent: #7f6df2;        /* Purple accent */
  --accent-hover: #9580ff;
  --accent-dim: #483d8b;

  --success: #50fa7b;
  --warning: #ffb86c;
  --error: #ff5555;
  --info: #8be9fd;

  --border: #404040;
  --border-light: #505050;

  --font-body: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace;

  --radius: 6px;
  --shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  background: var(--bg-primary);
  color: var(--text-primary);
  font-family: var(--font-body);
  line-height: 1.6;
}

/* Dashboard layout */
.dashboard {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.dashboard h1 {
  color: var(--text-primary);
  font-size: 1.5rem;
  margin-bottom: 24px;
}

/* Controls bar */
.controls {
  display: flex;
  gap: 12px;
  align-items: center;
  margin-bottom: 24px;
  padding: 16px;
  background: var(--bg-secondary);
  border-radius: var(--radius);
  border: 1px solid var(--border);
}

/* Buttons */
button {
  background: var(--accent);
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: var(--radius);
  cursor: pointer;
  font-weight: 500;
  transition: background 0.15s;
}

button:hover {
  background: var(--accent-hover);
}

button:disabled {
  background: var(--accent-dim);
  cursor: not-allowed;
}

/* Tables */
.table-container {
  overflow-x: auto;
  border-radius: var(--radius);
  border: 1px solid var(--border);
}

table {
  width: 100%;
  border-collapse: collapse;
}

th {
  background: var(--bg-tertiary);
  color: var(--text-secondary);
  font-weight: 600;
  text-align: left;
  padding: 10px 14px;
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 1px solid var(--border);
}

td {
  padding: 10px 14px;
  border-bottom: 1px solid var(--border);
  font-family: var(--font-mono);
  font-size: 0.9rem;
}

tr:hover {
  background: var(--bg-hover);
}

tr.clickable {
  cursor: pointer;
}

/* Error banner */
.error-banner {
  background: rgba(255, 85, 85, 0.1);
  border: 1px solid var(--error);
  color: var(--error);
  padding: 12px 16px;
  border-radius: var(--radius);
  margin-bottom: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* Loading spinner */
.loading-spinner {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 24px;
  justify-content: center;
  color: var(--text-muted);
}

.spinner {
  width: 24px;
  height: 24px;
  border: 3px solid var(--border);
  border-top-color: var(--accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Inputs */
input[type="date"],
input[type="text"],
select {
  background: var(--bg-tertiary);
  color: var(--text-primary);
  border: 1px solid var(--border);
  padding: 8px 12px;
  border-radius: var(--radius);
  font-family: var(--font-body);
}

input:focus,
select:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 2px rgba(127, 109, 242, 0.2);
}
```

---

## Vanilla JS → React Migration Table

Use this mapping when converting Ali's existing vanilla JS dashboards to React:

| Vanilla JS Pattern | React Equivalent | Notes |
|-------------------|-----------------|-------|
| `document.getElementById('x')` | `useRef<HTMLElement>(null)` | Ref for DOM access |
| `element.innerHTML = '...'` | JSX return value | React renders declaratively |
| `element.addEventListener('click', fn)` | `onClick={fn}` | Event handlers as props |
| `fetch(url).then(...)` | `useApi` hook or `useEffect` + `useState` | Encapsulate in custom hook |
| `element.classList.add('active')` | `className={isActive ? 'active' : ''}` | Conditional classes |
| `element.style.display = 'none'` | `{show && <Element />}` | Conditional rendering |
| `localStorage.getItem('key')` | `useState` with `useEffect` for persistence | Or use a localStorage hook |
| `setInterval(fn, 1000)` | `useEffect` with cleanup | Return cleanup function |
| `XMLHttpRequest` | `fetch` in custom hook | Use the API client |
| Global variables | React state (`useState`) or context | Lift state to nearest common ancestor |
| DOM manipulation loop | `.map()` in JSX | Key prop required |
| `document.createElement()` | Component function returning JSX | Compose components |
| `window.onload` | `useEffect(() => {...}, [])` | Empty deps = mount only |
| `element.setAttribute('disabled', true)` | `disabled={isDisabled}` | Props control attributes |
| Template string HTML | JSX | Type-safe, no injection risk |

### Migration Checklist

When converting a vanilla JS dashboard:

1. **Identify state** — What global variables hold data? → `useState`
2. **Identify effects** — What runs on load or timer? → `useEffect`
3. **Identify events** — What does the user click/type? → Event handler props
4. **Extract components** — Each distinct UI section becomes a component
5. **Replace fetch calls** — Wrap in custom hook using the API client
6. **Replace DOM manipulation** — Let React own the DOM via JSX
7. **Add types** — Define TypeScript interfaces for all data shapes

### Example Migration

**Before (Vanilla JS):**
```javascript
document.addEventListener('DOMContentLoaded', () => {
  const btn = document.getElementById('analyze-btn');
  const results = document.getElementById('results');

  btn.addEventListener('click', async () => {
    results.innerHTML = 'Loading...';
    const res = await fetch('/api/v1/wcs-trends/analyze', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({start_date: '2025-01-01', end_date: '2025-01-31'}),
    });
    const data = await res.json();
    results.innerHTML = `<pre>${JSON.stringify(data, null, 2)}</pre>`;
  });
});
```

**After (React):**
```tsx
import { useWcsTrends } from '../hooks/useWcsTrends';

export function AnalyzePanel() {
  const { data, loading, error, analyze } = useWcsTrends();

  return (
    <div>
      <button onClick={() => analyze({ startDate: '2025-01-01', endDate: '2025-01-31' })}>
        {loading ? 'Loading...' : 'Analyze'}
      </button>
      {error && <p className="error">{error}</p>}
      {data && <pre>{JSON.stringify(data, null, 2)}</pre>}
    </div>
  );
}
```
