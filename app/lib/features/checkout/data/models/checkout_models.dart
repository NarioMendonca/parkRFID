// Modelos do checkout (fechamento de comanda).
//
// Espelham o que a API já expõe:
// - `Sessions` (uma por pulseira): `total` é o saldo pendente da pulseira.
// - `SessionsGroup`: responsável (CPF/telefone) e as sessões do grupo.
// - `GET /sessions/:sessionId/history`: eventos ORDER (com itens) e PAYMENT.
//
// Enquanto não houver endpoint que devolva o grupo pela pulseira, os dados
// vêm do `MockCheckoutRepository`.

enum PaymentMethod { pix, credito, debito, dinheiro }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.pix:
        return 'Pix';
      case PaymentMethod.credito:
        return 'Crédito';
      case PaymentMethod.debito:
        return 'Débito';
      case PaymentMethod.dinheiro:
        return 'Dinheiro';
    }
  }
}

class CheckoutOrderItem {
  final String menuItemId;
  final String name;
  final int amount;
  final double unitPrice;

  const CheckoutOrderItem({
    required this.menuItemId,
    required this.name,
    required this.amount,
    required this.unitPrice,
  });

  double get subtotal => unitPrice * amount;

  /// Formato do item dentro de um evento ORDER do histórico da sessão.
  factory CheckoutOrderItem.fromJson(Map<String, dynamic> json) {
    return CheckoutOrderItem(
      menuItemId: json['menuItemId'] ?? '',
      name: json['name'] ?? '',
      amount: json['amount'] ?? 0,
      unitPrice: double.tryParse(json['unitPrice'].toString()) ?? 0,
    );
  }
}

class CheckoutOrder {
  final String id;
  final DateTime date;
  final String? tableNumber;
  final List<CheckoutOrderItem> items;

  const CheckoutOrder({
    required this.id,
    required this.date,
    required this.items,
    this.tableNumber,
  });

  double get total => items.fold(0, (sum, i) => sum + i.subtotal);

  /// Evento `{ type: "ORDER", date, orderId, tableNumber, total, items }` do histórico.
  factory CheckoutOrder.fromHistoryEvent(Map<String, dynamic> json) {
    return CheckoutOrder(
      id: json['orderId'] ?? '',
      tableNumber: json['tableNumber']?.toString(),
      date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      items: ((json['items'] as List?) ?? [])
          .map((e) => CheckoutOrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class CheckoutBracelet {
  final String sessionId;
  final String braceletId;
  final bool isKid;
  final bool isLeader;
  final DateTime checkinDate;
  final List<CheckoutOrder> orders;

  /// Saldo pendente (campo `total` da sessão).
  double pending;

  /// Soma dos pagamentos já feitos nesta sessão.
  double paid;

  /// Saída já liberada (sessão fechada).
  bool exited;

  CheckoutBracelet({
    required this.sessionId,
    required this.braceletId,
    required this.isKid,
    required this.isLeader,
    required this.checkinDate,
    required this.orders,
    required this.pending,
    this.paid = 0,
    this.exited = false,
  });

  double get consumed => orders.fold(0, (sum, o) => sum + o.total);
  bool get isSettled => pending <= 0;
}

class CheckoutGroup {
  final String id;
  final String responsibleCpf;
  final String responsiblePhone;
  final List<CheckoutBracelet> bracelets;

  const CheckoutGroup({
    required this.id,
    required this.responsibleCpf,
    required this.responsiblePhone,
    required this.bracelets,
  });

  double get totalPending => bracelets.fold(0, (sum, b) => sum + b.pending);
  double get totalConsumed => bracelets.fold(0, (sum, b) => sum + b.consumed);
  double get totalPaid => bracelets.fold(0, (sum, b) => sum + b.paid);

  /// Itens de todas as pulseiras somados por produto (comanda compartilhada).
  List<CheckoutOrderItem> get groupedItems {
    final map = <String, CheckoutOrderItem>{};
    for (final b in bracelets) {
      for (final o in b.orders) {
        for (final i in o.items) {
          final current = map[i.menuItemId];
          map[i.menuItemId] = CheckoutOrderItem(
            menuItemId: i.menuItemId,
            name: i.name,
            unitPrice: i.unitPrice,
            amount: (current?.amount ?? 0) + i.amount,
          );
        }
      }
    }
    final list = map.values.toList()..sort((a, b) => b.subtotal.compareTo(a.subtotal));
    return list;
  }
}

class CheckoutPaymentResult {
  final double paidAmount;
  final PaymentMethod method;
  final List<String> braceletIds;
  final double? cashReceived;
  final DateTime date;

  const CheckoutPaymentResult({
    required this.paidAmount,
    required this.method,
    required this.braceletIds,
    required this.date,
    this.cashReceived,
  });

  double get change =>
      cashReceived == null ? 0 : (cashReceived! - paidAmount).clamp(0, double.infinity);
}
