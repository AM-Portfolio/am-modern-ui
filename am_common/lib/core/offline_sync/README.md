# Offline Sync Kit

Reusable offline layer for AM Flutter hosts. **Cache/connectivity policy is centralized** — feature files do not call GrowthBook or connectivity themselves.

## Central control

1. **Host DI** (`am_app` `injection.dart`): `OfflineSyncConfig(widgets: OfflineWidgetCatalog.amAppDefaults)`
2. **Edit the matrix** in `offline_widget_policy.dart` (`OfflineWidgetCatalog`) or pass a custom list in config
3. **Feature code** only asks:

```dart
if (OfflineSync.shouldServeCache(OfflineWidgetId.portfolioHoldings)) {
  return cached;
}
OfflineSync.reportNetworkFailure();
```

UI hide:

```dart
OfflineAware(
  widgetId: OfflineWidgetId.dashboardTopMovers,
  child: TopMoversWidget(),
)
```

## Widget matrix (defaults)

| WidgetId | Domain | cacheOnFailure | hideWhenOffline | queuedWrites |
|---|---|---|---|---|
| portfolioHoldings/Summary/List | portfolio | yes | no | no |
| tradeList/Calendar/Metrics | trades | yes | no | tradeList yes |
| dashboard* | dashboard | yes | movers hide | no |
| aiSession* | aiChat | yes | no | detail yes |

Master switches: GrowthBook `offline_reads_v1` / `offline_writes_v1` (wired once on the engine).

## Integrate (future app)

1. Depend on `am_common`
2. Build `OfflineSyncConfig` with your `widgets` list
3. Register `OfflineSyncEngine` with `isReadsEnabled` / `isWritesEnabled`
4. Register adapters
5. Wrap shell with `OfflineShell`
6. Enable GrowthBook flags
