import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:go_router/go_router.dart';

class CommandItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final VoidCallback onSelected;

  CommandItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.onSelected,
  });
}

class AmCommandPalette extends StatefulWidget {
  final List<CommandItem> globalItems;

  const AmCommandPalette({super.key, required this.globalItems});

  static Future<void> show(BuildContext context, {required List<CommandItem> items}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Command Palette',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: AmCommandPalette(globalItems: items),
        );
      },
    );
  }

  @override
  State<AmCommandPalette> createState() => _AmCommandPaletteState();
}

class _AmCommandPaletteState extends State<AmCommandPalette> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<CommandItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.globalItems;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _selectedCategory = 'All';

  void _applyFilters() {
    final query = _controller.text.toLowerCase();
    
    setState(() {
      _filteredItems = widget.globalItems.where((item) {
        // 1. Category Filter
        final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
        if (!matchesCategory) return false;

        // 2. Text Filter
        if (query.isEmpty) return true;
        return item.title.toLowerCase().contains(query) ||
               item.subtitle.toLowerCase().contains(query) ||
               item.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  Widget _buildHighlightedText(String text, String query, TextStyle style, Color highlightColor) {
    if (query.isEmpty) return Text(text, style: style);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int startIndex = lowerText.indexOf(lowerQuery);
    if (startIndex == -1) return Text(text, style: style);

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, startIndex + query.length),
            style: style.copyWith(
              color: highlightColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(startIndex + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 500),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: context.colors.textSecondary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            onChanged: (_) => _applyFilters(),
                            style: TextStyle(
                              fontSize: 18,
                              color: context.colors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search markets, portfolios, trades...',
                              hintStyle: TextStyle(color: context.colors.textSecondary.withOpacity(0.5)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (query.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.close, color: context.colors.textSecondary, size: 20),
                            onPressed: () {
                              _controller.clear();
                              _applyFilters();
                            },
                          ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: context.colors.textSecondary,
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Cancel'),
                        )
                      ],
                    ),
                  ),
                  // Category Filter Pills
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Market', 'Portfolio', 'Trade', 'News', 'Action'].map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => _onCategorySelected(category),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? context.colors.actionPrimaryBg.withOpacity(0.15) 
                                      : context.colors.surface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? context.colors.actionPrimaryBg : context.colors.border.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? context.colors.textPrimary : context.colors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: context.colors.border.withOpacity(0.5)),
                  
                  // Results List
                  Flexible(
                    child: _filteredItems.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 48, color: context.colors.textSecondary.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found for "$query"',
                                  style: TextStyle(color: context.colors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  item.onSelected();
                                },
                                hoverColor: context.colors.actionPrimaryBg.withOpacity(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: context.colors.border.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(item.icon, size: 20, color: context.colors.textPrimary),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildHighlightedText(
                                              item.title, 
                                              query, 
                                              TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                                              context.colors.statusInfo
                                            ),
                                            const SizedBox(height: 2),
                                            _buildHighlightedText(
                                              item.subtitle, 
                                              query, 
                                              TextStyle(fontSize: 12, color: context.colors.textSecondary),
                                              context.colors.statusInfo
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: context.colors.border.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          item.category,
                                          style: TextStyle(fontSize: 10, color: context.colors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}





