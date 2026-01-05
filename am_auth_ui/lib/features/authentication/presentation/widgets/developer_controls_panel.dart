import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/datasources/user_activation_datasource.dart';

/// Developer controls panel for feature flags and testing
class DeveloperControlsPanel extends StatefulWidget {
  const DeveloperControlsPanel({super.key});

  @override
  State<DeveloperControlsPanel> createState() => _DeveloperControlsPanelState();
}

class _DeveloperControlsPanelState extends State<DeveloperControlsPanel> {
  bool _isExpanded = false;
  bool _useRealGoogleAuth = false;
  bool _useRealBackendAPI = false;
  bool _enableMockDelays = true;
  bool _enableDebugLogging = true;

  // Activation state
  final TextEditingController _userIdController = TextEditingController();
  bool _isActivating = false;
  String? _activationMessage;
  bool? _activationSuccess;

  late final UserActivationDataSource _activationDataSource;

  @override
  void initState() {
    super.initState();
    _activationDataSource = UserActivationRemoteDataSource(Dio());
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.developer_mode,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Developer Controls',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Configuration',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle('Use Real Google Auth', _useRealGoogleAuth, (
                    value,
                  ) {
                    setState(() {
                      _useRealGoogleAuth = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Real Google Auth enabled'
                              : 'Mock Google Auth enabled',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _buildToggle('Use Real Backend API', _useRealBackendAPI, (
                    value,
                  ) {
                    setState(() {
                      _useRealBackendAPI = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Real Backend API enabled'
                              : 'Mock Backend API enabled',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Development Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle('Mock API Delays', _enableMockDelays, (value) {
                    setState(() {
                      _enableMockDelays = value;
                    });
                  }),
                  const SizedBox(height: 8),
                  _buildToggle('Debug Logging', _enableDebugLogging, (value) {
                    setState(() {
                      _enableDebugLogging = value;
                    });
                  }),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  // Account Activation Section
                  Text(
                    'Account Activation',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _userIdController,
                    decoration: InputDecoration(
                      hintText: 'Enter User ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    enabled: !_isActivating,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isActivating ? null : _handleActivateUser,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isActivating
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Activate Account'),
                    ),
                  ),
                  if (_activationMessage != null) const SizedBox(height: 12),
                  if (_activationMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _activationSuccess == true
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _activationSuccess == true
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _activationSuccess == true
                                ? Icons.check_circle
                                : Icons.error,
                            color: _activationSuccess == true
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _activationMessage!,
                              style: TextStyle(
                                color: _activationSuccess == true
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _useRealGoogleAuth = false;
                              _useRealBackendAPI = false;
                              _enableMockDelays = true;
                              _enableDebugLogging = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings reset to defaults'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Reset All'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleActivateUser() async {
    final userId = _userIdController.text.trim();

    if (userId.isEmpty) {
      setState(() {
        _activationMessage = 'Please enter a User ID';
        _activationSuccess = false;
      });
      return;
    }

    setState(() {
      _isActivating = true;
      _activationMessage = null;
      _activationSuccess = null;
    });

    try {
      await _activationDataSource.activateUser(userId);

      if (mounted) {
        setState(() {
          _isActivating = false;
          _activationMessage = 'User activated successfully!';
          _activationSuccess = true;
        });

        // Clear message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _activationMessage = null;
              _activationSuccess = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActivating = false;
          _activationMessage = e.toString().replaceAll('Exception: ', '');
          _activationSuccess = false;
        });
      }
    }
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}
