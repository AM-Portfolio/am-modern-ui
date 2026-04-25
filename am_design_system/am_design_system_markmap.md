# am_design_system

## Purpose
- Shared Flutter package for the entire AM monorepo
- Contains all UI components, themes, navigation, and layouts
- Used by: am_trade_ui, am_portfolio_ui, am_market_ui, am_app, am_dashboard_ui
- Does NOT contain any business logic or API calls

## Dependencies
- flutter_bloc (state for ThemeCubit)
- google_fonts (typography)
- fl_chart (charts)
- glassmorphism (glass effects)
- lottie (animations)
- flutter_animate (micro-animations)
- hive + hive_flutter (browser cache / local storage)
- audioplayers (sound feedback)
- shared_preferences (persistent settings)
- am_common (shared utilities, logging)

## Barrel File
- lib/am_design_system.dart
- Exports ~60+ components
- Everything public is imported via `package:am_design_system/am_design_system.dart`

## CORE Layer (lib/core)

### Theme (lib/core/theme)
- app_theme.dart
  - AppTheme.darkTheme (primary theme — deep navy/purple palette)
  - AppTheme.lightTheme
  - Uses Google Fonts (Inter)
- app_colors.dart
  - AppColors.primary = #6C5DD3 (Purple)
  - AppColors.tradeAccent = #4ADE80 (Green)
  - AppColors.marketAccent = #06b6d4 (Cyan)
  - AppColors.portfolioAccent = #FFA500 (Orange)
  - AppColors.profit = #00B894 (Green)
  - AppColors.loss = #FF7675 (Red/Salmon)
  - AppColors.darkBackground = #1A1A2E
  - multiColors[] — 8-color palette for charts/tags
  - Helper: profitLossColor(double value)
  - Helper: winRateColor(double rate)
- app_typography.dart
  - AppTypography — text styles for headings, body, caption
- app_glassmorphism.dart / v2
  - Glassmorphism containers with blur + transparency
  - Used for cards, modals, sidebar panels
- app_animations.dart
  - Standard animation durations and curves
- am_chart_theme.dart
  - Chart color palette (synced with fl_chart)
- ThemeCubit (core/theme/cubit)
  - States: ThemeLight / ThemeDark
  - Persists selection via ThemeRepository (shared_preferences)

### Module System (lib/core/module)
- module_type.dart → ModuleType enum
  - dashboard, market, trade, portfolio, news, admin, other
  - Each has: title, subtitle, icon, accentColor
- module_config.dart → ModuleConfig class
  - moduleId, title, subtitle, icon, accentColor
  - routes (List of ModuleRoute)
  - requiresAuth, isEnabled, showInNavigation, order
  - ModuleColors class
    - market = #06b6d4 Cyan
    - trade = #8b5cf6 Purple
    - portfolio = #ec4899 Pink
    - dashboard = #3b82f6 Blue
    - analytics = #10b981 Green
    - reports = #f59e0b Amber
- i_module.dart → IModule abstract class
  - moduleId (String)
  - config (ModuleConfig)
  - build(BuildContext, ModuleContext) → Widget
  - configure(ModuleContext) → Future (async setup)
  - dispose()
  - routes (Map<String, WidgetBuilder>)
  - requiresAuth (bool)
  - isEnabled (bool)
- module_context.dart → ModuleContext
  - Shared context passed to every module on init
- module_color_provider.dart
  - Riverpod provider for module accent color

### Navigation Logic (lib/core/navigation)
- swipe_navigation_controller.dart
  - NavigationItem class (title, subtitle, icon, page widget, accentColor, badge)
  - SwipeNavigationController extends ChangeNotifier
    - Wraps Flutter PageController
    - navigateTo(index) — animated
    - next() / previous()
    - findIndexByTitle(String) → int?
    - navigateToByTitle(String)
    - onPageChanged(int) — syncs sidebar + page
    - updateItems(List) — dynamic tab update

### Cache (lib/core/cache)
- cache_service.dart → CacheService
  - Uses Hive (browser localStorage equivalent)
  - Box name: 'am_cache'
  - get<T>(key) → TTL-aware retrieval
  - set<T>(key, value, {ttl}) → stores with optional expiry
  - clear(key) / clearAll()
  - Must call init() on app startup
- cache_keys.dart → CacheKeys constants
- cache_provider.dart → Riverpod provider for CacheService

### Utils (lib/core/utils)
- common_logger.dart — structured logging wrapper
- device_utils.dart — screen size helpers (isMobile, isTablet, isDesktop)
- validators.dart — form field validation functions
- conditional_mouse_region.dart — hover support (web only)

### Constants (lib/core/constants)
- app_constants.dart — sizes, spacing, border radii, breakpoints

### Contracts (lib/core/contracts)
- design_contract.dart — base interface contracts

## SHARED Layer (lib/shared)

### Scaffold (shared/widgets/scaffold)
- unified_sidebar_scaffold.dart → UnifiedSidebarScaffold
  - THE main layout used by ALL module screens
  - Props: navigationItems, body, primaryAction, moduleType
  - Renders: GlobalSidebar (left) + SecondarySidebar + SwipeablePageView
  - Handles: collapse/expand, responsive breakpoints

### Navigation Widgets (shared/widgets/navigation)
- global_sidebar.dart → GlobalSidebar
  - Top-level module switcher (Dashboard, Market, Trade, Portfolio icons)
- secondary_sidebar.dart → SecondarySidebar
  - Per-module tab list (e.g., Portfolios, Holdings, Calendar...)
  - Icon-only mode when collapsed
- sidebar_nav_item.dart → SidebarNavItem
  - Single item in secondary sidebar with active state
- sidebar_primary_action.dart → SidebarPrimaryAction
  - The big CTA button (e.g., "Add Trade", "Add Portfolio")
- sidebar_selector.dart → SidebarSelector
  - Dropdown inside sidebar (e.g., portfolio selector)
- swipeable_page_view.dart → SwipeablePageView
  - Flutter PageView wrapper, synced with SwipeNavigationController
- global_bottom_navigation.dart — mobile bottom nav bar
- module_bottom_navigation.dart — per-module mobile nav
- step_indicator.dart — wizard progress steps
- wizard_navigation.dart — prev/next for multi-step forms

### Selectors (shared/widgets/selectors)
- shared_portfolio_selector.dart → SharedPortfolioSelector
  - Dropdown for selecting active portfolio (used in trade & portfolio modules)
- selectors.dart — barrel for all selectors

### Cards (shared/widgets/cards)
- app_card.dart → AppCard — base card with glassmorphism
- investment_card.dart → InvestmentCard — rich investment data card
- am_stat_card.dart → AmStatCard — metric stat display card

### Display (shared/widgets/display)
- glass_card.dart → GlassCard — frosted glass container
- pill_selector.dart → PillSelector — horizontal pill/chip tabs
- architecture_card.dart — architecture display card
- interactive_background.dart — animated particle background

### Inputs & Controls (shared/widgets/inputs)
- app_text_field.dart → AppTextField — themed text input
- glass_text_field.dart → GlassTextField — glassmorphism input
- app_segmented_control.dart — toggle segments
- custom_dropdown.dart → CustomDropdown — styled dropdown
- multi_select_dropdown.dart → MultiSelectDropdown — checkbox dropdown
- dropdown_styles.dart — shared dropdown styling
- compact_date_range_picker.dart — inline date range picker

### Buttons (shared/widgets/buttons)
- app_button.dart → AppButton — primary/secondary variants
- glossy_button.dart → GlossyButton — glassmorphism CTA
- reset_button.dart → ResetButton — filter reset

### Layouts (shared/widgets/layouts)
- web_layout.dart → WebLayout — desktop-optimized layout
- mobile_layout.dart → MobileLayout — mobile-optimized layout
- platform_widget.dart → PlatformWidget — renders different widget per platform

### Containers (shared/widgets/containers)
- module_container.dart → ModuleContainer — themed container per module
- selector_container.dart → SelectorContainer

### Heatmap Engine (shared/widgets/heatmap)
- universal_heatmap.dart → UniversalHeatmap — main heatmap entry point
- heatmap_config.dart → HeatmapConfig — size, colors, interaction config
- configs/
  - display_config.dart — rendering options
  - interaction_config.dart — tap/hover callbacks
  - layout_config.dart — grid dimensions
  - selector_config.dart — data source selection
  - visual_config.dart — colors, gradients
- core/heatmap_selector_core.dart — data selection logic
- templates/
  - web_heatmap_defaults.dart — desktop heatmap presets
  - mobile_heatmap_defaults.dart — mobile heatmap presets
- loaders/heatmap_skeleton_loader.dart — loading skeleton

### Calendar (shared/widgets/calendar)
- universal_calendar/
  - universal_calendar_widget.dart → UniversalCalendarWidget
  - calendar_types.dart — CalendarCardType (pnlSummary, tradeMetrics, winLossRatio, riskReward)
  - types.dart — DateSelection, DateFilterMode, DateRange
  - card_types.dart — CalendarCardConfig (type, size, layout, theme)
  - data_provider.dart — CalendarDataProvider interface
- year_calendar/
  - year_calendar.dart → YearCalendar data model
  - year_calendar_widget.dart → full year grid view

### Charts (shared/widgets/charts)
- chart_factory.dart → ChartFactory
  - Builds fl_chart instances from config
  - Supports: Line, Bar, Pie, Scatter, Area charts
- chart_types.dart → ChartType enum

### Tables (shared/widgets/tables)
- sortable_table.dart → SortableTable — column-sortable data table
- adaptive_data_table.dart → AdaptiveDataTable — responsive (collapses on mobile)

### Portfolio Charts (shared/widgets/portfolio_overview)
- animated_sector_donut_chart.dart — animated donut for sector allocation
- animated_market_cap_chart.dart — market cap breakdown chart
- models/portfolio_overview_data.dart — data model for charts

### Feedback & Loading (shared/widgets/feedback)
- shimmer_loading.dart → ShimmerLoading — skeleton loader
- error_widget.dart → AppErrorWidget — styled error display
- animated_page_transition.dart — page enter/exit animation
- animated_list_item.dart — list item stagger animation
- animated_login_elements.dart — login screen animations

### Filters (shared/widgets/filters)
- am_filter_panel.dart → AmFilterPanel — reusable filter panel shell

### Shared Models (shared/models)
- user.dart → User model (userId, name, email, avatar)
- holding.dart → Holding model (shared across portfolio & trade modules)
- heatmap.dart — HeatmapData, HeatmapCell

### Shared Cubits (shared/cubits)
- heatmap/ — HeatmapCubit for managing heatmap data state

## How Modules Use This Package

### Step 1 — Import
```dart
import 'package:am_design_system/am_design_system.dart';
```

### Step 2 — Wrap with UnifiedSidebarScaffold
```dart
UnifiedSidebarScaffold(
  moduleType: ModuleType.trade,
  navigationItems: [NavigationItem(...)],
  body: SwipeablePageView(...),
  primaryAction: SidebarPrimaryAction(label: 'Add Trade', onTap: ...),
)
```

### Step 3 — Use SwipeNavigationController
```dart
final controller = SwipeNavigationController(items: navItems);
controller.navigateTo(2); // Jump to Calendar tab
```

### Step 4 — Use ThemeCubit for dark/light toggle
```dart
context.read<ThemeCubit>().toggleTheme();
```

### Step 5 — Use AppColors for consistent colors
```dart
AppColors.profitLossColor(trade.pnl) // returns green or red
ModuleColors.trade // #8b5cf6 purple — trade module accent
```

## Key Design Decisions
- Single source of truth for ALL colors via AppColors
- Module system enforces IModule contract for pluggable architecture
- CacheService uses Hive (browser localStorage) — survives page refresh
- UnifiedSidebarScaffold is the ONLY scaffold — no module builds its own chrome
- SwipeNavigationController is a ChangeNotifier — works with Provider/ListenableBuilder
- Glassmorphism is available in 2 versions (v1 simpler, v2 advanced with blur)
- Navigation is always sidebar-first (web), bottom-nav (mobile)
