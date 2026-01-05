import 'package:flutter/material.dart';
import '../../../config/environment.dart';

/// A widget that allows switching between different environments at runtime
class EnvironmentSwitcher extends StatefulWidget {
  /// Constructor
  const EnvironmentSwitcher({super.key});

  @override
  State<EnvironmentSwitcher> createState() => _EnvironmentSwitcherState();
}

class _EnvironmentSwitcherState extends State<EnvironmentSwitcher> {
  late Environment _selectedEnvironment;

  @override
  void initState() {
    super.initState();
    _selectedEnvironment = EnvironmentConfig.environment;
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, size: 18),
              const SizedBox(width: 8),
              Text(
                'Environment',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: Environment.values.map((env) {
              final isSelected = env == _selectedEnvironment;
              final envName = env.toString().split('.').last;

              return FilterChip(
                selected: isSelected,
                label: Text(
                  envName[0].toUpperCase() + envName.substring(1),
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedEnvironment = env;
                    EnvironmentConfig.environment = env;
                  });

                  // Show a snackbar to confirm the change
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Switched to ${envName[0].toUpperCase() + envName.substring(1)} environment',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'API URL: ${EnvironmentConfig.apiBaseUrl}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}
