import 'package:am_market_ui/features/ipo/screens/ipo_details_screen.dart';
import 'package:flutter/material.dart';

/// Keeps card and table actions on the existing IPO details route.
void openIpoDetails(BuildContext context, String ipoId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => IpoDetailsScreen(
        ipoId: ipoId,
        embedded: true,
      ),
    ),
  );
}
