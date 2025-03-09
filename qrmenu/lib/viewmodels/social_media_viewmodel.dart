import 'package:flutter/material.dart';
import 'package:qrmenu/models/settings_model.dart';
import 'package:qrmenu/services/api_service.dart';

class SocialMediaViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Settings _socialMedia = Settings();
  bool _isLoading = false;
  String? _error;

  // Getters
  Settings get socialMedia => _socialMedia;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSocialLinks => _socialMedia.hasSocialLinks;

  // Load social media info from API
  Future<void> loadSocialMediaInfo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _socialMedia = await _apiService.getSocialMediaInfo();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
