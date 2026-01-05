import 'package:flutter/material.dart';

import '../../../internal/domain/entities/filter_criteria.dart';
import 'filter_group.dart';

/// Profit/Loss Filter Group
class ProfitLossFilterGroup extends FilterGroup {
  ProfitLossFilterGroup({required this.onChanged});
  final TextEditingController minPnLController = TextEditingController();
  final TextEditingController maxPnLController = TextEditingController();
  final TextEditingController minPositionSizeController = TextEditingController();
  final TextEditingController maxPositionSizeController = TextEditingController();
  final VoidCallback onChanged;

  @override
  String get title => 'Profit/Loss & Position';

  @override
  IconData get icon => Icons.attach_money;

  @override
  bool get hasActiveFilters =>
      minPnLController.text.isNotEmpty ||
      maxPnLController.text.isNotEmpty ||
      minPositionSizeController.text.isNotEmpty ||
      maxPositionSizeController.text.isNotEmpty;

  @override
  void reset() {
    minPnLController.clear();
    maxPnLController.clear();
    minPositionSizeController.clear();
    maxPositionSizeController.clear();
    onChanged();
  }

  @override
  Widget buildContent(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              'Min P&L (₹)',
              minPnLController,
              '-10000',
              const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTextField(
              'Max P&L (₹)',
              maxPnLController,
              '10000',
              const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              'Min Position Size (₹)',
              minPositionSizeController,
              '0',
              const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTextField(
              'Max Position Size (₹)',
              maxPositionSizeController,
              '100000',
              const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildTextField(String label, TextEditingController controller, String hint, TextInputType keyboardType) =>
      SizedBox(
        height: 40,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 11),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 10),
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 9),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      controller.clear();
                      onChanged();
                    },
                  )
                : null,
            isDense: true,
          ),
          onChanged: (_) => onChanged(),
        ),
      );

  ProfitLossFilter toFilterCriteria() => ProfitLossFilter(
    minProfitLoss: minPnLController.text.isEmpty ? null : double.tryParse(minPnLController.text),
    maxProfitLoss: maxPnLController.text.isEmpty ? null : double.tryParse(maxPnLController.text),
    minPositionSize: minPositionSizeController.text.isEmpty ? null : double.tryParse(minPositionSizeController.text),
    maxPositionSize: maxPositionSizeController.text.isEmpty ? null : double.tryParse(maxPositionSizeController.text),
  );

  void dispose() {
    minPnLController.dispose();
    maxPnLController.dispose();
    minPositionSizeController.dispose();
    maxPositionSizeController.dispose();
  }
}
