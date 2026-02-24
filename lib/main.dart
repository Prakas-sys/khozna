import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme/app_theme.dart';
import 'utils/security_utils.dart';
import 'screens/login_screen.dart';
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
      home: FutureBuilder<Map<String, dynamic>>(
        future: _initApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.brandColor),
              ),
            );
          }

          if (snapshot.hasData) {
            final bool isCompromised = snapshot.data!['isCompromised'] ?? false;
            final bool isLocationGranted = snapshot.data!['isLocationGranted'] ?? false;

            if (isCompromised) {
              return _buildSecurityAlert(context);
            }

            return isLocationGranted ? const LoginScreen() : const LocationPermissionScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _initApp() async {
    // 1. Check for compromised device (Mr. Robot protection)
    bool isCompromised = await SecurityUtils.isDeviceCompromised();
    
    // 2. Check location permission
    final status = await Permission.location.status;
    
    return {
      'isCompromised': isCompromised,
      'isLocationGranted': status.isGranted,
    };
  }

  Widget _buildSecurityAlert(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                'Security Alert',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Khozna cannot run on this device because it appears to be rooted or jailbroken. '
                'To protect your data, the app will now close.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Close App', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
