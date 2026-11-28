# New-user MF run log — dig — 2026-11-23

**Env:** dig / Contabo (`am-dev.asrax.in`)  
**Account:** `kumargyan89@gmail.com` (password redacted in this log)  
**Agent:** Cursor browser automation  
**Rule:** every UI action and observed result is appended below in order.

---

## Session start

| # | Action | Result |
|---|--------|--------|
| 0 | Created this run-log file | OK |

---

## 1 — Open dig

| # | Action | Result |
|---|--------|--------|
| 1 | Open new browser tab | requested |
| 2 | Navigate to `https://am-dev.asrax.in` | pending screenshot |


| # | Action | Result |
|---|--------|--------|
| 3 | Wait for splash | Loading → login |
| 4 | Observed URL | `https://am-dev.asrax.in/login` |
| 5 | Observed UI | Welcome back + Email/Password form; Email & Google tab selected; Remember Me checked; Sign In + Continue with Google visible |


| # | Action | Result |
|---|--------|--------|
| 6 | Click email field area (~670,207) | Flutter canvas focused; no DOM textbox exposed |
| 7 | Attempt Keycloak password grant via API (email user) | pending |


## 2 — API journey as new user (Bearer via Keycloak)

_Started 2026-11-23T10:11:49.634863+00:00_

| Kind | Action | Result |
|---|---|---|
| auth | Keycloak password grant `am-web-client` for kumargyan89@gmail.com | access_token saved under `~/.asrax/generated/` (not in git) |
| API | `GET /health` — **health** | HTTP **200** · `{"status":"ok","version":"0.1.0","distributor":"nse","nse_dry_run_effective":false,"persistence":"mongodb","kafka_outbox":true,"auth":{"gateway_secret_required":true,"jwt_validation_enabled":true,"auth_relaxed":false}}` |
| note | health flags | distributor=`nse` dry_run=`False` persistence=`mongodb` |
| API | `GET /v1/mf/schemes?limit=5&purchaseAllowed=Y` — **catalog search** | HTTP **200** · `{"error":null,"message":null,"items":[{"schemeCode":"FTIFIPP-GR","schemeName":"FRANKLIN INDIA FLEXI CAP FUND - GROWTH","isin":"INF090I01239","amcCode":"FRANKLINTEMPLETON","schemeType":"EQUITY","planType":"NORMAL","purchaseAllowed":"Y","nav":1599.4558,"navDate":"2026-11-05","priceType":"EOD_NAV_NOT_LIVE_LTP","newPurchaseMinAmount":"5000","aum":45000.0,"expenseRatio":1.05,"riskometer":"Very High","sebiCategory":"Equity","sebiSubCategory":"Small Cap","enrichmentSource":"amfi"},{"schemeCode":"FTIFIP...` |
| API | `GET /v1/mf/schemes/INF579M01AV5` — **scheme AV5** | HTTP **200** · `{"error":null,"message":null,"schemeCode":"IIIBHRG-GR","schemeName":"360 ONE BALANCED HYBRID FUND - REGULAR PLAN - GROWTH","isin":"INF579M01AV5","amcCode":"IIFLMUTUALFUND_MF","schemeType":"DEBT","planType":"NORMAL","purchaseAllowed":"Y","redemptionAllowed":"Y","sipAllowed":"Y","stpEnabled":"Y","swpEnabled":"Y","switchAllowed":"Y","purchaseTransactionMode":"DP","newPurchaseMinAmount":"1000","redemptionTransactionMode":"DP","rtaAgentCode":"CAMS","nav":13.1571,"navDate":"2026-11-05","exitLoadFlag":...` |
| API | `GET /v1/mf/kyc?pan=GYAPK8901K&mobile=9876590089` — **KYC** | HTTP **200** · `{"ok":true,"dry_run":false,"message":"ok","ref":null,"details":{}}` |
| API | `POST /v1/mf/kyc/ekyc/start` — **eKYC start** | HTTP **200** · `{"ok":false,"dry_run":false,"message":"An unexpected error occurred.","ref":null,"details":{}}` |
| API | `POST /v1/mf/onboarding/ucc` — **UCC** | HTTP **200** · `{"ok":true,"dry_run":false,"message":"ok","ref":"1634720","details":{}}` |
| API | `POST /v1/mf/onboarding/fatca` — **FATCA** | HTTP **200** · `{"ok":true,"dry_run":false,"message":"ok","ref":"298041","details":{}}` |
| API | `POST /v1/mf/onboarding/bank` — **bank** | HTTP **200** · `{"ok":true,"dry_run":false,"message":"ok","ref":null,"details":{}}` |
| API | `POST /v1/mf/orders/purchase` — **purchase** | HTTP **200** · `{"id":"85a129f6-122a-44de-a4ee-735f42fed5c9","user_id":"5de4e844-f4be-4d1e-91e7-fff0db19ca7a","distributor":"nse","side":"purchase","status":"submitted","isin":"INF579M01AV5","to_isin":null,"amount":"1000.00","units":null,"distributor_order_ref":"463270000979","dry_run":false,"idempotency_key":"new-user-buy-e2989cd6-def8-4022-975e-129b9f053586","failure_code":null,"failure_message":null,"created_at":"2026-11-23T10:12:15.369235+00:00","updated_at":"2026-11-23T10:12:38.420209+00:00"}` |
| API | `POST /v1/mf/orders/85a129f6-122a-44de-a4ee-735f42fed5c9/pay` — **pay** | HTTP **200** · `{"id":"85a129f6-122a-44de-a4ee-735f42fed5c9","user_id":"5de4e844-f4be-4d1e-91e7-fff0db19ca7a","distributor":"nse","side":"purchase","status":"failed","isin":"INF579M01AV5","to_isin":null,"amount":"1000.00","units":null,"distributor_order_ref":"463270000979","dry_run":false,"idempotency_key":"new-user-buy-e2989cd6-def8-4022-975e-129b9f053586","failure_code":"DISTRIBUTOR_REJECTED","failure_message":"distributor rejected","created_at":"2026-11-23T10:12:15.369235+00:00","updated_at":"2026-11-23T10:1...` |
| API | `GET /v1/mf/orders/85a129f6-122a-44de-a4ee-735f42fed5c9` — **get order** | HTTP **200** · `{"id":"85a129f6-122a-44de-a4ee-735f42fed5c9","user_id":"5de4e844-f4be-4d1e-91e7-fff0db19ca7a","distributor":"nse","side":"purchase","status":"failed","isin":"INF579M01AV5","to_isin":null,"amount":"1000.00","units":null,"distributor_order_ref":"463270000979","dry_run":false,"idempotency_key":"new-user-buy-e2989cd6-def8-4022-975e-129b9f053586","failure_code":"DISTRIBUTOR_REJECTED","failure_message":"distributor rejected","created_at":"2026-11-23T10:12:15.369235+00:00","updated_at":"2026-11-23T10:1...` |
| API | `POST /v1/mf/orders/redeem` — **redeem** | HTTP **200** · `{"id":"d81ceb7e-9087-46b5-bfb2-28fa4b09d9d4","user_id":"5de4e844-f4be-4d1e-91e7-fff0db19ca7a","distributor":"nse","side":"redeem","status":"failed","isin":"INF579M01AV5","to_isin":null,"amount":null,"units":"0.1000","distributor_order_ref":null,"dry_run":false,"idempotency_key":"new-user-rdm-5c82d6eb-22fb-4b82-9f04-94071854d5f2","failure_code":"DISTRIBUTOR_REJECTED","failure_message":"Redemption Units are not valid.","created_at":"2026-11-23T10:12:41.546924+00:00","updated_at":"2026-11-23T10:12:...` |
| API | `POST /v1/mf/mandates` — **mandate** | HTTP **200** · `{"id":"0c6e862e-b0f8-4fad-a51e-4f23461ed1ee","user_id":"5de4e844-f4be-4d1e-91e7-fff0db19ca7a","amount":"5000.00","status":"pending","distributor":"nse","distributor_mandate_ref":"2026112310016","dry_run":false,"failure_message":null,"created_at":"2026-11-23T10:12:42.973090+00:00"}` |
| API | `POST /v1/mf/sips` — **XSIP register** | HTTP **409** · `{"detail":{"error":"INVALID_STATE","message":"Mandate status pending cannot register XSIP; wait until ACTIVE (bank eNACH auth complete)"}}` |
| note | pause/resume skipped | no distributor_sip_ref |
| API | `GET /v1/mf/holdings` — **holdings** | HTTP **200** · `[]` |
| API | `GET /v1/mf/orders?limit=10` — **orders history** | HTTP **200** · `[{"id":"d81ceb7e-9087-46b5-bfb2-28fa4b09d9d4","user_id":"5de4e844-f4be-4d1e-91e7-fff0db19ca7a","distributor":"nse","side":"redeem","status":"failed","isin":"INF579M01AV5","to_isin":null,"amount":null,"units":"0.1000","distributor_order_ref":null,"dry_run":false,"idempotency_key":"new-user-rdm-5c82d6eb-22fb-4b82-9f04-94071854d5f2","failure_code":"DISTRIBUTOR_REJECTED","failure_message":"Redemption Units are not valid.","created_at":"2026-11-23T10:12:41.546924+00:00","updated_at":"2026-11-23T10:12...` |
| API | `GET /v1/mf/sips` — **sips history** | HTTP **200** · `[]` |

_Finished 2026-11-23T10:12:38.790215+00:00_

## 3 — UI login attempts (Flutter web)

| # | Action | Result |
|---|--------|--------|
| 8 | Click email (~670,207) again | Focus on flutter-view only |
| 9 | Press key `k` | No visible character in Email field (Flutter canvas does not receive DOM keyboard into TextField via this path) |
| 10 | Conclusion for UI automation | Dig login form cannot be filled reliably via Cursor browser a11y/coords; **API path with Keycloak token used instead** for full MF journey |

## 4 — Summary for this new user

| Step | HTTP | Outcome |
|------|------|---------|
| Keycloak login | 200 | Bearer for `kumargyan89@gmail.com` / sub `5de4e844-…` |
| Health | 200 | NSE live, not dry-run |
| Catalog + AV5 | 200 | NAV present |
| KYC | 200 | ok |
| eKYC | 200 | ok:false unexpected error (advanced anyway) |
| UCC | 200 | **ok:true** ref `1634720` (PAN `GYAPK8901K`, client `GYAAN891`) |
| FATCA | 200 | ok |
| Bank | 200 | ok |
| Purchase | 200 | submitted `463270000979` |
| Pay | 200 | **DISTRIBUTOR_REJECTED** (payment trust) |
| Redeem | 200 | units not valid (no holdings) |
| Mandate | 200 | pending `2026112310016` |
| XSIP | 409 | mandate not ACTIVE |
| Pause/resume | skipped | no SIP ref |
| Holdings | 200 | `[]` |
| Orders/SIPs lists | 200 | show attempted orders |

**Password:** not stored in this log. Token file: `~/.asrax/generated/mf-new-user-token.json` (local only).

