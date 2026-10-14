import 'dart:ui';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import '../../../internal/domain/entities/journal_template.dart';

/// Animated template card with glassmorphism design
class TemplateCard extends StatefulWidget {
  const TemplateCard({
    required this.template,
    required this.onTap,
    required this.onFavoriteToggle,
    this.isListView = false,
    super.key,
  });

  final JournalTemplate template;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isListView;

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 2.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isListView ? _buildListCard(context) : _buildGridCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.card,
                  boxShadow: [
                    BoxShadow(
                      color: ModuleColors.trade.withValues(alpha: 0.12),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadii.card,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.cardSurface,
                        borderRadius: AppRadii.card,
                        border: Border.all(
                          color: _isHovered
                              ? ModuleColors.trade.withValues(alpha: 0.45)
                              : colors.border.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: AppSpacing.xs),
                            _buildTitle(context),
                            const SizedBox(height: AppSpacing.xxs),
                            _buildDescription(context, maxLines: 2),
                            const SizedBox(height: AppSpacing.sm),
                            // Fill leftover cell height with summary, not a blank void.
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: _buildFieldSummary(context, maxItems: 5),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _buildFooter(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 120),
              decoration: BoxDecoration(
                borderRadius: AppRadii.card,
                boxShadow: [
                  BoxShadow(
                    color: ModuleColors.trade.withValues(alpha: 0.1),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadii.card,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.cardSurface,
                      borderRadius: AppRadii.card,
                      border: Border.all(
                        color: _isHovered
                            ? ModuleColors.trade.withValues(alpha: 0.45)
                            : colors.border.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTitle(context),
                                const SizedBox(height: AppSpacing.xxs),
                                _buildDescription(context, maxLines: 2),
                                const SizedBox(height: AppSpacing.sm),
                                _buildFieldSummary(context, maxItems: 3),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildFavoriteButton(context),
                              _buildCategoryChip(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Checklist-style preview of template fields — fills former empty card space.
  Widget _buildFieldSummary(BuildContext context, {int maxItems = 4}) {
    final colors = context.colors;
    final fields = widget.template.fields;
    if (fields.isEmpty) {
      return Text(
        widget.template.description ??
            'Open this playbook to review fields and start an entry.',
        style: context.text.caption(compact: true).copyWith(
              color: colors.textSecondary,
              height: 1.35,
            ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      );
    }

    final visible = fields.take(maxItems).toList();
    final remaining = fields.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: ModuleColors.trade.withValues(alpha: 0.85),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    field.fieldLabel,
                    style: context.text.caption(compact: true).copyWith(
                          color: colors.textPrimary.withValues(alpha: 0.85),
                          height: 1.25,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (field.required)
                  Text(
                    'Req',
                    style: context.text.caption(compact: true).copyWith(
                          color: context.statusError.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                  ),
              ],
            ),
          ),
        if (remaining > 0)
          Text(
            '+$remaining more field${remaining == 1 ? '' : 's'}',
            style: context.text.caption(compact: true).copyWith(
                  color: ModuleColors.trade,
                  fontWeight: FontWeight.w600,
                ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _buildCategoryChip(context)),
        _buildFavoriteButton(context),
      ],
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ModuleColors.trade.withValues(alpha: 0.15),
        borderRadius: AppRadii.chip,
        border: Border.all(
          color: ModuleColors.trade.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        widget.template.category.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ModuleColors.trade,
              fontWeight: FontWeight.w600,
            ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: widget.template.isFavorite ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.2),
          child: IconButton(
            icon: Icon(
              widget.template.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.template.isFavorite
                  ? context.statusError
                  : context.textSecondary,
            ),
            onPressed: widget.onFavoriteToggle,
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      widget.template.name,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription(BuildContext context, {int maxLines = 3}) {
    return Text(
      widget.template.description ?? 'No description available',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
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
              borderRadius: AppRadii.chip,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 12,
                  color: colors.statusWarning,
                ),
                const SizedBox(width: 4),
                Text(
                  'System',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.statusWarning,
                      ),
                ),
              ],
            ),
          ),
        const Spacer(),
        Icon(
          Icons.people_outline,
          size: 14,
          color: colors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.template.usageCount}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
      ],
    );
  }
}
