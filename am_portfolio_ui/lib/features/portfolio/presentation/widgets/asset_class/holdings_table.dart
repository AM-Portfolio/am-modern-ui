import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart' as market;
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/asset_class/holding_form_state.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/asset_class/add_asset_class_workspace.dart'; // For StepBadge
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_suggest_search.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_providers.dart';

class HoldingsTable extends ConsumerStatefulWidget {
  const HoldingsTable({
    super.key,
    required this.isDesktop,
    required this.portfolioId,
    this.onOpenDocIntel,
  });

  final bool isDesktop;
  final String portfolioId;
  final VoidCallback? onOpenDocIntel;

  @override
  ConsumerState<HoldingsTable> createState() => _HoldingsTableState();
}

class _HoldingsTableState extends ConsumerState<HoldingsTable> {
  final _SessionSearchCache _sessionCache = _SessionSearchCache();

  @override
  void dispose() {
    _sessionCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = ref.watch(addAssetClassTypeProvider);
    final holdings = ref.watch(addAssetClassHoldingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(widget.isDesktop ? 12 : 0),
          decoration: BoxDecoration(
            color: widget.isDesktop
                ? theme.colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.isDesktop
                ? Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isDesktop) _TableHeader(type: type),
              ...holdings.asMap().entries.map((entry) {
                final index = entry.key;
                final holding = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _HoldingCard(
                    index: index,
                    holding: holding,
                    type: type,
                    portfolioId: widget.portfolioId,
                    isDesktop: widget.isDesktop,
                    sessionCache: _sessionCache,
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => ref
                        .read(addAssetClassHoldingsProvider.notifier)
                        .addRow(),
                    child: CustomPaint(
                      painter: _DashedBorderPainter(
                        color: ModuleColors.portfolio.withValues(alpha: 0.6),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: ModuleColors.portfolio,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              type == 'bonds'
                                  ? 'Add Another Bond'
                                  : type == 'commodities'
                                  ? 'Add Another Commodity'
                                  : 'Add Another Cash',
                              style: TextStyle(
                                color: ModuleColors.portfolio,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HoldingCard extends ConsumerStatefulWidget {
  const _HoldingCard({
    required this.index,
    required this.holding,
    required this.type,
    required this.portfolioId,
    required this.isDesktop,
    required this.sessionCache,
  });
  final int index;
  final HoldingFormState holding;
  final String type;
  final String portfolioId;
  final bool isDesktop;
  final _SessionSearchCache sessionCache;

  @override
  ConsumerState<_HoldingCard> createState() => _HoldingCardState();
}

class _HoldingCardState extends ConsumerState<_HoldingCard> {
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _totalController;
  Timer? _debounceTimer;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.holding.name);
    _qtyController = TextEditingController(text: widget.holding.quantity);
    _priceController = TextEditingController(text: widget.holding.pricePerUnit);
    _totalController = TextEditingController(text: widget.holding.totalValue);
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (_nameController.text != widget.holding.name) {
      ref
          .read(addAssetClassHoldingsProvider.notifier)
          .updateRow(
            widget.holding.id,
            (h) => h.copyWith(name: _nameController.text),
          );
    }
  }

  @override
  void didUpdateWidget(_HoldingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holding.name != widget.holding.name &&
        _nameController.text != widget.holding.name) {
      _nameController.text = widget.holding.name;
    }
    if (oldWidget.holding.quantity != widget.holding.quantity &&
        _qtyController.text != widget.holding.quantity) {
      _qtyController.text = widget.holding.quantity;
    }
    if (oldWidget.holding.pricePerUnit != widget.holding.pricePerUnit &&
        _priceController.text != widget.holding.pricePerUnit) {
      _priceController.text = widget.holding.pricePerUnit;
    }
    if (oldWidget.holding.totalValue != widget.holding.totalValue &&
        _totalController.text != widget.holding.totalValue) {
      _totalController.text = widget.holding.totalValue;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final holding = widget.holding;
    final type = widget.type;
    final holdingsCount = ref.watch(addAssetClassHoldingsProvider).length;
    final isFlatLayout = MediaQuery.sizeOf(context).width >= 900;

    void update(HoldingFormState Function(HoldingFormState) updater) {
      ref
          .read(addAssetClassHoldingsProvider.notifier)
          .updateRow(holding.id, updater);
    }

    Future<List<market.SecurityDocument>> _searchNames(String query) async {
      if (widget.type == 'cash') return const [];

      final q = query.trim();
      if (q.isEmpty) return const [];

      final cacheKey = '${widget.type}:$q';
      final cached = widget.sessionCache.get(cacheKey);
      if (cached != null) return cached;

      _debounceTimer?.cancel();
      final completer = Completer<List<market.SecurityDocument>>();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        final myId = ++_requestId;
        try {
          final remote = await ref.read(
            portfolioRemoteDataSourceProvider.future,
          );
          final rawResults = await searchClassAddNames(
            remote: remote,
            portfolioId: widget.portfolioId,
            query: q,
            wire: widget.type,
          );
          if (myId == _requestId) {
            final seen = <String>{};
            final results = <market.SecurityDocument>[];
            for (final doc in rawResults) {
              final val = (doc.key?.symbol ?? '').toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]'),
                '',
              );
              if (val.isNotEmpty && !seen.contains(val)) {
                seen.add(val);
                var cName = doc.metadata?.companyName;
                market.SecurityDocument finalDoc = doc;
                if (cName != null && cName.toLowerCase().contains('template')) {
                  cName = cName.replaceAll(
                    RegExp(r'\s*·\s*Template', caseSensitive: false),
                    '',
                  );
                  finalDoc = market.SecurityDocument(
                    key: doc.key,
                    metadata: market.SecurityMetadata(companyName: cName),
                  );
                }
                results.add(finalDoc);
              }
            }
            widget.sessionCache.put(cacheKey, results);
            if (!completer.isCompleted) completer.complete(results);
          } else {
            if (!completer.isCompleted) completer.complete(const []);
          }
        } catch (_) {
          if (!completer.isCompleted) completer.complete(const []);
        }
      });
      return completer.future;
    }

    void onNameSelected(String name) {
      _nameController.text = name;
      update((h) => h.copyWith(name: name));
    }

    Widget buildNameField() {
      final numberLabel = isFlatLayout
          ? [
              SizedBox(
                width: 24,
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ]
          : <Widget>[];

      if (widget.type == 'cash') {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ...numberLabel,
            Expanded(
              child: SizedBox(
                height: 38,
                child: _buildInput(
                  context,
                  controller: _nameController,
                  hint: classAddNameHint('cash'),
                  onChanged: (v) => update((h) => h.copyWith(name: v)),
                ),
              ),
            ),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...numberLabel,
          Expanded(
            child: SizedBox(
              height: 38,
              child: SmartSearchAnchor(
                controller: _nameController,
                compact: true,
                hintText: classAddNameHint(widget.type),
                accentColor: ModuleColors.portfolio,
                forceUppercase: false,
                resultBadge: null,
                overlayPlacement: SmartSearchOverlayPlacement.below,
                onSelected: onNameSelected,
                searchHandler: _searchNames,
              ),
            ),
          ),
        ],
      );
    }

    Widget buildSegmentField() {
      if (type == 'cash') return const SizedBox.shrink();
      return SizedBox(
        height: 38,
        child: _buildDropdown(
          context,
          value:
              holding.segment ?? (type == 'bonds' ? 'Government' : 'Bullion'),
          items: type == 'bonds'
              ? ['Government', 'Corporate', 'PSU']
              : ['Bullion', 'Energy', 'Metals', 'Agri'],
          onChanged: (v) => update((h) => h.copyWith(segment: v)),
        ),
      );
    }

    Widget buildQuantityField() {
      if (type == 'cash') return const SizedBox.shrink();
      return SizedBox(
        height: 38,
        child: _buildInput(
          context,
          controller: _qtyController,
          hint: '0',
          isNumber: true,
          textAlign: TextAlign.right,
          onChanged: (v) => update((h) => h.updateQuantity(v.isEmpty ? '' : v)),
        ),
      );
    }

    Widget buildPriceField() {
      if (type == 'cash') return const SizedBox.shrink();
      return SizedBox(
        height: 38,
        child: _buildInput(
          context,
          controller: _priceController,
          hint: '0.00',
          isNumber: true,
          textAlign: TextAlign.right,
          onChanged: (v) => update((h) => h.updatePrice(v.isEmpty ? '' : v)),
        ),
      );
    }

    Widget buildTotalField() {
      return SizedBox(
        height: 38,
        child: _buildInput(
          context,
          controller: _totalController,
          hint: '0.00',
          isNumber: true,
          textAlign: TextAlign.right,
          onChanged: (v) =>
              update((h) => h.updateTotalValue(v.isEmpty ? '' : v)),
        ),
      );
    }

    Widget buildDeleteIcon() {
      if (holdingsCount <= 1) return const SizedBox(width: 48);
      return SizedBox(
        width: 48,
        height: 38, // Match input height for precise vertical alignment
        child: Align(
          alignment: Alignment.center,
          child: IconButton(
            tooltip: 'Remove holding',
            onPressed: () => ref
                .read(addAssetClassHoldingsProvider.notifier)
                .removeRow(holding.id),
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: theme.colorScheme.error,
            ),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    }

    final content = isFlatLayout
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 30, child: buildNameField()),
              if (type != 'cash') ...[
                const SizedBox(width: 12),
                Expanded(flex: 18, child: buildSegmentField()),
                const SizedBox(width: 12),
                Expanded(flex: 13, child: buildQuantityField()),
                const SizedBox(width: 12),
                Expanded(flex: 18, child: buildPriceField()),
              ] else ...[
                const SizedBox(width: 12),
                const Spacer(flex: 18),
                const SizedBox(width: 12),
                const Spacer(flex: 13),
                const SizedBox(width: 12),
                const Spacer(flex: 18),
              ],
              const SizedBox(width: 12),
              Expanded(flex: 16, child: buildTotalField()),
              const SizedBox(width: 8),
              buildDeleteIcon(),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildNameField(),
              if (type != 'cash') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: buildSegmentField()),
                    const SizedBox(width: 12),
                    Expanded(child: buildQuantityField()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: buildPriceField()),
                    const SizedBox(width: 12),
                    Expanded(child: buildTotalField()),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                buildTotalField(),
              ],
            ],
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isFlatLayout
            ? context.glassOverlay(isDark ? 0.015 : 0.01)
            : context.glassOverlay(isDark ? 0.03 : 0.02),
        border: Border(
          bottom: BorderSide(color: context.glassOverlay(isDark ? 0.07 : 0.05)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isDesktop) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Holding ${widget.index + 1}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (holdingsCount > 1)
                    IconButton(
                      tooltip: 'Remove holding',
                      onPressed: () => ref
                          .read(addAssetClassHoldingsProvider.notifier)
                          .removeRow(holding.id),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            content,
          ],
        ),
      ),
    );
  }
}

// Helpers

Widget _fieldLabel(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
      ),
    ),
  );
}

InputDecoration _fieldDeco(BuildContext context, {required String hint}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.never,
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: context.glassOverlay(isDark ? 0.03 : 0.01),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    hintStyle: TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      fontSize: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: ModuleColors.portfolio, width: 1.5),
    ),
  );
}

Widget _buildInput(
  BuildContext context, {
  required TextEditingController controller,
  required String hint,
  bool isNumber = false,
  TextAlign textAlign = TextAlign.left,
  required ValueChanged<String> onChanged,
}) {
  return SizedBox(
    height: 40,
    child: TextFormField(
      controller: controller,
      onChanged: onChanged,
      textAlign: textAlign,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: _fieldDeco(context, hint: hint),
    ),
  );
}

Widget _buildDropdown(
  BuildContext context, {
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return SizedBox(
    height: 40,
    child: DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      onChanged: onChanged,
      isExpanded: true,
      decoration: _fieldDeco(context, hint: ''),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill the background
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, bgPaint);

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? 6.0 : 4.0;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            strokePaint,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget headerText(String text, {TextAlign align = TextAlign.left}) {
      return Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: context.glassOverlay(isDark ? 0.05 : 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 30,
            child: Row(
              children: [
                SizedBox(width: 24, child: headerText('#')),
                const SizedBox(width: 8),
                Expanded(
                  child: headerText(type == 'bonds' ? 'Bond Name' : 'Name'),
                ),
              ],
            ),
          ),
          if (type != 'cash') ...[
            const SizedBox(width: 12),
            Expanded(flex: 18, child: headerText('Segment (Optional)')),
            const SizedBox(width: 12),
            Expanded(
              flex: 13,
              child: headerText('Quantity (Optional)', align: TextAlign.right),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 18,
              child: headerText(
                'Price per unit (Optional)',
                align: TextAlign.right,
              ),
            ),
          ] else ...[
            const SizedBox(width: 12),
            const Spacer(flex: 18),
            const SizedBox(width: 12),
            const Spacer(flex: 13),
            const SizedBox(width: 12),
            const Spacer(flex: 18),
          ],
          const SizedBox(width: 12),
          Expanded(
            flex: 16,
            child: headerText('Total Value (INR)', align: TextAlign.right),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: headerText('Action', align: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _SessionSearchCache {
  _SessionSearchCache({this.maxSize = 50});
  final int maxSize;
  final _map = <String, List<market.SecurityDocument>>{};

  List<market.SecurityDocument>? get(String key) => _map[key];

  void put(String key, List<market.SecurityDocument> value) {
    if (_map.length >= maxSize) _map.remove(_map.keys.first);
    _map[key] = value;
  }

  void clear() => _map.clear();
}
