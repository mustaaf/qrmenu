import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrmenu/config/theme.dart';
import 'package:qrmenu/models/dish_model.dart';
import 'package:qrmenu/models/category_model.dart';
import 'package:qrmenu/viewmodels/category_viewmodel.dart';
import 'package:qrmenu/viewmodels/dish_viewmodel.dart';
import 'package:go_router/go_router.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load dishes when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DishViewModel>().loadDishesByCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the category view model
    final categoryViewModel = Provider.of<CategoryViewModel>(context);

    // If categories haven't been loaded yet, load them
    if (categoryViewModel.categories.isEmpty &&
        !categoryViewModel.isLoading &&
        categoryViewModel.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        categoryViewModel.loadCategories();
      });

      // Show loading indicator while categories are being loaded
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If categories are loading
    if (categoryViewModel.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If there was an error loading categories
    if (categoryViewModel.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${categoryViewModel.error}'),
              ElevatedButton(
                onPressed: () => categoryViewModel.loadCategories(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Try to find the category by ID
    final category = categoryViewModel.categories.firstWhere(
      (cat) => cat.id == widget.categoryId,
      orElse: () => Category(id: widget.categoryId, name: 'Unknown Category'),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
        title: Text(category.name),
      ),
      body: Consumer<DishViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${viewModel.error}'),
                  ElevatedButton(
                    onPressed: () =>
                        viewModel.loadDishesByCategory(widget.categoryId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.dishes.isEmpty) {
            return const Center(
              child: Text('No dishes available in this category'),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Responsive
              final crossaxiscount = constraints.maxWidth > 600 ? 2 : 1;
              return _buildScreenLayout(viewModel.dishes, crossaxiscount);
            },
          );
        },
      ),
    );
  }

  Widget _buildScreenLayout(List<Dish> dishes, int crossAxisCount) {
    if (crossAxisCount == 2) {
      // Create balanced columns with roughly equal content
      final int halfLength = (dishes.length / 2).ceil();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First column
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < halfLength && i < dishes.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
                      child: _buildDishCard(dishes[i]),
                    ),
                ],
              ),
            ),

            // Second column
            Expanded(
              child: Column(
                children: [
                  for (int i = halfLength; i < dishes.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
                      child: _buildDishCard(dishes[i]),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // For narrow screens, use a simple list
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: dishes.length,
        itemBuilder: (context, index) {
          return _buildDishCard(dishes[index]);
        },
      );
    }
  }

  // Helper method to build a single dish card
  Widget _buildDishCard(Dish dish) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dish.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  dish.imageUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: Icon(Icons.fastfood, size: 50),
                  ),
                ),
              )
            else
              const SizedBox(
                width: double.infinity,
                height: 180,
                child: Icon(Icons.fastfood, size: 50),
              ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                dish.name,
                style: AppTheme.cardTitleStyle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dish.description,
              style: AppTheme.cardDescriptionStyle,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${dish.price.toStringAsFixed(2)}',
              style: AppTheme.cardPriceStyle,
            ),
          ],
        ),
      ),
    );
  }
}
