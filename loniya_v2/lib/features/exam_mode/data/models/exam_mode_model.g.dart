// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'exam_mode_model.dart';

class ExamModeModelAdapter extends TypeAdapter<ExamModeModel> {
  @override
  final int typeId = 21;

  @override
  ExamModeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExamModeModel(
      userId:         fields[0] as String,
      active:         fields[1] as bool,
      startDate:      fields[2] as String,
      endDate:        fields[3] as String,
      subjects:       (fields[4] as List).cast<String>(),
      parentNotified: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExamModeModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.userId)
      ..writeByte(1)..write(obj.active)
      ..writeByte(2)..write(obj.startDate)
      ..writeByte(3)..write(obj.endDate)
      ..writeByte(4)..write(obj.subjects)
      ..writeByte(5)..write(obj.parentNotified);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamModeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
