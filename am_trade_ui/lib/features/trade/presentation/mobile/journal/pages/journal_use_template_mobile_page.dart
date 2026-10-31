import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../internal/domain/entities/journal_template.dart';
import '../../../../internal/domain/enums/template_field_type.dart';

/// Fill playbook fields — full route or inline body inside Playbooks tab.
class JournalUseTemplateMobilePage extends StatefulWidget {
  const JournalUseTemplateMobilePage({
    required this.template,
    required this.onSubmit,
    this.embedded = false,
    this.onCancel,
    super.key,
  });

  final JournalTemplate template;
  final ValueChanged<Map<String, dynamic>> onSubmit;

  /// When true, render form only (no Scaffold) for in-tab Playbooks composer.
  final bool embedded;
  final VoidCallback? onCancel;

  @override
  State<JournalUseTemplateMobilePage> createState() =>
      JournalUseTemplateMobilePageState();
}

class JournalUseTemplateMobilePageState
    extends State<JournalUseTemplateMobilePage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _initialValues = {};
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.template.fields) {
      final type = field.fieldType;
      if (type == TemplateFieldType.text || type == TemplateFieldType.textarea) {
        final text = field.defaultValue ?? '';
        _controllers[field.fieldId] = TextEditingController(text: text)
          ..addListener(_markDirty);
        _initialValues[field.fieldId] = text;
      }
      if (type == TemplateFieldType.checkbox) {
        final checked = field.defaultValue == 'true';
        _values[field.fieldId] = checked;
        _initialValues[field.fieldId] = checked;
      } else if (field.defaultValue != null &&
          type != TemplateFieldType.text &&
          type != TemplateFieldType.textarea) {
        _values[field.fieldId] = field.defaultValue;
        _initialValues[field.fieldId] = field.defaultValue;
      }
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasChanges {
    if (_dirty) return true;
    for (final e in _controllers.entries) {
      if (e.value.text != (_initialValues[e.key] ?? '')) return true;
    }
    for (final e in _values.entries) {
      if (e.value != _initialValues[e.key]) return true;
    }
    return false;
  }

  /// Returns true if caller should leave / discard.
  ///
  /// [force] — Cancel button always warns; back/pop only when dirty.
  Future<bool> confirmLeaveIfUnsaved({bool force = false}) async {
    if (!force && !_hasChanges) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard playbook?'),
        content: Text(
          _hasChanges
              ? 'Your checklist and notes will be lost if you cancel now.'
              : 'Leave without applying this playbook?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ModuleColors.trade,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _handleCancel() async {
    final leave = await confirmLeaveIfUnsaved(force: true);
    if (!leave || !mounted) return;
    if (widget.embedded) {
      widget.onCancel?.call();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    for (final e in _controllers.entries) {
      _values[e.key] = e.value.text;
    }
    widget.onSubmit(Map<String, dynamic>.from(_values));
    if (widget.embedded) {
      // Parent clears inline composer after onSubmit.
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _buildSummaryHeader(context),
                const SizedBox(height: 16),
                if (widget.template.fields.isEmpty)
                  Text(
                    'No fields on this playbook — continue to apply it.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  )
                else
                  for (final field in widget.template.fields) ...[
                    _buildField(context, field),
                    const SizedBox(height: 14),
                  ],
              ],
            ),
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
                      onPressed: _handleCancel,
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ModuleColors.trade,
                      ),
                      onPressed: _submit,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: colors.surface,
        child: PopScope(
          canPop: !_hasChanges,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _handleCancel();
          },
          child: body,
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleCancel,
        ),
        title: Text(
          widget.template.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: PopScope(
        canPop: !_hasChanges,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _handleCancel();
        },
        child: body,
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context) {
    final colors = context.colors;
    final t = widget.template;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.input,
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded) ...[
            Text(
              t.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _metaChip(
                context,
                icon: Icons.category_outlined,
                label: t.category.displayName,
                color: ModuleColors.trade,
              ),
              if (t.isSystemTemplate)
                _metaChip(
                  context,
                  icon: Icons.verified,
                  label: 'System',
                  color: colors.statusWarning,
                ),
              if (t.isRecommended)
                _metaChip(
                  context,
                  icon: Icons.star,
                  label: 'Recommended',
                  color: ModuleColors.trade,
                ),
              _metaChip(
                context,
                icon: Icons.people_outline,
                label: '${t.usageCount} uses',
                color: colors.textSecondary,
              ),
            ],
          ),
          if (t.description != null && t.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              t.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.chip,
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

  Widget _buildField(BuildContext context, dynamic field) {
    final colors = context.colors;
    final type = field.fieldType as TemplateFieldType;
    final label = field.fieldLabel as String;
    final required = field.required == true;

    if (type == TemplateFieldType.checkbox) {
      final checked = _values[field.fieldId] == true;
      return Container(
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: AppRadii.button,
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: CheckboxListTile(
          value: checked,
          onChanged: (v) {
            setState(() {
              _values[field.fieldId] = v ?? false;
              _dirty = true;
            });
          },
          title: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: ModuleColors.trade,
        ),
      );
    }

    final controller = _controllers[field.fieldId]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: type == TemplateFieldType.textarea ? 4 : 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.cardSurface,
            border: OutlineInputBorder(borderRadius: AppRadii.input),
          ),
          validator: required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      ],
    );
  }
}
