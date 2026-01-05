import 'package:flutter/material.dart';

/// Mobile-optimized layout widget with bottom navigation and app bar
/// Used for mobile platforms (Android and iOS)
class MobileLayout extends StatefulWidget {
  const MobileLayout({
    required this.title,
    required this.activeNavItem,
    required this.onLogout,
    required this.onNavigate,
    required this.child,
    super.key,
    this.hideBottomNav = false,
  });
  final String title;
  final String activeNavItem;
  final VoidCallback onLogout;
  final Function(String) onNavigate;
  final Widget child;
  final bool hideBottomNav;

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int get _selectedIndex {
    switch (widget.activeNavItem) {
      case 'Portfolio':
        return 0;
      case 'Dashboard':
        return 1;
      case 'Trade':
        return 2;
      case 'Market':
        return 3;
      case 'News':
        return 4;
      default:
        return 0;
    }
  }

  void _onItemTapped(int index) {
    String navItem;
    switch (index) {
      case 0:
        navItem = 'Portfolio';
        break;
      case 1:
        navItem = 'Dashboard';
        break;
      case 2:
        navItem = 'Trade';
        break;
      case 3:
        navItem = 'Market';
        break;
      case 4:
        navItem = 'News';
        break;
      default:
        navItem = 'Portfolio';
    }
    widget.onNavigate(navItem);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: widget.child,
    bottomNavigationBar: widget.hideBottomNav
        ? null
        : BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey[600],
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Portfolio'),
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Trade'),
              BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Market'),
              BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
            ],
          ),
  );
}
