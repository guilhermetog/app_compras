class ShoppingList {
  final int? id;
  final String name;
  final DateTime createdAt;
  bool isCompleted;

  ShoppingList({
    this.id,
    required this.name,
    DateTime? createdAt,
    this.isCompleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      isCompleted: map['is_completed'] == 1,
    );
  }
}

class ShoppingListItem {
  final int? id;
  final int shoppingListId;
  final int productId;
  double quantity;

  ShoppingListItem({
    this.id,
    required this.shoppingListId,
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopping_list_id': shoppingListId,
      'product_id': productId,
      'quantity': quantity,
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'],
      shoppingListId: map['shopping_list_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
    );
  }
}
