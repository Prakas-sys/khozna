import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/location_permission_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const KhoznaApp());
}

class KhoznaApp extends StatelessWidget {
  const KhoznaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khozna',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LocationPermissionScreen(),
    );
  }
}
