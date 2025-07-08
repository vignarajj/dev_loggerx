import 'package:http/http.dart' as http;
import '../logit.dart';

/// HTTP client wrapper for logging API requests and responses to DevLoggerX.
class LoggerHttp extends http.BaseClient {
  final http.Client _inner;

  // Using LogitCore's container for access to the loggerProvider
  LoggerHttp([http.Client? inner]) : _inner = inner ?? http.Client();

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
      _logApiCall(
        heading: '[${request.method}] ${request.url}',
        content: responseBody.body,
        method: request.method,
        url: request.url.toString(),
        headers: request.headers,
        body: requestBody,
        statusCode: responseBody.statusCode,
        timings: duration,
      );
      // Return a new stream because we've consumed the original one
      return http.StreamedResponse(
        http.ByteStream.fromBytes(responseBody.bodyBytes),
        responseBody.statusCode,
        headers: response.headers,
        contentLength: responseBody.contentLength,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
        request: response.request,
      );
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      _logApiCall(
        heading: '[${request.method}] ${request.url}',
        content: e.toString(),
        method: request.method,
        url: request.url.toString(),
        headers: request.headers,
        body: requestBody,
        statusCode: null,
        timings: duration,
      );
      rethrow;
    }
  }

  /// Helper method to log API calls using LogitCore's provider container
  void _logApiCall({
    required String heading,
    required String content,
    required String method,
    required String url,
    required Map<String, String> headers,
    Object? body,
    int? statusCode,
    Duration? timings,
  }) {
    LogitCore.container?.read(loggerProvider.notifier).addApiLog(
          heading: heading,
          content: content,
          method: method,
          url: url,
          headers: Map<String, dynamic>.from(headers),
          body: body,
          statusCode: statusCode,
          timings: timings,
          memoryUsage: null,
        );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
