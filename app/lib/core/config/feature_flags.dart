/// Liga/desliga funcionalidades que dependem de algo ainda não disponível.
abstract final class FeatureFlags {
  /// Número de mesa no pedido + impressão do ticket.
  ///
  /// A API atual (main) não aceita `tableNumber` em `POST /orders` nem
  /// imprime pedidos. A tela de atribuir mesa ([TelaAtribuirMesa]) e o card
  /// de mesa na revisão continuam no código; com `false` eles só ficam fora
  /// do fluxo. Quando a API voltar a suportar, basta trocar para `true`.
  static const bool mesaEImpressao = false;
}
