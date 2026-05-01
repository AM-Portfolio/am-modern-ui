import 'package:am_market_common/am_market_common.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';

/// Instrument details card for trade forms
class InstrumentCard extends StatefulWidget {
  const InstrumentCard({
    required this.symbolController,
    required this.selectedExchange,
    required this.selectedSegment,
    required this.onExchangeChanged,
    required this.onSegmentChanged,
    this.onInstrumentSelected,
    super.key,
  });

  final TextEditingController symbolController;
  final ExchangeTypes? selectedExchange;
  final MarketSegments? selectedSegment;
  final ValueChanged<ExchangeTypes?> onExchangeChanged;
  final ValueChanged<MarketSegments?> onSegmentChanged;
  final ValueChanged<Map<String, dynamic>>? onInstrumentSelected;

  @override
  State<InstrumentCard> createState() => _InstrumentCardState();
}

class _InstrumentCardState extends State<InstrumentCard> {
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.symbolController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.symbolController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (widget.symbolController.text.isNotEmpty && _focusNode.hasFocus) {
        _performSearch(widget.symbolController.text);
      } else {
        setState(() => _searchResults = []);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final apiService = GetIt.I<ApiService>();
      final results = await apiService.searchInstruments(query, 'UPSTOX'); // Defaulting to UPSTOX as provider
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      AppLogger.error('Error searching instruments', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.candlestick_chart, size: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Instrument',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Column(
                children: [
                  TextField(
                    controller: widget.symbolController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      labelText: 'Symbol *',
                      hintText: 'e.g., RELIANCE',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _isSearching 
                        ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
                        : null,
                      isDense: true,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  CustomDropdown<ExchangeTypes>(
                    value: widget.selectedExchange,
                    hint: 'Select Exchange',
                    items: ExchangeTypes.values
                        .map(
                          (exchange) => exchange.toSimpleDropdownItem(text: exchange.toString().split('.').last.toUpperCase()),
                        )
                        .toList(),
                    onChanged: widget.onExchangeChanged,
                    icon: Icons.account_balance,
                  ),
                  const SizedBox(height: 8),
                  CustomDropdown<MarketSegments>(
                    value: widget.selectedSegment,
                    hint: 'Select Segment',
                    items: MarketSegments.values
                        .map((segment) => segment.toSimpleDropdownItem(text: segment.toString().split('.').last.toUpperCase()))
                        .toList(),
                    onChanged: widget.onSegmentChanged,
                    icon: Icons.pie_chart,
                  ),
                ],
              ),
              if (_searchResults.isNotEmpty)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.05)),
                        itemBuilder: (context, index) {
                          final instrument = _searchResults[index];
                          return ListTile(
                            dense: true,
                            title: Text(instrument['displayName'] ?? instrument['description'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${instrument['symbol']} | ${instrument['exchange']}'),
                            onTap: () {
                              widget.onInstrumentSelected?.call(instrument);
                              setState(() => _searchResults = []);
                              _focusNode.unfocus();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
