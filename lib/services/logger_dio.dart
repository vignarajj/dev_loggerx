import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logger_service.dart';

class LoggerDio extends Interceptor {
  final WidgetRef ref;
  LoggerDio(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['devLoggerStartTime'] = DateTime.now();
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime =
        response.requestOptions.extra['devLoggerStartTime'] as DateTime?;
    final endTime = DateTime.now();
    final duration = startTime != null ? endTime.difference(startTime) : null;
    ref.read(loggerProvider.notifier).addApiLog(
          heading:
              '[${response.requestOptions.method}] ${response.requestOptions.uri}',
          content: response.data.toString(),
          method: response.requestOptions.method,
          url: response.requestOptions.uri.toString(),
          headers: response.requestOptions.headers,
          body: response.requestOptions.data,
          statusCode: response.statusCode,
          timings: duration,
          memoryUsage: null,
        );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime =
        err.requestOptions.extra['devLoggerStartTime'] as DateTime?;
    final endTime = DateTime.now();
    final duration = startTime != null ? endTime.difference(startTime) : null;
    ref.read(loggerProvider.notifier).addApiLog(
          heading:
              '[${err.requestOptions.method}] ${err.requestOptions.uri} (ERROR)',
          content: err.toString(),
          method: err.requestOptions.method,
          url: err.requestOptions.uri.toString(),
          headers: err.requestOptions.headers,
          body: err.requestOptions.data,
          statusCode: err.response?.statusCode,
          timings: duration,
          memoryUsage: null,
        );
    super.onError(err, handler);
  }
}
