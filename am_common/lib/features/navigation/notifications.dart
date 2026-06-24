import 'package:flutter/material.dart';

/// Notification to request opening the Add Trade screen.
/// Bubbles up the widget tree to be handled by a global router or shell.
class OpenAddTradeNotification extends Notification {
  final String? portfolioId;
  final String? portfolioName;
  final VoidCallback? onTradeAdded;
  final Object? existingTrade;
  bool handled = false;

  OpenAddTradeNotification({
    this.portfolioId,
    this.portfolioName,
    this.onTradeAdded,
    this.existingTrade,
  });
}
