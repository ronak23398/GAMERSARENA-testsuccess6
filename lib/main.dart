import 'package:flutter/material.dart';
import 'package:gamers_gram/core/app_theme/app_theme.dart';
import 'package:gamers_gram/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://uedteqmekyqpoqtjcbdp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVlZHRlcW1la3lxcG9xdGpjYmRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI2NDMyMDMsImV4cCI6MjA0ODIxOTIwM30.pXJm_az4rPT8ijI-rfL9R7vrQNmSCiTP4km00lfSzt4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gaming Platform',
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      getPages: AppPages.routes,
    );
  }
}
