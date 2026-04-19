import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';

class SubscriptionModel extends HiveObject {
  final String userId;
  final String plan;                    // 'annual'
  final int priceFcfa;                  // 2000
  final String startDate;              // ISO8601
  final String expiresAt;              // ISO8601
  final String paymentRef;             // mobile money transaction code
  final bool isActive;
  final bool isVerified;               // admin-validated teacher
  final String? verificationRequestedAt;

  SubscriptionModel({
    required this.userId,
    this.plan = 'annual',
    this.priceFcfa = 2000,
    required this.startDate,
    required this.expiresAt,
    required this.paymentRef,
    this.isActive = true,
    this.isVerified = false,
    this.verificationRequestedAt,
  });

  bool get isExpired => DateTime.now().isAfter(DateTime.parse(expiresAt));
  bool get isValid => isActive && !isExpired;
  bool get hasRequestedVerification => verificationRequestedAt != null;

  String get formattedExpiry {
    final dt = DateTime.parse(expiresAt);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  int get daysRemaining {
    final exp = DateTime.parse(expiresAt);
    return exp.difference(DateTime.now()).inDays.clamp(0, 999);
  }

  SubscriptionModel copyWith({
    bool? isActive,
    bool? isVerified,
    String? verificationRequestedAt,
  }) =>
      SubscriptionModel(
        userId: userId,
        plan: plan,
        priceFcfa: priceFcfa,
        startDate: startDate,
        expiresAt: expiresAt,
        paymentRef: paymentRef,
        isActive: isActive ?? this.isActive,
        isVerified: isVerified ?? this.isVerified,
        verificationRequestedAt:
            verificationRequestedAt ?? this.verificationRequestedAt,
      );
}

class SubscriptionModelAdapter extends TypeAdapter<SubscriptionModel> {
  @override
  final int typeId = HiveTypeIds.subscriptionModel;

  @override
  SubscriptionModel read(BinaryReader reader) {
    final f = reader.readMap().cast<int, dynamic>();
    return SubscriptionModel(
      userId: f[0] as String,
      plan: f[1] as String? ?? 'annual',
      priceFcfa: f[2] as int? ?? 2000,
      startDate: f[3] as String,
      expiresAt: f[4] as String,
      paymentRef: f[5] as String? ?? '',
      isActive: f[6] as bool? ?? true,
      isVerified: f[7] as bool? ?? false,
      verificationRequestedAt: f[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionModel obj) {
    writer.writeMap({
      0: obj.userId,
      1: obj.plan,
      2: obj.priceFcfa,
      3: obj.startDate,
      4: obj.expiresAt,
      5: obj.paymentRef,
      6: obj.isActive,
      7: obj.isVerified,
      8: obj.verificationRequestedAt,
    });
  }
}
