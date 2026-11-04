import 'dart:ui';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/journal_template.dart';
import '../../../journal_template_providers.dart';

/// Single editable template dialog — fill fields here; no second "Use Template" page.
class TemplateDetailDialog extends ConsumerStatefulWidget {
  const TemplateDetailDialog({
    required this.template,
    this.onUseTemplate,
    super.key,
  });

  final JournalTemplate template;
  final ValueChanged<JournalTemplate>? onUseTemplate;

  @override
  ConsumerState<TemplateDetailDialog> createState() =>
      _TemplateDetailDialogState();
}

class _TemplateDetailDialogState extends ConsumerState<TemplateDetailDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _fieldValues = {};
  final Map<String, TextEditingController> _controllers = {};
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    for (final field in widget.template.fields) {
      final type = field.fieldType.value;
      if (type == 'TEXT' || type == 'TEXTAREA' || type == 'NUMBER') {
        _controllers[field.fieldId] = TextEditingController(
          text: field.defaultValue ?? '',
        );
      }
      if (type == 'CHECKBOX' || type == 'CHECKBOX_LIST') {
        _fieldValues[field.fieldId] = field.defaultValue == 'true';
      } else if (field.defaultValue != null) {
        _fieldValues[field.fieldId] = field.defaultValue;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: ListView(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            children: [
                              _buildDescription(context),
                              const SizedBox(height: AppSpacing.md),
                              _buildMetadata(context),
                              if (widget.template.fields.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'Template Fields',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                ...widget.template.fields.map(
                                  (field) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: _buildEditableField(context, field),
                                  ),
                                ),
                              ],
                              if (widget.template.tags.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                _buildTags(context),
                              ],
                            ],
                          ),
                        ),
                      ),
                      _buildActions(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ModuleColors.trade.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.template.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  widget.template.category.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ModuleColors.trade,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final desc = widget.template.description?.trim();
    if (desc == null || desc.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          desc,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
        ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _MetaChip(
          icon: Icons.people_outline,
          label: '${widget.template.usageCount} uses',
          color: ModuleColors.trade,
        ),
        if (widget.template.isSystemTemplate)
          _MetaChip(
            icon: Icons.verified,
            label: 'System Template',
            color: colors.statusWarning,
          ),
        if (widget.template.isRecommended)
          _MetaChip(
            icon: Icons.star,
            label: 'Recommended',
            color: ModuleColors.trade,
          ),
      ],
    );
  }

  Widget _buildEditableField(BuildContext context, dynamic field) {
    final type = field.fieldType.value as String;
    switch (type) {
      case 'CHECKBOX':
      case 'CHECKBOX_LIST':
        return _buildCheckboxField(context, field);
      case 'NUMBER':
        return _buildTextInput(context, field, number: true);
      case 'TEXTAREA':
        return _buildTextInput(context, field, maxLines: 4);
      case 'TEXT':
      default:
        return _buildTextInput(context, field, maxLines: 1);
    }
  }

  /// Checkbox: interactive row — checklist item label only (no stacked title).
  Widget _buildCheckboxField(BuildContext context, dynamic field) {
    final colors = context.colors;
    // Prefer the checklist item name; fall back to placeholder/help.
    final label = (field.fieldLabel as String?)?.trim().isNotEmpty == true
        ? field.fieldLabel as String
        : ((field.placeholder as String?)?.trim().isNotEmpty == true
            ? field.placeholder as String
            : (field.helpText as String? ?? 'Item'));
    final checked = _fieldValues[field.fieldId] as bool? ?? false;

    return Material(
      color: colors.surface.withValues(alpha: 0.55),
      borderRadius: AppRadii.input,
      child: InkWell(
        borderRadius: AppRadii.input,
        onTap: () => setState(() => _fieldValues[field.fieldId] = !checked),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.input,
            border: Border.all(color: colors.border.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                activeColor: ModuleColors.trade,
                onChanged: (v) =>
                    setState(() => _fieldValues[field.fieldId] = v ?? false),
              ),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                ),
              ),
              if (field.required == true)
                Text(
                  '*',
                  style: TextStyle(
                    color: colors.statusError,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Text/notes: placeholder only (no title above the field).
  Widget _buildTextInput(
    BuildContext context,
    dynamic field, {
    int maxLines = 1,
    bool number = false,
  }) {
    final colors = context.colors;
    final hint = (field.placeholder as String?)?.trim().isNotEmpty == true
        ? field.placeholder as String
        : ((field.helpText as String?)?.trim().isNotEmpty == true
            ? field.helpText as String
            : field.fieldLabel as String);
    final controller = _controllers.putIfAbsent(
      field.fieldId as String,
      () => TextEditingController(text: field.defaultValue ?? ''),
    );

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: colors.surface.withValues(alpha: 0.55),
        border: OutlineInputBorder(borderRadius: AppRadii.input),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: ModuleColors.trade, width: 1.5),
        ),
      ),
      validator: (value) {
        if (field.required == true && (value == null || value.trim().isEmpty)) {
          return 'Required';
        }
        if (number &&
            value != null &&
            value.trim().isNotEmpty &&
            double.tryParse(value.trim()) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
      onChanged: (value) => _fieldValues[field.fieldId] = value,
    );
  }

  Widget _buildTags(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: widget.template.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: ModuleColors.trade.withValues(alpha: 0.12),
            borderRadius: AppRadii.chip,
          ),
          child: Text(
            tag,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ModuleColors.trade,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.cardSurface.withValues(alpha: 0.65),
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: ModuleColors.trade),
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(_submitting ? 'Saving…' : 'Create Entry'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    for (final entry in _controllers.entries) {
      _fieldValues[entry.key] = entry.value.text;
    }
    for (final field in widget.template.fields) {
      final type = field.fieldType.value;
      if ((type == 'CHECKBOX' || type == 'CHECKBOX_LIST') &&
          field.required &&
          _fieldValues[field.fieldId] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check “${_checkboxLabel(field)}” to continue'),
            backgroundColor: context.colors.statusWarning,
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final cubit = await ref.read(journalTemplateCubitProvider.future);
      await cubit.useTemplate(
        templateId: widget.template.id,
        fieldValues: _fieldValues,
      );
      if (!mounted) return;
      widget.onUseTemplate?.call(widget.template);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create entry: $e'),
          backgroundColor: context.colors.statusError,
        ),
      );
    }
  }

  String _checkboxLabel(dynamic field) {
    // Prefer the checklist item name (unique); help/placeholder is often identical.
    final label = (field.fieldLabel as String?)?.trim();
    if (label != null && label.isNotEmpty) return label;
    final placeholder = (field.placeholder as String?)?.trim();
    if (placeholder != null && placeholder.isNotEmpty) return placeholder;
    final help = (field.helpText as String?)?.trim();
    if (help != null && help.isNotEmpty) return help;
    return 'Required item';
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.chip,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
