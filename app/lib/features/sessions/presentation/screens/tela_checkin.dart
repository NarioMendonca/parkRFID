import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/utils/nfc_off_screen.dart';
import '../../data/repositories/sessions_repository.dart';
import '../controllers/checkin_controller.dart';
import 'tela_checkin_grupo.dart';
import 'tela_checkin_inicio.dart';
import 'tela_checkin_leitura_nfc.dart';
import 'tela_checkin_responsavel.dart';
import 'tela_checkin_sucesso.dart';
import 'tela_checkin_tipo_pulseira.dart';


class TelaCheckin extends StatelessWidget {
  const TelaCheckin({super.key, this.onNavbarVisibilityChanged});


  final ValueChanged<bool>? onNavbarVisibilityChanged;

  static void Function()? _resetCallback;


  static void resetarFluxo() => _resetCallback?.call();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckinController(SessionsRepository(ApiClient.dio)),
      child: _TelaCheckinContent(onNavbarVisibilityChanged: onNavbarVisibilityChanged),
    );
  }
}

class _TelaCheckinContent extends StatefulWidget {
  const _TelaCheckinContent({this.onNavbarVisibilityChanged});

  final ValueChanged<bool>? onNavbarVisibilityChanged;

  @override
  State<_TelaCheckinContent> createState() => _TelaCheckinContentState();
}

class _TelaCheckinContentState extends State<_TelaCheckinContent>
    with SingleTickerProviderStateMixin {
  late final CheckinController _controller = context.read<CheckinController>();

  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();


  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final Animation<double> _fade = Tween<double>(begin: 0.35, end: 1).animate(
    CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
  );

  CheckinStep _etapaAnterior = CheckinStep.menu;
  bool _animarTroca = true;

  @override
  void initState() {
    super.initState();
    TelaCheckin._resetCallback = _reiniciarSemAnimacao;
    _controller.addListener(_onEtapaTalvezMudou);
  }

  @override
  void dispose() {
    if (TelaCheckin._resetCallback == _reiniciarSemAnimacao) {
      TelaCheckin._resetCallback = null;
    }
    _controller.removeListener(_onEtapaTalvezMudou);
    _fadeController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    super.dispose();
  }


  void _onEtapaTalvezMudou() {
    final etapa = _controller.step;
    if (etapa == _etapaAnterior) return;

    final estavaNoMenu = _etapaAnterior == CheckinStep.menu;
    _etapaAnterior = etapa;

    if (_animarTroca) {
      _fadeController.forward(from: 0);
    } else {
      _fadeController.value = 1;
    }


    if (etapa == CheckinStep.tipoPulseira) HapticFeedback.heavyImpact();

    final estaNoMenu = etapa == CheckinStep.menu;
    if (estavaNoMenu != estaNoMenu) widget.onNavbarVisibilityChanged?.call(estaNoMenu);
  }


  void _reiniciar() {
    HapticFeedback.mediumImpact();
    _cpfController.clear();
    _phoneController.clear();
    _controller.reset();
  }


  void _reiniciarSemAnimacao() {
    _animarTroca = false;
    _cpfController.clear();
    _phoneController.clear();
    _controller.reset();
    _animarTroca = true;
  }

  void _continuarParaLeitura() {
    final erro = _controller.setResponsible(
      cpf: _cpfController.text,
      phone: _phoneController.text,
    );
    if (erro != null) {
      _mostrarErro(erro);
      return;
    }
    _iniciarLeitura();
  }

  void _iniciarLeitura() => _controller.startNfc(onError: _mostrarErro);

  void _voltarParaFormulario() {
    _controller.stopNfc();
    _controller.goTo(CheckinStep.formulario);
  }

  Future<void> _finalizar() async {
    final erro = await _controller.finishCheckin();
    if (erro != null) _mostrarErro(erro);
  }


  void _voltar() {
    HapticFeedback.lightImpact();
    switch (_controller.step) {
      case CheckinStep.menu:
        break;
      case CheckinStep.formulario:
      case CheckinStep.sucesso:
        _reiniciar();
      case CheckinStep.leituraNfc:
      case CheckinStep.nfcDesativado:
      case CheckinStep.grupo:
        _voltarParaFormulario();
      case CheckinStep.tipoPulseira:
        _iniciarLeitura();
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atenção', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(dialogContext);
            },
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckinController>();

    return PopScope(
      canPop: c.step == CheckinStep.menu,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _voltar();
      },
      child: FadeTransition(
        opacity: _fade,
        child: _buildEtapa(c),
      ),
    );
  }

  Widget _buildEtapa(CheckinController c) {
    switch (c.step) {
      case CheckinStep.menu:
        return TelaCheckinInicio(
          onNovoCheckin: () => c.goTo(CheckinStep.formulario),
        );
      case CheckinStep.formulario:
        return TelaCheckinResponsavel(
          cpfController: _cpfController,
          phoneController: _phoneController,
          onVoltar: _reiniciar,
          onContinuar: _continuarParaLeitura,
        );
      case CheckinStep.leituraNfc:
        return TelaCheckinLeituraNfc(
          pulseirasNoGrupo: c.bracelets.length,
          onVoltar: _voltarParaFormulario,
          onVerGrupo: () {
            c.stopNfc();
            c.goTo(CheckinStep.grupo);
          },
        );
      case CheckinStep.nfcDesativado:
        return TelaNfcDesativado(
          key: const ValueKey('nfc_desativado'),
          onVoltar: _voltarParaFormulario,
          onTentarNovamente: _iniciarLeitura,
        );
      case CheckinStep.tipoPulseira:
        return TelaCheckinTipoPulseira(
          braceletId: c.scannedUid ?? '',
          tipoSelecionado: c.selectedType,
          onSelecionarTipo: c.selectType,
          onVoltar: _iniciarLeitura,
          onAdicionar: c.addScannedToGroup,
        );
      case CheckinStep.grupo:
        return TelaCheckinGrupo(
          cpfResponsavel: c.responsibleCpf,
          pulseiras: c.bracelets,
          isLoading: c.isLoading,
          onVoltar: _iniciarLeitura,
          onRemover: c.removeBracelet,
          onFinalizar: _finalizar,
          onLerMais: _iniciarLeitura,
        );
      case CheckinStep.sucesso:
        return TelaCheckinSucesso(
          resultado: c.lastResult,
          onNovoCheckin: _reiniciar,
        );
    }
  }
}
