/// UI and styling constants
class UIConstants {
  /// Colors
  static const int primaryColorValue = 0xFF2196F3; // Blue
  static const int secondaryColorValue = 0xFF03DAC6; // Teal
  static const int errorColorValue = 0xFFB00020; // Red
  static const int surfaceColorValue = 0xFFFFFFFF; // White
  static const int backgroundColorValue = 0xFFFAFAFA; // Light Gray
  
  /// Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  
  /// Border Radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXl = 16.0;
  
  /// Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  /// Animation Duration
  static const int animationShort = 200; // milliseconds
  static const int animationMedium = 300; // milliseconds
  static const int animationLong = 500; // milliseconds
  
  /// Breakpoints for responsive design
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  
  /// Icon Sizes
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXl = 48.0;
  static const double iconSizeXxl = 64.0;
  
  /// Font Sizes
  static const double fontSizeCaption = 12.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeSubtitle = 16.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeHeadline = 24.0;
  static const double fontSizeDisplay = 32.0;
}

/// Platform-specific constants
class PlatformConstants {
  /// Mobile platforms
  static const List<String> mobilePlatforms = ['android', 'ios'];
  
  /// Desktop platforms
  static const List<String> desktopPlatforms = ['windows', 'macos', 'linux'];
  
  /// Web platform
  static const String webPlatform = 'web';
  
  /// Platform specific sizes
  static const double mobileAppBarHeight = 56.0;
  static const double desktopAppBarHeight = 64.0;
  static const double mobileBottomNavHeight = 56.0;
  
  /// Platform specific paddings
  static const double mobilePadding = 16.0;
  static const double tabletPadding = 24.0;
  static const double desktopPadding = 32.0;
}