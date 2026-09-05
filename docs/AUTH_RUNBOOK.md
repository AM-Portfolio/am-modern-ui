# Auth runbook (am-modern-ui)

Operational guide for identity session features on branch `feature/refresh-token`.

## Session policies

| Client | Refresh session | App lock |
|--------|-----------------|----------|
| Web | 7 days (cookie BFF) | N/A — QR or web OTP login |
| Mobile | 15 days | Biometric/PIN every 24h since last unlock |

Access tokens remain short-lived (~5m). Lazy refresh on 401 is default; enable `FeatureFlags.aggressiveTokenRefresh` before trading goes live.

## Login paths

| Platform | Primary | Fallback |
|----------|---------|----------|
| Web | QR device link | Email/SMS OTP (`enableWebOtp`) |
| Mobile | Google / email-password | None (no OTP on mobile) |

## Key routes

| Route | Purpose |
|-------|---------|
| `/login` | Web QR/OTP or mobile email login |
| `/app-lock` | Mobile biometric gate (24h) |
| `/app/scan-web-login` | Mobile QR scanner |
| `/app/active-sessions` | Session list + revoke |

## Feature flags (`FeatureFlags`)

- `useIdentityAuth` — identity backend (default `true`)
- `enableQrWebLogin` — web QR section
- `enableWebOtp` — web OTP fallback
- `aggressiveTokenRefresh` — proactive refresh timer (Phase 8 trading)

## Troubleshooting

### Web stuck on "Waiting for scan"

- Confirm am-identity device-link APIs are deployed.
- Check browser network tab for poll 403 (wrong `code_verifier`).
- QR expires after 120s; page should auto-refresh the link.

### Mobile app lock loop

- Verify `local_auth` permissions (Android biometric, iOS Face ID usage string).
- After 3 failed unlocks user is sent to full login.
- Refresh token expired (>15d idle) requires full login regardless of biometrics.

### Security banner not showing on web

- Banner polls only when tab is visible (`SecurityAlertService`).
- Requires authenticated session and `/users/me/security-events` API.

### Active sessions empty

- Sessions are recorded server-side on login/QR/OTP approve.
- Revoke calls `DELETE /users/me/login-sessions/{id}`.

## Tests

```powershell
cd a:\InfraCode\AM-Portfolio-grp\am-modern-ui\am_auth_ui
flutter pub get
flutter test test/core/services/app_lock_service_test.dart
flutter test test/features/auth/device_link_poll_service_test.dart
flutter test test/core/services/security_alert_service_test.dart
```

## Cross-repo dependencies

- am-identity: device-link, web OTP, login sessions, security events, step-up API
- See am-platform `docs/identity-session-auth-plan.md` for backend phases
