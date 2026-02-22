import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:am_common/am_common.dart';

/// Utility class for handling logout functionality
class PortfolioLogoutHandler {
  /// Shows logout confirmation dialog
  static void showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            child: const Text('Logout'),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performLogout(context);
            },
          ),
        ],
      ),
    );
  }

  /// Performs the actual logout process
  static Future<void> _performLogout(BuildContext context) async {
    CommonLogger.userAction(
      'User logout initiated',
      tag: 'PortfolioLogoutHandler',
    );

    try {
      // Clear authentication state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_authenticated');
      await prefs.remove('user_id');

      CommonLogger.info(
        'Authentication state cleared successfully',
        tag: 'PortfolioLogoutHandler',
      );
    } catch (e) {
      CommonLogger.error(
        'Failed to clear SharedPreferences during logout',
        tag: 'PortfolioLogoutHandler',
        error: e,
      );
      // Continue with logout even if SharedPreferences fails
    }

    // Navigate back to root and clear all routes
    if (context.mounted) {
      CommonLogger.info(
        'Navigating to login screen',
        tag: 'PortfolioLogoutHandler',
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}

