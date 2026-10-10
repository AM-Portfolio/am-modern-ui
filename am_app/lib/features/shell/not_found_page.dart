import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'browser_back_stub.dart' if (dart.library.html) 'browser_back_web.dart';

/// Full-route miss (go_router [errorBuilder]) — Bull & Bear 404 art + CTAs.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({
    super.key,
    required this.uri,
    required this.isAuthenticated,
  });

  final Uri uri;
  final bool isAuthenticated;

  static const assetPath = 'assets/images/bull_bear_404.png';

  void _goDashboard(BuildContext context) {
    if (isAuthenticated) {
      context.go(AppRoutes.dashboard);
      return;
    }
    context.go(AuthRedirect.recoverLoginLocation(uri));
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    browserHistoryBack(fallback: () => _goDashboard(context));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Edge-to-edge art (no inset card / letterboxing).
          Positioned.fill(
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: Center(
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
          // Soft bottom scrim so CTAs stay readable on any crop.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.28,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC000000),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    'Page not found: $uri',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: () => _goBack(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                      FilledButton(
                        onPressed: () => _goDashboard(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          isAuthenticated ? 'Dashboard' : 'Login',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
