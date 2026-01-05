import 'package:flutter/material.dart';

import 'modern_datetime_picker.dart';

/// Combined Entry/Exit details card with tabs
class EntryExitCard extends StatefulWidget {
  const EntryExitCard({
    required this.entryDate,
    required this.entryPriceController,
    required this.entryQuantityController,
    required this.exitDate,
    required this.exitPriceController,
    required this.exitQuantityController,
    required this.onEntryDateChanged,
    required this.onExitDateChanged,
    required this.showExit,
    super.key,
  });

  final DateTime? entryDate;
  final TextEditingController entryPriceController;
  final TextEditingController entryQuantityController;
  final DateTime? exitDate;
  final TextEditingController exitPriceController;
  final TextEditingController exitQuantityController;
  final ValueChanged<DateTime> onEntryDateChanged;
  final ValueChanged<DateTime> onExitDateChanged;
  final bool showExit;

  @override
  State<EntryExitCard> createState() => _EntryExitCardState();
}

class _EntryExitCardState extends State<EntryExitCard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Header
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1))),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: theme.colorScheme.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.login, size: 14, color: Colors.green),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.showExit
                              ? Colors.red.withOpacity(0.1)
                              : theme.colorScheme.outline.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.logout,
                          size: 14,
                          color: widget.showExit ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Exit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: widget.showExit ? null : theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          SizedBox(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Entry Tab
                _buildEntryContent(theme),

                // Exit Tab
                if (widget.showExit)
                  _buildExitContent(theme)
                else
                  _buildDisabledContent(theme, 'Close the trade to add exit details'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryContent(ThemeData theme) => SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModernDateTimePicker(initialDateTime: widget.entryDate, onDateTimeChanged: widget.onEntryDateChanged),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.entryPriceController,
                decoration: InputDecoration(
                  labelText: 'Price *',
                  prefixIcon: const Icon(Icons.currency_rupee, size: 18),
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
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.entryQuantityController,
                decoration: InputDecoration(
                  labelText: 'Qty *',
                  prefixIcon: const Icon(Icons.numbers, size: 18),
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
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildExitContent(ThemeData theme) => SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModernDateTimePicker(initialDateTime: widget.exitDate, onDateTimeChanged: widget.onExitDateChanged),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.exitPriceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixIcon: const Icon(Icons.currency_rupee, size: 18),
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
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.exitQuantityController,
                decoration: InputDecoration(
                  labelText: 'Qty',
                  prefixIcon: const Icon(Icons.numbers, size: 18),
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
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildDisabledContent(ThemeData theme, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 32, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    ),
  );
}
