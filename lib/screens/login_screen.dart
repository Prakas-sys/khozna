import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'register_screen.dart';
import 'verify_phone_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _agreeToTerms = false;
  final PageController _pageController = PageController();
  int _currentIllustration = 0;

  final List<String> _illustrations = [
    'assets/images/illustrate of login screen.png',
    'assets/images/boy illustrate  png.png',
    'assets/images/man illustrate png.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandColor,
      body: Column(
        children: [
          // ── TOP: Swipeable Illustration ──
          Expanded(
            flex: 42,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _illustrations.length,
                  onPageChanged: (i) => setState(() => _currentIllustration = i),
                  itemBuilder: (context, index) {
                    return Container(
                      color: AppTheme.brandColor,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 56,
                        left: 20,
                        right: 20,
                        bottom: 24,
                      ),
                      child: Image.asset(
                        _illustrations[index],
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
                // Logo + Skip bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/images/original logo.png', height: 36, fit: BoxFit.contain),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Skip', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Dot indicators
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_illustrations.length, (i) {
                      final active = i == _currentIllustration;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM: White rounded card ──
          Expanded(
            flex: 58,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome Back To',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'KHOZNA',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.zenAntiqueSoft(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.brandColor,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nepal-only phone field — pill shaped
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇳🇵', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text('+977', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                                  const SizedBox(width: 10),
                                  Container(width: 1.5, height: 22, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.phone,
                                style: GoogleFonts.outfit(fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Mobile number',
                                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Terms
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            activeColor: AppTheme.brandColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                              children: const [
                                TextSpan(text: 'I agree to the '),
                                TextSpan(text: 'Terms of Service', style: TextStyle(color: AppTheme.brandColor, fontWeight: FontWeight.w600)),
                                TextSpan(text: ' and '),
                                TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppTheme.brandColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Login button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B4F5), AppTheme.brandColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [BoxShadow(color: AppTheme.brandColor.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const VerifyPhoneScreen()),
                        ),
                        child: Text('Login', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OR divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[200], thickness: 1.5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR CONTINUE WITH', style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        ),
                        Expanded(child: Divider(color: Colors.grey[200], thickness: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Social buttons
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/google_g.svg',
                                    height: 22,
                                    width: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Text('Google', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white, 
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/facebook_f.svg',
                                    height: 22,
                                    width: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Text('Facebook', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text(
                            "Register Here",
                            style: GoogleFonts.outfit(
                              color: AppTheme.brandColor,
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

