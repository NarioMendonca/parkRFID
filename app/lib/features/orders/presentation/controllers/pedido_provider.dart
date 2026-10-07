
import 'package:flutter/material.dart';

class PedidoProvider extends ChangeNotifier {
  String? braceletId;
  String? mesa;
  final List<Map<String, dynamic>> _itensCarrinho = [];

  List<Map<String, dynamic>> get itensCarrinho => _itensCarrinho;


  void setBraceletId(String id) {
    braceletId = id;
    notifyListeners();
  }


  void setMesa(String numeroMesa) {
    mesa = numeroMesa;
    notifyListeners();
  }


  void adicionarItem(Map<String, dynamic> itemMenu) {
    final index = _itensCarrinho.indexWhere((item) => item['id'] == itemMenu['id']);

    if (index >= 0) {
      _itensCarrinho[index]['amount'] = (_itensCarrinho[index]['amount'] ?? 1) + 1;
    } else {
      _itensCarrinho.add({
        'id': itemMenu['id'],
        'name': itemMenu['name'],
        'price': itemMenu['price'],
        'amount': 1,
      });
    }
    notifyListeners();
  }


  void removerItem(String itemId) {
    final index = _itensCarrinho.indexWhere((item) => item['id'] == itemId);

    if (index >= 0) {
      if (_itensCarrinho[index]['amount'] > 1) {
        _itensCarrinho[index]['amount'] -= 1;
      } else {
        _itensCarrinho.removeAt(index);
      }
      notifyListeners();
    }
  }


  double get valorTotal {
    double total = 0.0;
    for (var item in _itensCarrinho) {
      final preco = double.tryParse(item['price'].toString()) ?? 0.0;
      final qtd = item['amount'] ?? 1;
      total += preco * qtd;
    }
    return total;
  }


  void limparTudo() {
    braceletId = null;
    mesa = null;
    _itensCarrinho.clear();
    notifyListeners();
  }
}