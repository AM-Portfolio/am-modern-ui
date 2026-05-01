import 'package:flutter/material.dart';

import 'package:am_common/am_common.dart';
import '../../../internal/domain/enums/broker_types.dart';
import '../../../internal/domain/enums/derivative_types.dart';
import '../../../internal/domain/enums/exchange_types.dart';
import '../../../internal/domain/enums/fundamental_reasons.dart';
import '../../../internal/domain/enums/market_segments.dart';
import '../../../internal/domain/enums/option_types.dart';
import '../../../internal/domain/enums/order_types.dart';
import '../../../internal/domain/enums/psychology_factors.dart';
import '../../../internal/domain/enums/technical_reasons.dart';
import '../../../internal/domain/enums/trade_directions.dart';
import '../../../internal/domain/enums/trade_statuses.dart';

/// Review Step - Display all collected trade data
class ReviewStep extends StatelessWidget {
  const ReviewStep({
    required this.symbol,
    required this.selectedExchange,
    required this.selectedSegment,
    required this.selectedDirection,
    required this.selectedStatus,
    required this.entryDate,
    required this.entryPrice,
    required this.entryQuantity,
    required this.exitDate,
    required this.exitPrice,
    required this.exitQuantity,
    required this.selectedBroker,
    required this.selectedOrderType,
    required this.strategy,
    required this.selectedDerivativeType,
    required this.strikePrice,
    required this.selectedOptionType,
    required this.expiryDate,
    required this.selectedEntryPsychology,
    required this.selectedExitPsychology,
    required this.selectedTechnicalReasons,
    required this.selectedFundamentalReasons,
    required this.attachments,
    required this.notes,
    super.key,
  });

  final String symbol;
  final ExchangeTypes? selectedExchange;
  final MarketSegments? selectedSegment;
  final TradeDirections selectedDirection;
  final TradeStatuses selectedStatus;
  final DateTime? entryDate;
  final String entryPrice;
  final String entryQuantity;
  final DateTime? exitDate;
  final String exitPrice;
  final String exitQuantity;
  final BrokerTypes? selectedBroker;
  final OrderTypes? selectedOrderType;
  final String strategy;
  final DerivativeTypes? selectedDerivativeType;
  final String strikePrice;
  final OptionTypes? selectedOptionType;
  final DateTime? expiryDate;
  final List<EntryPsychologyFactors> selectedEntryPsychology;
  final List<ExitPsychologyFactors> selectedExitPsychology;
  final List<TechnicalReasons> selectedTechnicalReasons;
  final List<FundamentalReasons> selectedFundamentalReasons;
  final List<String> attachments;
  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primaryContainer, theme.colorScheme.primaryContainer.withOpacity(0.5)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Your Trade',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Verify details before submitting',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Combined Instrument & Trade Details
          _buildCompactReviewCard(theme, 'Trade Summary', Icons.summarize, [
            _buildReviewRow(theme, 'Symbol', symbol.toUpperCase(), Icons.abc),
            if (selectedExchange != null)
              _buildReviewRow(
                theme,
                'Exchange',
                selectedExchange.toString().split('.').last.toUpperCase(),
                Icons.business,
              ),
            if (selectedSegment != null)
              _buildReviewRow(
                theme,
                'Segment',
                selectedSegment.toString().split('.').last.toUpperCase(),
                Icons.category,
              ),
            _buildReviewRow(
              theme,
              'Direction',
              selectedDirection.toString().split('.').last.toUpperCase(),
              selectedDirection == TradeDirections.long ? Icons.trending_up : Icons.trending_down,
              color: selectedDirection == TradeDirections.long ? Colors.green : Colors.red,
            ),
            _buildReviewRow(
              theme,
              'Status',
              selectedStatus.toString().split('.').last.toUpperCase(),
              Icons.flag,
              color: selectedStatus == TradeStatuses.open ? Colors.orange : Colors.green,
            ),
          ]),

          const SizedBox(height: 12),

          // Entry & Exit Combined
          _buildCompactReviewCard(theme, 'Transaction Details', Icons.receipt_long, [
            // Entry
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Entry', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (entryDate != null)
                        _buildCompactRow(theme, 'Date', entryDate!.toLocal().toString().split(' ')[0]),
                      _buildCompactRow(theme, 'Price', '₹$entryPrice'),
                      _buildCompactRow(theme, 'Qty', entryQuantity),
                    ],
                  ),
                ),
                if (selectedStatus != TradeStatuses.open && exitDate != null) ...[
                  Container(width: 1, height: 60, color: theme.colorScheme.outline.withOpacity(0.3)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exit', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (exitDate != null)
                          _buildCompactRow(theme, 'Date', exitDate!.toLocal().toString().split(' ')[0]),
                        if (exitPrice.isNotEmpty) _buildCompactRow(theme, 'Price', '₹$exitPrice'),
                        if (exitQuantity.isNotEmpty) _buildCompactRow(theme, 'Qty', exitQuantity),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            if (selectedBroker != null)
              _buildReviewRow(
                theme,
                'Broker',
                selectedBroker.toString().split('.').last.toUpperCase(),
                Icons.account_balance,
              ),
            if (selectedOrderType != null)
              _buildReviewRow(
                theme,
                'Order Type',
                selectedOrderType.toString().split('.').last.toUpperCase(),
                Icons.receipt,
              ),
            if (strategy.isNotEmpty) _buildReviewRow(theme, 'Strategy', strategy, Icons.psychology),
          ]),

          // Derivative Info (if any)
          if (selectedDerivativeType != null) ...[
            const SizedBox(height: 12),
            _buildCompactReviewCard(theme, 'Derivative', Icons.analytics, [
              _buildReviewRow(
                theme,
                'Type',
                selectedDerivativeType.toString().split('.').last.toUpperCase(),
                Icons.category,
              ),
              if (strikePrice.isNotEmpty) _buildReviewRow(theme, 'Strike', strikePrice, Icons.gavel),
              if (selectedOptionType != null)
                _buildReviewRow(
                  theme,
                  'Option',
                  selectedOptionType.toString().split('.').last.toUpperCase(),
                  Icons.compare_arrows,
                ),
              if (expiryDate != null)
                _buildReviewRow(theme, 'Expiry', expiryDate!.toLocal().toString().split(' ')[0], Icons.calendar_today),
            ]),
          ],

          // Psychology & Reasoning (if any)
          if (selectedEntryPsychology.isNotEmpty ||
              selectedExitPsychology.isNotEmpty ||
              selectedTechnicalReasons.isNotEmpty ||
              selectedFundamentalReasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCompactReviewCard(theme, 'Analysis', Icons.psychology, [
              if (selectedEntryPsychology.isNotEmpty)
                _buildChipRow(
                  theme,
                  'Entry Psychology',
                  selectedEntryPsychology.map((e) => e.toString().split('.').last).toList(),
                ),
              if (selectedExitPsychology.isNotEmpty)
                _buildChipRow(
                  theme,
                  'Exit Psychology',
                  selectedExitPsychology.map((e) => e.toString().split('.').last).toList(),
                ),
              if (selectedTechnicalReasons.isNotEmpty)
                _buildChipRow(
                  theme,
                  'Technical',
                  selectedTechnicalReasons.map((e) => e.toString().split('.').last).toList(),
                ),
              if (selectedFundamentalReasons.isNotEmpty)
                _buildChipRow(
                  theme,
                  'Fundamental',
                  selectedFundamentalReasons.map((e) => e.toString().split('.').last).toList(),
                ),
            ]),
          ],

          // Attachments (if any)
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCompactReviewCard(theme, 'Attachments', Icons.attach_file, [
              AttachmentPreviewGrid(attachments: attachments.map(AttachmentItem.uploaded).toList(), readOnly: true),
            ]),
          ],

          // Notes (if any)
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.note, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Notes', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(notes, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactReviewCard(ThemeData theme, String title, IconData icon, List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    ),
  );

  Widget _buildReviewRow(ThemeData theme, String label, String value, IconData icon, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color ?? theme.colorScheme.primary.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: color),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );

  Widget _buildCompactRow(ThemeData theme, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
        Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildChipRow(ThemeData theme, String label, List<String> items) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 11,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}
