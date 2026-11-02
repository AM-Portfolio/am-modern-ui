import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/screens/ipo_center_host.dart';
import 'package:flutter/material.dart';

/// Keeps card and table actions on the nested IPO Center navigator route.
void openIpoDetails(BuildContext context, String ipoId) {
  Navigator.of(context).pushNamed(
    IpoCenterHost.detailsRoute,
    arguments: ipoId,
  );
}

/// Opens an IPO only when the backend has supplied a complete bidding window.
///
/// Upcoming records without announced dates remain visible in the listing, but
/// are intentionally not navigable until both dates are present in the API
/// response.
Future<void> openIpoDetailsForSummary(
  BuildContext context,
  AsraxIpoSummaryDto ipo,
) async {
  if (!ipoHasAnnouncedBiddingDates(ipo)) {
    await InformationDialog.show(
      context: context,
      title: 'Date not announced yet',
      message: 'Stay tuned with AM Investments.',
    );
    return;
  }

  openIpoDetails(context, ipo.id);
}

/// A bidding date is announced only when both ends of the window are present.
/// This mirrors the backend payload and does not infer dates from status.
bool ipoHasAnnouncedBiddingDates(AsraxIpoSummaryDto ipo) {
  return _hasValue(ipo.biddingStartDate) && _hasValue(ipo.biddingEndDate);
}

bool _hasValue(String? value) => value?.trim().isNotEmpty == true;
