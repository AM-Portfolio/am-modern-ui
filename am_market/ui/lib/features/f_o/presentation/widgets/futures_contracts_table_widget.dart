import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_contract_mobile_tile.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FuturesContractsTableWidget extends ConsumerWidget {
  const FuturesContractsTableWidget({
    required this.contracts,
    super.key,
  });

  final List<Object?> contracts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final selectedFilter = ref.watch(futuresExpiryFilterProvider);
    final selectedContract = ref.watch(selectedFutureContractProvider);

    // Filter out expired contracts (older than 30 days prior to current date)
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final validContracts = contracts.where((c) {
      if (c is Map) {
        final rawExp = c['expiry'];
        if (rawExp is num && rawExp > 0) {
          return rawExp.toInt() >= (nowMs - 86400000 * 30);
        }
      }
      return true;
    }).toList();

    // Sort active contracts chronologically by expiry date (near-month Sep 2026 first)
    validContracts.sort((a, b) {
      final mapA = a is Map ? Map<String, dynamic>.from(a) : <String, dynamic>{};
      final mapB = b is Map ? Map<String, dynamic>.from(b) : <String, dynamic>{};
      final expA = mapA['expiry'] is num ? (mapA['expiry'] as num).toInt() : 0;
      final expB = mapB['expiry'] is num ? (mapB['expiry'] as num).toInt() : 0;
      return expA.compareTo(expB);
    });

    // Dynamically extract unique expiry month-year labels from active contract data
    final dynamicExpiries = <String>{};
    for (final c in validContracts) {
      if (c is Map) {
        final label = _extractExpiryMonthYear(Map<String, dynamic>.from(c));
        if (label.isNotEmpty) dynamicExpiries.add(label);
      }
    }

    final filters = ['All', ...dynamicExpiries];
    final activeFilter = filters.contains(selectedFilter) ? selectedFilter : 'All';

    // Active filtering based on dynamic expiry filter
    final filteredContracts = validContracts.where((c) {
      if (activeFilter == 'All') return true;
      final map = c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{};
      final expLabel = _extractExpiryMonthYear(map);
      return expLabel.equalsIgnoreCase(activeFilter) ||
          (map['trading_symbol'] ?? map['tradingSymbol'] ?? '')
              .toString()
              .toUpperCase()
              .contains(activeFilter.split(' ').first.toUpperCase());
    }).toList();

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final isMobile = outerConstraints.maxWidth < AmBreakpoints.mobile;
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.5),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Futures Contracts',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 15 : 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message:
                        'All available futures contracts for the selected symbol sorted by expiry.',
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: colors.textSecondary,
                      size: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 12),
              AMFilterPillsBar<String>(
                options: filters,
                selectedOption: activeFilter,
                activeColor: ModuleColors.market,
                onSelected: (val) {
                  ref.read(futuresExpiryFilterProvider.notifier).state = val;
                },
              ),
              SizedBox(height: isMobile ? 10 : 14),
              if (filteredContracts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No futures contracts found for $activeFilter',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else if (isMobile)
                ...filteredContracts.asMap().entries.map((entry) {
                  final built = _buildContractRowData(
                    entry.value,
                    entry.key,
                    selectedContract,
                  );
                  return FuturesContractMobileTile(
                    tradingSymbol: built.tradingSymbol,
                    expiryLabel: built.expiryStr,
                    ltp: built.ltp,
                    change: built.change,
                    pChange: built.pChange,
                    oi: built.oi,
                    volume: built.volume,
                    isSelected: built.isSelected,
                    formatNum: _formatNum,
                    onTap: () => ref
                        .read(selectedFutureContractProvider.notifier)
                        .state = built.enriched,
                  );
                })
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 720;
                    final minTableWidth = isCompact ? 640.0 : 720.0;
                    final isScrollable = constraints.maxWidth < minTableWidth;
                    final tableWidth =
                        isScrollable ? minTableWidth : constraints.maxWidth;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: isScrollable
                              ? const ClampingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          child: SizedBox(
                            width: tableWidth,
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 8 : 12,
                                    vertical: isCompact ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Contract',
                                          style: _headerStyle(colors),
                                        ),
                                      ),
                                      if (!isCompact)
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Expiry',
                                            style: _headerStyle(colors),
                                          ),
                                        ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'LTP (₹)',
                                          style: _headerStyle(colors),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Change',
                                          style: _headerStyle(colors),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Change %',
                                          style: _headerStyle(colors),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          isCompact ? 'Volume' : 'OI',
                                          style: _headerStyle(colors),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          isCompact ? 'OI' : 'Volume',
                                          style: _headerStyle(colors),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      if (!isCompact)
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'Lot',
                                            style: _headerStyle(colors),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      if (isCompact) const SizedBox(width: 20),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...filteredContracts.asMap().entries.map((entry) {
                                  final built = _buildContractRowData(
                                    entry.value,
                                    entry.key,
                                    selectedContract,
                                  );
                                  final deltaColor = built.change >= 0
                                      ? marketTheme.positive
                                      : marketTheme.negative;
                                  final lotSizeStr =
                                      built.enriched['lot_size'].toString();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => ref
                                          .read(
                                            selectedFutureContractProvider
                                                .notifier,
                                          )
                                          .state = built.enriched,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isCompact ? 8 : 12,
                                          vertical: isCompact ? 8 : 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: built.isSelected
                                              ? ModuleColors.market
                                                  .withValues(alpha: 0.12)
                                              : colors.surface
                                                  .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: built.isSelected
                                                ? ModuleColors.market
                                                    .withValues(alpha: 0.4)
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                isCompact
                                                    ? '${built.tradingSymbol}${built.expiryStr.isNotEmpty ? ' ${built.expiryStr}' : ''}'
                                                    : built.tradingSymbol,
                                                style: TextStyle(
                                                  color: ModuleColors.market,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      isCompact ? 12 : 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!isCompact)
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  built.expiryStr,
                                                  style: TextStyle(
                                                    color:
                                                        colors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '₹${built.ltp.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      isCompact ? 12 : 13,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${built.change >= 0 ? '+' : ''}${built.change.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: deltaColor,
                                                  fontSize:
                                                      isCompact ? 11 : 12,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${built.pChange >= 0 ? '+' : ''}${built.pChange.toStringAsFixed(2)}%',
                                                style: TextStyle(
                                                  color: deltaColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      isCompact ? 11 : 12,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                _formatNum(
                                                  isCompact
                                                      ? built.volume
                                                      : built.oi,
                                                ),
                                                style: TextStyle(
                                                  color: colors.textPrimary,
                                                  fontSize:
                                                      isCompact ? 11 : 12,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                _formatNum(
                                                  isCompact
                                                      ? built.oi
                                                      : built.volume,
                                                ),
                                                style: TextStyle(
                                                  color: colors.textPrimary,
                                                  fontSize:
                                                      isCompact ? 11 : 12,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            if (!isCompact)
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  lotSizeStr,
                                                  style: TextStyle(
                                                    color:
                                                        colors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                            if (isCompact)
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 18,
                                                color: colors.textSecondary,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        if (isScrollable)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Swipe left or right for more columns',
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
            ],
          ),
        );
      },
    );
  }

  static _FuturesRowData _buildContractRowData(
    Object? contract,
    int index,
    Map<String, dynamic>? selectedContract,
  ) {
    final map = contract is Map
        ? Map<String, dynamic>.from(contract)
        : <String, dynamic>{};
    final tradingSymbol = (map['trading_symbol'] ??
            map['tradingSymbol'] ??
            map['name'] ??
            'FUT')
        .toString();

    final metrics = _deriveContractMetrics(map, index);
    final ltp = metrics['ltp'] as double;
    final change = metrics['change'] as double;
    final pChange = metrics['pChange'] as double;
    final oi = metrics['oi'] as int;
    final volume = metrics['volume'] as int;

    final rawExpiry = map['expiry'];
    final expiryMs = rawExpiry is num && rawExpiry > 0
        ? rawExpiry.toInt()
        : (map['expiry_ms'] is num ? (map['expiry_ms'] as num).toInt() : null);
    var expiryStr = '24 Sep 2026';
    if (expiryMs != null) {
      expiryStr = DateFormat('d MMM yyyy').format(
        DateTime.fromMillisecondsSinceEpoch(expiryMs),
      );
    } else if (rawExpiry != null &&
        rawExpiry.toString().isNotEmpty &&
        rawExpiry is! num) {
      expiryStr = rawExpiry.toString();
    }

    final isSelected = selectedContract != null &&
        (selectedContract['trading_symbol'] ??
                selectedContract['tradingSymbol']) ==
            tradingSymbol;

    final enriched = {
      ...map,
      'trading_symbol': tradingSymbol,
      if (expiryMs != null) 'expiry_ms': expiryMs,
      'expiry': expiryMs ?? expiryStr,
      'expiry_display': expiryStr,
      'ltp': ltp,
      'change': change,
      'pChange': pChange,
      'oi': oi,
      'volume': volume,
      'lot_size': metrics['lot_size'],
    };

    return _FuturesRowData(
      tradingSymbol: tradingSymbol,
      expiryStr: expiryStr,
      ltp: ltp,
      change: change,
      pChange: pChange,
      oi: oi,
      volume: volume,
      isSelected: isSelected,
      enriched: enriched,
    );
  }

  static Map<String, dynamic> _deriveContractMetrics(Map<String, dynamic> map, int index) {
    final rawLotSize = map['lot_size'] ?? map['lotSize'] ?? map['minimum_lot_size'] ?? map['lot_multiplier'];
    final lotSize = (rawLotSize is num && rawLotSize > 0) ? rawLotSize.toInt() : 1;

    final rawLtp = map['ltp'];
    final ltp = (rawLtp is num) ? rawLtp.toDouble() : 0.0;

    final rawChange = map['change'];
    final change = (rawChange is num) ? rawChange.toDouble() : 0.0;

    final rawPChange = map['pChange'];
    final pChange = (rawPChange is num) ? rawPChange.toDouble() : 0.0;

    final rawOi = map['oi'];
    final oi = (rawOi is num) ? rawOi.toInt() : 0;

    final rawVol = map['volume'];
    final volume = (rawVol is num) ? rawVol.toInt() : 0;

    return {
      'ltp': ltp,
      'change': change,
      'pChange': pChange,
      'oi': oi,
      'volume': volume,
      'lot_size': lotSize,
    };
  }

  TextStyle _headerStyle(AppColorsTheme colors) {
    return TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12);
  }

  static String _extractExpiryMonthYear(Map<String, dynamic> map) {
    final rawExpiry = map['expiry'];
    if (rawExpiry is num && rawExpiry > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(rawExpiry.toInt());
      return DateFormat('MMM yyyy').format(dt);
    } else if (rawExpiry != null && rawExpiry.toString().isNotEmpty) {
      final str = rawExpiry.toString();
      final parts = str.split(' ');
      if (parts.length >= 3) {
        return '${parts[1]} ${parts[2]}';
      }
      return str;
    }
    final symbol = (map['trading_symbol'] ?? map['tradingSymbol'] ?? '').toString();
    final match = RegExp(r'(\d{1,2})\s+([A-Z]{3})\s+(\d{2})').firstMatch(symbol);
    if (match != null) {
      final mStr = match.group(2)!;
      final yStr = '20${match.group(3)!}';
      return '${mStr[0]}${mStr.substring(1).toLowerCase()} $yStr';
    }
    return '';
  }

  static String _formatNum(int num) {
    return num.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

class _FuturesRowData {
  const _FuturesRowData({
    required this.tradingSymbol,
    required this.expiryStr,
    required this.ltp,
    required this.change,
    required this.pChange,
    required this.oi,
    required this.volume,
    required this.isSelected,
    required this.enriched,
  });

  final String tradingSymbol;
  final String expiryStr;
  final double ltp;
  final double change;
  final double pChange;
  final int oi;
  final int volume;
  final bool isSelected;
  final Map<String, dynamic> enriched;
}

extension _StringExt on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}
