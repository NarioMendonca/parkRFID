import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../../../core/utils/nfc_tag_utils.dart';
import '../../data/models/checkin_bracelet_model.dart';
import '../../data/models/checkin_result_model.dart';
import '../../data/repositories/sessions_repository.dart';


enum CheckinStep {
  menu,
  formulario,
  leituraNfc,
  nfcDesativado,
  tipoPulseira,
  grupo,
  sucesso,
}


class CheckinController extends ChangeNotifier {
  CheckinController(this._repository);

  final SessionsRepository _repository;
  bool _disposed = false;

  CheckinStep _step = CheckinStep.menu;
  CheckinStep get step => _step;

  /// CPF e telefone como foram digitados (com máscara).
  String _responsibleCpf = '';
  String get responsibleCpf => _responsibleCpf;
  String _responsiblePhone = '';

  final List<CheckinBraceletModel> _bracelets = [];
  List<CheckinBraceletModel> get bracelets => List.unmodifiable(_bracelets);

  String? _scannedUid;
  String? get scannedUid => _scannedUid;

  SessionType _selectedType = SessionType.normal;
  SessionType get selectedType => _selectedType;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CheckinResultModel? _lastResult;
  CheckinResultModel? get lastResult => _lastResult;

  bool get _isPristine =>
      _step == CheckinStep.menu && _bracelets.isEmpty && _lastResult == null && _scannedUid == null;


  void goTo(CheckinStep step) {
    if (_step == step) return;
    _step = step;
    _notify();
  }


  void reset() {
    stopNfc();
    if (_isPristine) return;
    _step = CheckinStep.menu;
    _responsibleCpf = '';
    _responsiblePhone = '';
    _bracelets.clear();
    _scannedUid = null;
    _selectedType = SessionType.normal;
    _lastResult = null;
    _isLoading = false;
    _notify();
  }


  String? setResponsible({required String cpf, required String phone}) {
    if (_digits(cpf).length != 11) return 'O CPF deve conter exatamente 11 dígitos.';
    if (_digits(phone).length < 10) return 'Informe um telefone válido com DDD.';
    _responsibleCpf = cpf.trim();
    _responsiblePhone = phone.trim();
    return null;
  }


  Future<void> startNfc({required void Function(String message) onError}) async {
    final available = await _isNfcAvailable();
    if (_disposed) return;

    if (!available) {
      goTo(CheckinStep.nfcDesativado);
      return;
    }

    goTo(CheckinStep.leituraNfc);

    try {
      NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          if (_disposed) return;
          final tagId = extractNfcTagId(tag);
          if (tagId == null || tagId.isEmpty) {
            onError('Não foi possível extrair o ID desta tag NFC.');
            return;
          }
          _onTagRead(tagId, onError);
        },
      );
    } catch (_) {
      if (!_disposed) goTo(CheckinStep.nfcDesativado);
    }
  }

  void stopNfc() {
    try {
      NfcManager.instance.stopSession();
    } catch (_) {}
  }

  void _onTagRead(String raw, void Function(String message) onError) {
    final uid = raw.trim().toUpperCase();
    if (uid.isEmpty) return;

    if (_bracelets.any((b) => b.braceletId == uid)) {
      onError('Pulseira ($uid) já foi adicionada neste grupo!');
      return;
    }

    stopNfc();
    _scannedUid = uid;
    _selectedType = SessionType.normal;
    _step = CheckinStep.tipoPulseira;
    _notify();
  }


  void selectType(SessionType type) {
    if (_selectedType == type) return;
    _selectedType = type;
    _notify();
  }

  void addScannedToGroup() {
    final uid = _scannedUid;
    if (uid == null) return;
    _bracelets.add(CheckinBraceletModel(
      braceletId: uid,
      type: _selectedType,
      isLeader: _bracelets.isEmpty,
    ));
    _scannedUid = null;
    _step = CheckinStep.grupo;
    _notify();
  }


  void removeBracelet(int index) {
    if (index < 0 || index >= _bracelets.length) return;
    _bracelets.removeAt(index);
    // Se o líder saiu, a primeira pulseira restante vira a líder.
    if (_bracelets.isNotEmpty && !_bracelets.any((b) => b.isLeader)) {
      _bracelets[0] = _bracelets[0].copyWith(isLeader: true);
    }
    _notify();
  }


  Future<String?> finishCheckin() async {
    if (_bracelets.isEmpty) return 'Nenhuma pulseira foi registrada no grupo.';

    _isLoading = true;
    _notify();

    try {
      final group = await _repository.createGroup(
        responsibleCpf: _digits(_responsibleCpf),
        responsiblePhoneNumber: _digits(_responsiblePhone),
      );
      if (group.id.isEmpty) {
        throw Exception('Não foi possível obter o ID do grupo criado.');
      }

      for (final bracelet in _bracelets) {
        await _repository.checkinBracelet(
          braceletId: bracelet.braceletId,
          sessionGroupId: group.id,
          sessionType: bracelet.type.apiValue,
        );
      }

      _lastResult = CheckinResultModel(
        responsibleCpf: _responsibleCpf,
        responsiblePhone: _responsiblePhone,
        braceletCount: _bracelets.length,
        finishedAt: DateTime.now(),
      );
      _step = CheckinStep.sucesso;
      return null;
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return message.isEmpty ? 'Erro ao realizar check-in.' : message;
    } finally {
      _isLoading = false;
      _notify();
    }
  }


  static String _digits(String text) => text.replaceAll(RegExp(r'[^0-9]'), '');

  Future<bool> _isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopNfc();
    super.dispose();
  }
}
