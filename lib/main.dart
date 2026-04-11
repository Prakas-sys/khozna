import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:firebase_core/firebase_core.dart';
// firebase_auth import removed
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'theme/app_theme.dart';
import 'utils/supabase_service.dart';
import 'utils/security_utils.dart';
import 'utils/app_notifiers.dart';
import 'screens/main_screen.dart';
import 'screens/location_permission_screen.dart';
import 'screens/login_screen.dart';
// import 'screens/splash_screen.dart'; // Removed

// Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Handle Background Push Messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // 🔥 RED BADGE IN BACKGROUND - Temporarily disabled due to Android build incompatibility
  if (message.notification != null) {
    debugPrint("Background notification received: ${message.notification?.title}");
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Load environment variables for security
  try {
    await dotenv.load(fileName: ".env");
    if (kDebugMode) debugPrint("--- .ENV LOADED SUCCESSFULLY ---");
  } catch (e) {
    if (kDebugMode) debugPrint("--- ERROR LOADING .ENV: $e ---");
  }

  // 🔐 SECURITY: Block rooted/jailbroken devices
  final bool isCompromised = await SecurityUtils.isDeviceCompromised();
  if (isCompromised) {
    runApp(const _CompromisedDeviceApp());
    return;
  }

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

/// Shown when device is rooted/jailbroken — blocks app from running
class _CompromisedDeviceApp extends StatelessWidget {
  const _CompromisedDeviceApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security_rounded, color: Color(0xFF00A3E1), size: 80),
                const SizedBox(height: 24),
                Text(
                  'Security Alert',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Khozna cannot run on rooted or compromised devices to protect your data.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// New central initialization hub
Future<void> _initializeServices() async {
  debugPrint('--- SERVICE INITIALIZATION START ---');
  
  // 1. Supabase (Crucial)
  try {
    await supabase.Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
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
    GoogleFonts.inter(),
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
    // Check if it's a chat message based on data payload
    final bool isChatMessage = message.data['table'] == 'messages' || message.data['type'] == 'chat';

    if (notification != null) {
      if (isChatMessage) {
        // Update the Messages tab badge
        messageBadgeCount.value += 1;
      } else {
        // Update the global notification badge
        notificationBadgeCount.value += 1;
      }
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
  supabase.Session? _session;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    debugPrint('--- _initApp START ---');
    
    // Start global service initialization
    await _initializeServices();
    await SupabaseService.fetchSavedPropertyIds(); // Fetch Master Memory IDs
    initializeBadgeSync();
    
    // 🧹 AUTO-CLEAR RED BADGE ON OPEN - Temporarily disabled due to Android build incompatibility
    debugPrint("Auto-clearing badges on app open");
    notificationBadgeCount.value = 0; // Reset internal counter

    // Listen for Auth State changes to update internal state and initialize services
    supabase.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (mounted) {
        setState(() {
          _session = session;
          // When we get the initial session or a sign-in, we are no longer "initializing" the auth check
          if (event == supabase.AuthChangeEvent.initialSession || event == supabase.AuthChangeEvent.signedIn) {
            _isInitializing = false;
          }
        });
      }

      if (event == supabase.AuthChangeEvent.signedIn || 
          event == supabase.AuthChangeEvent.initialSession || 
          event == supabase.AuthChangeEvent.tokenRefreshed) {
        debugPrint('--- [AUTH] Session Sync: Event=$event. Initializing Realtime Listeners ---');
        SupabaseService.initRealtimeListeners();
        SupabaseService.fetchSavedPropertyIds();
      }
      
      if (event == supabase.AuthChangeEvent.signedOut) {
        debugPrint('--- [AUTH] User Signed Out ---');
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
      }
    });

    // Capture current session immediately if available
    _session = supabase.Supabase.instance.client.auth.currentSession;

    // Initial check is handled by the onAuthStateChange.initialSession listener above
    // No need to call manually here as it would double-initialize
    
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
      home: _isInitializing 
          ? Container(color: Colors.white)
          : (_session != null 
              ? (_isLocationGranted ? const MainScreen() : const LocationPermissionScreen())
              : const LoginScreen()),
    );
  }

}
