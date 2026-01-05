import 'package:flutter/material.dart';

/// Exit details card for trade forms
class ExitCard extends StatelessWidget {
  const ExitCard({
    required this.exitDate,
    required this.exitPriceController,
    required this.exitQuantityController,
    required this.onDateTap,
    required this.entryDate,
    super.key,
  });

  final DateTime? exitDate;
  final TextEditingController exitPriceController;
  final TextEditingController exitQuantityController;
  final VoidCallback onDateTap;
  final DateTime? entryDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.logout, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Exit', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          InkWell(
            onTap: onDateTap,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.event, size: 18),
                isDense: true,
              ),
              child: Text(
                exitDate?.toLocal().toString().split(' ')[0] ?? 'Not selected',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: exitPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixIcon: Icon(Icons.currency_rupee, size: 18),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: exitQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    prefixIcon: Icon(Icons.tag, size: 18),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
