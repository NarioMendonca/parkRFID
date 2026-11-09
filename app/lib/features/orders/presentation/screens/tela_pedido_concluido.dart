import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/animated_success_check.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/pedido_concluido_model.dart';
import 'tela_fazer_pedido_inicio.dart';

class TelaPedidoConcluido extends StatefulWidget {
  const TelaPedidoConcluido({super.key, required this.pedido});

  final PedidoConcluidoModel pedido;

  @override
  State<TelaPedidoConcluido> createState() => _TelaPedidoConcluidoState();
}

class _TelaPedidoConcluidoState extends State<TelaPedidoConcluido> with SingleTickerProviderStateMixin {

  late final AnimationController _conteudo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  Animation<double> _intervalo(double inicio, double fim) => CurvedAnimation(
        parent: _conteudo,
        curve: Interval(inicio, fim, curve: Curves.easeOutCubic),
      );

  late final _titulo = _intervalo(0.0, 0.55);
  late final _resumo = _intervalo(0.2, 0.8);
  late final _botoes = _intervalo(0.4, 1.0);

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) _conteudo.forward();
    });
  }

  @override
  void dispose() {
    _conteudo.dispose();
    super.dispose();
  }

  void _novoPedido() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TelaFazerPedidoInicio()),
    );
  }

  void _voltarAoInicio() {
    HapticFeedback.lightImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _entrar(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  const Center(child: AnimatedSuccessCheck(size: 112)),
                  _entrar(
                    _titulo,
                    Column(
                      children: [
                        Text(
                          'Pedido lançado!',
                          textAlign: TextAlign.center,
                          style: AppTheme.display(size: 28, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Adicionado à comanda às ${formatarHora(p.criadoEm)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14.5, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _entrar(_resumo, _ResumoPedido(pedido: p)),
                ],
              ),
            ),
            _entrar(
              _botoes,
              BottomActionBar(
                primary: AppButton(
                  label: 'Novo pedido',
                  icon: Icons.add_shopping_cart_rounded,
                  onPressed: _novoPedido,
                ),
                secondary: AppButton(
                  label: 'Voltar ao início',
                  icon: Icons.home_rounded,
                  outlined: true,
                  tone: AppTone.neutral,
                  height: 50,
                  onPressed: _voltarAoInicio,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoPedido extends StatelessWidget {
  const _ResumoPedido({required this.pedido});

  final PedidoConcluidoModel pedido;

  @override
  Widget build(BuildContext context) {
    final p = pedido;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow(icon: Icons.nfc_rounded, label: 'Pulseira', value: p.braceletId),
          if (p.mesa != null && p.mesa!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            InfoRow(icon: Icons.table_restaurant_rounded, label: 'Mesa', value: p.mesa!.padLeft(2, '0')),
          ],
          const SizedBox(height: 20),
          SectionLabel(p.quantidadeItens == 1 ? '1 item' : '${p.quantidadeItens} itens'),
          const SizedBox(height: 10),
          for (final item in p.itens)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTone.primary.soft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.amount}x',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatarMoeda(item.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.accentSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text(
                  'Total do pedido',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textDark),
                ),
                const Spacer(),
                Text(formatarMoeda(p.total), style: AppTheme.display(size: 26, color: AppTheme.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
