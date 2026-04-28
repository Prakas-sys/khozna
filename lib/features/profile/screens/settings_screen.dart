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
      // Call the Edge Function
      await Supabase.instance.client.functions.invoke('delete-account');
      
      // Sign out locally
      await Supabase.instance.client.auth.signOut();
      
      if (mounted) {
        // Clear navigation stack and go to LoginScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account permanently deleted. We are sorry to see you go.'),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.redAccent, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'This will permanently delete your profile, properties, messages, and all other data. This action cannot be undone.',
          style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w400),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showFinalConfirmation();
                  },
                  child: Text('Continue to Delete', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 15)),
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
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.redAccent, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Are you 100% sure?\nAll your listed properties and earnings history will be lost forever.',
          style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w400),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteAccount();
                  },
                  child: Text('Yes, Delete Everything', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Wait, keep my account', style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
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
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
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
          _buildSimpleTile(Icons.lock_outline, 'Change Password'),

          const SizedBox(height: 32),
          _buildSectionTitle('DANGER ZONE'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
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
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
            ),
            subtitle: Text(
              'This action cannot be undone.',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey[600]),
            ),
            onTap: _isDeleting ? null : _showDeleteConfirmation,
            trailing: _isDeleting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
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
        style: GoogleFonts.plusJakartaSans(
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(
        desc,
        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w400),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.brandColor,
      ),
    );
  }

  Widget _buildLanguageTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Language',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        _language,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: AppTheme.brandColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
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
    );
  }

  Widget _buildSimpleTile(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: () {},
    );
  }
}
