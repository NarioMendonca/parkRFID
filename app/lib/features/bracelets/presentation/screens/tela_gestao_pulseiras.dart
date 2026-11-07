import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/utils/nfc_off_screen.dart';
import '../../../../core/widgets/nfc_radar_pulse.dart';
import '../controllers/bracelets_controller.dart';


final GlobalKey<_TelaGestaoPulseirasContentState> gestaoPulseirasKey = GlobalKey();

class TelaGestaoPulseiras extends StatelessWidget {
  final ValueChanged<bool>? onNavbarVisibilityChanged;

  const TelaGestaoPulseiras({
    super.key,
    this.onNavbarVisibilityChanged,
  });

  static void resetarFluxo() {
    gestaoPulseirasKey.currentState?._resetFlow();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BraceletsController(),
      child: _TelaGestaoPulseirasContent(
        key: gestaoPulseirasKey,
        onNavbarVisibilityChanged: onNavbarVisibilityChanged,
      ),
    );
  }
}

class _TelaGestaoPulseirasContent extends StatefulWidget {
  final ValueChanged<bool>? onNavbarVisibilityChanged;

  const _TelaGestaoPulseirasContent({
    super.key,
    this.onNavbarVisibilityChanged,
  });

  @override
  State<_TelaGestaoPulseirasContent> createState() => _TelaGestaoPulseirasContentState();
}

class _TelaGestaoPulseirasContentState extends State<_TelaGestaoPulseirasContent> {
  int _step = 1;
  String? _scannedUid;
  bool _isDeleteMode = false;
  bool _isCheckingStatus = false;
  String? _localErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BraceletsController>().checkNfcSupport();
      }
    });
  }

  void _startScanning(bool deleteMode) async {
    final controller = context.read<BraceletsController>();
    final bool isAvailable = await controller.isNfcAvailable();

    if (!isAvailable) {
      if (mounted) {
        setState(() {
          _isDeleteMode = deleteMode;
          _step = 4;
        });
        widget.onNavbarVisibilityChanged?.call(false);
      }
      return;
    }

    setState(() {
      _isDeleteMode = deleteMode;
      _step = 2;
      _scannedUid = null;
      _localErrorMessage = null;
      _isCheckingStatus = false;
    });

    widget.onNavbarVisibilityChanged?.call(false);

    controller.startNfcScan((uid) async {
      if (_scannedUid != null) return;

      setState(() {
        _scannedUid = uid;
        _step = 3;
        _localErrorMessage = null;
        _isCheckingStatus = false;
      });
    });
  }

  Future<void> _restartScanning() async {
    final controller = context.read<BraceletsController>();
    final bool isAvailable = await controller.isNfcAvailable();

    if (!isAvailable) {
      if (mounted) {
        setState(() {
          _step = 4;
        });
      }
      return;
    }

    try { controller.stopNfc(); } catch (_) {}

    setState(() {
      _step = 2;
      _scannedUid = null;
      _localErrorMessage = null;
      _isCheckingStatus = false;
    });

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    controller.startNfcScan((uid) async {
      if (_scannedUid != null) return;
      setState(() {
        _scannedUid = uid;
        _step = 3;
        _localErrorMessage = null;
        _isCheckingStatus = false;
      });
    });
  }

  void _resetFlow() {
    try {
      context.read<BraceletsController>().stopNfc();
    } catch (_) {}

    if (mounted && _step != 1) {
      setState(() {
        _step = 1;
        _scannedUid = null;
        _isDeleteMode = false;
        _isCheckingStatus = false;
        _localErrorMessage = null;
      });

      widget.onNavbarVisibilityChanged?.call(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PopScope(
        canPop: _step == 1,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _step > 1) {
            _resetFlow();
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
      case 2:
        return _buildTela2Leitura();
      case 3:
        return _buildTela3Resultado();
      case 4:
        return TelaNfcDesativado(
          key: const ValueKey('nfc_desativado'),
          tituloHeader: _isDeleteMode ? 'Apagar pulseira' : 'Cadastrar pulseira',
          onVoltar: _resetFlow,
          onTentarNovamente: () => _startScanning(_isDeleteMode),
        );
      case 1:
      default:
        return _buildTela1Home();
    }
  }

  Widget _buildTela1Home() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WaveBand(
            subtitle: 'Controle de acesso e vinculação via NFC.',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ScrollFill(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ActionCard(
                        title: 'Cadastrar Pulseira',
                        subtitle: 'Registrar uma nova pulseira no sistema.',
                        icon: Icons.add_circle_outline_rounded,
                        backgroundIcon: Icons.watch_rounded,
                        tone: AppTone.primary,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _startScanning(false);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ActionCard(
                        title: 'Apagar Pulseira',
                        subtitle: 'Remover uma pulseira do sistema.',
                        icon: Icons.remove_circle_outline_rounded,
                        backgroundIcon: Icons.watch_rounded,
                        tone: AppTone.danger,
                        filled: false,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _startScanning(true);
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

  Widget _buildTela2Leitura() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ScanBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              ScanTopBar(
                title: _isDeleteMode ? 'Apagar pulseira' : 'Cadastrar pulseira',
                subtitle: 'Leitura RFID',
                onBack: () {
          HapticFeedback.lightImpact();
          _resetFlow();
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
                  _isDeleteMode
                      ? 'A pulseira lida poderá ser removida do sistema.'
                      : 'A pulseira lida poderá ser registrada no sistema.',
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
          _resetFlow();
        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTela3Resultado() {
    final controller = context.watch<BraceletsController>();

    final AppTone statusTone = _isCheckingStatus
        ? AppTone.warning
        : (_localErrorMessage != null
            ? AppTone.danger
            : (_isDeleteMode ? AppTone.danger : AppTone.success));
    final IconData statusIcon = _isCheckingStatus
        ? Icons.hourglass_top_rounded
        : (_localErrorMessage != null
            ? Icons.error_outline_rounded
            : (_isDeleteMode ? Icons.delete_outline_rounded : Icons.check_rounded));
    final String statusLabel = _isCheckingStatus
        ? 'Verificando status...'
        : (_localErrorMessage != null
            ? 'Já cadastrada'
            : (_isDeleteMode ? 'Pronta para remoção' : 'Pronta para cadastro'));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: _isDeleteMode ? 'Apagar pulseira' : 'Cadastrar pulseira',
            subtitle: 'Resultado da leitura',
            onBack: () {
          HapticFeedback.lightImpact();
          _resetFlow();
        },
          ),
          Expanded(
            child: ScrollFill(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatePanel(
                    icon: statusIcon,
                    tone: statusTone,
                    title: statusLabel,
                    message: _localErrorMessage == null
                        ? (_isDeleteMode
                            ? 'A pulseira será removida completamente do sistema.'
                            : 'A pulseira será registrada no sistema.')
                        : null,
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
                              const SectionLabel('Pulseira / tag'),
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
                  if (_localErrorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ResultNotice(message: _localErrorMessage!),
                  ],
                ],
              ),
            ),
          ),
          BottomActionBar(
            primary: _isDeleteMode
                ? AppButton(
                    label: 'Confirmar exclusão',
                    icon: Icons.delete_outline_rounded,
                    tone: AppTone.danger,
                    loading: controller.isLoading,
                    onPressed: controller.isLoading
                        ? null
                        : () async {
                            HapticFeedback.lightImpact();
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
                  )
                : AppButton(
                    label: 'Confirmar cadastro',
                    icon: Icons.check_circle_outline_rounded,
                    loading: controller.isLoading,
                    onPressed: controller.isLoading
                        ? null
                        : () async {
                            HapticFeedback.lightImpact();
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
                  ),
            secondary: AppButton(
              label: 'Voltar ao menu',
              icon: Icons.arrow_back_rounded,
              outlined: true,
              tone: AppTone.neutral,
              height: 50,
              onPressed: () {
          HapticFeedback.lightImpact();
          _resetFlow();
        },
            ),
          ),
        ],
      ),
    );
  }
}



class _ResultNotice extends StatelessWidget {
  const _ResultNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTone.danger.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTone.danger.edge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 26, color: AppTheme.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Não foi possível concluir',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
