import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/price_history.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService.instance;

  final _nameController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _weeklyDemandController = TextEditingController(text: '0');
  final _monthlyDemandController = TextEditingController(text: '0');
  final _priceController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _weeklyDemandController.dispose();
    _monthlyDemandController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = Product(
        name: _nameController.text.trim(),
        stockQuantity: double.parse(_stockController.text),
        weeklyDemand: double.parse(_weeklyDemandController.text),
        monthlyDemand: double.parse(_monthlyDemandController.text),
      );

      final productId = await _dbService.createProduct(product);

      // Add initial price if provided
      if (_priceController.text.isNotEmpty) {
        final price = double.parse(_priceController.text);
        await _dbService.createPriceHistory(
          PriceHistory(
            productId: productId,
            price: price,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produto "${product.name}" adicionado com sucesso!'),
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
            content: Text('Erro ao adicionar produto: $e'),
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
        title: const Text('Adicionar Produto'),
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
                        labelText: 'Nome do Produto *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome do produto é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade em Estoque',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final number = double.tryParse(value);
                        if (number == null || number < 0) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weeklyDemandController,
                      decoration: const InputDecoration(
                        labelText: 'Demanda Semanal',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        helperText: 'Quanto você consome por semana',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final number = double.tryParse(value);
                        if (number == null || number < 0) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _monthlyDemandController,
                      decoration: const InputDecoration(
                        labelText: 'Demanda Mensal',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_month),
                        helperText: 'Quanto você consome por mês',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final number = double.tryParse(value);
                        if (number == null || number < 0) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Preço Unitário (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        helperText: 'Para cálculo de orçamento',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final number = double.tryParse(value);
                        if (number == null || number < 0) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27ae60),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Salvar Produto',
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
