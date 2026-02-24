import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme/app_theme.dart';
import 'screens/location_permission_screen.dart';
import 'screens/login_screen.dart';

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
      home: FutureBuilder<PermissionStatus>(
        future: Permission.location.status,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.brandColor),
              ),
            );
          }
          final bool isLocationGranted = snapshot.data?.isGranted ?? false;
          return isLocationGranted ? const LoginScreen() : const LocationPermissionScreen();
        },
      ),
    );
  }
}
