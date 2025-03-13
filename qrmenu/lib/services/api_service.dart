import 'package:dio/dio.dart';
import 'package:qrmenu/models/category_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qrmenu/models/dish_model.dart';
import 'package:qrmenu/models/settings_model.dart';

class ApiService {
  late final Dio _dio;
  late final String _baseUrl;
  final bool _isWeb = kIsWeb;

  ApiService() {
    _dio = Dio();

    // Handle different environments with appropriate base URLs
    if (_isWeb) {
      // Web environment
      _baseUrl = 'http://localhost:3000';
    } else {
      // Check if you're using an emulator or physical device
      // You need to replace this with your computer's actual IP address when testing on a physical device
      _baseUrl = 'http://10.0.2.2:3000'; // Android emulator default

      // For iOS simulator, use: 'http://localhost:3000'
      // For physical devices, use your computer's IP: 'http://192.168.x.x:3000'
    }

    // Add logging interceptor to see detailed request/response information
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  // Get all menu categories for a specific restaurant
  Future<List<Category>> getCategories(String restaurantId) async {
    try {
      print(
          'Requesting categories from: $_baseUrl/restaurants/$restaurantId/categories');

      final response = await _dio.get(
        '$_baseUrl/restaurants/$restaurantId/categories',
        options: _isWeb
            ? null // Don't set timeouts on web platform
            : Options(
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('Categories data received: $data');
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        print('Error status code: ${response.statusCode}');
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Dio error type: ${e.type}');
      print('Dio error message: ${e.message}');
      print('Dio error response: ${e.response}');
      throw Exception('Network error fetching categories: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Error fetching categories: $e');
    }
  }

  // Get dishes by category for a specific restaurant
  Future<List<Dish>> getDishesByCategory(
      String restaurantId, String categoryId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/restaurants/$restaurantId/categories/$categoryId/dishes',
        options: _isWeb
            ? null
            : Options(
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
      );

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

  // Get social media information for a specific restaurant
  Future<Settings> getSocialMediaInfo(String restaurantId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/restaurants/$restaurantId/settings/social',
        options: _isWeb
            ? null
            : Options(
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
      );

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
