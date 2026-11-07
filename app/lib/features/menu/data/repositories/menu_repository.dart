import 'package:dio/dio.dart';

import '../models/menu_item_model.dart';

/// Acesso às rotas `/menu` da API.
class MenuRepository {
  final Dio _dio;

  MenuRepository(this._dio);

  /// Lista os itens. Sem [category], traz todos.
  Future<List<MenuItemModel>> fetchItems({String? category}) async {
    try {
      final response = await _dio.get(
        '/menu',
        queryParameters: category == null ? null : {'category': category},
      );
      final data = response.data;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((json) => MenuItemModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Erro ao carregar o cardápio.');
    }
  }

  Future<void> createItem({
    required String name,
    required String category,
    required String price,
    required bool isAvailable,
  }) async {
    try {
      await _dio.post('/menu', data: {
        'name': name,
        'category': category,
        'price': price,
        'isAvaliable': isAvailable,
      });
    } on DioException catch (e) {
      throw _handleError(e, 'Erro ao conectar com a API ao salvar item.');
    }
  }

  Future<void> updateItem(MenuItemModel item) async {
    try {
      await _dio.patch('/menu/${item.id}', data: item.toJson());
    } on DioException catch (e) {
      throw _handleError(e, 'Erro de conexão com a API.');
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      // Corpo vazio de propósito: o Fastify recusa DELETE com
      // Content-Type JSON e sem corpo.
      await _dio.delete('/menu/$id', data: {});
    } on DioException catch (e) {
      throw _handleError(e, 'Erro ao deletar item.');
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
