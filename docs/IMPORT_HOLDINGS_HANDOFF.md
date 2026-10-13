# Import holdings handoff (Phase 1 UI + Phase 2 sync)

**Status:** Phase 1 READY FOR VERIFY · Phase 2 CODE COMPLETE (await Phase 1 checklist sign-off for smoke)  
**Branch:** `hotfix/import-holdings-one-page`  
**Last updated:** 2026-10-13  
**Local run:** `npm run run:app:9000:prod` → http://localhost:9000 → Import holdings

## Resume prompts

- Phase 1 verify: *Open Import holdings on localhost:9000 (prod defines); fill checklist below*
- Phase 2 smoke after checklist signed: *Smoke Gmail Dhan + document upload sync bar + deep links*

---

## Phase 1 — One page Import holdings (UI)

### Goal

One screen for Import holdings. Keep logic in separate files; compose one page. No Email vs Upload full-page swap.

### Layout

- Shared: broker **app icons**, portfolio name, PDF/file password (mail mandatory), document type (upload mandatory)
- Mail: Gmail connect + import from mailbox
- Upload: drag-drop / select files (no broker dropdown)
- Rail: Privacy | Recent imports | Capabilities

### Files

| Work | Path |
|------|------|
| Handoff | `docs/IMPORT_HOLDINGS_HANDOFF.md` |
| Shared controls | `am_doc_intelligence_ui/lib/features/import_holdings_shared_controls.dart` |
| Page compose | `am_doc_intelligence_ui/lib/features/doc_intelligence_screen.dart` |
| Mail | `am_doc_intelligence_ui/lib/features/email_extractor/email_extractor_view_web.dart` |
| Upload | `am_doc_intelligence_ui/lib/features/document_processor/document_processor_view.dart` |

### Phase 1 verification checklist

- [ ] Card tabs: **Email** | **Document upload** — body/fields switch with tab
- [ ] Shared broker icons; portfolio name optional (defaults to broker name)
- [ ] Email tab: password + mailbox; no doc-type chips
- [ ] Upload tab: required doc-type chips (equity / MF CAS / trades / F&O only); dropzone; theme primary
- [ ] Mail extract blocked without password + broker
- [ ] Upload blocked without broker + document type
- [ ] Verified locally with prod config (`npm run run:app:9000:prod`)
- [ ] **Verified by:** ________  **Date:** ________

Until checked, treat Phase 2 as code-landed but not smoke-signed.

---

## Phase 2 — Sync UX + identity (implemented on this branch)

Flip status to `Phase 2: SMOKE IN PROGRESS` after checklist is signed.

1. **Mapper** (`am-portfolio` `PortfolioMapperv1`): document events `id=null`, name = broker code — **already on am-portfolio main**
2. **Banner:** syncing phase + ~60s linear progress + Open Portfolio / Open Trade actions — `import_process_banner.dart`
3. **Poll helper:** `import_portfolio_sync.dart` (list poll, 60s / ~3s)
4. **Wire Gmail + document upload** → `notifyImported(real UUID)` → deep links
5. **App callbacks:** `onOpenPortfolio` / `onOpenTrade` in `deferred_routes` + `app_router` (session patch + `go()`)
6. **Guard:** `global_portfolio_wrapper` only uses `lastPortfolioId` if present in list

### Phase 2 done when (smoke)

- Gmail and document upload show syncing then deep links
- Correct portfolio without hard refresh
- No extractor Mongo id as portfolio id

---

## Out of scope

- Google OAuth app verification
- Codemagic / Mobile CI
- New Kafka WebSocket (v1 = list poll)
