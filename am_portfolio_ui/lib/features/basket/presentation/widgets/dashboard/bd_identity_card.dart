import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../domain/models/basket_detail.dart';
import '../../shared/basket_panel_styles.dart';

class BdIdentityCard extends StatelessWidget {
  final BasketDetail basket;
  final int stockCount;
  final VoidCallback? onMore;

  const BdIdentityCard({
    super.key,
    required this.basket,
    required this.stockCount,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final created = basket.createdAt;
    final createdLabel = created != null ? _formatDate(created) : '—';
    final isActive = (basket.status ?? 'ACTIVE').toUpperCase() == 'ACTIVE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BasketPanelStyles.glassCard(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.actionPrimaryBg.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              color: context.colors.actionPrimaryBg,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${basket.name} • $stockCount',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              context.statusSuccess.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.statusSuccess,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${basket.etfName}${basket.etfIsin.isNotEmpty ? ' (${basket.etfIsin})' : ''} • Created $createdLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (onMore != null)
            IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: context.colors.textSecondary,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: onMore,
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
