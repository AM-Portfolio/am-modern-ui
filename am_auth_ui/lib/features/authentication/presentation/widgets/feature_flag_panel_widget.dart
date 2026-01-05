import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/feature_flag_cubit.dart';
import '../cubit/feature_flag_state.dart';

/// Feature flag developer panel widget
class FeatureFlagPanelWidget extends StatefulWidget {
  const FeatureFlagPanelWidget({super.key});

  @override
  State<FeatureFlagPanelWidget> createState() => _FeatureFlagPanelWidgetState();
}

class _FeatureFlagPanelWidgetState extends State<FeatureFlagPanelWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FeatureFlagCubit, FeatureFlagState>(
        builder: (context, state) => Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.build, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Developer Tools',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded ? Icons.expand_more : Icons.expand_less,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded content
              if (_isExpanded)
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('API Configuration', [
                          _buildSwitch(
                            'Backend API',
                            state.flags.useRealBackendAPI,
                            (value) => context
                                .read<FeatureFlagCubit>()
                                .updateBoolFlag('useRealBackendAPI', value),
                          ),
                          _buildSwitch(
                            'Google OAuth',
                            state.flags.useRealGoogleAuth,
                            (value) => context
                                .read<FeatureFlagCubit>()
                                .updateBoolFlag('useRealGoogleAuth', value),
                          ),
                        ]),
                        const Divider(color: Colors.white24),
                        _buildSection('Development Settings', [
                          _buildSwitch(
                            'Mock Delays',
                            state.flags.enableMockDelays,
                            (value) => context
                                .read<FeatureFlagCubit>()
                                .updateBoolFlag('enableMockDelays', value),
                          ),
                          _buildSwitch(
                            'Error Simulation',
                            state.flags.enableErrorSimulation,
                            (value) => context
                                .read<FeatureFlagCubit>()
                                .updateBoolFlag('enableErrorSimulation', value),
                          ),
                          _buildSwitch(
                            'Debug Logging',
                            state.flags.enableDebugLogging,
                            (value) => context
                                .read<FeatureFlagCubit>()
                                .updateBoolFlag('enableDebugLogging', value),
                          ),
                        ]),
                        const Divider(color: Colors.white24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  context
                                      .read<FeatureFlagCubit>()
                                      .resetToDefaults();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child: const Text('Reset All'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildSection(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      ...children,
    ],
  );

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.green,
            ),
          ],
        ),
      );
}
