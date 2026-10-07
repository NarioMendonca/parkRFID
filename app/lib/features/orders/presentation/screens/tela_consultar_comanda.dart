import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../../../core/utils/nfc_off_screen.dart';
import '../../../bracelets/presentation/screens/nfc_radar_pulse.dart';
import '../../data/models/comanda_model.dart';
import '../../data/services/comanda_service.dart';

class TelaConsultarComanda extends StatefulWidget {
  const TelaConsultarComanda({super.key});

  @override
  State<TelaConsultarComanda> createState() => _TelaConsultarComandaState();
}

class _TelaConsultarComandaState extends State<TelaConsultarComanda> {
  final ComandaService _comandaService = ComandaService();

  int _step = 1;
  String? _scannedUid;
  ComandaSessaoModel? _comandaData;
  bool _isLoadingApi = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNfcSession();
    });
  }

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
          _step = 3;
        });
      }
      return;
    }

    setState(() {
      _step = 1;
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
          _step = 3;
        });
      }
    }
  }

  void _stopNfcSession({bool updateState = true}) {
    try {
      NfcManager.instance.stopSession();
    } catch (_) {}
  }

  void _handleTagDiscovered(String tagId) {
    final cleanId = tagId.trim().toUpperCase();
    if (cleanId.isEmpty) return;

    HapticFeedback.heavyImpact();
    _stopNfcSession();

    if (!mounted) return;
    _buscarComanda(cleanId);
  }

  Future<void> _buscarComanda(String uidRfid) async {
    setState(() {
      _scannedUid = uidRfid;
      _isLoadingApi = true;
      _step = 2;
    });

    try {
      final result = await _comandaService.buscarComandaPorUid(uidRfid);
      if (!mounted) return;

      setState(() {
        _comandaData = result;
        _isLoadingApi = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingApi = false;
      });
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _voltarParaInicio() {
    _stopNfcSession();
    if (!mounted) return;
    Navigator.of(context).pop();
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

  String _bytesToHex(List<int> bytes) => bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

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

  String _formatarMoeda(double valor) => 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatarHora(DateTime? date) {
    if (date == null) return '';
    final localDate = date.toLocal();
    return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            _stopNfcSession();
          }
        },
        child: SizedBox.expand(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(),
          ),
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
          tituloHeader: 'Consultar comanda',
          onVoltar: _voltarParaInicio,
          onTentarNovamente: _startNfcSession,
        );
      case 0:
      default:
        return _buildTelaLeitura();
    }
  }

  Widget _buildTelaLeitura() {
    return SizedBox.expand(
      key: const ValueKey('leitura'),
      child: DecoratedBox(
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
              _buildHeader('Consultar comanda'),
              const Spacer(),
              GestureDetector(
                onTap: () => _handleTagDiscovered('SIM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'),
                child: const NfcRadarPulse(),
              ),
              const SizedBox(height: 40),
              const Text(
                'Aproxime a pulseira',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelaResultado() {
    if (_isLoadingApi) {
      return SizedBox.expand(
        key: const ValueKey('loading'),
        child: ColoredBox(
          color: const Color(0xFFF4F7FA),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF3880C4)),
                SizedBox(height: 24),
                Text(
                  'Buscando comanda...',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = _comandaData?.items ?? [];

    return SizedBox.expand(
      key: const ValueKey('resultado'),
      child: ColoredBox(
        color: const Color(0xFFF4F7FA),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _voltarParaInicio,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Detalhes da Comanda',
                      style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.nfc_rounded, color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _scannedUid ?? '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Sessão Ativa',
                              style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Consumido', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                _formatarMoeda(_comandaData?.total ?? 0.0),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (_comandaData?.checkinDate != null)
                            Text(
                              'Entrada: ${_formatarHora(_comandaData!.checkinDate)}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.restaurant_menu_rounded, size: 18, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Text(
                      'Itens da comanda',
                      style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFF94A3B8)),
                      SizedBox(height: 12),
                      Text(
                        'Nenhum item consumido ainda',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3880C4), fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.description,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 15),
                                ),
                                if (item.date != null)
                                  Text(
                                    'Lançado às ${_formatarHora(item.date)}',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            _formatarMoeda(item.total),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3880C4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _startNfcSession,
                    icon: const Icon(Icons.nfc_rounded, color: Colors.white),
                    label: const Text(
                      'Consultar outra pulseira',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            onPressed: _voltarParaInicio,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}