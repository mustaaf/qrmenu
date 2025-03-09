import 'package:flutter/material.dart';
import 'package:qrmenu/models/dish_model.dart';
import 'package:qrmenu/services/api_service.dart';

class DishViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Dish> _dishes = [];
  bool _isLoading = false;
  String? _error;
  String _currentCategoryId = '';

  // Getters
  List<Dish> get dishes => _dishes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCategoryId => _currentCategoryId;

  // Load dishes by category from API
  Future<void> loadDishesByCategory(String categoryId) async {
    if (_currentCategoryId == categoryId && _dishes.isNotEmpty) return;

    _currentCategoryId = categoryId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dishes = await _apiService.getDishesByCategory(categoryId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
