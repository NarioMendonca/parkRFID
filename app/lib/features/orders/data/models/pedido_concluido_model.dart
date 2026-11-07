// Resumo do pedido enviado, mostrado na tela de conclusão.
// (A rota POST /orders só devolve { message }, então guardamos o que foi enviado.)

class PedidoConcluidoItem {
  final String name;
  final int amount;
  final double unitPrice;

  const PedidoConcluidoItem({required this.name, required this.amount, required this.unitPrice});

  double get subtotal => unitPrice * amount;
}

class PedidoConcluidoModel {
  final String braceletId;
  final String? mesa;
  final List<PedidoConcluidoItem> itens;
  final DateTime criadoEm;

  const PedidoConcluidoModel({
    required this.braceletId,
    required this.mesa,
    required this.itens,
    required this.criadoEm,
  });

  double get total => itens.fold<double>(0, (s, i) => s + i.subtotal);
  int get quantidadeItens => itens.fold<int>(0, (s, i) => s + i.amount);
}
