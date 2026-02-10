import 'package:flutter/material.dart';
import '../models/analysis_models.dart';
import '../services/analysis_service.dart';
import 'allocation_pie_chart.dart';
import 'performance_line_chart.dart';
import 'top_movers_list.dart';

class AnalysisDashboard extends StatefulWidget {
  final String? entityId;
  final AnalysisEntityType entityType;
  final AnalysisService analysisService;

  const AnalysisDashboard({
    Key? key,
    this.entityId,
    required this.entityType,
    required this.analysisService,
  }) : super(key: key);

  @override
  State<AnalysisDashboard> createState() => _AnalysisDashboardState();
}

class _AnalysisDashboardState extends State<AnalysisDashboard> {
  late Future<List<AllocationItem>> _allocationFuture;
  late Future<List<PerformanceDataPoint>> _performanceFuture;
  late Future<List<MoverItem>> _moversFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _allocationFuture = widget.analysisService.getAllocation(widget.entityId, widget.entityType);
    _performanceFuture = widget.analysisService.getPerformance(widget.entityId, widget.entityType, '1M');
    // For top movers, if entityId is present, we get generic movers WITHIN that entity
    // If not, we get top movers OF that type (e.g. top ETF performers)
    _moversFuture = widget.analysisService.getTopMovers(id: widget.entityId, type: widget.entityType);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analysis Dashboard', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return _buildDesktopLayout();
              } else {
                return _buildMobileLayout();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildPerformanceSection(),
              const SizedBox(height: 16),
              _buildAllocationSection(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: _buildMoversSection(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildPerformanceSection(),
        const SizedBox(height: 16),
        _buildAllocationSection(),
        const SizedBox(height: 16),
        _buildMoversSection(),
      ],
    );
  }

  Widget _buildPerformanceSection() {
    return FutureBuilder<List<PerformanceDataPoint>>(
      future: _performanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return PerformanceLineChart(dataPoints: snapshot.data ?? []);
      },
    );
  }

  Widget _buildAllocationSection() {
    return FutureBuilder<List<AllocationItem>>(
      future: _allocationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return AllocationPieChart(items: snapshot.data ?? []);
      },
    );
  }

  Widget _buildMoversSection() {
    return FutureBuilder<List<MoverItem>>(
      future: _moversFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return TopMoversList(items: snapshot.data ?? []);
      },
    );
  }
}
