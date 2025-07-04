import 'package:flutter/material.dart';
import 'package:qrmenu/models/dish_model.dart';
import 'package:qrmenu/services/api_service.dart';

class DishViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Dish> _dishes = [];
  bool _isLoading = false;
  String? _error;
  String _currentCategoryId = '';
  String _currentRestaurantId = '';

  // Getters
  List<Dish> get dishes => _dishes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCategoryId => _currentCategoryId;
  String get currentRestaurantId => _currentRestaurantId;

  // Load dishes by category from API
  Future<void> loadDishesByCategory(
      String restaurantId, String categoryId) async {
    if (_currentRestaurantId == restaurantId &&
        _currentCategoryId == categoryId &&
        _dishes.isNotEmpty) return;

    _currentRestaurantId = restaurantId;
    _currentCategoryId = categoryId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dishes = await _apiService.getDishesByCategory(restaurantId, categoryId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
