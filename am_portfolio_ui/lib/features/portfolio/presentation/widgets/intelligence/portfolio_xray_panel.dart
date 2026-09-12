import 'dart:async';
import 'dart:math' as math;

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/portfolio_analytics.dart';
import '../../../internal/domain/entities/portfolio_holding.dart';
import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_intelligence_providers.dart';
import '../../cubit/portfolio_analytics_cubit.dart';
import '../../cubit/portfolio_analytics_state.dart';
import '../../cubit/portfolio_cubit.dart';
import '../../cubit/portfolio_state.dart';
import 'intelligence_currency.dart';
import 'intelligence_donut.dart';
import 'intelligence_glass_card.dart';

/// FE display label for X-Ray slice names. API `name` stays unchanged for sync.
@visibleForTesting
String xrayDisplayName(String raw) {
  final key = raw.trim();
  if (key.isEmpty) return 'Unknown';
  switch (key.toUpperCase()) {
    case 'LARGE_CAP':
      return 'Large Cap';
    case 'MID_CAP':
      return 'Mid Cap';
    case 'SMALL_CAP':
      return 'Small Cap';
    case 'MICRO_CAP':
      return 'Micro Cap';
    case 'UNKNOWN':
      return 'Unknown';
    default:
      if (!key.contains('_')) return key;
      return key
          .toLowerCase()
          .split('_')
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' ');
  }
}

/// Donut-active index: hover wins, else sticky selected name.
@visibleForTesting
int? xrayActiveIndex({
  required int? hoveredIndex,
  required String? selectedName,
  required List<String> weightNames,
}) {
  if (hoveredIndex != null) return hoveredIndex;
  if (selectedName == null) return null;
  final i = weightNames.indexWhere((n) => n == selectedName);
  return i >= 0 ? i : null;
}

/// List row tint: only the hovered row while hovering; else sticky select.
@visibleForTesting
bool xrayRowTintSelected({
  required int index,
  required int? hoveredIndex,
  required String? selectedName,
  required String weightName,
}) {
  if (hoveredIndex != null) return index == hoveredIndex;
  return selectedName != null && selectedName == weightName;
}

/// Where a pointer lands on the donut box (hole clears; miss is no-op).
@visibleForTesting
enum XrayDonutTapKind { slice, hole, miss }

/// Hit band aligned to [_CompactGlowingDonutPainter] stroke (~18–22).
@visibleForTesting
int? xrayHitSliceIndex({
  required Offset local,
  required double side,
  required List<XrayWeight> weights,
}) {
  if (weights.isEmpty || side <= 0) return null;
  final kind = xrayDonutTapKind(local: local, side: side, weights: weights);
  if (kind != XrayDonutTapKind.slice) return null;

  final center = Offset(side / 2, side / 2);
  final dx = local.dx - center.dx;
  final dy = local.dy - center.dy;
  var total = weights.fold<double>(0, (s, w) => s + w.weightPct);
  if (total <= 0) total = 100;
  var angle = math.atan2(dy, dx);
  angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);
  var cumulative = 0.0;
  for (var i = 0; i < weights.length; i++) {
    cumulative += (weights[i].weightPct / total) * (2 * math.pi);
    if (angle <= cumulative) return i;
  }
  return weights.length - 1;
}

@visibleForTesting
XrayDonutTapKind xrayDonutTapKind({
  required Offset local,
  required double side,
  required List<XrayWeight> weights,
}) {
  if (weights.isEmpty || side <= 0) return XrayDonutTapKind.miss;
  final center = Offset(side / 2, side / 2);
  final dx = local.dx - center.dx;
  final dy = local.dy - center.dy;
  final dist = math.sqrt(dx * dx + dy * dy);
  final baseRadius = (side / 2) - 12;
  const strokePad = 22.0;
  final inner = (baseRadius - strokePad).clamp(0.0, side);
  final outer = baseRadius + strokePad;
  if (dist < inner) return XrayDonutTapKind.hole;
  if (dist > outer) return XrayDonutTapKind.miss;
  return XrayDonutTapKind.slice;
}

class PortfolioXrayPanel extends ConsumerStatefulWidget {
  const PortfolioXrayPanel({
    required this.portfolioId,
    this.height,
    this.minHeight,
    this.fillHeight = false,
    this.padding = const EdgeInsets.all(20),
    @visibleForTesting this.holdingsOverride,
    super.key,
  });

  final String portfolioId;
  final double? height;
  final double? minHeight;
  final bool fillHeight;
  final EdgeInsetsGeometry padding;

  /// Test-only holdings injection when PortfolioCubit is unavailable.
  @visibleForTesting
  final List<PortfolioHolding>? holdingsOverride;

  @override
  ConsumerState<PortfolioXrayPanel> createState() => _PortfolioXrayPanelState();
}

class _PortfolioXrayPanelState extends ConsumerState<PortfolioXrayPanel>
    with TickerProviderStateMixin {
  int _tab = 0;
  String? _expandedId;
  String? _selectedName;
  int? _hoveredIndex;
  int? _previousHoveredIndex;
  double _donutSide = 148;
  /// Phone only: Chart ↔ List inside the card (web stays side-by-side).
  bool _mobileShowList = false;
  Timer? _hoverCommitTimer;
  Timer? _hoverExitTimer;
  int? _pendingHoverIndex;
  XrayDonutTapKind? _pendingTapKind;
  int? _pendingTapSlice;
  bool _pointerDown = false;

  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const _donutSizePhone = 196.0;
  static const _donutSizeFill = 148.0;
  static const _hoverEnterMs = Duration(milliseconds: 200);
  static const _hoverSwitchMs = Duration(milliseconds: 110);

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: _hoverEnterMs,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensurePulse();
    });
  }

  void _ensurePulse() {
    if (_hoveredIndex != null || _selectedName != null) {
      _stopPulse();
      return;
    }
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopPulse() {
    if (_pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _hoverCommitTimer?.cancel();
    _hoverExitTimer?.cancel();
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<XrayWeight> _weightsForTab(PortfolioXray? xray) {
    if (xray == null) return const [];
    final raw = switch (_tab) {
      1 => xray.industryWeights,
      2 => xray.marketCapWeights,
      _ => xray.sectorWeights,
    };
    final sorted = [...raw]
      ..sort((a, b) {
        final aUnk = a.name.toLowerCase() == 'unknown';
        final bUnk = b.name.toLowerCase() == 'unknown';
        if (aUnk != bUnk) return aUnk ? 1 : -1;
        return b.weightPct.compareTo(a.weightPct);
      });
    return sorted;
  }

  int? _activeIndex(List<XrayWeight> weights) {
    return xrayActiveIndex(
      hoveredIndex: _hoveredIndex,
      selectedName: _selectedName,
      weightNames: [for (final w in weights) w.name],
    );
  }

  void _onHover(Offset local, double side, List<XrayWeight> weights) {
    final hit = xrayHitSliceIndex(local: local, side: side, weights: weights);
    if (hit == null) {
      _scheduleHoverExit(weights);
      return;
    }
    _hoverExitTimer?.cancel();
    _hoverExitTimer = null;
    if (hit == _hoveredIndex) {
      _hoverCommitTimer?.cancel();
      _pendingHoverIndex = null;
      return;
    }
    _pendingHoverIndex = hit;
    _hoverCommitTimer?.cancel();
    _hoverCommitTimer = Timer(const Duration(milliseconds: 24), () {
      if (!mounted) return;
      final next = _pendingHoverIndex;
      _pendingHoverIndex = null;
      if (next == null || next == _hoveredIndex) return;
      _applyHoveredIndex(next, weights);
    });
  }

  void _applyHoveredIndex(int index, List<XrayWeight> weights) {
    final switching = _hoveredIndex != null;
    setState(() {
      _previousHoveredIndex = _hoveredIndex ?? _activeIndex(weights);
      _hoveredIndex = index;
    });
    _stopPulse();
    if (switching && _hoverController.value >= 0.95) {
      _hoverController.duration = _hoverSwitchMs;
      _hoverController.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        _hoverController.duration = _hoverEnterMs;
      });
    } else {
      _hoverController.duration = _hoverEnterMs;
      _hoverController.forward(from: 0);
    }
  }

  void _scheduleHoverExit(List<XrayWeight> weights) {
    _hoverCommitTimer?.cancel();
    _pendingHoverIndex = null;
    if (_hoveredIndex == null) return;
    _hoverExitTimer?.cancel();
    _hoverExitTimer = Timer(const Duration(milliseconds: 70), () {
      if (!mounted) return;
      _commitHoverExit();
    });
  }

  void _commitHoverExit() {
    if (_hoveredIndex == null) return;
    setState(() {
      _previousHoveredIndex = _hoveredIndex;
      _hoveredIndex = null;
    });
    _hoverController.duration = _hoverEnterMs;
    _hoverController.forward(from: 0);
    _ensurePulse();
  }

  void _onHoverExit() {
    _hoverCommitTimer?.cancel();
    _pendingHoverIndex = null;
    _hoverExitTimer?.cancel();
    _commitHoverExit();
  }

  void _selectWeight(String name, List<XrayWeight> weights) {
    final i = weights.indexWhere((w) => w.name == name);
    setState(() {
      _previousHoveredIndex = _activeIndex(weights);
      _selectedName = name;
      _hoveredIndex = null;
    });
    if (i >= 0) {
      _stopPulse();
      _hoverController.duration = _hoverEnterMs;
      _hoverController.forward(from: 0);
    }
  }

  void _commitSliceSelect(
    String name,
    List<XrayWeight> weights, {
    required bool listVisible,
  }) {
    setState(() {
      _previousHoveredIndex = _activeIndex(weights);
      _selectedName = name;
      _hoveredIndex = null;
      if (listVisible) _expandedId = name;
    });
    _stopPulse();
    _hoverController.duration = _hoverEnterMs;
    _hoverController.forward(from: 0);
  }

  void _clearSticky(List<XrayWeight> weights) {
    setState(() {
      _previousHoveredIndex = _activeIndex(weights);
      _selectedName = null;
      _expandedId = null;
      _hoveredIndex = null;
    });
    _hoverController.duration = _hoverEnterMs;
    _hoverController.forward(from: 0);
    _ensurePulse();
  }

  void _onTapDown(Offset local, double side, List<XrayWeight> weights) {
    _pointerDown = true;
    final kind = xrayDonutTapKind(local: local, side: side, weights: weights);
    _pendingTapKind = kind;
    _pendingTapSlice = kind == XrayDonutTapKind.slice
        ? xrayHitSliceIndex(local: local, side: side, weights: weights)
        : null;
  }

  void _onPointerMove(Offset local, double side, List<XrayWeight> weights) {
    if (!_pointerDown) return;
    _onHover(local, side, weights);
  }

  void _onTapCommit(List<XrayWeight> weights, {required bool listVisible}) {
    final kind = _pendingTapKind;
    final slice = _pendingTapSlice;
    _pendingTapKind = null;
    _pendingTapSlice = null;
    _pointerDown = false;
    if (kind == XrayDonutTapKind.hole) {
      _clearSticky(weights);
      return;
    }
    if (kind == XrayDonutTapKind.slice &&
        slice != null &&
        slice >= 0 &&
        slice < weights.length) {
      _commitSliceSelect(
        weights[slice].name,
        weights,
        listVisible: listVisible,
      );
    }
  }

  void _onMobileShowList(bool show) {
    setState(() {
      _mobileShowList = show;
      if (show && _selectedName != null) {
        _expandedId = _selectedName;
      }
    });
  }

  void _onTab(int t) {
    _hoverCommitTimer?.cancel();
    _hoverExitTimer?.cancel();
    _pendingHoverIndex = null;
    _pendingTapKind = null;
    _pendingTapSlice = null;
    _pointerDown = false;
    setState(() {
      _tab = t;
      _expandedId = null;
      _selectedName = null;
      _hoveredIndex = null;
      _previousHoveredIndex = null;
    });
    _stopPulse();
    _ensurePulse();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(portfolioIntelligenceProvider(widget.portfolioId));
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final donutCap =
        widget.fillHeight ? _donutSizeFill : _donutSizePhone;

    List<PortfolioHolding>? holdings = widget.holdingsOverride;
    MarketCapAllocation? mcap;
    if (holdings == null) {
      try {
        final portfolioState = context.watch<PortfolioCubit>().state;
        if (portfolioState is PortfolioLoaded) {
          holdings = portfolioState.holdings;
        }
      } catch (_) {
        // Tests / hosts without PortfolioCubit.
      }
    }
    try {
      final analyticsState = context.watch<PortfolioAnalyticsCubit>().state;
      if (analyticsState is PortfolioAnalyticsLoaded) {
        mcap = analyticsState.marketCapAllocation;
      }
    } catch (_) {
      // Tests / hosts without analytics cubit.
    }

    return async.when(
      loading: () => IntelligenceCardSkeleton(
        height: widget.minHeight ??
            widget.height ??
            (widget.fillHeight ? 320 : 260),
      ),
      error: (e, _) => IntelligenceGlassCard(
        title: 'Portfolio X-Ray',
        icon: Icons.donut_large_rounded,
        minHeight: widget.minHeight,
        fillHeight: widget.fillHeight,
        padding: widget.padding,
        child: IntelligenceRetryRow(
          message: 'Could not load X-Ray',
          onRetry: () => ref
              .invalidate(portfolioIntelligenceProvider(widget.portfolioId)),
        ),
      ),
      data: (intel) {
        final xray = intel?.xray;
        final weights = _weightsForTab(xray);
        final holdingsTotal = holdings == null || holdings.isEmpty
            ? null
            : holdings.fold<double>(0, (s, h) => s + h.currentValue);
        final totalValue = xray?.totalValueInr ?? holdingsTotal;
        final useFill = widget.fillHeight;
        final sideBySide = wide || useFill;
        final listVisible = sideBySide || _mobileShowList;
        final tabs = _Tabs(tab: _tab, onTab: _onTab, compact: true);
        final active = _activeIndex(weights);

        final body = _XrayBody(
          weights: weights,
          tab: _tab,
          expandedId: _expandedId,
          selectedName: _selectedName,
          hoveredIndex: _hoveredIndex,
          activeIndex: active,
          previousHoveredIndex: _previousHoveredIndex,
          hoverAnimation: _hoverAnimation,
          pulseAnimation: _pulseAnimation,
          totalValue: totalValue,
          holdings: holdings,
          marketCapAllocation: mcap,
          donutCap: donutCap,
          fillHeight: useFill,
          sideBySide: sideBySide,
          mobileShowList: _mobileShowList,
          showTabsInBody: !wide,
          tabs: tabs,
          onDonutSide: (side) {
            if (!mounted) return;
            if ((_donutSide - side).abs() > 0.5) {
              _donutSide = side;
            }
          },
          onHover: (o, side) => _onHover(o, side, weights),
          onHoverExit: _onHoverExit,
          onTapDown: (o, side) => _onTapDown(o, side, weights),
          onPointerMove: (o, side) => _onPointerMove(o, side, weights),
          onPointerUp: () {
            _pointerDown = false;
          },
          onTap: () => _onTapCommit(weights, listVisible: listVisible),
          onSelect: (name) => _selectWeight(name, weights),
          onExpand: (name) => setState(() {
            _expandedId = _expandedId == name ? null : name;
          }),
        );

        final card = IntelligenceGlassCard(
          title: 'Portfolio X-Ray',
          icon: Icons.donut_large_rounded,
          minHeight: widget.minHeight,
          fillHeight: useFill,
          padding: widget.padding,
          scrollable: false,
          // Web: Sector/Industry/Cap in header. Phone: Chart/List in header
          // so the donut can use the freed vertical space.
          trailing: wide
              ? tabs
              : _MobilePaneSwap(
                  showList: _mobileShowList,
                  onShowList: _onMobileShowList,
                ),
          child: body,
        );

        if (widget.height != null) {
          return SizedBox(height: widget.height, child: card);
        }
        return card;
      },
    );
  }
}

class _XrayBody extends StatelessWidget {
  const _XrayBody({
    required this.weights,
    required this.tab,
    required this.expandedId,
    required this.selectedName,
    required this.hoveredIndex,
    required this.activeIndex,
    required this.previousHoveredIndex,
    required this.hoverAnimation,
    required this.pulseAnimation,
    required this.totalValue,
    required this.holdings,
    required this.marketCapAllocation,
    required this.donutCap,
    required this.onHover,
    required this.onHoverExit,
    required this.onTapDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onTap,
    required this.onSelect,
    required this.onExpand,
    required this.onDonutSide,
    required this.showTabsInBody,
    required this.tabs,
    this.fillHeight = true,
    this.sideBySide = false,
    this.mobileShowList = false,
  });

  final List<XrayWeight> weights;
  final int tab;
  final String? expandedId;
  final String? selectedName;
  final int? hoveredIndex;
  final int? activeIndex;
  final int? previousHoveredIndex;
  final Animation<double> hoverAnimation;
  final Animation<double> pulseAnimation;
  final double? totalValue;
  final List<PortfolioHolding>? holdings;
  final MarketCapAllocation? marketCapAllocation;
  final double donutCap;
  final void Function(Offset local, double side) onHover;
  final VoidCallback onHoverExit;
  final void Function(Offset local, double side) onTapDown;
  final void Function(Offset local, double side) onPointerMove;
  final VoidCallback onPointerUp;
  final VoidCallback onTap;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onExpand;
  final ValueChanged<double> onDonutSide;
  final bool showTabsInBody;
  final Widget tabs;
  final bool fillHeight;
  final bool sideBySide;
  /// When [sideBySide] is false, show list instead of donut.
  final bool mobileShowList;

  @override
  Widget build(BuildContext context) {
    Widget weightList({required double paneWidth}) {
      if (weights.isEmpty) {
        return const IntelligenceEmptyHint(message: 'No allocation data');
      }
      final pctW = paneWidth < 280 ? 44.0 : 52.0;
      final inrW = paneWidth < 280 ? 52.0 : 64.0;
      final listScrolls = fillHeight || (!sideBySide && mobileShowList);
      return ListView.builder(
        shrinkWrap: !listScrolls,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.hardEdge,
        physics: listScrolls
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: weights.length,
        itemBuilder: (context, i) {
          final w = weights[i];
          final color = intelligenceDonutColor(i);
          final resolved = _holdingsFor(w);
          return _WeightBar(
            weight: w,
            color: color,
            pctCol: pctW,
            inrCol: inrW,
            selected: xrayRowTintSelected(
              index: i,
              hoveredIndex: hoveredIndex,
              selectedName: selectedName,
              weightName: w.name,
            ),
            expanded: expandedId == w.name,
            onSelect: () => onSelect(w.name),
            onExpand: () => onExpand(w.name),
            holdings: resolved.holdings,
            emptyMessage: resolved.emptyMessage,
            groupPct: w.weightPct,
          );
        },
      );
    }

    final donut = LayoutBuilder(
      builder: (context, constraints) {
        final maxSide = math.min(
          donutCap,
          math.min(
            constraints.hasBoundedWidth ? constraints.maxWidth : donutCap,
            constraints.hasBoundedHeight ? constraints.maxHeight : donutCap,
          ),
        );
        final side = maxSide.clamp(120.0, donutCap);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onDonutSide(side);
        });
        return SizedBox(
          width: side,
          height: side,
          child: MouseRegion(
            opaque: true,
            cursor: SystemMouseCursors.click,
            onHover: (e) => onHover(e.localPosition, side),
            onExit: (_) => onHoverExit(),
            child: Listener(
              onPointerMove: (e) {
                onPointerMove(e.localPosition, side);
              },
              onPointerUp: (_) => onPointerUp(),
              onPointerCancel: (_) => onPointerUp(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => onTapDown(d.localPosition, side),
                onTap: onTap,
                child: AnimatedBuilder(
                  animation: Listenable.merge([hoverAnimation, pulseAnimation]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _CompactGlowingDonutPainter(
                        weights: weights,
                        palette: IntelligenceDonut.palette,
                        hoveredIndex: activeIndex,
                        previousHoveredIndex: previousHoveredIndex,
                        hoverProgress: hoverAnimation.value,
                        pulse: pulseAnimation.value,
                      ),
                      child: IgnorePointer(
                        child: Center(child: _centerLabel(context)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    final legendPane = LayoutBuilder(
      builder: (context, constraints) {
        final paneW = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        if (weights.isEmpty) {
          return const IntelligenceEmptyHint(message: 'No allocation data');
        }
        final list = fillHeight
            ? ClipRect(child: weightList(paneWidth: paneW))
            : ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: sideBySide ? 220 : 360,
                ),
                child: ClipRect(child: weightList(paneWidth: paneW)),
              );
        return IntelligenceInsetPanel(child: list);
      },
    );

    final Widget main;
    if (sideBySide) {
      main = Row(
        crossAxisAlignment:
            fillHeight ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
        children: [
          donut,
          const SizedBox(width: 12),
          Expanded(child: legendPane),
        ],
      );
    } else {
      // Phone: Chart/List lives in the card header; body is donut or list only.
      final pane = mobileShowList
          ? (fillHeight ? Expanded(child: legendPane) : legendPane)
          : Center(child: donut);
      main = fillHeight
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (mobileShowList)
                  pane
                else
                  Expanded(child: pane),
              ],
            )
          : pane;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (showTabsInBody) ...[
          tabs,
          const SizedBox(height: 10),
        ],
        if (fillHeight) Expanded(child: main) else main,
      ],
    );
  }

  Widget _centerLabel(BuildContext context) {
    if (activeIndex != null &&
        activeIndex! >= 0 &&
        activeIndex! < weights.length) {
      final w = weights[activeIndex!];
      final color = intelligenceDonutColor(activeIndex!);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${w.weightPct.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 20,
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              xrayDisplayName(w.name),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (w.valueInr != null)
            Tooltip(
              message: NumberFormat.currency(
                locale: 'en_IN',
                symbol: '₹',
                decimalDigits: 0,
              ).format(w.valueInr),
              child: Text(
                formatIntelligenceCompactInr(w.valueInr),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total Exposure',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (totalValue != null && totalValue! > 0)
          Tooltip(
            message: NumberFormat.currency(
              locale: 'en_IN',
              symbol: '₹',
              decimalDigits: 0,
            ).format(totalValue),
            child: Text(
              formatIntelligenceCompactInr(totalValue),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ModuleColors.portfolio,
                  ),
            ),
          ),
        Text(
          '100%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  ({List<PortfolioHolding> holdings, String emptyMessage}) _holdingsFor(
    XrayWeight weight,
  ) {
    const noHoldings = 'No holdings for this group';
    const capUnavailable = 'Cap breakdown unavailable';
    final all = holdings;
    if (all == null || all.isEmpty) {
      return (holdings: const [], emptyMessage: noHoldings);
    }
    Iterable<PortfolioHolding> filtered;
    if (tab == 0) {
      filtered = all.where((h) => h.sector == weight.name);
    } else if (tab == 1) {
      filtered = all.where((h) => h.industry == weight.name);
    } else {
      final display = xrayDisplayName(weight.name);
      final tops = marketCapAllocation?.segments
          .where((s) {
            final seg = s.segmentName;
            return seg == weight.name ||
                seg == display ||
                seg.toUpperCase().replaceAll(' ', '_') ==
                    weight.name.toUpperCase();
          })
          .expand((s) => s.topStocks)
          .toSet();
      if (tops == null || tops.isEmpty) {
        return (holdings: const [], emptyMessage: capUnavailable);
      }
      filtered = all.where((h) => tops.contains(h.symbol));
    }
    final list = filtered.toList()
      ..sort((a, b) => b.portfolioWeight.compareTo(a.portfolioWeight));
    return (holdings: list, emptyMessage: noHoldings);
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.tab,
    required this.onTab,
    this.compact = false,
  });

  final int tab;
  final ValueChanged<int> onTab;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget chip(int i, String label) {
      final selected = tab == i;
      return GestureDetector(
        onTap: () => onTab(i),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: selected ? ModuleColors.portfolio : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? context.colors.cardSurface.withValues(alpha: 0.55)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip(0, 'Sector'),
          chip(1, 'Industry'),
          chip(2, 'Cap'),
        ],
      ),
    );
  }
}

/// Phone Chart ↔ List toggle; mirrors [_Tabs] chip chrome.
class _MobilePaneSwap extends StatelessWidget {
  const _MobilePaneSwap({
    required this.showList,
    required this.onShowList,
  });

  final bool showList;
  final ValueChanged<bool> onShowList;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget chip({
      required bool list,
      required IconData icon,
      required String label,
    }) {
      final selected = showList == list;
      return GestureDetector(
        onTap: () => onShowList(list),
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? ModuleColors.portfolio : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? context.colors.cardSurface.withValues(alpha: 0.55)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip(
            list: false,
            icon: Icons.donut_large_rounded,
            label: 'Chart',
          ),
          chip(
            list: true,
            icon: Icons.view_list_rounded,
            label: 'List',
          ),
        ],
      ),
    );
  }
}

class _WeightBar extends StatelessWidget {
  const _WeightBar({
    required this.weight,
    required this.color,
    required this.pctCol,
    required this.inrCol,
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onExpand,
    required this.holdings,
    required this.groupPct,
    this.emptyMessage = 'No holdings for this group',
  });

  final XrayWeight weight;
  final Color color;
  final double pctCol;
  final double inrCol;
  final bool selected;
  final bool expanded;
  final VoidCallback onSelect;
  final VoidCallback onExpand;
  final List<PortfolioHolding> holdings;
  final double groupPct;
  final String emptyMessage;

  void _openMore(BuildContext context) {
    final label = xrayDisplayName(weight.name);
    showIntelligenceSheet(
      context: context,
      title: label,
      subtitle:
          '${holdings.length} holdings · ${weight.weightPct.toStringAsFixed(1)}% · ${formatIntelligenceCompactInr(weight.valueInr)}',
      body: SizedBox(
        height: 420,
        child: _HoldingsTable(
          holdings: holdings,
          groupPct: groupPct,
          color: color,
          scrollable: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = holdings.take(5).toList();
    final label = xrayDisplayName(weight.name);
    final inrText = formatIntelligenceCompactInr(weight.valueInr);
    final fullInr = weight.valueInr == null
        ? null
        : NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹',
            decimalDigits: 0,
          ).format(weight.valueInr);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected || expanded
            ? color.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, expanded ? 8 : 5, 2, expanded ? 8 : 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  onSelect();
                  onExpand();
                },
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: pctCol),
                          child: Text(
                            '${weight.weightPct.toStringAsFixed(1)}%',
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: inrCol),
                          child: Tooltip(
                            message: fullInr ?? '—',
                            child: Text(
                              inrText,
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 28),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (weight.weightPct / 100).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: color.withValues(alpha: 0.12),
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (expanded) ...[
                const SizedBox(height: 10),
                if (top.isEmpty)
                  Text(
                    emptyMessage,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  )
                else ...[
                  _HoldingsTable(
                    holdings: top,
                    groupPct: groupPct,
                    color: color,
                    scrollable: false,
                  ),
                  if (holdings.length > 5) ...[
                    const SizedBox(height: 8),
                    IntelligenceTextLink(
                      label: '+${holdings.length - 5} more',
                      onPressed: () => _openMore(context),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HoldingsTable extends StatelessWidget {
  const _HoldingsTable({
    required this.holdings,
    required this.groupPct,
    required this.color,
    this.scrollable = false,
  });

  final List<PortfolioHolding> holdings;
  final double groupPct;
  final Color color;
  final bool scrollable;

  static const _inrW = 64.0;
  static const _grpW = 52.0;
  static const _pfW = 48.0;

  @override
  Widget build(BuildContext context) {
    final header = _row(
      context,
      holding: 'HOLDING',
      inr: '₹',
      grp: '% GRP',
      pf: '% PF',
      header: true,
    );

    final rows = <Widget>[
      header,
      const SizedBox(height: 6),
      for (final h in holdings) ...[
        _row(
          context,
          holding: h.symbol,
          inr: formatIntelligenceCompactInr(h.currentValue),
          grp: groupPct > 0
              ? '${((h.portfolioWeight / groupPct) * 100).toStringAsFixed(1)}%'
              : '—',
          pf: '${h.portfolioWeight.toStringAsFixed(1)}%',
          header: false,
        ),
        const SizedBox(height: 6),
      ],
    ];

    if (!scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      );
    }
    return ListView(
      padding: EdgeInsets.zero,
      children: rows,
    );
  }

  Widget _row(
    BuildContext context, {
    required String holding,
    required String inr,
    required String grp,
    required String pf,
    required bool header,
  }) {
    final style = header
        ? TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).hintColor,
            letterSpacing: 0.3,
          )
        : const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          );
    final valueStyle = header
        ? style
        : TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          );

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            holding,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: header
                ? style
                : const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
        SizedBox(
          width: _inrW,
          child: Text(inr, textAlign: TextAlign.end, style: valueStyle),
        ),
        SizedBox(
          width: _grpW,
          child: Text(grp, textAlign: TextAlign.end, style: valueStyle),
        ),
        SizedBox(
          width: _pfW,
          child: Text(pf, textAlign: TextAlign.end, style: valueStyle),
        ),
      ],
    );
  }
}

class _CompactGlowingDonutPainter extends CustomPainter {
  _CompactGlowingDonutPainter({
    required this.weights,
    required this.palette,
    required this.hoveredIndex,
    required this.previousHoveredIndex,
    required this.hoverProgress,
    required this.pulse,
  });

  final List<XrayWeight> weights;
  final List<Color> palette;
  final int? hoveredIndex;
  final int? previousHoveredIndex;
  final double hoverProgress;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.shortestSide / 2) - 12;
    const gap = 0.03;
    var start = -math.pi / 2;
    var total = weights.fold<double>(0, (s, w) => s + w.weightPct);
    if (total <= 0) total = 100;

    for (var i = 0; i < weights.length; i++) {
      final color = palette[i % palette.length];
      double targetAlpha(int? h) => h == null ? 1.0 : (i == h ? 1.0 : 0.38);
      double targetGlow(int? h) => h == null ? 0.22 : (i == h ? 0.55 : 0.06);
      double targetProg(int? h) => h == null ? 0.0 : (i == h ? 1.0 : 0.0);

      final colorAlpha = targetAlpha(previousHoveredIndex) +
          (targetAlpha(hoveredIndex) - targetAlpha(previousHoveredIndex)) *
              hoverProgress;
      final glowAlpha = targetGlow(previousHoveredIndex) +
          (targetGlow(hoveredIndex) - targetGlow(previousHoveredIndex)) *
              hoverProgress;
      final hoverProg = targetProg(previousHoveredIndex) +
          (targetProg(hoveredIndex) - targetProg(previousHoveredIndex)) *
              hoverProgress;
      final idlePulse =
          (i == 0 && hoveredIndex == null) ? pulse * 0.35 : 0.0;

      final radius = baseRadius + 5 * hoverProg + idlePulse;
      final stroke = 18.0 + 2.5 * hoverProg;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final fullSweep = (weights[i].weightPct / total) * 2 * math.pi;
      final sweep = (fullSweep - gap).clamp(0.0, fullSweep);

      if (sweep > 0) {
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt
            ..color = color.withValues(alpha: glowAlpha * colorAlpha)
            ..strokeWidth = stroke + 4 + 4 * hoverProg
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              4 + 6 * hoverProg,
            ),
        );
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt
            ..color = color.withValues(alpha: colorAlpha)
            ..strokeWidth = stroke,
        );
      }
      start += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CompactGlowingDonutPainter old) =>
      old.weights != weights ||
      old.hoveredIndex != hoveredIndex ||
      old.previousHoveredIndex != previousHoveredIndex ||
      old.hoverProgress != hoverProgress ||
      old.pulse != pulse;
}
