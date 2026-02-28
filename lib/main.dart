import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
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
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  debugPrint('--- APP STARTING ---');
  
  await supabase.Supabase.initialize(
    url: 'https://qjpeablwokiuhfaopdbi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqcGVhYmx3b2tpdWhmYW9wZGJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NjkxMjgsImV4cCI6MjA4NzE0NTEyOH0.Sz3K67ClV8ZfgCdabA_cFfh_wa6X-Q-fHylYJ8utTLI',
  );
  debugPrint('--- SUPABASE INITIALIZED ---');

  // Initialize Firebase
  try {
    debugPrint('--- INITIALIZING FIREBASE ---');
    await Firebase.initializeApp();
    debugPrint('--- FIREBASE INITIALIZED ---');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _setupNotifications();
    debugPrint('--- NOTIFICATIONS SETUP COMPLETE ---');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Pre-load fonts to prevent flickering
  GoogleFonts.config.allowRuntimeFetching = true;
  // Start pre-fetching key fonts
  Future.wait([
    GoogleFonts.pendingFonts([
      GoogleFonts.outfit(),
      GoogleFonts.playfairDisplay(),
      GoogleFonts.zenAntiqueSoft(),
    ]),
  ]);

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
  bool _isCompromised = false;
  bool _isLocationGranted = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    debugPrint('--- _initApp START ---');
    
    // 1. Skip security check for now
    _isCompromised = false;
    
    // 2. Fast Check location
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
      return Container(color: Colors.white); // Keep splash or white while initializing
    }

    if (_isCompromised) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _buildSecurityAlert(context),
      );
    }

    return MaterialApp(
      title: 'Khozna',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        // Remove splash once the first frame of the authenticated/unauthenticated screen is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FlutterNativeSplash.remove();
        });
        return child!;
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If auth state is initializing, show nothing or splash (it's still visible)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.brandColor)));
          }

          final User? user = snapshot.data;
          
          if (user != null) {
            // User is logged in
            SupabaseService.syncUserWithSupabase(user);
            return const MainScreen();
          } else {
            // User is NOT logged in
            return _isLocationGranted ? const LoginScreen() : const LocationPermissionScreen();
          }
        },
      ),
    );
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
