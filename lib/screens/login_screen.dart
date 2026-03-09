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
    SecurityUtils.setSecure(false); // Temporarily unlocked for screenshots!
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
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // --- 1. HEADER SECTION (Identity & Action) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _handleBossTap,
                          child: Image.asset('assets/images/original logo.png', height: 40),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text('Skip', style: GoogleFonts.outfit(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, color: primaryBlue, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // --- 2. VISUAL CONTEXT SECTION ---
                    SizedBox(
                      height: constraints.maxHeight * 0.24,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _illustrations.length,
                        onPageChanged: (i) => setState(() => _currentIllustration = i),
                        itemBuilder: (context, index) => Image.asset(_illustrations[index], fit: BoxFit.contain),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- 3. CORE IDENTITY SECTION ---
                    Text(
                      'Welcome Back To',
                      style: GoogleFonts.zenAntiqueSoft(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF2D2D2D)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'KHOZNA',
                      style: GoogleFonts.zenAntiqueSoft(fontSize: 34, fontWeight: FontWeight.w900, color: primaryBlue, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No broker, no scams, only real place.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w400),
                    ),

                    const SizedBox(height: 32),

                    // --- 4. ACTION SECTION (Input & Buttons) ---
                    // Phone Input Field
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border(right: BorderSide(color: Colors.grey[200]!, width: 1.5)),
                            ),
                            child: Row(
                              children: [
                                const Text('\uD83C\uDDF3\uD83C\uDDF5', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Text('+977', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                              decoration: InputDecoration(
                                hintText: '98XXXXXXXX',
                                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Terms Link
                    GestureDetector(
                      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (v) => setState(() => _agreeToTerms = v!),
                              activeColor: primaryBlue,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(text: 'Terms', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                                  const TextSpan(text: ' and '),
                                  TextSpan(text: 'Privacy Policy', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Send OTP', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // OR Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[200], thickness: 1.5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR CONTINUE WITH', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                        Expanded(child: Divider(color: Colors.grey[200], thickness: 1.5)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Social Buttons
                    Row(
                      children: [
                        Expanded(child: _buildSocialBtn(icon: 'assets/icons/google_g.svg', label: 'Google', onTap: _signInWithGoogle)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSocialBtn(icon: 'assets/icons/facebook_f.svg', label: 'Facebook', onTap: _signInWithFacebook)),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // --- 5. FOOTER SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: GoogleFonts.outfit(color: Colors.grey[600])),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text('Register Now', style: GoogleFonts.outfit(color: primaryBlue, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),    ),
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
