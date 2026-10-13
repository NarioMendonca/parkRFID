class ConsumptionReportModel {
  final String date;
  final String total;

  ConsumptionReportModel({
    required this.date,
    required this.total,
  });

  factory ConsumptionReportModel.fromJson(Map<String, dynamic> json) {
    return ConsumptionReportModel(
      date: json['date'] ?? '',
      total: json['total'] ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'total': total,
    };
  }
}