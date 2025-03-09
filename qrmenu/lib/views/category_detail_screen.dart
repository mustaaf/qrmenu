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
  final String restaurantId;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.restaurantId,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load dishes when the screen initializes with restaurant ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DishViewModel>().loadDishesByCategory(
            widget.restaurantId,
            widget.categoryId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the category view model
    final categoryViewModel = Provider.of<CategoryViewModel>(context);

    // Ensure categories are loaded
    if (categoryViewModel.categories.isEmpty &&
        categoryViewModel.currentRestaurantId != widget.restaurantId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        categoryViewModel.loadCategories(widget.restaurantId);
      });

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.go('/restaurant/${widget.restaurantId}');
            },
          ),
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
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
            context.go('/restaurant/${widget.restaurantId}');
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
                    onPressed: () => viewModel.loadDishesByCategory(
                        widget.restaurantId, widget.categoryId),
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
