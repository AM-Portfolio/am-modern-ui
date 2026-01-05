import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Google Sign-In button widget
/// On web: Renders Google's official button
/// On mobile: Custom styled button
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  // No special initialization needed for web
  // The GoogleSignInWeb service handles the popup directly

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebButton(context);
    } else {
      return _buildMobileButton(context);
    }
  }

  Widget _buildWebButton(BuildContext context) {
    if (widget.isLoading) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    // For now, use the same custom button for web
    // The Google Identity Services will handle the actual OAuth
    return _buildMobileButton(context);
  }

  Widget _buildMobileButton(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
      ),
      child: widget.isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google logo
                Image.network(
                  'https://developers.google.com/identity/images/g-logo.png',
                  height: 20,
                  width: 20,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
    ),
  );
}
