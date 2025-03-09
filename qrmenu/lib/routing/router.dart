import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qrmenu/views/home_screen.dart';
import 'package:qrmenu/views/category_detail_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/category/:id',
        builder: (context, state) {
          final categoryId = state.pathParameters['id']!;
          return CategoryDetailScreen(categoryId: categoryId);
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
