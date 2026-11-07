import 'package:flutter/foundation.dart';

import '../../data/models/checkout_models.dart';
import '../../data/repositories/checkout_repository.dart';

enum CheckoutView { grupo, individual }

/// Estado e regras do checkout. A tela só lê daqui e chama os métodos.
///
/// Regra da API: o pagamento quita o saldo inteiro de uma pulseira
/// (`POST /sessions/:braceletId/pay`), então pagar "a comanda do grupo" é
/// pagar todas as pulseiras pendentes, e pagar "individual" é escolher quais.
class CheckoutController extends ChangeNotifier {
  CheckoutController(this._repository);

  final CheckoutRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CheckoutGroup? _group;
  CheckoutGroup? get group => _group;

  String? _scannedUid;
  String? get scannedUid => _scannedUid;

  CheckoutView _view = CheckoutView.grupo;
  CheckoutView get view => _view;

  final Set<String> _selected = {};
  Set<String> get selected => _selected;

  PaymentMethod _method = PaymentMethod.pix;
  PaymentMethod get method => _method;

  double? _cashReceived;
  double? get cashReceived => _cashReceived;

  CheckoutPaymentResult? _lastPayment;
  CheckoutPaymentResult? get lastPayment => _lastPayment;

  bool _exitReleased = false;
  bool get exitReleased => _exitReleased;

  // ---------------------------------------------------------------------------
  // Valores calculados
  // ---------------------------------------------------------------------------
  List<CheckoutBracelet> get pendingBracelets =>
      _group?.bracelets.where((b) => !b.isSettled).toList() ?? [];

  double get selectedTotal => _group == null
      ? 0
      : _group!.bracelets
          .where((b) => _selected.contains(b.braceletId))
          .fold(0, (sum, b) => sum + b.pending);

  double get change {
    if (_method != PaymentMethod.dinheiro || _cashReceived == null) return 0;
    final c = _cashReceived! - selectedTotal;
    return c > 0 ? c : 0;
  }

  bool get cashIsEnough =>
      _method != PaymentMethod.dinheiro ||
      (_cashReceived != null && _cashReceived! >= selectedTotal);

  bool get canPay => !_isLoading && _selected.isNotEmpty && selectedTotal > 0 && cashIsEnough;

  // ---------------------------------------------------------------------------
  // Ações
  // ---------------------------------------------------------------------------
  Future<bool> loadByBracelet(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    _scannedUid = uid;
    notifyListeners();

    try {
      _group = await _repository.fetchGroupByBracelet(uid);
      _selected
        ..clear()
        ..addAll(pendingBracelets.map((b) => b.braceletId));
      _view = CheckoutView.grupo;
      _method = PaymentMethod.pix;
      _cashReceived = null;
      _lastPayment = null;
      _exitReleased = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _group = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setView(CheckoutView view) {
    _view = view;
    notifyListeners();
  }

  void toggleBracelet(String braceletId) {
    final b = _group?.bracelets.firstWhere((x) => x.braceletId == braceletId);
    if (b == null || b.isSettled) return;
    if (!_selected.remove(braceletId)) _selected.add(braceletId);
    notifyListeners();
  }

  void selectAllPending() {
    _selected
      ..clear()
      ..addAll(pendingBracelets.map((b) => b.braceletId));
    notifyListeners();
  }

  void setMethod(PaymentMethod method) {
    _method = method;
    if (method != PaymentMethod.dinheiro) _cashReceived = null;
    notifyListeners();
  }

  void setCashReceived(String text) {
    _cashReceived = double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
    notifyListeners();
  }

  Future<bool> pay() async {
    if (!canPay) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final paidIds = <String>[];
    double total = 0;
    try {
      for (final id in _selected.toList()) {
        total += await _repository.payBracelet(id);
        paidIds.add(id);
      }
      _lastPayment = CheckoutPaymentResult(
        paidAmount: total,
        method: _method,
        braceletIds: paidIds,
        cashReceived: _method == PaymentMethod.dinheiro ? _cashReceived : null,
        date: DateTime.now(),
      );
      _selected.clear();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      // Mantém registrado o que já foi pago antes do erro.
      if (paidIds.isNotEmpty) {
        _selected.removeAll(paidIds);
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Libera a saída de todas as pulseiras do grupo que estão quitadas.
  Future<bool> releaseExit() async {
    final group = _group;
    if (group == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      for (final b in group.bracelets.where((b) => b.isSettled && !b.exited)) {
        await _repository.exitBracelet(b.braceletId);
      }
      _exitReleased = true;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Volta do recibo para a comanda quando ainda há pulseiras pendentes.
  void backToComanda() {
    _lastPayment = null;
    _errorMessage = null;
    _cashReceived = null;
    selectAllPending();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _group = null;
    _scannedUid = null;
    _selected.clear();
    _errorMessage = null;
    _lastPayment = null;
    _exitReleased = false;
    _cashReceived = null;
    _method = PaymentMethod.pix;
    _view = CheckoutView.grupo;
    notifyListeners();
  }
}
