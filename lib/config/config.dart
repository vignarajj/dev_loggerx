// Config layer for Logger plugin

/// Logger configuration model for DevLoggerX.
///
/// Holds all runtime config options for the logger overlay and persistence.
class LoggerConfig {
  /// Enable logger in debug mode (default: true)
  final bool enableInDebug;

  /// List of allowed IDs (email, phone, or string IDs) for access in production. If empty, no one is allowed by ID.
  final List<String> allowedIds;

  /// Enable global long-press gesture to open overlay (default: true)
  final bool enableLongPressGesture;

  /// Enable log persistence using Hive (default: false)
  final bool enablePersistence;

  /// Maximum number of logs to store (if persistence enabled)
  final int? maxStoredLogs;

  /// Create a LoggerConfig.
  const LoggerConfig({
    this.enableInDebug = true,
    this.allowedIds = const [],
    this.enableLongPressGesture = true,
    this.enablePersistence = false,
    this.maxStoredLogs,
  });

  /// Copy this config with new values.
  LoggerConfig copyWith({
    bool? enableInDebug,
    List<String>? allowedIds,
    bool? enableLongPressGesture,
    bool? enablePersistence,
    int? maxStoredLogs,
  }) {
    return LoggerConfig(
      enableInDebug: enableInDebug ?? this.enableInDebug,
      allowedIds: allowedIds ?? this.allowedIds,
      enableLongPressGesture:
          enableLongPressGesture ?? this.enableLongPressGesture,
      enablePersistence: enablePersistence ?? this.enablePersistence,
      maxStoredLogs: maxStoredLogs ?? this.maxStoredLogs,
    );
  }
}
