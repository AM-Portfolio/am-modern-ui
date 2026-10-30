import 'dart:ui';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/enums/journal_template_category.dart';
import '../../../internal/domain/enums/template_field_type.dart';
import '../../../journal_template_providers.dart';

/// Draft row for the simple field builder (v1: checkbox / text / textarea).
class _DraftField {
  _DraftField() : labelController = TextEditingController();

  final TextEditingController labelController;
  TemplateFieldType type = TemplateFieldType.checkbox;
  bool required = false;

  void dispose() => labelController.dispose();
}

/// Dialog / page for creating custom templates with a simple field builder.
class CreateTemplateDialog extends ConsumerStatefulWidget {
  const CreateTemplateDialog({
    this.asPage = false,
    super.key,
  });

  /// When true, render full-bleed content (mobile Scaffold body) without Dialog chrome.
  final bool asPage;

  @override
  ConsumerState<CreateTemplateDialog> createState() =>
      _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends ConsumerState<CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  JournalTemplateCategory _selectedCategory = JournalTemplateCategory.custom;
  final List<_DraftField> _fields = [_DraftField()];
  String? _fieldsError;

  static const _v1FieldTypes = <TemplateFieldType>[
    TemplateFieldType.checkbox,
    TemplateFieldType.text,
    TemplateFieldType.textarea,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = Column(
      children: [
        if (!widget.asPage) _buildHeader(context),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(widget.asPage ? 16 : 24),
              children: [
                _buildNameField(context),
                const SizedBox(height: 20),
                _buildDescriptionField(context),
                const SizedBox(height: 20),
                _buildCategoryDropdown(context),
                const SizedBox(height: 24),
                _buildFieldsSection(context),
              ],
            ),
          ),
        ),
        _buildActions(context),
      ],
    );

    if (widget.asPage) {
      return ColoredBox(color: colors.surface, child: body);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.surface.withValues(alpha: 0.9),
                    colors.cardSurface.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ModuleColors.trade.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Custom Template',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Name your playbook and add checklist or note fields',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: colors.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Template Name *',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'e.g., My Daily Review',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colors.cardSurface.withValues(alpha: 0.35),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a template name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe what this template is for...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colors.cardSurface.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<JournalTemplateCategory>(
          value: _selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colors.cardSurface.withValues(alpha: 0.35),
          ),
          items: JournalTemplateCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCategory = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFieldsSection(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Fields *',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _fields.add(_DraftField());
                  _fieldsError = null;
                });
              },
              icon: Icon(Icons.add, size: 18, color: ModuleColors.trade),
              label: Text(
                'Add field',
                style: TextStyle(color: ModuleColors.trade),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Add at least one checklist or text field for your playbook.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        if (_fieldsError != null) ...[
          const SizedBox(height: 8),
          Text(
            _fieldsError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.statusError,
                ),
          ),
        ],
        const SizedBox(height: 12),
        ...List.generate(_fields.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFieldRow(context, index),
          );
        }),
      ],
    );
  }

  Widget _buildFieldRow(BuildContext context, int index) {
    final colors = context.colors;
    final draft = _fields[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardSurface.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: draft.labelController,
                  decoration: InputDecoration(
                    labelText: 'Label',
                    hintText: 'e.g., Risk defined',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: colors.surface.withValues(alpha: 0.5),
                  ),
                  onChanged: (_) {
                    if (_fieldsError != null) {
                      setState(() => _fieldsError = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<TemplateFieldType>(
                  value: draft.type,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: colors.surface.withValues(alpha: 0.5),
                  ),
                  items: _v1FieldTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => draft.type = value);
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: 'Remove field',
                onPressed: _fields.length <= 1
                    ? null
                    : () {
                        setState(() {
                          final removed = _fields.removeAt(index);
                          removed.dispose();
                        });
                      },
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: _fields.length <= 1
                      ? colors.textSecondary.withValues(alpha: 0.4)
                      : colors.statusError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: const Text('Required'),
              selected: draft.required,
              onSelected: (selected) {
                setState(() => draft.required = selected);
              },
              selectedColor: ModuleColors.trade.withValues(alpha: 0.15),
              checkmarkColor: ModuleColors.trade,
              labelStyle: TextStyle(
                color: draft.required
                    ? ModuleColors.trade
                    : colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardSurface.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton(
            text: 'Cancel',
            type: AppButtonType.text,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          AppButton(
            text: 'Create Template',
            icon: Icons.add,
            backgroundColor: ModuleColors.trade,
            onPressed: _createTemplate,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>>? _buildFieldsPayload() {
    final labeled = <Map<String, dynamic>>[];
    for (var i = 0; i < _fields.length; i++) {
      final draft = _fields[i];
      final label = draft.labelController.text.trim();
      if (label.isEmpty) continue;
      labeled.add({
        'fieldId': _slugFieldId(label, i),
        'fieldLabel': label,
        'fieldType': draft.type.value,
        'required': draft.required,
        'order': labeled.length,
      });
    }
    return labeled.isEmpty ? null : labeled;
  }

  static String _slugFieldId(String label, int index) {
    final base = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final safe = base.isEmpty ? 'field' : base;
    return '${safe}_$index';
  }

  Future<void> _createTemplate() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final fields = _buildFieldsPayload();
    if (fields == null) {
      setState(() {
        _fieldsError = 'Add at least one field with a label.';
      });
      return;
    }
    if (!formOk) return;

    final cubit = await ref.read(journalTemplateCubitProvider.future);
    cubit.createTemplate(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      fields: fields,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
