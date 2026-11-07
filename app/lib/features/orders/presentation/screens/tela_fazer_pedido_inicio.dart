import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:provider/provider.dart';
import 'package:rfidparque/features/orders/presentation/screens/tela_consultar_comanda.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/utils/nfc_off_screen.dart';
import '../../../../core/widgets/nfc_radar_pulse.dart';
import '../controllers/pedido_provider.dart';
import 'tela_selecao_produtos.dart';

class TelaFazerPedidoInicio extends StatefulWidget {
  const TelaFazerPedidoInicio({super.key});

  @override
  State<TelaFazerPedidoInicio> createState() => _TelaFazerPedidoInicioState();
}

class _TelaFazerPedidoInicioState extends State<TelaFazerPedidoInicio> {

  int _step = 0;
  String? _scannedUid;
  bool _isNfcActive = false;

  @override
  void dispose() {
    _stopNfcSession(updateState: false);
    super.dispose();
  }

  Future<void> _startNfcSession() async {
    final bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      if (mounted) {
        setState(() {
          _isNfcActive = false;
          _step = 3;
        });
      }
      return;
    }

    setState(() {
      _step = 1;
      _isNfcActive = true;
    });

    try {
      NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          final tagId = _extractTagId(tag);
          if (!mounted) return;

          if (tagId != null && tagId.isNotEmpty) {
            _handleTagDiscovered(tagId);
          } else {
            _showErrorDialog('Não foi possível extrair o ID desta tag NFC.');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNfcActive = false;
          _step = 3;
        });
      }
    }
  }

  void _stopNfcSession({bool updateState = true}) {
    try {
      NfcManager.instance.stopSession();
    } catch (_) {}

    if (updateState && mounted) {
      setState(() => _isNfcActive = false);
    }
  }

  void _handleTagDiscovered(String tagId) {
    final cleanId = tagId.trim().toUpperCase();
    if (cleanId.isEmpty) return;

    HapticFeedback.heavyImpact();
    _stopNfcSession();

    if (!mounted) return;


    final pedido = context.read<PedidoProvider>();
    pedido.limparTudo();
    pedido.setBraceletId(cleanId);

    setState(() {
      _scannedUid = cleanId;
      _step = 2;
    });
  }

  String? _extractTagId(NfcTag tag) {
    try {
      final rawData = tag.data;
      if (rawData is Map) return _extractFromMap(rawData);
      try {
        final dynamic dynamicData = tag.data;
        if (dynamicData.id != null) return _bytesToHex(List<int>.from(dynamicData.id));
        if (dynamicData.identifier != null) return _bytesToHex(List<int>.from(dynamicData.identifier));
      } catch (_) {}
    } catch (_) {}
    return null;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }

  String? _extractFromMap(Map data) {
    for (final tech in ['nfca', 'mifareclassic', 'mifareultralight', 'mifare', 'isodep', 'ndef', 'nfcb', 'nfcf', 'nfcv']) {
      if (data.containsKey(tech) && data[tech] is Map) {
        final techMap = data[tech] as Map;
        if (techMap.containsKey('identifier') && techMap['identifier'] is List) {
          return _bytesToHex(List<int>.from(techMap['identifier']));
        }
      }
    }
    return null;
  }

  void _voltarParaMenu() {
    _stopNfcSession();
    if (!mounted) return;
    setState(() {
      _step = 0;
      _scannedUid = null;
    });
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Atenção', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF4F7FA),
      body: PopScope(
        canPop: _step == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _step > 0) {
            _voltarParaMenu();
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildTelaLeitura();
      case 2:
        return _buildTelaResultado();
      case 3:

        return TelaNfcDesativado(
          key: const ValueKey('nfc_desativado'),
          onVoltar: _voltarParaMenu,
          onTentarNovamente: _startNfcSession,
        );
      case 0:
      default:
        return _buildTelaInicial();
    }
  }

  Widget _buildTelaInicial() {
    return Container(
      key: const ValueKey('menu_inicial'),
      color: AppTheme.background,
      child: Column(
        children: [
          AppHeader(
            titleSize: 19,
            title: 'Comanda e pedidos',
            subtitle: 'Escolha como deseja continuar',
            onBack: Navigator.of(context).canPop()
                ? () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  }
                : null,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ScrollFill(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ActionCard(
                        title: 'Fazer pedido',
                        subtitle: 'Ler a pulseira e lançar os itens na comanda.',
                        icon: Icons.add_shopping_cart_rounded,
                        tone: AppTone.primary,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _startNfcSession();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ActionCard(
                        title: 'Consultar comanda',
                        subtitle: 'Ver o consumo registrado na pulseira.',
                        icon: Icons.receipt_long_rounded,
                        tone: AppTone.accent,
                        filled: false,
                        onTap: () {
                          HapticFeedback.lightImpact();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TelaConsultarComanda(),
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

  Widget _buildTelaLeitura() {
    return ScanBackdrop(
      key: const ValueKey('leitura'),
      child: SafeArea(
        child: Column(
          children: [
            ScanTopBar(
              title: 'Leitura da pulseira',
              subtitle: 'Novo pedido',
              onBack: () {
          HapticFeedback.lightImpact();
          _voltarParaMenu();
        },
            ),
            const Spacer(),
            const NfcRadarPulse(),
            const SizedBox(height: 28),
            Text(
              'APROXIME A PULSEIRA',
              style: AppTheme.display(size: 22, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Aproxime a tag física da parte de trás do aparelho',
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
          _voltarParaMenu();
        },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelaResultado() {
    return Container(
      key: const ValueKey('resultado'),
      color: AppTheme.background,
      child: Column(
        children: [
          AppHeader(
            titleSize: 19,
            title: 'Leitura da pulseira',
            subtitle: 'Novo pedido',
            onBack: () {
          HapticFeedback.lightImpact();
          _voltarParaMenu();
        },
          ),
          Expanded(
            child: ScrollFill(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StatePanel(
                    icon: Icons.check_rounded,
                    tone: AppTone.success,
                    title: 'Pulseira identificada',
                    message: 'Tudo pronto para escolher os itens e lançar na comanda.',
                  ),
                  const SizedBox(height: 28),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const IconBadge(icon: Icons.nfc_rounded, tone: AppTone.info, size: 58),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionLabel('ID da pulseira'),
                              const SizedBox(height: 4),
                              Text(
                                _scannedUid ?? 'N/A',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomActionBar(
            primary: AppButton(
              label: 'Escolher os itens do pedido',
              icon: Icons.restaurant_menu_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaSelecaoProdutos(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

