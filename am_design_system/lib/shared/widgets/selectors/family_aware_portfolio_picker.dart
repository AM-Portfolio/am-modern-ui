import 'package:am_design_system/core/module/module_config.dart';
import 'package:am_design_system/shared/widgets/selectors/shared_family_filter_dropdown.dart';
import 'package:am_design_system/shared/widgets/selectors/shared_portfolio_selector.dart';
import 'package:flutter/material.dart';

/// Family filter (optional) + portfolio dropdown, shared by dashboard + sidebars.
class FamilyAwarePortfolioPicker<T> extends StatelessWidget {
  const FamilyAwarePortfolioPicker({
    super.key,
    required this.showFamilyFilter,
    required this.familyFilterKey,
    required this.primaryLabel,
    required this.members,
    required this.onFamilySelected,
    required this.currentPortfolioId,
    required this.currentPortfolioName,
    required this.portfolios,
    required this.onPortfolioSelected,
    required this.idExtractor,
    required this.nameExtractor,
    this.subtitleExtractor,
    this.accentColor,
    this.isSelectableExtractor,
    this.showNoHoldingsBadgeExtractor,
    this.defaultPortfolioId,
    this.onToggleDefault,
    this.layout = FamilyAwarePortfolioPickerLayout.stack,
    this.compact = false,
    this.familyWidth,
    this.portfolioWidth,
  });

  final bool showFamilyFilter;
  final String familyFilterKey;
  final String primaryLabel;
  final List<({String id, String name})> members;
  final ValueChanged<String> onFamilySelected;

  final String? currentPortfolioId;
  final String? currentPortfolioName;
  final List<T> portfolios;
  final void Function(String id, String name) onPortfolioSelected;
  final String Function(T) idExtractor;
  final String Function(T) nameExtractor;
  final String? Function(T)? subtitleExtractor;
  final Color? accentColor;
  final bool Function(T)? isSelectableExtractor;
  final bool Function(T)? showNoHoldingsBadgeExtractor;
  final String? defaultPortfolioId;
  final void Function(String id, String name)? onToggleDefault;

  /// [stack] = Family above Portfolio (sidebars). [row] = side-by-side (toolbar).
  final FamilyAwarePortfolioPickerLayout layout;
  final bool compact;
  final double? familyWidth;
  final double? portfolioWidth;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? ModuleColors.portfolio;
    final portfolio = SharedPortfolioSelector<T>(
      currentPortfolioId: currentPortfolioId,
      currentPortfolioName: currentPortfolioName,
      portfolios: portfolios,
      onPortfolioSelected: onPortfolioSelected,
      idExtractor: idExtractor,
      nameExtractor: nameExtractor,
      subtitleExtractor: compact ? null : subtitleExtractor,
      accentColor: accent,
      isSelectableExtractor: isSelectableExtractor,
      showNoHoldingsBadgeExtractor: showNoHoldingsBadgeExtractor,
      defaultPortfolioId: defaultPortfolioId,
      onToggleDefault: onToggleDefault,
      // Toolbar uses dense single-line dropdown; sidebars keep titled control.
      dense: layout == FamilyAwarePortfolioPickerLayout.row,
    );

    if (!showFamilyFilter) return portfolio;

    final family = SharedFamilyFilterDropdown(
      selectedKey: familyFilterKey,
      primaryLabel: primaryLabel,
      members: members,
      onSelected: onFamilySelected,
      accentColor: accent,
      compact: compact,
    );

    if (layout == FamilyAwarePortfolioPickerLayout.row) {
      // Compact mobile toolbars: share width (family left, portfolio right).
      if (compact) {
        return SizedBox(
          height: 36,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 1,
                child: familyWidth == null
                    ? SizedBox(width: double.infinity, child: family)
                    : SizedBox(width: familyWidth, child: family),
              ),
              const SizedBox(width: 6),
              Flexible(
                flex: 1,
                child: portfolioWidth == null
                    ? SizedBox(width: double.infinity, child: portfolio)
                    : SizedBox(width: portfolioWidth, child: portfolio),
              ),
            ],
          ),
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (familyWidth != null)
            SizedBox(width: familyWidth, child: family)
          else
            family,
          const SizedBox(width: 10),
          Flexible(
            child: portfolioWidth == null
                ? ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 148,
                      maxWidth: 210,
                    ),
                    child: portfolio,
                  )
                : SizedBox(width: portfolioWidth, child: portfolio),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        family,
        const SizedBox(height: 8),
        portfolio,
      ],
    );
  }
}

enum FamilyAwarePortfolioPickerLayout { stack, row }
