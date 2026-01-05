import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';

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
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Avatar & Info
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: ModuleColors.portfolio.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: ModuleColors.portfolio,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userId,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'User ID',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Quick Actions Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildQuickAction(
                context,
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => _showChangePasswordDialog(context),
              ),
              _buildQuickAction(
                context,
                icon: Icons.email_outlined,
                label: 'Email',
                onTap: () => _showEditEmailDialog(context),
              ),
              _buildQuickAction(
                context,
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                label: 'Toggle Theme',
                onTap: () => context.read<ThemeCubit>().toggleTheme(),
              ),
              _buildQuickAction(
                context,
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => _showNotificationSettings(context),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Account Information Section
          _buildSection(
            context,
            title: 'Account Information',
            icon: Icons.person_outline,
            children: [
              _buildListTile(
                context,
                title: 'User ID',
                subtitle: userId,
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyUserId(context, userId),
                ),
              ),
              const Divider(),
              _buildListTile(
                context,
                title: 'Email',
                subtitle: 'Not set',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditEmailDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Security Section
          _buildSection(
            context,
            title: 'Security',
            icon: Icons.security_outlined,
            children: [
              _buildListTile(
                context,
                title: 'Change Password',
                subtitle: 'Update your account password',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showChangePasswordDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Preferences Section
          _buildSection(
            context,
            title: 'Preferences',
            icon: Icons.tune,
            children: [
              _buildListTile(
                context,
                title: 'Theme',
                subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                  activeColor: ModuleColors.portfolio,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // About Section
          _buildSection(
            context,
            title: 'About',
            icon: Icons.info_outline,
            children: [
              _buildListTile(
                context,
                title: 'App Version',
                subtitle: '1.0.0',
              ),
              const Divider(),
              _buildListTile(
                context,
                title: 'Terms & Conditions',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(),
              _buildListTile(
                context,
                title: 'Privacy Policy',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ModuleColors.portfolio.withOpacity(0.2),
              ModuleColors.portfolio.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ModuleColors.portfolio.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: ModuleColors.portfolio,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ModuleColors.portfolio,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: ModuleColors.portfolio),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
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
