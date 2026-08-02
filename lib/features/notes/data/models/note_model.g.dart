// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      updatedAt: fields[3] as DateTime,
      syncStatus: fields[4] as String,
      isDeleted: fields[5] as bool,
      lastSyncedAt: fields[6] as DateTime?,
      serverUpdatedAt: fields[7] as DateTime?,
      conflictTitle: fields[8] as String?,
      conflictBody: fields[9] as String?,
      conflictUpdatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.syncStatus)
      ..writeByte(5)
      ..write(obj.isDeleted)
      ..writeByte(6)
      ..write(obj.lastSyncedAt)
      ..writeByte(7)
      ..write(obj.serverUpdatedAt)
      ..writeByte(8)
      ..write(obj.conflictTitle)
      ..writeByte(9)
      ..write(obj.conflictBody)
      ..writeByte(10)
      ..write(obj.conflictUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
