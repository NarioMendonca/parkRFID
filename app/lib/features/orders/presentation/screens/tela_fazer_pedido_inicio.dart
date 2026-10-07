import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:provider/provider.dart';
import 'package:rfidparque/features/orders/presentation/screens/tela_consultar_comanda.dart';
import '../../../../core/utils/nfc_off_screen.dart';
import '../../../bracelets/presentation/screens/nfc_radar_pulse.dart';
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

    context.read<PedidoProvider>().setBraceletId(cleanId);

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
      color: const Color(0xFFF4F7FA),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
                    ),
                ],
              ),
            ),
            const Spacer(flex: 1),

            Image.asset(
              'assets/images/logo.png',
              height: 160,
              fit: BoxFit.contain,
            ),

            const Spacer(flex: 1),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _startNfcSession();
                      },
                      child: Container(
                        height: 180,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3880C4),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3880C4).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Fazer\npedido',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'ler pulseira e lançar\nitens',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),


                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();


                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TelaConsultarComanda(),
                          ),
                        );
                      },
                      child: Container(
                        height: 180,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4E5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.adjust_rounded, color: Color(0xFFE29933), size: 24),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Consultar\ncomanda',
                                  style: TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'ver consumo da\npulseira',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTelaLeitura() {
    return Container(
      key: const ValueKey('leitura'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B7BB9), Color(0xFF102847)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Spacer(),
            const NfcRadarPulse(),
            const SizedBox(height: 40),
            const Text(
              'Aproxime a pulseira',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTelaResultado() {
    return Container(
      key: const ValueKey('resultado'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B7BB9), Color(0xFF102847)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                          SizedBox(width: 6),
                          Text('Pulseira identificada', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                          child: const Icon(Icons.nfc_rounded, color: Color(0xFF1E88E5), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_scannedUid ?? 'N/A', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            const Text('ID da Pulseira', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TelaSelecaoProdutos(),
                      ),
                    );
                  },
                  child: const Text(
                    'Escolher os itens do pedido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            onPressed: _voltarParaMenu,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Leitura da pulseira',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}