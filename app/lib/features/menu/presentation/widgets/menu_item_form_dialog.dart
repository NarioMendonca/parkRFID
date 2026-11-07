import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/menu_item_model.dart';


class MenuItemFormResult {
  const MenuItemFormResult.salvar({
    required this.name,
    required this.category,
    required this.price,
    required this.isAvailable,
  }) : excluir = false;

  const MenuItemFormResult.excluir()
      : excluir = true,
        name = '',
        category = '',
        price = '',
        isAvailable = false;


  final bool excluir;
  final String name;
  final String category;


  final String price;
  final bool isAvailable;
}


Future<MenuItemFormResult?> showMenuItemFormDialog(BuildContext context, {MenuItemModel? item}) {
  return showGeneralDialog<MenuItemFormResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => _MenuItemFormDialog(item: item),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class _MenuItemFormDialog extends StatefulWidget {
  const _MenuItemFormDialog({this.item});

  final MenuItemModel? item;

  @override
  State<_MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends State<_MenuItemFormDialog> {
  late final _nameController = TextEditingController(text: widget.item?.name ?? '');
  late final _categoryController = TextEditingController(text: widget.item?.category ?? '');
  late final _priceController = TextEditingController(text: widget.item?.price ?? '');
  late bool _isAvailable = widget.item?.isAvailable ?? true;

  bool _hasErrorName = false;
  bool _hasErrorCategory = false;
  bool _hasErrorPrice = false;

  bool get _isEditing => widget.item != null;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _salvar() {
    HapticFeedback.lightImpact();
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final price = _priceController.text.trim().replaceAll(',', '.');

    setState(() {
      _hasErrorName = name.isEmpty;
      _hasErrorCategory = category.isEmpty;
      _hasErrorPrice = price.isEmpty || double.tryParse(price) == null;
    });
    if (_hasErrorName || _hasErrorCategory || _hasErrorPrice) return;

    Navigator.pop(
      context,
      MenuItemFormResult.salvar(
        name: name,
        category: category,
        price: price,
        isAvailable: _isAvailable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 10 : 0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge(
                      icon: _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                      size: 50,
                      solid: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Editar Item' : 'Novo Item do Cardápio',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEditing ? 'Atualize os dados do item.' : 'Preencha os dados do novo item.',
                            style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionLabel('Nome do item'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ex: Refrigerante Lata',
                    errorText: _hasErrorName ? 'Campo obrigatório' : null,
                  ),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Categoria'),
                const SizedBox(height: 8),
                TextField(
                  controller: _categoryController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Ex: Bebidas, Comidas',
                    errorText: _hasErrorCategory ? 'Campo obrigatório' : null,
                  ),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Preço'),
                const SizedBox(height: 8),
                TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0,00',
                    prefixText: 'R\$ ',
                    errorText: _hasErrorPrice ? 'Informe um preço válido' : null,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.inputBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Disponível para venda',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    subtitle: Text(
                      _isAvailable ? 'Aparece na seleção de produtos' : 'Não aparece na seleção de produtos',
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                    ),
                    value: _isAvailable,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      setState(() => _isAvailable = val);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Cancelar',
                        outlined: true,
                        tone: AppTone.neutral,
                        height: 52,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: AppButton(
                        label: _isEditing ? 'Salvar' : 'Criar',
                        icon: Icons.check_rounded,
                        tone: AppTone.primary,
                        height: 52,
                        onPressed: _salvar,
                      ),
                    ),
                  ],
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context, const MenuItemFormResult.excluir());
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text('Excluir item'),
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
}
