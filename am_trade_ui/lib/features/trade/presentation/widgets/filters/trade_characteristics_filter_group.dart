import 'package:flutter/material.dart';

import 'package:am_design_system/am_design_system.dart';
import '../../../internal/domain/entities/filter_criteria.dart';
import '../../../internal/domain/enums/trade_directions.dart';
import '../../../internal/domain/enums/trade_statuses.dart';
import 'filter_group.dart';

/// Trade Characteristics Filter Group
class TradeCharacteristicsFilterGroup extends FilterGroup {
  TradeCharacteristicsFilterGroup({required this.onChanged});
  List<TradeDirections> selectedDirections = [];
  List<TradeStatuses> selectedStatuses = [];
  final TextEditingController strategiesController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController minHoldingHoursController = TextEditingController();
  final TextEditingController maxHoldingHoursController = TextEditingController();
  final VoidCallback onChanged;

  @override
  String get title => 'Trade Characteristics';

  @override
  IconData get icon => Icons.trending_up;

  @override
  bool get hasActiveFilters =>
      selectedDirections.isNotEmpty ||
      selectedStatuses.isNotEmpty ||
      strategiesController.text.isNotEmpty ||
      tagsController.text.isNotEmpty ||
      minHoldingHoursController.text.isNotEmpty ||
      maxHoldingHoursController.text.isNotEmpty;

  @override
  void reset() {
    selectedDirections.clear();
    selectedStatuses.clear();
    strategiesController.clear();
    tagsController.clear();
    minHoldingHoursController.clear();
    maxHoldingHoursController.clear();
    onChanged();
  }

  @override
  Widget buildContent(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: MultiSelectDropdown<TradeDirections>(
              label: 'Direction',
              selectedValues: selectedDirections,
              allValues: TradeDirections.values,
              formatter: _formatDirection,
              onChanged: (values) {
                selectedDirections = values;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: MultiSelectDropdown<TradeStatuses>(
              label: 'Status',
              selectedValues: selectedStatuses,
              allValues: TradeStatuses.values,
              formatter: _formatStatus,
              onChanged: (values) {
                selectedStatuses = values;
                onChanged();
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(child: _buildTextField('Strategies (comma-separated)', strategiesController, 'Scalping, Swing')),
          const SizedBox(width: 6),
          Expanded(child: _buildTextField('Tags (comma-separated)', tagsController, 'earnings, breakout')),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(child: _buildTextField('Min Holding Hours', minHoldingHoursController, '0', TextInputType.number)),
          const SizedBox(width: 6),
          Expanded(child: _buildTextField('Max Holding Hours', maxHoldingHoursController, '24', TextInputType.number)),
        ],
      ),
    ],
  );

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, [
    TextInputType keyboardType = TextInputType.text,
  ]) => SizedBox(
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

  String _formatDirection(TradeDirections direction) {
    switch (direction) {
      case TradeDirections.long:
        return 'Long/Buy';
      case TradeDirections.short:
        return 'Short/Sell';
    }
  }

  String _formatStatus(TradeStatuses status) {
    switch (status) {
      case TradeStatuses.open:
        return 'Open';
      case TradeStatuses.win:
        return 'Win';
      case TradeStatuses.loss:
        return 'Loss';
      case TradeStatuses.breakeven:
        return 'Break Even';
    }
  }

  TradeCharacteristicsFilter toFilterCriteria() => TradeCharacteristicsFilter(
    directions: selectedDirections,
    statuses: selectedStatuses,
    strategies: strategiesController.text.isEmpty
        ? []
        : strategiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    tags: tagsController.text.isEmpty
        ? []
        : tagsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    minHoldingTimeHours: minHoldingHoursController.text.isEmpty ? null : int.tryParse(minHoldingHoursController.text),
    maxHoldingTimeHours: maxHoldingHoursController.text.isEmpty ? null : int.tryParse(maxHoldingHoursController.text),
  );

  void dispose() {
    strategiesController.dispose();
    tagsController.dispose();
    minHoldingHoursController.dispose();
    maxHoldingHoursController.dispose();
  }
}
