part of 'app_shell.dart';

/// Paid-subscriber gold ring around the global-sidebar avatar.
Widget buildShellSidebarAvatar({
  required String displayName,
  String? photoUrl,
}) {
  final isPaid = GetIt.I.isRegistered<am_sub.SubscriptionCubit>() &&
      GetIt.I<am_sub.SubscriptionCubit>().isPaidSubscription;
  final avatar = common.UserAvatar(
    radius: 20,
    displayName: displayName,
    remotePhotoUrl: photoUrl,
  );
  if (!isPaid) return avatar;
  return Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.center,
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: avatar,
      ),
      Positioned(
        top: -4,
        child: Icon(
          Icons.workspace_premium_rounded,
          size: 14,
          color: const Color(0xFFFFB300),
          shadows: [
            Shadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.8),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    ],
  );
}
