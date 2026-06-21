import 'dart:async';

import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] when [AuthCubit] state changes for redirect refresh.
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(AuthCubit authCubit) {
    _subscription = authCubit.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
