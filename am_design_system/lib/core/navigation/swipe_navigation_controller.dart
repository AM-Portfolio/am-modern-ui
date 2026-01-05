import 'package:flutter/material.dart';

/// Represents a single navigation item in a swipeable view
class NavigationItem {
  /// Display title for this navigation item
  final String title;

  /// Subtitle or description
  final String subtitle;

  /// Icon to display in sidebar
  final IconData icon;

  /// The page widget to display
  final Widget page;

  /// Accent color for this item (usually module-specific)
  final Color accentColor;

  /// Optional badge text (e.g., count, "New")
  final String? badge;

  /// Whether this item is enabled
  final bool isEnabled;

  const NavigationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
    required this.accentColor,
    this.badge,
    this.isEnabled = true,
  });
}

/// Controller for managing swipe navigation between pages
class SwipeNavigationController extends ChangeNotifier {
  /// List of navigation items
  List<NavigationItem> _items;

  List<NavigationItem> get items => _items;

  /// PageController for the PageView
  final PageController pageController;

  /// Current active index
  int _currentIndex;

  /// Get current active index
  int get currentIndex => _currentIndex;

  /// Get current navigation item
  NavigationItem get currentItem => _items[_currentIndex];

  /// Check if can swipe to next page
  bool get canSwipeNext => _currentIndex < _items.length - 1;

  /// Check if can swipe to previous page
  bool get canSwipePrevious => _currentIndex > 0;

  SwipeNavigationController({
    required List<NavigationItem> items,
    int initialIndex = 0,
  })  : _items = items,
        _currentIndex = initialIndex,
        pageController = PageController(initialPage: initialIndex) {
    assert(items.isNotEmpty, 'Navigation items cannot be empty');
    assert(
      initialIndex >= 0 && initialIndex < items.length,
      'Initial index must be within items range',
    );
  }

  /// Update navigation items dynamically
  void updateItems(List<NavigationItem> newItems) {
    if (newItems.isEmpty) return;
    _items = newItems;
    
    // Ensure index is valid
    if (_currentIndex >= _items.length) {
      _currentIndex = _items.length - 1;
      // We might want to jump to the new valid index effectively?
    }
    
    notifyListeners();
  }

  /// Called when page changes via swipe or programmatic navigation
  void onPageChanged(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Navigate to specific index with animation
  void navigateTo(int index, {bool animate = true}) {
    if (index < 0 || index >= items.length) return;
    if (!items[index].isEnabled) return;

    if (animate) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      pageController.jumpToPage(index);
    }
  }

  /// Navigate to next page
  void next() {
    if (canSwipeNext) {
      navigateTo(_currentIndex + 1);
    }
  }

  /// Navigate to previous page
  void previous() {
    if (canSwipePrevious) {
      navigateTo(_currentIndex - 1);
    }
  }

  /// Find index by title
  int? findIndexByTitle(String title) {
    final index = items.indexWhere((item) => item.title == title);
    return index >= 0 ? index : null;
  }

  /// Navigate to page by title
  void navigateToByTitle(String title) {
    final index = findIndexByTitle(title);
    if (index != null) {
      navigateTo(index);
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
