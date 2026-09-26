import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:am_market_ui/features/ipo/widgets/ipo_summary_card.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoLandingScreen extends ConsumerStatefulWidget {
  const IpoLandingScreen({super.key});

  @override
  ConsumerState<IpoLandingScreen> createState() => _IpoLandingScreenState();
}

class _IpoLandingScreenState extends ConsumerState<IpoLandingScreen> {
  String _selectedStatus = 'open';

  @override
  Widget build(BuildContext context) {
    final countsAsync = ref.watch(ipoCountsProvider);
    final ipoListAsync = ref.watch(ipoListProvider(_selectedStatus));

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        leading: const AmBackButton(),
        title: Text(
          'IPO Center',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.textPrimary,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: _buildSegmentedControl(countsAsync),
          ),
          Expanded(
            child: ipoListAsync.when(
              data: (ipos) => _buildIpoList(ipos),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Failed to load IPOs', style: TextStyle(color: context.statusError)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(AsyncValue<AsraxIpoCountsDto> countsAsync) {
    // Fallback counts
    final counts = countsAsync.value ?? AsraxIpoCountsDto();
    
    return Row(
      children: [
        _buildToggleChip('Available', 'open', counts.open),
        const SizedBox(width: AppSpacing.sm),
        _buildToggleChip('Upcoming', 'upcoming', counts.upcoming),
        const SizedBox(width: AppSpacing.sm),
        _buildToggleChip('Closed', 'closed', counts.closed),
      ],
    );
  }

  Widget _buildToggleChip(String label, String status, int count) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? ModuleColors.market.withValues(alpha: 0.1) : context.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isSelected ? ModuleColors.market : context.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? ModuleColors.market : context.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? ModuleColors.market : context.borderColor,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? context.marketTheme.accentText : context.textPrimary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIpoList(List<AsraxIpoSummaryDto> ipos) {
    if (ipos.isEmpty) {
      return Center(
        child: Text(
          'No IPOs found',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ipoCountsProvider);
        ref.invalidate(ipoListProvider(_selectedStatus));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: ipos.length,
        itemBuilder: (context, index) {
          final ipo = ipos[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: IpoSummaryCard(ipo: ipo),
          );
        },
      ),
    );
  }
}
