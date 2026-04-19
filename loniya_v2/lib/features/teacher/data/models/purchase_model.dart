import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';

class PurchaseModel extends HiveObject {
  final String id;
  final String userId;       // buyer
  final String contentId;
  final String contentTitle;
  final int priceFcfa;
  final String purchasedAt;  // ISO8601
  final String paymentRef;   // mobile money ref
  final String teacherId;    // content author (for revenue tracking)

  PurchaseModel({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.contentTitle,
    required this.priceFcfa,
    required this.purchasedAt,
    required this.paymentRef,
    required this.teacherId,
  });

  String get formattedDate {
    final dt = DateTime.parse(purchasedAt);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String get formattedPrice => '$priceFcfa FCFA';
}

class PurchaseModelAdapter extends TypeAdapter<PurchaseModel> {
  @override
  final int typeId = HiveTypeIds.purchaseModel;

  @override
  PurchaseModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return PurchaseModel(
      id: f[0] as String,
      userId: f[1] as String,
      contentId: f[2] as String,
      contentTitle: f[3] as String,
      priceFcfa: f[4] as int? ?? 0,
      purchasedAt: f[5] as String,
      paymentRef: f[6] as String? ?? '',
      teacherId: f[7] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseModel obj) {
    writer.writeMap({
      0: obj.id,
      1: obj.userId,
      2: obj.contentId,
      3: obj.contentTitle,
      4: obj.priceFcfa,
      5: obj.purchasedAt,
      6: obj.paymentRef,
      7: obj.teacherId,
    });
  }
}
