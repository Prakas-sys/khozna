import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/security_utils.dart';
import '../utils/supabase_service.dart';
import 'main_screen.dart';

class VerifyPhoneScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const VerifyPhoneScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  
  // Timer for OTP resend
  Timer? _timer;
  int _timerSeconds = 60;
  bool _canResend = false;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
    // Secure OTP screen from screenshots/recordings
    SecurityUtils.setSecure(true);
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    // Disable secure mode
    SecurityUtils.setSecure(false);
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        forceResendingToken: widget.resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: ${e.message}', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
        },
        codeSent: (String newId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _currentVerificationId = newId;
          });
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification code resent!', style: GoogleFonts.outfit()), backgroundColor: AppTheme.brandColor, behavior: SnackBarBehavior.floating));
        },
        codeAutoRetrievalTimeout: (String id) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _verifyOtp() async {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the full 6-digit code', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: otp,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Sync with Supabase
        await SupabaseService.syncUserWithSupabase(userCredential.user!);
      }

      if (mounted) {
        // Take user to home screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid OTP or verification failed', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandColor.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const SizedBox(height: 20),
                  // Illustration
                  SizedBox(
                    height: 180,
                    child: Image.asset(
                      'assets/images/man illustrate png.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify Phone',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryTextColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          color: AppTheme.secondaryTextColor,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a 6-digit code to\n'),
                          TextSpan(
                            text: widget.phoneNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // OTP Input Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) => _buildOtpBox(index)),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: AppTheme.brandColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text('Verify & Continue', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Resend Section
                  Column(
                    children: [
                      Text(
                        _canResend 
                            ? "Didn't receive the code?"
                            : "Resend code in $_timerSeconds seconds",
                        style: GoogleFonts.outfit(
                          color: AppTheme.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: _canResend ? _resendOtp : null,
                        child: Text(
                          'Resend Code',
                          style: GoogleFonts.outfit(
                            color: _canResend ? AppTheme.brandColor : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNodes[index].hasFocus ? AppTheme.brandColor : Colors.grey.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: _focusNodes[index].hasFocus ? [
          BoxShadow(
            color: AppTheme.brandColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryTextColor,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              _verifyOtp();
            }
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {}); // To update border color/shadow
        },
      ),
    );
  }
}
