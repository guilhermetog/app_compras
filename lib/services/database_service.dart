import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/price_history.dart';
import '../models/shopping_list.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_compras.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        stock_quantity REAL DEFAULT 0.0,
        weekly_demand REAL DEFAULT 0.0,
        monthly_demand REAL DEFAULT 0.0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        price_per_unit REAL NOT NULL,
        total_price REAL NOT NULL,
        purchased_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE price_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        price REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_list_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopping_list_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');
  }

  // Product operations
  Future<int> createProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Purchase Record operations
  Future<int> createPurchaseRecord(PurchaseRecord record) async {
    final db = await database;
    return await db.insert('purchase_records', record.toMap());
  }

  Future<List<PurchaseRecord>> getPurchaseRecordsByProduct(int productId) async {
    final db = await database;
    final result = await db.query(
      'purchase_records',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'purchased_at DESC',
    );
    return result.map((map) => PurchaseRecord.fromMap(map)).toList();
  }

  // Price History operations
  Future<int> createPriceHistory(PriceHistory priceHistory) async {
    final db = await database;
    return await db.insert('price_history', priceHistory.toMap());
  }

  Future<List<PriceHistory>> getPriceHistoryByProduct(int productId) async {
    final db = await database;
    final result = await db.query(
      'price_history',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'recorded_at DESC',
    );
    return result.map((map) => PriceHistory.fromMap(map)).toList();
  }

  Future<double?> getLatestPrice(int productId) async {
    final history = await getPriceHistoryByProduct(productId);
    if (history.isEmpty) return null;
    return history.first.price;
  }

  // Shopping List operations
  Future<int> createShoppingList(ShoppingList shoppingList) async {
    final db = await database;
    return await db.insert('shopping_lists', shoppingList.toMap());
  }

  Future<List<ShoppingList>> getAllShoppingLists() async {
    final db = await database;
    final result = await db.query('shopping_lists', orderBy: 'created_at DESC');
    return result.map((map) => ShoppingList.fromMap(map)).toList();
  }

  Future<ShoppingList?> getShoppingList(int id) async {
    final db = await database;
    final result = await db.query(
      'shopping_lists',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return ShoppingList.fromMap(result.first);
  }

  Future<int> updateShoppingList(ShoppingList shoppingList) async {
    final db = await database;
    return await db.update(
      'shopping_lists',
      shoppingList.toMap(),
      where: 'id = ?',
      whereArgs: [shoppingList.id],
    );
  }

  // Shopping List Item operations
  Future<int> createShoppingListItem(ShoppingListItem item) async {
    final db = await database;
    return await db.insert('shopping_list_items', item.toMap());
  }

  Future<List<ShoppingListItem>> getShoppingListItems(int shoppingListId) async {
    final db = await database;
    final result = await db.query(
      'shopping_list_items',
      where: 'shopping_list_id = ?',
      whereArgs: [shoppingListId],
    );
    return result.map((map) => ShoppingListItem.fromMap(map)).toList();
  }

  Future<int> deleteShoppingListItem(int id) async {
    final db = await database;
    return await db.delete(
      'shopping_list_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
