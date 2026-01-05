import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Dashboard page - aggregates widgets from all modules
class DashboardPage extends StatelessWidget {
  const DashboardPage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Text(
              'Welcome to AM Investment Platform',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your all-in-one investment management solution',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 32),
            
            // Stats cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2,
              children: [
                _buildStatCard(
                  context,
                  'Portfolio',
                  'View Holdings',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Trades',
                  'Manage Trades',
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Market',
                  'Market Data',
                  Icons.show_chart,
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  'Analysis',
                  'View Reports',
                  Icons.analytics,
                  Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Module overview
            Text(
              'Available Modules',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildModulesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesList(BuildContext context) {
    final modules = [
      {'name': 'Portfolio Management', 'status': 'Active', 'color': Colors.blue},
      {'name': 'Trade Management', 'status': 'Active', 'color': Colors.green},
      {'name': 'Market Data', 'status': 'Active', 'color': Colors.orange},
      {'name': 'User Profile', 'status': 'Active', 'color': Colors.purple},
      {'name': 'Authentication', 'status': 'Active', 'color': Colors.indigo},
    ];

    return Column(
      children: modules.map((module) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (module['color'] as Color).withOpacity(0.2),
              child: Icon(
                Icons.check_circle,
                color: module['color'] as Color,
              ),
            ),
            title: Text(module['name'] as String),
            subtitle: Text('Status: ${module['status']}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      }).toList(),
    );
  }
}
