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
  bool _agreeToTerms = true;
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
    const primaryBlue = Color(0xFF00B4F4);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _handleBossTap,
                            child: Image.asset(
                              'assets/images/original logo.png',
                              height: 44,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen())),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: primaryBlue,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Illustration Area - increased size slightly
                      SizedBox(
                        height: constraints.maxHeight * 0.35,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _illustrations.length,
                          onPageChanged: (i) => setState(() => _currentIllustration = i),
                          itemBuilder: (context, index) {
                            return Image.asset(
                              _illustrations[index],
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),

                      // Grouping Branding, Input, and Action for tighter, better alignment
                      Column(
                        children: [
                          // Branding & Texts
                          Text(
                            'Welcome Back To',
                            style: GoogleFonts.zenAntiqueSoft(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'KHOZNA',
                            style: GoogleFonts.zenAntiqueSoft(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: primaryBlue,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No broker, no scams, only real place.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.zenAntiqueSoft(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12), // Reduced from 28 to push it up higher

                          // Single-Shape Phone Input
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(27),
                              border: Border.all(color: Colors.grey[300]!, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 18),
                                  child: Row(
                                    children: [
                                      const Text('\uD83C\uDDF3\uD83C\uDDF5', style: TextStyle(fontSize: 20)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+977',
                                        style: GoogleFonts.zenAntiqueSoft(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        height: 24,
                                        width: 1.5,
                                        color: Colors.grey[300],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12, right: 30),
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: GoogleFonts.zenAntiqueSoft(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter Mobile Number',
                                        hintStyle: GoogleFonts.zenAntiqueSoft(
                                          color: Colors.grey[300],
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12), // Reduced from 16 for tightness

                          // Terms Agreement
                          GestureDetector(
                            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                                    color: _agreeToTerms ? primaryBlue : Colors.white,
                                  ),
                                  child: _agreeToTerms
                                      ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                                    children: [
                                      const TextSpan(text: 'I agree to terms of '),
                                      TextSpan(
                                        text: 'Service',
                                        style: TextStyle(
                                          color: primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14), // Reduced from 18 to bring button closer to input

                          // Primary Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 56, // Adjusted to 56 for better fit
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyPhone,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24), // Spacing before divider

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
                            ],
                          ),

                          const SizedBox(height: 20), // Spacing before social buttons

                          // Social Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialBtn(
                                  icon: 'assets/icons/google_g.svg',
                                  label: 'Google',
                                  onTap: _signInWithGoogle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSocialBtn(
                                  icon: 'assets/icons/facebook_f.svg',
                                  label: 'Facebook',
                                  onTap: _signInWithFacebook,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28), // Spacing before footer

                          // Footer Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                ),
                                child: Text(
                                  'Register Here',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildSocialBtn({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 56, // Matched height with Login button
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey[200]!, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(icon, height: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D2D2D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
