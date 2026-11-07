import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/repositories/menu_repository.dart';
import '../controllers/cardapio_controller.dart';
import '../widgets/category_chip.dart';
import '../widgets/menu_dialogs.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/menu_item_form_dialog.dart';


class TelaMenu extends StatelessWidget {
  const TelaMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CardapioController(MenuRepository(ApiClient.dio))..load(),
      child: const _TelaMenuContent(),
    );
  }
}

class _TelaMenuContent extends StatelessWidget {
  const _TelaMenuContent();


  Future<void> _abrirFormulario(BuildContext context, {MenuItemModel? item}) async {
    final controller = context.read<CardapioController>();
    final resultado = await showMenuItemFormDialog(context, item: item);
    if (resultado == null || !context.mounted) return;

    if (resultado.excluir) {
      if (item == null) return;
      final confirmou = await confirmarExclusaoItem(context);
      if (!confirmou || !context.mounted) return;
      final erroExclusao = await controller.delete(item.id);
      if (context.mounted) _avisarSeErro(context, erroExclusao);
      return;
    }

    final erro = await controller.save(
      id: item?.id,
      name: resultado.name,
      category: resultado.category,
      price: resultado.price,
      isAvailable: resultado.isAvailable,
    );
    if (context.mounted) _avisarSeErro(context, erro);
  }

  Future<void> _alternarDisponibilidade(BuildContext context, MenuItemModel item, bool value) async {
    final erro = await context.read<CardapioController>().toggleAvailability(item, value);
    if (context.mounted) _avisarSeErro(context, erro);
  }

  void _avisarSeErro(BuildContext context, String? erro) {
    if (erro != null && context.mounted) mostrarAvisoCardapio(context, erro);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CardapioController>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WaveBand(
              subtitle: 'Itens disponíveis para os garçons.',
              child: SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: CardapioController.categorias.length,
                  itemBuilder: (context, index) {
                    final cat = CardapioController.categorias[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: cat,
                        icon: iconForMenuCategory(cat),
                        selected: c.selectedCategory == cat,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          c.selectCategory(cat);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(child: _buildConteudo(context, c)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _abrirFormulario(context);
        },
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.onAccent,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Novo item',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildConteudo(BuildContext context, CardapioController c) {
    if (c.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Carregando cardápio...',
              style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (c.isApiOffline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: StatePanel(
            icon: Icons.wifi_off_rounded,
            tone: AppTone.warning,
            title: 'Conexão com a API desativada',
            message: 'Verifique a conexão e tente novamente.',
            action: SizedBox(
              width: 240,
              child: AppButton(
                label: 'Tentar novamente',
                icon: Icons.refresh_rounded,
                tone: AppTone.primary,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  c.load();
                },
              ),
            ),
          ),
        ),
      );
    }

    if (c.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: StatePanel(
            icon: Icons.restaurant_menu_rounded,
            tone: AppTone.neutral,
            title: 'Nenhum item encontrado.',
            message: 'Use o botão "Novo item" para cadastrar o primeiro.',
          ),
        ),
      );
    }

    final items = c.items;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MenuItemCard(
          item: item,
          onTap: () => _abrirFormulario(context, item: item),
          onAvailabilityChanged: (value) => _alternarDisponibilidade(context, item, value),
        );
      },
    );
  }
}
