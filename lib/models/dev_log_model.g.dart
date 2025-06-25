// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dev_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DevLogModelAdapter extends TypeAdapter<DevLogModel> {
  @override
  final int typeId = 0;

  @override
  DevLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DevLogModel(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      type: fields[2] as String,
      heading: fields[3] as String,
      content: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DevLogModel obj) {
    writer
      ..writeByte(5)
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
      other is DevLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
