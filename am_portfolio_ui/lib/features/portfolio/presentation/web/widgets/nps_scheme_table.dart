import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/nps_providers.dart';

/// Scheme-wise NPS holdings: statement NAV vs live NAV.
class NpsSchemeTable extends ConsumerWidget {
  const NpsSchemeTable({required this.portfolioId, super.key});

  final String portfolioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(npsSchemesProvider(portfolioId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (schemes) {
        if (schemes.isEmpty) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('NPS schemes', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 56,
                  columns: const [
                    DataColumn(label: Text('Scheme')),
                    DataColumn(label: Text('Tier')),
                    DataColumn(label: Text('ISIN')),
                    DataColumn(label: Text('Units'), numeric: true),
                    DataColumn(label: Text('Stmt NAV'), numeric: true),
                    DataColumn(label: Text('Live NAV'), numeric: true),
                    DataColumn(label: Text('Live value'), numeric: true),
                    DataColumn(label: Text('vs stmt'), numeric: true),
                  ],
                  rows: [
                    for (final s in schemes)
                      DataRow(
                        cells: [
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                s.name ??
                                    '${s.schemeClass ?? '?'} · ${s.schemeOption ?? ''}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          DataCell(Text(s.tier ?? '—')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(s.isin ?? s.schemeCode ?? '—'),
                                if (s.isUnmapped) ...[
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message: 'ISIN not mapped',
                                    child: Icon(
                                      Icons.link_off,
                                      size: 14,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          DataCell(Text(_fmt(s.units, digits: 3))),
                          DataCell(Text(_fmt(s.statementNav))),
                          DataCell(Text(
                            s.liveNav != null ? _fmt(s.liveNav) : '—',
                          )),
                          DataCell(Text(
                            s.liveValue != null
                                ? _fmt(s.liveValue, digits: 0)
                                : '—',
                          )),
                          DataCell(Text(
                            s.gainVsStatement != null
                                ? _fmt(s.gainVsStatement, digits: 0)
                                : '—',
                          )),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _fmt(double? v, {int digits = 2}) {
    if (v == null) return '—';
    return v.toStringAsFixed(digits);
  }
}
