import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'verify_phone_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/original logo.png', 
                height: 36, 
                fit: BoxFit.contain
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Text('Join Us Today', 
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24, // Reduced from 28
                          fontWeight: FontWeight.bold, 
                          color: AppTheme.primaryTextColor
                        )
                      ),
                      Text('KHOZNA', 
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30, // Reduced from 34
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandColor
                        )
                      ),
                      const SizedBox(height: 8),
                      Text('Create an account to start your journey.', 
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500])),
                      const SizedBox(height: 20),
                      
                      TextField(
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                          prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      IntlPhoneField(
                        decoration: InputDecoration(
                          hintText: 'Enter Mobile number',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide(color: Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide(color: Colors.grey[300]!)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: const BorderSide(color: AppTheme.brandColor)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        initialCountryCode: 'NP',
                        showDropdownIcon: false,
                        disableLengthCheck: true,
                        flagsButtonPadding: const EdgeInsets.only(left: 16),
                        dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.transparent),
                        pickerDialogStyle: PickerDialogStyle(),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Email (Optional)',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) {
                                setState(() { _agreeToTerms = value ?? false; });
                              },
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: BorderSide(color: Colors.grey[400]!),
                              activeColor: AppTheme.brandColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: RichText(
                                textAlign: TextAlign.start,
                                text: TextSpan(
                                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                                  children: const [
                                    TextSpan(text: 'I agree to terms of '),
                                    TextSpan(text: 'Service', style: TextStyle(color: AppTheme.brandColor, fontWeight: FontWeight.bold)),
                                    TextSpan(text: ' and '),
                                    TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppTheme.brandColor, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                                  builder: (context) => const VerifyPhoneScreen()), (route) => false),
                          child: const Text('Register', style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account? ", style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                          GestureDetector(
                            child: Text("Login Here", style: GoogleFonts.outfit(color: AppTheme.brandColor, fontSize: 13, fontWeight: FontWeight.w500)),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
}
