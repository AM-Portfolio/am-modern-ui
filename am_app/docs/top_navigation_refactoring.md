# Top Navigation Refactoring

## Date: 2026-06-12
## Branch: feature/mobile_ui_design

## Problem
After redesigning the Global Bottom Navigation Bar (Dashboard, Portfolio, Trade, Market, Menu) to a floating pill design, there was a UX conflict: local modules (Portfolio, Trade) and the generic `UnifiedSidebarScaffold` (Market) still had their own Bottom Navigation Bars. This resulted in a "double bottom navigation bar" layout, confusing users and wasting screen space.

## Solution
We moved all module-specific local navigation from the bottom of the screen to the **TOP** of the screen (as horizontal, scrollable TabBars placed within or just below the AppBar). The bottom of the screen is now completely reserved for the Global Navigation.

### 1. Portfolio Module (`portfolio_mobile_screen.dart`)
- **Removed**: The local `bottomNavigationBar`.
- **Added**: A scrollable pill-style `TabBar` at the top of the main `Column`.
- **Added**: A top header row that prominently displays the Portfolio Title and a trailing "Menu" icon button (to open the "Switch Portfolio" bottom sheet).

### 2. Trade Module (`trade_mobile_screen.dart`)
- **Removed**: The local `_buildBottomNavigationBar` logic.
- **Added**: A scrollable tab bar injected into the `AppBar`'s `bottom` (PreferredSize) property.
- **Updated Action**: The "More" action (which opens the Journal/Options bottom sheet) was moved to a standard `IconButton` in the `AppBar` `actions` list.
- **Bug Fix**: Fixed a bug where disabled tabs silently absorbed taps. They now correctly trigger `_onViewChanged` to show the user a helpful Snackbar message ("Please select a portfolio first") if tapped while locked.

### 3. Market Module & Unified Scaffold (`unified_sidebar_scaffold.dart`)
- **Removed**: The local `bottomNavigationBar` in the mobile layout fallback.
- **Added**: A dynamic top `TabBar` built inside the mobile `AppBar`'s `bottom` property.
- **Impact**: Any feature utilizing `UnifiedSidebarScaffold` (such as Market Analysis, Developers Dashboard) now automatically inherits sleek top navigation instead of an overlapping bottom nav bar.

## Result
A much cleaner, professional user interface.
- **Bottom**: Global Shell Navigation only.
- **Top**: Contextual Module Navigation only.
- **Design Language**: Top tabs use consistent glassmorphic, rounded-pill styling matching the new AM UI design tokens.
