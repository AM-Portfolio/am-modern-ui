# Pre-Release Gate UI Test

Workflow: [`.github/workflows/ui-test-gate.yml`](../.github/workflows/ui-test-gate.yml)

## What it does (P0)

1. Optional Contabo deploy — **not yet** (`deploy_mode` must be `none`; branch/tag = P3).
2. **JSON health probe** of `/ui-test/health` and `/qa/ready` (or `/health`). SPA HTML = fail.
3. `POST {gateway}/v2/releases/ops/start` with `QA_AGENT_GATEWAY_TOKEN`.
4. Poll `GET {gateway}/v2/releases/{request_id}` until `release_ops_complete`.
5. Temporal runs first-check → `prod_ui_full` (unless `skip_ui`) → pack/soak/publish.

**No Playwright in GitHub Actions.** Temporal owns suites.

## Secrets / vars

| Name | Where | Purpose |
|------|--------|---------|
| `QA_AGENT_GATEWAY_TOKEN` | repo secret | Bearer for `/qa/v2/releases/*` |
| `QA_AGENT_GATEWAY_BASE` | repo var (optional) | Default `{target_url}/qa` |
| `UI_TEST_AGENT_BASE` | repo var (optional) | Default `{target_url}/ui-test` |

## Dispatch inputs

| Input | Default | Notes |
|-------|---------|--------|
| `deploy_mode` | `none` | Only `none` in P0 |
| `target_url` | `https://am.asrax.in` | App under test |
| `suite` | `prod_ui_full` | Passed to Temporal |
| `soak_min` | `0` | Set `30` for full soak |
| `skip_ui` | `false` | Drive-pack-only if true |

## Operator pack

See `am-qa-agents/docs/qa-agent/pre-release-gate/` (`PLAN.md`, `TODOS.md`, `VERIFICATION.md`, `architecture.drawio`).
