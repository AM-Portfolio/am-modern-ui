import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pending symbol from Global Search to add/select on the Paper desk watchlist.
class PaperSymbolDiscoveryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;

  void clear() => state = null;
}

final paperSymbolDiscoveryProvider =
    NotifierProvider<PaperSymbolDiscoveryNotifier, String?>(
  PaperSymbolDiscoveryNotifier.new,
);
