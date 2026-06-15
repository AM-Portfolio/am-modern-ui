# Mobile Navigation Bar Redesign

## Date: 2026-06-12
## Branch: feature/mobile_ui_design

## Problem
The original mobile bottom navigation bar was overcrowded with 10 items (Dashboard, Portfolio, Trade, Market, AI Chat, Lab, Analysis, Doc Intel, Subscription, Profile) squeezed into a single row. This made tapping difficult and looked visually cluttered.

## Solution
Reduced the bottom bar to **5 core tabs** with a premium floating pill design, and moved secondary items into a "More Menu" bottom sheet.

### New Bottom Bar Layout
| Position | Item | Icon |
|----------|------|------|
| 1 | Dashboard | `dashboard_rounded` |
| 2 | Portfolio | `account_balance_wallet_rounded` |
| 3 | Trade | `swap_horiz_rounded` |
| 4 | Market | `show_chart_rounded` |
| 5 | Menu | `menu_rounded` |

### "More Menu" Bottom Sheet Items
| Item | Icon | Color |
|------|------|-------|
| AI Chat | `auto_awesome_rounded` | Purple (#6C5DD3) |
| Lab | `science_rounded` | Green (#00B894) |
| Analysis | `analytics_outlined` | Blue (#0984E3) |
| Doc Intel | `psychology_outlined` | Cyan (#00D2D3) |
| Subscription | `subscriptions_rounded` | Orange (#FF9F43) |
| Profile | `person_rounded` | Light Purple (#8B7EE0) |

---

## Files Changed

### 1. [MODIFY] `am_design_system/lib/shared/widgets/navigation/global_bottom_navigation.dart`
**Complete rewrite of the GlobalBottomNavigation widget.**

#### What changed:
- **Floating Pill Design**: The bar no longer hugs the bottom edge. It now floats with 16px horizontal padding and 12px bottom padding, with a 28px border radius creating a smooth pill shape.
- **Glassmorphism Effect**: Added `BackdropFilter` with `ImageFilter.blur(sigmaX: 20, sigmaY: 20)` behind the bar, creating a frosted glass effect where content scrolls behind it.
- **Active Indicator Dot**: A glowing 3px-wide accent-colored dot appears above the active tab icon, with a matching `BoxShadow` glow effect.
- **Animated Transitions**: All state changes (icon size, colors, indicator dot width) animate smoothly over 250ms with `Curves.easeOutCubic`.
- **New `onMenuTap` Callback**: Added a dedicated callback property for when the "Menu" item is tapped, separate from `onNavigate`.
- **Removed `onProfileTap`**: Profile is now inside the "More Menu" bottom sheet, not a standalone icon on the bar.

#### Key lines:
- **Lines 36-38**: Outer `Container` with floating padding
- **Lines 39-41**: `ClipRRect` + `BackdropFilter` for glassmorphism
- **Lines 44-67**: Glass container decoration with conditional dark/light styling
- **Lines 82-91**: Menu button detection and routing to `onMenuTap`
- **Lines 130-145**: Active indicator dot with glow shadow

---

### 2. [MODIFY] `am_app/lib/features/shell/app_shell.dart`
**Reduced mobile items from 10 to 5, added "More Menu" bottom sheet.**

#### What changed:

##### New static field (Lines 32-39):
```dart
static const List<_MoreMenuItem> _moreMenuItems = [
  _MoreMenuItem(title: 'AI Chat', icon: Icons.auto_awesome_rounded, index: 4),
  _MoreMenuItem(title: 'Lab', icon: Icons.science_rounded, index: 5),
  _MoreMenuItem(title: 'Analysis', icon: Icons.analytics_outlined, index: 6),
  _MoreMenuItem(title: 'Doc Intel', icon: Icons.psychology_outlined, index: 7),
  _MoreMenuItem(title: 'Subscription', icon: Icons.subscriptions_rounded, index: 9),
  _MoreMenuItem(title: 'Profile', icon: Icons.person_rounded, index: 8),
];
```
Defines the secondary navigation items that appear in the "More Menu" bottom sheet.

##### `showMobileGlobalBar` logic (Line 178):
```diff
- final showMobileGlobalBar = !isDesktop && (_selectedIndex == 0 || _selectedIndex == 5);
+ final showMobileGlobalBar = !isDesktop;
```
Previously the bottom bar only appeared on the Dashboard and Lab tabs. Now it is always visible on mobile, which is the standard UX pattern.

##### Bottom bar items (Lines 234-252):
Replaced the 9 SidebarItems with just 5:
- Dashboard, Portfolio, Trade, Market, **Menu** (was: AI Chat, Lab, Analysis, Doc Intel, Subscription)

##### New `onMenuTap` callback (Line 236):
```dart
onMenuTap: () => _showMoreMenu(context, userId, isDark),
```
When the user taps the "Menu" tab, it opens the bottom sheet instead of navigating.

##### New `_showMoreMenu()` method (Lines 303-460):
A premium bottom sheet with:
- Rounded top corners (24px radius)
- Drag handle pill indicator
- "More" title with close button
- 3-column grid layout of secondary items
- Each item has an icon container with accent color background
- Active item is visually highlighted with a colored border

##### New `_MoreMenuItem` class (Lines 487-498):
Simple data class holding `title`, `icon`, and `index` for each secondary menu item.

---

## Desktop/Web Impact
**ZERO impact.** The desktop `GlobalSidebar` is rendered by a completely separate code path (`isDesktop` check on line 175). All 10 navigation items remain visible in the desktop sidebar exactly as before.
