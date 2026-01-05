import 'package:flutter/material.dart';

import '../../../models/trade_holding_view_model.dart';
import '../widgets/info_card.dart';
import '../widgets/info_row.dart';

/// Displays comprehensive trade information with all fields from TradeDetails.
///
/// This component shows all available trade data including:
/// - Company & Instrument Information
/// - Derivative Details (if applicable)
/// - Trade Details & Execution Info
/// - Strategy & Notes
/// - Tags
/// - Pricing & Fees
/// - Performance Metrics (including MAE/MFE/ROE)
/// - Entry & Exit Reasoning
/// - Psychology Analysis
/// - Attachments
class TradeInfoSection extends StatelessWidget {
  const TradeInfoSection({required this.holding, super.key});

  final TradeHoldingViewModel holding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCompanyInfoCard(context),
        const SizedBox(height: 16),

        // Derivative Information (if applicable)
        if (holding.isDerivative) ...[_buildDerivativeInfoCard(context), const SizedBox(height: 16)],

        _buildTradeDetailsCard(context),
        const SizedBox(height: 16),

        // Strategy & Notes
        if (holding.strategy != null || holding.notes != null) ...[
          _buildStrategyNotesCard(context),
          const SizedBox(height: 16),
        ],

        // Tags
        if (holding.hasTags) ...[_buildTagsCard(context), const SizedBox(height: 16)],

        _buildPricingCard(context),
        const SizedBox(height: 16),

        // Fees & Charges
        if (holding.entryFees != null || holding.exitFees != null) ...[
          _buildFeesCard(context),
          const SizedBox(height: 16),
        ],

        _buildPerformanceMetricsCard(context),
        const SizedBox(height: 16),

        // Entry Reasoning
        if (holding.hasEntryReasoning) ...[_buildEntryReasoningCard(context), const SizedBox(height: 16)],

        // Exit Reasoning
        if (holding.hasExitReasoning) ...[_buildExitReasoningCard(context), const SizedBox(height: 16)],

        // Psychology Data
        if (holding.hasPsychologyData) ...[_buildPsychologyCard(context), const SizedBox(height: 16)],

        // Attachments
        if (holding.hasAttachments) ...[_buildAttachmentsCard(context)],
      ],
    ),
  );

  Widget _buildCompanyInfoCard(BuildContext context) => InfoCard(
    title: 'Company Information',
    icon: Icons.business,
    iconColor: Colors.blue,
    children: [
      InfoRow(label: 'Symbol', value: holding.displaySymbol),
      InfoRow(label: 'Company', value: holding.displayCompanyName),
      InfoRow(label: 'Sector', value: holding.displaySector),
      InfoRow(label: 'Industry', value: holding.displayIndustry),
      InfoRow(label: 'Exchange', value: holding.displayExchange),
      if (holding.isin != null) InfoRow(label: 'ISIN', value: holding.isin!),
      if (holding.currency != null) InfoRow(label: 'Currency', value: holding.displayCurrency),
      if (holding.lotSize != null) InfoRow(label: 'Lot Size', value: holding.displayLotSize),
    ],
  );

  Widget _buildDerivativeInfoCard(BuildContext context) => InfoCard(
    title: 'Derivative Information',
    icon: Icons.trending_up,
    iconColor: Colors.deepPurple,
    children: [
      InfoRow(label: 'Type', value: holding.displayDerivativeType),
      if (holding.underlyingSymbol != null) InfoRow(label: 'Underlying', value: holding.displayUnderlyingSymbol),
      if (holding.strikePrice != null) InfoRow(label: 'Strike Price', value: holding.displayStrikePrice),
      if (holding.expiryDate != null) InfoRow(label: 'Expiry Date', value: holding.displayExpiryDate),
      if (holding.optionType != null) InfoRow(label: 'Option Type', value: holding.displayOptionType),
    ],
  );

  Widget _buildTradeDetailsCard(BuildContext context) => InfoCard(
    title: 'Trade Details',
    icon: Icons.receipt_long,
    iconColor: Colors.purple,
    children: [
      InfoRow(
        label: 'Status',
        value: holding.displayStatus.toUpperCase(),
        valueColor: _getStatusColor(holding.status),
        isBold: true,
      ),
      InfoRow(label: 'Position Type', value: (holding.tradePositionType ?? 'Unknown').toUpperCase(), isBold: true),
      InfoRow(label: 'Quantity', value: holding.displayQuantity),
      InfoRow(label: 'Executions', value: '${holding.executionCount}'),
      InfoRow(label: 'Holding Period', value: holding.displayHoldingPeriod),
      if (holding.broker != null) InfoRow(label: 'Broker', value: holding.broker!),
    ],
  );

  Widget _buildStrategyNotesCard(BuildContext context) => InfoCard(
    title: 'Strategy & Notes',
    icon: Icons.lightbulb_outline,
    iconColor: Colors.amber,
    children: [
      if (holding.strategy != null) InfoRow(label: 'Strategy', value: holding.displayStrategy, isBold: true),
      if (holding.notes != null) InfoRow(label: 'Notes', value: holding.displayNotes, maxLines: null),
    ],
  );

  Widget _buildTagsCard(BuildContext context) {
    final theme = Theme.of(context);
    return InfoCard(
      title: 'Tags',
      icon: Icons.label_outline,
      iconColor: Colors.teal,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: holding.tags!
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(BuildContext context) => InfoCard(
    title: 'Pricing Information',
    icon: Icons.attach_money,
    iconColor: Colors.green,
    children: [
      InfoRow(label: 'Entry Price', value: holding.displayEntryPrice),
      if (holding.exitPrice != null) InfoRow(label: 'Exit Price', value: holding.displayExitPrice),
      InfoRow(label: 'Current Price', value: holding.displayCurrentPrice),
      InfoRow(label: 'Average Price', value: holding.displayAvgPrice),
      if (holding.entryTotalValue != null)
        InfoRow(label: 'Entry Total Value', value: '\$${holding.entryTotalValue!.toStringAsFixed(2)}'),
      if (holding.exitTotalValue != null)
        InfoRow(label: 'Exit Total Value', value: '\$${holding.exitTotalValue!.toStringAsFixed(2)}'),
      InfoRow(label: 'Current Value', value: holding.displayCurrentValue),
    ],
  );

  Widget _buildFeesCard(BuildContext context) => InfoCard(
    title: 'Fees & Charges',
    icon: Icons.receipt,
    iconColor: Colors.redAccent,
    children: [
      if (holding.entryFees != null) InfoRow(label: 'Entry Fees', value: holding.displayEntryFees),
      if (holding.exitFees != null) InfoRow(label: 'Exit Fees', value: holding.displayExitFees),
      const Divider(height: 16),
      InfoRow(label: 'Total Fees', value: holding.displayTotalFees, isBold: true),
    ],
  );

  Widget _buildPerformanceMetricsCard(BuildContext context) => InfoCard(
    title: 'Performance Metrics',
    icon: Icons.analytics,
    iconColor: holding.isProfit ? Colors.green : Colors.red,
    children: [
      InfoRow(
        label: 'Profit/Loss',
        value: '${holding.displayProfitLoss} (${holding.displayProfitLossPercentage})',
        valueColor: holding.isProfit ? Colors.green : Colors.red,
        isBold: true,
      ),
      const Divider(height: 16),
      if (holding.returnOnEquity != null) InfoRow(label: 'Return on Equity', value: holding.displayReturnOnEquity),
      if (holding.riskAmount != null) InfoRow(label: 'Risk Amount', value: holding.displayRiskAmount),
      if (holding.rewardAmount != null) InfoRow(label: 'Reward Amount', value: holding.displayRewardAmount),
      if (holding.riskRewardRatio != null)
        InfoRow(label: 'Risk/Reward Ratio', value: holding.displayRiskRewardRatio, isBold: true),
      if (holding.maxAdverseExcursion != null)
        InfoRow(label: 'Max Adverse Excursion', value: holding.displayMaxAdverseExcursion, valueColor: Colors.red),
      if (holding.maxFavorableExcursion != null)
        InfoRow(
          label: 'Max Favorable Excursion',
          value: holding.displayMaxFavorableExcursion,
          valueColor: Colors.green,
        ),
    ],
  );

  Widget _buildEntryReasoningCard(BuildContext context) => InfoCard(
    title: 'Entry Reasoning',
    icon: Icons.input,
    iconColor: Colors.blue,
    children: [
      if (holding.entryReasoning!.primaryReason != null)
        InfoRow(label: 'Primary Reason', value: holding.entryReasoning!.primaryReason!, isBold: true),
      if (holding.entryReasoning!.reasoningSummary != null)
        InfoRow(label: 'Summary', value: holding.entryReasoning!.reasoningSummary!, maxLines: null),
      if (holding.entryReasoning!.confidenceLevel != null)
        InfoRow(
          label: 'Confidence Level',
          value: '${holding.entryReasoning!.confidenceLevel}/10',
          valueColor: _getConfidenceColor(holding.entryReasoning!.confidenceLevel!),
        ),
      if (holding.entryReasoning!.technicalReasons != null && holding.entryReasoning!.technicalReasons!.isNotEmpty)
        InfoRow(
          label: 'Technical Reasons',
          value: holding.entryReasoning!.technicalReasons!.map((e) => e.name).join(', '),
        ),
      if (holding.entryReasoning!.fundamentalReasons != null && holding.entryReasoning!.fundamentalReasons!.isNotEmpty)
        InfoRow(
          label: 'Fundamental Reasons',
          value: holding.entryReasoning!.fundamentalReasons!.map((e) => e.name).join(', '),
        ),
      if (holding.entryReasoning!.supportingIndicators != null &&
          holding.entryReasoning!.supportingIndicators!.isNotEmpty)
        InfoRow(label: 'Supporting Indicators', value: holding.entryReasoning!.supportingIndicators!.join(', ')),
      if (holding.entryReasoning!.conflictingIndicators != null &&
          holding.entryReasoning!.conflictingIndicators!.isNotEmpty)
        InfoRow(
          label: 'Conflicting Indicators',
          value: holding.entryReasoning!.conflictingIndicators!.join(', '),
          valueColor: Colors.orange,
        ),
    ],
  );

  Widget _buildExitReasoningCard(BuildContext context) => InfoCard(
    title: 'Exit Reasoning',
    icon: Icons.output,
    iconColor: Colors.orange,
    children: [
      if (holding.exitReasoning!.exitPrimaryReason != null)
        InfoRow(label: 'Primary Reason', value: holding.exitReasoning!.exitPrimaryReason!, isBold: true),
      if (holding.exitReasoning!.exitReasoningSummary != null)
        InfoRow(label: 'Summary', value: holding.exitReasoning!.exitReasoningSummary!, maxLines: null),
      if (holding.exitReasoning!.exitConfidenceLevel != null)
        InfoRow(
          label: 'Confidence Level',
          value: '${holding.exitReasoning!.exitConfidenceLevel}/10',
          valueColor: _getConfidenceColor(holding.exitReasoning!.exitConfidenceLevel!),
        ),
      if (holding.exitReasoning!.exitQualityScore != null)
        InfoRow(
          label: 'Exit Quality Score',
          value: '${holding.exitReasoning!.exitQualityScore}/10',
          valueColor: _getConfidenceColor(holding.exitReasoning!.exitQualityScore!),
          isBold: true,
        ),
      if (holding.exitReasoning!.exitSupportingIndicators != null &&
          holding.exitReasoning!.exitSupportingIndicators!.isNotEmpty)
        InfoRow(label: 'Supporting Indicators', value: holding.exitReasoning!.exitSupportingIndicators!.join(', ')),
    ],
  );

  Widget _buildPsychologyCard(BuildContext context) => InfoCard(
    title: 'Psychology Analysis',
    icon: Icons.psychology,
    iconColor: Colors.deepPurple,
    children: [
      if (holding.psychologyData!.psychologyNotes != null)
        InfoRow(label: 'Notes', value: holding.psychologyData!.psychologyNotes!, maxLines: null),
      if (holding.psychologyData!.entryPsychologyFactors != null &&
          holding.psychologyData!.entryPsychologyFactors!.isNotEmpty)
        InfoRow(
          label: 'Entry Psychology',
          value: holding.psychologyData!.entryPsychologyFactors!.map((e) => e.name).join(', '),
        ),
      if (holding.psychologyData!.exitPsychologyFactors != null &&
          holding.psychologyData!.exitPsychologyFactors!.isNotEmpty)
        InfoRow(
          label: 'Exit Psychology',
          value: holding.psychologyData!.exitPsychologyFactors!.map((e) => e.name).join(', '),
        ),
      if (holding.psychologyData!.behaviorPatterns != null && holding.psychologyData!.behaviorPatterns!.isNotEmpty)
        InfoRow(
          label: 'Behavior Patterns',
          value: holding.psychologyData!.behaviorPatterns!.map((e) => e.name).join(', '),
        ),
    ],
  );

  Widget _buildAttachmentsCard(BuildContext context) {
    final theme = Theme.of(context);
    return InfoCard(
      title: 'Attachments (${holding.attachmentCount})',
      icon: Icons.attach_file,
      iconColor: Colors.cyan,
      children: [
        ...holding.attachments!.map(
          (attachment) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getFileIcon(attachment.fileType), size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        attachment.fileName ?? 'Unknown File',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (attachment.description != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 4),
                    child: Text(
                      attachment.description!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                if (attachment.uploadedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 2),
                    child: Text(
                      'Uploaded: ${attachment.uploadedAt!.day}/${attachment.uploadedAt!.month}/${attachment.uploadedAt!.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (attachment != holding.attachments!.last)
                  const Padding(padding: EdgeInsets.only(top: 8), child: Divider(height: 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'WIN':
        return Colors.green;
      case 'LOSS':
        return Colors.red;
      case 'BREAK_EVEN':
        return Colors.orange;
      case 'OPEN':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(int level) {
    if (level >= 8) return Colors.green;
    if (level >= 6) return Colors.orange;
    return Colors.red;
  }

  IconData _getFileIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;

    final type = fileType.toLowerCase();
    if (type.contains('image') || type.contains('png') || type.contains('jpg') || type.contains('jpeg')) {
      return Icons.image;
    }
    if (type.contains('pdf')) {
      return Icons.picture_as_pdf;
    }
    if (type.contains('video')) {
      return Icons.video_file;
    }
    if (type.contains('excel') || type.contains('spreadsheet') || type.contains('csv')) {
      return Icons.table_chart;
    }
    if (type.contains('word') || type.contains('doc')) {
      return Icons.description;
    }
    return Icons.insert_drive_file;
  }
}
