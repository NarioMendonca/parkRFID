/// Resumo de um check-in concluído, mostrado na tela de sucesso.
class CheckinResultModel {
  /// CPF e telefone como foram digitados (com máscara), para exibição.
  final String responsibleCpf;
  final String responsiblePhone;
  final int braceletCount;
  final DateTime finishedAt;

  const CheckinResultModel({
    required this.responsibleCpf,
    required this.responsiblePhone,
    required this.braceletCount,
    required this.finishedAt,
  });
}
