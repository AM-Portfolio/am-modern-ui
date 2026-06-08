import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_analysis_core/am_analysis_core.dart';
import 'package:am_analysis_ui/am_analysis_ui.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import 'package:am_common/am_common.dart';

/// Demonstration widget showcasing the headless architecture.
///
/// This widget uses AllocationCubit from am_analysis_core directly
/// to build a completely custom UI, demonstrating full control over
/// appearance and layout without being constrained by pre-built widgets.
class HeadlessAllocationDemo extends StatefulWidget {
  final String portfolioId;

  const HeadlessAllocationDemo({required this.portfolioId, super.key});

  @override
  State<HeadlessAllocationDemo> createState() => _HeadlessAllocationDemoState();
}

class _HeadlessAllocationDemoState extends State<HeadlessAllocationDemo> {
  late AllocationCubit _cubit;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    // Get auth token from secure storage (CRITICAL!)
    final storage = SecureStorageService();
    final token = await storage.getAccessToken();

    print(
      '[HeadlessDemo] Initializing with portfolioId=${widget.portfolioId}, token=${token != null ? "present" : "MISSING"}',
    );

    // Create the service with auth token
    final realService = RealAnalysisService(
      baseUrl: AnalysisConfig.instance.baseUrl,
      authToken: token != null ? 'Bearer $token' : null,
    );
    final service = AnalysisServiceAdapter(realService);

    // Create the cubit
    _cubit = AllocationCubit(
      portfolioId: widget.portfolioId,
      analysisService: service,
    );

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      // Load data after initialization
      _cubit.loadAllocation(GroupBy.sector);
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Card(
        elevation: 4,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider<AllocationCubit>.value(
      value: _cubit,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          '🎨 Headless Architecture Demo',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        BlocBuilder<AllocationCubit, AllocationState>(
          builder: (context, state) {
            return DropdownButton<GroupBy>(
              value: state is AllocationLoaded ? state.groupBy : GroupBy.sector,
              items: GroupBy.values.map((groupBy) {
                return DropdownMenuItem(
                  value: groupBy,
                  child: Text(_groupByLabel(groupBy)),
                );
              }).toList(),
              onChanged: (groupBy) {
                if (groupBy != null) {
                  _cubit.changeGroupBy(groupBy);
                }
              },
            );
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _cubit.refresh(),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<AllocationCubit, AllocationState>(
      builder: (context, state) {
        if (state is AllocationInitial) {
          return const Center(child: Text('Press refresh to load data'));
        } else if (state is AllocationLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AllocationLoaded) {
          return _buildAllocationList(
            context,
            state.allocations,
            state.groupBy,
          );
        } else if (state is AllocationError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load allocation data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message.replaceAll('Exception:', '').trim(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.red.shade300),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _cubit.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAllocationList(
    BuildContext context,
    List<AllocationItem> allocations,
    GroupBy groupBy,
  ) {
    if (allocations.isEmpty) {
      return const Center(child: Text('No allocation data available'));
    }

    return ListView.builder(
      itemCount: allocations.length,
      itemBuilder: (context, index) {
        final item = allocations[index];
        return _buildAllocationCard(context, item);
      },
    );
  }

  Widget _buildAllocationCard(BuildContext context, AllocationItem item) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Custom percentage indicator
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
              ),
              child: Center(
                child: Text(
                  '${item.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_formatValue(item.value)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
            ),
            // Progress bar
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: item.percentage / 100,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _groupByLabel(GroupBy groupBy) {
    switch (groupBy) {
      case GroupBy.sector:
        return 'By Sector';
      case GroupBy.industry:
        return 'By Industry';
      case GroupBy.marketCap:
        return 'By Market Cap';
      case GroupBy.stock:
        return 'By Stock';
    }
  }

  String _formatValue(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)}L';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
