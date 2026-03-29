import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (user != null) {
      _fullNameController.text = user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? '';
      _emailController.text = user?.email ?? '';
      _phoneController.text = user?.phone ?? '';
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      if (user != null) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {'full_name': _fullNameController.text},
          ),
        );
        
        // Also update the profiles table if it exists
        await Supabase.instance.client.from('profiles').update({
          'full_name': _fullNameController.text,
          'email': _emailController.text,
        }).eq('id', user!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.brandColor.withOpacity(0.1), AppTheme.brandColor.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.person_rounded, size: 50, color: AppTheme.brandColor.withOpacity(0.5)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.brandColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('PERSONAL INFORMATION'),
            const SizedBox(height: 16),
            _buildTextField('Full Name', _fullNameController, Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextField('Email Address', _emailController, Icons.email_outlined, enabled: false),
            const SizedBox(height: 20),
            _buildTextField('Phone Number', _phoneController, Icons.phone_android_outlined, enabled: false),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey[400],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey[500],
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: enabled ? Colors.grey.shade100 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: GoogleFonts.inter(
              fontSize: 15, 
              color: enabled ? Colors.black87 : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.brandColor, size: 18),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              hintText: 'Enter your $label',
              hintStyle: GoogleFonts.inter(color: Colors.grey[300], fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
