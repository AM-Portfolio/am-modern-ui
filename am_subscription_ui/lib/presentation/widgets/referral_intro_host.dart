import 'package:am_common/am_common.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../data/datasources/subscription_remote_datasource.dart';

/// Shows a one-time sheet: “You joined with invite CODE.”
class ReferralIntroHost {
  ReferralIntroHost._();

  static bool _inFlight = false;

  /// Call after the user is authenticated and a navigator is available.
  static Future<void> maybeShow(BuildContext context, String userId) async {
    if (_inFlight || userId.isEmpty || !context.mounted) return;
    _inFlight = true;
    try {
      final store = ReferralInstallStore.instance;
      if (await store.isIntroSeen(userId)) return;
      if (!GetIt.instance.isRegistered<SubscriptionRemoteDataSource>()) return;

      final summary =
          await GetIt.instance<SubscriptionRemoteDataSource>().getReferralSummary();
      final joined = summary.joined;
      if (joined == null || joined.code.isEmpty) {
        // No attribution — never show; mark seen so we do not re-hit the API.
        await store.markIntroSeen(userId);
        return;
      }
      if (!context.mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You joined with invite',
                    style: Theme.of(sheetContext).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    joined.code,
                    textAlign: TextAlign.center,
                    style: Theme.of(sheetContext).textTheme.headlineMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          );
        },
      );
      await store.markIntroSeen(userId);
    } catch (_) {
      // Silent — first-run is best-effort.
    } finally {
      _inFlight = false;
    }
  }
}
