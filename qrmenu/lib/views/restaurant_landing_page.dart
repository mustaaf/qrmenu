import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qrmenu/config/theme.dart';

class RestaurantLandingPage extends StatelessWidget {
  const RestaurantLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Restaurant Menu'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to QR Restaurant Menu',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Please scan a restaurant QR code to view their menu',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Demo purposes only - would be removed in production
            ElevatedButton(
              style: AppTheme.detailsButtonStyle,
              onPressed: () {
                // Navigate to a demo restaurant
                context.go('/restaurant/demo-restaurant');
              },
              child: const Text('Try Demo Restaurant'),
            ),
          ],
        ),
      ),
    );
  }
}
