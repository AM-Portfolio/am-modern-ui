import 'package:flutter/material.dart';
import 'package:am_design_system/shared/widgets/navigation/secondary_sidebar.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_market_ui/src/market_data/providers/market_provider.dart';

/// Market-specific sidebar using shared SecondarySidebar component
class MarketSidebar extends StatelessWidget {
  const MarketSidebar({
    required this.provider,
    super.key,
  });

  final MarketProvider provider;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = provider.selectedIndex ?? 'All Indices';
    const marketAccent = AppColors.marketAccent; // Cyan

    // Build navigation items
    final mainItems = [
      SecondarySidebarItem(
        title: 'All Indices',
        subtitle: 'Market Overview',
        icon: Icons.dashboard_rounded,
        accentColor: marketAccent,
        isSelected: selectedIndex == 'All Indices',
        onTap: () => provider.selectIndex('All Indices'),
      ),
      SecondarySidebarItem(
        title: 'Streamer',
        subtitle: 'Real-time data',
        icon: Icons.waves_rounded,
        accentColor: marketAccent,
        isSelected: selectedIndex == 'Streamer',
        onTap: () => provider.selectIndex('Streamer'),
      ),
      SecondarySidebarItem(
        title: 'Instrument Explorer',
        subtitle: 'Search instruments',
        icon: Icons.manage_search_rounded,
        accentColor: marketAccent,
        isSelected: selectedIndex == 'Instrument Explorer',
        onTap: () => provider.selectIndex('Instrument Explorer'),
      ),
      SecondarySidebarItem(
        title: 'Security Explorer',
        subtitle: 'Security details',
        icon: Icons.security_rounded,
        accentColor: marketAccent,
        isSelected: selectedIndex == 'Security Explorer',
        onTap: () => provider.selectIndex('Security Explorer'),
      ),
      SecondarySidebarItem(
        title: 'ETF Explorer',
        subtitle: 'ETF insights',
        icon: Icons.dashboard_customize_rounded,
        accentColor: marketAccent,
        isSelected: selectedIndex == 'ETF Explorer',
        onTap: () => provider.selectIndex('ETF Explorer'),
      ),
      SecondarySidebarItem(
        title: 'Price Test',
        subtitle: 'Price validation',
        icon: Icons.price_check_rounded,
        accentColor: marketAccent,
        isSelected: selectedIndex == 'Price Test',
        onTap: () => provider.selectIndex('Price Test'),
      ),
      SecondarySidebarItem(
        title: 'Market Analysis',
        subtitle: 'Detailed charts',
        icon: Icons.analytics_rounded,
        accentColor: marketAccent,
        isSelected: selectedIndex == 'Market Analysis',
        onTap: () => provider.selectIndex('Market Analysis'),
      ),
    ];

    // Build sections with dynamic indices if available
    final sections = <SecondarySidebarSection>[
      // Main navigation section
      SecondarySidebarSection(
        title: 'NAVIGATION',
        items: mainItems,
        initiallyExpanded: true,
      ),

      // Major indices section (if data available)
      if (provider.availableIndices != null &&
          provider.availableIndices!.broad.isNotEmpty)
        SecondarySidebarSection(
          title: 'MAJOR INDICES',
          icon: Icons.trending_up_rounded,
          items: provider.availableIndices!.broad.take(5).map((index) {
            return SecondarySidebarItem(
              title: index,
              subtitle: 'Live data',
              icon: Icons.show_chart_rounded,
              accentColor: marketAccent,
              isSelected: selectedIndex == index,
              onTap: () => provider.selectIndex(index),
            );
          }).toList(),
          initiallyExpanded: false,
        ),

      // System tools section
      SecondarySidebarSection(
        title: 'SYSTEM TOOLS',
        icon: Icons.settings_rounded,
        customWidget: _buildSystemTools(context),
        initiallyExpanded: true,
      ),
    ];

    return SecondarySidebar(
      title: 'Market Data',
      subtitle: 'Indices & Analytics',
      icon: Icons.show_chart_rounded,
      accentColor: marketAccent,
      width: 280,
      sections: sections,
    );
  }

  Widget _buildSystemTools(BuildContext context) {
    final isAdmin = provider.selectedIndex == 'Admin Dashboard';
    final adminColor = const Color(0xFFFF6B6B);

    return Column(
      children: [
        // Force Refresh Switch
        ListTile(
          dense: true,
          title: const Text('Force Refresh', style: TextStyle(fontSize: 13)),
          leading: Icon(
            provider.forceRefresh ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: provider.forceRefresh ? AppColors.marketAccent : Colors.grey,
          ),
          trailing: Switch(
            value: provider.forceRefresh,
            onChanged: (val) => provider.toggleForceRefresh(val),
            activeColor: AppColors.marketAccent,
          ),
          onTap: () => provider.toggleForceRefresh(!provider.forceRefresh),
        ),

        // Refresh Cookies Button
        ListTile(
          dense: true,
          title: const Text('Refresh Cookies', style: TextStyle(fontSize: 13)),
          leading: const Icon(Icons.cookie, size: 20, color: Colors.orange),
          onTap: () async {
            await provider.refreshCookies();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.error ?? 'Cookies refreshed successfully!'),
                ),
              );
            }
          },
        ),

        const SizedBox(height: 8),

        // Admin Dashboard Button
        GestureDetector(
          onTap: () => provider.selectIndex('Admin Dashboard'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isAdmin
                  ? adminColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAdmin ? adminColor : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: isAdmin ? adminColor : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: isAdmin ? adminColor : Colors.grey[700],
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
