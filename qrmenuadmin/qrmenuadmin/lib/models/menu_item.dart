class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final String restaurantId;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.restaurantId,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price']?.toString() ?? '0'),
      imageUrl: json['image_url'] ?? '',
      categoryId: json['category_id'].toString(),
      restaurantId: json['restaurant_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
      'restaurant_id': restaurantId,
    };
  }
}
