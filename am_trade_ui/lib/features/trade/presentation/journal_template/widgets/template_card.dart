import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import '../../../internal/domain/entities/journal_template.dart';

/// Playbook template card — theme tokens only (no hardcoded colors).
class TemplateCard extends StatefulWidget {
  const TemplateCard({
    required this.template,
    required this.onTap,
    required this.onFavoriteToggle,
    this.isListView = false,
    this.isMobileFullWidth = false,
    super.key,
  });

  final JournalTemplate template;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isListView;

  /// Full-width intrinsic-height card for mobile Playbooks (one per row).
  final bool isMobileFullWidth;

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isMobileFullWidth) return _buildMobileFullWidthCard(context);
    return widget.isListView ? _buildListCard(context) : _buildGridCard(context);
  }

  Widget _buildMobileFullWidthCard(BuildContext context) {
    final colors = context.colors;
    final t = widget.template;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: AppRadii.input,
          border: Border.all(color: colors.border.withValues(alpha: 0.28)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildCategoryChip(context),
                      if (t.isSystemTemplate)
                        _smallBadge(
                          context,
                          label: 'System',
                          color: colors.statusWarning,
                          icon: Icons.settings,
                        ),
                      if (t.isRecommended)
                        _smallBadge(
                          context,
                          label: 'Recommended',
                          color: ModuleColors.trade,
                          icon: Icons.star,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${t.usageCount} uses',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 4),
                _buildFavoriteButton(context),
              ],
            ),
            const SizedBox(height: 8),
            _buildTitle(context),
            const SizedBox(height: 4),
            _buildDescription(context, maxLines: 2),
            if (t.fields.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                decoration: BoxDecoration(
                  color: ModuleColors.trade.withValues(alpha: 0.06),
                  borderRadius: AppRadii.button,
                ),
                child: _buildFieldSummary(context, maxItems: 3),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _smallBadge(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.button,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: AppRadii.input,
            border: Border.all(
              color: _isHovered
                  ? ModuleColors.trade.withValues(alpha: 0.35)
                  : colors.border.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: _isHovered ? 0.07 : 0.035),
                blurRadius: _isHovered ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 6),
              _buildTitle(context),
              const SizedBox(height: 2),
              _buildDescription(context, maxLines: 2),
              const SizedBox(height: 6),
              Expanded(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _buildFieldSummary(context, maxItems: 4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Divider(height: 1, color: colors.border.withValues(alpha: 0.35)),
              const SizedBox(height: 4),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 112),
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: AppRadii.input,
            border: Border.all(
              color: _isHovered
                  ? ModuleColors.trade.withValues(alpha: 0.35)
                  : colors.border.withValues(alpha: 0.28),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(context),
                    const SizedBox(height: 4),
                    _buildDescription(context, maxLines: 2),
                    const SizedBox(height: 8),
                    _buildFieldSummary(context, maxItems: 3),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildFavoriteButton(context),
                  const SizedBox(height: 8),
                  _buildCategoryChip(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldSummary(BuildContext context, {int maxItems = 4}) {
    final colors = context.colors;
    final fields = widget.template.fields;
    if (fields.isEmpty) {
      return Text(
        widget.template.description ??
            'Open this playbook to review fields and start an entry.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.35,
            ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    final visible = fields.take(maxItems).toList();
    final remaining = fields.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final field in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: ModuleColors.trade,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    field.fieldLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textPrimary.withValues(alpha: 0.88),
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (remaining > 0)
          Text(
            '+$remaining more field${remaining == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: ModuleColors.trade,
                  fontWeight: FontWeight.w600,
                ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCategoryChip(context)),
        _buildFavoriteButton(context),
      ],
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ModuleColors.trade.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          widget.template.category.displayName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ModuleColors.trade,
                fontWeight: FontWeight.w600,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        widget.template.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: widget.template.isFavorite
            ? context.statusError
            : context.textSecondary,
      ),
      onPressed: widget.onFavoriteToggle,
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      widget.template.name,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            height: 1.2,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription(BuildContext context, {int maxLines = 2}) {
    return Text(
      widget.template.description ?? 'No description available',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
            height: 1.35,
          ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        if (widget.template.isSystemTemplate)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.statusWarning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings,
                  size: 12,
                  color: colors.statusWarning,
                ),
                const SizedBox(width: 4),
                Text(
                  'System',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.statusWarning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        const Spacer(),
        Icon(
          Icons.person_outline,
          size: 14,
          color: colors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.template.usageCount}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
