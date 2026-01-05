import 'package:flutter/material.dart';

import '../../../../../features/trade/internal/domain/enums/derivative_types.dart';
import '../../../../../features/trade/internal/domain/enums/enum_extensions.dart';
import '../../../../../features/trade/internal/domain/enums/option_types.dart';
import 'package:am_design_system/am_design_system.dart';

/// Derivative details card for trade forms
class DerivativeCard extends StatelessWidget {
  const DerivativeCard({
    required this.selectedDerivativeType,
    required this.selectedOptionType,
    required this.strikePriceController,
    required this.expiryDate,
    required this.onDerivativeTypeChanged,
    required this.onOptionTypeChanged,
    required this.onExpiryDateTap,
    super.key,
  });

  final DerivativeTypes? selectedDerivativeType;
  final OptionTypes? selectedOptionType;
  final TextEditingController strikePriceController;
  final DateTime? expiryDate;
  final ValueChanged<DerivativeTypes?> onDerivativeTypeChanged;
  final ValueChanged<OptionTypes?> onOptionTypeChanged;
  final VoidCallback onExpiryDateTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics_outlined, size: 20, color: theme.colorScheme.onTertiaryContainer),
              ),
              const SizedBox(width: 12),
              Text('Derivative (Optional)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),

          // Type dropdown
          CustomDropdown<DerivativeTypes>(
            value: selectedDerivativeType,
            hint: 'Select Type',
            items: DerivativeTypes.values
                .map((type) => type.toSimpleDropdownItem(text: type.toString().split('.').last.toUpperCase()))
                .toList(),
            onChanged: onDerivativeTypeChanged,
          ),

          // Expanded fields when type is selected
          if (selectedDerivativeType != null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: strikePriceController,
                    decoration: InputDecoration(
                      labelText: 'Strike',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomDropdown<OptionTypes>(
                    value: selectedOptionType,
                    hint: 'Select Option',
                    items: OptionTypes.values
                        .map((type) => type.toSimpleDropdownItem(text: type.toString().split('.').last.toUpperCase()))
                        .toList(),
                    onChanged: onOptionTypeChanged,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: onExpiryDateTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expiry',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          expiryDate?.toLocal().toString().split(' ')[0] ?? 'Select date',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
