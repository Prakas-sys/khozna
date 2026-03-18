import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Unused now
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'theme/app_theme.dart';
import 'utils/supabase_service.dart';
import 'screens/main_screen.dart';
import 'screens/location_permission_screen.dart';
// import 'screens/splash_screen.dart'; // Removed

// Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Handle Background Push Messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Pre-load fonts strategy (Non-blocking)
  GoogleFonts.config.allowRuntimeFetching = true;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const KhoznaApp());
}

/// New central initialization hub
Future<void> _initializeServices() async {
  debugPrint('--- SERVICE INITIALIZATION START ---');
  
  // 1. Supabase (Crucial)
  try {
    await supabase.Supabase.initialize(
      url: 'https://qjpeablwokiuhfaopdbi.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqcGVhYmx3b2tpdWhmYW9wZGJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NjkxMjgsImV4cCI6MjA4NzE0NTEyOH0.Sz3K67ClV8ZfgCdabA_cFfh_wa6X-Q-fHylYJ8utTLI',
    );
    debugPrint('--- SUPABASE INITIALIZED ---');
  } catch (e) {
    debugPrint('Supabase Error: $e');
  }

  // 2. Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('--- FIREBASE INITIALIZED ---');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _setupNotifications();
    debugPrint('--- NOTIFICATIONS SETUP COMPLETE ---');
  } catch (e) {
    debugPrint('Firebase Error: $e');
  }

  // 3. Fonts (Low priority)
  GoogleFonts.pendingFonts([
    GoogleFonts.outfit(),
    GoogleFonts.playfairDisplay(),
    GoogleFonts.zenAntiqueSoft(),
    GoogleFonts.montserrat(),
  ]).catchError((_) => []);

  debugPrint('--- SERVICE INITIALIZATION END ---');
}

Future<void> _setupNotifications() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  final token = await messaging.getToken();
  if (token != null) {
    await SupabaseService.saveDeviceToken(token);
  }
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

class KhoznaApp extends StatefulWidget {
  const KhoznaApp({super.key});

  @override
  State<KhoznaApp> createState() => _KhoznaAppState();
}

class _KhoznaAppState extends State<KhoznaApp> {
  bool _isInitializing = true;
  bool _isLocationGranted = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    debugPrint('--- _initApp START ---');
    
    // Start global service initialization
    await _initializeServices();
    
    // Check location permission
    try {
      final status = await Permission.location.status;
      _isLocationGranted = status.isGranted;
    } catch (e) {
      debugPrint('Location check error: $e');
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
    debugPrint('--- _initApp END ---');
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Container(color: Colors.white);
    }

    return MaterialApp(
      title: 'Khozna',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        // Remove native splash when the first real frame is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FlutterNativeSplash.remove();
        });
        return child!;
      },
      home: _isLocationGranted ? const MainScreen() : const LocationPermissionScreen(),
    );
  }

}
