import 'package:dio/dio.dart';

import '../models/checkout_models.dart';

/// Contrato do checkout. A tela só conhece esta interface, então trocar o mock
/// pela API real é só trocar a implementação passada ao controller.
abstract class CheckoutRepository {
  /// Busca o grupo da pulseira lida, com as pulseiras e o consumo de cada uma.
  Future<CheckoutGroup> fetchGroupByBracelet(String braceletUid);

  /// Quita o saldo pendente da pulseira. Retorna o valor pago.
  /// API: `POST /sessions/:braceletId/pay` → `{ paidAmount, message }`
  Future<double> payBracelet(String braceletUid);

  /// Libera a saída (fecha a sessão). Só funciona com saldo zerado.
  /// API: `POST /sessions/:braceletId/exit`
  Future<void> exitBracelet(String braceletUid);
}

// -----------------------------------------------------------------------------
// Implementação com a API real (usar quando o endpoint do grupo existir)
// -----------------------------------------------------------------------------
class ApiCheckoutRepository implements CheckoutRepository {
  final Dio _dio;

  ApiCheckoutRepository(this._dio);

  @override
  Future<CheckoutGroup> fetchGroupByBracelet(String braceletUid) async {
    // TODO: ainda não existe rota que devolva o grupo pela pulseira.
    // Sugestão: GET /sessions/group/:braceletId → grupo + sessões abertas,
    // e para cada sessão usar GET /sessions/:sessionId/history (eventos ORDER).
    throw UnimplementedError('Endpoint de grupo ainda não disponível.');
  }

  @override
  Future<double> payBracelet(String braceletUid) async {
    try {
      final response = await _dio.post('/sessions/$braceletUid/pay');
      return double.tryParse(response.data['paidAmount'].toString()) ?? 0;
    } on DioException catch (e) {
      throw _handleError(e, 'Não foi possível registrar o pagamento.');
    }
  }

  @override
  Future<void> exitBracelet(String braceletUid) async {
    try {
      await _dio.post('/sessions/$braceletUid/exit');
    } on DioException catch (e) {
      throw _handleError(e, 'Não foi possível liberar a saída.');
    }
  }

  Exception _handleError(DioException e, String defaultMessage) {
    if (e.response?.data != null && e.response?.data is Map) {
      final apiMessage = e.response?.data['message'];
      if (apiMessage != null && apiMessage.toString().isNotEmpty) {
        return Exception(apiMessage);
      }
    }
    return Exception(defaultMessage);
  }
}

// -----------------------------------------------------------------------------
// Implementação com dados simulados (enquanto o backend não fica pronto)
// -----------------------------------------------------------------------------
class MockCheckoutRepository implements CheckoutRepository {
  CheckoutGroup? _group;

  static const _delay = Duration(milliseconds: 600);

  /// UIDs prontos para teste (também aceita qualquer outro UID lido).
  static const testBraceletUids = ['A1B2C3D4', 'E5F6A7B8', 'C9D0E1F2'];

  @override
  Future<CheckoutGroup> fetchGroupByBracelet(String braceletUid) async {
    await Future.delayed(_delay);
    final uid = braceletUid.trim().toUpperCase();
    if (uid == 'SEMSESSAO') {
      throw Exception('Nenhuma sessão ativa encontrada nesta pulseira.');
    }

    // Se o UID lido não é de teste, ele vira a pulseira líder do grupo simulado.
    final ids = [...testBraceletUids];
    if (!ids.contains(uid)) ids[0] = uid;

    final now = DateTime.now();
    CheckoutOrderItem item(String id, String name, int qtd, double price) =>
        CheckoutOrderItem(menuItemId: id, name: name, amount: qtd, unitPrice: price);

    final bracelets = [
      CheckoutBracelet(
        sessionId: 'sess-1',
        braceletId: ids[0],
        isKid: false,
        isLeader: true,
        checkinDate: now.subtract(const Duration(hours: 5, minutes: 12)),
        orders: [
          CheckoutOrder(
            id: 'ord-101',
            date: now.subtract(const Duration(hours: 3, minutes: 40)),
            tableNumber: '12',
            items: [
              item('m1', 'Porção de batata frita', 1, 32.90),
              item('m2', 'Refrigerante lata', 2, 7.00),
            ],
          ),
          CheckoutOrder(
            id: 'ord-108',
            date: now.subtract(const Duration(hours: 1, minutes: 5)),
            tableNumber: '12',
            items: [
              item('m3', 'Cerveja long neck', 2, 12.50),
            ],
          ),
        ],
        pending: 0,
      ),
      CheckoutBracelet(
        sessionId: 'sess-2',
        braceletId: ids[1],
        isKid: false,
        isLeader: false,
        checkinDate: now.subtract(const Duration(hours: 5, minutes: 10)),
        orders: [
          CheckoutOrder(
            id: 'ord-102',
            date: now.subtract(const Duration(hours: 3, minutes: 20)),
            items: [
              item('m4', 'Hambúrguer artesanal', 1, 38.00),
              item('m5', 'Suco natural', 1, 9.50),
            ],
          ),
        ],
        pending: 0,
        paid: 20.00,
      ),
      CheckoutBracelet(
        sessionId: 'sess-3',
        braceletId: ids[2],
        isKid: true,
        isLeader: false,
        checkinDate: now.subtract(const Duration(hours: 5, minutes: 10)),
        orders: [
          CheckoutOrder(
            id: 'ord-103',
            date: now.subtract(const Duration(hours: 2, minutes: 50)),
            items: [
              item('m6', 'Picolé de frutas', 2, 6.00),
              item('m2', 'Refrigerante lata', 1, 7.00),
            ],
          ),
        ],
        pending: 0,
      ),
    ];

    // Saldo pendente = consumo - já pago (como o `total` da sessão na API).
    for (final b in bracelets) {
      b.pending = double.parse((b.consumed - b.paid).toStringAsFixed(2));
    }

    _group = CheckoutGroup(
      id: 'grupo-001',
      responsibleCpf: '123.456.789-00',
      responsiblePhone: '(88) 99876-5432',
      bracelets: bracelets,
    );
    return _group!;
  }

  CheckoutBracelet _find(String uid) {
    final group = _group;
    if (group == null) throw Exception('Grupo não carregado.');
    return group.bracelets.firstWhere(
      (b) => b.braceletId == uid,
      orElse: () => throw Exception('Pulseira $uid não pertence ao grupo.'),
    );
  }

  @override
  Future<double> payBracelet(String braceletUid) async {
    await Future.delayed(_delay);
    final b = _find(braceletUid);
    if (b.pending <= 0) throw Exception('A pulseira $braceletUid não tem saldo pendente.');
    final amount = b.pending;
    b.paid += amount;
    b.pending = 0;
    return amount;
  }

  @override
  Future<void> exitBracelet(String braceletUid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final b = _find(braceletUid);
    if (b.pending > 0) {
      throw Exception('Saldo pendente de R\$ ${b.pending.toStringAsFixed(2)} na pulseira $braceletUid.');
    }
    b.exited = true;
  }
}
