class Category {
  final String id;
  final String name;
  final String description;
  final String restaurantId;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    this.description =
        '', // Make description optional with a default empty string
    required this.restaurantId,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(), // Convert to string in case it's an integer
      name: json['name'],
      description: json['description'] ?? '', // Handle missing description
      restaurantId:
          json['restaurant_id'].toString(), // Match API's snake_case field name
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'restaurant_id': restaurantId, // Match API's snake_case field name
      'image_url': imageUrl,
    };
  }
}
