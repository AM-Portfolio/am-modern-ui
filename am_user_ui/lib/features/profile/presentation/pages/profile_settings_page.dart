import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'dart:ui';

import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

/// Profile and Settings page for user account management
class ProfileSettingsPage extends StatefulWidget {
  final String userId;
  final String? email;
  final String? displayName;

  /// Prefer these for in-shell navigation (GoRouter). When null, falls back to
  /// [Navigator.push] of the in-app legal pages.
  final VoidCallback? onOpenPrivacyPolicy;
  final VoidCallback? onOpenTermsOfService;

  /// Opens the existing subscription / pricing screen via GoRouter when set.
  final VoidCallback? onOpenSubscription;

  /// When true (e.g. returning from Subscription), pulse Account + Subscription.
  final bool highlightSubscription;

  /// Live plan label from `/subscriptions/me` (e.g. `"Free · Active"`).
  final String? subscriptionStatusLabel;

  /// True when plan is Pro/Premium (not free). Hides upgrade upsell copy.
  final bool? isPaidSubscription;

  const ProfileSettingsPage({
    required this.userId,
    this.email,
    this.displayName,
    this.onOpenPrivacyPolicy,
    this.onOpenTermsOfService,
    this.onOpenSubscription,
    this.highlightSubscription = false,
    this.subscriptionStatusLabel,
    this.isPaidSubscription,
    super.key,
  });

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _highlightController;
  late final Animation<double> _highlightPulse;
  final GlobalKey _subscriptionTileKey = GlobalKey();
  bool _highlightActive = false;

  String get userId => widget.userId;
  String? get email => widget.email;
  String? get displayName => widget.displayName;
  VoidCallback? get onOpenPrivacyPolicy => widget.onOpenPrivacyPolicy;
  VoidCallback? get onOpenTermsOfService => widget.onOpenTermsOfService;
  VoidCallback? get onOpenSubscription => widget.onOpenSubscription;
  String? get subscriptionStatusLabel => widget.subscriptionStatusLabel;
  bool get isPaidSubscription => widget.isPaidSubscription ?? false;


  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _highlightPulse = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    );
    if (widget.highlightSubscription) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startHighlight());
    }
  }

  @override
  void didUpdateWidget(covariant ProfileSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightSubscription && !oldWidget.highlightSubscription) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startHighlight());
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  Future<void> _startHighlight() async {
    if (!mounted) return;
    setState(() => _highlightActive = true);

    final ctx = _subscriptionTileKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.35,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) return;
    _highlightController.repeat(reverse: true);
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    _highlightController.stop();
    _highlightController.value = 0;
    setState(() => _highlightActive = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: isDark ? Colors.white : Colors.black87,
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        //   onPressed: () => Navigator.pop(context),
        // ),
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

                        if (onOpenSubscription != null && !isDesktop) ...[
                          const SizedBox(height: 24),
                          _buildPremiumUpgradeCard(context, isDark),
                        ],

                        const SizedBox(height: 32),

                        // Settings Content
                        _buildSettingsContent(context, isDark, isDesktop),
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

  Widget _buildPremiumUpgradeCard(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenSubscription,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF3D1F3A),
                      Color(0xFF1F1630),
                      Color(0xFF2A1848),
                    ]
                  : const [
                      Color(0xFFFFE8F0),
                      Color(0xFFFFF0F5),
                      Color(0xFFEDE7FF),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : ModuleColors.portfolio.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: ModuleColors.portfolio.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.85),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: ModuleColors.portfolio,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPaidSubscription
                            ? (subscriptionStatusLabel ?? 'Premium plan')
                            : 'Unlock more with Premium',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isPaidSubscription
                      ? 'You’re on a paid plan. Manage billing, change plans, or review access anytime.'
                      : 'Live data, deeper analytics, and AI tools — upgrade to level up your portfolio experience.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onOpenSubscription,
                    style: FilledButton.styleFrom(
                      backgroundColor: ModuleColors.portfolio,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    child: Text(
                      isPaidSubscription ? 'Manage plan' : 'Explore plans',
                    ),
                  ),
                ),
              ],
            ),
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
          displayName != null && displayName!.isNotEmpty ? displayName! : userId,
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

  Widget _buildSettingsContent(BuildContext context, bool isDark, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Account Section
        _buildSectionHeader(context, 'Account', isDark),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _highlightPulse,
          builder: (context, child) {
            final glow = _highlightActive ? _highlightPulse.value : 0.0;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: glow > 0
                    ? [
                        BoxShadow(
                          color: ModuleColors.portfolio
                              .withValues(alpha: 0.18 + glow * 0.28),
                          blurRadius: 18 + glow * 12,
                          spreadRadius: glow * 2,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: _buildGlassSection(
            context,
            isDark,
            highlighted: _highlightActive,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.email_outlined,
                title: 'Email Address',
                subtitle:
                    (email != null && email!.isNotEmpty) ? email! : 'Not set',
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
              if (onOpenSubscription != null) ...[
                _buildDivider(isDark),
                KeyedSubtree(
                  key: _subscriptionTileKey,
                  child: AnimatedBuilder(
                    animation: _highlightPulse,
                    builder: (context, _) {
                      return _buildSettingTile(
                        context,
                        icon: Icons.subscriptions_outlined,
                        title: 'Subscription',
                        subtitle: subscriptionStatusLabel ??
                            'Plans, billing, and access',
                        isDark: isDark,
                        highlighted: _highlightActive,
                        highlightStrength:
                            _highlightActive ? _highlightPulse.value : 0,
                        onTap: onOpenSubscription!,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
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
              onTap: () => _openTerms(context),
            ),
             _buildDivider(isDark),
            _buildSettingTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              isDark: isDark,
              onTap: () => _openPrivacy(context),
            ),
          ],
        ),
        if (!isDesktop) ...[
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Session', isDark),
          const SizedBox(height: 16),
          _buildGlassSection(
            context,
            isDark,
            children: [
              _buildSettingTile(
                context,
                icon: Icons.logout_rounded,
                title: 'Log Out',
                subtitle: 'Sign out of your account',
                isDark: isDark,
                iconColor: Colors.redAccent,
                textColor: Colors.redAccent,
                trailing: const SizedBox(),
                onTap: () {
                  context.read<AuthCubit>().logout();
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGlassSection(
    BuildContext context,
    bool isDark, {
    required List<Widget> children,
    bool highlighted = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1a1a2e).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted
              ? ModuleColors.portfolio.withValues(alpha: isDark ? 0.55 : 0.45)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05)),
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
    Color? iconColor,
    Color? textColor,
    bool highlighted = false,
    double highlightStrength = 0,
  }) {
    final accent = ModuleColors.portfolio;
    final bgTint = highlighted
        ? accent.withValues(
            alpha: (isDark ? 0.12 : 0.08) + highlightStrength * 0.12,
          )
        : null;

    return Material(
      color: bgTint ?? Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: highlighted
                      ? accent.withValues(alpha: isDark ? 0.22 : 0.18)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : accent.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: highlighted
                      ? Border.all(
                          color: accent.withValues(alpha: 0.45),
                        )
                      : null,
                ),
                child: Icon(
                  icon,
                  color: iconColor ??
                      (isDark ? Colors.white : ModuleColors.portfolio),
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
                        color: textColor ??
                            (isDark ? Colors.white : Colors.black87),
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
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: highlighted
                        ? accent
                        : (isDark ? Colors.white24 : Colors.black26),
                    size: 20,
                  ),
            ],
          ),
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
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final authState = context.read<AuthCubit>().state;
        final email = authState is Authenticated ? authState.user.email : '';
        final isGoogle = authState is Authenticated &&
            authState.user.authMethod.toLowerCase().contains('google');

        if (isGoogle || email.isEmpty) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: Text(
              isGoogle
                  ? 'Google sign-in accounts manage passwords with Google. No local password to change.'
                  : 'Sign in with email to change your password.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                  validator: (v) =>
                      Validators.validatePasswordMatch(v, newController.text),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await context.read<AuthCubit>().changePassword(
                      email: email,
                      currentPassword: currentController.text,
                      newPassword: newController.text,
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated. Use your new password next sign-in.'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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

  void _openPrivacy(BuildContext context) {
    if (onOpenPrivacyPolicy != null) {
      onOpenPrivacyPolicy!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrivacyPolicyPage(
          onOpenTerms: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => TermsOfServicePage(
                  onOpenPrivacy: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openTerms(BuildContext context) {
    if (onOpenTermsOfService != null) {
      onOpenTermsOfService!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TermsOfServicePage(
          onOpenPrivacy: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => PrivacyPolicyPage(
                  onOpenTerms: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsOfServicePage(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
