import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/api/api_client.dart';

class TelaMenuDesktop extends StatefulWidget {
  const TelaMenuDesktop({super.key});

  @override
  State<TelaMenuDesktop> createState() => _TelaMenuDesktopState();
}

class _TelaMenuDesktopState extends State<TelaMenuDesktop> {
  final Dio _dio = ApiClient.dio;

  List<dynamic> _menuItems = [];
  bool _isLoading = true;
  bool _isApiOffline = false;
  String _selectedCategory = 'Todas';

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    setState(() {
      _isLoading = true;
      _isApiOffline = false;
    });
    try {
      String path = '/menu';
      if (_selectedCategory != 'Todas') {
        path += '?category=$_selectedCategory';
      }

      final response = await _dio.get(path);
      if (response.data is List) {
        setState(() {
          _menuItems = response.data;
          _isLoading = false;
          _isApiOffline = false;
        });
      }
    } on DioException catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isApiOffline = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isApiOffline = true;
        });
      }
    }
  }

  Future<void> _showItemFormDialog({Map<String, dynamic>? itemToEdit}) async {
    final isEditing = itemToEdit != null;
    final nameController = TextEditingController(text: itemToEdit?['name'] ?? '');
    final categoryController = TextEditingController(text: itemToEdit?['category'] ?? '');
    final priceController = TextEditingController(text: itemToEdit?['price']?.toString() ?? '');
    bool isAvaliable = itemToEdit?['isAvaliable'] ?? true;

    bool hasErrorName = false;
    bool hasErrorCategory = false;
    bool hasErrorPrice = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;

                return AlertDialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  titlePadding: const EdgeInsets.fromLTRB(36, 36, 36, 12),
                  contentPadding: const EdgeInsets.fromLTRB(36, 12, 36, 24),
                  actionsPadding: const EdgeInsets.fromLTRB(36, 0, 36, 36),
                  title: Text(
                    isEditing ? 'Editar Item' : 'Novo Item do Cardápio',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                  ),
                  content: SizedBox(
                    width: 680,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: nameController,
                            autofocus: true,
                            style: const TextStyle(fontSize: 18),
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Nome do Item',
                              labelStyle: const TextStyle(fontSize: 16),
                              hintText: 'Ex: Refrigerante Lata',
                              errorText: hasErrorName ? 'Campo obrigatório' : null,
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: categoryController,
                            style: const TextStyle(fontSize: 18),
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Categoria',
                              labelStyle: const TextStyle(fontSize: 16),
                              hintText: 'Ex: Bebidas, Comidas',
                              errorText: hasErrorCategory ? 'Campo obrigatório' : null,
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: priceController,
                            style: const TextStyle(fontSize: 18),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Preço (R\$)',
                              labelStyle: const TextStyle(fontSize: 16),
                              hintText: '0,00',
                              errorText: hasErrorPrice ? 'Informe um preço válido' : null,
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SwitchListTile(
                              title: const Text('Disponível para venda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                              value: isAvaliable,
                              activeColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              onChanged: (val) {
                                HapticFeedback.lightImpact();
                                setDialogState(() => isAvaliable = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        isEditing
                            ? TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            _confirmDelete(itemToEdit['id']);
                          },
                          child: const Text('Excluir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                        )
                            : const SizedBox.shrink(),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              child: Text('Cancelar', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final name = nameController.text.trim();
                                final category = categoryController.text.trim();
                                final priceText = priceController.text.trim().replaceAll(',', '.');

                                setDialogState(() {
                                  hasErrorName = name.isEmpty;
                                  hasErrorCategory = category.isEmpty;
                                  hasErrorPrice = priceText.isEmpty || (double.tryParse(priceText) == null);
                                });

                                if (hasErrorName || hasErrorCategory || hasErrorPrice) {
                                  return;
                                }

                                Navigator.pop(context);
                                await _submitItemData(
                                  id: itemToEdit?['id'],
                                  name: name,
                                  category: category,
                                  price: priceText,
                                  isAvaliable: isAvaliable,
                                  isEditing: isEditing,
                                );
                              },
                              child: Text(isEditing ? 'Salvar' : 'Criar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Item', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        content: const Text('Tem certeza de que deseja remover este item do cardápio?', style: TextStyle(fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              _deleteItem(id);
            },
            child: const Text('Excluir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitItemData({
    String? id,
    required String name,
    required String category,
    required String price,
    required bool isAvaliable,
    required bool isEditing,
  }) async {
    setState(() => _isLoading = true);
    try {
      final body = {
        'name': name,
        'category': category,
        'price': price,
        'isAvaliable': isAvaliable,
      };

      if (isEditing) {
        body['id'] = id!;
        await _dio.patch('/menu/$id', data: body);
      } else {
        await _dio.post('/menu', data: body);
      }

      await _fetchMenu();
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.response?.data?['message'] ?? 'Erro ao conectar com a API ao salvar item.');
    }
  }

  Future<void> _toggleAvailability(Map<String, dynamic> item, bool newValue) async {
    final id = item['id'];
    try {
      setState(() {
        item['isAvaliable'] = newValue;
      });

      await _dio.patch('/menu/$id', data: {
        'id': id,
        'name': item['name'],
        'category': item['category'],
        'price': item['price'],
        'isAvaliable': newValue,
      });
    } on DioException catch (e) {
      setState(() {
        item['isAvaliable'] = !newValue;
      });
      _showErrorDialog(e.response?.data?['message'] ?? 'Erro de conexão com a API.');
    }
  }

  Future<void> _deleteItem(String id) async {
    setState(() => _isLoading = true);
    try {
      await _dio.delete('/menu/$id', data: {});
      await _fetchMenu();
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.response?.data?['message'] ?? 'Erro ao deletar item.');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Atenção', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = ['Todas', 'Bebidas', 'Comidas', 'Sobremesas'];

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primaryContainer],
              ),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 42, fit: BoxFit.contain),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gerenciamento de Cardápio', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cardápio',
                              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Gerencie os itens disponíveis para os garçons e clientes.',
                              style: TextStyle(fontSize: 17, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showItemFormDialog();
                          },
                          icon: const Icon(Icons.add, size: 24),
                          label: const Text('Novo Item', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 56,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = _selectedCategory == cat;

                          return Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: ChoiceChip(
                              label: Text(cat, style: const TextStyle(fontSize: 16)),
                              selected: isSelected,
                              selectedColor: colorScheme.primary,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(color: isSelected ? Colors.transparent : colorScheme.outlineVariant),
                              ),
                              onSelected: (selected) {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedCategory = cat);
                                _fetchMenu();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _isApiOffline
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Conexão com a API desativada',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _fetchMenu();
                              },
                              icon: const Icon(Icons.refresh, size: 20),
                              label: const Text('Tentar novamente', style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                      )
                          : _menuItems.isEmpty
                          ? const Center(child: Text('Nenhum item encontrado.', style: TextStyle(fontSize: 18, color: Colors.grey)))
                          : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisExtent: 160,
                          crossAxisSpacing: 22,
                          mainAxisSpacing: 22,
                        ),
                        itemCount: _menuItems.length,
                        itemBuilder: (context, index) {
                          final item = _menuItems[index];
                          final isAvailable = item['isAvaliable'] ?? true;
                          final category = (item['category'] ?? '').toUpperCase();

                          return InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showItemFormDialog(itemToEdit: item);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: colorScheme.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Switch(
                                        value: isAvailable,
                                        activeColor: colorScheme.primary,
                                        onChanged: (val) {
                                          HapticFeedback.lightImpact();
                                          _toggleAvailability(item, val);
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                    item['name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: isAvailable ? colorScheme.onSurface : Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'R\$ ${(double.tryParse(item['price'].toString()) ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
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
            ),
          ),
        ],
      ),
    );
  }
}