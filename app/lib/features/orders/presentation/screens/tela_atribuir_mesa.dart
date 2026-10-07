import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/pedido_provider.dart';
import 'tela_revisar_pedido.dart';

class TelaAtribuirMesa extends StatefulWidget {
  const TelaAtribuirMesa({super.key});

  @override
  State<TelaAtribuirMesa> createState() => _TelaAtribuirMesaState();
}

class _TelaAtribuirMesaState extends State<TelaAtribuirMesa> {
  String _numeroMesa = '';

  void _digitar(String valor) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_numeroMesa.length < 3) {
        _numeroMesa += valor;
      }
    });
  }

  void _apagar() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_numeroMesa.isNotEmpty) {
        _numeroMesa = _numeroMesa.substring(0, _numeroMesa.length - 1);
      }
    });
  }

  void _limpar() {
    HapticFeedback.lightImpact();
    setState(() {
      _numeroMesa = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pedidoProvider = Provider.of<PedidoProvider>(context);

    // Cálculo do total de itens no carrinho
    final totalItens = pedidoProvider.itensCarrinho.fold<int>(
      0,
          (sum, item) => sum + (item['amount'] as int? ?? 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              _buildHeader(pedidoProvider, totalItens),
              const SizedBox(height: 28),

              const Text(
                'DIGITE O NÚMERO DA MESA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Display da Mesa Selecionada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: Text(
                  _numeroMesa.isEmpty ? '--' : _numeroMesa,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -1,
                  ),
                ),
              ),

              const Spacer(),

              // Teclado Numérico
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                childAspectRatio: 1.45,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 1; i <= 9; i++) _buildBotaoTeclado(i.toString()),
                  _buildBotaoAcao('C', _limpar),
                  _buildBotaoTeclado('0'),
                  _buildBotaoBackspace(),
                ],
              ),

              const SizedBox(height: 24),

              // Botão de Ação Inferior
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _numeroMesa.isEmpty
                      ? null
                      : () {
                    HapticFeedback.lightImpact();
                    pedidoProvider.setMesa(_numeroMesa);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TelaRevisarPedido(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3880C4),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Associar mesa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PedidoProvider pedidoProvider, int totalItens) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEDF2F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFF1E293B),
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Associar mesa',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Pulseira ${pedidoProvider.braceletId ?? "MP-0472"} · $totalItens item${totalItens != 1 ? 'ns' : ''}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotaoTeclado(String texto) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _digitar(texto),
          child: Center(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoAcao(String texto, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoBackspace() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _apagar,
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 22,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}