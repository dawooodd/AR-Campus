import 'package:flutter/material.dart';
import 'screens/main_navigation.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Hunto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const MainNavigation(),
    );
  }
}
