class Expense {
  final String id;
  final String concept;
  final double amount;
  final String date;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.concept,
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      concept: map['concept'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'concept': concept,
      'amount': amount,
      'date': date,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
