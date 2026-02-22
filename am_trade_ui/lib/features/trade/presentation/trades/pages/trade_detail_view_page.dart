import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_common/am_common.dart';
import '../../models/trade_holding_view_model.dart';
import '../widgets/trade_detail_widgets/attachments_grid_view.dart';
import '../widgets/trade_detail_widgets/modern_trade_header.dart';
import '../widgets/trade_detail_widgets/similar_trades_section.dart';
import '../widgets/trade_detail_widgets/trade_detail_summary.dart';
import '../widgets/trade_detail_widgets/vertical_attachments_feed.dart';

/// Dedicated page for displaying detailed trade information in a modular layout
class TradeDetailViewPage extends ConsumerStatefulWidget {
  const TradeDetailViewPage({
    required this.trade,
    required this.userId,
    required this.portfolioId,
    this.onClose,
    this.onNavigateToChart,
    super.key,
  });

  final TradeHoldingViewModel trade;
  final String userId;
  final String portfolioId;
  final VoidCallback? onClose;
  final Function(String symbol)? onNavigateToChart;

  @override
  ConsumerState<TradeDetailViewPage> createState() => _TradeDetailViewPageState();
}

class _TradeDetailViewPageState extends ConsumerState<TradeDetailViewPage> {
  String? _symbolFilter;

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('?? Building TradeDetailViewPage', tag: 'TradeDetail');
    AppLogger.debug('?? Trade Symbol: ${widget.trade.symbol}', tag: 'TradeDetail');
    AppLogger.debug('?? Has Attachments: ${widget.trade.hasAttachments}', tag: 'TradeDetail');
    AppLogger.debug('?? Attachment Count: ${widget.trade.attachmentCount}', tag: 'TradeDetail');

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          // Modern Header with animations
          ModernTradeHeader(
            trade: widget.trade,
            onClose: widget.onClose,
            onSymbolTap: widget.onNavigateToChart,
            onFilterChanged: (value) {
              setState(() {
                _symbolFilter = value?.trim().isEmpty ?? true ? null : value;
              });
            },
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Summary Cards (Trade Details, Price, Fees, Performance)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TradeDetailSummary(trade: widget.trade),
                        const SizedBox(height: 20),

                        // Similar Trades Section
                        SimilarTradesSection(
                          trade: widget.trade,
                          userId: widget.userId,
                          portfolioId: widget.portfolioId,
                          symbolFilter: _symbolFilter,
                        ),
                      ],
                    ),
                  ),

                  // Attachments Grid View - SHOWN FIRST IN GRID FORMAT
                  if (widget.trade.hasAttachments) ...[AttachmentsGridView(trade: widget.trade)],

                  // Evidence & Analysis Section (Vertical Feed) - AT THE BOTTOM
                  if (widget.trade.hasAttachments) ...[
                    const SizedBox(height: 8),
                    VerticalAttachmentsFeed(trade: widget.trade),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

