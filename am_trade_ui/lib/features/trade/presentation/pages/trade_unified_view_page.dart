import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:am_market_ui/am_market_ui.dart';
import '../journal/pages/journal_web_page.dart';

class TradeUnifiedViewPage extends ConsumerStatefulWidget {
  final String userId;

  const TradeUnifiedViewPage({required this.userId, super.key});

  @override
  ConsumerState<TradeUnifiedViewPage> createState() => _TradeUnifiedViewPageState();
}

class _TradeUnifiedViewPageState extends ConsumerState<TradeUnifiedViewPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Default to Chart
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _scrollToJournal() {
    _tabController.animateTo(2); // Switch to Journal tab
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar: Trade List (Placeholder for now, simplified)
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(right: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Trades", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 15, // Dummy count
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index % 2 == 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          child: Icon(
                            index % 2 == 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            color: index % 2 == 0 ? Colors.green : Colors.red,
                            size: 16,
                          ),
                        ),
                        title: Text("TCS Trade #${index + 1}"),
                        subtitle: Text("Sep 12, 2025 • 09:30 AM"),
                        trailing: Text(
                          index % 2 == 0 ? "+₹111" : "-₹16",
                          style: TextStyle(
                            color: index % 2 == 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Header / Stats Bar (Keep it compact)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(bottom: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Text("TCS", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      _buildStatChip(context, "Net P&L", "-₹16", Colors.red),
                      const SizedBox(width: 12),
                      _buildStatChip(context, "ROI", "(1.20%)", Colors.orange),
                      const Spacer(),
                      // TABS
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                          tabs: const [
                            Tab(text: "Stats & Strategy"),
                            Tab(text: "Chart"),
                            Tab(text: "Journal & Notes"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Body
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe on web
                    children: [
                      // Tab 1: Stats
                      const Center(child: Text("Detailed Statistics & Strategy Info Here")),
                      
                      // Tab 2: Chart (Reusing the Fullscreen Widget)
                      Consumer(
                        builder: (context, ref, child) {
                          final config = ref.watch(marketAnalysisChartConfigProvider);
                          return TradingViewChartWidget(config: config);
                        }
                      ),

                      // Tab 3: Journal
                      JournalWebPage(userId: widget.userId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatChip(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
