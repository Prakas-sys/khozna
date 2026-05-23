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
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'core/security/security_utils.dart';
import 'core/utils/app_notifiers.dart';
import 'package:khozna/screens/main_screen.dart';
import 'core/guards/location_permission_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'widgets/khozna_error_screen.dart';
// import 'screens/splash_screen.dart'; // Removed

// Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handle Background Push Messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Try to update badge count if data is present
  try {
    if (message.data.containsKey('badge')) {
      int? badge = int.tryParse(message.data['badge'].toString());
      if (badge != null && badge > 0) {
        FlutterAppBadger.updateBadgeCount(badge);
      }
    }
  } catch (e) {
    debugPrint("Background badge error: $e");
  }

  debugPrint("Background message received: ${message.messageId}");
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

  // Initialize Firebase earlier to establish stable channel
  try {
    await Firebase.initializeApp();

    // 📈 Pass all unfiltered errors from the framework to Crashlytics.
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all errors within the platform (e.g. native crashes)
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint('--- FIREBASE CORE & OBSERVABILITY READY ---');
  } catch (e) {
    debugPrint('--- FIREBASE INIT ERROR: $e ---');
  }

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
                const Icon(
                  Icons.security_rounded,
                  color: Color(0xFF00A3E1),
                  size: 80,
                ),
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
  debugPrint('--- PARALLEL SERVICE INITIALIZATION START ---');

  // Staggered initialization for maximum stability on 6GB RAM systems
  await Future.delayed(const Duration(milliseconds: 150));
  await supabase.Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  debugPrint('--- SUPABASE READY ---');

  await Future.delayed(const Duration(milliseconds: 150));
  // Firebase Core is now pre-initialized in main()
  debugPrint('--- SETTING UP FIREBASE SERVICES ---');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  _setupNotifications();

  await Future.delayed(const Duration(milliseconds: 150));
  await GoogleFonts.pendingFonts([
    GoogleFonts.inter(),
    GoogleFonts.plusJakartaSans(),
    GoogleFonts.outfit(),
  ]).catchError((_) => []);

  debugPrint('--- PARALLEL INITIALIZATION COMPLETE ---');
}

Future<void> _setupNotifications() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  final token = await messaging.getToken();
  if (token != null) {
    await SupabaseService.saveDeviceToken(token);
  }
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final currentUserId =
        supabase.Supabase.instance.client.auth.currentUser?.id;
    final senderId = message.data['sender_id'];

    // 🛡️ SECURITY: Don't show notifications or increment badges for our own messages!
    if (senderId != null && senderId == currentUserId) {
      debugPrint('--- [PUSH] Ignoring self-sent message notification ---');
      return;
    }

    RemoteNotification? notification = message.notification;
    // Check if it's a chat message based on data payload
    final bool isChatMessage =
        message.data['table'] == 'messages' || message.data['type'] == 'chat';

    if (notification != null) {
      if (isChatMessage) {
        // Update the Messages tab badge
        messageBadgeCount.value += 1;
      } else {
        // Update the global notification badge
        notificationBadgeCount.value += 1;
      }
      int total = messageBadgeCount.value + notificationBadgeCount.value;
      _showLocalNotification(
        notification.title ?? '',
        notification.body ?? '',
        total,
      );
    }
  });
}

void _showLocalNotification(String title, String body, int badgeCount) async {
  // Update native badge explicitly as well
  FlutterAppBadger.updateBadgeCount(badgeCount);

  // FIX: Generate unique ID every time to prevent old ones from disappearing
  final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
    100000,
  );

  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        number:
            badgeCount, // This sets the badge/number on some Android launchers
        // FIX: Enable BigText so long messages aren't cut off
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Khozna Alert',
        ),
      );

  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    notificationId,
    title,
    body,
    platformChannelSpecifics,
  );
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
    await SupabaseService.fetchBookedPropertyIds(); // Fetch Booking Master Memory
    initializeBadgeSync();

    // Initial fetch of unread counts to populate badges immediately
    SupabaseService.fetchUnreadMessageCount();
    SupabaseService.fetchUnreadNotificationCount();

    // 🧹 AUTO-CLEAR RED BADGE ON OPEN - Reset internal counters only if needed
    debugPrint("Initializing badges on app open");
    // We don't want to force reset to 0 here because it might clear the launcher badge
    // before the fetchUnread... calls complete.
    // Instead, we let the fetch calls update the values.

    // Listen for Auth State changes to update internal state and initialize services
    supabase.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (mounted) {
        setState(() {
          _session = session;
          // When we get the initial session or a sign-in, we are no longer "initializing" the auth check
          if (event == supabase.AuthChangeEvent.initialSession ||
              event == supabase.AuthChangeEvent.signedIn) {
            _isInitializing = false;
          }
        });
      }

      if (event == supabase.AuthChangeEvent.signedIn ||
          event == supabase.AuthChangeEvent.initialSession ||
          event == supabase.AuthChangeEvent.tokenRefreshed) {
        debugPrint(
          '--- [AUTH] Session Sync: Event=$event. Initializing Realtime Listeners ---',
        );
        SupabaseService.initRealtimeListeners();
        SupabaseService.fetchSavedPropertyIds();
        SupabaseService.fetchBookedPropertyIds();
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

    // 🛡️ SAFETY FALLBACK: If onAuthStateChange hasn't fired 'initialSession'
    // within 5 seconds (e.g. very slow cold start), forcibly unblock the UI
    // using the currentSession snapshot already captured above. Without this,
    // the app would show a blank white screen indefinitely.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isInitializing) {
        debugPrint('--- [AUTH] Safety timeout: forcing _isInitializing=false ---');
        setState(() {
          _isInitializing = false;
          // _session already set above from currentSession snapshot
        });
      }
    });

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
        // 🛠️ CUSTOM ERROR BOUNDARY: Replace Red/Grey screen with Khozna Premium Error Screen
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return KhoznaErrorScreen(details: details);
        };

        // Remove native splash when the first real frame is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FlutterNativeSplash.remove();
        });
        return child!;
      },
      home: _isInitializing
          ? Container(color: Colors.white)
          : (_session != null
                ? (_isLocationGranted
                      ? const MainScreen()
                      : const LocationPermissionScreen())
                : const LoginScreen()),
    );
  }
}
