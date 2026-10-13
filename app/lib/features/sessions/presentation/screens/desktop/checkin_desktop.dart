import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/api/api_client.dart';

class MaskedTextInputFormatter extends TextInputFormatter {
  final String mask;
  final String separator;

  MaskedTextInputFormatter({required this.mask, required this.separator});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isNotEmpty) {
      if (newValue.text.length > oldValue.text.length) {
        if (newValue.text.length > mask.length) return oldValue;
      }
    }

    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String result = '';
    int currentIndex = 0;

    for (int i = 0; i < mask.length; i++) {
      if (currentIndex >= text.length) break;
      if (mask[i] == '0') {
        result += text[currentIndex];
        currentIndex++;
      } else {
        result += mask[i];
      }
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class TelaCheckinDesktop extends StatefulWidget {
  const TelaCheckinDesktop({super.key});

  @override
  State<TelaCheckinDesktop> createState() => _TelaCheckinDesktopState();
}

class _TelaCheckinDesktopState extends State<TelaCheckinDesktop> {
  final Dio _dio = ApiClient.dio;

  int _step = 0;
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _manualTagController = TextEditingController();
  final _focusNodeManual = FocusNode();

  final List<Map<String, String>> _bands = [];
  String? _currentUid;
  String _selectedType = 'adulto';
  DateTime? _finishedAt;
  bool _isLoading = false;
  bool _isWelcomeHovered = false;

  final StringBuffer _usbBuffer = StringBuffer();
  DateTime? _lastKeyEventTime;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _cpfController.dispose();
    _phoneController.dispose();
    _manualTagController.dispose();
    _focusNodeManual.dispose();
    super.dispose();
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (_step != 2) return false;
    if (_focusNodeManual.hasFocus) return false;

    if (event is KeyDownEvent) {
      final now = DateTime.now();
      if (_lastKeyEventTime != null && now.difference(_lastKeyEventTime!) > const Duration(milliseconds: 100)) {
        _usbBuffer.clear();
      }
      _lastKeyEventTime = now;

      if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        final raw = _usbBuffer.toString().trim();
        _usbBuffer.clear();
        if (raw.isNotEmpty) {
          _submitTag(raw);
          return true;
        }
      } else {
        final char = event.character;
        if (char != null && char.isNotEmpty) {
          _usbBuffer.write(char);
          return true;
        }
      }
    }
    return false;
  }

  void _reset() {
    setState(() {
      _step = 0;
      _cpfController.clear();
      _phoneController.clear();
      _manualTagController.clear();
      _bands.clear();
      _currentUid = null;
      _finishedAt = null;
    });
  }

  void _submitTag(String raw) {
    final u = raw.trim().toUpperCase();
    if (u.isEmpty) return;
    if (_bands.any((b) => b['uid'] == u)) {
      _showError('Esta pulseira já está vinculada ao grupo.');
      return;
    }
    setState(() {
      _currentUid = u;
      _step = 3;
      _manualTagController.clear();
    });
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(36, 36, 36, 12),
        contentPadding: const EdgeInsets.fromLTRB(36, 12, 36, 24),
        actionsPadding: const EdgeInsets.fromLTRB(36, 0, 36, 36),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 16),
            const Text('Atenção', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Text(msg, style: const TextStyle(fontSize: 18, color: Colors.black87)),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Text('OK, Entendido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeCheckin() async {
    if (_bands.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final cleanCpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanPhone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

      final groupRes = await _dio.post('/sessions/checkin/group', data: {
        'responsibleCpf': cleanCpf,
        'responsiblePhoneNumber': cleanPhone,
      });

      String? groupId;
      if (groupRes.statusCode == 200 || groupRes.statusCode == 201) {
        if (groupRes.data is Map && groupRes.data['sessionGroup'] != null) {
          groupId = groupRes.data['sessionGroup']['id']?.toString();
        }
      }

      if (groupId == null || groupId.isEmpty) {
        throw Exception('Não foi possível obter o ID do grupo.');
      }

      for (final b in _bands) {
        await _dio.post('/sessions/checkin', data: {
          'braceletId': b['uid'],
          'sessionGroupId': groupId,
          'sessionType': b['type'] == 'kid' ? 'KID' : 'NORMAL',
        });
      }

      setState(() {
        _finishedAt = DateTime.now();
        _step = 4;
      });
    } catch (e) {
      _showError('Erro ao finalizar check-in: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                Image.asset('assets/images/logo.png', height: 44, fit: BoxFit.contain),
                const SizedBox(width: 18),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Check-in', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 56,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: (_step > 0 && _step < 4)
                                  ? Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      if (_step == 1) {
                                        _reset();
                                      } else if (_step > 1) {
                                        _step--;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.arrow_back_rounded, size: 22, color: colorScheme.onSurface),
                                        const SizedBox(width: 10),
                                        Text('Voltar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              switchInCurve: Curves.easeInOut,
                              switchOutCurve: Curves.easeInOut,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.05, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey<int>(_step),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: _buildMainWorkspace(colorScheme),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: _buildSidebar(colorScheme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainWorkspace(ColorScheme colorScheme) {
    switch (_step) {
      case 1:
        return _buildStepIdentify();
      case 2:
        return _buildStepReader();
      case 3:
        return _buildStepChooseType();
      case 4:
        return _buildStepSuccess();
      case 0:
      default:
        return _buildStepWelcome();
    }
  }

  Widget _buildSidebar(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Resumo do atendimento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reiniciar', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RESPONSÁVEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 14),
              _InfoRow(icon: Icons.person_outline, label: 'CPF', value: _cpfController.text.isEmpty ? '—' : _cpfController.text),
              const SizedBox(height: 14),
              _InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: _phoneController.text.isEmpty ? '—' : _phoneController.text),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PULSEIRAS VINCULADAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${_bands.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _bands.isEmpty
                      ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: const Text('Nenhuma pulseira vinculada ainda', style: TextStyle(color: Colors.grey, fontSize: 15), textAlign: TextAlign.center),
                    ),
                  )
                      : ListView.builder(
                    itemCount: _bands.length,
                    itemBuilder: (context, index) {
                      final b = _bands[index];
                      final isKid = b['type'] == 'kid';
                      return StatefulBuilder(
                        builder: (context, setStateItem) {
                          bool isHovered = false;
                          return MouseRegion(
                            onEnter: (_) => setStateItem(() => isHovered = true),
                            onExit: (_) => setStateItem(() => isHovered = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isHovered ? Colors.red : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isHovered ? Colors.red.shade700 : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isHovered ? Colors.white.withOpacity(0.2) : colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isKid ? Icons.child_care : Icons.person,
                                      color: isHovered ? Colors.white : colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '#${index + 1} · ${isKid ? 'Kid / Infantil' : 'Normal / Adulto'}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isHovered ? Colors.white : colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          b['uid']!,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            color: isHovered ? Colors.white70 : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_step != 4)
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: isHovered ? Colors.white : Colors.redAccent,
                                        size: 22,
                                      ),
                                      onPressed: () => setState(() => _bands.removeAt(index)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (_bands.isNotEmpty && _step != 4) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: _isLoading ? null : _finalizeCheckin,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Finalizar Check-in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepWelcome() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', height: 95, fit: BoxFit.contain),
          const SizedBox(height: 28),
          const Text('Bem-vindo ao balcão', style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          const Text('Inicie um atendimento para cadastrar o responsável e vincular as pulseiras do grupo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 18)),
          const SizedBox(height: 48),
          MouseRegion(
            onEnter: (_) => setState(() => _isWelcomeHovered = true),
            onExit: (_) => setState(() => _isWelcomeHovered = false),
            child: GestureDetector(
              onTap: () => setState(() => _step = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _isWelcomeHovered ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _isWelcomeHovered
                      ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ]
                      : [],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 24),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Novo Check-in', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('Identificar responsável → ler pulseiras → finalizar', style: TextStyle(color: Colors.white70, fontSize: 15)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIdentify() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('PASSO 1 DE 3', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          const Text('Identificação do responsável', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Informe o CPF e o telefone/WhatsApp do responsável pelo grupo.', style: TextStyle(color: Colors.grey, fontSize: 17)),
          const SizedBox(height: 36),
          const Text('CPF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          TextField(
            controller: _cpfController,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              MaskedTextInputFormatter(mask: '000.000.000-00', separator: '.'),
            ],
            decoration: const InputDecoration(hintText: '000.000.000-00', contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 28),
          const Text('TELEFONE / WHATSAPP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              MaskedTextInputFormatter(mask: '(00) 00000-0000', separator: ' '),
            ],
            decoration: const InputDecoration(hintText: '(00) 00000-0000', contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 62,
            child: ElevatedButton(
              onPressed: () {
                final cpfClean = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
                final phoneClean = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
                if (cpfClean.length == 11 && phoneClean.length >= 10) {
                  setState(() => _step = 2);
                } else {
                  _showError('Preencha o CPF (11 dígitos) e Telefone válidos.');
                }
              },
              child: const Text('Prosseguir para leitura', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepReader() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('PASSO 2 DE 3', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          const Text('Aproxime a pulseira', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('O leitor USB/NFC está ativo e aguardando a leitura da tag.', style: TextStyle(color: Colors.grey, fontSize: 17)),
          const SizedBox(height: 44),
          Container(
            padding: const EdgeInsets.all(38),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nfc, size: 76, color: Colors.blue),
          ),
          const SizedBox(height: 24),
          const Text('● Aguardando leitura...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 17)),
          const SizedBox(height: 44),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualTagController,
                  focusNode: _focusNodeManual,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(hintText: 'Simular código da tag (ex: 04A1B2C3)', contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      _submitTag(v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 14),
              OutlinedButton(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
                onPressed: () {
                  final rand = 'TAG${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                  _submitTag(rand);
                },
                child: const Text('Gerar', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20)),
                onPressed: () {
                  if (_manualTagController.text.trim().isNotEmpty) {
                    _submitTag(_manualTagController.text);
                  }
                },
                child: const Text('Ler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepChooseType() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('PASSO 3 DE 3', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          const Text('Tipo de pulseira', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tag lida: ${_currentUid ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = 'adulto'),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _selectedType == 'adulto' ? Colors.blue.shade50 : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedType == 'adulto' ? Colors.blue : Theme.of(context).colorScheme.outlineVariant,
                        width: _selectedType == 'adulto' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.person, size: 38, color: Colors.blue),
                        SizedBox(height: 20),
                        Text('Normal / Adulto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('Acesso completo às atrações', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = 'kid'),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _selectedType == 'kid' ? Colors.blue.shade50 : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedType == 'kid' ? Colors.blue : Theme.of(context).colorScheme.outlineVariant,
                        width: _selectedType == 'kid' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.child_care, size: 38, color: Colors.blue),
                        SizedBox(height: 20),
                        Text('Kid / Infantil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('Atrações e áreas infantis', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20)),
                onPressed: () => setState(() => _step = 2),
                child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentUid != null) {
                        setState(() {
                          _bands.add({
                            'uid': _currentUid!,
                            'type': _selectedType,
                            'at': DateTime.now().toIso8601String(),
                          });
                          _currentUid = null;
                          _step = 2;
                        });
                      }
                    },
                    child: const Text('Vincular ao grupo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepSuccess() {
    final kids = _bands.where((b) => b['type'] == 'kid').length;
    final adults = _bands.length - kids;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          ),
          const SizedBox(height: 28),
          const Text('Check-in concluído!', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Pulseiras ativadas. Bom divertimento!', style: TextStyle(color: Colors.grey, fontSize: 18)),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _InfoRow(icon: Icons.access_time, label: 'Horário', value: _finishedAt != null ? TimeOfDay.fromDateTime(_finishedAt!).format(context) : '—'),
                const SizedBox(height: 14),
                _InfoRow(icon: Icons.person_outline, label: 'CPF', value: _cpfController.text),
                const SizedBox(height: 14),
                _InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: _phoneController.text),
                const SizedBox(height: 14),
                _InfoRow(icon: Icons.nfc, label: 'Pulseiras', value: '${_bands.length} ($adults adulto · $kids kid)'),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 62,
            child: ElevatedButton(
              onPressed: _reset,
              child: const Text('Novo atendimento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}