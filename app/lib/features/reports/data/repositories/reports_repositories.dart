import 'package:dio/dio.dart';
import '../models/session_report_model.dart';
import '../models/consumption_report_model.dart';

class ReportsRepository {
  final Dio _dio;

  ReportsRepository(this._dio);

  Future<SessionReportModel> fetchSessionReport() async {
    try {
      final response = await _dio.get('/reports/sessions');
      return SessionReportModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Erro ao carregar relatório de sessões.');
    }
  }

  Future<ConsumptionReportModel> fetchConsumptionToday() async {
    try {
      final response = await _dio.get('/reports/consumption/today');
      return ConsumptionReportModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Erro ao carregar relatório de consumo de hoje.');
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