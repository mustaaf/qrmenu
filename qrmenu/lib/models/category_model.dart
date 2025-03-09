class Category {
  final String id;
  final String name;
  final String? imageUrl;
  final String? description;

  Category({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? 'Unknown Category',
      imageUrl: json['imageUrl'],
      description: json['description'],
    );
  }
}
