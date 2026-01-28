import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/shopping_list.dart';
import '../models/product.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final int listId;

  const ShoppingListDetailScreen({super.key, required this.listId});

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  final _dbService = DatabaseService.instance;

  ShoppingList? _shoppingList;
  List<Map<String, dynamic>> _items = [];
  List<Product> _availableProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _dbService.getShoppingList(widget.listId);
      final items = await _dbService.getShoppingListItems(widget.listId);

      final itemsWithProducts = <Map<String, dynamic>>[];
      for (final item in items) {
        final product = await _dbService.getProduct(item.productId);
        if (product != null) {
          final price = await _dbService.getLatestPrice(product.id!) ?? 0.0;
          itemsWithProducts.add({
            'item': item,
            'product': product,
            'price': price,
          });
        }
      }

      final existingProductIds = items.map((i) => i.productId).toList();
      final allProducts = await _dbService.getAllProducts();
      final available = allProducts.where((p) => !existingProductIds.contains(p.id)).toList();

      setState(() {
        _shoppingList = list;
        _items = itemsWithProducts;
        _availableProducts = available;
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

  Future<void> _completeList() async {
    try {
      // Update stock for each item
      for (final itemData in _items) {
        final item = itemData['item'] as ShoppingListItem;
        final product = itemData['product'] as Product;
        product.stockQuantity += item.quantity;
        await _dbService.updateProduct(product);
      }

      // Mark list as completed
      _shoppingList!.isCompleted = true;
      await _dbService.updateShoppingList(_shoppingList!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lista concluída e estoque atualizado!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao concluir lista: $e')),
        );
      }
    }
  }

  Future<void> _addProduct(Product product) async {
    final quantityController = TextEditingController(text: '1');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar ${product.name}'),
        content: TextField(
          controller: quantityController,
          decoration: const InputDecoration(
            labelText: 'Quantidade',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final quantity = double.parse(quantityController.text);
        if (quantity > 0) {
          await _dbService.createShoppingListItem(
            ShoppingListItem(
              shoppingListId: widget.listId,
              productId: product.id!,
              quantity: quantity,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quantidade inválida')),
          );
        }
      }
    }
  }

  Future<void> _removeItem(ShoppingListItem item) async {
    try {
      await _dbService.deleteShoppingListItem(item.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removido')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover item: $e')),
        );
      }
    }
  }

  double _calculateTotal() {
    return _items.fold<double>(0, (sum, data) {
      final item = data['item'] as ShoppingListItem;
      final price = data['price'] as double;
      return sum + (item.quantity * price);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes da Lista')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_shoppingList == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes da Lista')),
        body: const Center(child: Text('Lista não encontrada')),
      );
    }

    final total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text(_shoppingList!.name),
      ),
      body: Column(
        children: [
          // Total Card
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF667eea).withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Estimado:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'R\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Nenhum item na lista'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final itemData = _items[index];
                      final item = itemData['item'] as ShoppingListItem;
                      final product = itemData['product'] as Product;
                      final price = itemData['price'] as double;
                      final itemTotal = item.quantity * price;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.shopping_basket, color: Color(0xFF667eea)),
                          title: Text(product.name),
                          subtitle: Text('Quantidade: ${item.quantity.toStringAsFixed(1)}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'R\$ ${itemTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '@ R\$ ${price.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          onLongPress: () {
                            if (!_shoppingList!.isCompleted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remover item?'),
                                  content: Text('Deseja remover ${product.name} da lista?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _removeItem(item);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Remover'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Action Buttons
          if (!_shoppingList!.isCompleted)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_availableProducts.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _availableProducts.length,
                            itemBuilder: (context, index) {
                              final product = _availableProducts[index];
                              return ListTile(
                                title: Text(product.name),
                                trailing: const Icon(Icons.add),
                                onTap: () {
                                  Navigator.pop(context);
                                  _addProduct(product);
                                },
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Produto'),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _items.isEmpty ? null : _completeList,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27ae60),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Concluir Lista e Atualizar Estoque',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
