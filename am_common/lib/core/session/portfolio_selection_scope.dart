import 'package:flutter/material.dart';

/// Lightweight shell-level portfolio selection (ID + name only).
///
/// Lives in the main bundle so Trade tab routing works before the portfolio
/// deferred chunk loads. [GlobalPortfolioWrapper] syncs cubit state here.
class PortfolioSelectionScope extends StatefulWidget {
  const PortfolioSelectionScope({
    required this.child,
    this.initialPortfolioId,
    this.initialPortfolioName,
    super.key,
  });

  final Widget child;
  final String? initialPortfolioId;
  final String? initialPortfolioName;

  static _PortfolioSelectionScopeState? maybeStateOf(BuildContext context) {
    return context.findAncestorStateOfType<_PortfolioSelectionScopeState>();
  }

  @override
  State<PortfolioSelectionScope> createState() =>
      _PortfolioSelectionScopeState();
}

class _PortfolioSelectionScopeState extends State<PortfolioSelectionScope> {
  late String? _selectedPortfolioId;
  late String? _selectedPortfolioName;

  @override
  void initState() {
    super.initState();
    _selectedPortfolioId = widget.initialPortfolioId;
    _selectedPortfolioName = widget.initialPortfolioName;
  }

  @override
  void didUpdateWidget(PortfolioSelectionScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.initialPortfolioId;
    if (id != null &&
        id != _selectedPortfolioId &&
        id != oldWidget.initialPortfolioId) {
      _selectedPortfolioId = id;
      _selectedPortfolioName = widget.initialPortfolioName;
    }
  }

  void updateSelection(String id, String name) {
    if (_selectedPortfolioId == id && _selectedPortfolioName == name) return;
    setState(() {
      _selectedPortfolioId = id;
      _selectedPortfolioName = name;
    });
  }

  void seedSelection(String? id, String? name) {
    if (id == null) return;
    if (_selectedPortfolioId == id && _selectedPortfolioName == name) return;
    setState(() {
      _selectedPortfolioId = id;
      _selectedPortfolioName = name;
    });
  }

  String? get selectedPortfolioId => _selectedPortfolioId;
  String? get selectedPortfolioName => _selectedPortfolioName;

  @override
  Widget build(BuildContext context) {
    return _PortfolioSelectionData(
      selectedPortfolioId: _selectedPortfolioId,
      selectedPortfolioName: _selectedPortfolioName,
      onSelect: updateSelection,
      child: widget.child,
    );
  }
}

class _PortfolioSelectionData extends InheritedWidget {
  const _PortfolioSelectionData({
    required this.selectedPortfolioId,
    required this.selectedPortfolioName,
    required this.onSelect,
    required super.child,
  });

  final String? selectedPortfolioId;
  final String? selectedPortfolioName;
  final void Function(String id, String name) onSelect;

  static _PortfolioSelectionData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_PortfolioSelectionData>();
  }

  @override
  bool updateShouldNotify(_PortfolioSelectionData oldWidget) {
    return oldWidget.selectedPortfolioId != selectedPortfolioId ||
        oldWidget.selectedPortfolioName != selectedPortfolioName;
  }
}

extension PortfolioSelectionContext on BuildContext {
  String? get selectedPortfolioId =>
      _PortfolioSelectionData.maybeOf(this)?.selectedPortfolioId;

  String? get selectedPortfolioName =>
      _PortfolioSelectionData.maybeOf(this)?.selectedPortfolioName;

  void selectPortfolio(String id, String name) {
    PortfolioSelectionScope.maybeStateOf(this)?.updateSelection(id, name);
  }
}
