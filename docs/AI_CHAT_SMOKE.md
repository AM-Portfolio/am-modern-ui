# AI chat smoke — domain first (no port-forward)

## Branches

- `am-modern-ui`: `feature/ai-chat-l3`
- `am-agents`: `feature/ai-chat-l3`
- `am-gateways`: `main` / `feature/ai-chat-l3`

## Layout

| Layer | Deploy | Public (dev) |
|-------|--------|----------------|
| L2 AI gateway | **am-ai-gateway** | `https://am-dev.asrax.in/ai` |
| L3 finance agent | **am-fin-agent** | ClusterIP only (via gateway) |
| UI | **am-modern-ui** | `https://am-dev.asrax.in/app/ai-chat` |

## 1. Domain smoke (preferred)

```powershell
curl https://am-dev.asrax.in/ai/health
curl -X POST https://am-dev.asrax.in/ai/api/v1/ai/chat `
  -H "Content-Type: application/json" `
  -d '{"message":"hello","userId":"b75743c9-fe0e-4c54-8ee0-8da350cc27b3","sessionId":"smoke"}'
```

Postman: Asrax → collection **am-fin-agent** → env **AM Fin-Agent - Dev**.

## 2. Local process only (optional)

```powershell
# Agent :8101 then gateway :8120 — only when developing without cluster ingress
cd a:\InfraCode\AM-Portfolio-grp\am-gateways\mcp-gateway
$env:FINANCE_AGENT_BASE_URL = "http://localhost:8101"
uvicorn app.main:app --host 0.0.0.0 --port 8120
```

## 3. UI

Deployed UI uses `domain: am-dev.asrax.in` → `EnvDomains` resolves chat to `$apiBase/ai`.  
Local override: set `aiGateway` to `https://am-dev.asrax.in/ai` in `config.local.json`.
5. Ask for portfolio summary / holdings / top movers → expect cards; **View details** deep-links into portfolio / trade / analysis routes.

## 4. Fallback (no gateway)

Remove `aiGateway` from `config.local.json`, keep `financeAgent: http://localhost:8101`, re-run `npm run config:local` + UI. Chat should hit the agent on **8101** directly.

## 5. Optional auth

With agent `$env:AUTH_REQUIRED = "true"`, chat without Bearer → 401; with valid JWT → success. Local default stays `AUTH_REQUIRED=false`.

## Pass criteria

- Agent healthy on **8101**; gateway on **8120** proxies chat.
- UI uses **8120** when `aiGateway` is set.
- At least `PORTFOLIO_SUMMARY` renders; other widgetIds show data cards / deep links.
