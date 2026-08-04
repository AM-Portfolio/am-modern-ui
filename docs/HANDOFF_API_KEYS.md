# API Keys Handoff — am-modern-ui

## Status — 2026-08-02

- The API Keys settings page and one-time secret flow exist in the local tree.
- Profile Settings already imports and opens `ApiKeysPage`; basic navigation is linked.
- The auth interceptor attaches Bearer auth and refreshes/replays once on HTTP 401.
- Repository: `am-modern-ui` on `feature/ai-chat-l3`, with uncommitted WIP.
- Live testing is blocked until the updated identity image is deployed.

## Goal / architecture

“Call Asrax” AI is `fin-agent`, exposed in dev through:

`https://am-dev.asrax.in/ai` → AI gateway → fin-agent → `am-analysis`

The UI manages credentials through identity:

1. A signed-in user opens Profile Settings → API Keys.
2. The UI creates/lists/revokes keys through `/identity/users/me/api-keys`.
3. Identity shows a new secret only in the create response.
4. External clients exchange `key_id` plus secret at identity `/auth/api-key`.
5. They send the resulting JWT to Call Asrax as `Authorization: Bearer <token>`.

JWT `sub` is the authoritative identity. API keys only mint tokens through
identity; never send a raw API key to fin-agent as Authorization.

## Git topology

- `AM-Portfolio-grp` is **not** a Git repository; its parent `.git` was removed.
- Work and commit only in nested repositories:
  - `am-modern-ui`
  - `am-platform`
  - `am-agents`
  - `am-gateways`
- Do not stage or commit from the workspace root.
- Keep this work on a feature branch; the current branch is `feature/ai-chat-l3`.

## Implemented and verified in the tree

### API Keys settings page

- File:
  `am_user_ui/lib/features/profile/presentation/pages/api_keys_page.dart`.
- Loads keys with `GET /users/me/api-keys`.
- Creates keys with `POST /users/me/api-keys`.
- Sends key name and current scope `ai.read`.
- Revokes keys with `DELETE /users/me/api-keys/{id}`.
- Shows loading, empty, error/retry, active, and revoked states.
- Uses the configured identity base URL rather than a hard-coded dev hostname.

### One-time secret experience

- The create dialog clearly says the secret is shown once.
- The dialog cannot be dismissed by tapping outside.
- It displays the key ID and secret after creation.
- It builds a Cursor MCP launcher snippet using `scripts/asrax_mcp.py`.
- The snippet places `ASRAX_KEY_ID` and `ASRAX_KEY_SECRET` in launcher env.
- A copy action copies the generated settings snippet.
- The UI does not expect secrets to appear in subsequent list responses.

### Navigation

- `profile_settings_page.dart` imports `api_keys_page.dart`.
- Profile Settings contains an **API Keys** tile.
- The tile opens `ApiKeysPage` with a `MaterialPageRoute`.
- Therefore the immediate navigation link is already present; verify visibility
  and packaging in the built app rather than adding a duplicate route.

### Authentication behavior

- `AuthProviders.dio` uses `AuthInterceptor`.
- Requests attach the stored access token as a Bearer credential.
- On the first HTTP 401, the interceptor exchanges the refresh token.
- It stores rotated access/refresh tokens and replays the original request once.
- `authRefreshRetried` prevents an infinite retry loop.
- The original 401 is preserved if refresh or replay fails.

## Shared backend context

- Identity API-key code exists locally in `am-platform/am-identity`.
- Live `POST https://am-dev.asrax.in/identity/users/me/api-keys` returned 404.
- Likely cause: the dev identity image has not been redeployed with new routes.
- Identity Vault path: `apps/data/dev/services/am-identity`.
- It contains `DATABASE_URL` and `OIDC_*`.
- Fin-agent maps identity OIDC data to `AUTH_ISSUER` and `AUTH_JWKS_URL`.
- Fin-agent `AUTH_REQUIRED` remains `false` pending smoke tests.
- PostgreSQL database is `am_identity`.
- Migration `001_create_api_keys.sql` has been applied on the VPS.

## Postman context

- Workspace: Asrax, ID `648a186b-f56c-4a95-b8ff-9a235cbde152`.
- Collection: **AM Identity Service**.
- Folder: **06 API Keys**.
- Environments:
  - **AM Platform - Dev**
  - **AM Fin-Agent - Dev**

Use Postman to prove the backend before diagnosing UI HTTP failures.

## Left / blockers — ordered

1. Wait for/redeploy the updated `am-identity` image so live routes stop returning 404.
2. Run the Postman API-key folder to prove create/list/exchange/revoke server-side.
3. Build the UI and verify Profile Settings → API Keys is visible in the shipped app.
4. Test create and confirm the one-time secret dialog cannot be accidentally lost.
5. Test list/reload, revoke, and error/retry against live identity.
6. Verify a stale access token causes one refresh/replay, not repeated retries.
7. Review responsive layout and copy behavior for web and target mobile widths.
8. Commit and ship from the feature branch; do not include generated secrets.

## How to continue

1. Inspect local WIP:
   `cd a:\InfraCode\AM-Portfolio-grp\am-modern-ui && git status --short --branch`
2. Confirm identity routes are live using Postman folder **06 API Keys** before
   running UI integration tests.
3. Launch the app, open Profile Settings → API Keys, and execute:
   create → save/copy once → reload/list → revoke → verify revoked state.

## Integration checks

- Confirm identity base URL resolves to
  `https://am-dev.asrax.in/identity` in the dev build.
- Confirm management requests carry the signed-in user's Bearer JWT.
- Confirm no secret is written to application logs or persisted by the page.
- Confirm list responses render safely without a `secret` field.
- Confirm a copied MCP snippet uses the exchange launcher, not raw key auth to AI.
- Confirm refresh replay retains method, body, and request URL.
- Confirm logout/expired refresh behavior returns the user to the normal auth flow.

## Success criteria

- The deployed UI can create, list, and revoke keys against live identity.
- New secret material appears exactly once and is not silently persisted.
- Profile Settings provides a working path to the page.
- One expired access token is refreshed and the failed request is replayed once.
- Call Asrax receives only exchanged Bearer JWTs whose `sub` identifies the user.
- No API key secret or JWT is committed, pasted into docs, or logged.

## Cross-repository handoffs

- Identity: `am-platform/am-identity/docs/HANDOFF_API_KEYS.md`
- Fin-agent: `am-agents/fin-portfolio-agent/docs/HANDOFF_JWT_API_KEYS.md`
- Gateway: `am-gateways/mcp-gateway/`
