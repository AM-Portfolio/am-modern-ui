import 'dart:async';

import 'package:flutter/material.dart';
import 'package:am_market_ui/shared/widgets/stock_chart.dart';
import 'package:am_market_ui/shared/widgets/time_range_selector.dart';
import 'package:am_market_common/services/api_service.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:provider/provider.dart';
import 'package:am_market_common/providers/market_provider.dart';

class StockDetailPage extends StatefulWidget {
  final String symbol;

  const StockDetailPage({Key? key, required this.symbol}) : super(key: key);

  @override
  _StockDetailPageState createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = true;
  String? _error;
  String _selectedRange = '1D';
  MarketProvider? _marketProvider;

  @override
  void initState() {
    super.initState();
    _fetchData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _marketProvider = context.read<MarketProvider>();
      unawaited(_marketProvider!.subscribeLiveSymbol(widget.symbol));
    });
  }

  @override
  void dispose() {
    final provider = _marketProvider;
    if (provider != null) {
      unawaited(provider.unsubscribeLiveSymbol(widget.symbol));
    }
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data =
          await _apiService.fetchHistory(widget.symbol, _selectedRange);
      data.sort((a, b) {
        final dateA = DateTime.tryParse(a['time'].toString()) ?? DateTime.now();
        final dateB = DateTime.tryParse(b['time'].toString()) ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      if (!mounted) return;
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: StreamBuilder<Map<String, dynamic>>(
          stream: marketProvider.livePriceStream,
          builder: (context, snapshot) {
            final liveData = marketProvider.getPrice(widget.symbol);
            final ltp = _toDouble(liveData?['lastPrice']);
            final change = _toDouble(liveData?['change']);
            final pChange = _toDouble(
              liveData?['changePercent'] ?? liveData?['pChange'],
            );
            final color = (change ?? 0) >= 0
                ? context.colors.statusSuccess
                : context.colors.statusError;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.symbol),
                if (ltp != null)
                  Text(
                    '₹${ltp.toStringAsFixed(2)}'
                    '${change == null ? '' : '  ${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}'}'
                    '${pChange == null ? '' : ' (${pChange.toStringAsFixed(2)}%)'}',
                    style: TextStyle(fontSize: 12, color: color),
                  ),
              ],
            );
          },
        ),
        backgroundColor: context.colors.cardSurface,
      ),
      body: Column(
        children: [
          TimeRangeSelector(
            selectedRange: _selectedRange,
            onRangeSelected: (range) {
              if (_selectedRange != range) {
                setState(() => _selectedRange = range);
                _fetchData();
              }
            },
            ranges: const [
              '10m',
              '15m',
              '30m',
              '1H',
              '4H',
              '1D',
              '1W',
              '1M',
              '5Y'
            ],
          ),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: marketProvider.livePriceStream,
              builder: (context, snapshot) {
                return StockChart(
                  chartData: _chartDataWithLivePoint(
                    marketProvider.getPrice(widget.symbol),
                  ),
                  isLoading: _isLoading,
                  error: _error,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return value == null ? null : double.tryParse(value.toString());
  }

  List<Map<String, dynamic>> _chartDataWithLivePoint(
    Map<String, dynamic>? live,
  ) {
    final livePrice = _toDouble(live?['lastPrice']);
    if (livePrice == null || livePrice <= 0) return _chartData;

    final point = <String, dynamic>{
      'time':
          live?['time']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      'close': livePrice,
    };
    final merged = List<Map<String, dynamic>>.from(_chartData);
    if (merged.isNotEmpty && merged.last['time']?.toString() == point['time']) {
      merged[merged.length - 1] = {...merged.last, 'close': livePrice};
    } else {
      merged.add(point);
    }
    return merged;
  }
}
