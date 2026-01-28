import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/product.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _dbService = DatabaseService.instance;
  List<Map<String, dynamic>> _budgetItems = [];
  double _totalBudget = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() => _isLoading = true);
    try {
      final products = await _dbService.getAllProducts();
      final items = <Map<String, dynamic>>[];
      double total = 0;

      for (final product in products) {
        if (product.monthlyDemand > 0) {
          final quantityNeeded = product.monthlyDemand - product.stockQuantity;
          if (quantityNeeded > 0) {
            final price = await _dbService.getLatestPrice(product.id!) ?? 0.0;
            final itemTotal = quantityNeeded * price;
            total += itemTotal;

            items.add({
              'product': product,
              'quantity_needed': quantityNeeded,
              'price': price,
              'total': itemTotal,
            });
          }
        }
      }

      setState(() {
        _budgetItems = items;
        _totalBudget = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao calcular orçamento: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamento Mensal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBudget,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudget,
              child: Column(
                children: [
                  // Total Budget Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Orçamento Mensal Estimado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R\$ ${_totalBudget.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_budgetItems.length} ${_budgetItems.length == 1 ? 'produto' : 'produtos'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Budget Items List
                  Expanded(
                    child: _budgetItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 80,
                                  color: Colors.green[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma compra necessária',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('Seu estoque está em dia!'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _budgetItems.length,
                            itemBuilder: (context, index) {
                              final item = _budgetItems[index];
                              final product = item['product'] as Product;
                              final quantityNeeded = item['quantity_needed'] as double;
                              final price = item['price'] as double;
                              final itemTotal = item['total'] as double;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'R\$ ${itemTotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF667eea),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.shopping_basket, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Quantidade necessária: ${quantityNeeded.toStringAsFixed(1)}',
                                            style: TextStyle(color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Preço por unidade: R\$ ${price.toStringAsFixed(2)}',
                                            style: TextStyle(color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFfff3cd),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.info_outline, size: 14, color: Color(0xFF856404)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Demanda mensal: ${product.monthlyDemand.toStringAsFixed(1)} | '
                                              'Estoque: ${product.stockQuantity.toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF856404),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
