# Integration APIs Reference

Reference for the **deployer** specialist — Domains 22-24
(Genesys Cloud CX API, SharePoint/Graph API, Slack webhooks, inbound webhook listeners).

---

## Genesys Cloud CX API

### OAuth2 Client Credentials Flow

```python
# services/genesys.py
import httpx
from datetime import datetime, timedelta
from app.config import settings

GENESYS_TOKEN_URL = f"{settings.GENESYS_API_BASE_URL}/oauth/token"
GENESYS_API_URL = settings.GENESYS_API_BASE_URL


class GenesysClient:
    """Genesys Cloud CX API client with automatic token management."""

    def __init__(self, client_id: str, client_secret: str):
        self.client_id = client_id
        self.client_secret = client_secret
        self._token: str | None = None
        self._token_expires: datetime = datetime.min
        self._http = httpx.AsyncClient(timeout=30.0)

    async def _ensure_token(self):
        """Refresh OAuth token if expired."""
        if datetime.utcnow() < self._token_expires:
            return

        response = await self._http.post(
            GENESYS_TOKEN_URL,
            data={"grant_type": "client_credentials"},
            auth=(self.client_id, self.client_secret),
        )
        response.raise_for_status()
        data = response.json()

        self._token = data["access_token"]
        # Refresh 60s before actual expiry
        self._token_expires = datetime.utcnow() + timedelta(
            seconds=data["expires_in"] - 60
        )

    async def _get(self, path: str, params: dict = None) -> dict:
        await self._ensure_token()
        response = await self._http.get(
            f"{GENESYS_API_URL}{path}",
            headers={"Authorization": f"Bearer {self._token}"},
            params=params,
        )
        response.raise_for_status()
        return response.json()

    async def close(self):
        await self._http.aclose()
```

### Queue Metrics

```python
    async def get_queue_observations(self, queue_id: str) -> dict:
        """Get real-time queue metrics (calls waiting, agents available)."""
        return await self._get(
            f"/api/v2/analytics/queues/observations/query",
        )

    async def get_queue_stats(
        self, queue_ids: list[str], interval: str = "PT30M"
    ) -> dict:
        """Get aggregate queue statistics."""
        body = {
            "filter": {
                "type": "or",
                "predicates": [
                    {"dimension": "queueId", "value": qid}
                    for qid in queue_ids
                ],
            },
            "metrics": [
                "oServiceLevel",
                "oWaiting",
                "tAnswered",
                "tAbandoned",
                "tAcw",
                "tHandle",
            ],
            "granularity": interval,
        }
        response = await self._http.post(
            f"{GENESYS_API_URL}/api/v2/analytics/queues/observations/query",
            headers={"Authorization": f"Bearer {self._token}"},
            json=body,
        )
        response.raise_for_status()
        return response.json()
```

### Agent Status

```python
    async def get_agent_status(self, user_id: str) -> dict:
        """Get agent's current routing status and presence."""
        return await self._get(f"/api/v2/users/{user_id}/routingstatus")

    async def get_agents_on_queue(self, queue_id: str) -> list[dict]:
        """List agents assigned to a queue with their status."""
        data = await self._get(
            f"/api/v2/routing/queues/{queue_id}/members",
            params={"pageSize": 100, "expand": "routingStatus"},
        )
        return data.get("entities", [])
```

### Interaction Details

```python
    async def get_interaction(self, conversation_id: str) -> dict:
        """Get details of a specific interaction."""
        return await self._get(f"/api/v2/conversations/{conversation_id}")

    async def query_interactions(
        self, start_date: str, end_date: str, queue_ids: list[str] = None
    ) -> dict:
        """Query historical interactions for analytics."""
        body = {
            "interval": f"{start_date}/{end_date}",
            "order": "asc",
            "orderBy": "conversationStart",
            "paging": {"pageSize": 100, "pageNumber": 1},
        }
        if queue_ids:
            body["segmentFilters"] = [{
                "type": "or",
                "predicates": [
                    {"dimension": "queueId", "value": qid}
                    for qid in queue_ids
                ],
            }]

        response = await self._http.post(
            f"{GENESYS_API_URL}/api/v2/analytics/conversations/details/query",
            headers={"Authorization": f"Bearer {self._token}"},
            json=body,
        )
        response.raise_for_status()
        return response.json()
```

### Genesys Rate Limits

| Endpoint | Limit |
|----------|-------|
| Analytics queries | 15 req/min |
| Routing/queues | 300 req/min |
| Users | 300 req/min |
| Conversations | 180 req/min |

Always check `X-Rate-Limit-Count` and `Retry-After` headers.

---

## SharePoint / Microsoft Graph API

### OAuth2 App-Only Authentication

```python
# services/graph.py
import httpx
from datetime import datetime, timedelta

GRAPH_TOKEN_URL = "https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
GRAPH_API_URL = "https://graph.microsoft.com/v1.0"


class GraphClient:
    """Microsoft Graph API client for SharePoint access."""

    def __init__(self, tenant_id: str, client_id: str, client_secret: str):
        self.tenant_id = tenant_id
        self.client_id = client_id
        self.client_secret = client_secret
        self._token: str | None = None
        self._token_expires: datetime = datetime.min
        self._http = httpx.AsyncClient(timeout=30.0)

    async def _ensure_token(self):
        if datetime.utcnow() < self._token_expires:
            return

        response = await self._http.post(
            GRAPH_TOKEN_URL.format(tenant_id=self.tenant_id),
            data={
                "grant_type": "client_credentials",
                "client_id": self.client_id,
                "client_secret": self.client_secret,
                "scope": "https://graph.microsoft.com/.default",
            },
        )
        response.raise_for_status()
        data = response.json()

        self._token = data["access_token"]
        self._token_expires = datetime.utcnow() + timedelta(
            seconds=data["expires_in"] - 60
        )

    async def _get(self, path: str, params: dict = None) -> dict:
        await self._ensure_token()
        response = await self._http.get(
            f"{GRAPH_API_URL}{path}",
            headers={"Authorization": f"Bearer {self._token}"},
            params=params,
        )
        response.raise_for_status()
        return response.json()

    async def close(self):
        await self._http.aclose()
```

### File Detection & Listing

```python
    async def list_site_drives(self, site_id: str) -> list[dict]:
        """List document libraries on a SharePoint site."""
        data = await self._get(f"/sites/{site_id}/drives")
        return data.get("value", [])

    async def list_folder_contents(
        self, drive_id: str, folder_path: str = "root"
    ) -> list[dict]:
        """List files and folders in a SharePoint directory."""
        data = await self._get(
            f"/drives/{drive_id}/root:/{folder_path}:/children",
            params={"$select": "id,name,size,lastModifiedDateTime,file,folder"},
        )
        return data.get("value", [])

    async def search_files(
        self, site_id: str, query: str, file_type: str = None
    ) -> list[dict]:
        """Search for files across a SharePoint site."""
        search_query = query
        if file_type:
            search_query += f" filetype:{file_type}"
        data = await self._get(
            f"/sites/{site_id}/drive/root/search(q='{search_query}')"
        )
        return data.get("value", [])
```

### File Download

```python
    async def download_file(self, drive_id: str, item_id: str) -> bytes:
        """Download a file from SharePoint."""
        await self._ensure_token()
        response = await self._http.get(
            f"{GRAPH_API_URL}/drives/{drive_id}/items/{item_id}/content",
            headers={"Authorization": f"Bearer {self._token}"},
            follow_redirects=True,
        )
        response.raise_for_status()
        return response.content

    async def download_excel(self, drive_id: str, item_id: str):
        """Download Excel file and return as pandas DataFrame."""
        import io
        import pandas as pd

        content = await self.download_file(drive_id, item_id)
        return pd.read_excel(io.BytesIO(content))
```

### Subscription (Inbound Webhook Listener)

Graph API can notify your app when files change:

```python
    async def create_subscription(
        self,
        resource: str,
        notification_url: str,
        expiration_minutes: int = 4230,  # Max ~3 days
    ) -> dict:
        """Subscribe to change notifications on a SharePoint resource."""
        await self._ensure_token()
        from datetime import timezone
        expiration = (
            datetime.now(timezone.utc) + timedelta(minutes=expiration_minutes)
        ).isoformat()

        response = await self._http.post(
            f"{GRAPH_API_URL}/subscriptions",
            headers={"Authorization": f"Bearer {self._token}"},
            json={
                "changeType": "created,updated",
                "notificationUrl": notification_url,
                "resource": resource,
                "expirationDateTime": expiration,
                "clientState": "ispn-webhook-secret",
            },
        )
        response.raise_for_status()
        return response.json()
```

### Webhook Receiver Endpoint

```python
# routers/webhooks.py
from fastapi import APIRouter, Request, Response

router = APIRouter(prefix="/webhooks", tags=["Webhooks"])


@router.post("/graph-notifications")
async def graph_notification(request: Request):
    """Receive Graph API change notifications."""
    # Validation token handshake (required for subscription creation)
    validation_token = request.query_params.get("validationToken")
    if validation_token:
        return Response(content=validation_token, media_type="text/plain")

    body = await request.json()
    for notification in body.get("value", []):
        resource = notification.get("resource", "")
        change_type = notification.get("changeType", "")

        # Verify client state to prevent spoofing
        if notification.get("clientState") != "ispn-webhook-secret":
            continue

        # Process the notification
        # e.g., trigger file download if a new Excel was uploaded
        await process_file_change(resource, change_type)

    return {"status": "ok"}
```

---

## Slack Webhooks

### Sending Alerts via Incoming Webhook

```python
# services/slack.py
import httpx
from app.config import settings


async def send_slack_alert(
    message: str,
    severity: str = "info",
    fields: dict = None,
    client: httpx.AsyncClient = None,
):
    """Send a formatted alert to Slack via webhook."""
    color_map = {
        "info": "#36a64f",     # green
        "warning": "#ff9900",  # orange
        "error": "#ff0000",    # red
        "critical": "#8b0000", # dark red
    }

    blocks = [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": f"{'🔴' if severity in ('error','critical') else '🟡' if severity == 'warning' else '🟢'} ISPN Alert: {severity.upper()}",
            },
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": message},
        },
    ]

    # Add fields (key-value pairs)
    if fields:
        field_blocks = []
        for key, value in fields.items():
            field_blocks.append({"type": "mrkdwn", "text": f"*{key}:*\n{value}"})
        blocks.append({"type": "section", "fields": field_blocks})

    # Add timestamp
    from datetime import datetime
    blocks.append({
        "type": "context",
        "elements": [
            {"type": "mrkdwn", "text": f"Sent at {datetime.utcnow().isoformat()}Z"},
        ],
    })

    payload = {
        "blocks": blocks,
        "attachments": [{"color": color_map.get(severity, "#36a64f")}],
    }

    _client = client or httpx.AsyncClient()
    try:
        response = await _client.post(settings.SLACK_WEBHOOK_URL, json=payload)
        response.raise_for_status()
    finally:
        if not client:
            await _client.aclose()
```

### Alert Templates

#### Deployment Notification

```python
await send_slack_alert(
    message=f"*{skill_name}* deployed to `{namespace}`",
    severity="info",
    fields={
        "Version": f"`{tag}`",
        "Cluster": f"`{cluster_name}`",
        "Deployed by": "ISPN Pipeline",
    },
)
```

#### Health Check Failure

```python
await send_slack_alert(
    message=f"*{skill_name}* health check failed in `{namespace}`",
    severity="error",
    fields={
        "Endpoint": f"`/api/v1/health`",
        "HTTP Status": f"`{status_code}`",
        "Pod": f"`{pod_name}`",
    },
)
```

#### High Error Rate

```python
await send_slack_alert(
    message=f"*{skill_name}* error rate above threshold",
    severity="warning",
    fields={
        "Error Rate": f"{error_pct:.1f}%",
        "Threshold": "5%",
        "Window": "5 minutes",
    },
)
```

### Block Kit Message Anatomy

```json
{
  "blocks": [
    {"type": "header", "text": {"type": "plain_text", "text": "Title"}},
    {"type": "section", "text": {"type": "mrkdwn", "text": "Body *bold* `code`"}},
    {"type": "section", "fields": [
      {"type": "mrkdwn", "text": "*Key:*\nValue"},
      {"type": "mrkdwn", "text": "*Key:*\nValue"}
    ]},
    {"type": "divider"},
    {"type": "context", "elements": [
      {"type": "mrkdwn", "text": "Footer text"}
    ]}
  ]
}
```

### Slack Rate Limits

- Incoming webhooks: 1 message per second per webhook URL
- Burst: up to 4 messages, then throttled
- For high-volume alerts, batch or deduplicate before sending

---

## Inbound Webhook Listener Pattern

For receiving events FROM external systems (SharePoint file changes, Genesys
events, etc.):

```python
# routers/webhooks.py
import hashlib
import hmac
from fastapi import APIRouter, Request, HTTPException

router = APIRouter(prefix="/webhooks", tags=["Webhooks"])


def verify_signature(payload: bytes, signature: str, secret: str) -> bool:
    """Verify webhook signature (HMAC-SHA256)."""
    expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)


@router.post("/inbound/{source}")
async def receive_webhook(source: str, request: Request):
    """Generic inbound webhook receiver."""
    body = await request.body()

    # Verify signature if provided
    signature = request.headers.get("X-Signature-256", "")
    if signature and not verify_signature(body, signature, settings.WEBHOOK_SECRET):
        raise HTTPException(401, "Invalid signature")

    payload = await request.json()

    # Route to handler by source
    handlers = {
        "sharepoint": handle_sharepoint_event,
        "genesys": handle_genesys_event,
    }

    handler = handlers.get(source)
    if not handler:
        raise HTTPException(404, f"Unknown webhook source: {source}")

    await handler(payload)
    return {"status": "accepted"}


async def handle_sharepoint_event(payload: dict):
    """Process SharePoint file change notification."""
    # Trigger skill re-run if input data changed
    pass


async def handle_genesys_event(payload: dict):
    """Process Genesys real-time event."""
    # Update metrics or trigger alert
    pass
```
