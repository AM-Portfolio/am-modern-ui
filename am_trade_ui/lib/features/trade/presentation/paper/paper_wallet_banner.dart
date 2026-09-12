import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../internal/data/dtos/oms_dto.dart';

class PaperWalletBanner extends StatelessWidget {
  const PaperWalletBanner({required this.wallet, super.key});

  final OmsWallet wallet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ModuleColors.trade.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: ModuleColors.trade.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 18, color: ModuleColors.trade),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Paper — practice with virtual cash, not a live broker order.  '
              'Available ₹${wallet.available}  ·  Reserved ₹${wallet.reserved}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
