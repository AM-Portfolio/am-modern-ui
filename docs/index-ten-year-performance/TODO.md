# Selected-index ten-year performance — execution checklist

- [x] Resolve repository/package and read architecture/design-system guidance.
- [x] Trace dashboard selection through the current aggregate widget, API route, and DTOs.
- [x] Define NIFTY 50 initial-load behavior, selected-index API/data contract, mobile behavior, failure behavior, and regression plan.
- [x] Prepare architecture diagrams and user-review plan.
- [x] Trace and design mobile Option Chain Calls/Puts horizontal-focus shortcuts.
- [x] Trace expiry provider, F&O tab controller, and mobile layout for calendar relocation and submarine visibility motion.
- [x] Generate the mobile after-change still preview and interactive animation demo.
- [x] User reviews the demo and explicitly approves implementation.
- [x] Add the selected-index ten-year performance widget and response/request-state tests.
- [x] Replace dashboard aggregate `HistoricalPerformanceSection` use only.
- [x] Format, analyze changed files, and run focused package tests.
- [ ] Verify web desktop plus 360/390px mobile emulation and Android/device when available; local Python launcher unavailable in this environment.
- [x] Add mobile Option Chain Calls/Puts focus controls and their layout/semantics tests.
- [x] Extract expiry picker; add compact calendar beside the F&O tabs with Option Chain only dive/rise animation.
- [x] Build, export, document, and test the reusable `AmSubmarineReveal` in `am_design_system`, with caller-supplied theme accent and reduced-motion behavior.
- [x] Audit changed production UI for zero new hardcoded colors and validate 599/600px responsive boundary in source/tests.
- [ ] Verify expiry selection, chart embed, tab swipes, rapid switches, reduced motion, and 360/390px layouts.
- [ ] Validate existing per-symbol response in Postman; deploy to preprod only when requested.
