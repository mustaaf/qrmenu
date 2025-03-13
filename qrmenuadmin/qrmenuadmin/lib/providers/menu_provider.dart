import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category.dart';
import '../models/menu_item.dart';

class MenuProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => [..._categories];
  List<MenuItem> get menuItems => [..._menuItems];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Base URL for the API
  final String _baseUrl = 'http://127.0.0.1:3000';

  // Get JWT token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Get restaurant ID from shared preferences
  Future<String?> _getRestaurantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('restaurant_id');
  }

  // Fetch all categories for the restaurant
  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final restaurantId = await _getRestaurantId();

      if (token == null || restaurantId == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/restaurants/$restaurantId/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> categoriesData = json.decode(response.body);
        _categories =
            categoriesData
                .map((categoryData) => Category.fromJson(categoryData))
                .toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to load categories';
        _isLoading = false;
        notifyListeners();
      }
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all menu items for a specific category
  Future<void> fetchMenuItems(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final restaurantId = await _getRestaurantId();

      if (token == null || restaurantId == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/restaurants/$restaurantId/categories/$categoryId/dishes',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> menuItemsData = json.decode(response.body);
        _menuItems =
            menuItemsData
                .map((menuItemData) => MenuItem.fromJson(menuItemData))
                .toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to load menu items';
        _isLoading = false;
        notifyListeners();
      }
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new category (with optional image support)
  Future<bool> addCategory(
    String name, {
    File? imageFile,
    XFile? webImageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final restaurantId = await _getRestaurantId();

      if (token == null || restaurantId == null) {
        throw Exception('Not authenticated');
      }

      // WEB PLATFORM - Handle image upload
      if (kIsWeb && webImageFile != null) {
        try {
          // Read image bytes
          final bytes = await webImageFile.readAsBytes();
          if (bytes.isEmpty) {
            throw Exception('Image bytes are empty');
          }

          // Convert to base64
          final base64Image = base64Encode(bytes);

          // Determine file extension
          final fileName = webImageFile.name.toLowerCase();
          String fileExtension = 'jpeg';

          if (fileName.endsWith('.png')) {
            fileExtension = 'png';
          } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
            fileExtension = 'jpeg';
          } else if (fileName.endsWith('.gif')) {
            fileExtension = 'gif';
          } else if (fileName.endsWith('.webp')) {
            fileExtension = 'webp';
          }

          // URL pattern for the image
          final imageUrlPattern =
              '/uploads/categories/$restaurantId/{id}.$fileExtension';

          // JSON payload with base64 image
          final payload = {
            'name': name,
            'imageUrlPattern': imageUrlPattern,
            'imageBase64': base64Image,
            'fileName': webImageFile.name,
            'fileExtension': fileExtension,
          };

          final response = await http.post(
            Uri.parse('$_baseUrl/restaurants/$restaurantId/categories'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          );

          print(
            'Web category add request sent. Status: ${response.statusCode}',
          );

          if (response.statusCode == 201) {
            await fetchCategories(); // Refresh categories
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            _errorMessage =
                'Failed to add category: ${response.statusCode} - ${response.body}';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (e) {
          print('Error in category web upload: $e');
          throw Exception('Failed to process category image: $e');
        }
      }
      // MOBILE PLATFORM - Handle image upload with MultipartRequest
      else if (imageFile != null) {
        final uri = Uri.parse('$_baseUrl/restaurants/$restaurantId/categories');
        var request = http.MultipartRequest('POST', uri);

        // Add headers and fields
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['name'] = name;

        // Add image file
        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();
        final fileName = imageFile.path.split('/').last;

        final multipartFile = http.MultipartFile(
          'image',
          fileStream,
          fileLength,
          filename: fileName,
          contentType: MediaType('image', _getImageMimeType(fileName)),
        );

        request.files.add(multipartFile);

        // Send request
        final streamResponse = await request.send();
        final response = await http.Response.fromStream(streamResponse);

        print(
          'Mobile category add request sent. Status: ${response.statusCode}',
        );

        if (response.statusCode == 201) {
          await fetchCategories();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage =
              'Failed to add category: ${response.statusCode} - ${response.body}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      // NO IMAGE CASE - Simple JSON request
      else {
        final response = await http.post(
          Uri.parse('$_baseUrl/restaurants/$restaurantId/categories'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'name': name}),
        );

        print(
          'Simple category add request sent. Status: ${response.statusCode}',
        );

        if (response.statusCode == 201) {
          await fetchCategories();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage =
              'Failed to add category: ${response.statusCode} - ${response.body}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add a new menu item with image upload
  Future<bool> addMenuItem(
    String name,
    String description,
    double price,
    String categoryId,
    File? imageFile,
    XFile? webImageFile,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final restaurantId = await _getRestaurantId();

      if (token == null || restaurantId == null) {
        throw Exception('Not authenticated');
      }

      // WEB PLATFORM SOLUTION
      if (kIsWeb && webImageFile != null) {
        print('WEB PLATFORM: Using direct approach');

        try {
          // Read image bytes
          final bytes = await webImageFile.readAsBytes();
          if (bytes.isEmpty) {
            throw Exception('Image bytes are empty');
          }

          print('Image size: ${bytes.length} bytes');

          // Convert to base64 for simpler transport
          final base64Image = base64Encode(bytes);

          // Extract file extension
          final fileName = webImageFile.name.toLowerCase();
          String fileExtension = 'jpeg';

          if (fileName.endsWith('.png')) {
            fileExtension = 'png';
          } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
            fileExtension = 'jpeg';
          } else if (fileName.endsWith('.gif')) {
            fileExtension = 'gif';
          } else if (fileName.endsWith('.webp')) {
            fileExtension = 'webp';
          }

          // Önce dish'i imageUrlPattern ile gönder
          final imageUrlPattern =
              '/uploads/$restaurantId/$categoryId/{id}.$fileExtension';

          // Create JSON payload with the base64 image
          final payload = {
            'name': name,
            'description': description,
            'price': price,
            'categoryId': categoryId,
            'restaurantId': restaurantId,
            'imageUrlPattern':
                imageUrlPattern, // {id} parametresi ile şablon gönderiyoruz
            'imageBase64': base64Image,
            'fileName': webImageFile.name,
            'fileExtension': fileExtension,
          };

          // Make the request
          final response = await http.post(
            Uri.parse(
              '$_baseUrl/restaurants/$restaurantId/categories/$categoryId/dishes',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          );

          print('Web request sent. Status: ${response.statusCode}');
          print('Response: ${response.body}');

          if (response.statusCode == 201) {
            // Yanıttan yeni oluşturulan dish'in bilgilerini al
            final responseData = json.decode(response.body);
            final dishId = responseData['id']; // Burada dish ID'yi alıyoruz

            print('Created dish with ID: $dishId');

            await fetchMenuItems(categoryId);
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            _errorMessage =
                'Web upload failed: ${response.statusCode} - ${response.body}';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (e) {
          print('Error in web file upload: $e');
          throw Exception('Failed to process web image: $e');
        }
      }
      // MOBILE PLATFORM SOLUTION
      else if (imageFile != null) {
        print('MOBILE PLATFORM: Using multipart request');

        final uri = Uri.parse(
          '$_baseUrl/restaurants/$restaurantId/categories/$categoryId/dishes',
        );
        var request = http.MultipartRequest('POST', uri);

        // Add auth header
        request.headers['Authorization'] = 'Bearer $token';

        // Add text fields
        request.fields['name'] = name;
        request.fields['description'] = description;
        request.fields['price'] = price.toString();
        request.fields['categoryId'] = categoryId;
        request.fields['restaurantId'] = restaurantId;

        // Add the image file
        if (!imageFile.existsSync()) {
          throw Exception('Image file does not exist: ${imageFile.path}');
        }

        // Get file details
        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();
        final fileName = imageFile.path.split('/').last;

        // Create multipart file
        final multipartFile = http.MultipartFile(
          'image',
          fileStream,
          fileLength,
          filename: fileName,
          contentType: MediaType('image', _getImageMimeType(fileName)),
        );

        // Add to request
        request.files.add(multipartFile);

        // Send request
        print('Sending mobile multipart request...');
        final streamResponse = await request.send();
        final response = await http.Response.fromStream(streamResponse);

        print('Mobile request sent. Status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 201) {
          await fetchMenuItems(categoryId);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage =
              'Failed to add menu item: ${response.statusCode} - ${response.body}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      // NO IMAGE CASE
      else {
        final response = await http.post(
          Uri.parse(
            '$_baseUrl/restaurants/$restaurantId/categories/$categoryId/dishes',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': name,
            'description': description,
            'price': price,
          }),
        );

        // For debugging - print the request body
        print(
          'Sending JSON request with body: ${json.encode({'name': name, 'description': description, 'price': price})}',
        );

        if (response.statusCode == 201) {
          await fetchMenuItems(categoryId); // Refresh menu items
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage =
              'Failed to add menu item: ${response.statusCode} - ${response.body}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
    } catch (error) {
      _errorMessage = error.toString();
      print('Error in addMenuItem: $error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper method to determine the MIME type from filename
  String _getImageMimeType(String filename) {
    filename = filename.toLowerCase();
    if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) {
      return 'jpeg';
    } else if (filename.endsWith('.png')) {
      return 'png';
    } else if (filename.endsWith('.gif')) {
      return 'gif';
    } else if (filename.endsWith('.webp')) {
      return 'webp';
    } else if (filename.endsWith('.bmp')) {
      return 'bmp';
    } else {
      // Default to jpeg if can't determine
      return 'jpeg';
    }
  }

  // Update existing menu item
  Future<bool> updateMenuItem(
    String id,
    String name,
    String description,
    double price,
    String categoryId,
    File? imageFile,
    bool imageChanged,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final restaurantId = await _getRestaurantId();

      if (token == null || restaurantId == null) {
        throw Exception('Not authenticated');
      }

      final apiUrl = Uri.parse(
        '$_baseUrl/restaurants/$restaurantId/categories/$categoryId/dishes/$id',
      );

      // Use different request methods based on whether the image changed
      http.Response response;

      if (imageChanged && imageFile != null) {
        // Use MultipartRequest when uploading a new image
        var request = http.MultipartRequest('PUT', apiUrl);

        // Add headers
        request.headers.addAll({'Authorization': 'Bearer $token'});

        // Add text fields
        request.fields['name'] = name;
        request.fields['description'] = description;
        request.fields['price'] = price.toString();
        request.fields['categoryId'] = categoryId;
        request.fields['restaurantId'] = restaurantId;

        // Add image file
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );

        // Send request
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Use regular PUT request with JSON body when not changing the image
        response = await http.put(
          apiUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': name,
            'description': description,
            'price': price,
            'categoryId': categoryId,
            'restaurantId': restaurantId,
            'keepExistingImage':
                true, // Tell backend to keep the existing image
          }),
        );
      }

      if (response.statusCode == 200) {
        await fetchMenuItems(categoryId); // Refresh menu items
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            'Failed to update menu item: ${response.statusCode} - ${response.body}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete menu item
  Future<bool> deleteMenuItem(String id, String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final restaurantId = await _getRestaurantId();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse(
          '$_baseUrl/restaurants/$restaurantId/categories/$categoryId/dishes/$id',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchMenuItems(categoryId); // Refresh menu items
        return true;
      } else {
        _errorMessage = 'Failed to delete menu item';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final restaurantId = await _getRestaurantId();

      if (token == null || restaurantId == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/restaurants/$restaurantId/categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchCategories(); // Refresh categories list
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            'Failed to delete category: ${response.statusCode} - ${response.body}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
