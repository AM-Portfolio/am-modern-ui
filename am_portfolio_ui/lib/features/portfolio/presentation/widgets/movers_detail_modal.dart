import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import '../../internal/domain/entities/portfolio_analytics.dart';
import 'movers_widget.dart';

class MoversDetailModal extends StatelessWidget {
  final Movers movers;
  
  const MoversDetailModal({super.key, required this.movers});

  static Future<void> show(BuildContext context, Movers movers) async {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) => _ModalContainer(
            movers: movers,
            scrollController: scrollController,
          ),
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980, maxHeight: 720),
            child: _ModalContainer(movers: movers),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ModalContainer(movers: movers);
  }
}

class _ModalContainer extends StatelessWidget {
  final Movers movers;
  final ScrollController? scrollController;

  const _ModalContainer({required this.movers, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0D1B2A).withValues(alpha: 0.95),
                      const Color(0xFF0A1628).withValues(alpha: 0.85),
                    ]
                  : [
                      context.cardColor.withValues(alpha: 0.98),
                      const Color(0xFFF5F7FF).withValues(alpha: 0.9),
                    ],
            ),
            border: Border.all(
              color: context.colors.actionPrimaryFg.withValues(alpha: isDark ? 0.07 : 0.4),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ds.ModuleColors.portfolio.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_graph_rounded,
                        color: ds.ModuleColors.portfolio,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Top Movers',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          Text(
                            'Day change — highest gainers and losers',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: MoversPanelContent(
                    movers: movers,
                    compact: isMobile,
                    maxRows: 10,
                    forceTabs: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
