import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/cas_providers.dart';

/// Grouped MF folio detail for CDSL CAS portfolios.
class CasFolioPanel extends ConsumerWidget {
  const CasFolioPanel({required this.portfolioId, super.key});

  final String portfolioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(casFoliosProvider(portfolioId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (folios) {
        if (folios.isEmpty) return const SizedBox.shrink();
        return ExpansionTile(
          title: Text('Mutual fund folios (${folios.length})'),
          children: [
            for (final f in folios)
              ExpansionTile(
                title: Text(f.folio),
                subtitle: Text(
                  [
                    if (f.amcName != null) f.amcName!,
                    if (f.rtaName != null) 'RTA ${f.rtaName}',
                    if (f.ucc != null && f.ucc!.isNotEmpty) 'UCC ${f.ucc}',
                  ].join(' · '),
                ),
                children: [
                  for (final h in f.holdings)
                    ListTile(
                      dense: true,
                      title: Text(
                        (h['name'] ?? h['schemeName'] ?? h['isin'] ?? '')
                            .toString(),
                      ),
                      subtitle: Text(
                        [
                          if (h['schemeCode'] != null) 'Code ${h['schemeCode']}',
                          if (h['isin'] != null) h['isin'].toString(),
                          if (h['folioNumber'] != null) 'Folio ${h['folioNumber']}',
                        ].join(' · '),
                      ),
                      trailing: Text(
                        h['currentValue'] != null
                            ? '₹${(h['currentValue'] as num).toStringAsFixed(2)}'
                            : '',
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
