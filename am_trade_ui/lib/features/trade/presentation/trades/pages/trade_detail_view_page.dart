import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/trade_holding_view_model.dart';
import '../widgets/trade_detail_widgets/attachments_grid_view.dart';
import '../widgets/trade_detail_widgets/mobile_trade_detail_header.dart';
import '../widgets/trade_detail_widgets/mobile_trade_detail_summary.dart';
import '../widgets/trade_detail_widgets/modern_trade_header.dart';
import '../widgets/trade_detail_widgets/similar_trades_section.dart';
import '../widgets/trade_detail_widgets/trade_detail_journal_section.dart';
import '../widgets/trade_detail_widgets/trade_detail_summary.dart';
import '../widgets/trade_detail_widgets/vertical_attachments_feed.dart';

/// Dedicated page for displaying detailed trade information in a modular layout.
class TradeDetailViewPage extends ConsumerStatefulWidget {
  const TradeDetailViewPage({
    required this.trade,
    required this.portfolioId,
    this.onClose,
    this.onNavigateToChart,
    super.key,
  });

  final TradeHoldingViewModel trade;
  final String portfolioId;
  final VoidCallback? onClose;
  final Function(String symbol)? onNavigateToChart;

  static const double mobileBreakpoint = 700;

  @override
  ConsumerState<TradeDetailViewPage> createState() =>
      _TradeDetailViewPageState();
}

class _TradeDetailViewPageState extends ConsumerState<TradeDetailViewPage> {
  String? _symbolFilter;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building TradeDetailViewPage', tag: 'TradeDetail');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < TradeDetailViewPage.mobileBreakpoint;
        return Material(
          color: isMobile
              ? context.colors.scaffoldBackground
              : Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Column(
            children: [
              if (!isMobile)
                ModernTradeHeader(
                  trade: widget.trade,
                  portfolioId: widget.portfolioId,
                  onClose: widget.onClose,
                  onSymbolTap: widget.onNavigateToChart,
                  onFilterChanged: (value) {
                    setState(() {
                      _symbolFilter =
                          value?.trim().isEmpty ?? true ? null : value;
                    });
                  },
                ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(
                          isMobile ? AppSpacing.sm : AppSpacing.md,
                        ),
                        child: Column(
                          children: [
                            if (isMobile) ...[
                              MobileTradeDetailHeader(
                                trade: widget.trade,
                                portfolioId: widget.portfolioId,
                                onClose: widget.onClose,
                                onSymbolTap: widget.onNavigateToChart,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              MobileTradeDetailSummary(trade: widget.trade),
                            ] else
                              TradeDetailSummary(trade: widget.trade),
                            SizedBox(
                              height: isMobile
                                  ? AppSpacing.sm
                                  : AppSpacing.sm + AppSpacing.xs,
                            ),
                            if (!isMobile) ...[
                              TradeDetailJournalSection(
                                tradeId: widget.trade.tradeId,
                                portfolioId: widget.portfolioId,
                                symbol: widget.trade.symbol,
                                holding: widget.trade,
                              ),
                              SizedBox(
                                height: AppSpacing.sm + AppSpacing.xs,
                              ),
                            ],
                            SimilarTradesSection(
                              trade: widget.trade,
                              portfolioId: widget.portfolioId,
                              symbolFilter: _symbolFilter,
                              onSymbolFilterChanged: (value) {
                                setState(() {
                                  _symbolFilter =
                                      value?.trim().isEmpty ?? true
                                          ? null
                                          : value;
                                });
                              },
                              compact: isMobile,
                            ),
                          ],
                        ),
                      ),
                      if (widget.trade.hasAttachments) ...[
                        AttachmentsGridView(trade: widget.trade),
                        const SizedBox(height: AppSpacing.sm),
                        VerticalAttachmentsFeed(trade: widget.trade),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
