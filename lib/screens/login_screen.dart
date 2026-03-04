import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/security_utils.dart';
import 'main_screen.dart';
import 'register_screen.dart';
import 'verify_phone_screen.dart';
import 'owner_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _agreeToTerms = false;
  bool _isLoading = false;
  final PageController _pageController = PageController();
  int _currentIllustration = 0;
  final TextEditingController _phoneController = TextEditingController();
  int _bossTaps = 0;

  final List<String> _illustrations = [
    'assets/images/illustrate of login screen.png',
    'assets/images/boy illustrate  png.png',
    'assets/images/man illustrate png.png',
  ];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SecurityUtils.setSecure(true);
    _startAutoSwipe();
  }

  void _startAutoSwipe() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextScene = (_currentIllustration + 1) % _illustrations.length;
        _pageController.animateToPage(nextScene, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    SecurityUtils.setSecure(false);
    _timer?.cancel();
    _pageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleBossTap() {
    _bossTaps++;
    if (_bossTaps >= 5) {
      _bossTaps = 0;
      _showBossLogin();
    }
  }

  void _showBossLogin() {
    final bossPhone = TextEditingController();
    final bossPass = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Owner Access', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bossPhone, decoration: const InputDecoration(labelText: 'Admin ID'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: bossPass, decoration: const InputDecoration(labelText: 'Secret Key'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: [Color(0xFF00B4F5), AppTheme.brandColor]),
            ),
            child: ElevatedButton(
              onPressed: () {
                if (bossPhone.text == '9705278379' && bossPass.text == 'Khozna@Success') {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Credentials')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              child: const Text('Unlock Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPhone() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please agree to terms to continue', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid phone number', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _isLoading = true);
    final fullPhone = '+977$phone';
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: ${e.message}', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyPhoneScreen(phoneNumber: fullPhone, verificationId: verificationId)));
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _signInWithFacebook() async {
    if (!_agreeToTerms) return;
    setState(() => _isLoading = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login(permissions: ['public_profile', 'email']);
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.token);
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) {
          await SupabaseService.syncUserWithSupabase(userCredential.user!);
          if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _signInWithGoogle() async {
    if (!_agreeToTerms) return;
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) { setState(() => _isLoading = false); return; }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        await SupabaseService.syncUserWithSupabase(userCredential.user!);
        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
      }
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final double screenH = MediaQuery.of(context).size.height;
    final double statusH = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black, // Dark foundation for mesh depth
      body: Stack(
        children: [
          // 1. Premium Mesh Background
          _buildMeshBackground(),

          SafeArea(
            child: Column(
              children: [
                // 2. Illustration Area (37%)
                _buildIllustrationArea(statusH),

                // 3. Form Area (63%) with Glassmorphism
                _buildFormArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0056D2), // Deep Corporate Blue
            Color(0xFF002B6B), // Midnight Blue
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _blurCircle(400, const Color(0xFF00B4F4).withOpacity(0.35)),
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: _blurCircle(600, AppTheme.brandColor.withOpacity(0.25)),
          ),
          Positioned(
            top: screenHeight(context) * 0.4,
            right: -50,
            child: _blurCircle(250, const Color(0xFF673AB7).withOpacity(0.15)),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildIllustrationArea(double statusH) {
    return Expanded(
      flex: 37,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _illustrations.length,
            onPageChanged: (i) => setState(() => _currentIllustration = i),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.fromLTRB(28, 48, 28, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(_illustrations[index], fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Header Logo & Skip
          Positioned(
            top: 12,
            left: 28,
            right: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _handleBossTap,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset('assets/images/original logo.png', height: 32),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MainScreen())),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Text(
                          'Skip Now',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Indicators
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_illustrations.length, (index) {
                final bool isSelected = index == _currentIllustration;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormArea() {
    return Expanded(
      flex: 63,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(36, 12, 36, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top: Branding Section
                          Column(
                            children: [
                              Container(
                                width: 45,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Experience',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[500],
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'KHOZNA',
                                style: GoogleFonts.zenAntiqueSoft(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.brandColor,
                                  letterSpacing: 8.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Premium Rental Market Nepal',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),

                          // Middle: The Vault Phone Input & Action
                          Column(
                            children: [
                              // Glass-Inset Phone Input
                              Container(
                                height: 62,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        children: [
                                          const Text('\uD83C\uDDF3\uD83C\uDDF5', style: TextStyle(fontSize: 22)),
                                          const SizedBox(width: 10),
                                          Text(
                                            '+977',
                                            style: GoogleFonts.outfit(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(width: 1, height: 26, color: Colors.grey[200]),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: GoogleFonts.outfit(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '9800000000',
                                          hintStyle: GoogleFonts.outfit(
                                            color: Colors.grey[300],
                                            fontSize: 16,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.only(right: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Terms
                              GestureDetector(
                                onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _agreeToTerms ? AppTheme.brandColor : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _agreeToTerms ? AppTheme.brandColor : Colors.grey[300]!,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: _agreeToTerms ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                                            children: [
                                              const TextSpan(text: 'I accept individual '),
                                              TextSpan(
                                                text: 'Privacy & Terms',
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
                              ),
                              const SizedBox(height: 22),
                              // Prism Button
                              _buildPrismButton(),
                            ],
                          ),

                          // Bottom: Social & Registration
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey[100])),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR SIGN IN WITH',
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey[300],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey[100])),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(child: _socialBtn('assets/icons/google_g.svg', 'Google', _signInWithGoogle)),
                                  const SizedBox(width: 18),
                                  Expanded(child: _socialBtn('assets/icons/facebook_f.svg', 'Facebook', _signInWithFacebook, isFb: true)),
                                ],
                              ),
                              const SizedBox(height: 30),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
                                    children: [
                                      const TextSpan(text: "Don't have an account? "),
                                      TextSpan(
                                        text: 'Join Khozna',
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
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrismButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF00B4F4), AppTheme.brandColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandColor.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyPhone,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get Started',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _socialBtn(String icon, String label, VoidCallback onTap, {bool isFb = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(icon, height: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isFb ? const Color(0xFF1877F2) : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
}
