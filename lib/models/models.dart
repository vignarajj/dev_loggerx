// Models layer for DevLogger plugin 

import 'package:hive/hive.dart';
part 'models.g.dart';

/// Types of logs supported by DevLogger.
enum DevLogType { debug, log, api }

/// Levels for debug logs.
enum DebugLogLevel { error, info, warning }

/// Base log model for all log types.
@HiveType(typeId: 0)
class DevLogModel {
  /// Unique log ID
  @HiveField(0)
  final String id;
  /// Timestamp of log creation
  @HiveField(1)
  final DateTime timestamp;
  /// Log type as string ('debug', 'log', 'api')
  @HiveField(2)
  final String type;
  /// Short heading/title for the log
  @HiveField(3)
  final String heading;
  /// Main log content/message
  @HiveField(4)
  final String content;

  /// Create a base log model.
  DevLogModel({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.heading,
    required this.content,
  });
}

/// Debug log model with level (error/info/warning).
@HiveType(typeId: 1)
class DebugLogModel extends DevLogModel {
  /// Debug log level
  @HiveField(5)
  final String level;

  /// Create a debug log.
  DebugLogModel({
    required super.id,
    required super.timestamp,
    required super.heading,
    required super.content,
    required this.level,
  }) : super(type: 'debug');
}

/// API log model with request/response details.
@HiveType(typeId: 2)
class ApiLogModel extends DevLogModel {
  /// HTTP method (GET, POST, etc)
  @HiveField(5)
  final String method;
  /// Request URL
  @HiveField(6)
  final String url;
  /// Request/response headers
  @HiveField(7)
  final Map<String, dynamic> headers;
  /// Request body
  @HiveField(8)
  final dynamic body;
  /// HTTP status code
  @HiveField(9)
  final int? statusCode;
  /// Request/response time in ms
  @HiveField(10)
  final int? timings;
  /// Memory usage (optional)
  @HiveField(11)
  final int? memoryUsage;

  /// Create an API log.
  ApiLogModel({
    required super.id,
    required super.timestamp,
    required super.heading,
    required super.content,
    required this.method,
    required this.url,
    required this.headers,
    this.body,
    this.statusCode,
    this.timings,
    this.memoryUsage,
  }) : super(type: 'api');
} 