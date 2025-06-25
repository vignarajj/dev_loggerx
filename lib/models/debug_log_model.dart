import 'package:hive/hive.dart';
import 'dev_log_model.dart';
part 'debug_log_model.g.dart';

/// Model for debug log entries (info, warning, error).
///
/// Extends [DevLogModel] and adds a debug level field.
@HiveType(typeId: 1)
class DebugLogModel extends DevLogModel {
  @HiveField(5)
  final String level;

  DebugLogModel({
    required super.id,
    required super.timestamp,
    required super.heading,
    required super.content,
    required this.level,
  }) : super(type: 'debug');
}
