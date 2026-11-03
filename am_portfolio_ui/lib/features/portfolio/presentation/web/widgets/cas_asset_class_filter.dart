import 'package:flutter/material.dart';

/// Chip filter for CAS / statement asset classes on holdings.
class CasAssetClassFilter extends StatelessWidget {
  const CasAssetClassFilter({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  static const options = <String, String>{
    'equity': 'Equity',
    'mutual_fund_demat': 'MF (demat)',
    'debt': 'Debt',
    'mutual_fund_folio': 'MF folios',
    'nps': 'NPS',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: value == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          for (final e in options.entries) ...[
            FilterChip(
              label: Text(e.value),
              selected: value == e.key,
              onSelected: (_) => onChanged(e.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
