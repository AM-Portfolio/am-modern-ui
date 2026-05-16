import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart';

class PortfolioVerificationPage extends StatefulWidget {
  final String userId;
  const PortfolioVerificationPage({super.key, required this.userId});

  @override
  State<PortfolioVerificationPage> createState() =>
      _PortfolioVerificationPageState();
}

class _PortfolioVerificationPageState extends State<PortfolioVerificationPage> {
  final _stompClient = GetIt.instance<AmStompClient>();
  final List<String> _logs = [];
  String _selectedStock = 'AAPL';

  @override
  void initState() {
    super.initState();
    _subscribeToGlobal();
  }

  void _subscribeToGlobal() {
    // Subscribe to user-specific portfolio updates
    _stompClient.subscribe('/user/queue/portfolio');
    _addLog('Subscribed to /user/queue/portfolio');
  }

  void _subscribeToStock() {
    final topic = '/topic/stock/$_selectedStock';
    _stompClient.subscribe(topic);
    _addLog('Subscribed to $topic');
  }

  void _unsubscribeFromStock() {
    final topic = '/topic/stock/$_selectedStock';
    _stompClient.unsubscribe(topic);
    _addLog('Unsubscribed from $topic');
  }

  void _addLog(String log) {
    if (mounted) {
      setState(() {
        _logs.insert(
          0,
          '${DateTime.now().toIso8601String().substring(11, 19)}: $log',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebSocket Verification')),
      body: Column(
        children: [
          // Connection Status
          StreamBuilder<StompStatus>(
            stream: _stompClient.status,
            initialData: StompStatus.disconnected,
            builder: (context, snapshot) {
              final status = snapshot.data!;
              Color color;
              switch (status) {
                case StompStatus.connected:
                  color = Colors.green;
                  break;
                case StompStatus.connecting:
                  color = Colors.orange;
                  break;
                case StompStatus.error:
                  color = Colors.red;
                  break;
                default:
                  color = Colors.grey;
              }
              return Container(
                padding: const EdgeInsets.all(16),
                color: color.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: color, size: 12),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${status.name.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (status == StompStatus.disconnected)
                      ElevatedButton(
                        onPressed: () => _stompClient.connect(),
                        child: const Text('Connect'),
                      ),
                  ],
                ),
              );
            },
          ),

          const Divider(),

          // Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Stock Symbol',
                    ),
                    controller: TextEditingController(text: _selectedStock),
                    onChanged: (v) => _selectedStock = v,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _subscribeToStock,
                  child: const Text('Sub'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _unsubscribeFromStock,
                  child: const Text('Unsub'),
                ),
              ],
            ),
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Live Logs & Messages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Message Stream
          Expanded(
            child: StreamBuilder<StompFrame>(
              stream: _stompClient.messages,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Side effect: only strictly for demo purposes here to log incoming frames
                  // Ideally we shouldn't do side effects in build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Deduplication logic or just log
                    // _addLog('MSG: ${snapshot.data!.body}');
                  });
                }

                return ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        _logs[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                      dense: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
