# AM Analysis Core

**Headless state management for portfolio analysis**

This package provides pure state management (Cubits) without UI dependencies, enabling full control over design and responsive behavior for desktop and mobile applications.

## Features

- 🧠 **Headless Architecture**: State management decoupled from UI
- 🎨 **Full Customization**: Build your own UI or use default widgets
- 📱 **Platform Agnostic**: Works on all Flutter platforms
- ⚡ **Lightweight**: Minimal dependencies (flutter_bloc + equatable)
- 🔄 **Reactive**: Built on BLoC pattern for predictable state management

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  am_analysis_core:
    path: ../am_analysis_core
```

## Usage

### Option 1: Headless (Full Control)

Build your own custom UI using the Cubits:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_analysis_core/am_analysis_core.dart';

// Create the cubit
final cubit = AllocationCubit(
  portfolioId: 'portfolio-123',
  analysisService: MyAnalysisServiceImpl(),
);

// Load data
await cubit.loadAllocation(GroupBy.sector);

// Build UI with BlocBuilder
BlocBuilder<AllocationCubit, AllocationState>(
  bloc: cubit,
  builder: (context, state) {
    return switch (state) {
      AllocationLoading() => CircularProgressIndicator(),
      AllocationLoaded(:final allocations) => MyCustomAllocationUI(allocations),
      AllocationError(:final message) => ErrorWidget(message),
      _ => SizedBox(),
    };
  },
)
```

### Option 2: With Default UI

Use the `am_analysis_ui` package for pre-built widgets:

```dart
import 'package:am_analysis_ui/am_analysis_ui.dart';

// Uses AllocationCubit internally
AnalysisAllocationWidget(
  portfolioId: 'portfolio-123',
  layoutMode: LayoutMode.compact, // Mobile-optimized
)
```

## Architecture

```
┌─────────────────────────────────────┐
│     Consumer App (Portfolio UI)    │
├─────────────────────────────────────┤
│  Option 1: Custom UI + Core Cubits │
│  Option 2: Default Widgets (UI)    │
├─────────────────────────────────────┤
│      am_analysis_core (Cubits)     │  ← This package
├─────────────────────────────────────┤
│       AnalysisService Interface     │
│    (Implemented by consumer/UI)     │
└─────────────────────────────────────┘
```

## Components

### States

- **AllocationState**: `Initial | Loading | Loaded | Error`
- **TopMoversState**: `Initial | Loading | Loaded | Error`
- **PerformanceState**: `Initial | Loading | Loaded | Error`

### Cubits

- **AllocationCubit**: Manages allocation data and grouping
  - `loadAllocation(GroupBy)` - Load data
  - `changeGroupBy(GroupBy)` - Change grouping
  - `refresh()` - Reload current data

- **TopMoversCubit**: Manages top movers with filtering
  - `loadTopMovers(TimeFrame)` - Load data
  - `applyFilter(MoverFilter)` - Filter gainers/losers
  - `changeTimeFrame(TimeFrame)` - Change time period
  - `refresh()` - Reload current data

- **PerformanceCubit**: Manages performance chart data
  - `loadPerformance(TimeFrame)` - Load data
  - `changeTimeFrame(TimeFrame)` - Change time period
  - `refresh()` - Reload current data

### Models

- `AllocationItem` - Sector/industry allocation data
- `MoverItem` - Stock mover data (symbol, price, change%)
- `PerformanceDataPoint` - Time-series performance data

### Enums

- `GroupBy`: `sector | industry | marketCap | stock`
- `TimeFrame`: `oneDay | oneWeek | oneMonth | threeMonths | oneYear | all`
- `MoverFilter`: `all | gainers | losers`

## Service Interface

Cubits depend on an `AnalysisService` interface that you must implement:

```dart
abstract class AnalysisService {
  Future<List<AllocationItem>> getAllocation({
    required String portfolioId,
    required GroupBy groupBy,
  });
  
  Future<List<MoverItem>> getTopMovers({
    required String portfolioId,
    required TimeFrame timeFrame,
  });
  
  Future<List<PerformanceDataPoint>> getPerformance({
    required String portfolioId,
    required TimeFrame timeFrame,
  });
}
```

## Examples

### Desktop Layout (Expanded Mode)

```dart
final cubit = AllocationCubit(
  portfolioId: portfolioId,
  analysisService: RealAnalysisService(),
)..loadAllocation(GroupBy.sector);

BlocBuilder<AllocationCubit, AllocationState>(
  bloc: cubit,
  builder: (context, state) {
    if (state is AllocationLoaded) {
      return MyExpandedDesktopLayout(
        allocations: state.allocations,
        groupBy: state.groupBy,
        onGroupByChanged: cubit.changeGroupBy,
      );
    }
    // ... handle other states
  },
)
```

### Mobile Layout (Compact Mode)

```dart
// Same cubit, different UI
BlocBuilder<AllocationCubit, AllocationState>(
  bloc: cubit,
  builder: (context, state) {
    if (state is AllocationLoaded) {
      return MyCompactMobileLayout(
        allocations: state.allocations,
      );
    }
    // ...
  },
)
```

### Real-time Updates

```dart
// Listen to state changes
cubit.stream.listen((state) {
  if (state is AllocationLoaded) {
    print('Loaded ${state.allocations.length} items');
  }
});

// Trigger reload
await cubit.refresh();
```

## Benefits

### For UI Consumers

✅ **Full Design Control**: Build UI that matches your design system  
✅ **Responsive Freedom**: Implement custom breakpoints and layouts  
✅ **Platform Flexibility**: Desktop, mobile, web - your choice  
✅ **Testing**: Mock the service, test Cubits in isolation  

### For Headless Usage

✅ **CLI Tools**: Use Cubits in command-line applications  
✅ **Background Services**: Fetch and process data without UI  
✅ **Web APIs**: Build REST endpoints powered by analysis Cubits  

## License

Proprietary - Internal use only.
