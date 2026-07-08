# Boot RUM — Real User Metrics

Automatic boot timing for every visit to `https://am.asrax.in` — **no `?bootTrace=1` required**.

---

## Enable / disable

| Build | RUM | Verbose console |
|-------|-----|-----------------|
| Preprod Docker | `AM_BOOT_RUM=true` (default) | OFF unless `?bootTrace=1` |
| Local `npm run run:app:preprod` | ON (web) | ON via `--boot-trace` |
| Prod Docker | `AM_BOOT_RUM=true` | OFF |

---

## Four buckets (classification)

| Bucket | What it measures | Typical preprod reload |
|--------|------------------|------------------------|
| **networkMs** | HTML + `main.dart.js` + CanvasKit download | 6–10s |
| **engineMs** | WASM compile + Flutter engine init | 3–6s |
| **appBootMs** | Config + DI + auth + shell visible | 0.5–2s |
| **dataMs** | First dashboard widget data | 0.5–3s (API dependent) |

---

## Where to read results

### 1. Browser console (preprod)

After ~6 seconds:

```
[BootRUM] {"buildId":"...","buckets":{"networkMs":8200,...},...}
```

### 2. DevTools

```js
JSON.parse(window.__AM_BOOT_TRACE__.rum)
```

### 3. Diagnostic Lab (`/app/lab`)

Look for **Boot RUM Summary** card with bucket chips and **Boot** events in the live log.

### 4. Nginx pod logs (network only)

Correlate `[BootRUM].resources.mainDartJsMs` with nginx access log timestamps for `main.dart.js` and `canvaskit/*.wasm`.

---

## Example payload

```json
{
  "buildId": "28718448288",
  "env": "preprod",
  "path": "/app/dashboard",
  "isReload": true,
  "buckets": {
    "networkMs": 8200,
    "engineMs": 4500,
    "appBootMs": 890,
    "dataMs": 1200
  },
  "slowestPhase": "canvaskit_download",
  "cacheHit": { "mainDartJs": false, "canvaskit": true }
}
```

---

## Related

- [CACHE_STRATEGY.md](CACHE_STRATEGY.md) — tiered cache (CanvasKit cacheable, main.dart.js no-store)
- [RELOAD_AND_TAB_FIXES.md](RELOAD_AND_TAB_FIXES.md) — reload UX fixes
- [FAST_BOOT_PERFORMANCE.md](FAST_BOOT_PERFORMANCE.md) — full boot optimization history
