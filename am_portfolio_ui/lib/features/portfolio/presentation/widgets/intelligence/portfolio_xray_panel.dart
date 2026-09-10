import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_intelligence_providers.dart';
import 'intelligence_glass_card.dart';

class PortfolioXrayPanel extends ConsumerStatefulWidget {
  const PortfolioXrayPanel({
    required this.portfolioId,
    this.height,
    super.key,
  });

  final String portfolioId;
  final double? height;

  @override
  ConsumerState<PortfolioXrayPanel> createState() => _PortfolioXrayPanelState();
}

class _PortfolioXrayPanelState extends ConsumerState<PortfolioXrayPanel> {
  int _tab = 0; // 0 sector, 1 industry, 2 cap, 3 asset (disabled)

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(portfolioIntelligenceProvider(widget.portfolioId));

    return async.when(
      loading: () => IntelligenceCardSkeleton(height: widget.height ?? 320),
      error: (e, _) => IntelligenceGlassCard(
        title: 'Portfolio X-Ray',
        icon: Icons.donut_large_rounded,
        child: IntelligenceRetryRow(
          message: 'Could not load X-Ray',
          onRetry: () => ref
              .invalidate(portfolioIntelligenceProvider(widget.portfolioId)),
        ),
      ),
      data: (intel) {
        final xray = intel?.xray;
        final weights = _weightsForTab(xray);

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TabChip(
                    label: 'Sector',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _TabChip(
                    label: 'Industry',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                  _TabChip(
                    label: 'Cap',
                    selected: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                  ),
                  const _TabChip(
                    label: 'Asset Class',
                    selected: false,
                    enabled: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (weights.isEmpty)
              Text(
                'No allocation data',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...weights.take(8).map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _WeightRow(weight: w),
                    ),
                  ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showIntelligenceSheet(
                  context: context,
                  title: 'Full X-Ray',
                  body: Column(
                    children: (xray == null
                            ? const <XrayWeight>[]
                            : [
                                ...xray.sectorWeights,
                                ...xray.industryWeights,
                                ...xray.marketCapWeights,
                              ])
                        .map(
                          (w) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(w.name),
                            trailing: Text(
                              '${w.weightPct.toStringAsFixed(1)}%',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                child: const Text('Explore Full X-Ray'),
              ),
            ),
          ],
        );

        final card = IntelligenceGlassCard(
          title: 'Portfolio X-Ray',
          icon: Icons.donut_large_rounded,
          child: body,
        );

        if (widget.height != null) {
          return SizedBox(
            height: widget.height,
            child: SingleChildScrollView(child: card),
          );
        }
        return card;
      },
    );
  }

  List<XrayWeight> _weightsForTab(PortfolioXray? xray) {
    if (xray == null) return const [];
    switch (_tab) {
      case 1:
        return xray.industryWeights;
      case 2:
        return xray.marketCapWeights;
      case 0:
      default:
        return xray.sectorWeights;
    }
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: !enabled || onTap == null ? null : (_) => onTap!(),
        selectedColor: ModuleColors.portfolio.withValues(alpha: 0.25),
        labelStyle: TextStyle(
          color: !enabled
              ? Theme.of(context).disabledColor
              : (selected ? ModuleColors.portfolio : null),
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({required this.weight});

  final XrayWeight weight;

  @override
  Widget build(BuildContext context) {
    final pct = weight.weightPct.clamp(0, 100) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                weight.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              '${weight.weightPct.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: ModuleColors.portfolio.withValues(alpha: 0.12),
            color: ModuleColors.portfolio,
          ),
        ),
      ],
    );
  }
}
