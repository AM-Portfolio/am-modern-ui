# Tasks - Portfolio UI & Backend Synchronization

- [x] Fix Portfolio List API response handling
    - [x] Update `PortfolioRemoteDataSourceImpl.getPortfoliosList` (Handles List/Map/Null)
    - [x] Update `PortfolioMapper.portfolioListFromJson` (Correctly parses raw JSON array)
- [x] Align Portfolio Summary data model with backend
    - [x] Update `PortfolioSummaryDto` fields and `fromJson` logic
    - [x] Update `PortfolioSummaryMapper` to derive UI analytics from backend maps
- [x] Standardize User Identity in UI
    - [x] Verify production user `b75743c9-fe0e-4c54-8ee0-8da350cc27b3` in `test_users.json`
    - [x] Force production user ID in `PortfolioRemoteDataSourceImpl`
- [x] Verify End-to-End communication
    - [x] Run UI and check console for parse errors
    - [x] Confirm data visibility in Dashboard (Summary cards verified with non-zero data)
