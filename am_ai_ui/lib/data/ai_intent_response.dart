// AI Intent Response — prefers artifactType+data; widgetId kept for legacy.
class AiIntentResponse {
  final String message;
  final String artifactType;
  final dynamic data;
  final String widgetId;
  final Map<String, dynamic> widgetParams;
  final String sessionId;
  final List<String> toolsUsed;
  final String traceId;

  const AiIntentResponse({
    required this.message,
    required this.artifactType,
    this.data,
    required this.widgetId,
    required this.widgetParams,
    required this.sessionId,
    required this.toolsUsed,
    required this.traceId,
  });

  static const _artifactToWidget = <String, String>{
    'portfolio.summary.v1': 'PORTFOLIO_SUMMARY',
    'holdings.list.v1': 'HOLDINGS_TABLE',
    'holdings.detail.v1': 'HOLDINGS_TABLE',
    'portfolio.overviews.v1': 'PORTFOLIO_SUMMARY',
    'portfolio.detail.v1': 'PORTFOLIO_SUMMARY',
    'portfolio.analytics.v1': 'PORTFOLIO_SUMMARY',
    'portfolio.movers.v1': 'TOP_MOVERS',
    'portfolio.sector_allocation.v1': 'ALLOCATION_PIE_CHART',
    'portfolio.market_cap.v1': 'ALLOCATION_PIE_CHART',
    'trades.recent.v1': 'RECENT_ACTIVITY',
    'trades.history.v1': 'RECENT_ACTIVITY',
    'trades.unrealised_pnl.v1': 'PORTFOLIO_SUMMARY',
    'market.quote.v1': 'TEXT_RESPONSE',
    'market.movers.v1': 'TOP_MOVERS',
    'error.v1': 'ERROR',
    'text.v1': 'TEXT_RESPONSE',
    'data.generic.v1': 'TEXT_RESPONSE',
  };

  factory AiIntentResponse.fromJson(Map<String, dynamic> json) {
    final artifact = (json['artifactType'] as String?)?.trim();
    final legacyWidget = json['widgetId'] as String?;
    final mapped = artifact != null && artifact.isNotEmpty
        ? (_artifactToWidget[artifact] ?? 'TEXT_RESPONSE')
        : null;
    final widgetId = mapped ?? legacyWidget ?? 'TEXT_RESPONSE';

    Map<String, dynamic> params =
        (json['widgetParams'] as Map<String, dynamic>?) ?? {};
    final data = json['data'];
    if (params.isEmpty && data is Map<String, dynamic>) {
      params = Map<String, dynamic>.from(data);
    } else if (params.isEmpty && data != null) {
      params = {'data': data};
    }

    return AiIntentResponse(
      message: json['message'] as String? ?? '',
      artifactType: artifact?.isNotEmpty == true ? artifact! : 'text.v1',
      data: data,
      widgetId: widgetId,
      widgetParams: params,
      sessionId: json['sessionId'] as String? ?? '',
      toolsUsed: (json['toolsUsed'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      traceId: json['traceId'] as String? ?? '',
    );
  }

  factory AiIntentResponse.error(String message) => AiIntentResponse(
        message: message,
        artifactType: 'error.v1',
        widgetId: 'ERROR',
        widgetParams: {},
        sessionId: '',
        toolsUsed: [],
        traceId: '',
      );
}

enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String text;
  final AiIntentResponse? response;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    this.response,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
