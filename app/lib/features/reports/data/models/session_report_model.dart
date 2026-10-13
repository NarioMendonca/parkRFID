class SessionReportModel {
  final int activeSessions;
  final int sessionsCreatedToday;

  SessionReportModel({
    required this.activeSessions,
    required this.sessionsCreatedToday,
  });

  factory SessionReportModel.fromJson(Map<String, dynamic> json) {
    return SessionReportModel(
      activeSessions: json['activeSessions'] ?? 0,
      sessionsCreatedToday: json['sessionsCreatedToday'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeSessions': activeSessions,
      'sessionsCreatedToday': sessionsCreatedToday,
    };
  }
}