import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';

part 'marketplace_item_model.g.dart';

@HiveType(typeId: HiveTypeIds.marketplaceItemModel)
class MarketplaceItemModel extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String title;
  @HiveField(2)  final String subject;
  @HiveField(3)  final String gradeLevel;
  @HiveField(4)  final String type;
  @HiveField(5)  final String description;
  @HiveField(6)  final String? thumbnailPath;
  @HiveField(7)  final int fileSizeBytes;
  @HiveField(8)  final bool isDownloaded;
  @HiveField(9)  final String? localPath;
  @HiveField(10) final String createdAt;
  @HiveField(11) final String authorId;
  @HiveField(12) final List<String> tags;
  @HiveField(13) final int downloadCount;
  @HiveField(14) final double rating;
  @HiveField(15) final bool isEncrypted;
  @HiveField(16) final int priceFcfa;   // 0 = free, else price in FCFA

  MarketplaceItemModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.type,
    required this.description,
    this.thumbnailPath,
    required this.fileSizeBytes,
    this.isDownloaded = false,
    this.localPath,
    required this.createdAt,
    required this.authorId,
    required this.tags,
    this.downloadCount = 0,
    this.rating = 0.0,
    this.isEncrypted = true,
    this.priceFcfa = 0,
  });

  bool get isFree => priceFcfa == 0;

  factory MarketplaceItemModel.fromJson(Map<String, dynamic> j) =>
      MarketplaceItemModel(
        id: j['id'] as String,
        title: j['title'] as String,
        subject: j['subject'] as String,
        gradeLevel: j['grade_level'] as String,
        type: j['type'] as String,
        description: j['description'] as String? ?? '',
        thumbnailPath: j['thumbnail_path'] as String?,
        fileSizeBytes: j['file_size_bytes'] as int? ?? 0,
        isDownloaded: j['is_downloaded'] as bool? ?? false,
        localPath: j['local_path'] as String?,
        createdAt: j['created_at'] as String,
        authorId: j['author_id'] as String? ?? '',
        tags: List<String>.from(j['tags'] as List? ?? []),
        downloadCount: j['download_count'] as int? ?? 0,
        rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
        isEncrypted: j['is_encrypted'] as bool? ?? true,
        priceFcfa: j['price_fcfa'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'grade_level': gradeLevel,
        'type': type,
        'description': description,
        'thumbnail_path': thumbnailPath,
        'file_size_bytes': fileSizeBytes,
        'is_downloaded': isDownloaded,
        'local_path': localPath,
        'created_at': createdAt,
        'author_id': authorId,
        'tags': tags,
        'download_count': downloadCount,
        'rating': rating,
        'is_encrypted': isEncrypted,
        'price_fcfa': priceFcfa,
      };

  MarketplaceItemModel copyWith({
    bool? isDownloaded,
    String? localPath,
    int? downloadCount,
    double? rating,
    int? priceFcfa,
  }) =>
      MarketplaceItemModel(
        id: id, title: title, subject: subject, gradeLevel: gradeLevel,
        type: type, description: description, thumbnailPath: thumbnailPath,
        fileSizeBytes: fileSizeBytes, createdAt: createdAt, authorId: authorId,
        tags: tags, isEncrypted: isEncrypted,
        isDownloaded: isDownloaded ?? this.isDownloaded,
        localPath: localPath ?? this.localPath,
        downloadCount: downloadCount ?? this.downloadCount,
        rating: rating ?? this.rating,
        priceFcfa: priceFcfa ?? this.priceFcfa,
      );
}

class MarketplaceItemModelAdapter extends TypeAdapter<MarketplaceItemModel> {
  @override
  final int typeId = HiveTypeIds.marketplaceItemModel;

  @override
  MarketplaceItemModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return MarketplaceItemModel(
      id: f[0] as String,
      title: f[1] as String,
      subject: f[2] as String,
      gradeLevel: f[3] as String,
      type: f[4] as String,
      description: f[5] as String,
      thumbnailPath: f[6] as String?,
      fileSizeBytes: f[7] as int,
      isDownloaded: f[8] as bool,
      localPath: f[9] as String?,
      createdAt: f[10] as String,
      authorId: f[11] as String,
      tags: List<String>.from(f[12] as List? ?? []),
      downloadCount: f[13] as int? ?? 0,
      rating: (f[14] as num?)?.toDouble() ?? 0.0,
      isEncrypted: f[15] as bool? ?? true,
      priceFcfa: f[16] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, MarketplaceItemModel obj) {
    writer.writeMap({
      0: obj.id, 1: obj.title, 2: obj.subject, 3: obj.gradeLevel,
      4: obj.type, 5: obj.description, 6: obj.thumbnailPath,
      7: obj.fileSizeBytes, 8: obj.isDownloaded, 9: obj.localPath,
      10: obj.createdAt, 11: obj.authorId, 12: obj.tags,
      13: obj.downloadCount, 14: obj.rating, 15: obj.isEncrypted,
      16: obj.priceFcfa,
    });
  }
}
