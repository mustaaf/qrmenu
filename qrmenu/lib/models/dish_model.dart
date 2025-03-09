class Dish {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String categoryId;
  final bool isAvailable;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.categoryId,
    this.isAvailable = true,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'],
      categoryId: json['categoryId'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}
