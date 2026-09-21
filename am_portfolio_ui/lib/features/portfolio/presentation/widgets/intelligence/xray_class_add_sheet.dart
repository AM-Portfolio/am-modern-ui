import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart' as market;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/portfolio_holding.dart';
import '../../../providers/portfolio_providers.dart';
import 'intelligence_suggest_search.dart';
import 'xray_display_name.dart';

/// Wire values for PUT `/v1/portfolios/{id}/asset-classes/{assetClass}`.
const kXrayClassAddWireOptions = <({String wire, String apiName, IconData icon})>[
  (wire: 'bonds', apiName: 'BONDS', icon: Icons.account_balance_rounded),
  (wire: 'commodities', apiName: 'COMMODITY', icon: Icons.diamond_outlined),
  (wire: 'cash', apiName: 'CASH', icon: Icons.payments_outlined),
];

Future<void> showXrayClassAddSheet({
  required BuildContext context,
  required String portfolioId,
  required VoidCallback onSaved,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final isPhone = width < 600;

  final form = XrayClassAddSheet(
    portfolioId: portfolioId,
    onSaved: onSaved,
  );

  if (isPhone) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (routeContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(routeContext).bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          builder: (_, controller) => _SheetShell(
            child: ListView(
              controller: controller,
              children: [form],
            ),
          ),
        ),
      ),
    );
  }

  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (routeContext) {
      final maxH = MediaQuery.sizeOf(routeContext).height * 0.82;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480, maxHeight: maxH),
          child: _SheetShell(child: form),
        ),
      );
    },
  );
}

/// Frosted panel chrome around the form.
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF1A222D),
                  Color(0xFF121820),
                  Color(0xFF0E141C),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: ModuleColors.portfolio.withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}

class XrayClassAddSheet extends ConsumerStatefulWidget {
  const XrayClassAddSheet({
    required this.portfolioId,
    required this.onSaved,
    super.key,
  });

  final String portfolioId;
  final VoidCallback onSaved;

  @override
  ConsumerState<XrayClassAddSheet> createState() => _XrayClassAddSheetState();
}

class _XrayClassAddSheetState extends ConsumerState<XrayClassAddSheet> {
  String _wire = kXrayClassAddWireOptions.first.wire;
  final List<_RowCtrls> _rows = [_RowCtrls()];
  bool _saving = false;
  String? _error;
  final Map<String, String> _symbolByName = {};

  List<PortfolioHolding> _holdings() {
    return ref
            .watch(portfolioHoldingsProvider(widget.portfolioId))
            .asData
            ?.value
            .holdings ??
        const [];
  }

  void _onNameSelected(_RowCtrls ctrls, String name) {
    setState(() {
      ctrls.name.text = name;
      final sym = _symbolByName[name.toLowerCase()];
      if (sym != null && sym.isNotEmpty) {
        ctrls.symbol.text = sym;
      }
    });
  }

  Future<List<market.SecurityDocument>> _searchNames(String query) async {
    final remote = await ref.read(portfolioRemoteDataSourceProvider.future);
    final docs = await searchClassAddNames(
      remote: remote,
      portfolioId: widget.portfolioId,
      query: query,
      wire: _wire,
    );
    _symbolByName.clear();
    for (final h in _holdings()) {
      final label = (h.companyName.isNotEmpty
              ? h.companyName
              : (h.name.isNotEmpty ? h.name : h.symbol))
          .trim();
      final sym = h.symbol.trim();
      if (label.isEmpty || sym.isEmpty) continue;
      if (sym.toUpperCase() == label.toUpperCase()) continue;
      _symbolByName[label.toLowerCase()] = sym;
    }
    return docs;
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRow() => setState(() => _rows.add(_RowCtrls()));

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() => _rows.removeAt(index).dispose());
  }

  String? _validate() {
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      if (r.name.text.trim().isEmpty) {
        return 'Item ${i + 1}: name is required';
      }
      final value = double.tryParse(r.value.text.trim());
      if (value == null || value <= 0) {
        return 'Item ${i + 1}: value must be greater than 0';
      }
      final qtyText = r.quantity.text.trim();
      if (qtyText.isNotEmpty) {
        final qty = double.tryParse(qtyText);
        if (qty == null || qty < 0) {
          return 'Item ${i + 1}: quantity must be a valid number';
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _bodyItems() => [
        for (final r in _rows)
          <String, dynamic>{
            'name': r.name.text.trim(),
            if (r.symbol.text.trim().isNotEmpty) 'symbol': r.symbol.text.trim(),
            if (r.quantity.text.trim().isNotEmpty)
              'quantity': double.parse(r.quantity.text.trim()),
            'currentValue': double.parse(r.value.text.trim()),
          },
      ];

  String _friendlyError(Object e) {
    final raw = e.toString();
    if (raw.contains('404') || raw.contains('No static resource')) {
      return 'Save isn’t available on prod yet — backend deploy is still pending. Try again after Deploy → Prod finishes.';
    }
    if (raw.contains('403') || raw.contains('Forbidden')) {
      return 'You don’t have permission to edit this portfolio.';
    }
    if (raw.contains('401') || raw.contains('Unauthorized')) {
      return 'Session expired. Please sign in again.';
    }
    return raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Api'), '')
        .trim();
  }

  Future<void> _save() async {
    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final remote = await ref.read(portfolioRemoteDataSourceProvider.future);
      await remote.replaceAssetClassList(
        widget.portfolioId,
        _wire,
        _bodyItems(),
      );
      if (!mounted) return;
      widget.onSaved();
      Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _friendlyError(e);
      });
    }
  }

  InputDecoration _fieldDeco({
    required String label,
    String? hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      // External labels — avoids float overlap with section headers.
      floatingLabelBehavior: FloatingLabelBehavior.never,
      hintText: hint ?? label,
      isDense: true,
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ModuleColors.portfolio, width: 1.5),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.72),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: ModuleColors.portfolio.withValues(alpha: 0.18),
                ),
                child: Icon(
                  Icons.add_chart_rounded,
                  color: ModuleColors.portfolio,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add asset class',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bond, precious metal, or cash — not covered by Doc Intel.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context, rootNavigator: true).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'CLASS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < kXrayClassAddWireOptions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _ClassPickCard(
                    label: xrayDisplayName(kXrayClassAddWireOptions[i].apiName),
                    icon: kXrayClassAddWireOptions[i].icon,
                    selected: _wire == kXrayClassAddWireOptions[i].wire,
                    enabled: !_saving,
                    onTap: () => setState(
                      () {
                        _wire = kXrayClassAddWireOptions[i].wire;
                        _symbolByName.clear();
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < _rows.length; i++) ...[
            _HoldingCard(
              index: i,
              ctrls: _rows[i],
              canRemove: _rows.length > 1 && !_saving,
              onRemove: () => _removeRow(i),
              fieldDeco: _fieldDeco,
              fieldLabel: _fieldLabel,
              nameHint: classAddNameHint(_wire),
              onNameSelected: (name) => _onNameSelected(_rows[i], name),
              searchNames: _searchNames,
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _saving ? null : _addRow,
              icon: Icon(
                Icons.add_rounded,
                size: 18,
                color: ModuleColors.portfolio,
              ),
              label: Text(
                'Add another holding',
                style: TextStyle(
                  color: ModuleColors.portfolio,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context, rootNavigator: true).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: ModuleColors.portfolio,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save to portfolio',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassPickCard extends StatelessWidget {
  const _ClassPickCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? ModuleColors.portfolio.withValues(alpha: 0.22)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03)),
            border: Border.all(
              color: selected
                  ? ModuleColors.portfolio
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? ModuleColors.portfolio
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({
    required this.index,
    required this.ctrls,
    required this.canRemove,
    required this.onRemove,
    required this.fieldDeco,
    required this.fieldLabel,
    required this.nameHint,
    required this.onNameSelected,
    required this.searchNames,
  });

  final int index;
  final _RowCtrls ctrls;
  final bool canRemove;
  final VoidCallback onRemove;
  final InputDecoration Function({required String label, String? hint})
      fieldDeco;
  final Widget Function(String text) fieldLabel;
  final String nameHint;
  final ValueChanged<String> onNameSelected;
  final Future<List<market.SecurityDocument>> Function(String query)
      searchNames;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Holding ${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: onRemove,
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            fieldLabel('Name'),
            SizedBox(
              height: 48,
              child: SmartSearchAnchor(
                controller: ctrls.name,
                compact: true,
                hintText: nameHint,
                accentColor: ModuleColors.portfolio,
                forceUppercase: false,
                resultBadge: null,
                overlayPlacement: SmartSearchOverlayPlacement.above,
                onSelected: onNameSelected,
                searchHandler: searchNames,
              ),
            ),
            const SizedBox(height: 12),
            fieldLabel('Symbol'),
            TextField(
              controller: ctrls.symbol,
              decoration: fieldDeco(label: 'Symbol', hint: 'Optional'),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('Quantity'),
                      TextField(
                        controller: ctrls.quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: fieldDeco(label: 'Qty', hint: 'Optional'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('Value (INR)'),
                      TextField(
                        controller: ctrls.value,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: fieldDeco(label: 'Value', hint: '50000'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RowCtrls {
  final name = TextEditingController();
  final symbol = TextEditingController();
  final quantity = TextEditingController();
  final value = TextEditingController();

  void dispose() {
    name.dispose();
    symbol.dispose();
    quantity.dispose();
    value.dispose();
  }
}
