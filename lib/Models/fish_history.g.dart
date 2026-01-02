// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fish_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FishHistoryAdapter extends TypeAdapter<FishHistory> {
  @override
  final int typeId = 0;

  @override
  FishHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FishHistory(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      speciesLabel: fields[2] as String,
      speciesConfidence: fields[3] as double,
      freshnessLabel: fields[4] as String,
      freshnessConfidence: fields[5] as double,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FishHistory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.speciesLabel)
      ..writeByte(3)
      ..write(obj.speciesConfidence)
      ..writeByte(4)
      ..write(obj.freshnessLabel)
      ..writeByte(5)
      ..write(obj.freshnessConfidence)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FishHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
