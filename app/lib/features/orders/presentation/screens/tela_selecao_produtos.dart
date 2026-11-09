import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../menu/presentation/controllers/cardapio_controller.dart';
import '../../../menu/presentation/widgets/category_chip.dart';
import '../../../menu/presentation/widgets/menu_search_field.dart';
import '../controllers/pedido_provider.dart';
import '../../../../core/config/feature_flags.dart';
import 'tela_atribuir_mesa.dart';
import 'tela_revisar_pedido.dart';

class TelaSelecaoProdutos extends StatefulWidget {
  const TelaSelecaoProdutos({super.key});

  @override
  State<TelaSelecaoProdutos> createState() => _TelaSelecaoProdutosState();
}

class _TelaSelecaoProdutosState extends State<TelaSelecaoProdutos> {
  bool _carregando = true;
  List<dynamic> _produtosMenu = [];
  String? _erro;

  static const List<String> _categorias = CardapioController.categorias;
  String _categoriaSelecionada = CardapioController.todas;
  String _busca = '';


  List<dynamic> get _produtosFiltrados {
    final categoria = normalizarBusca(_categoriaSelecionada);
    return _produtosMenu.where((produto) {
      final daCategoria = _categoriaSelecionada == CardapioController.todas ||
          normalizarBusca('${produto['category'] ?? ''}') == categoria;
      final batComBusca = _busca.isEmpty ||
          normalizarBusca('${produto['name'] ?? ''}').contains(_busca);
      return daCategoria && batComBusca;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _carregarCardapioDaApi();
  }

  Future<void> _carregarCardapioDaApi() async {
    try {
      final response = await ApiClient.dio.get('/menu/');

      if (response.statusCode == 200) {
        setState(() {
          _produtosMenu = (response.data as List)
              .where((item) => item['isAvaliable'] == true)
              .toList();
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar cardápio: $e';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidoProvider = Provider.of<PedidoProvider>(context);

    final totalItens = pedidoProvider.itensCarrinho.fold<int>(
      0, (sum, item) => sum + (item['amount'] as int? ?? 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(pedidoProvider),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: MenuSearchField(
                onChanged: (texto) => setState(() => _busca = normalizarBusca(texto)),
              ),
            ),
            _buildCategorias(),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _erro != null
                  ? Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)))
                  : _buildListaProdutos(pedidoProvider),
            ),
            if (pedidoProvider.itensCarrinho.isNotEmpty)
              _buildBottomBar(context, pedidoProvider, totalItens),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PedidoProvider pedidoProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFEDF2F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF1E293B),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Novo pedido',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Pulseira ${pedidoProvider.braceletId ?? "N/A"} • comanda #2314',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorias() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final isSelected = _categorias[index] == _categoriaSelecionada;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _categoriaSelecionada = _categorias[index]);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconForMenuCategory(_categorias[index]),
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _categorias[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListaProdutos(PedidoProvider pedidoProvider) {
    final produtos = _produtosFiltrados;
    if (produtos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                _busca.isNotEmpty
                    ? 'Nenhum item com esse nome nesta categoria.'
                    : 'Nenhum item disponível nesta categoria.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: produtos.length,
      itemBuilder: (context, index) {
        final produto = produtos[index];
        final double preco = double.tryParse(produto['price'].toString()) ?? 0.0;
        final String nome = produto['name'];
        final String primeiraLetra = nome.isNotEmpty ? nome[0].toUpperCase() : '-';

        final itemMap = {
          'id': produto['id'],
          'name': nome,
          'price': preco,
        };

        final itemNoCarrinho = pedidoProvider.itensCarrinho.firstWhere(
              (item) => item['id'] == produto['id'],
          orElse: () => {},
        );
        final int qtd = itemNoCarrinho['amount'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  primeiraLetra,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildControlesQuantidade(qtd, itemMap, pedidoProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlesQuantidade(int qtd, Map<String, dynamic> itemMap, PedidoProvider pedidoProvider) {
    if (qtd == 0) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          pedidoProvider.adicionarItem(itemMap);
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        ),
      );
    }

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              pedidoProvider.removerItem(itemMap['id']);
            },
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.remove_rounded, color: Color(0xFF94A3B8), size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$qtd',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              pedidoProvider.adicionarItem(itemMap);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, PedidoProvider pedidoProvider, int totalItens) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pedido da vez • $totalItens item${totalItens > 1 ? 'ns' : ''}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'R\$ ${pedidoProvider.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeatureFlags.mesaEImpressao
                      ? const TelaAtribuirMesa()
                      : const TelaRevisarPedido(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.onAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}