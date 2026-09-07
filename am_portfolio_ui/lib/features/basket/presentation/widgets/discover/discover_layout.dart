import 'package:am_design_system/am_design_system.dart';

/// Discover layout constants (DS tokens used elsewhere).
class DiscoverLayout {
  DiscoverLayout._();

  static const double cardHeight = 188;
  static const double gridGap = 12;
  static const double sectionGap = 20;
  static const double filterInternalGap = 0;
  static const double filtersToContentGap = AppSpacing.md;
  static const double actionMinWidth = 96;
  static const double ctaMinHeight = 36;
  static const double tableMinScrollWidth = 720;

  /// Mobile dense list (AppSpacing compositions only).
  static const double mobileCardPadding = AppSpacing.sm + AppSpacing.xxs;
  static const double mobileListGap = AppSpacing.sm;
  static const double mobileTileSize = 36;
  static const double matchRingMobile = 36;
  static const double mobileMetaGap = AppSpacing.xs;

  static const double matchRingCard = 44;
  static const double matchRingTable = 26;
  static const double sparklineWidth = 56;
  static const double sparklineHeight = 24;
  static const double avatarRadius = 12;

  static const double headerBlockHeight = 36;

  static const int flexBasket = 28;
  static const int flexCategory = 15;
  static const int flexConstituents = 9;
  static const int flexMatch = 14;
  static const int flexPerf = 14;
  static const int flexRequired = 12;
  static const int flexAction = 12;

  static int get flexTotal =>
      flexBasket +
      flexCategory +
      flexConstituents +
      flexMatch +
      flexPerf +
      flexRequired +
      flexAction;

  static bool get cardHeightInRange =>
      cardHeight >= 180 && cardHeight <= 210;
}
