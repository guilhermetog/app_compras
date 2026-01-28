import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _dbService = DatabaseService.instance;
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _dbService.getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum produto cadastrado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Adicione seu primeiro produto'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: product.needsPurchase()
                                  ? const Color(0xFFf8d7da)
                                  : const Color(0xFFd4edda),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              color: product.needsPurchase()
                                  ? const Color(0xFF721c24)
                                  : const Color(0xFF155724),
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Estoque: ${product.stockQuantity.toStringAsFixed(1)}'),
                              Text('Demanda Semanal: ${product.weeklyDemand.toStringAsFixed(1)}'),
                              Text('Demanda Mensal: ${product.monthlyDemand.toStringAsFixed(1)}'),
                              if (product.predictShortage() != null)
                                Text(
                                  'Semanas restantes: ${product.predictShortage()!.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    color: product.needsPurchase()
                                        ? Colors.red[700]
                                        : Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          trailing: _buildStatusBadge(product),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(productId: product.id!),
                              ),
                            );
                            _loadProducts();
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusBadge(Product product) {
    final needsPurchase = product.needsPurchase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: needsPurchase ? const Color(0xFFf8d7da) : const Color(0xFFd4edda),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        needsPurchase ? 'Comprar' : 'OK',
        style: TextStyle(
          color: needsPurchase ? const Color(0xFF721c24) : const Color(0xFF155724),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
