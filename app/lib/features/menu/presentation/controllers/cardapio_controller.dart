import 'package:flutter/foundation.dart';

import '../../data/models/menu_item_model.dart';
import '../../data/repositories/menu_repository.dart';


class CardapioController extends ChangeNotifier {
  CardapioController(this._repository);

  final MenuRepository _repository;
  bool _disposed = false;

  static const String todas = 'Todas';
  static const List<String> categorias = [todas, 'Bebidas', 'Comidas', 'Sobremesas'];

  List<MenuItemModel> _items = [];
  List<MenuItemModel> get items => List.unmodifiable(_items);

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isApiOffline = false;
  bool get isApiOffline => _isApiOffline;

  String _selectedCategory = todas;
  String get selectedCategory => _selectedCategory;


  Future<void> load() async {
    _isLoading = true;
    _isApiOffline = false;
    _notify();

    try {
      final fetched = await _repository.fetchItems(
        category: _selectedCategory == todas ? null : _selectedCategory,
      );
      _items = [...fetched];
      _isApiOffline = false;
    } catch (_) {
      _isApiOffline = true;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    load();
  }



  Future<String?> save({
    String? id,
    required String name,
    required String category,
    required String price,
    required bool isAvailable,
  }) async {
    _isLoading = true;
    _notify();
    try {
      if (id == null) {
        await _repository.createItem(
          name: name,
          category: category,
          price: price,
          isAvailable: isAvailable,
        );
      } else {
        await _repository.updateItem(MenuItemModel(
          id: id,
          name: name,
          category: category,
          price: price,
          isAvailable: isAvailable,
        ));
      }
      await load();
      return null;
    } catch (e) {
      _isLoading = false;
      _notify();
      return _message(e);
    }
  }


  Future<String?> toggleAvailability(MenuItemModel item, bool value) async {
    final index = _items.indexWhere((x) => x.id == item.id);
    if (index < 0) return null;

    final updated = item.copyWith(isAvailable: value);
    _items[index] = updated;
    _notify();

    try {
      await _repository.updateItem(updated);
      return null;
    } catch (e) {
      final i = _items.indexWhere((x) => x.id == item.id);
      if (i >= 0) _items[i] = item;
      _notify();
      return _message(e);
    }
  }

  Future<String?> delete(String id) async {
    _isLoading = true;
    _notify();
    try {
      await _repository.deleteItem(id);
      await load();
      return null;
    } catch (e) {
      _isLoading = false;
      _notify();
      return _message(e);
    }
  }


  static String _message(Object e) {
    final message = e.toString().replaceAll('Exception: ', '');
    return message.isEmpty ? 'Erro de conexão com a API.' : message;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
