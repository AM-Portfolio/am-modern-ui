import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/nps_providers.dart';

/// Compact banner for latest NPS import (PRAN + as-of + tier totals).
class NpsStatusBanner extends ConsumerWidget {
  const NpsStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(npsLatestProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (meta) {
        if (meta == null || (meta.pran == null && meta.asOfDate == null)) {
          return const SizedBox.shrink();
        }
        final ok = meta.validationAllOk != false;
        final theme = Theme.of(context);
        final parts = <String>[
          if (meta.pran != null) 'PRAN ${meta.pran}',
          if (meta.asOfDate != null) 'as of ${meta.asOfDate}',
          if (meta.tier1Value != null)
            'T-I ₹${meta.tier1Value!.toStringAsFixed(0)}',
          if (meta.tier2Value != null)
            'T-II ₹${meta.tier2Value!.toStringAsFixed(0)}',
          if (meta.totalValue != null)
            'total ₹${meta.totalValue!.toStringAsFixed(0)}',
        ];
        return Material(
          color: ok
              ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.35)
              : theme.colorScheme.errorContainer.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  ok ? Icons.account_balance_outlined : Icons.warning_amber_rounded,
                  size: 18,
                  color: ok
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ok
                        ? 'NPS · ${parts.join(' · ')}'
                        : 'NPS · ${parts.join(' · ')} — validation issues',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
