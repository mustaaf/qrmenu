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
    // Handle different price formats (string or number)
    double parsePrice() {
      final priceValue = json['price'];
      if (priceValue == null) return 0.0;

      if (priceValue is num) {
        return priceValue.toDouble();
      } else if (priceValue is String) {
        try {
          // Replace comma with dot if needed (for European number format)
          final normalizedPrice = priceValue.replaceAll(',', '.');
          return double.parse(normalizedPrice);
        } catch (e) {
          print('Error parsing price: $priceValue - $e');
          return 0.0; // Default value on error
        }
      }
      return 0.0; // Default value for other cases
    }

    // Handle ID that might be string or int
    int parseId() {
      final idValue = json['id'];
      if (idValue is int) return idValue;
      if (idValue is String) {
        try {
          return int.parse(idValue);
        } catch (_) {
          return 0;
        }
      }
      return 0;
    }

    return Dish(
      id: parseId(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parsePrice(),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      categoryId: json['categoryId']?.toString() ??
          json['category_id']?.toString() ??
          '',
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}
