# Heatmap Selector Template

## Overview

The `HeatmapSelectorTemplate` is a smart wrapper widget that provides adaptive heatmap selector functionality by choosing between the existing `HeatmapSelectorWeb` and `HeatmapSelectorMobile` components based on screen size and configuration.

## Key Features

- **Adaptive Layout**: Automatically switches between web and mobile implementations based on screen size
- **Component Delegation**: Uses existing `HeatmapSelectorWeb` and `HeatmapSelectorMobile` components without reimplementation
- **Configurable Breakpoints**: Customizable breakpoints for responsive behavior
- **Smart Configuration**: Auto-generates appropriate configs or accepts custom ones
- **Extension Methods**: Convenient factory methods for common use cases

## Usage Examples

### Basic Adaptive Usage
```dart
HeatmapSelectorTemplate(
  core: myHeatmapCore,
  title: 'Stock Heatmap Filters',
  enableAdaptiveLayout: true,
  mobileBreakpoint: 768,
)
```

### Force Mobile Layout
```dart
HeatmapSelectorTemplate.mobile(
  core: myHeatmapCore,
  title: 'Mobile Filters',
  showResetButton: true,
)
```

### Force Web Layout
```dart
HeatmapSelectorTemplate.web(
  core: myHeatmapCore,
  title: 'Desktop Filters',
  layout: SelectorLayoutType.expanded,
)
```

### Fully Adaptive with Custom Breakpoints
```dart
HeatmapSelectorTemplate.adaptive(
  core: myHeatmapCore,
  title: 'Responsive Filters',
  mobileBreakpoint: 600,
  tabletBreakpoint: 900,
  onLayoutChanged: (layout) => print('Layout changed to: $layout'),
)
```

## Component Architecture

```
HeatmapSelectorTemplate
├── Determines platform based on screen size
├── Generates appropriate SelectorConfig
├── Chooses effective layout type
└── Delegates to appropriate component:
    ├── HeatmapSelectorMobile (for mobile screens)
    └── HeatmapSelectorWeb (for web/desktop screens)
```

## Key Benefits

1. **Clean Separation**: Template acts as a smart router, keeping web and mobile implementations separate
2. **Easy Enhancement**: You can enhance web and mobile components independently
3. **Consistent API**: Single interface for all screen sizes with adaptive behavior
4. **Reusable**: Extension methods provide convenient factory constructors for common scenarios
5. **Responsive**: Automatically adapts to screen size changes

## Breakpoint Behavior

- **< mobileBreakpoint**: Uses `HeatmapSelectorMobile` with compact layout
- **mobileBreakpoint - tabletBreakpoint**: Uses `HeatmapSelectorWeb` with dropdown/expanded layout
- **> tabletBreakpoint**: Uses `HeatmapSelectorWeb` with configured layout

## Configuration

The template auto-generates appropriate `SelectorConfig` instances:
- Mobile: `SelectorConfig.mobile()` - optimized for touch interaction
- Web: `SelectorConfig.web()` - optimized for mouse interaction

You can also provide custom configurations for fine-grained control.