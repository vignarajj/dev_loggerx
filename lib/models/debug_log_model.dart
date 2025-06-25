import 'package:hive/hive.dart';
import 'dev_log_model.dart';
part 'debug_log_model.g.dart';

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
