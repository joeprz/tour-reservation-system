
enum ReservationStatus {
  pending,
  confirmed,
  cancelled,
  checkedIn,
  noShow;

  String get label {
    switch (this) {
      case ReservationStatus.pending:
        return 'Pendiente';
      case ReservationStatus.confirmed:
        return 'Confirmada';
      case ReservationStatus.cancelled:
        return 'Cancelada';
      case ReservationStatus.checkedIn:
        return 'Ingresó';
      case ReservationStatus.noShow:
        return 'No Show';
    }
  }

  static ReservationStatus fromString(String s) {
    switch (s) {
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'checked_in':
        return ReservationStatus.checkedIn;
      case 'no_show':
        return ReservationStatus.noShow;
      default:
        return ReservationStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case ReservationStatus.pending:
        return 'pending';
      case ReservationStatus.confirmed:
        return 'confirmed';
      case ReservationStatus.cancelled:
        return 'cancelled';
      case ReservationStatus.checkedIn:
        return 'checked_in';
      case ReservationStatus.noShow:
        return 'no_show';
    }
  }
}

class Reservation {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;

  final String code;
  final String token;

  final String date;
  final String timeSlot;

  final int adults;
  final int children;

  final double adultPrice;
  final double childPrice;

  final double total;
  final double deposit;
  final double balance;

  final String packageType;
  final String packageName;

  final int tents;

  final ReservationStatus status;

  final String? notes;

  final DateTime? checkedInAt;
  final String? checkedInBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reservation({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.code,
    required this.token,
    required this.date,
    required this.timeSlot,
    required this.adults,
    required this.children,
    required this.adultPrice,
    required this.childPrice,
    required this.total,
    required this.deposit,
    required this.balance,
    required this.packageType,
    required this.packageName,
    required this.tents,
    required this.status,
    this.notes,
    this.checkedInAt,
    this.checkedInBy,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalPeople => adults + children;

  bool get isPaid => balance <= 0;

  bool get hasCamping =>
      packageType == 'camping' ||
      packageType == 'premium';

  bool get isCheckedIn =>
      status == ReservationStatus.checkedIn;

  static const _sentinel = Object();

Reservation copyWith({
  String? id,
  String? customerId,
  String? customerName,
  String? customerPhone,
  String? code,
  String? token,
  String? date,
  String? timeSlot,
  int? adults,
  int? children,
  double? adultPrice,
  double? childPrice,
  double? total,
  double? deposit,
  double? balance,
  String? packageType,
  String? packageName,
  int? tents,
  ReservationStatus? status,
  String? notes,
  Object? checkedInAt = _sentinel,
  Object? checkedInBy = _sentinel,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Reservation(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    customerName:
        customerName ?? this.customerName,
    customerPhone:
        customerPhone ?? this.customerPhone,
    code: code ?? this.code,
    token: token ?? this.token,
    date: date ?? this.date,
    timeSlot: timeSlot ?? this.timeSlot,
    adults: adults ?? this.adults,
    children: children ?? this.children,
    adultPrice:
        adultPrice ?? this.adultPrice,
    childPrice:
        childPrice ?? this.childPrice,
    total: total ?? this.total,
    deposit: deposit ?? this.deposit,
    balance: balance ?? this.balance,
    packageType:
        packageType ?? this.packageType,
    packageName:
        packageName ?? this.packageName,
    tents: tents ?? this.tents,
    status: status ?? this.status,
    notes: notes ?? this.notes,

    checkedInAt:
        checkedInAt == _sentinel
            ? this.checkedInAt
            : checkedInAt as DateTime?,

    checkedInBy:
        checkedInBy == _sentinel
            ? this.checkedInBy
            : checkedInBy as String?,

    createdAt:
        createdAt ?? this.createdAt,
    updatedAt:
        updatedAt ?? this.updatedAt,
  );
}

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
 'customer_phone': customerPhone,
      'code': code,
      'token': token,
      'date': date,
      'time_slot': timeSlot,
      'adults': adults,
      'children': children,
      'adult_price': adultPrice,
      'child_price': childPrice,
      'total': total,
      'deposit': deposit,
      'balance': balance,
      'package_type': packageType,
      'package_name': packageName,
      'tents': tents,
      'status': status.value,
      'notes': notes,
      'checked_in_at': checkedInAt?.toIso8601String(),
      'checked_in_by': checkedInBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
Map<String, dynamic> toJson() {
  return {
    ...toMap(),
    'customer_name': customerName,
    'customer_phone': customerPhone,
  };
}
  factory Reservation.fromMap(
    Map<String, dynamic> map, {
    String? customerName,
    String? customerPhone,
  }) {
    return Reservation(
      id: map['id'],
      customerId: map['customer_id'],
      customerName:
          customerName ??
          map['customer_name'] ??
          '',
      customerPhone:
          customerPhone ??
          map['customer_phone'] ??
          '',
      code: map['code'],
      token: map['token'],
      date: map['date'],
      timeSlot: map['time_slot'],
      adults: (map['adults'] as num).toInt(),
children: (map['children'] as num).toInt(),
      adultPrice:
          (map['adult_price'] as num)
              .toDouble(),
      childPrice:
          (map['child_price'] as num)
              .toDouble(),
      total:
          (map['total'] as num)
              .toDouble(),
      deposit:
          (map['deposit'] as num)
              .toDouble(),
      balance:
          (map['balance'] as num)
              .toDouble(),
      packageType:
          map['package_type'] ??
          'basic',
      packageName:
          map['package_name'] ??
          'PAQUETE BÁSICO',
      tents:
          map['tents'] ?? 0,
      status:
          ReservationStatus
              .fromString(
        map['status'],
      ),
      notes: map['notes'],
      checkedInAt:
          map['checked_in_at'] != null
              ? DateTime.parse(
                  map['checked_in_at'])
              : null,
      checkedInBy: map['checked_in_by'],
      createdAt:
          DateTime.parse(
              map['created_at']),
      updatedAt:
          DateTime.parse(
              map['updated_at']),
    );
  }
}