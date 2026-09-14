import 'dart:math' as math;
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OptionChainColumnGroup {
  bidAsk('Bid / Ask'),
  valuation('Valuation & Breakeven'),
  greeks('Option Greeks');

  final String label;
  const OptionChainColumnGroup(this.label);
}

class OptionChainView extends ConsumerStatefulWidget {
  const OptionChainView({super.key});

  @override
  ConsumerState<OptionChainView> createState() => _OptionChainViewState();
}

class _OptionChainViewState extends ConsumerState<OptionChainView> {
  late final ScrollController _scrollController;
  final List<OptionChainColumnGroup> _activeGroups = [];
  String? _lastAutoScrolledKey;
  final GlobalKey _spotLineKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final chainAsync = ref.watch(optionChainProvider);

    return chainAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: ModuleColors.market),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: marketTheme.negative, size: 36),
            const SizedBox(height: 12),
            Text(
              'Failed to load Option Chain',
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(err.toString(), style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
      data: (data) {
        if (data == null || data.isEmpty) {
          return Center(
            child: Text('No Option Chain data available', style: TextStyle(color: colors.textSecondary)),
          );
        }

        final underlyingLtp = (data['underlyingLtp'] as num?)?.toDouble() ?? 0.0;
        final rawStrikes = (data['strikes'] as List<dynamic>?) ?? [];
        final expiriesList = (data['expiries'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final currentExpiry = (data['expiry'] as String?) ?? '';
        final activeExpiry = ref.watch(foSelectedExpiryProvider) ?? currentExpiry;

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

        // Determine spot price insertion index for Groww-style divider line
        int spotIndex = -1;
        for (int i = 0; i < rawStrikes.length - 1; i++) {
          final s1 = (rawStrikes[i] as Map<String, dynamic>)['strikePrice'] as num? ?? 0.0;
          final s2 = (rawStrikes[i + 1] as Map<String, dynamic>)['strikePrice'] as num? ?? 0.0;
          if (underlyingLtp >= s1 && underlyingLtp < s2) {
            spotIndex = i;
            break;
          }
        }

        final activeSymbol = ref.watch(foActiveSymbolProvider) ?? '';
        final currentKey = '${activeSymbol}_${activeExpiry}_${rawStrikes.length}';

        // Auto-scroll to center on the Spot Price indicator upon load or key change
        if (_lastAutoScrolledKey != currentKey && spotIndex != -1) {
          _lastAutoScrolledKey = currentKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollController.hasClients) return;
            // Step 1: Instant mathematical jump to bring spotIndex into viewport
            const double itemHeight = 39.0;
            final double spotY = (spotIndex * itemHeight) + 52.0;
            final double viewport = _scrollController.position.viewportDimension;
            if (viewport > 0) {
              final double targetOffset = math.max(0.0, spotY - (viewport / 2));
              final double maxScroll = _scrollController.position.maxScrollExtent;
              _scrollController.jumpTo(math.min(targetOffset, maxScroll));
            }

            // Step 2: Fine-tune exact 50% viewport alignment via ensureVisible
            Future.delayed(const Duration(milliseconds: 30), () {
              if (!mounted) return;
              final renderObj = _spotLineKey.currentContext?.findRenderObject();
              if (renderObj != null && _scrollController.hasClients) {
                _scrollController.position.ensureVisible(
                  renderObj,
                  alignment: 0.5, // 0.5 = Exact mathematical center of viewport
                  duration: Duration.zero,
                );
              }
            });
          });
        }

        return Column(
          children: [
            // Top Controls: Expiry Selector Dropdown + Multi-Column Toggles
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
              child: Row(
                children: [
                  // Expiry Selector Badge / Dropdown (Sensibull Style with DTE)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ModuleColors.market.withValues(alpha: 0.5)),
                    ),
                    child: expiriesList.isNotEmpty
                        ? DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: expiriesList.contains(activeExpiry)
                                  ? activeExpiry
                                  : (expiriesList.isNotEmpty ? expiriesList.first : activeExpiry),
                              icon: Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: Icon(Icons.calendar_today, size: 13, color: ModuleColors.market),
                              ),
                              isDense: true,
                              dropdownColor: colors.surface,
                              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                              onChanged: (newExpiry) {
                                if (newExpiry != null) {
                                  ref.read(foSelectedExpiryProvider.notifier).state = newExpiry;
                                }
                              },
                              items: expiriesList.map((exp) {
                                return DropdownMenuItem<String>(
                                  value: exp,
                                  child: Text(_formatExpiryWithDte(exp), style: TextStyle(color: colors.textPrimary, fontSize: 12)),
                                );
                              }).toList(),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 13, color: ModuleColors.market),
                              const SizedBox(width: 6),
                              Text(
                                _formatExpiryWithDte(activeExpiry),
                                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 12),
                  // CALLS Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: marketTheme.positive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('CALLS', style: TextStyle(color: marketTheme.positive, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(width: 12),
                  // Toggleable Column Chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: OptionChainColumnGroup.values.map((group) {
                          final isSelected = _activeGroups.contains(group);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: FilterChip(
                              label: Text(group.label),
                              selected: isSelected,
                              onSelected: (_) => _toggleGroup(group),
                              selectedColor: ModuleColors.market.withValues(alpha: 0.2),
                              checkmarkColor: ModuleColors.market,
                              labelStyle: TextStyle(
                                color: isSelected ? ModuleColors.market : colors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 11,
                              ),
                              side: BorderSide(
                                color: isSelected ? ModuleColors.market : colors.border.withValues(alpha: 0.3),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // PUTS Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: marketTheme.negative.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('PUTS', style: TextStyle(color: marketTheme.negative, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Option Chain Table Header & Matrix Rows
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Dynamically compute width based on active column count
                  final columnCount = 5 + (_activeGroups.contains(OptionChainColumnGroup.bidAsk) ? 4 : 0)
                                        + (_activeGroups.contains(OptionChainColumnGroup.valuation) ? 6 : 0)
                                        + (_activeGroups.contains(OptionChainColumnGroup.greeks) ? 4 : 0);
                  final minWidth = math.max(850.0, columnCount * 80.0);
                  final contentWidth = math.max(minWidth, constraints.maxWidth);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: contentWidth,
                      height: constraints.maxHeight,
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            child: Row(
                              children: _buildHeaderColumns(context, marketTheme, colors),
                            ),
                          ),
                          const Divider(height: 1),
                          // Matrix Rows & Groww-style Spot Line Divider
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: rawStrikes.length,
                              itemBuilder: (context, index) {
                                final strikeMap = rawStrikes[index] as Map<String, dynamic>;
                                final strikePrice = (strikeMap['strikePrice'] as num?)?.toDouble() ?? 0.0;
                                final callMap = (strikeMap['call'] as Map<String, dynamic>?) ?? {};
                                final putMap = (strikeMap['put'] as Map<String, dynamic>?) ?? {};

                                return Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Row(
                                        children: _buildRowColumns(
                                          context,
                                          strikePrice,
                                          underlyingLtp,
                                          callMap,
                                          putMap,
                                          maxOi,
                                          colors,
                                          marketTheme,
                                        ),
                                      ),
                                    ),
                                    // Groww-Style Spot Price Capsule Line Divider
                                    if (index == spotIndex)
                                      _buildSpotPriceLine(context, underlyingLtp, colors, marketTheme, key: _spotLineKey)
                                    else
                                      const Divider(height: 1, indent: 16, endIndent: 16),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
          Expanded(child: Container(height: 1.5, color: ModuleColors.market.withValues(alpha: 0.6))),
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
          Expanded(child: Container(height: 1.5, color: ModuleColors.market.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  List<Widget> _buildHeaderColumns(BuildContext context, MarketThemeExtension marketTheme, AppColorsTheme colors) {
    TextStyle callStyle = TextStyle(color: marketTheme.positive, fontWeight: FontWeight.bold, fontSize: 11);
    TextStyle putStyle = TextStyle(color: marketTheme.negative, fontWeight: FontWeight.bold, fontSize: 11);
    TextStyle strikeStyle = TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12);

    final cols = <Widget>[];

    // --- CALLS SIDE ---
    // Core Call OI
    cols.add(Expanded(flex: 2, child: Center(child: Text('CALL OI', style: callStyle))));

    // Optional Call Greeks
    if (_activeGroups.contains(OptionChainColumnGroup.greeks)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text('DELTA', style: callStyle))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('THETA', style: callStyle))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('IV', style: callStyle))));
    }

    // Optional Call Valuation
    if (_activeGroups.contains(OptionChainColumnGroup.valuation)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text('INT VAL', style: callStyle))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('TIME VAL', style: callStyle))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('BREAKEVEN %', style: callStyle))));
    }

    // Optional Call Depth
    if (_activeGroups.contains(OptionChainColumnGroup.bidAsk)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text('BID', style: callStyle))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('ASK', style: callStyle))));
    }

    // Core Call LTP
    cols.add(Expanded(flex: 3, child: Center(child: Text('LTP (CHG %)', style: callStyle))));

    // --- CENTER STRIKE ---
    cols.add(Expanded(flex: 2, child: Center(child: Text('STRIKE', style: strikeStyle))));

    // --- PUTS SIDE ---
    // Core Put LTP
    cols.add(Expanded(flex: 3, child: Center(child: Text('LTP (CHG %)', style: putStyle))));

    // Optional Put Depth
    if (_activeGroups.contains(OptionChainColumnGroup.bidAsk)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text('ASK', style: putStyle))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('BID', style: putStyle))));
    }

    // Optional Put Valuation
    if (_activeGroups.contains(OptionChainColumnGroup.valuation)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text('BREAKEVEN %', style: putStyle))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('TIME VAL', style: putStyle))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('INT VAL', style: putStyle))));
    }

    // Optional Put Greeks
    if (_activeGroups.contains(OptionChainColumnGroup.greeks)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text('IV', style: putStyle))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('THETA', style: putStyle))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('DELTA', style: putStyle))));
    }

    // Core Put OI
    cols.add(Expanded(flex: 2, child: Center(child: Text('PUT OI', style: putStyle))));

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
    MarketThemeExtension marketTheme,
  ) {
    // Call metrics
    final callLtp = (callMap['ltp'] as num?)?.toDouble() ?? 0.0;
    final callClose = (callMap['closePrice'] as num?)?.toDouble() ?? 0.0;
    final callChgPct = callClose > 0 ? ((callLtp - callClose) / callClose) * 100 : 0.0;
    final callOi = (callMap['oi'] as num?)?.toDouble() ?? 0.0;
    final callIv = ((callMap['greeks'] as Map<String, dynamic>?)?['iv'] as num?)?.toDouble() ?? 0.0;
    final callBid = (callMap['bidPrice'] as num?)?.toDouble() ?? 0.0;
    final callAsk = (callMap['askPrice'] as num?)?.toDouble() ?? 0.0;
    final callDelta = ((callMap['greeks'] as Map<String, dynamic>?)?['delta'] as num?)?.toDouble() ?? 0.0;
    final callTheta = ((callMap['greeks'] as Map<String, dynamic>?)?['theta'] as num?)?.toDouble() ?? 0.0;

    final callIntVal = math.max(0.0, underlyingLtp - strikePrice);
    final callTimeVal = math.max(0.0, callLtp - callIntVal);
    final callBreakeven = strikePrice + callLtp;
    final callBreakevenPct = underlyingLtp > 0 ? ((callBreakeven - underlyingLtp) / underlyingLtp) * 100 : 0.0;

    // Put metrics
    final putLtp = (putMap['ltp'] as num?)?.toDouble() ?? 0.0;
    final putClose = (putMap['closePrice'] as num?)?.toDouble() ?? 0.0;
    final putChgPct = putClose > 0 ? ((putLtp - putClose) / putClose) * 100 : 0.0;
    final putOi = (putMap['oi'] as num?)?.toDouble() ?? 0.0;
    final putIv = ((putMap['greeks'] as Map<String, dynamic>?)?['iv'] as num?)?.toDouble() ?? 0.0;
    final putBid = (putMap['bidPrice'] as num?)?.toDouble() ?? 0.0;
    final putAsk = (putMap['askPrice'] as num?)?.toDouble() ?? 0.0;
    final putDelta = ((putMap['greeks'] as Map<String, dynamic>?)?['delta'] as num?)?.toDouble() ?? 0.0;
    final putTheta = ((putMap['greeks'] as Map<String, dynamic>?)?['theta'] as num?)?.toDouble() ?? 0.0;

    final putIntVal = math.max(0.0, strikePrice - underlyingLtp);
    final putTimeVal = math.max(0.0, putLtp - putIntVal);
    final putBreakeven = strikePrice - putLtp;
    final putBreakevenPct = underlyingLtp > 0 ? ((underlyingLtp - putBreakeven) / underlyingLtp) * 100 : 0.0;

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
            Text(callOi > 0 ? '${(callOi / 1000).toStringAsFixed(1)}k' : '-', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );

    // Call Greeks
    if (_activeGroups.contains(OptionChainColumnGroup.greeks)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text(callDelta != 0 ? callDelta.toStringAsFixed(2) : '-', style: TextStyle(color: colors.textPrimary, fontSize: 12)))));
      cols.add(Expanded(flex: 2, child: Center(child: Text(callTheta != 0 ? callTheta.toStringAsFixed(2) : '-', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
      cols.add(Expanded(flex: 2, child: Center(child: Text(callIv > 0 ? '${callIv.toStringAsFixed(1)}%' : '-', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
    }

    // Call Valuation
    if (_activeGroups.contains(OptionChainColumnGroup.valuation)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text('₹${callIntVal.toStringAsFixed(1)}', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('₹${callTimeVal.toStringAsFixed(1)}', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('${callBreakevenPct.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 12)))));
    }

    // Call Depth
    if (_activeGroups.contains(OptionChainColumnGroup.bidAsk)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text(callBid > 0 ? '₹${callBid.toStringAsFixed(2)}' : '-', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
      cols.add(Expanded(flex: 2, child: Center(child: Text(callAsk > 0 ? '₹${callAsk.toStringAsFixed(2)}' : '-', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
    }

    // Call LTP & Chg %
    cols.add(
      Expanded(
        flex: 3,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('₹${callLtp.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
              if (callChgPct != 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${callChgPct > 0 ? '+' : ''}${callChgPct.toStringAsFixed(1)}%',
                  style: TextStyle(color: callChgPct >= 0 ? marketTheme.positive : marketTheme.negative, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // --- CENTER STRIKE ---
    cols.add(
      Expanded(
        flex: 2,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.border.withValues(alpha: 0.3)),
            ),
            child: Text(
              strikePrice.toStringAsFixed(0),
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
    );

    // --- PUTS SIDE ---
    // Put LTP & Chg %
    cols.add(
      Expanded(
        flex: 3,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('₹${putLtp.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
              if (putChgPct != 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${putChgPct > 0 ? '+' : ''}${putChgPct.toStringAsFixed(1)}%',
                  style: TextStyle(color: putChgPct >= 0 ? marketTheme.positive : marketTheme.negative, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Put Depth
    if (_activeGroups.contains(OptionChainColumnGroup.bidAsk)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text(putAsk > 0 ? '₹${putAsk.toStringAsFixed(2)}' : '-', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
      cols.add(Expanded(flex: 2, child: Center(child: Text(putBid > 0 ? '₹${putBid.toStringAsFixed(2)}' : '-', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
    }

    // Put Valuation
    if (_activeGroups.contains(OptionChainColumnGroup.valuation)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text('${putBreakevenPct.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 12)))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('₹${putTimeVal.toStringAsFixed(1)}', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
      cols.add(Expanded(flex: 2, child: Center(child: Text('₹${putIntVal.toStringAsFixed(1)}', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
    }

    // Put Greeks
    if (_activeGroups.contains(OptionChainColumnGroup.greeks)) {
      cols.add(Expanded(flex: 2, child: Center(child: Text(putIv > 0 ? '${putIv.toStringAsFixed(1)}%' : '-', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
      cols.add(Expanded(flex: 2, child: Center(child: Text(putTheta != 0 ? putTheta.toStringAsFixed(2) : '-', style: TextStyle(color: colors.textSecondary, fontSize: 12)))));
      cols.add(Expanded(flex: 2, child: Center(child: Text(putDelta != 0 ? putDelta.toStringAsFixed(2) : '-', style: TextStyle(color: colors.textPrimary, fontSize: 12)))));
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
            Text(putOi > 0 ? '${(putOi / 1000).toStringAsFixed(1)}k' : '-', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );

    return cols;
  }

  String _formatExpiryLabel(String rawDate) {
    if (rawDate.isEmpty) return 'Expiry';
    try {
      final parts = rawDate.split('-');
      if (parts.length == 3) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final mIdx = int.tryParse(parts[1]);
        if (mIdx != null && mIdx >= 1 && mIdx <= 12) {
          return '${parts[2]} ${months[mIdx - 1]} ${parts[0]}';
        }
      }
    } catch (_) {}
    return rawDate;
  }

  String _formatExpiryWithDte(String rawDate) {
    final label = _formatExpiryLabel(rawDate);
    if (rawDate.isEmpty) return label;
    try {
      final parsed = DateTime.parse(rawDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expDate = DateTime(parsed.year, parsed.month, parsed.day);
      final diff = expDate.difference(today).inDays;
      if (diff >= 0) {
        return '$label ($diff Days)';
      }
    } catch (_) {}
    return label;
  }
}
