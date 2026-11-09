import 'package:equatable/equatable.dart';

import 'dashboard_widget_id.dart';

/// One slot in the user's dashboard layout.
class DashboardWidgetSlot extends Equatable {
  const DashboardWidgetSlot({
    required this.id,
    this.visible = true,
    required this.order,
    this.size = DashboardWidgetSize.full,
    this.widgetConfig,
  });

  final DashboardWidgetId id;
  final bool visible;
  final int order;
  final DashboardWidgetSize size;
  final Map<String, dynamic>? widgetConfig;

  DashboardWidgetSlot copyWith({
    DashboardWidgetId? id,
    bool? visible,
    int? order,
    DashboardWidgetSize? size,
    Map<String, dynamic>? widgetConfig,
  }) {
    return DashboardWidgetSlot(
      id: id ?? this.id,
      visible: visible ?? this.visible,
      order: order ?? this.order,
      size: size ?? this.size,
      widgetConfig: widgetConfig ?? this.widgetConfig,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'visible': visible,
        'order': order,
        'size': size.name,
        if (widgetConfig != null) 'widgetConfig': widgetConfig,
      };

  factory DashboardWidgetSlot.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] as String? ?? '';
    final id = DashboardWidgetIdX.tryParse(idRaw) ?? DashboardWidgetId.summary;
    final sizeRaw = json['size'] as String? ?? DashboardWidgetSize.full.name;
    final size = DashboardWidgetSize.values.firstWhere(
      (s) => s.name == sizeRaw,
      orElse: () => DashboardWidgetSize.full,
    );
    return DashboardWidgetSlot(
      id: id,
      visible: json['visible'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      size: size,
      widgetConfig: json['widgetConfig'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [id, visible, order, size, widgetConfig];
}

/// Ordered dashboard layout for a user.
class DashboardLayoutModel extends Equatable {
  const DashboardLayoutModel({required this.slots});

  final List<DashboardWidgetSlot> slots;

  List<DashboardWidgetSlot> get visibleSlots {
    final visible = slots.where((s) => s.visible).toList();
    visible.sort((a, b) => a.order.compareTo(b.order));
    return visible;
  }

  DashboardLayoutModel copyWith({List<DashboardWidgetSlot>? slots}) {
    return DashboardLayoutModel(slots: slots ?? this.slots);
  }

  Map<String, dynamic> toJson() => {
        'slots': slots.map((s) => s.toJson()).toList(),
      };

  factory DashboardLayoutModel.fromJson(Map<String, dynamic> json) {
    final raw = json['slots'] as List<dynamic>? ?? const [];
    return DashboardLayoutModel(
      slots: raw
          .whereType<Map<String, dynamic>>()
          .map(DashboardWidgetSlot.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [slots];
}

/// Default: Chart|Health, X-Ray|Users, then news/activity/movers.
/// Risk Radar is off by default (customize only).
DashboardLayoutModel defaultDashboardLayout() {
  return const DashboardLayoutModel(
    slots: [
      DashboardWidgetSlot(
        id: DashboardWidgetId.summary,
        visible: true,
        order: 0,
        size: DashboardWidgetSize.full,
      ),
      DashboardWidgetSlot(
        id: DashboardWidgetId.benchmarkComparison,
        visible: true,
        order: 1,
        size: DashboardWidgetSize.twoThirds,
      ),
      DashboardWidgetSlot(
        id: DashboardWidgetId.portfolioHealth,
        visible: true,
        order: 2,
        size: DashboardWidgetSize.oneThird,
      ),
      DashboardWidgetSlot(
        id: DashboardWidgetId.portfolioXray,
        visible: true,
        order: 3,
        size: DashboardWidgetSize.twoThirds,
      ),
      DashboardWidgetSlot(
        id: DashboardWidgetId.accountsHub,
        visible: true,
        order: 4,
        size: DashboardWidgetSize.oneThird,
      ),
      DashboardWidgetSlot(
        id: DashboardWidgetId.news,
        visible: true,
        order: 5,
        size: DashboardWidgetSize.twoThirds,
      ),
      DashboardWidgetSlot(
        id: DashboardWidgetId.recentActivity,
        visible: true,
        order: 6,
        size: DashboardWidgetSize.oneThird,
      ),
      DashboardWidgetSlot(
        id: DashboardWidgetId.movers,
        visible: true,
        order: 7,
        size: DashboardWidgetSize.oneThird,
      ),
      DashboardWidgetSlot(
        id: DashboardWidgetId.portfolioList,
        visible: false,
        order: 8,
        size: DashboardWidgetSize.oneThird,
      ),
      DashboardWidgetSlot(
        id: DashboardWidgetId.allocation,
        visible: false,
        order: 9,
        size: DashboardWidgetSize.oneThird,
      ),
      DashboardWidgetSlot(
        id: DashboardWidgetId.portfolioRisk,
        visible: false,
        order: 10,
        size: DashboardWidgetSize.oneThird,
      ),
    ],
  );
}

/// Maps legacy portfolio wealth slot to the overlay comparison chart.
DashboardLayoutModel normalizeDashboardLayout(DashboardLayoutModel layout) {
  final slots = <DashboardWidgetSlot>[];
  var benchmarkSeen = false;

  for (final slot in layout.slots) {
    var id = slot.id;
    if (id == DashboardWidgetId.portfolioWealthChart) {
      id = DashboardWidgetId.benchmarkComparison;
    }
    if (id == DashboardWidgetId.benchmarkComparison) {
      if (benchmarkSeen) continue;
      benchmarkSeen = true;
    }
    slots.add(slot.copyWith(id: id));
  }

  return layout.copyWith(slots: slots);
}

const _newsRowSlotIds = {
  DashboardWidgetId.news,
  DashboardWidgetId.recentActivity,
  DashboardWidgetId.movers,
  DashboardWidgetId.allocation,
};

/// Chart | Health peer row — always visible at default order/size.
const _chartPeerSlotIds = {
  DashboardWidgetId.benchmarkComparison,
  DashboardWidgetId.portfolioHealth,
};

/// X-Ray | Users peer row — always visible at default order/size.
const _xrayPeerSlotIds = {
  DashboardWidgetId.portfolioXray,
  DashboardWidgetId.accountsHub,
};

/// Ensures every default widget slot exists (saved layouts may omit newer slots).
DashboardLayoutModel mergeWithDefaultLayout(DashboardLayoutModel layout) {
  final defaults = defaultDashboardLayout();
  final savedById = {for (final s in layout.slots) s.id: s};
  final merged = <DashboardWidgetSlot>[
    for (final slot in defaults.slots)
      _mergeDefaultSlot(slot, savedById[slot.id]),
  ];
  for (final slot in layout.slots) {
    if (!merged.any((s) => s.id == slot.id)) {
      merged.add(slot);
    }
  }
  return layout.copyWith(slots: merged);
}

DashboardWidgetSlot _mergeDefaultSlot(
  DashboardWidgetSlot fallback,
  DashboardWidgetSlot? saved,
) {
  if (saved == null) return fallback;
  if (_chartPeerSlotIds.contains(fallback.id) ||
      _xrayPeerSlotIds.contains(fallback.id)) {
    return saved.copyWith(
      order: fallback.order,
      size: fallback.size,
      visible: true,
    );
  }
  // Risk is off by default — keep saved visibility, adopt default order/size.
  if (fallback.id == DashboardWidgetId.portfolioRisk) {
    return saved.copyWith(order: fallback.order, size: fallback.size);
  }
  if (_newsRowSlotIds.contains(fallback.id)) {
    return saved.copyWith(order: fallback.order, size: fallback.size);
  }
  // Demoted portfolioList: keep saved visibility but adopt default order/size.
  if (fallback.id == DashboardWidgetId.portfolioList) {
    return saved.copyWith(order: fallback.order, size: fallback.size);
  }
  return saved;
}

/// Narrow dashboards keep intelligence then activity before news.
List<DashboardWidgetSlot> compactDashboardSlots(
  List<DashboardWidgetSlot> slots, {
  required bool newsEnabled,
}) {
  final filtered = [
    for (final slot in slots)
      if (newsEnabled || slot.id != DashboardWidgetId.news) slot,
  ];
  DashboardWidgetSlot? news;
  DashboardWidgetSlot? activity;
  DashboardWidgetSlot? movers;
  final out = <DashboardWidgetSlot>[];
  for (final slot in filtered) {
    switch (slot.id) {
      case DashboardWidgetId.news:
        news = slot;
        break;
      case DashboardWidgetId.recentActivity:
        activity = slot;
        break;
      case DashboardWidgetId.movers:
        movers = slot;
        break;
      case DashboardWidgetId.summary:
      case DashboardWidgetId.portfolioWealthChart:
      case DashboardWidgetId.portfolioList:
      case DashboardWidgetId.accountsHub:
      case DashboardWidgetId.allocation:
      case DashboardWidgetId.benchmarkComparison:
      case DashboardWidgetId.paperTrading:
      case DashboardWidgetId.portfolioHealth:
      case DashboardWidgetId.portfolioXray:
      case DashboardWidgetId.portfolioRisk:
        out.add(slot);
        break;
    }
  }
  if (activity != null) out.add(activity);
  if (movers != null) out.add(movers);
  if (news != null) out.add(news);
  return out;
}
