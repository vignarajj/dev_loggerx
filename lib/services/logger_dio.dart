import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logger_service.dart';

/// Dio interceptor for logging API requests and responses to DevLoggerX.
class LoggerDio extends Interceptor {
  // Container for accessing providers outside the widget tree
  static ProviderContainer? _container;

  /// Initialize a provider container for use in non-widget contexts
  static void initializeProviderContainer(ProviderContainer container) {
    _container = container;
  }

  LoggerDio(); // No more optional WidgetRef parameter

  /// Called before a request is sent. Stores start time.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['devLoggerStartTime'] = DateTime.now();
    super.onRequest(options, handler);
  }

  /// Called when a response is received. Logs the API call.
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime =
        response.requestOptions.extra['devLoggerStartTime'] as DateTime?;
    final endTime = DateTime.now();
    final duration = startTime != null ? endTime.difference(startTime) : null;

    _logApiResponse(
      heading:
          '[${response.requestOptions.method}] ${response.requestOptions.uri}',
      content: response.data.toString(),
      method: response.requestOptions.method,
      url: response.requestOptions.uri.toString(),
      headers: response.requestOptions.headers,
      body: response.requestOptions.data,
      statusCode: response.statusCode,
      timings: duration,
    );

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime =
        err.requestOptions.extra['devLoggerStartTime'] as DateTime?;
    final endTime = DateTime.now();
    final duration = startTime != null ? endTime.difference(startTime) : null;

    _logApiResponse(
      heading: '[${err.requestOptions.method}] ${err.requestOptions.uri}',
      content: err.message ?? 'Error',
      method: err.requestOptions.method,
      url: err.requestOptions.uri.toString(),
      headers: err.requestOptions.headers,
      body: err.requestOptions.data,
      statusCode: err.response?.statusCode,
      timings: duration,
    );

    super.onError(err, handler);
  }

  /// Helper method to log API responses using the provider container
  void _logApiResponse({
    required String heading,
    required String content,
    required String method,
    required String url,
    required Map<String, dynamic> headers,
    dynamic body,
    int? statusCode,
    Duration? timings,
  }) {
    if (_container != null) {
      try {
        final notifier = _container!.read(loggerProvider.notifier);
        notifier.addApiLog(
          heading: heading,
          content: content,
          method: method,
          url: url,
          headers: headers,
          body: body,
          statusCode: statusCode,
          timings: timings,
          memoryUsage: null,
        );
      } catch (e) {
        // Fallback if provider access fails
        print('Failed to log API call: $e');
      }
    } else {
      print(
          'Warning: LoggerDio provider container not initialized. Initialize with LoggerDio.initializeProviderContainer()');
    }
  }
}
