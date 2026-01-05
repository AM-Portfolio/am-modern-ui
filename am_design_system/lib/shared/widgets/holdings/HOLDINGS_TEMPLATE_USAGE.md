# Holdings Template Architecture Usage Guide

## Overview

The Holdings Template Architecture provides a flexible, reusable system for displaying portfolio holdings across web and mobile platforms. It follows the same pattern as the Heatmap template system.

## Architecture Components

### 1. Core State Management (`HoldingsSelectorCore`)
- Manages sorting, filtering, and display preferences
- Independent of UI implementation
- Notifies listeners on state changes

### 2. Display Configuration (`HoldingsDisplayConfig`)
- Web, mobile, and minimal presets
- Controls which features are visible
- Customizable for specific use cases

### 3. Layout Builders
- **TableLayoutBuilder**: Web-optimized table view
- **CardLayoutBuilder**: Mobile-optimized card view
- Follows strategy pattern for different layouts

### 4. Display Template (`HoldingsDisplayTemplate`)
- Coordinates layout builders
- Handles loading, error, and empty states
- Platform-agnostic rendering

### 5. Template Factory (`HoldingsTemplateFactory`)
- Creates display, selector, and layout components
- Supports minimal, compact, full, and adaptive templates

### 6. Universal Widget (`UniversalHoldingsWidget`)
- All-in-one component with Riverpod integration
- Automatic data fetching and state management

## Usage Examples

### 1. Simple Web Implementation

```dart
import 'package:flutter/material.dart';
import 'package:todo_apackage:am_portfolio_package:am_design_system/am_design_system.dart';

class SimpleHoldingsPage extends StatelessWidget {
  const SimpleHoldingsPage({required this.userId, super.key});
  
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Holdings')),
      body: UniversalHoldingsWidget(
        userId: userId,
        config: HoldingsDisplayConfig.web(),
        templateType: HoldingsTemplateType.full,
      ),
    );
  }
}
```

### 2. Mobile Dashboard Widget

```dart
UniversalHoldingsWidget(
  userId: userId,
  portfolioId: portfolioId,
  config: HoldingsDisplayConfig.minimal(),
  templateType: HoldingsTemplateType.compact,
  title: 'Top Holdings',
)
```

### 3. Adaptive Template (Auto-responsive)

```dart
UniversalHoldingsWidget(
  userId: userId,
  config: HoldingsDisplayConfig.web(), // Uses web features
  templateType: HoldingsTemplateType.adaptive, // Adapts to screen size
  onHoldingTap: (holding) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HoldingDetailsPage(holding: holding),
      ),
    );
  },
)
```

### 4. Custom Configuration

```dart
final customConfig = HoldingsDisplayConfig(
  showSummary: true,
  showPagination: true,
  showSearch: true,
  showSortControls: true,
  showViewModeSelector: true,
  itemsPerPage: 50,
  defaultViewMode: HoldingsViewMode.table,
  enableExport: true,
);

UniversalHoldingsWidget(
  userId: userId,
  config: customConfig,
  templateType: HoldingsTemplateType.full,
  title: 'Portfolio Analysis',
)
```

### 5. Programmatic Template Construction

For advanced use cases, you can use the factory directly:

```dart
class CustomHoldingsView extends ConsumerStatefulWidget {
  const CustomHoldingsView({required this.userId, super.key});
  
  final String userId;

  @override
  ConsumerState<CustomHoldingsView> createState() => _CustomHoldingsViewState();
}

class _CustomHoldingsViewState extends ConsumerState<CustomHoldingsView> {
  late HoldingsSelectorCore _core;

  @override
  void initState() {
    super.initState();
    _core = HoldingsSelectorCore(
      initialViewMode: HoldingsViewMode.table,
      onFiltersChanged: _handleFilterChange,
    );
  }

  void _handleFilterChange({
    HoldingsSortBy? sortBy,
    // ... other parameters
  }) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final holdingsAsync = ref.watch(portfolioHoldingsProvider(widget.userId));

    return holdingsAsync.when(
      data: (portfolioHoldings) {
        final displayWidget = HoldingsTemplateFactory.createDisplayTemplate(
          holdings: portfolioHoldings.holdings,
          core: _core,
          isLoading: false,
        );

        final selectorWidget = HoldingsTemplateFactory.createSelectorWidget(
          config: HoldingsDisplayConfig.web(),
          core: _core,
        );

        return HoldingsTemplateFactory.createLayoutTemplate(
          context: context,
          templateType: HoldingsTemplateType.full,
          config: HoldingsDisplayConfig.web(),
          holdings: portfolioHoldings.holdings,
          core: _core,
          displayWidget: displayWidget,
          selectorWidget: selectorWidget,
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Error: $e'),
    );
  }

  @override
  void dispose() {
    _core.dispose();
    super.dispose();
  }
}
```

## Template Types

### Minimal
- No title, no selectors
- Compact padding
- Pure data display

### Compact
- Optional selectors
- Moderate padding
- Good for dashboards

### Full
- Title with icon
- All selectors enabled
- Refresh/export actions
- Best for dedicated pages

### Adaptive
- Automatically chooses template based on screen size
- Mobile: Compact template
- Desktop: Full template

## Configuration Presets

### Web Configuration
```dart
HoldingsDisplayConfig.web()
```
- Table view by default
- All controls enabled
- 50 items per page
- Export and selection enabled

### Mobile Configuration
```dart
HoldingsDisplayConfig.mobile()
```
- Card view by default
- Essential controls only
- 20 items per page
- Simplified UI

### Minimal Configuration
```dart
HoldingsDisplayConfig.minimal()
```
- No controls
- 10 items
- Dashboard widget use

## Core State Management

The `HoldingsSelectorCore` manages:

- **Sort By**: Symbol, Value, Gain/Loss, Quantity, Weight
- **Display Format**: Value (₹), Percentage (%), Both
- **Change Type**: Daily, Total
- **View Mode**: Table, Card, Detailed
- **Sort Order**: Ascending/Descending
- **Sector Filter**: Filter by sector

## Benefits

1. **Consistent UI**: Same patterns across web and mobile
2. **Code Reuse**: Maximum component sharing
3. **Maintainability**: Centralized logic and presentation
4. **Flexibility**: Easy to extend with new layouts
5. **Testability**: Separated concerns, mockable dependencies

## Migration from Old Components

### Before (Old Web Page)
```dart
PortfolioHoldingsWebPage(
  userId: userId,
  portfolioId: portfolioId,
)
```

### After (Template System)
```dart
UniversalHoldingsWidget(
  userId: userId,
  portfolioId: portfolioId,
  config: HoldingsDisplayConfig.web(),
  templateType: HoldingsTemplateType.full,
)
```

## Integration with Existing Code

The template system works alongside existing components:
- Can be used in new features immediately
- Existing pages can migrate gradually
- Interoperable with current provider system
