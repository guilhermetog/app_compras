import 'package:flutter_test/flutter_test.dart';
import 'package:app_compras/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('Product should predict shortage correctly', () {
      final product = Product(
        name: 'Test Product',
        stockQuantity: 10,
        weeklyDemand: 5,
      );

      final shortage = product.predictShortage();
      expect(shortage, 2.0); // 10 / 5 = 2 weeks
    });

    test('Product should identify when purchase is needed', () {
      final product = Product(
        name: 'Low Stock Product',
        stockQuantity: 5,
        weeklyDemand: 5,
      );

      expect(product.needsPurchase(), true); // 1 week remaining < 2 weeks threshold
    });

    test('Product should not need purchase when stock is adequate', () {
      final product = Product(
        name: 'Good Stock Product',
        stockQuantity: 20,
        weeklyDemand: 5,
      );

      expect(product.needsPurchase(), false); // 4 weeks remaining > 2 weeks threshold
    });

    test('Product with zero demand should not predict shortage', () {
      final product = Product(
        name: 'No Demand Product',
        stockQuantity: 10,
        weeklyDemand: 0,
      );

      expect(product.predictShortage(), null);
      expect(product.needsPurchase(), false);
    });

    test('Product should convert to and from map correctly', () {
      final now = DateTime.now();
      final product = Product(
        id: 1,
        name: 'Test Product',
        stockQuantity: 10.5,
        weeklyDemand: 2.5,
        monthlyDemand: 10.0,
        createdAt: now,
      );

      final map = product.toMap();
      final productFromMap = Product.fromMap(map);

      expect(productFromMap.id, product.id);
      expect(productFromMap.name, product.name);
      expect(productFromMap.stockQuantity, product.stockQuantity);
      expect(productFromMap.weeklyDemand, product.weeklyDemand);
      expect(productFromMap.monthlyDemand, product.monthlyDemand);
    });
  });
}
