import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qrmenu/views/home_screen.dart';
import 'package:qrmenu/views/category_detail_screen.dart';
import 'package:qrmenu/views/restaurant_landing_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RestaurantLandingPage(),
      ),
      GoRoute(
        path: '/restaurant/:restaurantId',
        builder: (context, state) {
          final restaurantId = state.pathParameters['restaurantId']!;
          return HomeScreen(restaurantId: restaurantId);
        },
      ),
      GoRoute(
        path: '/restaurant/:restaurantId/category/:id',
        builder: (context, state) {
          final categoryId = state.pathParameters['id']!;
          final restaurantId = state.pathParameters['restaurantId']!;
          return CategoryDetailScreen(
            categoryId: categoryId,
            restaurantId: restaurantId,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Text(
          'Page not found: ${state.error}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}
