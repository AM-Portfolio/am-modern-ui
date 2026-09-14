import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Header Info
          Row(
            children: [
              Text(
                'Futures Contracts',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'All available futures contracts for the selected symbol sorted by expiry.',
                child: Icon(Icons.info_outline_rounded, color: colors.textSecondary, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Expiry Filter Pills using Design System AMFilterPillsBar
          AMFilterPillsBar<String>(
            options: filters,
            selectedOption: activeFilter,
            activeColor: ModuleColors.market,
            onSelected: (val) {
              ref.read(futuresExpiryFilterProvider.notifier).state = val;
            },
          ),
          const SizedBox(height: 14),

          // Responsive Full-Width Dynamic Table
          LayoutBuilder(
            builder: (context, constraints) {
              const minTableWidth = 720.0;
              final isScrollable = constraints.maxWidth < minTableWidth;
              final tableWidth = isScrollable ? minTableWidth : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: isScrollable ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('Contract', style: _headerStyle(colors))),
                            Expanded(flex: 2, child: Text('Expiry', style: _headerStyle(colors))),
                            Expanded(flex: 2, child: Text('LTP (₹)', style: _headerStyle(colors), textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text('Change', style: _headerStyle(colors), textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text('Change %', style: _headerStyle(colors), textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text('OI', style: _headerStyle(colors), textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text('Volume', style: _headerStyle(colors), textAlign: TextAlign.right)),
                            Expanded(flex: 1, child: Text('Lot', style: _headerStyle(colors), textAlign: TextAlign.right)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Rows
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
                      else
                        ...filteredContracts.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final contract = entry.value;
                          final map = contract is Map ? Map<String, dynamic>.from(contract) : <String, dynamic>{};
                          final tradingSymbol = (map['trading_symbol'] ?? map['tradingSymbol'] ?? map['name'] ?? 'FUT').toString();

                          final metrics = _deriveContractMetrics(map, idx);
                          final ltp = metrics['ltp'] as double;
                          final change = metrics['change'] as double;
                          final pChange = metrics['pChange'] as double;
                          final oi = metrics['oi'] as int;
                          final volume = metrics['volume'] as int;
                          final lotSizeStr = metrics['lot_size'].toString();

                          final rawExpiry = map['expiry'];
                          String expiryStr = '24 Sep 2026';
                          if (rawExpiry is num && rawExpiry > 0) {
                            final dt = DateTime.fromMillisecondsSinceEpoch(rawExpiry.toInt());
                            expiryStr = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
                          } else if (rawExpiry != null && rawExpiry.toString().isNotEmpty) {
                            expiryStr = rawExpiry.toString();
                          }

                          final isSelected = selectedContract != null &&
                              (selectedContract['trading_symbol'] ?? selectedContract['tradingSymbol']) == tradingSymbol;

                          final deltaColor = change >= 0 ? marketTheme.positive : marketTheme.negative;

                          // Ensure selecting row updates selectedFutureContractProvider with enriched metrics
                          final enrichedContractMap = {
                            ...map,
                            'trading_symbol': tradingSymbol,
                            'expiry': expiryStr,
                            'ltp': ltp,
                            'change': change,
                            'pChange': pChange,
                            'oi': oi,
                            'volume': volume,
                            'lot_size': metrics['lot_size'],
                          };

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => ref.read(selectedFutureContractProvider.notifier).state = enrichedContractMap,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ModuleColors.market.withValues(alpha: 0.12)
                                      : colors.surface.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? ModuleColors.market.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        tradingSymbol,
                                        style: TextStyle(
                                          color: ModuleColors.market,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        expiryStr,
                                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${ltp.toStringAsFixed(2)}',
                                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}',
                                        style: TextStyle(color: deltaColor, fontSize: 12),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${pChange >= 0 ? '+' : ''}${pChange.toStringAsFixed(2)}%',
                                        style: TextStyle(color: deltaColor, fontWeight: FontWeight.bold, fontSize: 12),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _formatNum(oi),
                                        style: TextStyle(color: colors.textPrimary, fontSize: 12),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _formatNum(volume),
                                        style: TextStyle(color: colors.textPrimary, fontSize: 12),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        lotSizeStr,
                                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                                        textAlign: TextAlign.right,
                                      ),
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
              );
            },
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic> _deriveContractMetrics(Map<String, dynamic> map, int index) {
    final symbol = (map['trading_symbol'] ?? map['tradingSymbol'] ?? map['name'] ?? '').toString().toUpperCase();

    int lotSize = 65;
    if (map['lot_size'] != null || map['lotSize'] != null) {
      lotSize = ((map['lot_size'] ?? map['lotSize']) as num).toInt();
    } else if (symbol.contains('BANKNIFTY')) {
      lotSize = 30;
    } else if (symbol.contains('FINNIFTY')) {
      lotSize = 60;
    } else if (symbol.contains('MIDCPNIFTY')) {
      lotSize = 120;
    } else if (symbol.contains('NIFTYNXT50')) {
      lotSize = 25;
    }

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
      return '${_monthName(dt.month)} ${dt.year}';
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

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  static String _formatNum(int num) {
    return num.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

extension _StringExt on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}
