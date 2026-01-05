import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../internal/domain/entities/journal_template.dart';
import '../../../journal_template_providers.dart';

/// Dynamic form builder for template fields
class TemplateFormBuilder extends ConsumerStatefulWidget {
  const TemplateFormBuilder({
    required this.template,
    required this.userId,
    required this.onSubmit,
    super.key,
  });

  final JournalTemplate template;
  final String userId;
  final Function(Map<String, dynamic>) onSubmit;

  @override
  ConsumerState<TemplateFormBuilder> createState() =>
      _TemplateFormBuilderState();
}

class _TemplateFormBuilderState extends ConsumerState<TemplateFormBuilder> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _fieldValues = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for text fields
    for (final field in widget.template.fields) {
      if (field.fieldType.value == 'TEXT' || field.fieldType.value == 'TEXTAREA') {
        _controllers[field.fieldId] = TextEditingController(
          text: field.defaultValue ?? '',
        );
      }
      // Set default values
      if (field.defaultValue != null) {
        _fieldValues[field.fieldId] = field.defaultValue;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
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
                    Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: widget.template.fields.map((field) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildField(context, field),
                          );
                        }).toList(),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
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
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in the template fields',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, field) {
    final fieldType = field.fieldType.value;
    
    switch (fieldType) {
      case 'TEXT':
        return _buildTextField(context, field, maxLines: 1);
      case 'TEXTAREA':
        return _buildTextField(context, field, maxLines: 5);
      case 'CHECKBOX':
        return _buildCheckboxField(context, field);
      case 'NUMBER':
        return _buildNumberField(context, field);
      default:
        return _buildTextField(context, field, maxLines: 1);
    }
  }

  Widget _buildTextField(BuildContext context, field, {required int maxLines}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              field.fieldLabel,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (field.required)
              Text(
                ' *',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        if (field.helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            field.helpText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: _controllers[field.fieldId],
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ),
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
          onChanged: (value) {
            _fieldValues[field.fieldId] = value;
          },
        ),
      ],
    );
  }

  Widget _buildCheckboxField(BuildContext context, field) {
    return CheckboxListTile(
      title: Text(field.fieldLabel),
      subtitle: field.helpText != null ? Text(field.helpText!) : null,
      value: _fieldValues[field.fieldId] as bool? ?? (field.defaultValue == 'true'),
      onChanged: (value) {
        setState(() {
          _fieldValues[field.fieldId] = value ?? false;
        });
      },
    );
  }

  Widget _buildNumberField(BuildContext context, field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              field.fieldLabel,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (field.required)
              Text(
                ' *',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        if (field.helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            field.helpText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ),
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onChanged: (value) {
            _fieldValues[field.fieldId] = value;
          },
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _submitForm,
            icon: const Icon(Icons.check),
            label: const Text('Create Entry'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Collect all field values
      for (final entry in _controllers.entries) {
        _fieldValues[entry.key] = entry.value.text;
      }
      
      // Use the template
      final cubit = ref.read(journalTemplateCubitProvider);
      cubit.useTemplate(
        userId: widget.userId,
        templateId: widget.template.id,
        fieldValues: _fieldValues,
      );
      
      widget.onSubmit(_fieldValues);
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Journal entry created from template!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
