import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrmenu/routing/router.dart';
import 'package:qrmenu/viewmodels/category_viewmodel.dart';
import 'package:qrmenu/viewmodels/dish_viewmodel.dart';
import 'package:qrmenu/viewmodels/social_media_viewmodel.dart'; // Add this import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => DishViewModel()),
        ChangeNotifierProvider(
            create: (_) => SocialMediaViewModel()), // Add this provider
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'QR Restaurant Menu',
        theme: ThemeData(
          fontFamily: 'ViaodaLibre',
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          cardTheme: const CardTheme(
            color:
                Color(0xFF121212), // Slightly lighter than pure black for cards
          ),
          colorScheme: const ColorScheme.dark(
            surface: Colors.black,
            primary: Colors.white,
            onPrimary: Colors.black,
            secondary: Colors.white70,
            onSecondary: Colors.black,
            onSurface: Colors.white,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
            titleLarge: TextStyle(color: Colors.white),
            titleMedium: TextStyle(color: Colors.white),
            titleSmall: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
