import 'package:equatable/equatable.dart';

class ContentEntity extends Equatable {
  final String id;
  final String title;
  final String subject;
  final String gradeLevel;
  final String type;           // lesson | exercise | video | document
  final String description;
  final String? thumbnailPath;
  final int fileSizeBytes;
  final bool isDownloaded;
  final String? localPath;
  final String createdAt;
  final String authorId;
  final List<String> tags;
  final int downloadCount;
  final double rating;
  final bool isEncrypted;

  const ContentEntity({
    required this.id,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.type,
    required this.description,
    this.thumbnailPath,
    required this.fileSizeBytes,
    required this.isDownloaded,
    this.localPath,
    required this.createdAt,
    required this.authorId,
    required this.tags,
    required this.downloadCount,
    required this.rating,
    required this.isEncrypted,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} Ko';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  String get typeLabel {
    switch (type) {
      case 'lesson':    return 'Leçon';
      case 'exercise':  return 'Exercice';
      case 'video':     return 'Vidéo';
      case 'document':  return 'Document';
      default:          return type;
    }
  }

  @override
  List<Object?> get props => [id, isDownloaded, localPath];
}
