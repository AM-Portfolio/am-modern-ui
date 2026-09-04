import 'offline_domain.dart';
import 'offline_widget_policy.dart';

enum EncryptionPolicy {
  aesGcmKeystoreWrapped,
}

enum ReachabilityPolicy {
  connectivityAndAuthenticatedProbe,
}

enum OfflineTokenPolicy {
  browseCachePauseFlush,
}

enum MultiDevicePolicy {
  lastWriteWinsWithBanner,
}

class OfflineCaps {
  const OfflineCaps({
    this.maxAiSessions = 20,
    this.maxAiBytes = 10 * 1024 * 1024,
    this.maxPendingUploadBytes = 50 * 1024 * 1024,
    this.maxTradeSnapshotMonths = 12,
  });

  final int maxAiSessions;
  final int maxAiBytes;
  final int maxPendingUploadBytes;
  final int maxTradeSnapshotMonths;
}

class OfflineUiPolicy {
  const OfflineUiPolicy({
    this.overlayOnce = true,
    this.hideLiveMovers = true,
    this.showAsOfOnCharts = true,
    this.aiStaleConfirmAfter = const Duration(hours: 24),
  });

  final bool overlayOnce;
  final bool hideLiveMovers;
  final bool showAsOfOnCharts;
  final Duration aiStaleConfirmAfter;
}

class OfflineFlagKeys {
  const OfflineFlagKeys({
    this.reads = 'offline_reads_v1',
    this.writes = 'offline_writes_v1',
  });

  final String reads;
  final String writes;
}

typedef OfflineUserIdProvider = String? Function();

class OfflineSyncConfig {
  OfflineSyncConfig({
    required this.appId,
    required this.userIdProvider,
    this.encryption = EncryptionPolicy.aesGcmKeystoreWrapped,
    this.reachability = ReachabilityPolicy.connectivityAndAuthenticatedProbe,
    this.tokenPolicy = OfflineTokenPolicy.browseCachePauseFlush,
    this.caps = const OfflineCaps(),
    this.ui = const OfflineUiPolicy(),
    this.multiDevice = MultiDevicePolicy.lastWriteWinsWithBanner,
    this.flags = const OfflineFlagKeys(),
    this.enabledDomains = const {
      OfflineDomain.portfolio,
      OfflineDomain.trades,
      OfflineDomain.dashboard,
      OfflineDomain.aiChat,
    },
    List<OfflineWidgetPolicy>? widgets,
    this.telemetryEnabled = true,
  }) : widgets = OfflineWidgetCatalog.asMap(
          widgets ?? OfflineWidgetCatalog.amAppDefaults,
        );

  final String appId;
  final OfflineUserIdProvider userIdProvider;
  final EncryptionPolicy encryption;
  final ReachabilityPolicy reachability;
  final OfflineTokenPolicy tokenPolicy;
  final OfflineCaps caps;
  final OfflineUiPolicy ui;
  final MultiDevicePolicy multiDevice;
  final OfflineFlagKeys flags;
  final Set<OfflineDomain> enabledDomains;
  final Map<OfflineWidgetId, OfflineWidgetPolicy> widgets;
  final bool telemetryEnabled;

  bool isDomainEnabled(OfflineDomain domain) => enabledDomains.contains(domain);

  OfflineWidgetPolicy? policyFor(OfflineWidgetId id) => widgets[id];

  bool isWidgetEnabled(OfflineWidgetId id) {
    final policy = policyFor(id);
    if (policy == null) return false;
    return isDomainEnabled(policy.domain);
  }
}
