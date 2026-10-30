import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// IPO-style friendly error panel — never dumps raw DioException text.
class MarketAsyncErrorView extends StatelessWidget {
  const MarketAsyncErrorView({
    super.key,
    required this.title,
    this.error,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String title;
  final Object? error;
  final VoidCallback? onRetry;
  final String retryLabel;

  static String reasonFor(Object? error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code != null) {
        if (code >= 500) return 'Server error ($code). Try again shortly.';
        if (code == 401 || code == 403) return 'Session expired. Sign in again.';
        if (code == 404) return 'Not found ($code).';
        return 'Request failed ($code).';
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out.';
        case DioExceptionType.connectionError:
          return 'Network unavailable.';
        default:
          return 'Could not complete the request.';
      }
    }
    return 'Something went wrong.';
  }

  @override
  Widget build(BuildContext context) {
    final reason = reasonFor(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: context.statusError,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: ModuleColors.market,
                  foregroundColor: context.colors.actionPrimaryFg,
                ),
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
