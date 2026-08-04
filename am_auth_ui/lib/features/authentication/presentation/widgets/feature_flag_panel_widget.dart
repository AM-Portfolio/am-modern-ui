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
            color: const Color(0xFF252836),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header matching image (1).png
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.handyman_outlined,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'Developer Tools',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
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
