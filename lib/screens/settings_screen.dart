import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle('PREFERENCES'),
          _buildToggleTile('Notifications', 'Receive alerts for new messages', _notifEnabled, (v) => setState(() => _notifEnabled = v)),
          _buildLanguageTile(),
          
          const SizedBox(height: 32),
          _buildSectionTitle('ACCOUNT SECURITY'),
          _buildSimpleTile(Icons.lock_outline, 'Change Password'),
          
          const SizedBox(height: 32),
          _buildSectionTitle('DANGER ZONE'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
            title: Text('Delete Account', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: Text('This action cannot be undone.', style: GoogleFonts.inter(fontSize: 12)),
            onTap: () {},
          ),
          
          const SizedBox(height: 40),
          Center(child: Text('Khozna v1.0.0', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.2)),
    );
  }

  Widget _buildToggleTile(String title, String desc, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      subtitle: Text(desc, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.brandColor),
    );
  }

  Widget _buildLanguageTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Language', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      subtitle: Text(_language, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.brandColor, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: const Text('English'), leading: const Icon(Icons.language), onTap: () { setState(() => _language = 'English'); Navigator.pop(context); }),
                ListTile(title: const Text('नेपाली (Nepali)'), leading: const Icon(Icons.language), onTap: () { setState(() => _language = 'Nepali'); Navigator.pop(context); }),
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
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Icon(icon, color: Colors.black, size: 20)),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {},
    );
  }
}
