import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../core/utils/nfc_off_screen.dart';
import '../../controllers/bracelets_controller.dart';

class TelaGestaoPulseirasDesktop extends StatelessWidget {
  const TelaGestaoPulseirasDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BraceletsController(),
      child: const _TelaGestaoPulseirasDesktopContent(),
    );
  }
}

class _TelaGestaoPulseirasDesktopContent extends StatefulWidget {
  const _TelaGestaoPulseirasDesktopContent();

  @override
  State<_TelaGestaoPulseirasDesktopContent> createState() => _TelaGestaoPulseirasDesktopContentState();
}

class _TelaGestaoPulseirasDesktopContentState extends State<_TelaGestaoPulseirasDesktopContent> with SingleTickerProviderStateMixin {
  int _step = 1;
  String? _scannedUid;
  bool _isDeleteMode = false;
  String? _localErrorMessage;

  final _simuladorUsbController = TextEditingController();
  final _focusNodeSimulador = FocusNode();
  final StringBuffer _usbBuffer = StringBuffer();
  Timer? _tagTimer;

  late final AnimationController _radarController;
  late final Animation<double> _radarScaleAnim;
  late final Animation<double> _radarOpacityAnim;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _radarScaleAnim = Tween<double>(begin: 0.9, end: 1.85).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.easeInOutCubicEmphasized),
    );

    _radarOpacityAnim = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _radarController.dispose();
    _tagTimer?.cancel();
    _simuladorUsbController.dispose();
    _focusNodeSimulador.dispose();
    super.dispose();
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (_step != 2) return false;
    if (_focusNodeSimulador.hasFocus) return false;

    if (event is KeyDownEvent) {
      final char = event.character;
      if (char != null && char.isNotEmpty) {
        _usbBuffer.write(char);
        _tagTimer?.cancel();
        _tagTimer = Timer(const Duration(milliseconds: 80), () {
          final raw = _usbBuffer.toString().trim();
          _usbBuffer.clear();
          if (raw.isNotEmpty) {
            _handleTagDiscovered(raw);
          }
        });
        return true;
      }
    }
    return false;
  }

  void _startScanning(bool deleteMode) {
    setState(() {
      _isDeleteMode = deleteMode;
      _step = 2;
      _scannedUid = null;
      _localErrorMessage = null;
      _usbBuffer.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodeSimulador.requestFocus();
    });
  }

  void _handleTagDiscovered(String raw) {
    final cleanId = raw.trim().toUpperCase();
    if (cleanId.isEmpty) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _scannedUid = cleanId;
      _step = 3;
      _localErrorMessage = null;
      _simuladorUsbController.clear();
    });
  }

  void _restartScanning() {
    setState(() {
      _step = 2;
      _scannedUid = null;
      _localErrorMessage = null;
      _usbBuffer.clear();
      _simuladorUsbController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodeSimulador.requestFocus();
    });
  }

  void _resetFlow() {
    _tagTimer?.cancel();
    _usbBuffer.clear();
    if (mounted && _step != 1) {
      setState(() {
        _step = 1;
        _scannedUid = null;
        _isDeleteMode = false;
        _localErrorMessage = null;
        _simuladorUsbController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/logo.png', height: 42, fit: BoxFit.contain),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gestão de Pulseiras', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                if (_step > 1)
                  OutlinedButton.icon(
                    onPressed: _resetFlow,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reiniciar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 850, minHeight: 560),
                  padding: const EdgeInsets.all(56),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildCurrentStep(colorScheme),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ColorScheme colorScheme) {
    switch (_step) {
      case 2:
        return _buildStepReader(colorScheme);
      case 3:
        return _buildStepResult(colorScheme);
      case 4:
        return TelaNfcDesativado(
          key: const ValueKey('nfc_desativado'),
          tituloHeader: _isDeleteMode ? 'Apagar pulseira' : 'Cadastrar pulseira',
          onVoltar: _resetFlow,
          onTentarNovamente: () => _startScanning(_isDeleteMode),
        );
      case 1:
      default:
        return _buildStepHome(colorScheme);
    }
  }

  Widget _buildStepHome(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/logo.png', height: 85, fit: BoxFit.contain),
        const SizedBox(height: 24),
        const Text('Cadastro de Pulseiras', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Selecione uma opção abaixo para iniciar a operação via leitor USB.', style: TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 50),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _startScanning(false);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.add, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 40),
                      const Text('Cadastrar', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Nova pulseira no sistema', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _startScanning(true);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 32),
                      ),
                      const SizedBox(height: 40),
                      const Text('Apagar', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Remover pulseira do sistema', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepReader(ColorScheme colorScheme) {
    final activeColor = _isDeleteMode ? Colors.redAccent : Colors.blue;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _radarScaleAnim.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor.withOpacity(_radarOpacityAnim.value),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.nfc, size: 68, color: activeColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _isDeleteMode ? 'Aproxime para apagar' : 'Aproxime a pulseira no leitor',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text('O leitor está ativo. A leitura é feita de forma instantânea ao aproximar a tag.', style: TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
        const SizedBox(height: 36),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: TextField(
            controller: _simuladorUsbController,
            focusNode: _focusNodeSimulador,
            autofocus: true,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Simulação manual (opcional)',
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _handleTagDiscovered(value.trim());
              }
            },
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: 300,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _resetFlow,
            child: const Text('Cancelar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepResult(ColorScheme colorScheme) {
    final controller = context.watch<BraceletsController>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _localErrorMessage != null ? const Color(0xFFFFEBEE) : (_isDeleteMode ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _localErrorMessage != null ? Icons.error_outline_rounded : (_isDeleteMode ? Icons.delete_outline_rounded : Icons.check_circle_rounded),
                color: _localErrorMessage != null ? const Color(0xFFC62828) : (_isDeleteMode ? const Color(0xFFC62828) : const Color(0xFF2E7D32)),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _localErrorMessage != null ? 'Erro na operação' : (_isDeleteMode ? 'Pronta para remoção' : 'Pronta para cadastro'),
                style: TextStyle(
                  color: _localErrorMessage != null ? const Color(0xFFC62828) : (_isDeleteMode ? const Color(0xFFC62828) : const Color(0xFF2E7D32)),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: colorScheme.surface, shape: BoxShape.circle),
                child: const Icon(Icons.nfc_rounded, color: Colors.blue, size: 32),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TAG IDENTIFICADA',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _scannedUid ?? 'N/A',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_localErrorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _localErrorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 44),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: _isDeleteMode
              ? OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: controller.isLoading
                ? null
                : () async {
              if (_scannedUid == null) return;
              final errorMessage = await controller.deleteBracelet(_scannedUid!);
              if (!mounted) return;
              if (errorMessage == null) {
                _restartScanning();
              } else {
                setState(() {
                  _localErrorMessage = errorMessage;
                });
              }
            },
            child: controller.isLoading
                ? const CircularProgressIndicator(color: Colors.redAccent)
                : const Text('Confirmar exclusão', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          )
              : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: controller.isLoading
                ? null
                : () async {
              if (_scannedUid == null) return;
              final errorMessage = await controller.registerBracelet(_scannedUid!);
              if (!mounted) return;
              if (errorMessage == null) {
                _restartScanning();
              } else {
                setState(() {
                  _localErrorMessage = errorMessage;
                });
              }
            },
            child: controller.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Confirmar cadastro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _resetFlow,
            child: const Text('Cancelar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}