class PurchaseRecord {
  final int? id;
  final int productId;
  final double quantity;
  final double pricePerUnit;
  final double totalPrice;
  final DateTime purchasedAt;

  PurchaseRecord({
    this.id,
    required this.productId,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    DateTime? purchasedAt,
  }) : purchasedAt = purchasedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
      'purchased_at': purchasedAt.toIso8601String(),
    };
  }

  factory PurchaseRecord.fromMap(Map<String, dynamic> map) {
    return PurchaseRecord(
      id: map['id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      pricePerUnit: map['price_per_unit'],
      totalPrice: map['total_price'],
      purchasedAt: DateTime.parse(map['purchased_at']),
    );
  }
}
