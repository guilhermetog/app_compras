import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/shopping_list.dart';
import '../models/product.dart';

class CreateShoppingListScreen extends StatefulWidget {
  const CreateShoppingListScreen({super.key});

  @override
  State<CreateShoppingListScreen> createState() => _CreateShoppingListScreenState();
}

class _CreateShoppingListScreenState extends State<CreateShoppingListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService.instance;
  final _nameController = TextEditingController();
  bool _autoAdd = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final shoppingList = ShoppingList(name: _nameController.text.trim());
      final listId = await _dbService.createShoppingList(shoppingList);

      if (_autoAdd) {
        final products = await _dbService.getAllProducts();
        const weeksToStock = 4;

        for (final product in products) {
          if (product.needsPurchase()) {
            final shortage = product.predictShortage();
            if (shortage != null) {
              final quantityNeeded = (weeksToStock * product.weeklyDemand) - product.stockQuantity;
              if (quantityNeeded > 0) {
                await _dbService.createShoppingListItem(
                  ShoppingListItem(
                    shoppingListId: listId,
                    productId: product.id!,
                    quantity: quantityNeeded,
                  ),
                );
              }
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lista "${shoppingList.name}" criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar lista: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Lista de Compras'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Lista *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                        helperText: 'Ex: Compras de Janeiro',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome da lista é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: CheckboxListTile(
                        title: const Text('Adicionar produtos em falta automaticamente'),
                        subtitle: const Text(
                          'Produtos com estoque baixo serão adicionados à lista',
                        ),
                        value: _autoAdd,
                        onChanged: (value) {
                          setState(() => _autoAdd = value ?? true);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _createList,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27ae60),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Criar Lista',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
