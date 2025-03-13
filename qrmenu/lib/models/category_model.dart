class Category {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final String? imageUrl;

  Category({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Handle different possible keys and formats for restaurant ID
    String restaurantId = '';
    if (json.containsKey('restaurant_id')) {
      restaurantId = json['restaurant_id'].toString();
    } else if (json.containsKey('restaurantId')) {
      restaurantId = json['restaurantId'].toString();
    } else if (json.containsKey('restaurantID')) {
      restaurantId = json['restaurantID'].toString();
    }

    return Category(
      id: json['id'].toString(),
      restaurantId: restaurantId,
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
    };
  }
}