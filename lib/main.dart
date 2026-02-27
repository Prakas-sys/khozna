import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'theme/app_theme.dart';
import 'utils/security_utils.dart';
import 'utils/supabase_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/location_permission_screen.dart';

// Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Handle Background Push Messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await supabase.Supabase.initialize(
    url: 'https://qjpeablwokiuhfaopdbi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqcGVhYmx3b2tpdWhmYW9wZGJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NjkxMjgsImV4cCI6MjA4NzE0NTEyOH0.Sz3K67ClV8ZfgCdabA_cFfh_wa6X-Q-fHylYJ8utTLI',
  );

  // Initialize Firebase (Requires google-services.json to be added manually)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _setupNotifications();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Pre-load fonts to prevent flickering
  GoogleFonts.config.allowRuntimeFetching = true;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const KhoznaApp());
}

Future<void> _setupNotifications() async {
  final messaging = FirebaseMessaging.instance;
  
  // Request Notification Permissions
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Get and Save Push Token
  final token = await messaging.getToken();
  if (token != null) {
    await SupabaseService.saveDeviceToken(token);
  }

  // Handle Foreground Messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _showLocalNotification(notification.title ?? '', notification.body ?? '');
    }
  });
}

void _showLocalNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('high_importance_channel', 'High Importance Notifications',
          importance: Importance.max, priority: Priority.high, showWhen: false);
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
}

class KhoznaApp extends StatelessWidget {
  const KhoznaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khozna',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.hasData && authSnapshot.data != null) {
            // Global Sync: Ensure Firebase user exists in Supabase Profiles
            SupabaseService.syncUserWithSupabase(authSnapshot.data!);
          }
          
          return FutureBuilder<Map<String, dynamic>>(
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

                // If logged in, go to MainScreen directly (skip login/location if already verified)
                if (authSnapshot.hasData && authSnapshot.data != null) {
                  return const MainScreen();
                }

                return isLocationGranted ? const LoginScreen() : const LocationPermissionScreen();
              }

              return const LoginScreen();
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _initApp() async {
    // 1. Check for compromised device (Mr. Robot protection)
    bool isCompromised = await SecurityUtils.isDeviceCompromised();
    
    // 2. Check location permission
    final status = await Permission.location.status;

    // 3. Pre-fetch the specific fonts used on the Login screen
    // This caches them before the Login screen is even built.
    await Future.wait([
      _loadFont(GoogleFonts.playfairDisplay().fontFamily),
      _loadFont(GoogleFonts.zenAntiqueSoft().fontFamily),
      _loadFont(GoogleFonts.outfit().fontFamily),
    ]);
    
    // Tiny extra delay to ensure rendering engine is ready
    await Future.delayed(const Duration(milliseconds: 200));
    
    return {
      'isCompromised': isCompromised,
      'isLocationGranted': status.isGranted,
    };
  }

  Future<void> _loadFont(String? fontFamily) async {
    if (fontFamily != null) {
      await FontLoader(fontFamily).load();
    }
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
