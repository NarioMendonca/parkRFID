// Modelos da comanda de uma pulseira, no formato de
// GET /sessions/:sessionId/history → { session, events }.
//
// `events` mistura CHECKIN, ORDER, PAYMENT e CHECKOUT. Só ORDER (pedido com
// seus itens) e PAYMENT (pagamento) interessam à comanda.

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  return 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

DateTime? _toDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

/// Item de um pedido (`events[].items[]` de um evento ORDER).
class ComandaItemModel {
  final String menuItemId;
  final String name;
  final int amount;
  final double unitPrice;
  final double subtotal;

  const ComandaItemModel({
    required this.menuItemId,
    required this.name,
    required this.amount,
    required this.unitPrice,
    required this.subtotal,
  });

  factory ComandaItemModel.fromJson(Map<String, dynamic> json) {
    final amount = _toInt(json['amount']);
    final unitPrice = _toDouble(json['unitPrice']);
    final subtotal = _toDouble(json['subtotal']);
    return ComandaItemModel(
      menuItemId: json['menuItemId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Item',
      amount: amount,
      unitPrice: unitPrice,
      subtotal: subtotal > 0 ? subtotal : unitPrice * amount,
    );
  }
}

/// Pedido lançado na comanda (evento ORDER).
class ComandaPedidoModel {
  final String id;
  final DateTime? date;
  final double total;
  final List<ComandaItemModel> items;

  const ComandaPedidoModel({
    required this.id,
    required this.date,
    required this.total,
    required this.items,
  });

  factory ComandaPedidoModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((i) => ComandaItemModel.fromJson(Map<String, dynamic>.from(i)))
            .toList()
        : <ComandaItemModel>[];
    final total = _toDouble(json['total']);
    return ComandaPedidoModel(
      id: json['orderId']?.toString() ?? '',
      date: _toDate(json['date']),
      total: total > 0 ? total : items.fold<double>(0, (s, i) => s + i.subtotal),
      items: items,
    );
  }
}

/// Pagamento registrado na sessão (evento PAYMENT).
class ComandaPagamentoModel {
  final String id;
  final DateTime? date;
  final double amount;

  const ComandaPagamentoModel({required this.id, required this.date, required this.amount});

  factory ComandaPagamentoModel.fromJson(Map<String, dynamic> json) {
    return ComandaPagamentoModel(
      id: json['paymentId']?.toString() ?? '',
      date: _toDate(json['date']),
      amount: _toDouble(json['amount']),
    );
  }
}

/// Comanda completa de uma pulseira (sessão + pedidos + pagamentos).
class ComandaSessaoModel {
  final String sessionId;
  final String braceletId;
  final bool isKid;
  final bool isOpen;
  final DateTime? checkinDate;

  /// `total` da sessão na API: o que ainda falta pagar (zera ao pagar).
  final double saldoPendente;
  final List<ComandaPedidoModel> pedidos;
  final List<ComandaPagamentoModel> pagamentos;

  const ComandaSessaoModel({
    required this.sessionId,
    required this.braceletId,
    required this.isKid,
    required this.isOpen,
    required this.checkinDate,
    required this.saldoPendente,
    required this.pedidos,
    required this.pagamentos,
  });

  double get totalConsumido => pedidos.fold<double>(0, (s, p) => s + p.total);
  double get totalPago => pagamentos.fold<double>(0, (s, p) => s + p.amount);
  int get quantidadeItens =>
      pedidos.fold<int>(0, (s, p) => s + p.items.fold<int>(0, (a, i) => a + i.amount));

  factory ComandaSessaoModel.fromApi(Map<String, dynamic> session, List<dynamic> events) {
    final pedidos = <ComandaPedidoModel>[];
    final pagamentos = <ComandaPagamentoModel>[];

    for (final raw in events.whereType<Map>()) {
      final event = Map<String, dynamic>.from(raw);
      switch (event['type']?.toString().toUpperCase()) {
        case 'ORDER':
          pedidos.add(ComandaPedidoModel.fromJson(event));
        case 'PAYMENT':
          pagamentos.add(ComandaPagamentoModel.fromJson(event));
      }
    }

    return ComandaSessaoModel(
      sessionId: session['id']?.toString() ?? '',
      braceletId: session['braceletId']?.toString() ?? '',
      isKid: session['sessionType']?.toString().toUpperCase() == 'KID',
      isOpen: session['status']?.toString().toUpperCase() != 'CLOSED',
      checkinDate: _toDate(session['checkinDate']),
      saldoPendente: _toDouble(session['total']),
      pedidos: pedidos,
      pagamentos: pagamentos,
    );
  }
}
