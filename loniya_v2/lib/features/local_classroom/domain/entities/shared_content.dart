import 'package:equatable/equatable.dart';

class SharedContent extends Equatable {
  final String id;
  final String title;
  final String subject;
  final String gradeLevel;
  final String type;
  final int fileSizeBytes;

  const SharedContent({
    required this.id,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.type,
    required this.fileSizeBytes,
  });

  factory SharedContent.fromJson(Map<String, dynamic> j) => SharedContent(
        id: j['id'] as String,
        title: j['title'] as String,
        subject: j['subject'] as String,
        gradeLevel: j['grade_level'] as String,
        type: j['type'] as String,
        fileSizeBytes: j['file_size_bytes'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'grade_level': gradeLevel,
        'type': type,
        'file_size_bytes': fileSizeBytes,
      };

  String get formattedSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes} B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [id];
}
