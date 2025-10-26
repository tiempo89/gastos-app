// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MovementAdapter extends TypeAdapter<Movement> {
  @override
  final int typeId = 0;

  @override
  Movement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Movement(
      date: fields[0] as DateTime,
      concept: fields[1] as String,
      amount: fields[2] as double,
      isDigital: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Movement obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.concept)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.isDigital);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
