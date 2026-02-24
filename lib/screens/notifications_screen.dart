import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color airbnbGrey = Color(0xFF717171);

    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Security Alert (सुरक्षा चेतावनी)',
        'desc': 'Never pay advance money before visiting. Avoid scams!',
        'time': '2m ago',
        'type': 'security',
        'isUnread': true,
      },
      {
        'title': 'New Message from Prakash',
        'desc': 'The villa in Baluwatar is ready for a visit.',
        'time': '1h ago',
        'type': 'message',
        'isUnread': true,
      },
      {
        'title': 'Listing Verified!',
        'desc': 'Your property "2BHK Flat" is now verified.',
        'time': '5h ago',
        'type': 'system',
        'isUnread': false,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'सूचनाहरू (Notifications)',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        itemCount: notifications.length,
        padding: const EdgeInsets.symmetric(vertical: 12),
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
        itemBuilder: (context, index) {
          final note = notifications[index];
          return Container(
            color: note['isUnread'] ? AppTheme.brandColor.withValues(alpha: 0.03) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(note['type']),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note['title'],
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: note['isUnread'] ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note['desc'],
                        style: GoogleFonts.outfit(fontSize: 13, color: airbnbGrey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note['time'],
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (note['isUnread'])
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.brandColor, shape: BoxShape.circle)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'security':
        icon = Icons.security_outlined;
        color = Colors.red;
        break;
      case 'message':
        icon = Icons.chat_bubble_outline;
        color = AppTheme.brandColor;
        break;
      default:
        icon = Icons.notifications_none;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
