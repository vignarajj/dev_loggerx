import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logitx/logit.dart';
import 'package:logitx/models/log_enums.dart';
import 'package:logitx/services/services.dart';
import 'package:logitx/models/api_log_model.dart';
import 'package:logitx/models/debug_log_model.dart';

void main() {
  group('API Logging Tests', () {
    late ProviderContainer container;
    late LoggerService loggerService;

    setUp(() {
      // Initialize logger configuration
      Logit.init(const LoggerConfig(
        enableInDebug: true,
        enablePersistence: false, // Disable for testing
      ));

      // Create provider container
      container = ProviderContainer();

      // Initialize containers for both LogitCore and LoggerDio
      LogitCore.initializeProviderContainer(container);
      LoggerDio.initializeProviderContainer(container);

      // Get logger service instance
      loggerService = container.read(loggerProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('Manual API Logging', () {
      test('should log API call manually using Logit.api()', () {
        // Arrange
        const heading = 'Manual API Test';
        const content = '{"success": true}';
        const method = 'POST';
        const url = 'https://api.test.com/endpoint';
        final headers = {'Content-Type': 'application/json'};
        const statusCode = 200;
        const timings = Duration(milliseconds: 150);

        // Act
        Logit.api(
          heading: heading,
          content: content,
          method: method,
          url: url,
          headers: headers,
          statusCode: statusCode,
          timings: timings,
        );

        // Assert
        final logs = container.read(loggerProvider);
        expect(logs.length, 1);

        final apiLog = logs.first as ApiLogModel;
        expect(apiLog.heading, heading);
        expect(apiLog.content, content);
        expect(apiLog.method, method);
        expect(apiLog.url, url);
        expect(apiLog.headers, headers);
        expect(apiLog.statusCode, statusCode);
        expect(apiLog.timings, timings.inMilliseconds);
      });

      test('should handle API log with minimal parameters', () {
        // Act
        Logit.api(
          heading: 'Minimal API Test',
          content: 'Response data',
          method: 'GET',
          url: 'https://api.test.com/minimal',
          headers: {},
        );

        // Assert
        final logs = container.read(loggerProvider);
        expect(logs.length, 1);

        final apiLog = logs.first as ApiLogModel;
        expect(apiLog.heading, 'Minimal API Test');
        expect(apiLog.content, 'Response data');
        expect(apiLog.method, 'GET');
        expect(apiLog.url, 'https://api.test.com/minimal');
        expect(apiLog.headers, {});
        expect(apiLog.statusCode, null);
        expect(apiLog.timings, null);
      });

      test('should handle API log with body and memory usage', () {
        // Act
        Logit.api(
          heading: 'Complete API Test',
          content: '{"data": "response"}',
          method: 'POST',
          url: 'https://api.test.com/complete',
          headers: {'Authorization': 'Bearer token123'},
          body: '{"request": "data"}',
          statusCode: 201,
          timings: const Duration(milliseconds: 250),
          memoryUsage: 1024,
        );

        // Assert
        final logs = container.read(loggerProvider);
        expect(logs.length, 1);

        final apiLog = logs.first as ApiLogModel;
        expect(apiLog.heading, 'Complete API Test');
        expect(apiLog.body, '{"request": "data"}');
        expect(apiLog.memoryUsage, 1024);
        expect(apiLog.headers['Authorization'], 'Bearer token123');
      });
    });

    group('Logger Service Direct Testing', () {
      test('should add API log through service', () {
        // Act
        loggerService.addApiLog(
          heading: 'Service API Test',
          content: 'Service Response',
          method: 'PATCH',
          url: 'https://api.service.com/patch',
          headers: {'X-Custom': 'header-value'},
          body: 'patch-data',
          statusCode: 204,
          timings: const Duration(milliseconds: 100),
          memoryUsage: 512,
        );

        // Assert
        final logs = container.read(loggerProvider);
        expect(logs.length, 1);

        final apiLog = logs.first as ApiLogModel;
        expect(apiLog.heading, 'Service API Test');
        expect(apiLog.content, 'Service Response');
        expect(apiLog.method, 'PATCH');
        expect(apiLog.url, 'https://api.service.com/patch');
        expect(apiLog.headers['X-Custom'], 'header-value');
        expect(apiLog.body, 'patch-data');
        expect(apiLog.statusCode, 204);
        expect(apiLog.timings, 100);
        expect(apiLog.memoryUsage, 512);
      });

      test('should add multiple different log types', () {
        // Act - Add different types of logs
        loggerService.addDebugLog(
          heading: 'Debug Test',
          content: 'Debug content',
          level: DebugLogLevel.info,
        );

        loggerService.addApiLog(
          heading: 'API Test',
          content: 'API content',
          method: 'GET',
          url: 'https://test.com',
          headers: {},
        );

        loggerService.addLog(
          heading: 'Generic Test',
          content: 'Generic content',
        );

        // Assert
        final logs = container.read(loggerProvider);
        expect(logs.length, 3);

        expect(logs[0] is DebugLogModel, true);
        expect(logs[1] is ApiLogModel, true);
        expect(logs[2].type, 'log');

        final debugLog = logs[0] as DebugLogModel;
        final apiLog = logs[1] as ApiLogModel;

        expect(debugLog.heading, 'Debug Test');
        expect(debugLog.level, 'info');
        expect(apiLog.heading, 'API Test');
        expect(apiLog.method, 'GET');
      });

      test('should clear all logs', () {
        // Arrange - Add some logs first
        loggerService.addApiLog(
          heading: 'Test API',
          content: 'Test Response',
          method: 'GET',
          url: 'https://api.test.com/test',
          headers: {},
        );

        loggerService.addDebugLog(
          heading: 'Test Debug',
          content: 'Test Debug Content',
          level: DebugLogLevel.error,
        );

        expect(container.read(loggerProvider).length, 2);

        // Act
        loggerService.clearLogs();

        // Assert
        expect(container.read(loggerProvider).length, 0);
      });
    });

    group('LoggerDio Interceptor Testing', () {
      test('should initialize LoggerDio interceptor', () {
        // Act
        final loggerDio = LoggerDio();

        // Assert
        expect(loggerDio, isA<LoggerDio>());
        expect(loggerDio, isA<Interceptor>());
      });

      test('should handle request options in onRequest', () {
        // Arrange
        final loggerDio = LoggerDio();
        final requestOptions = RequestOptions(path: '/test');
        final handler = RequestInterceptorHandler();

        // Act
        loggerDio.onRequest(requestOptions, handler);

        // Assert
        expect(requestOptions.extra.containsKey('devLoggerStartTime'), true);
        expect(requestOptions.extra['devLoggerStartTime'], isA<DateTime>());
      });

      test('should handle response in onResponse', () {
        // Arrange
        final loggerDio = LoggerDio();
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        requestOptions.extra['devLoggerStartTime'] = DateTime.now();

        final response = Response(
          requestOptions: requestOptions,
          statusCode: 200,
          data: '{"success": true}',
        );
        final handler = ResponseInterceptorHandler();

        // Act
        loggerDio.onResponse(response, handler);

        // Assert
        final logs = container.read(loggerProvider);
        expect(logs.length, 1);

        final apiLog = logs.first as ApiLogModel;
        expect(apiLog.method, 'GET');
        expect(apiLog.statusCode, 200);
        expect(apiLog.content, '{"success": true}');
        expect(apiLog.url.contains('/test'), true);
        expect(apiLog.heading.contains('[GET]'), true);
      });

      test('should handle error in onError', () {
        // Arrange
        final loggerDio = LoggerDio();
        final requestOptions = RequestOptions(
          path: '/error',
          method: 'POST',
        );
        requestOptions.extra['devLoggerStartTime'] = DateTime.now();

        final dioException = DioException(
          requestOptions: requestOptions,
          message: 'Network timeout',
          type: DioExceptionType.connectionTimeout,
        );

        // Create a mock handler that doesn't propagate the error
        final handler = _MockErrorInterceptorHandler();

        // Act - Call onError which should log the error
        loggerDio.onError(dioException, handler);

        // Assert that the log was created
        final logs = container.read(loggerProvider);
        expect(logs.length, 1);

        final apiLog = logs.first as ApiLogModel;
        expect(apiLog.method, 'POST');
        expect(apiLog.url.contains('/error'), true);
        expect(apiLog.heading.contains('[POST]'), true);
        expect(apiLog.content, contains('Network timeout'));
      });
    });
  });
}

// Mock handler for testing that doesn't propagate errors
class _MockErrorInterceptorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {
    // Don't propagate the error in tests
  }
}
