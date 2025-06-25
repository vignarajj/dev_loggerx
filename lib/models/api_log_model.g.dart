// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApiLogModelAdapter extends TypeAdapter<ApiLogModel> {
  @override
  final int typeId = 2;

  @override
  ApiLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiLogModel(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      heading: fields[3] as String,
      content: fields[4] as String,
      method: fields[5] as String,
      url: fields[6] as String,
      headers: (fields[7] as Map).cast<String, dynamic>(),
      body: fields[8] as dynamic,
      statusCode: fields[9] as int?,
      timings: fields[10] as int?,
      memoryUsage: fields[11] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ApiLogModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(5)
      ..write(obj.method)
      ..writeByte(6)
      ..write(obj.url)
      ..writeByte(7)
      ..write(obj.headers)
      ..writeByte(8)
      ..write(obj.body)
      ..writeByte(9)
      ..write(obj.statusCode)
      ..writeByte(10)
      ..write(obj.timings)
      ..writeByte(11)
      ..write(obj.memoryUsage)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.heading)
      ..writeByte(4)
      ..write(obj.content);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
