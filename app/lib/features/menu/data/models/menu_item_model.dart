/// Item do cardápio, como a API devolve em `GET /menu`.
///
/// Atenção: no backend o campo de disponibilidade se chama `isAvaliable`
/// (com o erro de digitação). O model usa `isAvailable` no Dart e converte
/// no [MenuItemModel.fromJson] / [toJson].
class MenuItemModel {
  final String id;
  final String name;
  final String category;

  /// Preço como texto, igual à API (ex.: "12.50").
  final String price;
  final bool isAvailable;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.isAvailable = true,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      isAvailable: json['isAvaliable'] ?? true,
    );
  }

  /// Corpo esperado pela API em `PATCH /menu/:id`.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'isAvaliable': isAvailable,
    };
  }

  double get priceValue => double.tryParse(price) ?? 0;

  /// Ex.: "R$ 12,50".
  String get formattedPrice => 'R\$ ${priceValue.toStringAsFixed(2).replaceAll('.', ',')}';

  MenuItemModel copyWith({
    String? name,
    String? category,
    String? price,
    bool? isAvailable,
  }) {
    return MenuItemModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
