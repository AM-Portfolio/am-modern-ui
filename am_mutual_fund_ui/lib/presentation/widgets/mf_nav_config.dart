import 'package:flutter/material.dart';

/// Secondary-sidebar destinations for the Mutual Funds desk.
class MfNavDest {
  const MfNavDest({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.path,
    required this.icon,
  });

  final String id;
  final String label;
  final String shortLabel;
  final String path;
  final IconData icon;
}

const mfBrowseDests = <MfNavDest>[
  MfNavDest(
    id: 'explore',
    label: 'Explore',
    shortLabel: 'Explore',
    path: '/app/mutual-funds',
    icon: Icons.explore_outlined,
  ),
  MfNavDest(
    id: 'holdings',
    label: 'Holdings',
    shortLabel: 'Holdings',
    path: '/app/mutual-funds/holdings',
    icon: Icons.account_balance_wallet_outlined,
  ),
  MfNavDest(
    id: 'history',
    label: 'History',
    shortLabel: 'History',
    path: '/app/mutual-funds/history',
    icon: Icons.history_outlined,
  ),
];

const mfAccountDests = <MfNavDest>[
  MfNavDest(
    id: 'onboarding',
    label: 'Onboarding',
    shortLabel: 'Onboard',
    path: '/app/mutual-funds/onboarding',
    icon: Icons.badge_outlined,
  ),
  MfNavDest(
    id: 'systematic',
    label: 'Systematic',
    shortLabel: 'SIP',
    path: '/app/mutual-funds/systematic',
    icon: Icons.autorenew_rounded,
  ),
  MfNavDest(
    id: 'stpSwp',
    label: 'STP / SWP',
    shortLabel: 'STP',
    path: '/app/mutual-funds/stp-swp',
    icon: Icons.swap_horiz_rounded,
  ),
];

/// Which primary dest should highlight for [path].
String mfSelectedDestId(String path) {
  if (path.startsWith('/app/mutual-funds/redeem') ||
      path.startsWith('/app/mutual-funds/switch') ||
      path == '/app/mutual-funds/holdings' ||
      path.startsWith('/app/mutual-funds/holdings/')) {
    return 'holdings';
  }
  if (path == '/app/mutual-funds/history' ||
      path.startsWith('/app/mutual-funds/history/')) {
    return 'history';
  }
  if (path == '/app/mutual-funds/onboarding' ||
      path.startsWith('/app/mutual-funds/onboarding/')) {
    return 'onboarding';
  }
  if (path == '/app/mutual-funds/systematic' ||
      path.startsWith('/app/mutual-funds/systematic/')) {
    return 'systematic';
  }
  if (path == '/app/mutual-funds/stp-swp' ||
      path.startsWith('/app/mutual-funds/stp-swp/')) {
    return 'stpSwp';
  }
  // schemes / invest / orders / explore root
  return 'explore';
}
