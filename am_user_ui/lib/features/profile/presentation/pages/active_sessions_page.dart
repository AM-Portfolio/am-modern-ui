import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

class ActiveSessionsPage extends StatefulWidget {
  const ActiveSessionsPage({super.key});

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
        title: Text(session.current ? 'Sign out this device?' : 'Sign out session?'),
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
      _showMessage(_actionErrorMessage(error, fallback: 'Could not sign out that session.'));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active sessions'),
        actions: [
          if (_sessions.isNotEmpty)
            TextButton(
              onPressed: _revokingAll ? null : _confirmRevokeAll,
              child: _revokingAll
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign out everywhere'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.statusError),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loadSessions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _sessions.isEmpty
                  ? const Center(child: Text('No active sessions'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        return Card(
                          child: ListTile(
                            title: Text(session.deviceLabel),
                            subtitle: Text(
                              '${session.locationLabel}\n'
                              'Last active ${_formatTime(session.lastActiveAt)}',
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (session.current)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Chip(
                                      label: Text(
                                        'Current',
                                        style: TextStyle(
                                          color: context.colors.textPrimary,
                                        ),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                TextButton(
                                  onPressed: _revokingAll
                                      ? null
                                      : () => _confirmRevoke(session),
                                  child: const Text('Sign out'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
