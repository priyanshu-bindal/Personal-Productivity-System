class Budget {
  final String id;
  final String userId;
  final String category;
  final double monthlyLimit;
  final String month; // YYYY-MM-01
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.monthlyLimit,
    required this.month,
    required this.createdAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: (json['category'] as String).toLowerCase(),
      monthlyLimit: (json['monthly_limit'] is num)
          ? (json['monthly_limit'] as num).toDouble()
          : double.parse(json['monthly_limit'].toString()),
      month: json['month'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'category': category.toLowerCase(),
      'monthly_limit': monthlyLimit,
      'month': month,
    };
  }
}
