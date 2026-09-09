import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../data/services/etf_search_service.dart';
import '../../domain/models/etf_search_result.dart';

class EtfSearchBar extends StatefulWidget {
  final Function(EtfSearchResult) onEtfSelected;

  /// Called when the clear (X) control cancels the current search text.
  final VoidCallback? onCleared;

  const EtfSearchBar({
    super.key,
    required this.onEtfSelected,
    this.onCleared,
  });

  @override
  State<EtfSearchBar> createState() => EtfSearchBarState();
}

class EtfSearchBarState extends State<EtfSearchBar> {
  final EtfSearchService _etfSearchService = EtfSearchService();
  TextEditingController? _fieldController;
  FocusNode? _fieldFocusNode;
  VoidCallback? _fieldListener;
  bool _hasText = false;

  /// Clears the field. When [notify] is true, calls [EtfSearchBar.onCleared].
  void clear({bool notify = true}) {
    final controller = _fieldController;
    if (controller == null) {
      if (notify) widget.onCleared?.call();
      return;
    }
    _clearSearch(controller, _fieldFocusNode, notify: notify);
  }

  @override
  void dispose() {
    _detachFieldListener();
    super.dispose();
  }

  void _detachFieldListener() {
    if (_fieldController != null && _fieldListener != null) {
      _fieldController!.removeListener(_fieldListener!);
    }
    _fieldController = null;
    _fieldFocusNode = null;
    _fieldListener = null;
  }

  void _attachFieldListener(
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    if (_fieldController == controller) {
      _fieldFocusNode = focusNode;
      return;
    }
    _detachFieldListener();
    _fieldController = controller;
    _fieldFocusNode = focusNode;
    _fieldListener = () {
      final hasText = controller.text.isNotEmpty;
      if (hasText != _hasText && mounted) {
        setState(() => _hasText = hasText);
      }
    };
    controller.addListener(_fieldListener!);
    _hasText = controller.text.isNotEmpty;
  }

  void _clearSearch(
    TextEditingController controller,
    FocusNode? focusNode, {
    bool notify = true,
  }) {
    controller.clear();
    focusNode?.unfocus();
    setState(() => _hasText = false);
    if (notify) widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<EtfSearchResult>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<EtfSearchResult>.empty();
            }

            if (textEditingValue.text.length < 2) {
              return const Iterable<EtfSearchResult>.empty();
            }

            return await _etfSearchService.searchEtfs(textEditingValue.text);
          },
          displayStringForOption: (EtfSearchResult option) => option.symbol,
          onSelected: (EtfSearchResult selection) {
            widget.onEtfSelected(selection);
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            _attachFieldListener(fieldTextEditingController, fieldFocusNode);

            return SizedBox(
              height: AppComponentSizes.inputHeight,
              child: TextField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search ETFs, baskets or themes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  suffixIcon: _hasText
                      ? IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => _clearSearch(
                            fieldTextEditingController,
                            fieldFocusNode,
                          ),
                        )
                      : null,
                ),
                onSubmitted: (value) {
                  if (value.contains(',')) {
                    widget.onEtfSelected(
                      EtfSearchResult(
                        symbol: value,
                        name: 'Custom List',
                        isin: value,
                      ),
                    );
                    fieldFocusNode.unfocus();
                  } else {
                    onFieldSubmitted();
                  }
                },
              ),
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<EtfSearchResult> onSelected,
            Iterable<EtfSearchResult> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: Theme.of(context).cardColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppRadii.md),
                  ),
                ),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final EtfSearchResult option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option.symbol,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${option.name}${option.marketCapCategory != null ? ' • ${option.marketCapCategory}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: option.marketCapCategory != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ModuleColors.portfolio
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  option.marketCapCategory!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: ModuleColors.portfolio,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
