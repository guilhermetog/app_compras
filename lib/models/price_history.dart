class PriceHistory {
  final int? id;
  final int productId;
  final double price;
  final DateTime recordedAt;

  PriceHistory({
    this.id,
    required this.productId,
    required this.price,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'price': price,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  factory PriceHistory.fromMap(Map<String, dynamic> map) {
    return PriceHistory(
      id: map['id'],
      productId: map['product_id'],
      price: map['price'],
      recordedAt: DateTime.parse(map['recorded_at']),
    );
  }
}
