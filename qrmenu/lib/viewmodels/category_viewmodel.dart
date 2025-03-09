import 'package:flutter/material.dart';
import 'package:qrmenu/models/category_model.dart';
import 'package:qrmenu/services/api_service.dart';

class CategoryViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _currentRestaurantId = '';

  // Getters
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentRestaurantId => _currentRestaurantId;

  // Load categories from API
  Future<void> loadCategories(String restaurantId) async {
    if (_currentRestaurantId == restaurantId && _categories.isNotEmpty) return;

    _currentRestaurantId = restaurantId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _apiService.getCategories(restaurantId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
