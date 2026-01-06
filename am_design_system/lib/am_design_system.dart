library am_design_system;

// ============================================================================
// CORE LAYER - Foundation
// ============================================================================

// Theme
export 'core/theme/app_theme.dart';
export 'core/theme/am_chart_theme.dart';
export 'core/theme/app_colors.dart';
export 'core/theme/color_extensions.dart';
export 'core/theme/app_typography.dart';
export 'core/theme/app_animations.dart';
export 'core/theme/app_glassmorphism.dart';
export 'core/theme/app_glassmorphism_v2.dart';
export 'core/theme/cubit/theme_cubit.dart';
export 'core/theme/theme_repository.dart';
export 'core/config/design_system_config.dart';
export 'core/config/design_system_provider.dart';

// Contracts
export 'core/contracts/design_contract.dart';

// Utils
export 'core/utils/common_logger.dart';
export 'core/utils/device_utils.dart';
export 'core/utils/conditional_mouse_region.dart';

// Constants & API Endpoints
export 'core/constants/app_constants.dart';

// Cache
export 'core/cache/cache_service.dart';
export 'core/cache/cache_keys.dart';
export 'core/cache/cache_provider.dart';

// Navigation Logic
export 'core/navigation/swipe_navigation_controller.dart';

// Module System
export 'core/module/i_module.dart';
export 'core/module/module_config.dart';
export 'core/module/module_type.dart';
export 'core/module/module_context.dart';
export 'core/module/module_color_provider.dart';

// ============================================================================
// SHARED LAYER - Reusable Foundation & Feature Support Components
// ============================================================================

// --- Navigation ---
export 'shared/widgets/navigation/global_sidebar.dart';
export 'shared/widgets/navigation/global_bottom_navigation.dart';
export 'shared/widgets/navigation/module_bottom_navigation.dart';
export 'shared/widgets/navigation/secondary_sidebar.dart';
export 'shared/widgets/navigation/sidebar_item.dart';
export 'shared/widgets/navigation/sidebar_nav_item.dart';
export 'shared/widgets/navigation/sidebar_primary_action.dart';
export 'shared/widgets/navigation/swipeable_page_view.dart';
export 'shared/widgets/navigation/sidebar_selector.dart';
export 'shared/widgets/scaffold/unified_sidebar_scaffold.dart';

// --- Layouts ---
export 'shared/widgets/layouts/web_layout.dart';
export 'shared/widgets/layouts/mobile_layout.dart';
export 'shared/widgets/containers/module_container.dart';
export 'shared/widgets/containers/selector_container.dart';
export 'shared/widgets/platform_widget.dart';

// --- Inputs & Controls ---
export 'shared/widgets/buttons/app_button.dart';
export 'shared/widgets/buttons/glossy_button.dart';
export 'shared/widgets/buttons/reset_button.dart';
export 'shared/widgets/inputs/app_text_field.dart';
export 'shared/widgets/inputs/glass_text_field.dart';
export 'shared/widgets/inputs/app_segmented_control.dart';
export 'shared/widgets/inputs/custom_dropdown.dart';
export 'shared/widgets/inputs/multi_select_dropdown.dart';
export 'shared/widgets/inputs/dropdown_styles.dart';
export 'shared/widgets/inputs/compact_date_range_picker.dart';

// --- Display & Cards ---
export 'shared/widgets/display/pill_selector.dart';
export 'shared/widgets/display/glass_card.dart';
export 'shared/widgets/display/architecture_card.dart';
export 'shared/widgets/cards/app_card.dart';
export 'shared/widgets/cards/investment_card.dart';
export 'shared/widgets/cards/am_stat_card.dart';
export 'shared/widgets/portfolio_display_controller.dart';
export 'shared/widgets/display/interactive_background.dart';
// Heatmaps
export 'core/app_logic/domain/entities/heatmap/heatmap_entities.dart';
export 'shared/models/heatmap.dart';
export 'shared/widgets/heatmap/universal_heatmap.dart';
export 'shared/widgets/heatmap/heatmap_config.dart';
export 'shared/widgets/heatmap/core/heatmap_selector_core.dart';
export 'shared/widgets/heatmap/configs/display_config.dart';
export 'shared/widgets/heatmap/configs/interaction_config.dart';
export 'shared/widgets/heatmap/configs/layout_config.dart';
export 'shared/widgets/heatmap/configs/selector_config.dart';
export 'shared/widgets/heatmap/configs/visual_config.dart';
export 'shared/widgets/heatmap/loaders/heatmap_skeleton_loader.dart';
export 'shared/widgets/heatmap/templates/mobile_heatmap_defaults.dart';
export 'shared/widgets/heatmap/templates/web_heatmap_defaults.dart';

// Calendar
export 'shared/widgets/calendar/year_calendar/year_calendar.dart';
export 'shared/widgets/calendar/year_calendar/year_calendar_widget.dart';
export 'shared/widgets/calendar/universal_calendar/universal_calendar_widget.dart';
export 'shared/widgets/calendar/universal_calendar/calendar_types.dart';
export 'shared/widgets/calendar/universal_calendar/types.dart';
export 'shared/widgets/calendar/universal_calendar/card_types.dart';
export 'shared/widgets/calendar/universal_calendar/data_provider.dart';

// Tables & Charts
export 'shared/widgets/tables/sortable_table.dart';
export 'shared/widgets/tables/adaptive_data_table.dart';
export 'shared/widgets/charts/chart_factory.dart';
export 'shared/widgets/charts/chart_types.dart';

// Portfolio Charts & Models
export 'shared/widgets/portfolio_overview/models/portfolio_overview_data.dart';
export 'shared/widgets/portfolio_overview/charts/sector_allocation/animated_sector_donut_chart.dart';
export 'shared/widgets/portfolio_overview/charts/market_cap_allocation/animated_market_cap_chart.dart';

// --- Selectors ---
export 'shared/widgets/selectors/sector_selector.dart' show SectorType, SectorSelector;
export 'shared/widgets/selectors/metric_selector.dart' show MetricType, MetricSelector;
export 'shared/widgets/selectors/time_frame_selector.dart' show TimeFrame, TimeFrameSelector;
export 'shared/widgets/selectors/market_cap_selector.dart' show MarketCapType, MarketCapSelector;
export 'shared/widgets/selectors/heatmap_layout_selector.dart' show HeatmapLayoutType, HeatmapLayoutSelector;
export 'shared/widgets/selectors/shared_portfolio_selector.dart';

// --- Feedback & Loading ---
export 'shared/widgets/feedback/shimmer_loading.dart';
export 'shared/widgets/feedback/animated_page_transition.dart';
export 'shared/widgets/feedback/animated_list_item.dart';

// --- Filters ---
export 'shared/widgets/filters/am_filter_panel.dart';
export 'shared/widgets/feedback/animated_login_elements.dart';

// --- Global Models ---
export 'shared/models/user.dart';
export 'shared/models/holding.dart';
// export 'shared/models/file_upload_models.dart';
// export 'models/investment_card/investment_data.dart'; // Missing model
