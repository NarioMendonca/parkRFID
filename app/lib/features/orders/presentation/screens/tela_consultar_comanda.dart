import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/nfc_off_screen.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/nfc_radar_pulse.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/models/comanda_model.dart';
import '../../data/services/comanda_service.dart';
import '../controllers/consultar_comanda_controller.dart';
import '../widgets/comanda_pagamentos_card.dart';
import '../widgets/comanda_pedido_card.dart';
import '../widgets/comanda_resumo_card.dart';

class TelaConsultarComanda extends StatelessWidget {
  const TelaConsultarComanda({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConsultarComandaController(ComandaService()),
      child: const _TelaConsultarComandaContent(),
    );
  }
}

class _TelaConsultarComandaContent extends StatefulWidget {
  const _TelaConsultarComandaContent();

  @override
  State<_TelaConsultarComandaContent> createState() => _TelaConsultarComandaContentState();
}

class _TelaConsultarComandaContentState extends State<_TelaConsultarComandaContent> {
  late final ConsultarComandaController _controller = context.read<ConsultarComandaController>();
  ConsultaComandaStep _etapaAnterior = ConsultaComandaStep.leitura;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onEtapaTalvezMudou);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _iniciarLeitura();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onEtapaTalvezMudou);
    super.dispose();
  }

  void _onEtapaTalvezMudou() {
    final etapa = _controller.step;
    if (etapa == _etapaAnterior) return;
    _etapaAnterior = etapa;
    if (etapa == ConsultaComandaStep.carregando) HapticFeedback.heavyImpact();
  }

  void _iniciarLeitura() => _controller.startNfc(onError: _mostrarErro);

  void _sair() {
    _controller.stopNfc();
    Navigator.of(context).maybePop();
  }

  Future<void> _mostrarErro(String mensagem) async {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatePanel(
                icon: Icons.priority_high_rounded,
                tone: AppTone.warning,
                title: 'Não foi possível consultar',
                message: mensagem,
              ),
              const SizedBox(height: 26),
              AppButton(
                label: 'Ler outra pulseira',
                icon: Icons.nfc_rounded,
                tone: AppTone.primary,
                height: 52,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConsultarComandaController>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _controller.stopNfc();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(
          key: ValueKey(c.step),
          child: switch (c.step) {
            ConsultaComandaStep.leitura => _buildLeitura(),
            ConsultaComandaStep.carregando => _buildCarregando(c.scannedUid ?? ''),
            ConsultaComandaStep.resultado => _buildResultado(c.comanda!),
            ConsultaComandaStep.nfcDesativado => TelaNfcDesativado(
                tituloHeader: 'Consultar comanda',
                onVoltar: _sair,
                onTentarNovamente: _iniciarLeitura,
              ),
          },
        ),
      ),
    );
  }

  Widget _buildLeitura() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ScanBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              ScanTopBar(
                title: 'Consultar comanda',
                subtitle: 'Leitura RFID',
                onBack: () {
                  HapticFeedback.lightImpact();
                  _sair();
                },
              ),
              const Spacer(),
              const NfcRadarPulse(),
              const SizedBox(height: 28),
              Text(
                'APROXIME A PULSEIRA',
                style: AppTheme.display(size: 28, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Encoste a pulseira na parte de trás do aparelho para ver o consumo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ),
              const Spacer(),
              BottomActionBar(
                dark: true,
                primary: AppButton(
                  label: 'Cancelar',
                  icon: Icons.close_rounded,
                  outlined: true,
                  onDark: true,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _sair();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarregando(String uid) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Comanda',
            subtitle: 'Buscando pulseira $uid...',
            onBack: _sair,
          ),
          Expanded(
            child: SkeletonPulse(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: const [
                  SkeletonBox(height: 250, radius: AppTheme.radiusLg),
                  SizedBox(height: 28),
                  SkeletonBox(width: 140, height: 12),
                  SizedBox(height: 12),
                  SkeletonBox(height: 120, radius: AppTheme.radiusMd),
                  SizedBox(height: 12),
                  SkeletonBox(height: 90, radius: AppTheme.radiusMd),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultado(ComandaSessaoModel comanda) {
    final pedidos = comanda.pedidos;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Comanda',
            subtitle: comanda.quantidadeItens == 1
                ? '1 item consumido'
                : '${comanda.quantidadeItens} itens consumidos',
            onBack: () {
              HapticFeedback.lightImpact();
              _sair();
            },
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                ComandaResumoCard(comanda: comanda),
                const SizedBox(height: 28),
                SectionLabel('Pedidos · ${pedidos.length}'),
                const SizedBox(height: 12),
                if (pedidos.isEmpty)
                  const AppCard(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    child: StatePanel(
                      icon: Icons.shopping_bag_outlined,
                      tone: AppTone.neutral,
                      title: 'Nenhum pedido ainda',
                      message: 'Os pedidos feitos com esta pulseira aparecem aqui.',
                    ),
                  )
                else
                  for (var i = 0; i < pedidos.length; i++)
                    ComandaPedidoCard(pedido: pedidos[i], numero: i + 1),
                if (comanda.pagamentos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionLabel('Pagamentos · ${comanda.pagamentos.length}'),
                  const SizedBox(height: 12),
                  ComandaPagamentosCard(pagamentos: comanda.pagamentos),
                ],
              ],
            ),
          ),
          BottomActionBar(
            primary: AppButton(
              label: 'Consultar outra pulseira',
              icon: Icons.nfc_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                _iniciarLeitura();
              },
            ),
          ),
        ],
      ),
    );
  }
}
