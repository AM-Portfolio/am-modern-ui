import 'package:flutter/foundation.dart';

/// Cross-module signal: holdings were imported / synced — reload portfolio UIs.
///
/// Doc-intel and Gmail sync call [notifyImported]; Portfolio / Trade / Dashboard
/// listen and refetch without requiring a full page refresh.
class PortfolioDataRefresh extends ChangeNotifier {
  PortfolioDataRefresh._();
  static final PortfolioDataRefresh instance = PortfolioDataRefresh._();

  int _generation = 0;
  String? _lastPortfolioId;

  int get generation => _generation;
  String? get lastPortfolioId => _lastPortfolioId;

  void notifyImported({String? portfolioId}) {
    _lastPortfolioId = portfolioId;
    _generation++;
    notifyListeners();
  }
}
