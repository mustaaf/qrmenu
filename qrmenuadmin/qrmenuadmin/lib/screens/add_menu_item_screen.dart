import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/menu_provider.dart';
// Import dart:html conditionally for web
import 'dart:ui' as ui;
// This import is used for web platform only
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AddMenuItemScreen extends StatefulWidget {
  final String categoryId;

  const AddMenuItemScreen({super.key, required this.categoryId});

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  XFile? _selectedImageFile;
  final _picker = ImagePicker();
  // For web platform image preview
  String? _webImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    // Clean up any blob URLs to avoid memory leaks
    if (kIsWeb && _webImageUrl != null) {
      html.Url.revokeObjectUrl(_webImageUrl!);
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      print('Opening image picker...');
      final pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        // Specify lower quality and size for better handling
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        print('Image selected: ${pickedImage.name}, path: ${pickedImage.path}');

        setState(() {
          _selectedImageFile = pickedImage;

          // Create a preview URL for web platform
          if (kIsWeb) {
            _createWebImagePreview(pickedImage);
          }
        });
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  // Create a blob URL for web platform image preview
  void _createWebImagePreview(XFile file) async {
    if (kIsWeb) {
      try {
        // Read the file bytes
        final bytes = await file.readAsBytes();
        print('Web preview image bytes: ${bytes.length}');

        if (bytes.isEmpty) {
          print('Warning: Image data is empty');
          return;
        }

        // Get the file extension to determine MIME type
        final fileName = file.name.toLowerCase();
        String mimeType = 'image/jpeg'; // Default

        if (fileName.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (fileName.endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (fileName.endsWith('.webp')) {
          mimeType = 'image/webp';
        } else if (fileName.endsWith('.bmp')) {
          mimeType = 'image/bmp';
        } else {
          print('Warning: Unknown image format. Using default mime type.');
        }

        print('Using MIME type: $mimeType for file: ${file.name}');

        // Clean up previous URL if exists
        if (_webImageUrl != null) {
          html.Url.revokeObjectUrl(_webImageUrl!);
        }

        // Create a blob with explicit type
        final blob = html.Blob([bytes], mimeType);
        _webImageUrl = html.Url.createObjectUrlFromBlob(blob);

        if (_webImageUrl != null) {
          print('Web image URL created successfully: $_webImageUrl');
          setState(() {});
        } else {
          print('Failed to create image URL');
        }
      } catch (e) {
        print('Error in web preview: $e');
        // Try an alternative approach if the blob creation fails
        _createBase64ImagePreview(file);
      }
    }
  }

  // Alternative method using base64 data URL if blob doesn't work
  void _createBase64ImagePreview(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64 = html.window.btoa(String.fromCharCodes(bytes));
      final fileName = file.name.toLowerCase();
      String mimeType = 'image/jpeg';

      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      }

      _webImageUrl = 'data:$mimeType;base64,$base64';
      print('Created base64 data URL as fallback');
      setState(() {});
    } catch (e) {
      print('Error creating base64 image preview: $e');
    }
  }

  // Widget to display image based on platform
  Widget _buildImagePreview() {
    if (_selectedImageFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate, size: 50),
          SizedBox(height: 8),
          Text('Tap to select an image'),
        ],
      );
    }

    if (kIsWeb) {
      if (_webImageUrl != null) {
        print('Displaying web image from URL: $_webImageUrl');
        // For web, use the blob URL
        return ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.network(
            _webImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading web image: $error');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 40),
                    SizedBox(height: 8),
                    Text('Error loading image: $error'),
                  ],
                ),
              );
            },
          ),
        );
      } else {
        // If we don't have a URL yet, show loading indicator
        return const Center(child: CircularProgressIndicator());
      }
    } else {
      // For mobile platforms, use File
      return ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.file(
          File(_selectedImageFile!.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading mobile image: $error');
            return Center(child: Text('Error loading image: $error'));
          },
        ),
      );
    }
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImageFile == null) {
      // Show a warning if no image is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image for the menu item'),
          backgroundColor: Colors.orange,
        ),
      );
      // Continue anyway after warning
    }

    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    // Convert XFile to File only when sending to provider
    File? imageFile =
        _selectedImageFile != null && !kIsWeb
            ? File(_selectedImageFile!.path)
            : null;

    print('Saving menu item...');
    print('Image file: ${imageFile?.path ?? 'none'}');
    print('Web image file: ${_selectedImageFile?.name ?? 'none'}');

    // For web, we need to send the XFile directly
    final success = await menuProvider.addMenuItem(
      _nameController.text.trim(),
      _descriptionController.text.trim(),
      price,
      widget.categoryId,
      imageFile,
      kIsWeb ? _selectedImageFile : null, // Pass XFile for web
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu item added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Menu Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image selection
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: menuProvider.isLoading ? null : _saveMenuItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    menuProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                          'Save Menu Item',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
              if (menuProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    menuProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
