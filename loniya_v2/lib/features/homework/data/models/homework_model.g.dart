// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'homework_model.dart';

class HomeworkModelAdapter extends TypeAdapter<HomeworkModel> {
  @override
  final int typeId = 22;

  @override
  HomeworkModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HomeworkModel(
      id:          fields[0]  as String,
      studentId:   fields[1]  as String,
      teacherId:   fields[2]  as String,
      classCode:   fields[3]  as String,
      title:       fields[4]  as String,
      subject:     fields[5]  as String,
      deadline:    fields[6]  as String,
      durationMin: fields[7]  as int,
      courseId:    fields[8]  as String,
      status:      fields[9]  as String,
      score:       fields[10] as int?,
      assignedAt:  fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HomeworkModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.studentId)
      ..writeByte(2)..write(obj.teacherId)
      ..writeByte(3)..write(obj.classCode)
      ..writeByte(4)..write(obj.title)
      ..writeByte(5)..write(obj.subject)
      ..writeByte(6)..write(obj.deadline)
      ..writeByte(7)..write(obj.durationMin)
      ..writeByte(8)..write(obj.courseId)
      ..writeByte(9)..write(obj.status)
      ..writeByte(10)..write(obj.score)
      ..writeByte(11)..write(obj.assignedAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
