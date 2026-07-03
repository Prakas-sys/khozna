import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:khozna/core/services/push_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:firebase_core/firebase_core.dart';
// firebase_auth import removed
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'core/security/security_utils.dart';
import 'core/utils/app_notifiers.dart';
import 'package:khozna/screens/main_screen.dart';
import 'core/guards/location_permission_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'widgets/khozna_error_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load environment variables for security
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('--- ERROR LOADING .ENV: $e ---');
  }

  // Allow runtime fetching only during boot preload — will be locked after fonts are cached.
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
  debugPrint('--- [PERF] Service Initialization Start ---');

  // Initialize Supabase immediately (Required blocking dependency)
  await supabase.Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  debugPrint('--- SUPABASE READY ---');

  // Run secondary initializations in background (Do NOT block splash screen)
  Future(() async {
    try {
      if (!kIsWeb) {
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

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        await PushNotificationService.initialize();
        debugPrint('--- FIREBASE SERVICES READY ---');
      } else {
        Firebase.initializeApp().timeout(const Duration(seconds: 2)).catchError((e) => null as dynamic);
      }
    } catch (e) {
      debugPrint('--- FIREBASE INITIALIZATION ERROR: $e ---');
    }
  });

  debugPrint('--- [PERF] Supabase Initialization Triggered ---');
}

class KhoznaApp extends StatefulWidget {
  const KhoznaApp({super.key});

  @override
  State<KhoznaApp> createState() => _KhoznaAppState();
}

class _KhoznaAppState extends State<KhoznaApp> {
  bool _isInitializing = true;
  bool _isLocationGranted = false;
  bool _isCompromised = false;
  supabase.Session? _session;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    debugPrint('--- _initApp START ---');

    // Start blocking service initialization (Supabase only)
    await _initializeServices();

    // Check pre-existing session immediately
    final currentSession = supabase.Supabase.instance.client.auth.currentSession;

    // Run font preloading and location status check, plus safety checks in parallel
    // We enforce a strict timeout on font preloading to avoid rendering layout shifts
    // while preventing lagging on slow connections.
    bool locationGranted = false;
    bool isCompromised = false;

    try {
      final results = await Future.wait([
        // 1. Check Location Status
        Permission.location.status.then((s) => s.isGranted),
        
        // 2. Preload ALL fonts used across the app, capped at 800ms to not block splash.
        GoogleFonts.pendingFonts([
          GoogleFonts.inter(),
          GoogleFonts.plusJakartaSans(),
          GoogleFonts.outfit(),
          GoogleFonts.zenAntiqueSoft(),
          GoogleFonts.montserrat(),
          GoogleFonts.poppins(),
          GoogleFonts.mukta(),
        ]).timeout(const Duration(milliseconds: 800)).then((_) {
          // Lock runtime fetching after preload — prevents FOUT on slow connections.
          GoogleFonts.config.allowRuntimeFetching = false;
          return true;
        }).catchError((_) => false),

        // 3. Perform compromise checks asynchronously with timeout (Capped at 80% of a second)
        SecurityUtils.isDeviceCompromised().timeout(const Duration(milliseconds: 800), onTimeout: () => false),
      ]);

      locationGranted = results[0];
      isCompromised = results[2];
    } catch (e) {
      debugPrint('Parallel boot tasks error: $e');
    }

    if (mounted) {
      setState(() {
        _session = currentSession;
        _isLocationGranted = locationGranted;
        _isCompromised = isCompromised;
        _isInitializing = false; // Instantly unblock splash screen removal
      });
    }

    // Trigger non-blocking data fetching preloads if user is logged in
    if (currentSession != null) {
      SupabaseService.fetchSavedPropertyIds();
      SupabaseService.fetchBookedPropertyIds();
      initializeBadgeSync();
      SupabaseService.fetchUnreadMessageCount();
      SupabaseService.fetchUnreadNotificationCount();
    }

    // Listen for Auth State changes to update internal state and initialize services reactively
    supabase.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (mounted) {
        setState(() {
          _session = session;
          _isInitializing = false;
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

    // 🛡️ SAFETY FALLBACK
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isInitializing) {
        debugPrint('--- [AUTH] Safety timeout: forcing _isInitializing=false ---');
        setState(() {
          _isInitializing = false;
        });
      }
    });

    debugPrint('--- _initApp END ---');
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompromised) {
      return const _CompromisedDeviceApp();
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
      home: RootScreen(
        isInitializing: _isInitializing,
        session: _session,
        isLocationGranted: _isLocationGranted,
      ),
    );
  }
}

/// A wrapper widget to serve as the root page of the home Navigator.
/// This prevents Flutter's Navigator from trapping the root route on dynamic type changes.
class RootScreen extends StatelessWidget {
  final bool isInitializing;
  final supabase.Session? session;
  final bool isLocationGranted;

  const RootScreen({
    super.key,
    required this.isInitializing,
    required this.session,
    required this.isLocationGranted,
  });

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return Container(color: Colors.white);
    }
    if (session != null) {
      return isLocationGranted
          ? const MainScreen()
          : const LocationPermissionScreen();
    }
    return const LoginScreen();
  }
}
