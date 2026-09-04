class Expense {
  final String id;
  final String userId;
  final double amount;
  final String description;
  final String category;
  final String paymentMethod;
  final String expenseDate; // YYYY-MM-DD
  final String? note;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.category,
    required this.paymentMethod,
    required this.expenseDate,
    this.note,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.parse(json['amount'].toString()),
      description: json['description'] as String,
      category: (json['category'] as String).toLowerCase(),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      expenseDate: json['expense_date'] as String? ?? DateTime.now().toIso8601String().split('T')[0],
      note: json['note'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'amount': amount,
      'description': description,
      'category': category.toLowerCase(),
      'payment_method': paymentMethod.toLowerCase().replaceAll(' ', '_'),
      'expense_date': expenseDate,
      'note': note,
    };
  }
}
