import 'package:khozna/widgets/khozna_image.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:khozna/core/security/security_utils.dart';
import 'package:khozna/features/profile/screens/kyc_screen.dart';
import 'package:khozna/core/utils/offline_storage.dart';
import 'package:khozna/core/utils/app_notifiers.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final User? user = Supabase.instance.client.auth.currentUser;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _esewaController = TextEditingController();
  final _khaltiController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _userTypeController = TextEditingController();
  final _bioController = TextEditingController();
  final _orgController = TextEditingController();

  // Focus nodes for interactive "Design Box" borders
  final Map<String, FocusNode> _focusNodes = {
    'name': FocusNode(),
    'phone': FocusNode(),
    'area': FocusNode(),
    'role': FocusNode(),
    'org': FocusNode(),
    'bio': FocusNode(),
    'esewa': FocusNode(),
    'khalti': FocusNode(),
    'acc': FocusNode(),
  };

  bool _isLoading = false;
  bool _isLocating = false;
  String? _avatarUrl;
  String? _qrCodeUrl;
  String? _studentIdUrl;
  File? _imageFile;
  File? _qrFile;
  File? _idFile;
  final ImagePicker _picker = ImagePicker();

  double? _latitude;
  double? _longitude;
  String _kycStatus = 'not_verified';
  String _initialEmail = '';
  String _initialPhone = '';

  // 🎨 COLOR PALETTE (60-30-10 Rule)
  static const Color colorPrimary = Colors.white; // 60%
  static const Color colorSecondary = Color(0xFFF7F7F7); // 30%
  static const Color colorAccent = AppTheme.brandColor; // 10%
  static const Color colorTextPrimary = Color(0xFF222222);
  static const Color colorTextSecondary = Color(0xFF717171);

  @override
  void initState() {
    super.initState();
    SecurityUtils.setSecure(true);

    // Synchronously pre-fill from auth user metadata & memory cache
    _emailController.text = user?.email ?? '';
    _fullNameController.text = user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? '';
    _phoneController.text = user?.userMetadata?['phone_number'] ?? user?.userMetadata?['phone'] ?? '';
    _avatarUrl = AppTheme.sanitizeAvatarUrl(
      user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'],
    );

    if (profileCache.value != null) {
      _applyCacheMap(profileCache.value!);
    }

    _loadFromDiskCache();
    _loadUserData();
  }

  Future<void> _loadFromDiskCache() async {
    final diskCache = await OfflineStorage.loadProfileCache();
    if (diskCache != null && mounted) {
      _applyCacheMap(diskCache);
    }
  }

  void _applyCacheMap(Map<String, dynamic> cache) {
    setState(() {
      if (_fullNameController.text.isEmpty && cache['full_name'] != null && cache['full_name'].toString().isNotEmpty) {
        _fullNameController.text = cache['full_name'].toString();
      }
      if ((_emailController.text.isEmpty || _emailController.text == user?.email) && cache['email'] != null && cache['email'].toString().isNotEmpty) {
        _emailController.text = cache['email'].toString();
      }
      if (_phoneController.text.isEmpty && cache['phone_number'] != null && cache['phone_number'].toString().isNotEmpty) {
        _phoneController.text = cache['phone_number'].toString();
      }
      if (_esewaController.text.isEmpty && cache['esewa_number'] != null) {
        _esewaController.text = cache['esewa_number'].toString();
      }
      if (_khaltiController.text.isEmpty && cache['khalti_number'] != null) {
        _khaltiController.text = cache['khalti_number'].toString();
      }
      if (_accountNameController.text.isEmpty && cache['account_holder_name'] != null) {
        _accountNameController.text = cache['account_holder_name'].toString();
      }
      if (_areaController.text.isEmpty && cache['area_name'] != null) {
        _areaController.text = cache['area_name'].toString();
      }
      if (_userTypeController.text.isEmpty && cache['user_type'] != null) {
        _userTypeController.text = cache['user_type'].toString();
      }
      if (_bioController.text.isEmpty && cache['bio'] != null) {
        _bioController.text = cache['bio'].toString();
      }
      if (_orgController.text.isEmpty && cache['organization'] != null) {
        _orgController.text = cache['organization'].toString();
      }
      _avatarUrl ??= AppTheme.sanitizeAvatarUrl(cache['avatar_url']);
      _qrCodeUrl ??= cache['qr_code_url']?.toString();
      _studentIdUrl ??= cache['student_id_url']?.toString();
      _latitude ??= (cache['latitude'] as num?)?.toDouble();
      _longitude ??= (cache['longitude'] as num?)?.toDouble();
      if (cache['kyc_status'] != null && _kycStatus == 'not_verified') {
        _kycStatus = cache['kyc_status'].toString();
      }
    });
  }

  void _saveCurrentToCache() {
    if (user == null) return;
    final cacheData = {
      'id': user!.id,
      'full_name': _fullNameController.text,
      'email': _emailController.text.isNotEmpty ? _emailController.text : user?.email,
      'phone_number': _phoneController.text,
      'avatar_url': _avatarUrl,
      'esewa_number': _esewaController.text,
      'khalti_number': _khaltiController.text,
      'account_holder_name': _accountNameController.text,
      'qr_code_url': _qrCodeUrl,
      'area_name': _areaController.text,
      'user_type': _userTypeController.text,
      'bio': _bioController.text,
      'organization': _orgController.text,
      'student_id_url': _studentIdUrl,
      'kyc_status': _kycStatus,
      'latitude': _latitude,
      'longitude': _longitude,
    };
    profileCache.value = cacheData;
    OfflineStorage.saveProfileCache(cacheData);
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final bool hasExistingData = _fullNameController.text.isNotEmpty || _phoneController.text.isNotEmpty;
      if (!hasExistingData) {
        setState(() => _isLoading = true);
      }
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('id', user!.id)
            .maybeSingle();

        final kyc = await Supabase.instance.client
            .from('kyc_verifications')
            .select('latitude, longitude, status')
            .eq('user_id', user!.id)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (mounted && profile != null) {
          final String kycTableStatus = (kyc?['status'] ?? '').toString().toLowerCase();
          final bool kycDocVerified = kycTableStatus == 'verified' || kycTableStatus == 'approved';

          setState(() {
            _fullNameController.text = profile['full_name'] ?? _fullNameController.text;
            _emailController.text = profile['email'] ?? user?.email ?? _emailController.text;
            _phoneController.text = profile['phone_number'] ?? _phoneController.text;
            _avatarUrl = AppTheme.sanitizeAvatarUrl(
              profile['avatar_url'] ??
                  user?.userMetadata?['avatar_url'] ??
                  user?.userMetadata?['picture'] ??
                  _avatarUrl,
            );
            _esewaController.text = profile['esewa_number'] ?? _esewaController.text;
            _khaltiController.text = profile['khalti_number'] ?? _khaltiController.text;
            _accountNameController.text = profile['account_holder_name'] ?? _accountNameController.text;
            _qrCodeUrl = profile['qr_code_url'] ?? _qrCodeUrl;
            _areaController.text = profile['area_name'] ?? _areaController.text;
            _userTypeController.text = profile['user_type'] ?? _userTypeController.text;
            _bioController.text = profile['bio'] ?? _bioController.text;
            _orgController.text = profile['organization'] ?? _orgController.text;
            _studentIdUrl = profile['student_id_url'] ?? _studentIdUrl;

            if (kyc != null) {
              _latitude = (kyc['latitude'] as num?)?.toDouble() ?? _latitude;
              _longitude = (kyc['longitude'] as num?)?.toDouble() ?? _longitude;
              _kycStatus = kycDocVerified
                  ? 'verified'
                  : (kycTableStatus.isNotEmpty ? kycTableStatus : 'pending');
            } else if (profile['kyc_status'] != null) {
              _kycStatus = profile['kyc_status'];
            }
          });

          _initialEmail = _emailController.text.trim();
          _initialPhone = _phoneController.text.trim();

          _saveCurrentToCache();
        }
      } catch (e) {
        debugPrint('Offline/Error loading profile: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLocation() async {
    if (user == null) return;
    setState(() => _isLocating = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Save ONLY location coordinates — do NOT touch kyc_status here.
      // Verification is done through the full KYC document flow only.
      try {
        final existingKyc = await Supabase.instance.client
            .from('kyc_verifications')
            .select('id')
            .eq('user_id', user!.id)
            .maybeSingle();

        if (existingKyc != null) {
          await Supabase.instance.client
              .from('kyc_verifications')
              .update({
                'latitude': position.latitude,
                'longitude': position.longitude,
              })
              .eq('user_id', user!.id);
        } else {
          await Supabase.instance.client.from('kyc_verifications').insert({
            'user_id': user!.id,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'status': 'pending',
          });
        }
      } catch (kycErr) {
        debugPrint('Location save warning: $kycErr');
      }

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          // Do NOT change _kycStatus here — only KYC document review can verify
        });

        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Location saved!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.brandColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location update failed: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imageFile = File(image.path));
  }

  Future<void> _pickQrCode() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _qrFile = File(image.path));
  }

  Future<void> _pickStudentId() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _idFile = File(image.path));
  }

  Future<bool> _showSecurityVerificationDialog({
    required String title,
    required String subtitle,
  }) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool hideOldPassword = true;
    bool hideNewPassword = true;
    bool dialogLoading = false;
    bool isResetSending = false;
    String? dialogError;
    String? dialogSuccess;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendPasswordResetEmail() async {
              final userEmail = user?.email ?? _emailController.text.trim();
              if (userEmail.isEmpty) {
                setDialogState(() {
                  dialogError = 'No valid email address found to send reset link.';
                });
                return;
              }
              setDialogState(() {
                isResetSending = true;
                dialogError = null;
                dialogSuccess = null;
              });
              try {
                await Supabase.instance.client.auth.resetPasswordForEmail(userEmail);
                setDialogState(() {
                  isResetSending = false;
                  dialogSuccess = 'Password reset link sent to $userEmail! Check your inbox.';
                });
              } catch (e) {
                setDialogState(() {
                  isResetSending = false;
                  dialogError = 'Failed to send reset email: ${e.toString()}';
                });
              }
            }

            Future<void> verifyPassword() async {
              final oldPass = oldPasswordController.text.trim();
              final newPass = newPasswordController.text.trim();

              if (oldPass.isEmpty) {
                setDialogState(() {
                  dialogError = 'Please enter your current password.';
                });
                return;
              }

              setDialogState(() {
                dialogLoading = true;
                dialogError = null;
                dialogSuccess = null;
              });

              try {
                final currentUser = Supabase.instance.client.auth.currentUser;
                final userEmail = currentUser?.email ?? _emailController.text.trim();

                if (userEmail.isNotEmpty) {
                  await Supabase.instance.client.auth.signInWithPassword(
                    email: userEmail,
                    password: oldPass,
                  );
                }

                if (newPass.isNotEmpty) {
                  if (newPass.length < 6) {
                    throw 'New password must be at least 6 characters long.';
                  }
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: newPass),
                  );
                }

                final newEmail = _emailController.text.trim();
                if (newEmail.isNotEmpty && newEmail != userEmail) {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(email: newEmail),
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e) {
                final errStr = e.toString().toLowerCase();
                final String userMsg = (errStr.contains('invalid_credentials') || errStr.contains('invalid login'))
                    ? 'Incorrect password entered. If missed/forgotten, tap reset link below.'
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
                      Icons.security_rounded,
                      color: AppTheme.brandColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: const Color(0xFF0F172A),
                      ),
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
                      subtitle,
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
                        labelText: 'New Password (Optional)',
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
                  onPressed: dialogLoading ? null : () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: dialogLoading ? null : verifyPassword,
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
                          'Confirm & Save',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Future<void> _updateProfile() async {
    if (user == null) return;

    final String currentEmail = _emailController.text.trim();
    final String currentPhone = _phoneController.text.trim();

    final bool sensitiveChanged =
        (_initialEmail.isNotEmpty && currentEmail != _initialEmail) ||
        (_initialPhone.isNotEmpty && currentPhone != _initialPhone);

    if (sensitiveChanged) {
      final bool verified = await _showSecurityVerificationDialog(
        title: 'Security Verification',
        subtitle: 'You are updating sensitive information (Email or Phone Number). Please enter your old password to confirm.',
      );
      if (!verified) return;
    }

    setState(() => _isLoading = true);
    try {
      String? avatar = _avatarUrl;
      String? qr = _qrCodeUrl;
      String? idCard = _studentIdUrl;

      if (_imageFile != null)
        avatar = await CloudinaryService.uploadImage(_imageFile!);
      if (_qrFile != null) qr = await CloudinaryService.uploadImage(_qrFile!);
      if (_idFile != null)
        idCard = await CloudinaryService.uploadImage(_idFile!);

      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': _fullNameController.text.trim(),
            'email': currentEmail,
            'avatar_url': avatar,
            'phone_number': currentPhone,
            'esewa_number': _esewaController.text.trim(),
            'khalti_number': _khaltiController.text.trim(),
            'account_holder_name': _accountNameController.text.trim(),
            'qr_code_url': qr,
            'area_name': _areaController.text.trim(),
            'user_type': _userTypeController.text.trim(),
            'bio': _bioController.text.trim(),
            'organization': _orgController.text.trim(),
            'student_id_url': idCard,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user!.id);

      _initialEmail = currentEmail;
      _initialPhone = currentPhone;

      _saveCurrentToCache();

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Profile saved permanently!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.brandColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Update error: $e');
      if (mounted) {
        String friendlyMsg = 'Failed to save profile. Please try again.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('profiles_phone_number_key') ||
            (errStr.contains('duplicate key') && errStr.contains('phone'))) {
          friendlyMsg = 'This phone number is already linked to another account. Please use a different number.';
        } else if (errStr.contains('duplicate key') || errStr.contains('unique constraint')) {
          friendlyMsg = 'One of your details is already in use by another account.';
        } else if (errStr.contains('socketexception') || errStr.contains('failed host lookup')) {
          friendlyMsg = 'Network error. Please check your internet connection.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    friendlyMsg,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorPrimary,
      appBar: _buildAirbnbAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildProfilePhotoSection(),
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKycHeaderBanner(),
                      const SizedBox(height: 4),

                      // ── 1. Personal Information ──
                      _buildSectionCard(
                        title: 'Personal Information',
                        icon: Icons.person_outline_rounded,
                        children: [
                          _buildAirbnbField(
                            'Full Name',
                            _fullNameController,
                            focusNode: _focusNodes['name'],
                            prefixIcon: Icons.badge_outlined,
                            hintText: 'e.g. Ram Bahadur Thapa',
                          ),
                          _buildAirbnbField(
                            'Email Address',
                            _emailController,
                            keyboardType: TextInputType.emailAddress,
                            focusNode: _focusNodes['email'],
                            prefixIcon: Icons.email_outlined,
                            hintText: 'e.g. ram@example.com',
                          ),
                          _buildAirbnbField(
                            'Phone Number',
                            _phoneController,
                            keyboardType: TextInputType.phone,
                            focusNode: _focusNodes['phone'],
                            prefixIcon: Icons.phone_outlined,
                            hintText: 'e.g. 9800000000',
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _showSecurityVerificationDialog(
                              title: 'Change Password',
                              subtitle: 'Enter your old password and a new password below. If forgotten, tap the reset link to receive a password email.',
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.brandColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.brandColor.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_reset_rounded, size: 20, color: AppTheme.brandColor),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Change Password',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.brandColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.brandColor),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── 2. About You ──
                      _buildSectionCard(
                        title: 'About You',
                        icon: Icons.auto_stories_outlined,
                        children: [
                          _buildAirbnbField(
                            'Role',
                            _userTypeController,
                            focusNode: _focusNodes['role'],
                            prefixIcon: Icons.work_outline_rounded,
                            hintText: 'e.g. Property Owner / Student',
                          ),
                          _buildAirbnbField(
                            'Organization',
                            _orgController,
                            focusNode: _focusNodes['org'],
                            prefixIcon: Icons.business_outlined,
                            hintText: 'e.g. Khozna Properties',
                          ),
                          _buildAirbnbField(
                            'Bio',
                            _bioController,
                            maxLines: 4,
                            focusNode: _focusNodes['bio'],
                            prefixIcon: Icons.notes_rounded,
                            hintText: 'e.g. Tell us a bit about yourself...',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── 3. Location ──
                      _buildLocationSection(),
                      const SizedBox(height: 18),

                      // ── 4. Receive Money Options ──
                      _buildSectionCard(
                        title: 'Receive Money Options',
                        icon: Icons.account_balance_wallet_outlined,
                        children: [
                          _buildAirbnbField(
                            'eSewa ID',
                            _esewaController,
                            focusNode: _focusNodes['esewa'],
                            hintText: 'e.g. 98XXXXXXXX',
                            prefixWidget: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                'assets/images/esewa.webp',
                                width: 18,
                                height: 18,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          _buildAirbnbField(
                            'Khalti ID',
                            _khaltiController,
                            focusNode: _focusNodes['khalti'],
                            hintText: 'e.g. 98XXXXXXXX',
                            prefixWidget: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                'assets/images/khalti.png',
                                width: 18,
                                height: 18,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          _buildAirbnbField(
                            'Legal Account Name',
                            _accountNameController,
                            focusNode: _focusNodes['acc'],
                            prefixIcon: Icons.account_box_outlined,
                            hintText: 'e.g. Ram Bahadur Thapa',
                          ),
                          const SizedBox(height: 8),
                          _buildPremiumMediaGrid(),
                        ],
                      ),

                      const SizedBox(height: 32),
                      _buildAirbnbSaveButton(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) _buildPremiumLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAirbnbAppBar() {
    return AppBar(
      backgroundColor: colorPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.close_rounded,
          color: colorTextPrimary,
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: _updateProfile,
          child: Text(
            'Save',
            style: GoogleFonts.plusJakartaSans(
              color: colorAccent,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildKycHeaderBanner() {
    return const SizedBox.shrink();
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.brandColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAirbnbField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
    IconData? prefixIcon,
    Widget? prefixWidget,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: enabled,
            focusNode: focusNode,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: enabled ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
              ),
              prefixIcon: prefixWidget != null
                  ? Padding(
                      padding: const EdgeInsets.all(11),
                      child: prefixWidget,
                    )
                  : (prefixIcon != null
                      ? Icon(prefixIcon, size: 18, color: enabled ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                      : null),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.brandColor,
                  width: 1.5,
                ),
              ),
              suffixIcon: !enabled
                  ? const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              _imageFile != null
                  ? Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : AppTheme.buildAvatarWidget(
                      avatarUrl: _avatarUrl,
                      radius: 60,
                      name: _fullNameController.text,
                    ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorTextPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorPrimary, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: colorPrimary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatarChip(
              label: '👨 Man Avatar',
              isSelected:
                  _avatarUrl == 'assets/images/man avatar.jpeg' &&
                  _imageFile == null,
              onTap: () {
                setState(() {
                  _imageFile = null;
                  _avatarUrl = 'assets/images/man avatar.jpeg';
                });
                HapticFeedback.lightImpact();
              },
            ),
            const SizedBox(width: 10),
            _buildAvatarChip(
              label: '👩 Woman Avatar',
              isSelected:
                  _avatarUrl == 'assets/images/women avatar.jpeg' &&
                  _imageFile == null,
              onTap: () {
                setState(() {
                  _imageFile = null;
                  _avatarUrl = 'assets/images/women avatar.jpeg';
                });
                HapticFeedback.lightImpact();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : colorTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.brandColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Location / ठेगाना',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pin your exact GPS location to enable distance calculation for guests and nearby services.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorTextSecondary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLocating ? null : _updateLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorTextPrimary,
                      ),
                    )
                  : Icon(
                      _latitude != null
                          ? Icons.refresh_rounded
                          : Icons.my_location_rounded,
                      size: 18,
                    ),
              label: Text(
                _isLocating
                    ? 'Capturing GPS...'
                    : (_latitude != null
                          ? 'Update GPS Location'
                          : 'Pin My Location'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorTextPrimary,
                side: const BorderSide(color: colorTextPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                '📍 Location saved: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.brandColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumMediaGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildAirbnbMediaTile(
            'PAYMENT QR',
            _qrFile,
            _qrCodeUrl,
            _pickQrCode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAirbnbMediaTile(
            'STUDENT ID',
            _idFile,
            _studentIdUrl,
            _pickStudentId,
          ),
        ),
      ],
    );
  }

  Widget _buildAirbnbMediaTile(
    String label,
    File? file,
    String? url,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: colorTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: (file != null || url != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: file != null
                        ? Image.file(file, fit: BoxFit.cover)
                        : KhoznaImage(imageUrl: url!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.add_rounded, color: colorTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAirbnbSaveButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: colorAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Update Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
    );
  }

  Widget _buildPremiumLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: const Center(
        child: CircularProgressIndicator(
          color: colorTextPrimary,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
