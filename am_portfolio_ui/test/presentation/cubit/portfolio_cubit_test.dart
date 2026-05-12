import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/cubit/portfolio_cubit.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/cubit/portfolio_state.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/services/portfolio_service.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_holding.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_summary.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_list.dart';
import 'package:am_common/am_common.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

// Manual mock implementation of PortfolioService
class MockPortfolioService implements PortfolioService {
  PortfolioHoldings? mockHoldings;
  PortfolioSummary? mockSummary;
  PortfolioList? mockPortfolioList;
  Object? errorToThrow;

  PortfolioSummary _createDummySummary() {
    return PortfolioSummary(
      userId: 'user_123',
      totalValue: 1250000.0,
      totalInvested: 1000000.0,
      investmentValue: 1000000.0,
      totalGainLoss: 250000.0,
      totalGainLossPercentage: 25.0,
      todayChange: 15000.0,
      todayChangePercentage: 1.2,
      todayGainLossPercentage: 1.2,
      totalHoldings: 8,
      totalAssets: 8,
      todayGainersCount: 6,
      todayLosersCount: 2,
      gainersCount: 5,
      losersCount: 3,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<PortfolioHoldings> getPortfolioHoldings(String userId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockHoldings ?? PortfolioHoldings.empty(userId);
  }

  @override
  Future<PortfolioHoldings> getPortfolioHoldingsById(String userId, String portfolioId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockHoldings ?? PortfolioHoldings.empty(userId);
  }

  @override
  Future<PortfolioSummary> getPortfolioSummary(String userId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockSummary ?? _createDummySummary();
  }

  @override
  Future<PortfolioSummary> getPortfolioSummaryById(String userId, String portfolioId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockSummary ?? _createDummySummary();
  }

  @override
  Future<PortfolioList> getPortfoliosList(String userId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockPortfolioList ?? PortfolioList(userId: userId, lastUpdated: DateTime.now(), portfolios: const []);
  }

  @override
  Future<bool> validatePortfolioConsistency(String userId) async {
    return errorToThrow == null;
  }
}

// Manual mock implementation of AmStompClient
class MockStompClient implements AmStompClient {
  final _statusController = StreamController<StompStatus>.broadcast();
  final _messagesController = StreamController<StompFrame>.broadcast();
  bool _isConnected = false;
  final List<String> subscriptions = [];
  final List<Map<String, dynamic>> sentMessages = [];

  @override
  Stream<StompStatus> get status => _statusController.stream;

  @override
  Stream<StompFrame> get messages => _messagesController.stream;

  @override
  bool get isConnected => _isConnected;

  void setConnected(bool value) {
    _isConnected = value;
    _statusController.add(value ? StompStatus.connected : StompStatus.disconnected);
  }

  void emitFrame(StompFrame frame) {
    _messagesController.add(frame);
  }

  @override
  void subscribe(String destination, {bool forceResubscribe = false}) {
    subscriptions.add(destination);
  }

  @override
  void send({required String destination, String? body, Map<String, String>? headers}) {
    sentMessages.add({
      'destination': destination,
      'body': body,
      'headers': headers,
    });
  }

  @override
  void unsubscribe(String destination) {
    subscriptions.remove(destination);
  }

  @override
  void configure({required String url}) {}

  @override
  void connect({
    Map<String, String>? headers,
    void Function(StompFrame frame)? onConnect,
    void Function(dynamic error)? onWebSocketError,
  }) {}

  @override
  void disconnect() {}

  @override
  void dispose() {
    _statusController.close();
    _messagesController.close();
  }
}

void main() {
  group('PortfolioCubit Unit Tests', () {
    late MockPortfolioService mockService;
    late MockStompClient mockStompClient;
    late PortfolioCubit cubit;

    setUp(() {
      mockService = MockPortfolioService();
      mockStompClient = MockStompClient();
      cubit = PortfolioCubit(mockService, stompClient: mockStompClient);
    });

    tearDown(() async {
      await cubit.close();
      mockStompClient.dispose();
    });

    test('initial state is PortfolioInitial', () {
      expect(cubit.state, isA<PortfolioInitial>());
    });

    test('loadPortfolio emits PortfolioLoading and PortfolioLoaded on success', () async {
      final summary = mockService._createDummySummary();
      final holdings = PortfolioHoldings(
        userId: 'user_123',
        holdings: const [],
        lastUpdated: DateTime.now(),
      );

      mockService.mockSummary = summary;
      mockService.mockHoldings = holdings;

      final expectFuture = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<PortfolioLoading>(),
          isA<PortfolioLoaded>().having((s) => s.portfolioId, 'portfolioId', 'GLOBAL')
                                .having((s) => s.summary.totalValue, 'totalValue', 1250000.0),
        ]),
      );

      await cubit.loadPortfolio('user_123');
      await expectFuture;
    });

    test('loadPortfolio emits PortfolioLoading and PortfolioError on failure', () async {
      mockService.errorToThrow = Exception('Database connection failed');

      final expectFuture = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<PortfolioLoading>(),
          isA<PortfolioError>().having((s) => s.message, 'message', 'Exception: Database connection failed'),
        ]),
      );

      await cubit.loadPortfolio('user_123');
      await expectFuture;
    });

    test('loadPortfolioById emits PortfolioLoading and PortfolioLoaded on success', () async {
      final summary = mockService._createDummySummary();
      final holdings = PortfolioHoldings(
        userId: 'user_123',
        holdings: const [],
        lastUpdated: DateTime.now(),
      );

      mockService.mockSummary = summary;
      mockService.mockHoldings = holdings;

      final expectFuture = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<PortfolioLoading>(),
          isA<PortfolioLoaded>().having((s) => s.portfolioId, 'portfolioId', 'custom_id')
                                .having((s) => s.summary.totalValue, 'totalValue', 1250000.0),
        ]),
      );

      await cubit.loadPortfolioById('user_123', 'custom_id');
      await expectFuture;
    });

    test('updateSummaryFromSocket merges WebSocket price updates directly', () async {
      final initialSummary = mockService._createDummySummary();
      final initialHoldings = PortfolioHoldings(
        userId: 'user_123',
        holdings: [
          PortfolioHolding(
            id: 'isin_1',
            symbol: 'RELIANCE',
            name: 'Reliance Industries',
            companyName: 'Reliance Industries',
            sector: 'Energy',
            industry: 'Oil & Gas',
            quantity: 10,
            avgPrice: 2000.0,
            currentPrice: 2000.0,
            investedAmount: 20000.0,
            currentValue: 20000.0,
            todayChange: 0.0,
            todayChangePercentage: 0.0,
            totalGainLoss: 0.0,
            totalGainLossPercentage: 0.0,
            portfolioWeight: 100.0,
          ),
        ],
        lastUpdated: DateTime.now(),
      );

      mockService.mockSummary = initialSummary;
      mockService.mockHoldings = initialHoldings;

      // 1. Move to PortfolioLoaded state
      await cubit.loadPortfolio('user_123');
      expect(cubit.state, isA<PortfolioLoaded>());

      // 2. Mock state change expectation
      final expectFuture = expectLater(
        cubit.stream,
        emits(
          isA<PortfolioLoaded>()
              .having((s) => s.summary.totalValue, 'totalValue', 1300000.0)
              .having((s) => s.summary.todayChange, 'todayChange', 50000.0)
              .having((s) => s.holdings[0].currentPrice, 'holdingPrice', 2500.0),
        ),
      );

      // 3. Call updateSummaryFromSocket directly to avoid any async stream race conditions
      cubit.updateSummaryFromSocket({
        "userId": "user_123",
        "portfolioId": "GLOBAL",
        "currentValue": 1300000.0,
        "investmentValue": 1000000.0,
        "totalGainLoss": 300000.0,
        "totalGainLossPercentage": 30.0,
        "todayGainLoss": 50000.0,
        "todayGainLossPercentage": 4.0,
        "equities": [
          {
            "isin": "isin_1",
            "symbol": "RELIANCE",
            "name": "Reliance Industries Ltd",
            "quantity": 10,
            "currentPrice": 2500.0,
            "currentValue": 25000.0,
            "investmentValue": 20000.0,
            "profitLoss": 5000.0,
            "profitLossPercentage": 25.0,
            "todayProfitLoss": 5000.0,
            "todayProfitLossPercentage": 25.0
          }
        ]
      });

      await expectFuture;
    });
  });
}
