import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'dart:ui';

/// Profile and Settings page for user account management
class ProfileSettingsPage extends StatelessWidget {
  final String userId;

  const ProfileSettingsPage({
    required this.userId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        titleTextStyle: const TextStyle(
          color: Colors.white, complete
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: AppGlassmorphismV2.techBackground(isDark: isDark),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final contentWidth = isDesktop ? 800.0 : constraints.maxWidth;

              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      children: [
                        // Profile Header
                        _buildProfileHeader(context, isDark),
                        
                        const SizedBox(height: 32),
                        
                        // Settings Content
                        _buildSettingsContent(context, isDark),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isDark) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ModuleColors.portfolio.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: isDark ? const Color(0xFF2C2C3E) : Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: ModuleColors.portfolio.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: ModuleColors.portfolio,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ModuleColors.portfolio,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF1F1F2E) : Colors.white,
                  width: 3,
                ),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          userId,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'User ID',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copyUserId(context, userId),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: ModuleColors.portfolio,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Account Section
        _buildSectionHeader(context, 'Account', isDark),
        const SizedBox(height: 16),
        _buildGlassSection(
          context,
          isDark,
          children: [
             _buildSettingTile(
              context,
              icon: Icons.email_outlined,
              title: 'Email Address',
              subtitle: 'Not set',
              isDark: isDark,
              onTap: () => _showEditEmailDialog(context),
            ),
            _buildDivider(isDark),
             _buildSettingTile(
              context,
              icon: Icons.lock_outline,
              title: 'Change Password',
              isDark: isDark,
              onTap: () => _showChangePasswordDialog(context),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Preferences Section
        _buildSectionHeader(context, 'Preferences', isDark),
        const SizedBox(height: 16),
        _buildGlassSection(
          context,
          isDark,
          children: [
            _buildSettingTile(
              context,
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              title: 'Theme Mode',
              subtitle: isDark ? 'Dark Mode' : 'Light Mode',
              isDark: isDark,
              trailing: Switch(
                value: isDark,
                onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                activeColor: ModuleColors.portfolio,
              ),
            ),
            _buildDivider(isDark),
            _buildSettingTile(
              context,
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Manage alerts and push notifications',
              isDark: isDark,
              onTap: () => _showNotificationSettings(context),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // About Section
        _buildSectionHeader(context, 'About', isDark),
        const SizedBox(height: 16),
        _buildGlassSection(
          context,
          isDark,
           children: [
            _buildSettingTile(
              context,
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0 (Build 100)',
              isDark: isDark,
              trailing: const SizedBox(), // No chevron
            ),
            _buildDivider(isDark),
            _buildSettingTile(
              context,
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              isDark: isDark,
            ),
             _buildDivider(isDark),
            _buildSettingTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassSection(BuildContext context, bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1a1a2e).withOpacity(0.6) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : ModuleColors.portfolio.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : ModuleColors.portfolio,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 0,
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change functionality coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Email'),
        content: const Text('Email edit functionality coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Text('Notification settings coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _copyUserId(BuildContext context, String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User ID copied to clipboard')),
    );
  }
}
