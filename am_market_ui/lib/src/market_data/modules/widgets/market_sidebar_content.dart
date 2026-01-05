import 'package:flutter/material.dart';
import '../../providers/market_provider.dart';

import 'package:am_design_system/am_design_system.dart';

/// Market sidebar navigation content - Standardized with SidebarNavItem
class MarketSidebarContent extends StatefulWidget {
  const MarketSidebarContent({
    required this.provider,
    super.key,
  });

  final MarketProvider provider;

  @override
  State<MarketSidebarContent> createState() => _MarketSidebarContentState();
}

class _MarketSidebarContentState extends State<MarketSidebarContent> {
  String? _hoveredItem;

  @override
  void initState() {
    super.initState();
    CommonLogger.methodEntry('initState', tag: 'MarketSidebarContent');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.provider.availableIndices == null) {
        CommonLogger.info('Triggering initial loadIndices', tag: 'MarketSidebarContent');
        widget.provider.loadIndices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    CommonLogger.methodEntry('build', tag: 'MarketSidebarContent');
    final selectedIndex = widget.provider.selectedIndex ?? 'All Indices';
    const accentColor = Color(0xFF06b6d4); // Cyan for Market section

    return Column(
      children: [
        // Main Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(4),
            children: [
              _buildNavItem(
                'All Indices', 
                Icons.dashboard_rounded, 
                'Market Overview',
                selectedIndex == 'All Indices',
                accentColor,
              ),
              _buildNavItem(
                'Streamer', 
                Icons.waves_rounded, 
                'Real-time data',
                selectedIndex == 'Streamer',
                accentColor,
              ),
              _buildNavItem(
                'Instrument Explorer', 
                Icons.manage_search_rounded, 
                'Search instruments',
                selectedIndex == 'Instrument Explorer',
                accentColor,
              ),
              _buildNavItem(
                'Security Explorer', 
                Icons.security_rounded, 
                'Security details',
                selectedIndex == 'Security Explorer',
                accentColor,
              ),
              _buildNavItem(
                'ETF Explorer', 
                Icons.dashboard_customize_rounded, 
                'ETF insights',
                selectedIndex == 'ETF Explorer',
                accentColor,
              ),
              _buildNavItem(
                'Price Test', 
                Icons.price_check_rounded, 
                'Price validation',
                selectedIndex == 'Price Test',
                accentColor,
              ),
              _buildNavItem(
                'Market Analysis', 
                Icons.analytics_rounded, 
                'Detailed charts',
                selectedIndex == 'Market Analysis',
                accentColor,
              ),
              
              if (widget.provider.availableIndices != null) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('MAJOR INDICES'),
                ...widget.provider.availableIndices!.broad.take(5).map((index) => 
                  _buildNavItem(
                    index, 
                    Icons.trending_up_rounded, 
                    'Live Index Data',
                    selectedIndex == index, 
                    accentColor,
                    isSmall: true,
                  )
                ).toList(),
              ],
            ],
          ),
        ),

        // Footer Section
        _buildFooter(selectedIndex == 'Admin Dashboard'),
      ],
    );
  }

  Widget _buildNavItem(
    String title, 
    IconData icon, 
    String subtitle, 
    bool isSelected, 
    Color accentColor,
    {bool isSmall = false}
  ) {
    return SidebarNavItem<String>(
      icon: icon,
      title: title,
      subtitle: isSmall ? '' : subtitle,
      value: title,
      groupValue: isSelected ? title : '',
      onChanged: (val) {
        CommonLogger.userAction('Select Menu Item: $val', tag: 'MarketSidebarContent');
        widget.provider.selectIndex(val);
      },
      isEnabled: true,
      isCompact: false,
      isCondensed: isSmall,
      accentColor: accentColor,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildFooter(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM TOOLS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildAdminPill(isAdmin),
        ],
      ),
    );
  }

  Widget _buildAdminPill(bool isAdmin) {
    final isHovered = _hoveredItem == 'Admin';
    final adminColor = const Color(0xFFFF6B6B);

    return MouseRegion(
      onEnter: (_) { if (mounted) setState(() => _hoveredItem = 'Admin'); },
      onExit: (_) { if (mounted) setState(() => _hoveredItem = null); },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.provider.selectIndex("Admin Dashboard"),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isAdmin 
                ? adminColor.withValues(alpha: 0.2) 
                : (isHovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAdmin ? adminColor : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: isAdmin ? adminColor : Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: isAdmin ? adminColor : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


