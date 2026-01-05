import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/market_provider.dart';

import 'package:am_design_system/am_design_system.dart';

class AppSidebar extends StatelessWidget {
  final MarketProvider provider;
  final bool isAllIndices;
  final bool isStreamer;
  final bool isInstruments;
  final bool isSecurityExplorer;
  final bool isPriceTest;

  const AppSidebar({
    super.key,
    required this.provider,
    required this.isAllIndices,
    required this.isStreamer,
    required this.isInstruments,
    required this.isSecurityExplorer,
    required this.isPriceTest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isAdmin = provider.selectedIndex == "Admin Dashboard";

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(4, 0),
          )
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                // Market Overview Option
                _buildMenuItem(context, "All Indices", Icons.dashboard_rounded, Colors.blueAccent, isAllIndices, customLabel: "All Indices (Overview)"),

                const SizedBox(height: 5),

                // Streamer Option
                _buildMenuItem(context, "Streamer", Icons.waves, Colors.purpleAccent, isStreamer),

                const SizedBox(height: 5),

                // Instrument Explorer Option
                _buildMenuItem(context, "Instrument Explorer", Icons.search, Colors.tealAccent, isInstruments),

                const SizedBox(height: 5),

                // Security Explorer Option
                _buildMenuItem(context, "Security Explorer", Icons.security, Colors.redAccent, isSecurityExplorer),

                const SizedBox(height: 5),

                // ETF Explorer Option (Added)
                _buildMenuItem(context, "ETF Explorer", Icons.dashboard_customize, Colors.indigoAccent, provider.selectedIndex == "ETF Explorer"),

                const SizedBox(height: 5),

                // Price Test Option (Added)
                _buildMenuItem(context, "Price Test", Icons.price_check, Colors.amberAccent, isPriceTest),

                const SizedBox(height: 5),

                // Market Analysis Option (Added)
                _buildMenuItem(context, "Market Analysis", Icons.analytics, Colors.cyanAccent, provider.selectedIndex == "Market Analysis"),

                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text("INDICES", style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),

                if (provider.availableIndices != null) ...[
                  // Broad Market Dropdown
                  if (provider.availableIndices!.broad.isNotEmpty)
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent), 
                      child: ExpansionTile(
                        leading: const Icon(Icons.public, color: Colors.greenAccent),
                        title: const Text("Broad Market", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        iconColor: Colors.greenAccent,
                        collapsedIconColor: Colors.grey,
                        children: provider.availableIndices!.broad.map((idx) => _buildSubMenuItem(context, idx)).toList(),
                      ),
                    ),

                  // Sectoral Indices Dropdown
                  if (provider.availableIndices!.sector.isNotEmpty)
                     Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(Icons.pie_chart, color: Colors.orangeAccent),
                        title: const Text("Sectoral Indices", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        iconColor: Colors.orangeAccent,
                        collapsedIconColor: Colors.grey,
                        children: provider.availableIndices!.sector.map((idx) => _buildSubMenuItem(context, idx)).toList(),
                      ),
                     ),
                ]
              ],
            ),
          ),

          
          // System Tools Section (Bottom of Sidebar)
          Divider(color: theme.dividerTheme.color ?? Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("SYSTEM TOOLS", style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          // Force Refresh Toggle (Relocated)
          ListTile(
            title: Text("Force Refresh", style: TextStyle(fontWeight: FontWeight.w500, color: theme.textTheme.bodyMedium?.color)),
            leading: Icon(
              provider.forceRefresh ? Icons.check_box : Icons.check_box_outline_blank, 
              color: provider.forceRefresh ? theme.primaryColor : Colors.grey
            ),
            trailing: Switch(
              value: provider.forceRefresh,
              onChanged: (val) => provider.toggleForceRefresh(val),
              activeColor: theme.primaryColor,
            ),
            onTap: () => provider.toggleForceRefresh(!provider.forceRefresh),
          ),
          ListTile(
            title: Text("Refresh Cookies", style: TextStyle(fontWeight: FontWeight.w500, color: theme.textTheme.bodyMedium?.color)),
            leading: const Icon(Icons.cookie, color: Colors.orange),
            onTap: () async {
                CommonLogger.info("Refresh Cookies requested", tag: "HomePage");

                await provider.refreshCookies();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error ?? "Cookies refreshed successfully!"))
                );
            },
          ),
          const SizedBox(height: 10),
          // Admin Dashboard integrated navigation
          _buildMenuItem(context, "Admin Dashboard", Icons.admin_panel_settings, Colors.red, isAdmin, customLabel: "Admin Dashboard"),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String id, IconData icon, Color color, bool isSelected, {String? customLabel}) {
     final theme = Theme.of(context);
     final textColor = isSelected ? color : theme.textTheme.bodyMedium?.color;

     return AnimatedListItem(
       isSelected: isSelected,
       selectedColor: color.withOpacity(0.15),
       hoverColor: color.withOpacity(0.08),
       borderRadius: BorderRadius.circular(10),
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
       onTap: () => provider.selectIndex(id),
       child: Row(
         children: [
           Icon(icon, color: color),
           const SizedBox(width: 12),
           Expanded(
             child: Text(
               customLabel ?? id,
               style: TextStyle(
                 fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                 color: textColor,
               ),
             ),
           ),
         ],
       ),
     );
  }

  Widget _buildSubMenuItem(BuildContext context, String id) {
    final isSelected = provider.selectedIndex == id;
    final theme = Theme.of(context);

    return AnimatedListItem(
      isSelected: isSelected,
      selectedColor: Colors.blueAccent.withOpacity(0.12),
      hoverColor: Colors.blueAccent.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.only(left: 32, right: 16, top: 8, bottom: 8),
      onTap: () => provider.selectIndex(id),
      child: Text(
        id,
        style: TextStyle(
          fontSize: 13,
          color: isSelected ? Colors.blueAccent : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

}
