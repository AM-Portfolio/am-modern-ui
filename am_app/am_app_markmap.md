# am_app

## Purpose
- The lightweight Orchestration Shell.
- Contains NO core business logic.
- Connects all feature modules together into the final executable Flutter app.

## Initialization Sequence (`main.dart`)
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `ConfigService.initialize()` (Sets up URLs & `useMockData`)
3. `configureDependencies()` (Fires up GetIt)
4. `runApp(ProviderScope(child: AMApp()))`

## Dependency Injection (`core/di/injection.dart`)
- **Framework**: Uses `GetIt` (Service Locator) for global singletons.
- **ServiceRegistry**: Initializes the `am_library` infrastructure with specific URLs.
- **Auth Wiring**: Registers Data Sources, Repos, and Use Cases for Auth.
- **Note**: Feature modules (like Dashboard, Trade) use `Riverpod` locally, but `GetIt` is used here at the root for infrastructure.

## The Global Shell (`features/shell/app_shell.dart`)
- **Authentication Intercept**: If `AuthCubit` state is NOT Authenticated, immediately returns `LoginPage()`.
- **Navigation/Layout**: Provides the global sidebar (Desktop) or bottom nav (Mobile).
- **Module Router**: Uses a simple integer switch statement (`_selectedIndex`) to decide which feature page to render.
- **Data Flow (Baton Pass)**: Grabs `userId` from the Auth state and passes it to the active module.

## Critical Gotchas
- **Disabled Modules**: Several modules (Trade, Portfolio, etc.) are currently commented out in `pubspec.yaml` and the shell router.
- **Config Conflict**: `am_app` sets URLs via `ServiceRegistry`, but also relies on `ConfigService` from `am_common`. Reconciling these is a major priority.
