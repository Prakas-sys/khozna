import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/auth/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = true;
  String _language = 'English';
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      // Direct call to our new permanent delete function
      await Supabase.instance.client.rpc('delete_own_account');

      // Clear local auth state
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account permanently deleted. All data has been cleared from our database.',
            ),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showDeleteConfirmation() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: Colors.redAccent,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'This will permanently delete your profile, properties, messages, and all other data. This action cannot be undone.',
          style: GoogleFonts.inter(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showFinalConfirmation();
                  },
                  child: Text(
                    'Continue to Delete',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Last Warning',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: Colors.redAccent,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'ARE YOU 100% SURE?\n\nThis action is PERMANENT and NOT RECOVERABLE.\n\nAll your listed properties, profile data, and earnings history will be wiped from our servers forever.',
          style: GoogleFonts.inter(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteAccount();
                  },
                  child: Text(
                    'Yes, Delete Everything',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Wait, keep my account',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWithoutLoginDeleteConfirmation() {
    HapticFeedback.mediumImpact();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    int currentStep = 1; // 1 = Enter Phone, 2 = Enter OTP
    bool dialogLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> sendOtp() async {
            final phone = phoneController.text.trim();
            if (phone.isEmpty) {
              setDialogState(() {
                errorMessage = 'Please enter your phone number';
              });
              return;
            }

            setDialogState(() {
              dialogLoading = true;
              errorMessage = null;
            });

            try {
              await Supabase.instance.client.auth.signInWithOtp(
                phone: '+977$phone',
              );
              setDialogState(() {
                currentStep = 2;
                dialogLoading = false;
              });
            } catch (e) {
              setDialogState(() {
                errorMessage = e.toString().contains('ApiException')
                    ? 'Failed to send OTP. Please check the phone number.'
                    : e.toString();
                dialogLoading = false;
              });
            }
          }

          Future<void> verifyAndDelete() async {
            final phone = phoneController.text.trim();
            final otp = otpController.text.trim();
            if (otp.length < 6) {
              setDialogState(() {
                errorMessage = 'Please enter the 6-digit OTP code';
              });
              return;
            }

            setDialogState(() {
              dialogLoading = true;
              errorMessage = null;
            });

            try {
              // 1. Verify OTP - this signs the user in
              final response = await Supabase.instance.client.auth.verifyOTP(
                phone: '+977$phone',
                token: otp,
                type: OtpType.sms,
              );

              if (response.user != null) {
                // 2. Invoke the permanent delete RPC
                await Supabase.instance.client.rpc('delete_own_account');

                // 3. Clear auth and caches
                await Supabase.instance.client.auth.signOut();

                // Go to login screen
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Account permanently deleted. This action is not recoverable.',
                      ),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              } else {
                throw 'Verification failed. User is empty.';
              }
            } catch (e) {
              setDialogState(() {
                errorMessage =
                    e.toString().contains('invalid response') ||
                        e.toString().contains('invalid_grant')
                    ? 'Invalid OTP code. Please try again.'
                    : e.toString();
                dialogLoading = false;
              });
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Permanent Account Delete',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    currentStep == 1
                        ? 'Please enter your registered mobile number to verify and permanently delete your account.'
                        : 'We sent a 6-digit OTP code to +977 ${phoneController.text}. Enter it below to confirm permanent deletion.',
                    style: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (currentStep == 1) ...[
                    // Phone Number field
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '+977',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1.2,
                            height: 20,
                            color: Colors.grey.withOpacity(0.4),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(30),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Mobile number',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // OTP Verification Code field
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Enter 6-digit code',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 13,
                            letterSpacing: 0,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.maxFinite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: dialogLoading
                          ? null
                          : (currentStep == 1 ? sendOtp : verifyAndDelete),
                      child: dialogLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              currentStep == 1
                                  ? 'Send OTP to Verify'
                                  : 'Permanently Delete Now',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: dialogLoading
                          ? null
                          : () {
                              if (currentStep == 2) {
                                setDialogState(() {
                                  currentStep = 1;
                                  otpController.clear();
                                  errorMessage = null;
                                });
                              } else {
                                Navigator.pop(context);
                              }
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        currentStep == 2 ? 'Back to Phone Number' : 'Cancel',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle('PREFERENCES'),
          _buildToggleTile(
            'Notifications',
            'Receive alerts for new messages',
            _notifEnabled,
            (v) => setState(() => _notifEnabled = v),
          ),
          _buildLanguageTile(),

          const SizedBox(height: 32),
          _buildSectionTitle('ACCOUNT SECURITY'),
          _buildSimpleTile(
            Icons.lock_outline,
            'Change Password',
            onTap: _showChangePasswordDialog,
          ),

          const SizedBox(height: 32),
          _buildSectionTitle('DANGER ZONE'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              'Delete Account',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
            ),
            subtitle: Text(
              'This action cannot be undone.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
            onTap: _isDeleting
                ? null
                : (Supabase.instance.client.auth.currentUser == null
                      ? _showWithoutLoginDeleteConfirmation
                      : _showDeleteConfirmation),
            trailing: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Khozna v1.0.0',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    String title,
    String desc,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // Subtle slate background
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: const Color(0xFF1E293B),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          desc,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.brandColor,
            activeTrackColor: AppTheme.brandColor.withOpacity(0.2),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[200],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.translate_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
        ),
        title: Text(
          'Language',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          _language,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.brandColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('English'),
                    leading: const Icon(Icons.language),
                    onTap: () {
                      setState(() => _language = 'English');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('नेपाली (Nepali)'),
                    leading: const Icon(Icons.language),
                    onTap: () {
                      setState(() => _language = 'Nepali');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final user = Supabase.instance.client.auth.currentUser;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool hideOldPassword = true;
    bool hideNewPassword = true;
    bool dialogLoading = false;
    bool isResetSending = false;
    String? dialogError;
    String? dialogSuccess;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendPasswordResetEmail() async {
              final email = user?.email ?? '';
              if (email.isEmpty) {
                setDialogState(() {
                  dialogError = 'No user email address found.';
                });
                return;
              }
              setDialogState(() {
                isResetSending = true;
                dialogError = null;
                dialogSuccess = null;
              });
              try {
                await Supabase.instance.client.auth.resetPasswordForEmail(email);
                setDialogState(() {
                  isResetSending = false;
                  dialogSuccess = 'Password reset link sent to $email! Check your inbox.';
                });
              } catch (e) {
                setDialogState(() {
                  isResetSending = false;
                  dialogError = 'Failed to send reset email: ${e.toString()}';
                });
              }
            }

            Future<void> verifyAndChangePassword() async {
              final oldPass = oldPasswordController.text.trim();
              final newPass = newPasswordController.text.trim();

              if (oldPass.isEmpty || newPass.isEmpty) {
                setDialogState(() {
                  dialogError = 'Please enter both current and new password.';
                });
                return;
              }

              if (newPass.length < 6) {
                setDialogState(() {
                  dialogError = 'New password must be at least 6 characters long.';
                });
                return;
              }

              setDialogState(() {
                dialogLoading = true;
                dialogError = null;
                dialogSuccess = null;
              });

              try {
                final email = user?.email ?? '';
                if (email.isNotEmpty) {
                  await Supabase.instance.client.auth.signInWithPassword(
                    email: email,
                    password: oldPass,
                  );
                }

                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: newPass),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully!'),
                      backgroundColor: AppTheme.brandColor,
                    ),
                  );
                }
              } catch (e) {
                final errStr = e.toString().toLowerCase();
                final String userMsg = (errStr.contains('invalid_credentials') || errStr.contains('invalid login'))
                    ? 'Incorrect current password. If missed/forgotten, tap reset link below.'
                    : e.toString().replaceAll('Exception: ', '');
                setDialogState(() {
                  dialogLoading = false;
                  dialogError = userMsg;
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppTheme.brandColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Change Password',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter your old password and new password to update account security.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    TextField(
                      controller: oldPasswordController,
                      obscureText: hideOldPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        hintText: 'Enter old password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hideOldPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setDialogState(() => hideOldPassword = !hideOldPassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: newPasswordController,
                      obscureText: hideNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                        prefixIcon: const Icon(Icons.key_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hideNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setDialogState(() => hideNewPassword = !hideNewPassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: isResetSending ? null : sendPasswordResetEmail,
                        icon: isResetSending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.mail_outline_rounded, size: 16, color: AppTheme.brandColor),
                        label: Text(
                          'Forgot/missed password? Send link to email',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandColor,
                          ),
                        ),
                      ),
                    ),

                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dialogError!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    if (dialogSuccess != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dialogSuccess!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF166534),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: dialogLoading ? null : verifyAndChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: dialogLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Update Password',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSimpleTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF1E293B),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
        onTap: onTap,
      ),
    );
  }
}
