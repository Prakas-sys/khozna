import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/offline_storage.dart';
import 'package:khozna/screens/main_screen.dart';
import 'package:khozna/features/auth/screens/register_screen.dart';
import 'package:khozna/features/auth/screens/verify_phone_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _agreeToTerms = true;
  bool _isLoading = false;
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final int _bossTaps = 0;
  bool _imagesPreloaded = false;

  // --- CAROUSEL ---
  final PageController _illustrationPageController = PageController();
  int _currentIllustrationPage = 0;
  Timer? _carouselTimer;
  final List<String> _illustrations = [
    'assets/images/boy illustrate  png.png',
    'assets/images/girl illustrate.png',
    'assets/images/man illustrate png.png',
  ];

  @override
  void initState() {
    super.initState();
    _startCarouselTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPreloaded) {
      _imagesPreloaded = true;
      // Preload all carousel images + logo so they appear instantly with no white flash
      for (final path in _illustrations) {
        precacheImage(AssetImage(path), context);
      }
      precacheImage(const AssetImage('assets/images/original_logo.png'), context);
    }
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final nextPage = (_currentIllustrationPage + 1) % _illustrations.length;
      _illustrationPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _illustrationPageController.dispose();
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please agree to terms to continue',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _phoneFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a phone number',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fullPhone = '+977$phone';

    setState(() => _isLoading = true);
    try {
      await supabase.Supabase.instance.client.auth.signInWithOtp(
        phone: fullPhone,
      );

      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyPhoneScreen(
              phoneNumber: fullPhone,
              verificationId: '', // Not needed for Supabase
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorPopup(e);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please agree to terms to continue',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // 1. Initialize Native Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      );

      // Removed forced signOut() to speed up login. 
      // If the user needs to switch accounts, they can do so via the picker (if it appears)
      // or using the 'Switch Account' feature in the Profile screen.
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw 'No ID Token found. Please ensure you have configured your Client IDs correctly in Google Cloud Console.';
      }

      // 2. Log in to Supabase using the Native Tokens
      await SupabaseService.signInWithGoogleNative(
        idToken: idToken,
        accessToken: accessToken,
      );

      // Persist login time for session freshness tracking
      await OfflineStorage.saveLastActiveTime();

      // 3. Stop loading and navigate
      if (mounted) {
        setState(() => _isLoading = false);
        // Pop all routes back to root — KhoznaApp's onAuthStateChange
        // listener will automatically rebuild home: to show MainScreen.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Google Login Error: $e');
      _showErrorPopup(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // More solid feel
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (!isKeyboardVisible) ...[
                      // --- TOP BAR ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: Image.asset(
                                'assets/images/original_logo.png',
                                height: 48,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MainScreen(),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandColor.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppTheme.brandColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 35),

                      // --- ILLUSTRATION CAROUSEL ---
                      SizedBox(
                        width: double.infinity,
                        height: constraints.maxHeight * 0.28,
                        child: PageView.builder(
                          controller: _illustrationPageController,
                          physics: const BouncingScrollPhysics(), // Smooth swipe with spring effect
                          onPageChanged: (index) {
                            setState(() => _currentIllustrationPage = index);
                          },
                          itemCount: _illustrations.length,
                          itemBuilder: (context, index) {
                            return Transform.translate(
                              offset: Offset(constraints.maxWidth * 0.05, 0), // Push slightly to the right to center illustration
                              child: Image.asset(
                                _illustrations[index],
                                fit: BoxFit.cover,
                                alignment: const Alignment(1.0, 1.0),
                                gaplessPlayback: true, // No white flash between slides
                              ),
                            );
                          },
                        ),
                      ),

                      // Dot Indicators (below image)
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _illustrations.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentIllustrationPage == index ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _currentIllustrationPage == index
                                  ? AppTheme.brandColor
                                  : Colors.grey.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      const SizedBox(height: 24),
                    ],

                    // --- WELCOME TEXT ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome Back To',
                            style: GoogleFonts.zenAntiqueSoft(
                              fontSize: 26.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1D1D1D).withOpacity(0.8),
                            ),
                          ),
                          Text(
                            'KHOZNA',
                            style: GoogleFonts.zenAntiqueSoft(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.brandColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Discover Rooms, Apartments and Villas Easily',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // --- INPUT ACTIONS ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Phone Input
                          Container(
                            height: 58,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🇳🇵',
                                  style: TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+977',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 1.2,
                                  height: 24,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter mobile number',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _agreeToTerms = !_agreeToTerms,
                                  ),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.6),
                                        width: 1.2,
                                      ),
                                      color: _agreeToTerms
                                          ? AppTheme.brandColor
                                          : Colors.white,
                                    ),
                                    child: _agreeToTerms
                                        ? const Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      children: [
                                        const TextSpan(
                                          text: 'I agree to terms of ',
                                        ),
                                        TextSpan(
                                          text: 'Service',
                                          style: TextStyle(
                                            color: AppTheme.brandColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            color: AppTheme.brandColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyPhone,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3.0,
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- FOOTER ---
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // OR Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.withOpacity(0.4),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'OR',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildSocialBtn(
                            'assets/icons/google_g.svg',
                            'Continue with Google',
                            _isLoading ? () {} : _signInWithGoogle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: "Don't have an account? ",
                                    ),
                                    TextSpan(
                                      text: 'Register Here',
                                      style: TextStyle(
                                        color: AppTheme.brandColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSocialBtn(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 56, // Increased height for a bigger look
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  0.6,
                ), // Semi-transparent for glass effect
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(icon, height: 24),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorPopup(dynamic error) {
    if (!mounted) return;

    // Parse the error message
    String title = 'Sign In Failed';
    String message = 'Something went wrong while signing in. Please try again.';
    String rawError = error.toString();
    IconData errorIcon = Icons.error_outline_rounded;
    Color primaryColor = const Color(0xFFEF4444); // Crimson/Red

    if (rawError.contains('ApiException: 7') || rawError.toLowerCase().contains('network_error')) {
      title = 'Network Connection Issue';
      message = 'We couldn\'t connect to Google services. Please verify:\n\n• Your device has a working internet connection.\n• Your phone\'s date & time settings are set to automatic.';
      errorIcon = Icons.wifi_off_rounded;
      primaryColor = const Color(0xFFF59E0B); // Amber
    } else if (rawError.contains('ApiException: 10') || rawError.toLowerCase().contains('developer_error')) {
      title = 'App Configuration Issue';
      message = 'Google sign-in is misconfigured (SHA-1 fingerprint mismatch). If you are a developer, please check your Firebase / Google Console settings.';
      errorIcon = Icons.build_rounded;
    } else if (rawError.contains('No ID Token found')) {
      title = 'Configuration Error';
      message = 'ID Token is missing. This usually means the Google client ID configured in the app does not match the server.';
      errorIcon = Icons.vpn_key_rounded;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  errorIcon,
                  color: primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Collapsible Raw Details for debugging
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    'Show technical details',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  iconColor: Colors.grey[500],
                  collapsedIconColor: Colors.grey[500],
                  childrenPadding: const EdgeInsets.only(top: 8, bottom: 16),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: SelectableText(
                        rawError,
                        style: GoogleFonts.firaCode(
                          fontSize: 11,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Dismiss Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
