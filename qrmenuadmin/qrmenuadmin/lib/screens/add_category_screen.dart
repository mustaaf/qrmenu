import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/menu_provider.dart';
// Import dart:html conditionally for web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  XFile? _selectedImageFile;
  final _picker = ImagePicker();
  String? _webImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    // Clean up blob URLs
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
          if (kIsWeb) {
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
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) return;

        final fileName = file.name.toLowerCase();
        String mimeType = 'image/jpeg';

        if (fileName.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (fileName.endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (fileName.endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        if (_webImageUrl != null) {
          html.Url.revokeObjectUrl(_webImageUrl!);
        }

        final blob = html.Blob([bytes], mimeType);
        _webImageUrl = html.Url.createObjectUrlFromBlob(blob);
        setState(() {});
      } catch (e) {
        print('Error creating web preview: $e');
      }
    }
  }

  // Build image preview widget
  Widget _buildImagePreview() {
    if (_selectedImageFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate, size: 50),
          SizedBox(height: 8),
          Text('Resim Seç (opsiyonel)'),
        ],
      );
    }

    if (kIsWeb) {
      if (_webImageUrl != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.network(
            _webImageUrl!,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, _) =>
                    Center(child: Text('Error loading image: $error')),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.file(File(_selectedImageFile!.path), fit: BoxFit.cover),
      );
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    // Convert XFile to File if needed (mobile only)
    File? imageFile =
        _selectedImageFile != null && !kIsWeb
            ? File(_selectedImageFile!.path)
            : null;

    // Call the modified addCategory method with image support
    final success = await menuProvider.addCategory(
      _nameController.text.trim(),
      imageFile: imageFile,
      webImageFile: kIsWeb ? _selectedImageFile : null,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Category')),
      body: Padding(
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
                  labelText: 'Kategori Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'kategori adı boş olamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: menuProvider.isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    menuProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Ekle', style: TextStyle(fontSize: 16)),
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
