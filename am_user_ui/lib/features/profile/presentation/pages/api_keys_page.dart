import 'dart:convert';

import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ApiKeysPage extends StatefulWidget {
  const ApiKeysPage({super.key});

  @override
  State<ApiKeysPage> createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends State<ApiKeysPage> {
  List<Map<String, dynamic>> _keys = const [];
  bool _loading = true;
  String? _error;

  String get _endpoint => '${AuthEndpoints.identityBaseUrl}/users/me/api-keys';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await AuthProviders.dio.get(_endpoint);
      final data = response.data as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _keys = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load API keys: $error';
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final controller = TextEditingController(text: 'Cursor');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create API key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Key name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;

    try {
      final response = await AuthProviders.dio.post(
        _endpoint,
        data: {'name': name, 'scope': 'ai.read'},
      );
      final created = Map<String, dynamic>.from(response.data as Map);
      if (!mounted) return;
      await _showCreatedKey(created);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create API key: $error')),
      );
    }
  }

  Future<void> _showCreatedKey(Map<String, dynamic> key) async {
    final keyId = key['key_id'] as String;
    final secret = key['secret'] as String;
    final snippet = const JsonEncoder.withIndent('  ').convert({
      'mcpServers': {
        'asrax-finance': {
          'command': 'python',
          'args': ['/path/to/asrax_mcp.py'],
          'env': {'ASRAX_KEY_ID': keyId, 'ASRAX_KEY_SECRET': secret},
        },
      },
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save this secret now'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'The secret is shown once and cannot be retrieved later.',
                ),
                const SizedBox(height: 16),
                SelectableText('Key ID: $keyId\nSecret: $secret'),
                const SizedBox(height: 16),
                const Text('Cursor MCP settings:'),
                const SizedBox(height: 8),
                SelectableText(snippet),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: snippet));
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy settings'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('I saved it'),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(Map<String, dynamic> key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke API key?'),
        content: Text('Revoke “${key['name']}”? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AuthProviders.dio.delete('$_endpoint/${key['id']}');
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not revoke API key: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API keys')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Create key'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _keys.isEmpty
          ? const Center(
              child: Text('No API keys yet. Create one for Cursor or MCP.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _keys.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final key = _keys[index];
                final revoked = key['revoked_at'] != null;
                return ListTile(
                  leading: Icon(
                    revoked ? Icons.key_off_rounded : Icons.key_rounded,
                  ),
                  title: Text(key['name'] as String),
                  subtitle: Text(
                    '${key['key_id']} · ${key['scope']}'
                    '${revoked ? ' · revoked' : ''}',
                  ),
                  trailing: revoked
                      ? null
                      : IconButton(
                          tooltip: 'Revoke',
                          onPressed: () => _revoke(key),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                );
              },
            ),
    );
  }
}
