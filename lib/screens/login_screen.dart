import 'dart:async';
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
  int _bossTaps = 0;

  @override
  void initState() {
    super.initState();
    SecurityUtils.setSecure(false);
  }

  @override
  void dispose() {
    SecurityUtils.setSecure(false);
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out top, middle, bottom
                    children: [
                       Column(
                        children: [
                          const SizedBox(height: 12),
                          // --- TOP BAR ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _handleBossTap,
                                child: Image.asset('assets/images/original logo.png', height: 42),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen())),
                                icon: Icon(Icons.chevron_right, color: AppTheme.brandColor, size: 30),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
        
                          // --- ILLUSTRATION ---
                          SizedBox(
                            height: constraints.maxHeight * 0.30, 
                            child: Image.asset(
                              'assets/images/boy illustrate  png.png',
                              fit: BoxFit.contain,
                            ),
                          ),
        
                          const SizedBox(height: 12),
        
                          // --- WELCOME TEXT ---
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Welcome Back To',
                                style: GoogleFonts.zenAntiqueSoft(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D2D2D),
                                ),
                              ),
                              Text(
                                'KHOZNA',
                                style: GoogleFonts.zenAntiqueSoft(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.brandColor,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Login to continue finding your next home.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
    
                      // --- INPUT ACTIONS ---
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Phone Input
                            Container(
                              height: 58,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white, 
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1.2),
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
                                  Container(width: 1.2, height: 24, color: Colors.grey.withOpacity(0.35)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500),
                                      decoration: InputDecoration(
                                        hintText: 'Enter Mobile number',
                                        hintStyle: GoogleFonts.montserrat(color: Colors.grey[400], fontSize: 15, fontWeight: FontWeight.w400),
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
                            
                            const SizedBox(height: 10),
        
                            // Terms agreement
                            Padding(
                              padding: const EdgeInsets.only(left: 12), 
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                                    child: Container(
                                      width: 20, height: 20,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1.2),
                                        color: _agreeToTerms ? AppTheme.brandColor : Colors.white,
                                      ),
                                      child: _agreeToTerms ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
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
                                                     const SizedBox(height: 10),
        
                            // Login Button
                            SizedBox(
                              width: double.infinity, height: 58,
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
                                    : Text('Login', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
        
                            // OR Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.withOpacity(0.4))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('OR', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[400])),
                                ),
                                Expanded(child: Divider(color: Colors.grey.withOpacity(0.4))),
                              ],
                            ),
        
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Expanded(child: _buildSocialBtn('assets/icons/google_g.svg', 'Google', _signInWithGoogle)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSocialBtn('assets/icons/facebook_f.svg', 'Facebook', _signInWithFacebook)),
                              ],
                            ),
                          ],
                        ),
                      ),
    
                      // --- FOOTER ---
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[500]),
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                TextSpan(text: 'Register Here', style: TextStyle(color: AppTheme.brandColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildSocialBtn(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56, // Large premium height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.grey.withOpacity(0.25), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(icon, height: 22), 
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)), 
          ],
        ),
      ),
    );
  }
}
