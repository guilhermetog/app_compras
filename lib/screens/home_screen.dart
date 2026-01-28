import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import 'create_shopping_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbService = DatabaseService.instance;
  List<Product> _products = [];
  int _lowStockCount = 0;
  double _totalStock = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _dbService.getAllProducts();
      final lowStock = products.where((p) => p.needsPurchase()).length;
      final totalStock = products.fold<double>(0, (sum, p) => sum + p.stockQuantity);

      setState(() {
        _products = products;
        _lowStockCount = lowStock;
        _totalStock = totalStock;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shopping_cart, size: 28),
            SizedBox(width: 8),
            Text('App Compras'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total de Produtos',
                              _products.length.toString(),
                              const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Produtos em Falta',
                              _lowStockCount.toString(),
                              const LinearGradient(
                                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        'Estoque Total',
                        _totalStock.toStringAsFixed(0),
                        const LinearGradient(
                          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Welcome Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bem-vindo ao App de Gestão de Compras',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2c3e50),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Este aplicativo ajuda você a gerenciar seus produtos e planejar suas compras mensais.',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Principais Funcionalidades:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFeatureItem('Gerenciamento de Produtos'),
                              _buildFeatureItem('Controle de Estoque'),
                              _buildFeatureItem('Listas de Compras'),
                              _buildFeatureItem('Orçamento Mensal'),
                              _buildFeatureItem('Alertas'),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const AddProductScreen(),
                                        ),
                                      );
                                      _loadData();
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Adicionar Produto'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF27ae60),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CreateShoppingListScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.note_add),
                                    label: const Text('Nova Lista'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Recent Products
                      if (_products.isNotEmpty) ...[
                        const Text(
                          'Produtos Recentes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _products.length > 5 ? 5 : _products.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return ListTile(
                                title: Text(product.name),
                                subtitle: Text(
                                  'Estoque: ${product.stockQuantity.toStringAsFixed(1)} | '
                                  'Demanda Semanal: ${product.weeklyDemand.toStringAsFixed(1)}',
                                ),
                                trailing: _buildStatusBadge(product),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(productId: product.id!),
                                    ),
                                  );
                                  _loadData();
                                },
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Comece Agora!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Você ainda não tem produtos cadastrados. Adicione seu primeiro produto para começar a gerenciar suas compras.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddProductScreen(),
                                      ),
                                    );
                                    _loadData();
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Adicionar Primeiro Produto'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF27ae60),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Gradient gradient) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF27ae60), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
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
