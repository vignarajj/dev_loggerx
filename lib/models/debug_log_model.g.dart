// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debug_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebugLogModelAdapter extends TypeAdapter<DebugLogModel> {
  @override
  final int typeId = 1;

  @override
  DebugLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebugLogModel(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      heading: fields[3] as String,
      content: fields[4] as String,
      level: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DebugLogModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(5)
      ..write(obj.level)
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
      other is DebugLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
