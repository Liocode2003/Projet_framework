// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
part of 'credit_model.dart';

class CreditModelAdapter extends TypeAdapter<CreditModel> {
  @override
  final int typeId = 20;

  @override
  CreditModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditModel(
      userId:      fields[0] as String,
      base:        fields[1] as int,
      bonus:       fields[2] as int,
      resetMonth:  fields[3] as String,
      totalEarned: fields[4] as int,
      totalSpent:  fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CreditModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.userId)
      ..writeByte(1)..write(obj.base)
      ..writeByte(2)..write(obj.bonus)
      ..writeByte(3)..write(obj.resetMonth)
      ..writeByte(4)..write(obj.totalEarned)
      ..writeByte(5)..write(obj.totalSpent);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
