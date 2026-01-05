import 'package:flutter/material.dart';

/// A dropdown menu widget for displaying user profile options
/// Typically used in the app header or navigation bar
class UserDropdownMenu extends StatelessWidget {
  const UserDropdownMenu({
    required this.userName,
    this.userEmail,
    this.onLogout,
    this.onProfile,
    this.child,
    super.key,
  });

  /// The user's display name
  final String userName;

  /// The user's email address (optional)
  final String? userEmail;

  /// Callback when logout is selected
  final VoidCallback? onLogout;

  /// Callback when profile is selected
  final VoidCallback? onProfile;

  /// Optional child widget to customize the dropdown trigger
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // If custom child is provided, use PopupMenuButton for full control
    if (child != null) {
      return PopupMenuButton<String>(
        tooltip: 'User Menu',
        offset: const Offset(0, 40),
        itemBuilder: _buildMenuItems,
        onSelected: _handleMenuSelection,
        child: child,
      );
    }

    // Otherwise use the default trigger with user info display
    return PopupMenuButton<String>(
      tooltip: 'User Menu',
      offset: const Offset(0, 40),
      itemBuilder: _buildMenuItems,
      onSelected: _handleMenuSelection,
      child: _buildDefaultTrigger(context),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) => [
    // User info header
    PopupMenuItem<String>(
      enabled: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (userEmail != null) ...[
            const SizedBox(height: 2),
            Text(
              userEmail!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    ),

    // Profile option
    PopupMenuItem<String>(
      value: 'profile',
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          const Text('Profile'),
        ],
      ),
    ),

    // Settings option
    PopupMenuItem<String>(
      value: 'settings',
      child: Row(
        children: [
          Icon(Icons.settings_outlined, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          const Text('Settings'),
        ],
      ),
    ),

    // Divider
    const PopupMenuDivider(),

    // Logout option
    PopupMenuItem<String>(
      value: 'logout',
      child: Row(
        children: [
          Icon(Icons.logout, size: 18, color: Colors.red[600]),
          const SizedBox(width: 12),
          Text('Logout', style: TextStyle(color: Colors.red[600])),
        ],
      ),
    ),
  ];

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        onProfile?.call();
        break;
      case 'settings':
        // Handle settings - for now show a snackbar
        // Note: We need context here, but it's not available in this callback
        // The calling widget should handle this
        onProfile?.call(); // Placeholder for now
        break;
      case 'logout':
        onLogout?.call();
        break;
    }
  }

  Widget _buildDefaultTrigger(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            if (userEmail != null)
              Text(
                userEmail!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[600]),
      ],
    ),
  );
}
