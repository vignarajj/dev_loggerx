import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logitx/models/dev_log_model.dart';
import 'package:logitx/models/debug_log_model.dart';
import 'package:logitx/models/api_log_model.dart';
import 'package:logitx/config/config.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:logitx/models/log_enums.dart';

/// Riverpod provider for the logger service (log state management).
final loggerProvider = NotifierProvider<LoggerService, List<DevLogModel>>(
  LoggerService.new,
);

/// Service for managing logs (add, clear, persist) using Riverpod state.
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

  @override
  List<DevLogModel> build() {
    // Load persisted logs if available
    if (_hiveInitialized) {
      try {
        final box = Hive.box<DevLogModel>(_boxName);
        return box.values.toList();
      } catch (e) {
        print('Failed to load persisted logs: $e');
      }
    }
    return [];
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
    _persistLog(log);
  }

  /// Add a debug log entry.
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
    _persistLog(log);
  }

  /// Add a generic log entry.
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
    _persistLog(log);
  }

  /// Persist log to Hive if persistence is enabled
  void _persistLog(DevLogModel log) {
    if (_hiveInitialized) {
      try {
        final box = Hive.box<DevLogModel>(_boxName);
        box.add(log);
      } catch (e) {
        print('Failed to persist log: $e');
      }
    }
  }

  void clearLogs() {
    state = [];
    if (_hiveInitialized) {
      try {
        final box = Hive.box<DevLogModel>(_boxName);
        box.clear();
      } catch (e) {
        print('Failed to clear persisted logs: $e');
      }
    }
  }

  /// Load logs from persistence on initialization
  void loadPersistedLogs() {
    if (_hiveInitialized) {
      try {
        final box = Hive.box<DevLogModel>(_boxName);
        state = box.values.toList();
      } catch (e) {
        print('Failed to load persisted logs: $e');
      }
    }
  }
}
