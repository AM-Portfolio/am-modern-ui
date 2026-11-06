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

  /// Bumped on [updateItems] so PageView can rebuild when titles stay the same
  /// but page widgets were replaced (e.g. new portfolio id injected).
  int _itemsRevision = 0;

  int get itemsRevision => _itemsRevision;

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

  /// True while a programmatic jump/animation owns the PageView.
  bool get isProgrammaticNavigation => _isProgrammaticNavigation;

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

  /// Update navigation items dynamically, preserving selection by title.
  void updateItems(List<NavigationItem> newItems) {
    if (newItems.isEmpty) return;
    final oldTitle = _items[_currentIndex].title;
    _items = newItems;
    _itemsRevision++;
    final byTitle = newItems.indexWhere((e) => e.title == oldTitle);
    final nextIndex = byTitle >= 0
        ? byTitle
        : _currentIndex.clamp(0, newItems.length - 1);
    _currentIndex = nextIndex;
    if (pageController.hasClients) {
      final page = pageController.page?.round() ?? nextIndex;
      if (page != nextIndex) {
        pageController.jumpToPage(nextIndex);
      }
    }
    notifyListeners();
  }

  int? _targetIndex;
  bool _isProgrammaticNavigation = false;
  int _navGeneration = 0;

  /// Called when page changes via swipe or programmatic navigation
  void onPageChanged(int index) {
    if (_isProgrammaticNavigation &&
        _targetIndex != null &&
        index != _targetIndex) {
      // Ignore intermediate page transition callbacks while navigating programmatically
      return;
    }
    _isProgrammaticNavigation = false;
    _targetIndex = null;
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  bool _pageDesynced(int index) {
    if (!pageController.hasClients) return false;
    final page = pageController.page?.round();
    return page != null && page != index;
  }

  void _clearProgrammaticFlagsIfCurrent(int gen) {
    if (gen != _navGeneration) return;
    _isProgrammaticNavigation = false;
    _targetIndex = null;
  }

  /// Navigate to a specific index.
  ///
  /// Defaults to [animate] `false` (instant jump) so sidebar / URL-driven
  /// taps across modules cannot stack overlapping `animateToPage` Futures.
  /// Pass `animate: true` for adjacent gesture swipes ([next]/[previous]).
  void navigateTo(int index, {bool animate = false}) {
    if (index < 0 || index >= items.length) return;
    if (!items[index].isEnabled) return;

    final alreadySelected = index == _currentIndex;
    if (alreadySelected && !_pageDesynced(index)) return;

    final gen = ++_navGeneration;
    _targetIndex = index;
    _currentIndex = index;
    notifyListeners();

    if (!pageController.hasClients) {
      _clearProgrammaticFlagsIfCurrent(gen);
      return;
    }

    final currentPage = pageController.page?.round() ?? _currentIndex;
    final distance = (index - currentPage).abs();

    if (distance > 1 || !animate || alreadySelected) {
      // Jump for multi-step moves, sidebar taps (animate:false), or desync recovery.
      _isProgrammaticNavigation = true;
      pageController.jumpToPage(index);
      _clearProgrammaticFlagsIfCurrent(gen);
    } else {
      _isProgrammaticNavigation = true;
      pageController
          .animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          )
          .then((_) {
            _clearProgrammaticFlagsIfCurrent(gen);
          })
          .catchError((_) {
            _clearProgrammaticFlagsIfCurrent(gen);
          });
    }
  }

  /// Navigate to next page
  void next() {
    if (canSwipeNext) {
      navigateTo(_currentIndex + 1, animate: true);
    }
  }

  /// Navigate to previous page
  void previous() {
    if (canSwipePrevious) {
      navigateTo(_currentIndex - 1, animate: true);
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
