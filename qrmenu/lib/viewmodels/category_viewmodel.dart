import 'package:flutter/material.dart';
import 'package:qrmenu/models/category_model.dart';
import 'package:qrmenu/services/api_service.dart';

class CategoryViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load categories from API
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _apiService.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
