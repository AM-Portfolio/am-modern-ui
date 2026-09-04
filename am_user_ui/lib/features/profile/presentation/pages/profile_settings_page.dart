import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final VoidCallback? onOpenActiveSessions;

  final VoidCallback? onOpenScanWebLogin;

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
    this.onOpenActiveSessions,
    this.onOpenScanWebLogin,
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
  VoidCallback? get onOpenActiveSessions => widget.onOpenActiveSessions;
  VoidCallback? get onOpenScanWebLogin => widget.onOpenScanWebLogin;
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
        foregroundColor: context.colors.textPrimary,
        title: Text(
          'Profile & Settings',
          style: context.text.pageTitle(compact: true).copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        // Profile Header
                        _buildProfileHeader(context, isDark),

                        if (onOpenSubscription != null && !isDesktop) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _buildPremiumUpgradeCard(context, isDark),
                        ],

                        const SizedBox(height: AppSpacing.xl),

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
        borderRadius: AppRadii.dialog,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadii.dialog,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.premiumGradientStart,
                context.colors.premiumGradientCenter,
                context.colors.premiumGradientEnd,
              ],
            ),
            border: Border.all(
              color: context.colors.premiumActionPrimary.withValues(alpha: 0.22),
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
                        color: context.colors.premiumActionPrimary.withValues(alpha: 0.15),
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
                        style: context.text.sectionTitle().copyWith(
                          color: context.colors.textPrimary,
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
                  style: context.text.bodyMuted().copyWith(
                    color: context.colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onOpenSubscription,
                    style: FilledButton.styleFrom(
                      backgroundColor: ModuleColors.portfolio,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.button,
                      ),
                      textStyle: context.text.button(compact: true),
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
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ModuleColors.portfolio.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: isDark
                ? context.cardColor
                : context.cardColor,
            child: CircleAvatar(
              radius: 56,
              backgroundColor: ModuleColors.portfolio.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                size: 60,
                color: ModuleColors.portfolio,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          displayName != null && displayName!.isNotEmpty
              ? displayName!
              : userId,
          style: context.text.pageTitle().copyWith(
            color: context.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + AppSpacing.xs,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: context.colors.surface.withValues(alpha: 0.05),
            borderRadius: AppRadii.dialog,
            border: Border.all(
              color: context.colors.border.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'User ID',
                style: context.text.caption().copyWith(
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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

  Widget _buildSettingsContent(
    BuildContext context,
    bool isDark,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Account Section
        _buildSectionHeader(context, 'Account', isDark),
        const SizedBox(height: AppSpacing.md),
        AnimatedBuilder(
          animation: _highlightPulse,
          builder: (context, child) {
            final glow = _highlightActive ? _highlightPulse.value : 0.0;
            return Container(
              decoration: BoxDecoration(
                borderRadius: AppRadii.card,
                boxShadow: glow > 0
                    ? [
                        BoxShadow(
                          color: ModuleColors.portfolio.withValues(
                            alpha: 0.18 + glow * 0.28,
                          ),
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
                subtitle: (email != null && email!.isNotEmpty)
                    ? email!
                    : 'Not set',
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
                        subtitle:
                            subscriptionStatusLabel ??
                            'Plans, billing, and access',
                        isDark: isDark,
                        highlighted: _highlightActive,
                        highlightStrength: _highlightActive
                            ? _highlightPulse.value
                            : 0,
                        onTap: onOpenSubscription!,
                      );
                    },
                  ),
                ),
              ],
              _buildDivider(isDark),
              _buildSettingTile(
                context,
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently remove your data',
                isDark: isDark,
                iconColor: context.colors.statusError,
                textColor: context.colors.statusError,
                trailing: const SizedBox(),
                onTap: () => _showDeleteAccountDialog(context, isDark),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        _buildSectionHeader(context, 'Security', isDark),
        const SizedBox(height: AppSpacing.md),
        _buildGlassSection(
          context,
          isDark,
          children: [
            if (!kIsWeb && onOpenScanWebLogin != null) ...[
              _buildSettingTile(
                context,
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan to log in on web',
                subtitle: 'Approve a browser login from your phone',
                isDark: isDark,
                onTap: onOpenScanWebLogin!,
              ),
              _buildDivider(isDark),
            ],
            _buildSettingTile(
              context,
              icon: Icons.devices_other_outlined,
              title: 'Active sessions',
              subtitle: 'Review browsers and devices signed in',
              isDark: isDark,
              onTap: onOpenActiveSessions ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Active sessions is unavailable here'),
                      ),
                    );
                  },
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // Preferences Section
        _buildSectionHeader(context, 'Preferences', isDark),
        const SizedBox(height: AppSpacing.md),
        _buildGlassSection(
          context,
          isDark,
          children: [
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                final currentMode = themeState.mode;
                String modeLabel = 'System Default';
                if (currentMode == AppThemeMode.light || currentMode == AppThemeMode.white) modeLabel = 'Light Mode';
                if (currentMode == AppThemeMode.dark) modeLabel = 'Dark Mode';
                if (currentMode == AppThemeMode.skyBlue) modeLabel = 'Sky Blue Mode';

                return _buildSettingTile(
                  context,
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  title: 'Theme Mode',
                  subtitle: modeLabel,
                  isDark: isDark,
                  onTap: () => _showThemeSelectionDialog(context, currentMode),
                  trailing: Text(
                    modeLabel,
                    style: context.text.body().copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                );
              },
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

        const SizedBox(height: AppSpacing.xl),

        // About Section
        _buildSectionHeader(context, 'About', isDark),
        const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader(context, 'Session', isDark),
          const SizedBox(height: AppSpacing.md),
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
                iconColor: context.colors.statusError,
                textColor: context.colors.statusError,
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
        color: context.colors.surface.withValues(alpha: 0.8),
        borderRadius: AppRadii.card,
        border: Border.all(
          color: highlighted
              ? ModuleColors.portfolio.withValues(alpha: 0.5)
              : context.colors.border.withValues(alpha: 0.05),
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
        borderRadius: AppRadii.card,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(children: children),
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
            alpha: 0.1 + highlightStrength * 0.12,
          )
        : null;

    return Material(
      color: bgTint ?? Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: highlighted
                      ? accent.withValues(alpha: 0.2)
                      : context.colors.surface.withValues(alpha: 0.1),
                  borderRadius: AppRadii.input,
                  border: highlighted
                      ? Border.all(color: accent.withValues(alpha: 0.45))
                      : null,
                ),
                child: Icon(
                  icon,
                  color:
                      iconColor ?? context.colors.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.sectionTitle(compact: true).copyWith(
                        color: textColor ?? context.colors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: context.text.bodyMuted().copyWith(
                          color: context.colors.textSecondary,
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
                        : context.colors.divider,
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
      color: context.colors.divider,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm + AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: context.text.caption().copyWith(
          color: context.colors.textSecondary,
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
        final isGoogle =
            authState is Authenticated &&
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
                  decoration: const InputDecoration(labelText: 'New password'),
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
                      content: Text(
                        'Password updated. Use your new password next sign-in.',
                      ),
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

  Future<void> _copyUserId(BuildContext context, String userId) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (!context.mounted) return;
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

  void _showThemeSelectionDialog(BuildContext context, AppThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppThemeMode>(
                title: const Text('System Default'),
                value: AppThemeMode.system,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) {
                    context.read<ThemeCubit>().setTheme(mode);
                  }
                  Navigator.pop(dialogContext);
                },
              ),
              RadioListTile<AppThemeMode>(
                title: const Text('Light Mode'),
                value: AppThemeMode.light,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) {
                    context.read<ThemeCubit>().setTheme(mode);
                  }
                  Navigator.pop(dialogContext);
                },
              ),
              RadioListTile<AppThemeMode>(
                title: const Text('Dark Mode'),
                value: AppThemeMode.dark,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) {
                    context.read<ThemeCubit>().setTheme(mode);
                  }
                  Navigator.pop(dialogContext);
                },
              ),
              RadioListTile<AppThemeMode>(
                title: const Text('Sky Blue Mode'),
                value: AppThemeMode.skyBlue,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) {
                    context.read<ThemeCubit>().setTheme(mode);
                  }
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    final feedbackController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final reasons = [
      'Too expensive / high fees',
      'Difficult to use / complex interface',
      'Missing key features or products',
      'Other (please write your custom feedback)',
    ];
    String selectedReason = reasons.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final isOtherSelected = selectedReason == reasons.last;

            return AlertDialog(
              backgroundColor: context.colors.scaffoldBackground,
              title: Text(
                'Delete Account',
                style: context.text.sectionTitle().copyWith(
                  color: context.colors.statusError,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are you sure you want to permanently delete your account? Your account will be deactivated immediately, and all your data will be permanently deleted in 90 days if you do not log back in.',
                        style: context.text.body().copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Please tell us why you are leaving (Required):',
                        style: context.text.label().copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        value: selectedReason,
                        dropdownColor: context.colors.scaffoldBackground,
                        style: context.text.body().copyWith(
                          color: context.colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.input,
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm + AppSpacing.xs,
                          ),
                        ),
                        items: reasons.map((r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedReason = val;
                            });
                          }
                        },
                      ),
                      if (isOtherSelected) ...[
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: feedbackController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Your feedback helps us improve...',
                            hintStyle: context.text.bodyMuted().copyWith(
                              color: context.colors.textSecondary,
                            ),
                            filled: true,
                            fillColor: context.colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.input,
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: context.text.body().copyWith(
                            color: context.colors.textPrimary,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Feedback is required when selecting "Other".';
                            }
                            if (value.trim().length < 5) {
                              return 'Please provide a bit more detail (min 5 chars).';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: context.text.label().copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.statusError,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final feedback = isOtherSelected
                          ? 'Other: ${feedbackController.text.trim()}'
                          : selectedReason;

                      // Call requestAccountDeletion via AuthCubit
                      final authCubit = context.read<AuthCubit>();

                      // Show loading overlay or just pop and show snackbar
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Processing account deletion...'),
                          duration: Duration(seconds: 2),
                        ),
                      );

                      try {
                        await authCubit.requestAccountDeletion(feedback: feedback);
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Account Deletion Requested'),
                              content: const Text(
                                'Your account will be deleted in 90 days if you don\'t come back and log in again.\n\nWe are sorry to see you go!',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    authCubit.logout();
                                  },
                                  child: const Text('Okay'),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete account: $e'),
                              backgroundColor: context.colors.statusError,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
