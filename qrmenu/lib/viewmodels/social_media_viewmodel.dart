import 'package:flutter/material.dart';
import 'package:qrmenu/models/settings_model.dart';
import 'package:qrmenu/services/api_service.dart';

class SocialMediaViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Settings _socialMedia = Settings();
  String _currentRestaurantId = '';
  bool _isLoading = false;

  Settings get socialMedia => _socialMedia;
  bool get isLoading => _isLoading;

  Future<void> loadSocialMediaInfo(String restaurantId) async {
    if (_currentRestaurantId == restaurantId &&
        _socialMedia.restaurantname != null) return;

    _currentRestaurantId = restaurantId;
    _isLoading = true;
    notifyListeners();

    try {
      _socialMedia = await _apiService.getSocialMediaInfo(restaurantId);
    } catch (e) {
      // Use default empty settings object
      _socialMedia = Settings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
