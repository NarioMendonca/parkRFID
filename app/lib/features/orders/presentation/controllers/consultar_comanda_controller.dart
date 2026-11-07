import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../../../core/utils/nfc_tag_utils.dart';
import '../../data/models/comanda_model.dart';
import '../../data/services/comanda_service.dart';

enum ConsultaComandaStep { leitura, carregando, resultado, nfcDesativado }

/// Fluxo: ler a pulseira → buscar a comanda → mostrar o resultado.
/// Em caso de erro, a tela mostra o aviso e a leitura recomeça sozinha.
class ConsultarComandaController extends ChangeNotifier {
  ConsultarComandaController(this._service);

  final ComandaService _service;
  bool _disposed = false;

  ConsultaComandaStep _step = ConsultaComandaStep.leitura;
  ConsultaComandaStep get step => _step;

  String? _scannedUid;
  String? get scannedUid => _scannedUid;

  ComandaSessaoModel? _comanda;
  ComandaSessaoModel? get comanda => _comanda;

  /// [onError] mostra a mensagem; quando ela termina (diálogo fechado), a
  /// leitura NFC recomeça.
  Future<void> startNfc({required Future<void> Function(String message) onError}) async {
    final available = await _isNfcAvailable();
    if (_disposed) return;

    if (!available) {
      _goTo(ConsultaComandaStep.nfcDesativado);
      return;
    }

    _goTo(ConsultaComandaStep.leitura);

    try {
      NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          if (_disposed || _step != ConsultaComandaStep.leitura) return;
          final tagId = extractNfcTagId(tag);
          if (tagId == null || tagId.isEmpty) {
            stopNfc();
            await onError('Não foi possível extrair o ID desta tag NFC.');
            if (!_disposed) startNfc(onError: onError);
            return;
          }
          await _buscar(tagId, onError);
        },
      );
    } catch (_) {
      if (!_disposed) _goTo(ConsultaComandaStep.nfcDesativado);
    }
  }

  void stopNfc() {
    try {
      NfcManager.instance.stopSession();
    } catch (_) {}
  }

  Future<void> _buscar(String raw, Future<void> Function(String message) onError) async {
    final uid = raw.trim().toUpperCase();
    if (uid.isEmpty) return;

    stopNfc();
    _scannedUid = uid;
    _comanda = null;
    _goTo(ConsultaComandaStep.carregando);

    try {
      final result = await _service.buscarComandaPorUid(uid);
      if (_disposed) return;
      _comanda = result;
      _goTo(ConsultaComandaStep.resultado);
    } catch (e) {
      if (_disposed) return;
      // Volta para a leitura (em vez de ficar num resultado vazio).
      _scannedUid = null;
      _goTo(ConsultaComandaStep.leitura);
      await onError(e.toString().replaceAll('Exception: ', ''));
      if (!_disposed) startNfc(onError: onError);
    }
  }

  Future<bool> _isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  void _goTo(ConsultaComandaStep step) {
    _step = step;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopNfc();
    super.dispose();
  }
}
