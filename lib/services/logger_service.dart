import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_loggerx/models/dev_log_model.dart';
import 'package:dev_loggerx/models/debug_log_model.dart';
import 'package:dev_loggerx/models/api_log_model.dart';
import 'package:dev_loggerx/config/config.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:dev_loggerx/models/log_enums.dart';

final loggerProvider = NotifierProvider<LoggerService, List<DevLogModel>>(
  LoggerService.new,
);

class LoggerService extends Notifier<List<DevLogModel>> {
  static const _boxName = 'logger_logs';
  static bool _hiveInitialized = false;

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

  @override
  List<DevLogModel> build() {
    // You may want to load from Hive here if persistence is enabled
    return [];
  }

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
    state = [...state, log];
  }

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
    state = [...state, log];
  }

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
    state = [...state, log];
  }

  void clearLogs() {
    state = [];
  }
}
