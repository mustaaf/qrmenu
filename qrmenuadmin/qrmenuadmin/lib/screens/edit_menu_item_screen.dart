import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
// Import dart:html conditionally for web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class EditMenuItemScreen extends StatefulWidget {
  final MenuItem menuItem;
  final String categoryId;

  const EditMenuItemScreen({
    super.key,
    required this.menuItem,
    required this.categoryId,
  });

  @override
  State<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends State<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  File? _selectedImage;
  XFile? _selectedImageFile; // XFile for both web and mobile
  final _picker = ImagePicker();
  bool _imageChanged = false;
  String? _webImageUrl; // For web image preview

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menuItem.name);
    _descriptionController = TextEditingController(
      text: widget.menuItem.description,
    );
    _priceController = TextEditingController(
      text: widget.menuItem.price.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    // Clean up web resources
    if (kIsWeb && _webImageUrl != null) {
      html.Url.revokeObjectUrl(_webImageUrl!);
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImageFile = pickedImage;
          _imageChanged = true;

          // For mobile platforms, convert XFile to File
          if (!kIsWeb) {
            _selectedImage = File(pickedImage.path);
          } else {
            // For web, create preview URL
            _createWebImagePreview(pickedImage);
          }
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  // Create web image preview
  void _createWebImagePreview(XFile file) async {
    if (kIsWeb) {
      try {
        // Read the file bytes
        final bytes = await file.readAsBytes();

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
        }

        // Clean up previous URL if exists
        if (_webImageUrl != null) {
          html.Url.revokeObjectUrl(_webImageUrl!);
        }

        // Create a blob with explicit type
        final blob = html.Blob([bytes], mimeType);
        _webImageUrl = html.Url.createObjectUrlFromBlob(blob);

        setState(() {}); // Trigger rebuild for preview
      } catch (e) {
        print('Error creating web preview: $e');
      }
    }
  }

  // Build image preview widget based on state and platform
  Widget _buildImagePreview() {
    if (_imageChanged) {
      if (kIsWeb) {
        // Web platform with selected image
        if (_webImageUrl != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.network(
              _webImageUrl!,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 40),
                        SizedBox(height: 8),
                        Text('Error loading image: $error'),
                      ],
                    ),
                  ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      } else {
        // Mobile platform with selected image
        return ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, _) =>
                    Center(child: Text('Error loading image: $error')),
          ),
        );
      }
    } else if (widget.menuItem.imageUrl.isNotEmpty) {
      // Show existing image if available
      return ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network(
          widget.menuItem.imageUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (ctx, error, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.broken_image, size: 50),
                  SizedBox(height: 8),
                  Text('Image not available'),
                ],
              ),
        ),
      );
    } else {
      // No image case
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate, size: 50),
          SizedBox(height: 8),
          Text('Tap to select an image'),
        ],
      );
    }
  }

  Future<void> _updateMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    // Update the menu item with the appropriate parameters for web/mobile
    final success = await menuProvider.updateMenuItem(
      widget.menuItem.id,
      _nameController.text.trim(),
      _descriptionController.text.trim(),
      price,
      widget.categoryId,
      !kIsWeb && _imageChanged ? _selectedImage : null, // Mobile image file
      kIsWeb ? _selectedImageFile : null, // Web image file (XFile)
      _imageChanged, // Flag indicating image was changed
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün güncellendi'),
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
      appBar: AppBar(title: const Text('Edit Menu Item')),
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
                onPressed: menuProvider.isLoading ? null : _updateMenuItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    menuProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                          'Update Menu Item',
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
