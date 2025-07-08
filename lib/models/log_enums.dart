/// Enum for debug log levels.
enum DebugLogLevel {
  /// Informational/debug message.
  info,

  /// Warning message.
  warning,

  /// Error message.
  error,
}

/// Enum for log types (debug, log, API).
enum DevLogType {
  /// Debug log (info, warning, error).
  debug,

  /// Generic log.
  log,

  /// API log (request/response).
  api,
}
