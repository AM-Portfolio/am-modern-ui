import 'package:am_market_ui/features/ipo/screens/ipo_details_screen.dart';
import 'package:am_market_ui/features/ipo/screens/ipo_landing_screen.dart';
import 'package:flutter/material.dart';

/// Nested navigator for IPO Center so list → detail stays inside the Market
/// shell (module pills / sidebar remain visible).
class IpoCenterHost extends StatefulWidget {
  const IpoCenterHost({super.key});

  static const listRoute = '/';
  static const detailsRoute = '/details';

  @override
  State<IpoCenterHost> createState() => _IpoCenterHostState();
}

class _IpoCenterHostState extends State<IpoCenterHost> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navKey.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
          return;
        }
        final root = Navigator.of(context);
        if (root.canPop()) {
          root.pop();
        }
      },
      child: Navigator(
        key: _navKey,
        initialRoute: IpoCenterHost.listRoute,
        onGenerateRoute: (settings) {
          final name = settings.name ?? IpoCenterHost.listRoute;

          if (name == IpoCenterHost.detailsRoute) {
            final ipoId = settings.arguments as String? ?? '';
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => IpoDetailsScreen(
                ipoId: ipoId,
                embedded: true,
              ),
            );
          }

          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const IpoLandingScreen(embedded: true),
          );
        },
      ),
    );
  }
}
