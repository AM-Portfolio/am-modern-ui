import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:am_common/am_common.dart' as common;
import 'ai_intent_response.dart';
import 'ai_stream_event.dart';

/// HTTP and SSE Streaming service for the AM AI Gateway.
class AiChatService {
  /// Base URL resolved at runtime from config.json → `services.ai`
  /// or defaults to `https://{domain}/ai`.
  static String get baseUrl => common.EnvDomains.ai;

  final Dio _dio;

  AiChatService(this._dio);

  /// Send a one-shot chat message and receive an [AiIntentResponse].
  Future<AiIntentResponse> chat({
    required String message,
    required String userId,
    String? sessionId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/ai/chat',
        data: {
          'message': message,
          'userId': userId,
          if (sessionId != null) 'sessionId': sessionId,
        },
        cancelToken: cancelToken,
      );
      return AiIntentResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return AiIntentResponse.error('Request cancelled.');
      }
      final msg = e.response?.data?.toString() ?? e.message ?? 'Unknown error';
      return AiIntentResponse.error('Agent unavailable: ');
    } catch (e) {
      return AiIntentResponse.error('Unexpected error: ');
    }
  }

  /// Open an SSE stream for real-time token, tool, and widget streaming.
  Stream<AiStreamEvent> chatStream({
    required String message,
    required String userId,
    String? sessionId,
    CancelToken? cancelToken,
  }) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        '/v1/ai/chat/stream',
        data: {
          'message': message,
          'userId': userId,
          if (sessionId != null) 'sessionId': sessionId,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
        ),
        cancelToken: cancelToken,
      );

      final stream = response.data?.stream;
      if (stream == null) {
        yield const AiStreamEvent(
          type: StreamEventType.error,
          content: 'No stream received from AI Gateway.',
        );
        return;
      }

      String buffer = '';
      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // keep incomplete line in buffer

        for (final line in lines) {
          final event = AiStreamEvent.fromSseLine(line);
          if (event != null) {
            yield event;
          }
        }
      }

      if (buffer.isNotEmpty) {
        final event = AiStreamEvent.fromSseLine(buffer);
        if (event != null) {
          yield event;
        }
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        yield const AiStreamEvent(
          type: StreamEventType.cancelled,
          content: 'Generation stopped by user.',
        );
      } else {
        yield AiStreamEvent(
          type: StreamEventType.error,
          content: e.message ?? 'Stream connection failed.',
        );
      }
    } catch (e) {
      yield AiStreamEvent(
        type: StreamEventType.error,
        content: e.toString(),
      );
    }
  }

  /// Submit user feedback (thumbs up/down) for a session turn.
  Future<bool> sendFeedback({
    required String sessionId,
    required String rating,
    String? comment,
  }) async {
    try {
      final r = await _dio.post(
        '/v1/ai/feedback',
        data: {
          'sessionId': sessionId,
          'rating': rating,
          if (comment != null) 'comment': comment,
        },
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Confirm a Human-In-The-Loop action (Phase 4).
  Future<Map<String, dynamic>?> confirmAction({
    required String confirmToken,
    required String userId,
  }) async {
    try {
      final r = await _dio.post(
        '/v1/ai/actions/confirm',
        data: {
          'confirmToken': confirmToken,
          'userId': userId,
        },
      );
      return r.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Health check — returns true if the gateway and agents are healthy.
  Future<bool> isHealthy() async {
    try {
      final r = await _dio.get('/v1/ai/health');
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
