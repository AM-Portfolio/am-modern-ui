# Universal Calendar Widget - Complete Implementation Guide

## Overview

The Universal Calendar Widget is a comprehensive, dynamic calendar system designed for Flutter applications. It supports multiple modules (trading, portfolio, analytics) with various card designs and filter capabilities.

## Key Features

- **Multiple Template Types**: Minimal, Compact, Full, Dashboard, and Adaptive layouts
- **Dynamic Card System**: Customizable cards with different layouts and themes
- **Predefined Models**: Ready-to-use configurations for different contexts
- **Data Provider System**: Pluggable data providers for different data sources
- **Responsive Design**: Adapts to different screen sizes and use cases

## Predefined Models and Configurations

### 1. Template Types

```dart
enum CalendarTemplateType {
  minimal,    // Filter display only, no selectors
  compact,    // Filter + compact date selectors  
  full,       // All components with full features
  dashboard,  // Optimized for dashboard widgets
  adaptive,   // Adapts based on screen size and config
}
```

### 2. Predefined Widget Wrappers

#### Quick Date Filter
```dart
QuickDateFilter(
  onDateSelectionChanged: (selection) {
    print('Selected: ${selection.description}');
  },
  initialSelection: DateSelection(
    startDate: DateTime.now().subtract(Duration(days: 7)),
    endDate: DateTime.now(),
    description: 'Last 7 Days',
    filterType: DateFilterMode.quick,
  ),
)
```

#### Web Date Filter
```dart
WebDateFilter(
  onDateSelectionChanged: (selection) {
    print('Selected: ${selection.description}');
  },
  title: "Analytics Period",
  fullFeatures: true,
)
```

#### Trade Date Filter
```dart
TradeDateFilter(
  onDateSelectionChanged: (selection) {
    print('Selected: ${selection.description}');
  },
  title: "Trading Period",
)
```

### 3. Card Types and Configurations

#### Trading Cards
```dart
// P&L Summary Card
const CalendarCardConfig(
  type: CalendarCardType.pnlSummary,
  title: 'Daily P&L',
  size: CardSizeType.medium,
  layout: CardLayoutStyle.metric,
  theme: CardTheme.neutral,
)

// Trade Metrics Card
const CalendarCardConfig(
  type: CalendarCardType.tradeMetrics,
  title: 'Trade Statistics',
  size: CardSizeType.large,
  layout: CardLayoutStyle.grid,
  theme: CardTheme.info,
)

// Win/Loss Ratio Card
const CalendarCardConfig(
  type: CalendarCardType.winLossRatio,
  title: 'Win/Loss Ratio',
  size: CardSizeType.small,
  layout: CardLayoutStyle.chart,
  theme: CardTheme.success,
)
```

#### Portfolio Cards
```dart
// Portfolio Value Card
const CalendarCardConfig(
  type: CalendarCardType.portfolioValue,
  title: 'Portfolio Value',
  size: CardSizeType.medium,
  layout: CardLayoutStyle.metric,
  theme: CardTheme.info,
)

// Asset Allocation Card
const CalendarCardConfig(
  type: CalendarCardType.assetAllocation,
  title: 'Asset Allocation',
  size: CardSizeType.large,
  layout: CardLayoutStyle.chart,
  theme: CardTheme.neutral,
)
```

### 4. Predefined Date Ranges

#### Quick Ranges
```dart
enum QuickRangeType {
  last7Days('Last 7 Days', 7),
  last30Days('Last 30 Days', 30),
  last90Days('Last 3 Months', 90),
  last6Months('Last 6 Months', 180),
  lastYear('Last Year', 365);
}
```

#### Time Periods
```dart
enum TimePeriodType {
  thisWeek('This Week', 'current_week'),
  thisMonth('This Month', 'current_month'),
  thisQuarter('This Quarter', 'current_quarter'),
  thisYear('This Year', 'current_year'),
  lastWeek('Last Week', 'previous_week'),
  lastMonth('Last Month', 'previous_month'),
  lastQuarter('Last Quarter', 'previous_quarter'),
  lastYear('Last Year', 'previous_year');
}
```

## Usage Examples

### 1. Basic Calendar (No Cards)
```dart
UniversalCalendarWidget(
  onDateSelectionChanged: (selection) {
    print('Date selected: ${selection.description}');
  },
  context: 'default',
  templateType: CalendarTemplateType.adaptive,
)
```

### 2. Trading Calendar with Cards
```dart
UniversalCalendarWidget(
  onDateSelectionChanged: (selection) {
    print('Trading period: ${selection.description}');
  },
  context: 'trade',
  templateType: CalendarTemplateType.full,
  title: 'Trading Analysis',
  enableCardView: true,
  cardConfigs: [
    const CalendarCardConfig(
      type: CalendarCardType.pnlSummary,
      title: 'P&L Summary',
      size: CardSizeType.medium,
      layout: CardLayoutStyle.metric,
      theme: CardTheme.neutral,
    ),
    const CalendarCardConfig(
      type: CalendarCardType.tradeMetrics,
      title: 'Trade Metrics',
      size: CardSizeType.large,
      layout: CardLayoutStyle.grid,
      theme: CardTheme.info,
    ),
  ],
  dataProvider: TradeCalendarDataProvider(
    portfolioId: 'your-portfolio-id',
    mockData: yourMockData,
  ),
)
```

### 3. Portfolio Calendar with Custom Data Provider
```dart
UniversalCalendarWidget(
  onDateSelectionChanged: (selection) {
    // Handle portfolio date selection
    portfolioService.updateDateRange(selection);
  },
  context: 'portfolio',
  templateType: CalendarTemplateType.adaptive,
  title: 'Portfolio Performance',
  enableCardView: true,
  cardConfigs: [
    const CalendarCardConfig(
      type: CalendarCardType.portfolioValue,
      title: 'Total Value',
      size: CardSizeType.medium,
      layout: CardLayoutStyle.metric,
      theme: CardTheme.info,
    ),
    const CalendarCardConfig(
      type: CalendarCardType.assetAllocation,
      title: 'Asset Mix',
      size: CardSizeType.large,
      layout: CardLayoutStyle.chart,
      theme: CardTheme.neutral,
    ),
  ],
  dataProvider: PortfolioCalendarDataProvider(
    portfolioId: 'portfolio-123',
  ),
)
```

## Data Provider System

### Creating Custom Data Providers

```dart
class CustomCalendarDataProvider extends CalendarDataProvider {
  @override
  Future<Map<String, List<CardData>>> getCardData({
    required DateTime startDate,
    required DateTime endDate,
    required List<CalendarCardType> cardTypes,
    Map<String, dynamic>? filters,
  }) async {
    // Implement your custom data fetching logic
    final data = await yourApiService.fetchData(startDate, endDate);
    return processDataForCards(data, cardTypes);
  }

  @override
  List<CalendarCardType> getSupportedCardTypes() {
    return [
      CalendarCardType.custom,
      CalendarCardType.summary,
      // Add your supported card types
    ];
  }

  @override
  List<CalendarCardConfig> getDefaultCardConfigs() {
    return [
      const CalendarCardConfig(
        type: CalendarCardType.custom,
        title: 'Custom Metric',
        size: CardSizeType.medium,
        layout: CardLayoutStyle.metric,
        theme: CardTheme.neutral,
      ),
    ];
  }
}
```

## Card Customization

### Card Sizes
- `CardSizeType.small`: 80x60 pixels
- `CardSizeType.medium`: 160x120 pixels  
- `CardSizeType.large`: 240x180 pixels
- `CardSizeType.full`: Full width, 200px height

### Card Layouts
- `CardLayoutStyle.metric`: Single metric display
- `CardLayoutStyle.comparison`: Side-by-side comparison
- `CardLayoutStyle.chart`: Chart/graph visualization
- `CardLayoutStyle.list`: List of items
- `CardLayoutStyle.grid`: Grid layout
- `CardLayoutStyle.timeline`: Timeline view
- `CardLayoutStyle.heatmap`: Heatmap visualization

### Card Themes
- `CardTheme.neutral`: Standard theme
- `CardTheme.success`: Green theme for positive metrics
- `CardTheme.warning`: Orange theme for caution
- `CardTheme.danger`: Red theme for negative metrics
- `CardTheme.info`: Blue theme for informational
- `CardTheme.custom`: User-defined theme with custom colors

## Integration with Mock Data

```dart
// Sample mock data structure for trading
Map<String, dynamic> mockTradeData = {
  '8a57024c-05c2-475b-a2c4-0545865efa4a': [
    {
      'tradeId': 'trade-1',
      'status': 'WIN',
      'tradePositionType': 'LONG',
      'entryInfo': {'quantity': 100, 'price': 50.0},
      'exitInfo': {'quantity': 100, 'price': 55.0},
      'metrics': {'totalPnL': 496.0},
      'tradeDate': '2024-01-15',
    },
    // More trades...
  ]
};

// Use with TradeCalendarDataProvider
TradeCalendarDataProvider(
  portfolioId: '8a57024c-05c2-475b-a2c4-0545865efa4a',
  mockData: mockTradeData,
)
```

## Best Practices

1. **Choose the Right Template**: Use `adaptive` for most cases, `minimal` for simple filtering, `full` for comprehensive analysis
2. **Optimize Card Count**: Limit to 3-4 cards per date to avoid overcrowding
3. **Use Appropriate Card Sizes**: Mix small, medium, and large cards for visual balance
4. **Context-Specific Data Providers**: Create specialized data providers for different modules
5. **Handle Loading States**: The widget automatically shows loading indicators while fetching card data
6. **Error Handling**: Implement proper error handling in your data providers

## Performance Considerations

- Card data is loaded asynchronously and cached
- Use pagination for large date ranges
- Implement data provider caching for frequently accessed data
- Consider using `enableCardView: false` for simple date selection without cards

This universal calendar system provides a flexible, scalable solution for date-based data visualization across different modules in your application.