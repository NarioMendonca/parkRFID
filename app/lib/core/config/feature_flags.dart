/// Liga/desliga funcionalidades que dependem de algo ainda não disponível.
abstract final class FeatureFlags {
  /// Número de mesa no pedido + impressão do ticket.
  ///
  /// Com `true`, o pedido passa pela tela de atribuir mesa ([TelaAtribuirMesa])
  /// e envia `tableNumber` em `POST /orders`; a API imprime o ticket quando
  /// `PRINTER_HOST` está configurado. Com `false`, a mesa sai do fluxo e o
  /// pedido vai direto para a revisão.
  static const bool mesaEImpressao = true;
}
