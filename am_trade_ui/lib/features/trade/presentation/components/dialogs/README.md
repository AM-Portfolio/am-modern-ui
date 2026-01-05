# Trade Detail Dialog - Modular Components

## Overview
This directory contains reusable, modular components for displaying detailed trade information in a beautiful, responsive dialog.

## Component Structure

```
dialogs/
├── trade_detail_dialog.dart          # Main dialog with tabs
├── sections/                          # Tab content sections
│   ├── trade_info_section.dart       # Basic trade information
│   ├── trade_metrics_section.dart    # Performance metrics
│   └── trade_performance_section.dart # Visual performance indicators
└── widgets/                           # Reusable UI widgets
    ├── info_card.dart                 # Card container for grouped info
    ├── info_row.dart                  # Label-value row display
    └── metric_card.dart               # Metric display with icon
```

## Usage

### Basic Usage

```dart
import 'package:your_app/features/trade/presentation/components/dialogs/trade_detail_dialog.dart';

// Show the dialog
TradeDetailDialog.show(context, tradeHoldingViewModel);
```

### Customization

Each section can be used independently:

```dart
// Use individual sections in custom layouts
TradeInfoSection(holding: holding)
TradeMetricsSection(holding: holding)
TradePerformanceSection(holding: holding)
```

## Components

### 1. TradeDetailDialog
**Purpose**: Main dialog container with tabbed interface  
**Features**:
- Responsive sizing (adapts to screen width)
- Three tabs: Overview, Metrics, Performance
- Beautiful gradient header with P&L badge
- Status indicator with color coding
- Auto-sized for mobile and desktop

**Props**:
- `holding` (required): TradeHoldingViewModel

### 2. TradeInfoSection
**Purpose**: Display basic trade information  
**Features**:
- Company information card
- Trade details card
- Pricing information card
- Broker information card
- Organized with InfoCard widgets

**Reusable**: Yes - can be used in detail pages, popups, etc.

### 3. TradeMetricsSection
**Purpose**: Display performance metrics and analytics  
**Features**:
- Responsive grid of metric cards
- Performance analysis with icons
- Risk/reward color coding
- Price movement calculations

**Reusable**: Yes - great for dashboards and reports

### 4. TradePerformanceSection
**Purpose**: Visual performance indicators  
**Features**:
- Large P&L display with trend icon
- Status indicator grid
- Chart placeholder (ready for integration)
- Color-coded profit/loss display

**Reusable**: Yes - perfect for summary views

## Reusable Widgets

### InfoCard
Container for grouped information with title and icon
```dart
InfoCard(
  title: 'Section Title',
  icon: Icons.info,
  iconColor: Colors.blue,
  children: [/* widgets */],
)
```

### InfoRow
Label-value pair display
```dart
InfoRow(
  label: 'Label',
  value: 'Value',
  valueColor: Colors.green,
  isBold: true,
)
```

### MetricCard
Metric display with icon and gradient background
```dart
MetricCard(
  title: 'Profit/Loss',
  value: '\$1,234.56',
  subtitle: '+12.5%',
  icon: Icons.trending_up,
  color: Colors.green,
)
```

## Design Features

### Responsive Design
- Dialog adapts from 300px to 900px width
- Grid layouts adjust columns based on space
- Mobile-optimized padding and font sizes
- Smooth animations and transitions

### Visual Polish
- Gradient backgrounds
- Color-coded status indicators
- Icon-based navigation
- Consistent spacing and typography
- Shadow and elevation effects

### Accessibility
- Clear visual hierarchy
- High contrast text
- Tooltip support (in responsive sidebar)
- Keyboard navigation ready

## Integration Points

These components are already integrated with:
- `TradeHoldingsDashboardWebPage` - Shows dialog on holding click
- `TradeHoldingsDashboardMobilePage` - Shows dialog on holding tap

## Future Enhancements

1. **Performance Charts**
   - Add chart library integration in TradePerformanceSection
   - Price movement timeline
   - P&L over time graph

2. **Trade Notes**
   - Add notes field to view model
   - Display in TradeInfoSection

3. **Edit Mode**
   - Allow inline editing of trade details
   - Save/cancel actions

4. **Export Functionality**
   - Export trade details as PDF
   - Share via email/messaging

## Best Practices

1. **Keep Sections Focused**: Each section should have a single responsibility
2. **Reusable Widgets**: Extract common UI patterns into widgets
3. **Null Safety**: Always handle nullable fields gracefully
4. **Responsive**: Test on multiple screen sizes
5. **Performance**: Use const constructors where possible

## Dependencies

- `flutter/material.dart` - UI framework
- `../../models/trade_holding_view_model.dart` - Data model

No external packages required! 🎉
