class ComandaItemModel {
  final String id;
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;
  final DateTime? date;

  ComandaItemModel({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.date,
  });

  factory ComandaItemModel.fromJson(Map<String, dynamic> json) {
    final qtd = json['quantity'] ?? json['qtd'] ?? 1;
    final unitPrice = _toDouble(json['price'] ?? json['unitPrice']);
    final totalCalculado = _toDouble(json['total']);

    return ComandaItemModel(
      id: json['id'] ?? '',
      description: json['description'] ?? json['name'] ?? json['title'] ?? 'Item sem nome',
      quantity: qtd is int ? qtd : int.tryParse(qtd.toString()) ?? 1,
      unitPrice: unitPrice,
      total: totalCalculado > 0 ? totalCalculado : (unitPrice * qtd),
      date: json['date'] != null || json['createdAt'] != null
          ? DateTime.tryParse(json['date'] ?? json['createdAt'])
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }
}

class ComandaSessaoModel {
  final String sessionId;
  final String braceletId;
  final double total;
  final DateTime? checkinDate;
  final List<ComandaItemModel> items;

  ComandaSessaoModel({
    required this.sessionId,
    required this.braceletId,
    required this.total,
    this.checkinDate,
    required this.items,
  });

  factory ComandaSessaoModel.fromApi(Map<String, dynamic> sessionJson, List<dynamic> eventsJson) {
    final rawTotal = sessionJson['total'];
    double totalParsed = 0.0;
    if (rawTotal is num) totalParsed = rawTotal.toDouble();
    if (rawTotal is String) totalParsed = double.tryParse(rawTotal.replaceAll(',', '.')) ?? 0.0;


    final itemsParsed = eventsJson
        .where((e) {
      final type = (e['type'] ?? '').toString().toUpperCase();
      return type != 'CHECKIN' && type != 'CHECKOUT';
    })
        .map((e) => ComandaItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ComandaSessaoModel(
      sessionId: sessionJson['id'] ?? '',
      braceletId: sessionJson['braceletId'] ?? '',
      total: totalParsed,
      checkinDate: sessionJson['checkinDate'] != null ? DateTime.tryParse(sessionJson['checkinDate']) : null,
      items: itemsParsed,
    );
  }
}