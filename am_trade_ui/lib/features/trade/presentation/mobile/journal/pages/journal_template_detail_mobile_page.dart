import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../internal/domain/entities/journal_template.dart';

/// Full-screen playbook detail for mobile (replaces [TemplateDetailDialog]).
class JournalTemplateDetailMobilePage extends StatelessWidget {
  const JournalTemplateDetailMobilePage({
    required this.template,
    this.onUseTemplate,
    super.key,
  });

  final JournalTemplate template;
  final ValueChanged<JournalTemplate>? onUseTemplate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              template.category.displayName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: ModuleColors.trade,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (template.description != null &&
                    template.description!.trim().isNotEmpty) ...[
                  Text(
                    template.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.people_outline,
                      label: '${template.usageCount} uses',
                      color: ModuleColors.trade,
                    ),
                    if (template.isSystemTemplate)
                      _MetaChip(
                        icon: Icons.verified,
                        label: 'System Template',
                        color: colors.statusWarning,
                      ),
                    if (template.isRecommended)
                      _MetaChip(
                        icon: Icons.star,
                        label: 'Recommended',
                        color: ModuleColors.trade,
                      ),
                  ],
                ),
                if (template.fields.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Template Fields',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  for (final field in template.fields)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.cardSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: ModuleColors.trade,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field.fieldLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                ),
                                if (field.helpText != null &&
                                    field.helpText!.trim().isNotEmpty)
                                  Text(
                                    field.helpText!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: colors.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                          if (field.required)
                            Text(
                              'Required',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colors.statusError,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: GlobalBottomNavVisibility.factor,
            builder: (context, navFactor, _) {
              final factor = navFactor.clamp(0.0, 1.0);
              final bottomReserve =
                  PlatformConstants.globalBottomNavReserve(context);
              final bottomPad = 12.0 + (bottomReserve * factor);
              return Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad),
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  border: Border(
                    top: BorderSide(
                      color: colors.border.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          final leave = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Leave playbook?'),
                              content: const Text(
                                'Leave without using this playbook?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Keep viewing'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ModuleColors.trade,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Leave'),
                                ),
                              ],
                            ),
                          );
                          if (leave == true && context.mounted) {
                            Navigator.of(context).pop(false);
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: ModuleColors.trade,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                          onUseTemplate?.call(template);
                        },
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text('Use Template'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
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
}
