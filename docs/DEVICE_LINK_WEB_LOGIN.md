# Device link web login

QR-based web login lets a user sign in on a browser by approving the request from an already-authenticated AM mobile app.

## Flow

1. Web login page calls `POST /identity/auth/device-link/start` with PKCE `code_challenge`.
2. Web renders QR payload and server `confirmation_code` (for example `482 913`).
3. Web polls `GET /identity/auth/device-link/{id}/status?code_verifier=...` every 2 seconds with cookies enabled.
4. Mobile user opens Profile → **Scan to log in on web**, scans the QR, and confirms on the preview screen.
5. Mobile calls `POST /identity/auth/device-link/{id}/approve` with Bearer token and matching confirmation code.
6. Poll returns `approved` and sets `am_session` cookie; web redirects to dashboard.

## Security controls

- PKCE binds the browser tab that started the link to the polling client.
- Numeric confirmation code must match on mobile approve.
- Mobile preview comes from server (`GET /preview`), not QR payload alone.
- QR TTL is 120 seconds; web starts a new link after expiry.
- Rate limits: start 10/min/IP, approve 5/min/user, status 30/min/IP.

## Feature flags

- `FeatureFlags.enableQrWebLogin` — show QR login on web (default `true`).
- `FeatureFlags.enableWebOtp` — show email/SMS OTP fallback on web.

## Mobile entry points

- Profile → Security → **Scan to log in on web**
- Route: `/app/scan-web-login`
- Confirm route: `/app/scan-web-login/confirm?id={device_link_id}`

## QA checklist

- Web shows QR + confirmation code when `enableQrWebLogin=true`.
- Expired QR auto-refreshes without user action.
- Wrong confirmation code is rejected on approve.
- Approved web session uses cookie BFF (`bff_cookie_session` marker client-side).
- Mobile scanner rejects non-AM QR payloads.

## Related docs

- [AUTH_RUNBOOK.md](./AUTH_RUNBOOK.md)
- am-platform `docs/identity-session-auth-plan.md`
