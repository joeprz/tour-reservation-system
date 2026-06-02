// lib/domain/entities/customer.dart
class Customer {
  final String id;
  final String name;
  final String phone;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() => 'Customer(id: $id, name: $name, phone: $phone)';
}
