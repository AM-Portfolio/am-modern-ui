# Shared Heatmap Components

This directory contains reusable heatmap components that can be used across different features in the application.

## Components

### 1. HeatmapCard (`shared/widgets/cards/heatmap_card.dart`)

A flexible heatmap visualization widget that supports multiple layouts and responsive design.

**Features:**
- Responsive sub-card visibility (show/hide based on screen size)
- Multiple layout options: treemap, grid, list
- Configurable color schemes: performance, custom, weightage, neutral
- Customizable tile sizing and padding
- Built-in loading and error states
- Interactive tile press handling

**Usage:**
```dart
HeatmapCard(
  data: heatmapData,
  icon: Icons.pie_chart,
  isLoading: false,
  error: null,
  onTilePressed: () {
    // Handle tile interaction
  },
)
```

### 2. HeatmapData Model (`shared/models/heatmap/heatmap_data.dart`)

Generic data structure for heatmap visualization.

**Key Classes:**
- `HeatmapData`: Container for all heatmap information
- `HeatmapTileData`: Individual tile data with performance and weightage
- `HeatmapConfig`: Display and behavior settings
- `HeatmapLayout`: Layout options (treemap, grid, list)
- `HeatmapColorScheme`: Color scheme options

**Usage:**
```dart
final heatmapData = HeatmapData(
  title: 'Portfolio Allocation',
  subtitle: 'By sector',
  tiles: [
    HeatmapTileData(
      id: 'tech',
      name: 'Technology',
      displayName: 'Tech',
      weightage: 35.0,
      performance: 12.5,
      value: 350000,
    ),
    // ... more tiles
  ],
  configuration: HeatmapConfig.web(), // or .mobile()
);
```

### 3. Configuration Options

#### Pre-built Configurations

**Web Configuration:**
- Shows sub-cards with detailed information
- Larger tile sizes
- Treemap layout
- All performance metrics visible

**Mobile Configuration:**
- Hides sub-cards for cleaner appearance
- Smaller tile sizes
- Grid layout
- Essential information only

#### Custom Configuration

```dart
HeatmapConfig(
  showSubCards: true,
  showPerformance: true,
  showWeightage: true,
  showValue: false,
  layout: HeatmapLayout.treemap,
  colorScheme: HeatmapColorScheme.performance,
  minTileWidth: 100,
  maxTileWidth: 200,
  minTileHeight: 80,
  maxTileHeight: 120,
  tilePadding: EdgeInsets.all(8),
  tileMargin: EdgeInsets.all(2),
)
```

## Layout Options

### 1. Treemap Layout
- Tiles sized proportionally to weightage
- Organic, flowing arrangement
- Best for showing relative importance
- Default for web view

### 2. Grid Layout
- Fixed-size tiles in regular grid
- Clean, uniform appearance
- Better for mobile devices
- Responsive column count

### 3. List Layout
- Horizontal tiles in vertical list
- Good for detailed information
- Easy scrolling on mobile

## Color Schemes

### 1. Performance (Default)
- Green for positive performance
- Red for negative performance
- Gray for neutral
- Intensity based on magnitude

### 2. Custom
- Uses colors from `HeatmapTileData.customColor`
- Full control over tile appearance
- Good for category-based coloring

### 3. Weightage
- Blue gradient based on weightage percentage
- Darker = higher weightage
- Good for allocation visualization

### 4. Neutral
- Single gray color for all tiles
- Focus on data, not performance
- Clean, minimal appearance

## Responsive Design

The components automatically adapt to different screen sizes:

- **Web/Desktop (>768px)**: Shows sub-cards with detailed metrics
- **Mobile (<768px)**: Hides sub-cards, shows essential info only

Use the `showSubCards` parameter to control this behavior manually.

## Examples

See `heatmap_examples.dart` for complete usage examples including:
- Asset allocation heatmap
- Geographic allocation with mobile config
- Custom color schemes
- Different layout options

## Integration with Existing Features

### SectorOverviewCard Integration

The `SectorOverviewCard` has been refactored to use the shared `HeatmapCard`. It uses `SectorHeatmapConverter` to transform portfolio analytics data into the generic heatmap format.

### Adding New Heatmap Features

1. Create your data in `HeatmapData` format
2. Use appropriate configuration for your use case
3. Handle tile interactions as needed
4. Consider responsive behavior for your users

## Best Practices

1. **Data Transformation**: Convert your domain data to `HeatmapData` format
2. **Responsive Design**: Use appropriate configurations for different screen sizes
3. **Performance**: Limit the number of tiles for better performance
4. **Accessibility**: Ensure sufficient color contrast and provide meaningful labels
5. **Interaction**: Implement tile press handlers for navigation or details
6. **Loading States**: Always handle loading and error states properly

## Migration from Old Components

If migrating from existing heatmap implementations:

1. Transform your data to `HeatmapTileData` format
2. Choose appropriate `HeatmapConfig`
3. Replace custom tile building with `HeatmapCard`
4. Update any interaction handling
5. Test responsive behavior on different screen sizes