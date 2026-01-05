import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/responsive_helper.dart';
import 'package:am_design_system/shared/widgets/display/interactive_background.dart';
import 'package:am_design_system/shared/widgets/media/background_audio_control.dart';
import 'package:am_design_system/shared/widgets/inputs/theme_selector.dart';

class AuthLayout extends StatefulWidget {
  final Widget child;
  final bool showBranding;

  const AuthLayout({
    super.key,
    required this.child,
    this.showBranding = true,
  });

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  BackgroundTheme _currentTheme = BackgroundTheme.nebula;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    // Responsive control positioning
    final controlsTop = isMobile ? 8.0 : 24.0;
    final controlsRight = isMobile ? 8.0 : 24.0;
    final controlsSpacing = isMobile ? 6.0 : 16.0;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Dark Navy)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A2E), // Dark Navy
                    const Color(0xFF16213E), // Slightly lighter Navy
                    const Color(0xFF0F3460).withValues(alpha: 0.8), // Deep Blue
                  ],
                ),
              ),
            ),
          ),
          
          // Full Screen Background Animation
          Positioned.fill(
            child: InteractiveBackground(
              baseColor: Theme.of(context).primaryColor,
              highlightColor: _currentTheme == BackgroundTheme.market 
                  ? Colors.greenAccent 
                  : Colors.tealAccent,
              theme: _currentTheme,
            ),
          ),

          // Content Layer (Responsive)
          Positioned.fill(
            child: widget.showBranding && kIsWeb
                ? (isMobile
                    ? _buildCenteredLayout()
                    : isTablet
                        ? _buildTabletLayout()
                        : _buildWebLayout())
                : _buildCenteredLayout(),
          ),

          // Controls Layer (Top Right - Responsive)
          Positioned(
            top: controlsTop,
            right: controlsRight,
            child: Row(
              children: [
                ThemeSelector(
                  currentTheme: _currentTheme,
                  onThemeChanged: (theme) => setState(() => _currentTheme = theme),
                ),
                SizedBox(width: controlsSpacing),
                const BackgroundAudioControl(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            // Left side - Branding
            Expanded(
              flex: 5,
              child: _buildBranding(),
            ),
            // Right side - Form
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: _buildGlassContainer(widget.child, maxWidth: 450, padding: 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showBranding) ...[
                _buildCompactBranding(),
                const SizedBox(height: 28),
              ],
              _buildGlassContainer(widget.child, maxWidth: 500, padding: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredLayout() {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = isMobile ? 12.0 : 16.0;
    final spacing = isMobile ? 24.0 : 32.0;
    final containerPadding = isMobile ? 20.0 : 24.0;
    
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showBranding) ...[
                _buildMobileBranding(),
                SizedBox(height: spacing),
              ],
              _buildGlassContainer(widget.child, maxWidth: double.infinity, padding: containerPadding),
            ],
          ),
        ),
      ),
    );
  }

  /// Glassmorphic container for the form (Responsive)
  Widget _buildGlassContainer(Widget child, {required double maxWidth, required double padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: BoxDecoration(
             color: Colors.white.withValues(alpha: 0.7),
             borderRadius: BorderRadius.circular(24),
             border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
             boxShadow: [
               BoxShadow(
                 color: Colors.black.withValues(alpha: 0.1),
                 blurRadius: 30,
                 spreadRadius: 5,
               ),
             ],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildBranding() {
     return Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 32),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 64,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                children: const [
                  TextSpan(text: 'AM\n'),
                  TextSpan(text: 'Investment'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your gateway to smart\nportfolio management',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 24,
                height: 1.3,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildFeatureItem('📊 Real-time analytics'),
            const SizedBox(height: 16),
            _buildFeatureItem('📈 Smart tracking'),
            const SizedBox(height: 16),
            _buildFeatureItem('🔍 Market insights'),
            const SizedBox(height: 16),
            _buildFeatureItem('💼 Portfolio tools'),
          ],
        ),
      );
  }

  Widget _buildMobileBranding() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
              height: 1.2,
              shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
            ),
            children: const [
              TextSpan(text: 'AM\n'),
              TextSpan(text: 'Investment'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Smart portfolio\nmanagement',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            height: 1.3,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 3)],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBranding() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
              height: 1.1,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(2, 2),
                  blurRadius: 10,
                ),
              ],
            ),
            children: const [
              TextSpan(text: 'AM\n'),
              TextSpan(text: 'Investment'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Smart portfolio\nmanagement',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            height: 1.3,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(1, 1),
                blurRadius: 5,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _buildFeatureItem('📊 Real-time analytics'),
        const SizedBox(height: 10),
        _buildFeatureItem('📈 Smart tracking'),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
