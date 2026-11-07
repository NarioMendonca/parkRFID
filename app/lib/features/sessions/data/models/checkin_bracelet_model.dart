/// Tipo da sessão da pulseira, com o valor que a API espera em `sessionType`.
enum SessionType {
  normal('NORMAL', 'Adulto / Normal'),
  kid('KID', 'Infantil / Kid');

  const SessionType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isKid => this == SessionType.kid;
}

/// Pulseira lida durante o check-in, ainda não enviada para a API.
class CheckinBraceletModel {
  final String braceletId;
  final SessionType type;

  /// A primeira pulseira do grupo é a do líder (responsável).
  final bool isLeader;

  const CheckinBraceletModel({
    required this.braceletId,
    required this.type,
    this.isLeader = false,
  });

  CheckinBraceletModel copyWith({SessionType? type, bool? isLeader}) {
    return CheckinBraceletModel(
      braceletId: braceletId,
      type: type ?? this.type,
      isLeader: isLeader ?? this.isLeader,
    );
  }
}
