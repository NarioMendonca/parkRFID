import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/comanda_model.dart';

class ComandaService {
  ComandaService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// Busca a comanda da sessão aberta da pulseira:
  /// `GET /bracelets/:uid/sessions` → sessão OPEN → `GET /sessions/:id/history`.
  Future<ComandaSessaoModel> buscarComandaPorUid(String uidRfid) async {
    try {
      final responseSessoes = await _dio.get('/bracelets/$uidRfid/sessions');
      final data = responseSessoes.data;
      final sessoes = data is Map && data['sessions'] is List
          ? (data['sessions'] as List).whereType<Map>().toList()
          : <Map>[];

      // A API já devolve da mais recente para a mais antiga.
      Map? sessaoAberta;
      for (final s in sessoes) {
        if (s['status'] == 'OPEN') {
          sessaoAberta = s;
          break;
        }
      }
      if (sessaoAberta == null) {
        throw Exception('Esta pulseira não possui nenhuma sessão ativa no momento.');
      }

      final responseHistorico = await _dio.get('/sessions/${sessaoAberta['id']}/history');
      final historico = responseHistorico.data;

      final session = historico is Map && historico['session'] is Map
          ? Map<String, dynamic>.from(historico['session'])
          : Map<String, dynamic>.from(sessaoAberta);
      final events = historico is Map && historico['events'] is List
          ? historico['events'] as List
          : const [];

      return ComandaSessaoModel.fromApi(session, events);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Pulseira não cadastrada no sistema.');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Sem conexão com o servidor. Verifique a rede e tente novamente.');
      }
      throw Exception('Erro ao conectar com o servidor. Tente novamente.');
    }
  }
}
