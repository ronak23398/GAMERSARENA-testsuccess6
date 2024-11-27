import 'package:flutter/material.dart';
import 'package:gamers_gram/appwrite.dart';
import 'package:gamers_gram/core/app_theme/app_theme.dart';
import 'package:gamers_gram/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AppwriteService.init(); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gaming Platform',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      getPages: AppPages.routes,
    );
  }
}
