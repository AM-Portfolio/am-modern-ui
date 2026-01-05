# Year Calendar Widget - Modular Architecture

## Overview
The Year Calendar Widget has been refactored into a modular, maintainable architecture with clear separation of concerns.

## File Structure

```
year_calendar/
├── year_calendar_widget_new.dart          # Main widget (uses components)
├── year_calendar_widget.dart              # Legacy widget (deprecated)
├── year_calendar_exports.dart             # Barrel export file
├── calendar_types.dart                    # Type definitions
│
├── components/                            # UI Components
│   ├── year_calendar_header.dart          # Header with navigation & stats
│   ├── year_summary_stats.dart            # Year-level statistics display
│   ├── calendar_legend.dart               # Win/Loss/Breakeven legend
│   ├── months_grid.dart                   # Responsive grid layout
│   ├── month_calendar_card.dart           # Individual month card
│   ├── month_header.dart                  # Month name & badges
│   ├── calendar_day_cell.dart             # Individual day cell
│   └── stat_badge.dart                    # Reusable stat badge
│
└── controllers/                           # Business Logic
    └── calendar_data_controller.dart      # Dashboard data management
```

## Component Breakdown

### 1. Header Components
**YearCalendarHeader** (`year_calendar_header.dart`)
- Year navigation (previous/next buttons)
- Responsive layout (mobile vs desktop)
- Integrates summary stats and legend
- Calculates year-wide statistics

**YearSummaryStats** (`year_summary_stats.dart`)
- Displays Total Trades, Win Rate, Total P&L
- Aligned to the right in header
- Includes calendar legend

**CalendarLegend** (`calendar_legend.dart`)
- Shows Win/Loss/Breakeven color indicators
- Compact, border-outlined design

### 2. Calendar Grid Components
**MonthsGrid** (`months_grid.dart`)
- Responsive grid layout (1-4 columns based on screen width)
- Breakpoints:
  - Mobile (<600px): 1 column
  - Tablet (600-900px): 2 columns  
  - Small Desktop (900-1200px): 3 columns
  - Large Desktop (>1200px): 4 columns

**MonthCalendarCard** (`month_calendar_card.dart`)
- Individual month as Material Card
- Contains header, weekday labels, calendar grid
- Calculates month-level statistics
- Elevation & rounded corners

**MonthHeader** (`month_header.dart`)
- Month name (left-aligned)
- Stat badges (right-aligned): trade days, trades, win rate, P&L
- Horizontal row layout with Spacer

**CalendarDayCell** (`calendar_day_cell.dart`)
- Individual day display with color coding
- Hover tooltips showing trade details
- Click handler for loading dashboard data
- Material InkWell with hover effects

**StatBadge** (`stat_badge.dart`)
- Reusable badge component
- Icon + label with themed colors
- Rounded corners, border, background opacity

### 3. Controllers
**CalendarDataController** (`calendar_data_controller.dart`)
- Manages calendar interaction state
- Handles day selection
- Triggers dashboard data loading
- Callbacks for:
  - `onDateSelected`: When user clicks a date
  - `onDashboardDataRequested`: Load holdings/analytics data
- Methods:
  - `handleDayTap()`: Process day click
  - `loadDashboardData()`: Load data for single date
  - `loadDashboardDataForRange()`: Load data for date range
  - `clearSelection()`: Reset selection

## Usage

### Basic Usage
```dart
import 'package:your_apackage:am_design_system/am_design_system.dart';

YearCalendarWidget(
  year: 2020,
  monthsData: convertedMonthsData,
  config: YearCalendarConfig(
    showHeader: true,
    showWeekdays: true,
  ),
  onYearChanged: (newYear) {
    // Handle year change
  },
)
```

### With Dashboard Integration
```dart
final controller = CalendarDataController(
  onDateSelected: (date, dayData) {
    print('Selected: $date with ${dayData.tradeCount} trades');
  },
  onDashboardDataRequested: (startDate, endDate) async {
    // Load portfolio data
    await portfolioService.loadForDate(startDate);
    
    // Load holdings data
    await holdingsService.loadForDate(startDate);
    
    // Load analytics data
    await analyticsService.loadForDate(startDate);
  },
);

YearCalendarWidget(
  year: 2020,
  monthsData: monthsData,
  controller: controller,
)
```

### Listening to Controller Changes
```dart
controller.addListener(() {
  if (controller.selectedDate != null) {
    print('Selected date: ${controller.selectedDate}');
    print('Loading: ${controller.isLoadingDashboard}');
  }
});
```

## Dashboard Connection Flow

1. **User Clicks Date** → CalendarDayCell.onTap
2. **Event Bubbles Up** → MonthCalendarCard → MonthsGrid → YearCalendarWidget
3. **Controller Handles** → CalendarDataController.handleDayTap()
4. **Callbacks Triggered**:
   - `onDateSelected`: Notify UI of selection
   - `onDashboardDataRequested`: Load data
5. **Dashboard Updates**: Holdings, Analytics, Portfolio views refresh

## Migration from Legacy Widget

### Before (Old)
```dart
YearCalendarWidget(
  year: 2020,
  monthsData: data,
  config: YearCalendarConfig(onDayTap: (date, dayData) {
    // Handle tap
  }),
)
```

### After (New)
```dart
// Create controller
final controller = CalendarDataController(
  onDateSelected: (date, dayData) {
    // Handle selection
  },
  onDashboardDataRequested: (startDate, endDate) {
    // Load dashboard data
  },
);

// Use new widget
YearCalendarWidget(
  year: 2020,
  monthsData: data,
  controller: controller,
)
```

## Benefits of Modular Design

✅ **Separation of Concerns**: UI components, business logic, types are separated
✅ **Reusability**: Components can be used independently
✅ **Testability**: Each component can be tested in isolation
✅ **Maintainability**: Easier to locate and modify specific functionality
✅ **Scalability**: Easy to add new features without touching existing code
✅ **Performance**: Only affected components re-render
✅ **Dashboard Integration**: Clean connection to portfolio/holdings/analytics

## Next Steps

1. Update `trade_calendar_analytics_web_page.dart` to use new widget
2. Create dashboard service to handle data loading
3. Connect holdings and analytics modules
4. Add loading states in UI
5. Implement error handling for failed data loads
6. Add unit tests for controller and components
