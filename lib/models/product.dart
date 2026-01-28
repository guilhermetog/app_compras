class Product {
  final int? id;
  final String name;
  double stockQuantity;
  double weeklyDemand;
  double monthlyDemand;
  final DateTime createdAt;

  Product({
    this.id,
    required this.name,
    this.stockQuantity = 0.0,
    this.weeklyDemand = 0.0,
    this.monthlyDemand = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Predict weeks until shortage
  double? predictShortage() {
    if (weeklyDemand == 0) return null;
    return stockQuantity / weeklyDemand;
  }

  // Check if product needs to be purchased
  bool needsPurchase({double weeksThreshold = 2}) {
    final shortage = predictShortage();
    if (shortage == null) return false;
    return shortage < weeksThreshold;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stock_quantity': stockQuantity,
      'weekly_demand': weeklyDemand,
      'monthly_demand': monthlyDemand,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      stockQuantity: map['stock_quantity'],
      weeklyDemand: map['weekly_demand'],
      monthlyDemand: map['monthly_demand'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
