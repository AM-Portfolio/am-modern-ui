import 'package:flutter/material.dart';

import '../navigation/global_sidebar.dart';
import '../navigation/sidebar_item.dart';

/// A layout component specifically designed for web interfaces
/// Includes header navigation and footer
class WebLayout extends StatelessWidget {
  /// Constructor
  const WebLayout({
    required this.child,
    required this.sidebarItems,
    super.key,
    this.title = 'AM Investment',
    this.activeNavItem = 'Dashboard',
    this.userName = 'User',
    this.userEmail,
    this.userAvatarUrl,
    this.onLogout,
    this.onNavigate,
  });

  /// The main content of the page
  final Widget child;

  /// Sidebar navigation items
  final List<SidebarItem> sidebarItems;

  /// The title to display in the header (only used for page title, not displayed)
  final String title;

  /// The currently active navigation item
  final String activeNavItem;

  /// User display name
  final String userName;

  /// User email
  final String? userEmail;

  /// User avatar URL
  final String? userAvatarUrl;

  /// Callback when logout is requested
  final VoidCallback? onLogout;

  /// Callback when navigation is requested
  final void Function(String navItem)? onNavigate;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        // Global Sidebar (Far Left)
        GlobalSidebar(
          items: sidebarItems,
          activeNavItem: activeNavItem,
          userName: userName,
          userEmail: userEmail,
          userAvatarUrl: userAvatarUrl,
          onNavigate: (navItem) {
            if (onNavigate != null) {
              onNavigate!(navItem);
            } else {
              Navigator.of(context).pushNamed('/${navItem.toLowerCase()}');
            }
          },
          onLogout: onLogout,
        ),

        // Main Content Area (Includes Sub-sidebar if present in child)
        Expanded(child: child),
      ],
    ),
  );
}
