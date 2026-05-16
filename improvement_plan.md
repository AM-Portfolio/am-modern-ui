# Improvement Plan: Fix Localhost Pointing in Deployed UI

## Overview
This document outlines the analysis and plan to fix the issue where the deployed UI points to `localhost` instead of the intended server. This behavior typically occurs in Flutter Web applications when environment variables are not properly passed during the build process or when hardcoded defaults fallback to `localhost`.

---

## 1. Root Cause Analysis

Based on the analysis of the `am-modern-ui` codebase, the following root causes have been identified:

### A. Build-Time Environment Variables Missing
Flutter Web evaluates `String.fromEnvironment` at **compile time**. If these variables are not provided during the `flutter build web` command, the app falls back to the default values specified in the code.
In `am_portfolio_ui/live/Dockerfile`, the build command is:
```dockerfile
RUN flutter build web --release
```
Since no `--dart-define` flags are passed, the app uses the hardcoded defaults in `ConfigService`.

### B. Hardcoded Defaults in `ConfigService`
In `am_common/lib/core/config/config_service.dart`, some services default to `localhost` if the environment variable is not set:
```dart
        trade: TradeApiConfig(
          baseUrl: const String.fromEnvironment('AM_TRADE_BASE_URL', defaultValue: 'http://localhost:8040'),
          ...
```
If `AM_TRADE_BASE_URL` is not provided during the build, it will always point to `http://localhost:8040`.

### C. Fallback Values in `main.dart`
In `am_portfolio_ui/lib/main.dart`, there are explicit fallbacks to `localhost` if the configuration is missing or null:
```dart
  final wsUrl = common.ConfigService.config.api.marketData?.wsUrl ?? 'ws://localhost:8091/ws-gateway-raw';
  ...
  final analysisUrl = common.ConfigService.config.api.analysis?.baseUrl ?? 'http://localhost:8061';
```

### D. Hardcoded URLs in `application.properties`
The file `am_portfolio_ui/assets/application.properties` contains:
```properties
portfolio.base.url=  http://localhost:8072
```
Although it's not clear if this file is actively loaded in the current version, it remains a potential source of `localhost` references.

---

## 2. Identified Localhost References

Here are the specific files and lines containing `localhost` that need attention:

| File Path | Line | Content |
| :--- | :--- | :--- |
| `am_common/lib/core/config/config_service.dart` | ~56 | `defaultValue: 'http://localhost:8040'` |
| `am_portfolio_ui/lib/main.dart` | 45 | `'ws://localhost:8091/ws-gateway-raw'` |
| `am_portfolio_ui/lib/main.dart` | 51 | `'http://localhost:8061'` |
| `am_portfolio_ui/assets/application.properties` | 2 | `portfolio.base.url=  http://localhost:8072` |
| `am_library/lib/core/network/analysis_api_client.dart`| 14 | `baseUrl ?? 'http://localhost:8080'` |
| `am_analysis/ui/lib/config/analysis_config.dart` | 25 | `config.setBaseUrl('http://localhost:8090');` |

---

## 3. Improvement Plan

We propose two approaches to fix this issue: **Option A** (Quick Fix via Build Arguments) and **Option B** (Best Practice via Runtime Configuration).

### Option A: Quick Fix (Bake URLs at Build Time)
This approach involves passing the correct URLs during the Docker build process using `--dart-define`.

#### Steps:
1.  **Modify `Dockerfile`**: Update `am_portfolio_ui/live/Dockerfile` to accept build arguments and pass them to Flutter.
    ```dockerfile
    ARG AM_TRADE_BASE_URL=https://am.munish.org/trade
    ARG AM_ANALYSIS_BASE_URL=https://am.munish.org/analysis
    ...
    RUN flutter build web --release \
      --dart-define=AM_TRADE_BASE_URL=$AM_TRADE_BASE_URL \
      --dart-define=AM_ANALYSIS_BASE_URL=$AM_ANALYSIS_BASE_URL
    ```
2.  **Update `docker-compose.yml`**: Pass these arguments in the `build` section.

### Option B: Recommended (Runtime Configuration)
To avoid rebuilding the image for different environments, load the configuration from a JSON file at runtime.

#### Steps:
1.  **Create Config File**: Create `assets/config.json` in `am_portfolio_ui/web` (or `assets/`).
    ```json
    {
      "AM_TRADE_BASE_URL": "https://am.munish.org/trade",
      "AM_ANALYSIS_BASE_URL": "https://am.munish.org/analysis"
    }
    ```
2.  **Modify `ConfigService`**: Update it to fetch this JSON file before rendering the app.
3.  **Mount in Docker**: You can mount different `config.json` files for different environments without rebuilding the image.

---

## 4. Immediate Action Items

To quickly resolve the current issue on the `feature/portfolio-streaming` branch:

1.  **Update `config_service.dart`**: Change the default value for `AM_TRADE_BASE_URL` to point to the server if applicable, or ensure it is overridden.
2.  **Remove hardcoded fallbacks** in `main.dart` or ensure they are only used in debug mode.
3.  **Verify Docker build**: Ensure that if you are using Docker, the URLs are being passed or the defaults are correct for the target environment.

Please review this plan and let me know which option (A or B) you prefer to implement.
