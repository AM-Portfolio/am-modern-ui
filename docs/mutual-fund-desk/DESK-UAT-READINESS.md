# MF desk UAT readiness (1A parallel ops)

Non-blocking ops track while UI gap-fill ships. Dig BFF: `https://am-dev.asrax.in/router/am/mf`.

## Catalog (Explore / NAV)

1. Open Explore → Network → `GET …/v1/mf/schemes` (or scheme detail).
2. Check JSON `source`:
   - Live: `nse-master-download` (or am-parser catalog) with real `nav` / `navDate`
   - Seed: UI shows quiet note + hides charts — **do not invent NAV in Flutter**
3. Dig path: CronJob `am-mf-catalog-nav-daily` → Postgres `mf_catalog` → am-parser → BFF `MF_CATALOG_API_URL`
4. Invest/SIP stay gated to mapper ISINs `INF579M01AV5`, `INF579M01AW3` until scheme-map expands

## Payment trust (NSE ops)

- Live UAT often: `Payment can not be done through API for non-trusted members.`
- BFF appends GET_LINK into `failure_message` when available — UI surfaces link + copy
- Checklist: `am-mutual-fund/docs/notes/22-dig-payment-trust-checklist.md`
- Verify script: `mf_service/scripts/verify_ship_c_payment.py`
- **Do not block UI merges** on trusted-member (decision 1A)

## Mandate / SIP ACTIVE

- eNACH often stays `AUTH_PENDING` until bank auth — XSIP/pause need **ACTIVE**
- Notes: `00-flow-index.md`, `04-mandate.md`, `10-remaining-products.md`

## Stub distributor (local / dig demo)

For pause → resume without NSE trust:

```text
MF_ACTIVE_DISTRIBUTOR=stub
```

Stub mandates are immediately usable (dry_run ACTIVE path); stub SIPs register as **ACTIVE** so pause/resume demos work. Dig helm default remains `nse`.

## SIP resume on NSE

`POST /v1/mf/sips/resume` is implemented; NSE adapter returns clear `RESUME_UNSUPPORTED` until desk confirms a resume wire (Postman has XSIP_PAUSE only). Use stub for demo resume.
