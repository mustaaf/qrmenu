import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  String? _userId;
  String? _restaurantId;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userId => _userId;
  String? get restaurantId => _restaurantId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Base URL for the API
  final String _baseUrl = 'http://127.0.0.1:3000';

  // Constructor to check if a token exists in shared preferences
  AuthProvider() {
    _checkIfAuthenticated();
  }

  Future<void> _checkIfAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      _token = token;
      _userId = prefs.getString('user_id');
      _restaurantId = prefs.getString('restaurant_id');
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update these lines to match the backend response structure
        _token = responseData['token'];
        _userId = responseData['user']['id'].toString();
        _restaurantId = responseData['user']['restaurant_id'].toString();
        _isAuthenticated = true;

        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('jwt_token', _token!);
        prefs.setString('user_id', _userId!);
        prefs.setString('restaurant_id', _restaurantId!);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['message'] ?? 'Authentication failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (error) {
      print('Login error: $error'); // Add logging for debugging
      _errorMessage = 'Could not authenticate. Please try again later.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _restaurantId = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('jwt_token');
    prefs.remove('user_id');
    prefs.remove('restaurant_id');

    notifyListeners();
  }
}
