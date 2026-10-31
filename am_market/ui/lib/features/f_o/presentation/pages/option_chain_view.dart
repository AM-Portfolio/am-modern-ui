import 'dart:math' as math;
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/option_chain_provider.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/fo_expiry_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OptionChainColumnGroup {
  bidAsk('Bid / Ask'),
  valuation('Valuation & Breakeven'),
  greeks('Option Greeks');

  final String label;
  const OptionChainColumnGroup(this.label);
}

enum _OptionSideFocus { calls, puts }

class OptionChainView extends ConsumerStatefulWidget {
  const OptionChainView({super.key, this.showExpiryInToolbar = true});

  /// The full mobile F&O page hosts its compact expiry control in the tab row.
  final bool showExpiryInToolbar;

  @override
  ConsumerState<OptionChainView> createState() => OptionChainViewState();
}

class OptionChainViewState extends ConsumerState<OptionChainView> {
  late final ScrollController _scrollController;
  late final ScrollController _horizontalScrollController;
  final List<OptionChainColumnGroup> _activeGroups = [];
  String? _lastAutoScrolledKey;
  String? _lastHorizontalCenterKey;
  String? _lastFocusKey;
  _OptionSideFocus? _focusedSide;
  final GlobalKey _spotLineKey = GlobalKey();
  double? _mobileHomeOffset;
  double? _mobileCallsFocusOffset;
  double? _mobilePutsFocusOffset;
  double _horizontalOffset = 0;
  double _verticalOffset = 0;

  static const double _mobileRowMinExtent = 44.0;
  static const double _mobileHeaderMinExtent = 33.0;
  static const double _spotCapsuleExtent = 32.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_syncVerticalOffset);
    _horizontalScrollController = ScrollController();
    _horizontalScrollController.addListener(_syncHorizontalOffset);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncVerticalOffset);
    _horizontalScrollController.removeListener(_syncHorizontalOffset);
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _toggleGroup(OptionChainColumnGroup group) {
    setState(() {
      if (_activeGroups.contains(group)) {
        _activeGroups.remove(group);
      } else {
        if (_activeGroups.length >= 2) {
          _activeGroups.removeAt(0); // Evict oldest
        }
        _activeGroups.add(group);
      }
    });
  }

  void _focusOptionSide(_OptionSideFocus side) {
    final returnHome = _focusedSide == side;
    setState(() => _focusedSide = returnHome ? null : side);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_horizontalScrollController.hasClients) return;
      final target = returnHome
          ? _mobileHomeOffset
          : side == _OptionSideFocus.calls
              ? _mobileCallsFocusOffset
              : _mobilePutsFocusOffset;
      if (target == null) return;
      final position = _horizontalScrollController.position;
      _horizontalScrollController.animateTo(
        target.clamp(0.0, position.maxScrollExtent),
        duration: AppAnimations.medium,
        curve: AppAnimations.defaultCurve,
      );
    });
  }

  void _syncVerticalOffset() {
    if (!mounted || !_scrollController.hasClients) return;
    final nextOffset = _scrollController.position.pixels;
    if ((nextOffset - _verticalOffset).abs() > 0.5) {
      setState(() => _verticalOffset = nextOffset);
    }
  }

  void _syncHorizontalOffset() {
    if (!mounted || !_horizontalScrollController.hasClients) return;
    final nextOffset = _horizontalScrollController.position.pixels;
    if ((nextOffset - _horizontalOffset).abs() > 0.5) {
      setState(() => _horizontalOffset = nextOffset);
    }
  }

  /// Restores the default Spot-centered view when the cached F&O page is
  /// revisited. The parent navigator retains this state between sections.
  void resetToSpotPosition() {
    if (!mounted) return;
    setState(() {
      _focusedSide = null;
      _lastAutoScrolledKey = null;
      _lastHorizontalCenterKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final chainAsync = ref.watch(optionChainProvider);

    return chainAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: ModuleColors.market)),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: marketTheme.negative, size: 36),
            const SizedBox(height: 12),
            Text(
              'Failed to load Option Chain',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              err.toString(),
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      data: (data) {
        if (data == null || data.isEmpty) {
          return Center(
            child: Text(
              'No Option Chain data available',
              style: TextStyle(color: colors.textSecondary),
            ),
          );
        }

        final underlyingLtp =
            (data['underlyingLtp'] as num?)?.toDouble() ?? 0.0;
        // Work on a copy: the backend does not guarantee strike ordering, but
        // rendering and Spot placement need a stable numerical sequence.
        final rawStrikes = List<dynamic>.from(
          (data['strikes'] as List<dynamic>?) ?? const <dynamic>[],
        )..sort((left, right) {
            final leftStrike =
                ((left as Map<String, dynamic>)['strikePrice'] as num?)
                        ?.toDouble() ??
                    0.0;
            final rightStrike =
                ((right as Map<String, dynamic>)['strikePrice'] as num?)
                        ?.toDouble() ??
                    0.0;
            return leftStrike.compareTo(rightStrike);
          });
        final expiriesList = (data['expiries'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final currentExpiry = (data['expiry'] as String?) ?? '';
        final activeExpiry =
            ref.watch(foSelectedExpiryProvider) ?? currentExpiry;

        // Pre-calculate max OI for relative visual bar calculations
        double maxOi = 1.0;
        for (final item in rawStrikes) {
          final strikeMap = item as Map<String, dynamic>;
          final callMap = (strikeMap['call'] as Map<String, dynamic>?) ?? {};
          final putMap = (strikeMap['put'] as Map<String, dynamic>?) ?? {};
          final cOi = (callMap['oi'] as num?)?.toDouble() ?? 0.0;
          final pOi = (putMap['oi'] as num?)?.toDouble() ?? 0.0;
          maxOi = math.max(maxOi, math.max(cOi, pOi));
        }

        // Determine the Spot divider row. This is order-safe and still shows
        // the nearest strike when the feed's range does not bracket the price.
        int spotIndex = -1;
        var nearestStrikeIndex = -1;
        var nearestStrikeDistance = double.infinity;
        for (var i = 0; i < rawStrikes.length; i++) {
          final strike =
              ((rawStrikes[i] as Map<String, dynamic>)['strikePrice'] as num?)
                      ?.toDouble() ??
                  0.0;
          final distance = (underlyingLtp - strike).abs();
          if (distance < nearestStrikeDistance) {
            nearestStrikeDistance = distance;
            nearestStrikeIndex = i;
          }
        }
        for (int i = 0; i < rawStrikes.length - 1; i++) {
          final s1 =
              ((rawStrikes[i] as Map<String, dynamic>)['strikePrice'] as num?)
                      ?.toDouble() ??
                  0.0;
          final s2 = ((rawStrikes[i + 1] as Map<String, dynamic>)['strikePrice']
                      as num?)
                  ?.toDouble() ??
              0.0;
          final lowerStrike = math.min(s1, s2);
          final upperStrike = math.max(s1, s2);
          if (underlyingLtp >= lowerStrike && underlyingLtp < upperStrike) {
            spotIndex = i;
            break;
          }
        }
        if (spotIndex == -1) spotIndex = nearestStrikeIndex;

        final activeSymbol = ref.watch(foActiveSymbolProvider) ?? '';
        final currentKey =
            '${activeSymbol}_${activeExpiry}_${rawStrikes.length}';
        final spotPositionKey = '${currentKey}_$spotIndex';
        if (_lastFocusKey != currentKey) {
          _lastFocusKey = currentKey;
          _focusedSide = null;
        }

        final isMobileLayout =
            MediaQuery.sizeOf(context).width < AmBreakpoints.mobile;

        // Desktop keeps the inline Spot divider. Mobile uses the exact row
        // extent calculated below, once the ListView has a viewport.
        if (!isMobileLayout &&
            _lastAutoScrolledKey != spotPositionKey &&
            spotIndex != -1) {
          _lastAutoScrolledKey = spotPositionKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollController.hasClients) return;
            final position = _scrollController.position;
            final estimate = (spotIndex + 1) * _mobileRowMinExtent -
                position.viewportDimension / 2;
            _scrollController.jumpTo(
              estimate.clamp(0.0, position.maxScrollExtent).toDouble(),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_scrollController.hasClients) return;
              final renderObj = _spotLineKey.currentContext?.findRenderObject();
              if (renderObj != null) {
                _scrollController.position.ensureVisible(
                  renderObj,
                  alignment: 0.5,
                  duration: Duration.zero,
                );
              }
            });
          });
        }

        return Column(
          children: [
            _buildToolbar(
              context,
              colors,
              marketTheme,
              expiriesList: expiriesList,
              activeExpiry: activeExpiry,
              isMobileLayout: isMobileLayout,
            ),
            const Divider(height: 1),

            // Option Chain Table Header & Matrix Rows
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Dynamically compute width based on active column count
                  final columnCount = 5 +
                      (_activeGroups.contains(OptionChainColumnGroup.bidAsk)
                          ? 4
                          : 0) +
                      (_activeGroups.contains(OptionChainColumnGroup.valuation)
                          ? 6
                          : 0) +
                      (_activeGroups.contains(OptionChainColumnGroup.greeks)
                          ? 4
                          : 0);
                  final rowPaddingH = isMobileLayout ? 10.0 : 16.0;
                  final rowPaddingV = isMobileLayout ? 6.0 : 10.0;
                  final headerPaddingV = isMobileLayout ? 6.0 : 10.0;
                  // The STRIKE chip is positioned over the row, so it cannot
                  // supply the row's intrinsic height. Give every mobile item
                  // the same extent used by Spot scrolling and positioning.
                  final mobileRowExtent = math.max(
                    _mobileRowMinExtent,
                    MediaQuery.textScalerOf(context).scale(12.0) * 1.4 +
                        2 * rowPaddingV +
                        12,
                  );
                  final mobileHeaderExtent = math.max(
                    _mobileHeaderMinExtent,
                    MediaQuery.textScalerOf(context).scale(12.0) * 1.4 + 12,
                  );

                  // The default mobile position exposes the central
                  // Call-LTP / Strike / Put-LTP band exactly. When a side is
                  // focused, the width expands to show a clean four-column
                  // side window without neighbouring column slivers.
                  final leftOptionalFlex = (_activeGroups
                              .contains(OptionChainColumnGroup.greeks)
                          ? 6
                          : 0) +
                      (_activeGroups.contains(OptionChainColumnGroup.valuation)
                          ? 6
                          : 0) +
                      (_activeGroups.contains(OptionChainColumnGroup.bidAsk)
                          ? 4
                          : 0);
                  // A three-flex STRIKE column keeps the values readable on
                  // phones while the home position still shows Call LTP,
                  // STRIKE, and Put LTP as one complete band.
                  final totalFlex = 15 + (leftOptionalFlex * 2);
                  final visibleFlex = _focusedSide == null ? 11 : 12;
                  final mobileFocusWidth = isMobileLayout
                      ? rowPaddingH * 2 +
                          math.max(
                                0.0,
                                constraints.maxWidth - rowPaddingH * 2,
                              ) *
                              totalFlex /
                              visibleFlex
                      : 0.0;
                  final minWidth = math.max(
                    isMobileLayout ? mobileFocusWidth : 850.0,
                    isMobileLayout ? 0.0 : columnCount * 80.0,
                  );
                  final contentWidth = math.max(minWidth, constraints.maxWidth);
                  final needsHorizontalScroll =
                      contentWidth > constraints.maxWidth;

                  if (isMobileLayout) {
                    final flexUnit =
                        (contentWidth - rowPaddingH * 2) / totalFlex;
                    _mobileHomeOffset = (2 + leftOptionalFlex) * flexUnit;
                    _mobileCallsFocusOffset = 0.0;
                    _mobilePutsFocusOffset = math.max(
                      0.0,
                      contentWidth - constraints.maxWidth,
                    );
                  }

                  final strikeWidth = isMobileLayout
                      ? 3 * (contentWidth - rowPaddingH * 2) / totalFlex
                      : 0.0;
                  final naturalStrikeLeft = isMobileLayout
                      ? (6 + leftOptionalFlex) *
                          (contentWidth - rowPaddingH * 2) /
                          totalFlex
                      : 0.0;
                  final naturalStrikeViewportLeft =
                      rowPaddingH + naturalStrikeLeft - _horizontalOffset;
                  final stickyStrikeViewportLeft = isMobileLayout
                      ? naturalStrikeViewportLeft
                          .clamp(
                            0.0,
                            math.max(0.0, constraints.maxWidth - strikeWidth),
                          )
                          .toDouble()
                      : 0.0;
                  final stickyStrikeLeft = isMobileLayout
                      ? _horizontalOffset +
                          stickyStrikeViewportLeft -
                          rowPaddingH
                      : 0.0;
                  final isStrikePinned = isMobileLayout &&
                      (stickyStrikeViewportLeft - naturalStrikeViewportLeft)
                              .abs() >
                          0.5;

                  if (_lastHorizontalCenterKey != currentKey) {
                    _lastHorizontalCenterKey = currentKey;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_horizontalScrollController.hasClients) return;
                      final viewport = _horizontalScrollController
                          .position.viewportDimension;
                      final maxScroll =
                          _horizontalScrollController.position.maxScrollExtent;
                      if (viewport <= 0 || maxScroll <= 0) return;
                      final targetOffset = isMobileLayout
                          ? _mobileHomeOffset ?? 0.0
                          : math.max(0.0, (contentWidth - viewport) / 2);
                      _horizontalScrollController.jumpTo(
                        math.min(targetOffset, maxScroll),
                      );
                    });
                  }
                  final showSwipeHint = needsHorizontalScroll;
                  final tableHeight =
                      constraints.maxHeight - (showSwipeHint ? 30.0 : 0.0);
                  if (isMobileLayout &&
                      spotIndex != -1 &&
                      _lastAutoScrolledKey != currentKey) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || !_scrollController.hasClients) return;
                      final position = _scrollController.position;
                      if (!position.hasContentDimensions ||
                          position.viewportDimension <= 0) {
                        return;
                      }
                      final dividerOffset = (spotIndex + 1) * mobileRowExtent;
                      final target =
                          (dividerOffset - position.viewportDimension / 2)
                              .clamp(0.0, position.maxScrollExtent)
                              .toDouble();
                      _lastAutoScrolledKey = currentKey;
                      _scrollController.jumpTo(target);
                    });
                  }
                  final spotViewportY = mobileHeaderExtent +
                      (spotIndex + 1) * mobileRowExtent -
                      _verticalOffset;

                  return Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: needsHorizontalScroll,
                              child: SingleChildScrollView(
                                controller: _horizontalScrollController,
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: contentWidth,
                                  height: tableHeight,
                                  child: Column(
                                    children: [
                                      Container(
                                        height: isMobileLayout
                                            ? mobileHeaderExtent - 1
                                            : null,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: rowPaddingH,
                                          vertical: isMobileLayout
                                              ? 0
                                              : headerPaddingV,
                                        ),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        child: Stack(
                                          children: [
                                            Row(
                                              children: _buildHeaderColumns(
                                                context,
                                                marketTheme,
                                                colors,
                                                isMobileLayout: isMobileLayout,
                                                reserveStrike: isMobileLayout,
                                              ),
                                            ),
                                            if (isMobileLayout)
                                              Positioned(
                                                left: stickyStrikeLeft,
                                                width: strikeWidth,
                                                top: 0,
                                                bottom: 0,
                                                child: _buildStickyStrikeHeader(
                                                  colors,
                                                  pinned: isStrikePinned,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Expanded(
                                        child: ListView.builder(
                                          controller: _scrollController,
                                          itemExtent: isMobileLayout
                                              ? mobileRowExtent
                                              : null,
                                          itemCount: rawStrikes.length,
                                          itemBuilder: (context, index) {
                                            final strikeMap = rawStrikes[index]
                                                as Map<String, dynamic>;
                                            final strikePrice =
                                                (strikeMap['strikePrice']
                                                            as num?)
                                                        ?.toDouble() ??
                                                    0.0;
                                            final callMap = (strikeMap['call']
                                                    as Map<String, dynamic>?) ??
                                                {};
                                            final putMap = (strikeMap['put']
                                                    as Map<String, dynamic>?) ??
                                                {};
                                            return Column(
                                              children: [
                                                SizedBox(
                                                  height: isMobileLayout
                                                      ? mobileRowExtent - 1
                                                      : null,
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: rowPaddingH,
                                                      vertical: rowPaddingV,
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        Row(
                                                          children:
                                                              _buildRowColumns(
                                                            context,
                                                            strikePrice,
                                                            underlyingLtp,
                                                            callMap,
                                                            putMap,
                                                            maxOi,
                                                            colors,
                                                            marketTheme,
                                                            isMobileLayout:
                                                                isMobileLayout,
                                                            reserveStrike:
                                                                isMobileLayout,
                                                          ),
                                                        ),
                                                        if (isMobileLayout)
                                                          Positioned(
                                                            left:
                                                                stickyStrikeLeft,
                                                            width: strikeWidth,
                                                            top: 0,
                                                            bottom: 0,
                                                            child:
                                                                _buildStickyStrikeCell(
                                                              strikePrice,
                                                              colors,
                                                              pinned:
                                                                  isStrikePinned,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                if (index == spotIndex)
                                                  isMobileLayout
                                                      ? SizedBox(
                                                          key: _spotLineKey,
                                                          height: 1,
                                                        )
                                                      : _buildSpotPriceLine(
                                                          context,
                                                          underlyingLtp,
                                                          colors,
                                                          marketTheme,
                                                          key: _spotLineKey,
                                                        )
                                                else
                                                  Divider(
                                                    height: 1,
                                                    indent: rowPaddingH,
                                                    endIndent: rowPaddingH,
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (isMobileLayout &&
                                spotIndex != -1 &&
                                spotViewportY >= mobileHeaderExtent &&
                                spotViewportY <= tableHeight)
                              Positioned(
                                top: spotViewportY - _spotCapsuleExtent / 2,
                                left: 0,
                                right: 0,
                                child: IgnorePointer(
                                  child: _buildSpotPriceLine(
                                    context,
                                    underlyingLtp,
                                    colors,
                                    marketTheme,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (showSwipeHint)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            'Swipe left or right to see more data',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    AppColorsTheme colors,
    MarketThemeExtension marketTheme, {
    required List<String> expiriesList,
    required String activeExpiry,
    required bool isMobileLayout,
  }) {
    final toolbarColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.15);
    final expiryControl = FoExpiryPicker(
      expiries: expiriesList,
      activeExpiry: activeExpiry,
      onSelected: (expiry) =>
          ref.read(foSelectedExpiryProvider.notifier).state = expiry,
      fullWidth: isMobileLayout,
    );
    const chipGroups = OptionChainColumnGroup.values;

    String chipLabel(OptionChainColumnGroup group, {required bool compact}) {
      if (!compact) return group.label;
      switch (group) {
        case OptionChainColumnGroup.bidAsk:
          return 'Bid';
        case OptionChainColumnGroup.valuation:
          return 'Val';
        case OptionChainColumnGroup.greeks:
          return 'Grk';
      }
    }

    Widget sideBadge({
      required String text,
      required Color accent,
      required bool expand,
      VoidCallback? onTap,
      bool selected = false,
    }) {
      final child = Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: expand ? 2 : 8,
          vertical: expand ? 10 : 6,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: selected ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: accent.withValues(alpha: selected ? 1 : 0.35),
          ),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
            fontSize: expand ? 10 : 11,
          ),
        ),
      );
      if (onTap == null) return child;
      return Semantics(
        button: true,
        label: 'Show ${text.toLowerCase()} columns',
        child: InkWell(onTap: onTap, child: child),
      );
    }

    Widget compactToggle({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Material(
        color: selected
            ? ModuleColors.market.withValues(alpha: 0.22)
            : colors.cardSurface,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected
                    ? ModuleColors.market
                    : colors.border.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? ModuleColors.market : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ),
        ),
      );
    }

    Widget groupChips({required bool compact}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < chipGroups.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              FilterChip(
                label: Text(chipLabel(chipGroups[i], compact: compact)),
                selected: _activeGroups.contains(chipGroups[i]),
                onSelected: (_) => _toggleGroup(chipGroups[i]),
                selectedColor: ModuleColors.market.withValues(alpha: 0.2),
                checkmarkColor: ModuleColors.market,
                labelStyle: TextStyle(
                  color: _activeGroups.contains(chipGroups[i])
                      ? ModuleColors.market
                      : colors.textSecondary,
                  fontWeight: _activeGroups.contains(chipGroups[i])
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 11,
                ),
                side: BorderSide(
                  color: _activeGroups.contains(chipGroups[i])
                      ? ModuleColors.market
                      : colors.border.withValues(alpha: 0.3),
                ),
                visualDensity: VisualDensity.standard,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ],
          ],
        );

    // Compact equal-flex row: CALLS | Bid | Val | Grk | PUTS (always fits).
    Widget mobileGroupRow() {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: sideBadge(
              text: 'CALLS',
              accent: marketTheme.positive,
              expand: true,
              selected: _focusedSide == _OptionSideFocus.calls,
              onTap: () => _focusOptionSide(_OptionSideFocus.calls),
            ),
          ),
          const SizedBox(width: 3),
          for (final group in chipGroups) ...[
            Expanded(
              flex: 3,
              child: compactToggle(
                label: chipLabel(group, compact: true),
                selected: _activeGroups.contains(group),
                onTap: () => _toggleGroup(group),
              ),
            ),
            const SizedBox(width: 3),
          ],
          Expanded(
            flex: 3,
            child: sideBadge(
              text: 'PUTS',
              accent: marketTheme.negative,
              expand: true,
              selected: _focusedSide == _OptionSideFocus.puts,
              onTap: () => _focusOptionSide(_OptionSideFocus.puts),
            ),
          ),
        ],
      );
    }

    if (isMobileLayout) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        color: toolbarColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showExpiryInToolbar) ...[
              expiryControl,
              const SizedBox(height: 6),
            ],
            mobileGroupRow(),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: toolbarColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            expiryControl,
            const SizedBox(width: 12),
            sideBadge(
              text: 'CALLS',
              accent: marketTheme.positive,
              expand: false,
            ),
            const SizedBox(width: 12),
            groupChips(compact: false),
            const SizedBox(width: 12),
            sideBadge(
              text: 'PUTS',
              accent: marketTheme.negative,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Groww-Style Spot Price Line Capsule Divider
  Widget _buildSpotPriceLine(
    BuildContext context,
    double underlyingLtp,
    AppColorsTheme colors,
    MarketThemeExtension marketTheme, {
    Key? key,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1.5,
              color: ModuleColors.market.withValues(alpha: 0.6),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ModuleColors.market, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: ModuleColors.market.withValues(alpha: 0.25),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: ModuleColors.market,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Spot: ₹${underlyingLtp.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: ModuleColors.market,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: ModuleColors.market.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the one semantic STRIKE header above the horizontally-scrollable
  /// option-chain data. On mobile, its x-position is clamped to the viewport
  /// by the table layout so it stays readable as either side is explored.
  Widget _buildStickyStrikeHeader(
    AppColorsTheme colors, {
    required bool pinned,
    double fontSize = 12,
  }) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pinned ? colors.surface : null,
        border: pinned
            ? Border.all(color: ModuleColors.market.withValues(alpha: 0.3))
            : null,
        boxShadow: pinned
            ? [
                BoxShadow(
                  color: ModuleColors.market.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        'STRIKE',
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }

  /// The strike cell is visually lifted above side columns only while pinned.
  /// Its data remains in the original row; this is a responsive presentation
  /// layer, not a duplicated strike column.
  Widget _buildStickyStrikeCell(
    double strikePrice,
    AppColorsTheme colors, {
    required bool pinned,
    double fontSize = 12,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: pinned
                ? ModuleColors.market.withValues(alpha: 0.4)
                : colors.border.withValues(alpha: 0.3),
          ),
          boxShadow: pinned
              ? [
                  BoxShadow(
                    color: ModuleColors.market.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          strikePrice.toStringAsFixed(0),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHeaderColumns(
    BuildContext context,
    MarketThemeExtension marketTheme,
    AppColorsTheme colors, {
    required bool isMobileLayout,
    required bool reserveStrike,
  }) {
    final headerFont = isMobileLayout ? 11.0 : 11.0;
    final strikeHeaderFont = isMobileLayout ? 12.0 : 12.0;
    TextStyle callStyle = TextStyle(
      color: marketTheme.positive,
      fontWeight: FontWeight.bold,
      fontSize: headerFont,
    );
    TextStyle putStyle = TextStyle(
      color: marketTheme.negative,
      fontWeight: FontWeight.bold,
      fontSize: headerFont,
    );
    final cols = <Widget>[];

    // --- CALLS SIDE ---
    // Core Call OI
    cols.add(
      Expanded(
        flex: 2,
        child: Center(child: Text('CALL OI', style: callStyle)),
      ),
    );

    // Optional Call Greeks
    if (_activeGroups.contains(OptionChainColumnGroup.greeks)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('DELTA', style: callStyle)),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('THETA', style: callStyle)),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('IV', style: callStyle)),
        ),
      );
    }

    // Optional Call Valuation
    if (_activeGroups.contains(OptionChainColumnGroup.valuation)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('INT VAL', style: callStyle)),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('TIME VAL', style: callStyle)),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('BREAKEVEN %', style: callStyle)),
        ),
      );
    }

    // Optional Call Depth
    if (_activeGroups.contains(OptionChainColumnGroup.bidAsk)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('BID', style: callStyle)),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('ASK', style: callStyle)),
        ),
      );
    }

    // Core Call LTP
    cols.add(
      Expanded(
        flex: isMobileLayout ? 4 : 3,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isMobileLayout ? 'LTP / CHG%' : 'LTP (CHG %)',
              style: callStyle,
            ),
          ),
        ),
      ),
    );

    // --- CENTER STRIKE ---
    cols.add(
      Expanded(
        flex: isMobileLayout ? 3 : 2,
        child: reserveStrike
            ? const SizedBox()
            : _buildStickyStrikeHeader(
                colors,
                pinned: false,
                fontSize: strikeHeaderFont,
              ),
      ),
    );

    // --- PUTS SIDE ---
    // Core Put LTP
    cols.add(
      Expanded(
        flex: isMobileLayout ? 4 : 3,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isMobileLayout ? 'LTP / CHG%' : 'LTP (CHG %)',
              style: putStyle,
            ),
          ),
        ),
      ),
    );

    // Optional Put Depth
    if (_activeGroups.contains(OptionChainColumnGroup.bidAsk)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('ASK', style: putStyle)),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('BID', style: putStyle)),
        ),
      );
    }

    // Optional Put Valuation
    if (_activeGroups.contains(OptionChainColumnGroup.valuation)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('BREAKEVEN %', style: putStyle)),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('TIME VAL', style: putStyle)),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('INT VAL', style: putStyle)),
        ),
      );
    }

    // Optional Put Greeks
    if (_activeGroups.contains(OptionChainColumnGroup.greeks)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('IV', style: putStyle)),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('THETA', style: putStyle)),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(child: Text('DELTA', style: putStyle)),
        ),
      );
    }

    // Core Put OI
    cols.add(
      Expanded(
        flex: 2,
        child: Center(child: Text('PUT OI', style: putStyle)),
      ),
    );

    return cols;
  }

  List<Widget> _buildRowColumns(
    BuildContext context,
    double strikePrice,
    double underlyingLtp,
    Map<String, dynamic> callMap,
    Map<String, dynamic> putMap,
    double maxOi,
    AppColorsTheme colors,
    MarketThemeExtension marketTheme, {
    required bool isMobileLayout,
    required bool reserveStrike,
  }) {
    final cellFont = isMobileLayout ? 11.0 : 12.0;
    final ltpFont = isMobileLayout ? 12.0 : 12.0;
    final chgFont = isMobileLayout ? 11.0 : 10.0;
    // Call metrics
    final callLtp = (callMap['ltp'] as num?)?.toDouble() ?? 0.0;
    final callClose = (callMap['closePrice'] as num?)?.toDouble() ?? 0.0;
    final callChgPct =
        callClose > 0 ? ((callLtp - callClose) / callClose) * 100 : 0.0;
    final callOi = (callMap['oi'] as num?)?.toDouble() ?? 0.0;
    final callIv = ((callMap['greeks'] as Map<String, dynamic>?)?['iv'] as num?)
            ?.toDouble() ??
        0.0;
    final callBid = (callMap['bidPrice'] as num?)?.toDouble() ?? 0.0;
    final callAsk = (callMap['askPrice'] as num?)?.toDouble() ?? 0.0;
    final callDelta =
        ((callMap['greeks'] as Map<String, dynamic>?)?['delta'] as num?)
                ?.toDouble() ??
            0.0;
    final callTheta =
        ((callMap['greeks'] as Map<String, dynamic>?)?['theta'] as num?)
                ?.toDouble() ??
            0.0;

    final callIntVal = math.max(0.0, underlyingLtp - strikePrice);
    final callTimeVal = math.max(0.0, callLtp - callIntVal);
    final callBreakeven = strikePrice + callLtp;
    final callBreakevenPct = underlyingLtp > 0
        ? ((callBreakeven - underlyingLtp) / underlyingLtp) * 100
        : 0.0;

    // Put metrics
    final putLtp = (putMap['ltp'] as num?)?.toDouble() ?? 0.0;
    final putClose = (putMap['closePrice'] as num?)?.toDouble() ?? 0.0;
    final putChgPct =
        putClose > 0 ? ((putLtp - putClose) / putClose) * 100 : 0.0;
    final putOi = (putMap['oi'] as num?)?.toDouble() ?? 0.0;
    final putIv = ((putMap['greeks'] as Map<String, dynamic>?)?['iv'] as num?)
            ?.toDouble() ??
        0.0;
    final putBid = (putMap['bidPrice'] as num?)?.toDouble() ?? 0.0;
    final putAsk = (putMap['askPrice'] as num?)?.toDouble() ?? 0.0;
    final putDelta =
        ((putMap['greeks'] as Map<String, dynamic>?)?['delta'] as num?)
                ?.toDouble() ??
            0.0;
    final putTheta =
        ((putMap['greeks'] as Map<String, dynamic>?)?['theta'] as num?)
                ?.toDouble() ??
            0.0;

    final putIntVal = math.max(0.0, strikePrice - underlyingLtp);
    final putTimeVal = math.max(0.0, putLtp - putIntVal);
    final putBreakeven = strikePrice - putLtp;
    final putBreakevenPct = underlyingLtp > 0
        ? ((underlyingLtp - putBreakeven) / underlyingLtp) * 100
        : 0.0;

    final callOiRatio = (callOi / maxOi).clamp(0.0, 1.0);
    final putOiRatio = (putOi / maxOi).clamp(0.0, 1.0);

    final cols = <Widget>[];

    // --- CALLS SIDE ---
    // Call OI
    cols.add(
      Expanded(
        flex: 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: callOiRatio,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: marketTheme.positive.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            Text(
              callOi > 0 ? '${(callOi / 1000).toStringAsFixed(1)}k' : '-',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ],
        ),
      ),
    );

    // Call Greeks
    if (_activeGroups.contains(OptionChainColumnGroup.greeks)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              callDelta != 0 ? callDelta.toStringAsFixed(2) : '-',
              style: TextStyle(color: colors.textPrimary, fontSize: cellFont),
            ),
          ),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              callTheta != 0 ? callTheta.toStringAsFixed(2) : '-',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              callIv > 0 ? '${callIv.toStringAsFixed(1)}%' : '-',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
    }

    // Call Valuation
    if (_activeGroups.contains(OptionChainColumnGroup.valuation)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              '₹${callIntVal.toStringAsFixed(1)}',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              '₹${callTimeVal.toStringAsFixed(1)}',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              '${callBreakevenPct.toStringAsFixed(1)}%',
              style: TextStyle(color: colors.textPrimary, fontSize: cellFont),
            ),
          ),
        ),
      );
    }

    // Call Depth
    if (_activeGroups.contains(OptionChainColumnGroup.bidAsk)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              callBid > 0 ? '₹${callBid.toStringAsFixed(2)}' : '-',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              callAsk > 0 ? '₹${callAsk.toStringAsFixed(2)}' : '-',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
    }

    // Call LTP & Chg %
    cols.add(
      Expanded(
        flex: isMobileLayout ? 4 : 3,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${callLtp.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: ltpFont,
                  ),
                ),
                if (isMobileLayout || callChgPct != 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${callChgPct > 0 ? '+' : ''}${callChgPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: callChgPct > 0
                          ? marketTheme.positive
                          : (callChgPct < 0
                              ? marketTheme.negative
                              : colors.textSecondary),
                      fontSize: chgFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // --- CENTER STRIKE ---
    cols.add(
      Expanded(
        flex: isMobileLayout ? 3 : 2,
        child: reserveStrike
            ? const SizedBox()
            : _buildStickyStrikeCell(
                strikePrice,
                colors,
                pinned: false,
                fontSize: ltpFont,
              ),
      ),
    );

    // --- PUTS SIDE ---
    // Put LTP & Chg %
    cols.add(
      Expanded(
        flex: isMobileLayout ? 4 : 3,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${putLtp.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: ltpFont,
                  ),
                ),
                if (isMobileLayout || putChgPct != 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${putChgPct > 0 ? '+' : ''}${putChgPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: putChgPct > 0
                          ? marketTheme.positive
                          : (putChgPct < 0
                              ? marketTheme.negative
                              : colors.textSecondary),
                      fontSize: chgFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // Put Depth
    if (_activeGroups.contains(OptionChainColumnGroup.bidAsk)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              putAsk > 0 ? '₹${putAsk.toStringAsFixed(2)}' : '-',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              putBid > 0 ? '₹${putBid.toStringAsFixed(2)}' : '-',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
    }

    // Put Valuation
    if (_activeGroups.contains(OptionChainColumnGroup.valuation)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              '${putBreakevenPct.toStringAsFixed(1)}%',
              style: TextStyle(color: colors.textPrimary, fontSize: cellFont),
            ),
          ),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              '₹${putTimeVal.toStringAsFixed(1)}',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              '₹${putIntVal.toStringAsFixed(1)}',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
    }

    // Put Greeks
    if (_activeGroups.contains(OptionChainColumnGroup.greeks)) {
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              putIv > 0 ? '${putIv.toStringAsFixed(1)}%' : '-',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              putTheta != 0 ? putTheta.toStringAsFixed(2) : '-',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ),
        ),
      );
      cols.add(
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              putDelta != 0 ? putDelta.toStringAsFixed(2) : '-',
              style: TextStyle(color: colors.textPrimary, fontSize: cellFont),
            ),
          ),
        ),
      );
    }

    // Put OI
    cols.add(
      Expanded(
        flex: 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: putOiRatio,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: marketTheme.negative.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            Text(
              putOi > 0 ? '${(putOi / 1000).toStringAsFixed(1)}k' : '-',
              style: TextStyle(color: colors.textSecondary, fontSize: cellFont),
            ),
          ],
        ),
      ),
    );

    return cols;
  }
}
