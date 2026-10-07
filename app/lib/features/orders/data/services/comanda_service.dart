import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../models/comanda_model.dart';

class ComandaService {
  final Dio _dio = ApiClient.dio;

  Future<ComandaSessaoModel> buscarComandaPorUid(String uidRfid) async {
    try {

      final responseSessao = await _dio.get('/bracelets/$uidRfid/sessions');
      final List<dynamic> sessions = responseSessao.data['sessions'] ?? [];

      final sessaoAtiva = sessions.firstWhere(
            (s) => s['status'] == 'OPEN',
        orElse: () => null,
      );

      if (sessaoAtiva == null) {
        throw Exception('Esta pulseira não possui nenhuma sessão ativa no momento.');
      }

      final String sessionId = sessaoAtiva['id'];


      final responseHistory = await _dio.get('/sessions/$sessionId/history');
      final dataHistory = responseHistory.data;

      final sessionData = dataHistory['session'] ?? sessaoAtiva;
      final eventsList = dataHistory['events'] ?? [];

      return ComandaSessaoModel.fromApi(sessionData, eventsList);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Pulseira não cadastrada ou sem registros.');
      }
      throw Exception('Erro ao conectar com o servidor. Tente novamente.');
    } catch (e) {
      rethrow;
    }
  }
}