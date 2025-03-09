import 'package:dio/dio.dart';
import 'package:qrmenu/models/category_model.dart';
import 'package:qrmenu/models/dish_model.dart';
import 'package:qrmenu/models/settings_model.dart';

class ApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:3000';

  // Get all menu categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('$_baseUrl/categories');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // Get dishes by category
  Future<List<Dish>> getDishesByCategory(String categoryId) async {
    try {
      final response =
          await _dio.get('$_baseUrl/categories/$categoryId/dishes');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Dish.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load dishes');
      }
    } catch (e) {
      throw Exception('Error fetching dishes: $e');
    }
  }

  // Get social media information
  Future<Settings> getSocialMediaInfo() async {
    try {
      final response = await _dio.get('$_baseUrl/settings/social');

      if (response.statusCode == 200) {
        return Settings.fromJson(response.data);
      } else {
        throw Exception('Failed to load social media information');
      }
    } catch (e) {
      // Return empty object if API call fails
      return Settings();
    }
  }
}
