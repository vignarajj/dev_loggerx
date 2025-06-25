import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logger_service.dart';

/// HTTP client wrapper for logging API requests and responses to DevLoggerX.
class LoggerHttp extends http.BaseClient {
  final http.Client _inner;
  final WidgetRef ref;

  LoggerHttp(this.ref, [http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();
    http.StreamedResponse response;
    Object? requestBody;
    if (request is http.Request) {
      requestBody = request.body;
    }
    try {
      response = await _inner.send(request);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      final responseBody = await http.Response.fromStream(response);
      ref.read(loggerProvider.notifier).addApiLog(
            heading: '[${request.method}] ${request.url}',
            content: responseBody.body,
            method: request.method,
            url: request.url.toString(),
            headers: request.headers,
            body: requestBody,
            statusCode: response.statusCode,
            timings: duration,
            memoryUsage: null,
          );
      return http.StreamedResponse(
        Stream.value(responseBody.bodyBytes),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      ref.read(loggerProvider.notifier).addApiLog(
            heading: '[${request.method}] ${request.url} (ERROR)',
            content: e.toString(),
            method: request.method,
            url: request.url.toString(),
            headers: request.headers,
            body: requestBody,
            statusCode: null,
            timings: duration,
            memoryUsage: null,
          );
      rethrow;
    }
  }
}
