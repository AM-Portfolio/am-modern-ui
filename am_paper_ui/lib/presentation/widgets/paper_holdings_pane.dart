import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';

/// Link out to the paper portfolio holdings page in a new browser tab.
class PaperHoldingsPane extends StatelessWidget {
  const PaperHoldingsPane({super.key});

  Future<void> _openHoldings(BuildContext context, String uuid) async {
    final base = EnvDomains.apiBase.isNotEmpty
        ? EnvDomains.apiBase
        : Uri.base.origin;
    final uri = Uri.parse('$base/app/portfolio/$uuid/holdings');
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $uri')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final uuid = state.wallet?.portfolioUuid.trim() ?? '';
        final hasUuid = uuid.isNotEmpty;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 40,
                    color: colors.actionPrimaryBg,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Holdings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasUuid
                        ? 'Opens your paper portfolio holdings in a new browser tab.'
                        : 'Paper portfolio link is not available yet.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed:
                        hasUuid ? () => _openHoldings(context, uuid) : null,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open holdings'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
