import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrmenu/routing/router.dart';
import 'package:qrmenu/viewmodels/category_viewmodel.dart';
import 'package:qrmenu/viewmodels/dish_viewmodel.dart';
import 'package:qrmenu/viewmodels/social_media_viewmodel.dart';
import 'package:qrmenu/config/theme.dart';

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
        ChangeNotifierProvider(create: (_) => SocialMediaViewModel()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'QR Restaurant Menu',
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
