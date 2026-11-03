import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/cas_providers.dart';

/// Compact banner for latest CDSL CAS import (as-of + validation).
class CasStatusBanner extends ConsumerWidget {
  const CasStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(casLatestProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (meta) {
        if (meta == null || meta.asOfDate == null) {
          return const SizedBox.shrink();
        }
        final ok = meta.validationAllOk == true;
        final theme = Theme.of(context);
        return Material(
          color: ok
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
              : theme.colorScheme.errorContainer.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  ok ? Icons.verified_outlined : Icons.warning_amber_rounded,
                  size: 18,
                  color: ok
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ok
                        ? 'CAS import as of ${meta.asOfDate}'
                            '${meta.totalValue != null ? ' · ₹${meta.totalValue!.toStringAsFixed(0)}' : ''}'
                        : 'CAS import as of ${meta.asOfDate} — validation issues',
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
