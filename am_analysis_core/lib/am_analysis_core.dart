/// Headless core for analysis features
/// 
/// This package provides state management (Cubits) without UI dependencies.
/// Consumers can use these Cubits to build custom UIs or use the default
/// widgets from am_analysis_ui.
library am_analysis_core;

// Export models
export 'models/allocation_item.dart';
export 'models/mover_item.dart';
export 'models/performance_data_point.dart';
export 'models/enums.dart';

// Export states
export 'states/allocation_state.dart';
export 'states/top_movers_state.dart';
export 'states/performance_state.dart';

// Export cubits
export 'cubits/allocation_cubit.dart';
export 'cubits/top_movers_cubit.dart';
export 'cubits/performance_cubit.dart';
