import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/purchase_record.dart';
import '../models/price_history.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _dbService = DatabaseService.instance;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  Product? _product;
  List<PurchaseRecord> _purchases = [];
  List<PriceHistory> _priceHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final product = await _dbService.getProduct(widget.productId);
      final purchases = await _dbService.getPurchaseRecordsByProduct(widget.productId);
      final priceHistory = await _dbService.getPriceHistoryByProduct(widget.productId);

      setState(() {
        _product = product;
        _purchases = purchases;
        _priceHistory = priceHistory;
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

  Future<void> _recordPurchase() async {
    if (_quantityController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha quantidade e preço')),
      );
      return;
    }

    try {
      final quantity = double.parse(_quantityController.text);
      final pricePerUnit = double.parse(_priceController.text);

      if (quantity <= 0 || pricePerUnit < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valores inválidos')),
        );
        return;
      }

      // Create purchase record
      await _dbService.createPurchaseRecord(
        PurchaseRecord(
          productId: widget.productId,
          quantity: quantity,
          pricePerUnit: pricePerUnit,
          totalPrice: quantity * pricePerUnit,
        ),
      );

      // Update stock
      _product!.stockQuantity += quantity;
      await _dbService.updateProduct(_product!);

      // Add to price history
      await _dbService.createPriceHistory(
        PriceHistory(
          productId: widget.productId,
          price: pricePerUnit,
        ),
      );

      _quantityController.clear();
      _priceController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compra registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar compra: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Produto')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Produto')),
        body: const Center(child: Text('Produto não encontrado')),
      );
    }

    final shortage = _product!.predictShortage();
    final needsPurchase = _product!.needsPurchase();

    return Scaffold(
      appBar: AppBar(
        title: Text(_product!.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Info Card
            Container(
              padding: const EdgeInsets.all(16),
              color: needsPurchase ? const Color(0xFFffe8e8) : const Color(0xFFe8f5e9),
              child: Column(
                children: [
                  Icon(
                    needsPurchase ? Icons.warning : Icons.check_circle,
                    size: 60,
                    color: needsPurchase ? Colors.red[700] : Colors.green[700],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn(
                        'Estoque',
                        _product!.stockQuantity.toStringAsFixed(1),
                        Icons.inventory,
                      ),
                      _buildInfoColumn(
                        'Demanda Semanal',
                        _product!.weeklyDemand.toStringAsFixed(1),
                        Icons.calendar_today,
                      ),
                      _buildInfoColumn(
                        'Demanda Mensal',
                        _product!.monthlyDemand.toStringAsFixed(1),
                        Icons.calendar_month,
                      ),
                    ],
                  ),
                  if (shortage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Semanas restantes: ${shortage.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: needsPurchase ? Colors.red[700] : Colors.green[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Register Purchase Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Registrar Compra',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_basket),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Preço por Unidade',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _recordPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27ae60),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Registrar Compra'),
                    ),
                  ],
                ),
              ),
            ),

            // Purchase History
            if (_purchases.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Histórico de Compras',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _purchases.length,
                itemBuilder: (context, index) {
                  final purchase = _purchases[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.shopping_bag, color: Color(0xFF27ae60)),
                      title: Text('Qtd: ${purchase.quantity.toStringAsFixed(1)}'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(purchase.purchasedAt),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'R\$ ${purchase.pricePerUnit.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Total: R\$ ${purchase.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2c3e50)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
