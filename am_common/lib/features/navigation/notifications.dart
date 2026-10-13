import 'package:flutter/material.dart';

/// Bubbles when an in-shell form (add trade, etc.) gains or loses real edits.
/// Parents should only show "Discard unsaved changes?" while [isDirty] is true.
class ShellOperationDirtyNotification extends Notification {
  ShellOperationDirtyNotification(this.isDirty);
  final bool isDirty;
}

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
