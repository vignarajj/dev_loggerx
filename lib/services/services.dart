// Services layer for Logger plugin 
// Handles log storage, persistence, and API logging integrations.

import 'package:dev_loggerx/dev_loggerx.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Riverpod provider for accessing the logger service.
final loggerProvider =
    NotifierProvider<LoggerService, List<DevLogModel>>(
  LoggerService.new,
);

/// Central service for collecting, storing, and accessing logs.
/// Supports in-memory and persistent storage, and API log integration.
class LoggerService extends Notifier<List<DevLogModel>> {
  static const _boxName = 'logger_logs';
  static bool _hiveInitialized = false;

  /// Initialize Hive persistence if enabled in config.
  static Future<void> initPersistenceIfNeeded(LoggerConfig config) async {
    if (config.enablePersistence && !_hiveInitialized) {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DevLogModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(DebugLogModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ApiLogModelAdapter());
      }
      await Hive.openBox<DevLogModel>(_boxName);
      _hiveInitialized = true;
    }
  }

  final _uuid = const Uuid();

  /// Load logs from Hive if enabled, otherwise use in-memory list.
  @override
  List<DevLogModel> build() {
    final config = LoggerCore.config.value;
    if (config.enablePersistence && _hiveInitialized) {
      final box = Hive.box<DevLogModel>(_boxName);
      return box.values.toList();
    }
    return [];
  }

  /// Persist logs to Hive if enabled.
  void _persistLogs(List<DevLogModel> logs) {
    final config = LoggerCore.config.value;
    if (config.enablePersistence && _hiveInitialized) {
      final box = Hive.box<DevLogModel>(_boxName);
      box.clear();
      for (final log in logs) {
        box.add(log);
      }
    }
  }

  /// Add a debug/info/error log.
  void addDebugLog({
    required String heading,
    required String content,
    required DebugLogLevel level,
  }) {
    final log = DebugLogModel(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      heading: heading,
      content: content,
      level: level.name,
    );
    final updated = [...state, log];
    _pruneAndPersist(updated);
    state = updated;
  }

  /// Add a generic log.
  void addLog({
    required String heading,
    required String content,
  }) {
    final log = DevLogModel(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      type: 'log',
      heading: heading,
      content: content,
    );
    final updated = [...state, log];
    _pruneAndPersist(updated);
    state = updated;
  }

  /// Add an API log (request/response).
  void addApiLog({
    required String heading,
    required String content,
    required String method,
    required String url,
    required Map<String, dynamic> headers,
    dynamic body,
    int? statusCode,
    Duration? timings,
    int? memoryUsage,
  }) {
    final log = ApiLogModel(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      heading: heading,
      content: content,
      method: method,
      url: url,
      headers: headers,
      body: body,
      statusCode: statusCode,
      timings: timings?.inMilliseconds,
      memoryUsage: memoryUsage,
    );
    final updated = [...state, log];
    _pruneAndPersist(updated);
    state = updated;
  }

  /// Clear all logs.
  void clearLogs() {
    _persistLogs([]);
    state = [];
  }

  /// Prune logs to maxStoredLogs if set, then persist.
  void _pruneAndPersist(List<DevLogModel> logs) {
    final config = LoggerCore.config.value;
    List<DevLogModel> pruned = logs;
    if (config.maxStoredLogs != null && logs.length > config.maxStoredLogs!) {
      pruned = logs.sublist(logs.length - config.maxStoredLogs!);
    }
    _persistLogs(pruned);
  }

  /// Get logs filtered by type.
  List<DevLogModel> getLogsByType(DevLogType type) {
    return state.where((log) => log.type == type.name).toList();
  }
}

/// Dio interceptor for automatic API logging.
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
          memoryUsage: null, // Optionally add memory usage if needed
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

/// http.Client wrapper for automatic API logging.
class LoggerHttp extends http.BaseClient {
  final http.Client _inner;
  final WidgetRef ref;

  LoggerHttp(this.ref, [http.Client? inner])
      : _inner = inner ?? http.Client();

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
