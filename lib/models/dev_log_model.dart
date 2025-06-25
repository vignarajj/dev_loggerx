import 'package:hive/hive.dart';
part 'dev_log_model.g.dart';

/// Base model for all log entries (debug, log, API).
///
/// Stores common log fields: id, timestamp, type, heading, and content.
@HiveType(typeId: 0)
class DevLogModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime timestamp;
  @HiveField(2)
  final String type;
  @HiveField(3)
  final String heading;
  @HiveField(4)
  final String content;

  DevLogModel({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.heading,
    required this.content,
  });
}
