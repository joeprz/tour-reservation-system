import '../../core/constants/app_constants.dart';

class AppSettings {
  final int id;

  final double basicAdultPrice;
  final double basicChildPrice;

  final double campingAdultPrice;
  final double campingChildPrice;

  final double premiumAdultPrice;
  final double premiumChildPrice;

  final double tent2PersonPrice; // 2 personas - 280
  final double tent4PersonPrice; // 4 personas - 450
  final double tent6PersonPrice; // 6 personas - 600
  final double tent10PersonPrice; // 10 personas - 900

  final String businessName;
  final List<String> timeSlots;
  final String adminPin;
  final DateTime updatedAt;

  const AppSettings({
    required this.id,
    required this.basicAdultPrice,
    required this.basicChildPrice,
    required this.campingAdultPrice,
    required this.campingChildPrice,
    required this.premiumAdultPrice,
    required this.premiumChildPrice,
    this.tent2PersonPrice = 280,
    this.tent4PersonPrice = 450,
    this.tent6PersonPrice = 600,
    this.tent10PersonPrice = 900,
    required this.businessName,
    required this.timeSlots,
    required this.adminPin,
    required this.updatedAt,
  });

  static AppSettings get defaults => AppSettings(
        id: 1,
        basicAdultPrice: 300,
        basicChildPrice: 200,
        campingAdultPrice: 500,
        campingChildPrice: 400,
        premiumAdultPrice: 1000,
        premiumChildPrice: 800,
        tent2PersonPrice: 280,
        tent4PersonPrice: 450,
        tent6PersonPrice: 600,
        tent10PersonPrice: 900,
        businessName: AppConstants.businessName,
        timeSlots: AppConstants.defaultTimeSlots,
        adminPin: '330297',
        updatedAt: DateTime.now(),
      );

  AppSettings copyWith({
    double? basicAdultPrice,
    double? basicChildPrice,
    double? campingAdultPrice,
    double? campingChildPrice,
    double? premiumAdultPrice,
    double? premiumChildPrice,
    double? tent2PersonPrice,
    double? tent4PersonPrice,
    double? tent6PersonPrice,
    double? tent10PersonPrice,
    String? businessName,
    List<String>? timeSlots,
    String? adminPin,
  }) {
    return AppSettings(
      id: id,
      basicAdultPrice: basicAdultPrice ?? this.basicAdultPrice,
      basicChildPrice: basicChildPrice ?? this.basicChildPrice,
      campingAdultPrice: campingAdultPrice ?? this.campingAdultPrice,
      campingChildPrice: campingChildPrice ?? this.campingChildPrice,
      premiumAdultPrice: premiumAdultPrice ?? this.premiumAdultPrice,
      premiumChildPrice: premiumChildPrice ?? this.premiumChildPrice,
      tent2PersonPrice: tent2PersonPrice ?? this.tent2PersonPrice,
      tent4PersonPrice: tent4PersonPrice ?? this.tent4PersonPrice,
      tent6PersonPrice: tent6PersonPrice ?? this.tent6PersonPrice,
      tent10PersonPrice: tent10PersonPrice ?? this.tent10PersonPrice,
      businessName: businessName ?? this.businessName,
      timeSlots: timeSlots ?? this.timeSlots,
      adminPin: adminPin ?? this.adminPin,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'basic_adult_price': basicAdultPrice,
      'basic_child_price': basicChildPrice,
      'camping_adult_price': campingAdultPrice,
      'camping_child_price': campingChildPrice,
      'premium_adult_price': premiumAdultPrice,
      'premium_child_price': premiumChildPrice,
      'tent_2_person_price': tent2PersonPrice,
      'tent_4_person_price': tent4PersonPrice,
      'tent_6_person_price': tent6PersonPrice,
      'tent_10_person_price': tent10PersonPrice,
      'business_name': businessName,
      'time_slots': timeSlots.join(','),
      'admin_pin': adminPin,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(
    Map<String, dynamic> map,
  ) {
    return AppSettings(
      id: map['id'] as int,
      basicAdultPrice: (map['basic_adult_price'] as num?)?.toDouble() ?? 300,
      basicChildPrice: (map['basic_child_price'] as num?)?.toDouble() ?? 200,
      campingAdultPrice:
          (map['camping_adult_price'] as num?)?.toDouble() ?? 500,
      campingChildPrice:
          (map['camping_child_price'] as num?)?.toDouble() ?? 400,
      premiumAdultPrice:
          (map['premium_adult_price'] as num?)?.toDouble() ?? 1000,
      premiumChildPrice:
          (map['premium_child_price'] as num?)?.toDouble() ?? 800,
      tent2PersonPrice: (map['tent_2_person_price'] as num?)?.toDouble() ?? 280,
      tent4PersonPrice: (map['tent_4_person_price'] as num?)?.toDouble() ?? 450,
      tent6PersonPrice: (map['tent_6_person_price'] as num?)?.toDouble() ?? 600,
      tent10PersonPrice:
          (map['tent_10_person_price'] as num?)?.toDouble() ?? 900,
      businessName: map['business_name'] as String,
      timeSlots: (map['time_slots'] as String).split(','),
      adminPin: map['admin_pin'] as String,
      updatedAt: DateTime.parse(
        map['updated_at'] as String,
      ),
    );
  }
}
