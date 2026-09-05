import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_design_system/am_design_system.dart';

class ActiveSessionsPage extends StatefulWidget {
  const ActiveSessionsPage({
    super.key,
    this.onOpenSecuritySettings,
  });

  /// Opens Profile (Security Settings). Wired from GoRouter when available.
  final VoidCallback? onOpenSecuritySettings;

  @override
  State<ActiveSessionsPage> createState() => _ActiveSessionsPageState();
}

class _ActiveSessionsPageState extends State<ActiveSessionsPage> {
  late final LoginSessionsRemoteDataSource _dataSource;
  List<LoginSessionModel> _sessions = const [];
  bool _loading = true;
  bool _revokingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dataSource = AuthProviders.loginSessionsRemoteDataSource;
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await _dataSource.listSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _loadErrorMessage(error);
      });
    }
  }

  Future<void> _confirmRevoke(LoginSessionModel session) async {
    final message = session.current
        ? 'This signs you out on this browser. You will need to sign in again.'
        : 'Sign out ${session.deviceLabel}?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          session.current ? 'Sign out this device?' : 'Sign out session?',
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _revoke(session);
  }

  Future<void> _revoke(LoginSessionModel session) async {
    try {
      await _dataSource.revokeSession(session.sessionId);
      if (!mounted) return;
      if (session.current) {
        await context.read<AuthCubit>().logout();
        return;
      }
      await _loadSessions();
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        _actionErrorMessage(error, fallback: 'Could not sign out that session.'),
      );
    }
  }

  Future<void> _confirmRevokeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out everywhere?'),
        content: const Text(
          'This signs you out on every device, including this browser. You will need to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out everywhere'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _revokeAll();
  }

  Future<void> _revokeAll() async {
    setState(() => _revokingAll = true);
    try {
      await _dataSource.revokeAllSessions();
      if (!mounted) return;
      await context.read<AuthCubit>().logout();
    } catch (error) {
      if (!mounted) return;
      setState(() => _revokingAll = false);
      _showMessage(
        _actionErrorMessage(error, fallback: 'Could not sign out everywhere.'),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _loadErrorMessage(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return 'Your session expired. Sign in again, then reopen this page.';
    }
    return 'Could not load active sessions. Please try again.';
  }

  String _actionErrorMessage(Object error, {required String fallback}) {
    if (error is DioException && error.response?.statusCode == 401) {
      return 'Your session expired. Sign in again.';
    }
    return fallback;
  }

  String _formatTime(double epochSeconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      (epochSeconds * 1000).round(),
    );
    return DateFormat.yMMMd().add_jm().format(date.toLocal());
  }

  LoginSessionModel? get _currentSession {
    for (final s in _sessions) {
      if (s.current) return s;
    }
    return _sessions.isEmpty ? null : _sessions.first;
  }

  List<LoginSessionModel> get _otherSessions {
    final current = _currentSession;
    if (current == null) return const [];
    return _sessions
        .where((s) => s.sessionId != current.sessionId)
        .toList(growable: false);
  }

  void _showSessionInfo(LoginSessionModel session) {
    final shortId = session.sessionId.length > 8
        ? session.sessionId.substring(session.sessionId.length - 8)
        : session.sessionId;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoLine('Device', session.deviceLabel),
            _infoLine('Client', session.clientType),
            _infoLine('Location', session.locationLabel),
            if (session.ipMasked != null && session.ipMasked!.isNotEmpty)
              _infoLine('IP', session.ipMasked!),
            _infoLine('Created', _formatTime(session.createdAt)),
            _infoLine('Last active', _formatTime(session.lastActiveAt)),
            _infoLine('Session', '#$shortId'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      );

  IconData _browserIcon(LoginSessionModel session) {
    if (session.clientType == 'mobile') return Icons.phone_android_rounded;
    final b = (session.browser ?? '').toLowerCase();
    if (b.contains('chrome')) return Icons.language;
    if (b.contains('firefox')) return Icons.travel_explore;
    if (b.contains('edge')) return Icons.public;
    if (b.contains('safari')) return Icons.apple;
    return Icons.devices_other_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    void goBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        widget.onOpenSecuritySettings?.call();
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppGlassmorphismV2.techBackground(
          isDark: isDark,
          scaffoldColor: colors.scaffoldBackground,
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState()
                  : _buildContent(isDark, onBack: goBack),
        ),
      ),
    );
  }

  Widget _buildErrorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: context.text.body().copyWith(
                      color: context.colors.statusError,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              TextButton(
                onPressed: _loadSessions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _buildContent(bool isDark, {required VoidCallback onBack}) {
    final colors = context.colors;
    final current = _currentSession;
    final others = _otherSessions;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth > 900 ? 900.0 : constraints.maxWidth;
        return Center(
          child: SizedBox(
            width: maxW,
            child: RefreshIndicator(
              onRefresh: _loadSessions,
              color: ModuleColors.portfolio,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  Row(
                    children: [
                      AmBackButton(
                        onPressed: onBack,
                        iconOnly: true,
                        compact: true,
                        tooltip: 'Back to Profile',
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildBreadcrumb(colors)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildHeaderRow(colors),
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoBanner(isDark, colors),
                  const SizedBox(height: AppSpacing.xl),
                  if (_sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'No active sessions',
                          style: context.text.body().copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                      ),
                    )
                  else ...[
                    if (current != null) ...[
                      _buildSectionLabel(
                        'CURRENT DEVICE',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Active Now',
                              style: context.text.caption().copyWith(
                                    color: const Color(0xFF22C55E),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildCurrentCard(current, isDark, colors),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    _buildSectionLabel(
                      'RECENT OTHER SESSIONS',
                      trailing: Text(
                        'Auto-expires after 30 days inactivity',
                        style: context.text.caption().copyWith(
                              color: colors.textTertiary,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (others.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No other sessions',
                          style: context.text.bodyMuted().copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                      )
                    else
                      ...others.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildOtherCard(s, isDark, colors),
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _buildFooter(colors),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumb(AppColorsTheme colors) => Row(
        children: [
          Text(
            'Security',
            style: context.text.caption().copyWith(color: colors.textTertiary),
          ),
          Text(
            '  >  ',
            style: context.text.caption().copyWith(color: colors.textTertiary),
          ),
          Text(
            'Session Manager',
            style: context.text.caption().copyWith(
                  color: ModuleColors.portfolio.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );

  Widget _buildHeaderRow(AppColorsTheme colors) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Active Sessions',
              style: context.text.pageTitle().copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.cardSurface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ModuleColors.portfolio.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '${_sessions.length} Authorized',
                style: context.text.caption().copyWith(
                      color: ModuleColors.portfolio,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Signed in · protected',
                    style: context.text.caption().copyWith(
                          color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: (_revokingAll || _sessions.isEmpty)
                  ? null
                  : _confirmRevokeAll,
              icon: _revokingAll
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Sign out everywhere'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.statusError.withValues(alpha: 0.85),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBanner(bool isDark, AppColorsTheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colors.cardSurface.withValues(alpha: 0.65)
            : colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: ModuleColors.portfolio, width: 3),
          top: BorderSide(color: colors.border.withValues(alpha: 0.4)),
          right: BorderSide(color: colors.border.withValues(alpha: 0.4)),
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.4)),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: ModuleColors.portfolio,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device management & instant session control',
                  style: context.text.sectionTitle().copyWith(
                        color: colors.textPrimary,
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review browsers and devices signed into your account. Sign out any session you do not recognize.',
                  style: context.text.bodyMuted().copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: context.text.caption().copyWith(
                color: context.colors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildCurrentCard(
    LoginSessionModel session,
    bool isDark,
    AppColorsTheme colors,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colors.cardSurface.withValues(alpha: 0.85)
            : colors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 560;
          final meta = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    session.deviceLabel,
                    style: context.text.sectionTitle().copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ModuleColors.portfolio.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CURRENT SESSION',
                      style: context.text.caption().copyWith(
                            color: ModuleColors.portfolio,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _metaChip(
                    Icons.location_on_outlined,
                    session.locationLabel,
                    colors,
                  ),
                  if (session.ipMasked != null && session.ipMasked!.isNotEmpty)
                    _metaChip(Icons.lan_outlined, session.ipMasked!, colors),
                  _metaChip(
                    Icons.schedule_outlined,
                    'Last active ${_formatTime(session.lastActiveAt)}',
                    colors,
                  ),
                ],
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => _showSessionInfo(session),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: const Text('Session Info'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _revokingAll ? null : () => _confirmRevoke(session),
                style: FilledButton.styleFrom(
                  backgroundColor: ModuleColors.portfolio,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text('Sign out'),
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _deviceIcon(session, large: true),
                    const SizedBox(width: 12),
                    Expanded(child: meta),
                  ],
                ),
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            children: [
              _deviceIcon(session, large: true),
              const SizedBox(width: 16),
              Expanded(child: meta),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildOtherCard(
    LoginSessionModel session,
    bool isDark,
    AppColorsTheme colors,
  ) {
    final shortId = session.sessionId.length > 4
        ? session.sessionId.substring(session.sessionId.length - 4)
        : session.sessionId;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colors.cardSurface.withValues(alpha: 0.55)
            : colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _deviceIcon(session, large: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: session.deviceLabel,
                        style: context.text.body().copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      TextSpan(
                        text: '  #$shortId',
                        style: context.text.caption().copyWith(
                              color: colors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.locationLabel} · Last active ${_formatTime(session.lastActiveAt)}',
                  style: context.text.caption().copyWith(
                        color: colors.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _revokingAll ? null : () => _confirmRevoke(session),
            style: OutlinedButton.styleFrom(
              foregroundColor: ModuleColors.portfolio,
              side: BorderSide(
                color: ModuleColors.portfolio.withValues(alpha: 0.45),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _deviceIcon(LoginSessionModel session, {required bool large}) {
    final size = large ? 52.0 : 40.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(large ? 12 : 10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ModuleColors.portfolio,
            ModuleColors.portfolio.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: Icon(
        _browserIcon(session),
        color: Colors.white,
        size: large ? 26 : 20,
      ),
    );
  }

  Widget _metaChip(IconData icon, String text, AppColorsTheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: context.text.caption().copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 14, color: colors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'End-to-End Encrypted Session Tokens (JWT RS256)',
              style: context.text.caption().copyWith(color: colors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: widget.onOpenSecuritySettings ??
                () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
            child: Text(
              'Security Settings',
              style: context.text.caption().copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
