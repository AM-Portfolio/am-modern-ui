import 'package:flutter/material.dart';
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
        _error = error.toString();
      });
    }
  }

  Future<void> _revoke(String sessionId) async {
    await _dataSource.revokeSession(sessionId);
    await _loadSessions();
  }

  Future<void> _revokeAll() async {
    await _dataSource.revokeAllSessions();
    await _loadSessions();
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
              onPressed: _revokeAll,
              child: const Text('Sign out everywhere'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
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
                            trailing: session.current
                                ? Chip(
                                    label: Text(
                                      'Current',
                                      style: TextStyle(
                                        color: context.colors.textPrimary,
                                      ),
                                    ),
                                  )
                                : TextButton(
                                    onPressed: () => _revoke(session.sessionId),
                                    child: const Text('Sign out'),
                                  ),
                          ),
                        );
                      },
                    ),
    );
  }
}
