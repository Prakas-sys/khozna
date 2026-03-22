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
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  int _bossTaps = 0;

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
    SecurityUtils.setSecure(true); // Enabled as per Khozna safety standards
    _startCarouselTimer();
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
    SecurityUtils.setSecure(false); // Disable when leaving screen
    _carouselTimer?.cancel();
    _illustrationPageController.dispose();
    _phoneFocusNode.dispose();
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
        title: Text('Admin Control', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
          ElevatedButton(
            onPressed: () {
              if (bossPhone.text == '9705278379' && bossPass.text == 'Khozna@Success') {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Credentials')));
              }
            },
            child: const Text('Unlock'),
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
      _phoneFocusNode.requestFocus();
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyPhoneScreen(
            phoneNumber: fullPhone, 
            verificationId: verificationId,
            resendToken: resendToken,
          )));
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _signInWithFacebook() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please agree to terms to continue', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Facebook login cancelled.', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      }
    } catch (e) { 
      setState(() => _isLoading = false); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Facebook Login Error: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please agree to terms to continue', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        serverClientId: '543455945266-ospb11mcl3ghpkrd8cnv6phs3l0hatt6.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) { 
        setState(() => _isLoading = false); 
        return; 
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        await SupabaseService.syncUserWithSupabase(userCredential.user!);
        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
      }
    } catch (e) { 
      setState(() => _isLoading = false); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Login Error: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    // --- TOP BAR ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _handleBossTap,
                            child: Image.asset('assets/images/original logo.png', height: 48),
                          ),
                          InkWell(
                            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen())),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.brandColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_forward_rounded, color: AppTheme.brandColor, size: 24),
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
                        onPageChanged: (index) {
                          setState(() => _currentIllustrationPage = index);
                        },
                        itemCount: _illustrations.length,
                        itemBuilder: (context, index) {
                          return Image.asset(
                            _illustrations[index],
                            fit: BoxFit.cover,
                            alignment: const Alignment(1.0, 1.0),
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

                    // --- WELCOME TEXT ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome Back To',
                            style: GoogleFonts.zenAntiqueSoft(
                              fontSize: 26,
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
                            'Discover Rooms, Apartments and Houses Easily',
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
                               border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.2),
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
                                const Text('🇳🇵', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Text(
                                  '+977',
                                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)
                                ),
                                const SizedBox(width: 12),
                                Container(width: 1.2, height: 24, color: Colors.grey.withOpacity(0.5)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500),
                                    decoration: InputDecoration(
                                      hintText: 'Enter mobile number',
                                      hintStyle: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w400),
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
                                  onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                                  child: Container(
                                    width: 18, height: 18,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.withOpacity(0.6), width: 1.2),
                                      color: _agreeToTerms ? AppTheme.brandColor : Colors.white,
                                    ),
                                    child: _agreeToTerms ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                   child: RichText(
                                     text: TextSpan(
                                       style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                       children: [
                                         const TextSpan(text: 'I agree to terms of '),
                                         TextSpan(text: 'Service', style: TextStyle(color: AppTheme.brandColor, fontWeight: FontWeight.bold)),
                                         const TextSpan(text: ' and '),
                                         TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppTheme.brandColor, fontWeight: FontWeight.bold)),
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
                            width: double.infinity, height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyPhone,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              ),
                              child: _isLoading
                                   ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                   : Text(
                                       'Login', 
                                       style: GoogleFonts.outfit(
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
                              Expanded(child: Divider(color: Colors.grey.withOpacity(0.4))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                              ),
                              Expanded(child: Divider(color: Colors.grey.withOpacity(0.4))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(child: _buildSocialBtn('assets/icons/google_g.svg', 'Google', _isLoading ? () {} : _signInWithGoogle)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildSocialBtn('assets/icons/facebook_f.svg', 'Facebook', _isLoading ? () {} : _signInWithFacebook)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                                  children: [
                                    const TextSpan(text: "Don't have an account? "),
                                    TextSpan(text: 'Register Here', style: TextStyle(color: AppTheme.brandColor, fontWeight: FontWeight.w600)),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 56, // Increased height for a bigger look
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6), // Semi-transparent for glass effect
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
                  style: GoogleFonts.outfit(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.black87
                  )
                ), 
              ],
            ),
          ),
        ),
      ),
    );
  }
}
