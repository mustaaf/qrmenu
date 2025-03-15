import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../models/category.dart';
import 'category_detail_screen.dart';
import 'add_category_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch categories when dashboard loads
    Future.delayed(Duration.zero, () {
      Provider.of<MenuProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategorileriniz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body:
          menuProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => menuProvider.fetchCategories(),
                child:
                    menuProvider.categories.isEmpty
                        ? const Center(child: Text('Henüz kategori eklenmedi.'))
                        : ListView.builder(
                          itemCount: menuProvider.categories.length,
                          itemBuilder:
                              (ctx, i) => CategoryCard(
                                category: menuProvider.categories[i],
                              ),
                        ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddCategoryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: ListTile(
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(category.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: 'Kateogriyi Sil',
            ),
            // Navigation icon
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CategoryDetailScreen(category: category),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text('kategori silmek istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('vazgeç'),
              ),
              TextButton(
                onPressed: () async {
                  // Önce silme işlemini gerçekleştir
                  final menuProvider = Provider.of<MenuProvider>(
                    context,
                    listen: false,
                  );

                  // İşlem bitmeden önce dialoğu kapatmıyoruz
                  // Navigator.of(ctx).pop();

                  // Silme işlemi sırasında bir loading göstergesi göster
                  showDialog(
                    context: ctx,
                    barrierDismissible: false,
                    builder:
                        (loadingContext) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  final success = await menuProvider.deleteCategory(
                    category.id,
                  );

                  // Şimdi loading dialoğunu kapat
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }

                  // Eğer başarısızsa, hata mesajını göster
                  if (!success &&
                      ctx.mounted &&
                      menuProvider.errorMessage != null) {
                    showDialog(
                      context: ctx,
                      builder:
                          (errorCtx) => AlertDialog(
                            title: const Text('Silme Hatası'),
                            content: Text(menuProvider.errorMessage!),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(
                                    errorCtx,
                                  ).pop(); // Hata dialoğunu kapat
                                  Navigator.of(
                                    ctx,
                                  ).pop(); // Orijinal onay dialoğunu kapat
                                },
                                child: const Text('Tamam'),
                              ),
                            ],
                          ),
                    );
                  } else if (ctx.mounted) {
                    // Başarılıysa sadece onay dialoğunu kapat
                    Navigator.of(ctx).pop();
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('sil'),
              ),
            ],
          ),
    );
  }
}
