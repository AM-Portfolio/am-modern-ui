import 'package:am_market_ui/features/dashboard/domain/dashboard_section_id.dart';
import 'package:am_market_ui/features/dashboard/domain/section_view_model.dart';

/// Data port for one dashboard section — no Flutter / no layout.
abstract class DashboardSectionPort {
  DashboardSectionId get id;

  /// Build a view-model for the current TF / drill context.
  Future<SectionViewModel> load({
    required String timeframe,
    String? focusedIndex,
  });
}
