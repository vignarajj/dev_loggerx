import 'package:hive/hive.dart';
import 'dev_log_model.dart';
part 'api_log_model.g.dart';

@HiveType(typeId: 2)
class ApiLogModel extends DevLogModel {
  @HiveField(5)
  final String method;
  @HiveField(6)
  final String url;
  @HiveField(7)
  final Map<String, dynamic> headers;
  @HiveField(8)
  final dynamic body;
  @HiveField(9)
  final int? statusCode;
  @HiveField(10)
  final int? timings;
  @HiveField(11)
  final int? memoryUsage;

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
