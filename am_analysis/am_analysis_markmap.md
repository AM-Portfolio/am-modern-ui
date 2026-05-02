# am_analysis

## Purpose
- Deep analytics, charting, and performance reporting.
- Strictly modular tri-package structure enforcing separation of concerns.

## Package Architecture

### 1. `sdk` (`am_analysis_sdk`)
- **Type**: Auto-generated API Client
- **Source**: Generated from `analysis_openapi.json` at repo root
- **Rule**: NEVER edit manually. Re-generate if backend API changes.

### 2. `common` (`am_analysis_core`)
- **Type**: Headless State Management
- **Contents**: Cubits, States, Domain Models
- **Rule**: Zero Flutter UI dependencies. Pure Dart for easy unit testing.

### 3. `ui` (`am_analysis_ui`)
- **Type**: Visual Flutter Components
- **Contents**: `fl_chart` Widgets, `RealAnalysisService`, `AnalysisMapper`
- **Role**: Bridges the Core Cubits with the SDK to render UI.

## Data Flow (Traditional BLoC + REST)
1. **Widget** triggers `Cubit.fetchData()`
2. **Cubit** calls `RealAnalysisService`
3. **Service** delegates to auto-generated **SDK**
4. **SDK** makes standard HTTP GET request to backend
5. **Service** uses Mapper to convert SDK JSON -> Clean Domain Models
6. **Cubit** emits new state
7. **Widget** redraws `fl_chart`

## Critical Gotchas
- **OpenAPI**: Changes must happen in the JSON spec, not the Dart code.
- **Headers vs Params**: The SDK sends certain parameters (like `groupBy`) as HTTP Headers, not as URL Query Parameters, due to Spring Boot backend requirements.
- **Decoupled Auth**: `RealAnalysisService` uses its own fallback tokens if not explicitly provided by the app root.
