import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/supabase_service.dart';
import 'owner_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.getUserNotifications();
    setState(() {
      _notifications = data;
      _isLoading = false;
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
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
          'Notifications (सूचनाहरू)',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor, strokeWidth: 2))
        : RefreshIndicator(
            onRefresh: _fetchNotifications,
            color: AppTheme.brandColor,
            child: _notifications.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _notifications.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final note = _notifications[index];
                    final sender = note['sender'];
                    final String id = note['id'].toString();
                    
                    return Dismissible(
                      key: Key(id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) async {
                        setState(() => _notifications.removeAt(index));
                        await SupabaseService.deleteNotification(id);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        color: Colors.red.shade50,
                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Handle navigation based on type? 
                          // For now just keep it simple
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // PROFILE AVATAR OR ICON
                              GestureDetector(
                                onTap: () {
                                  if (sender != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OwnerProfileScreen(
                                          name: sender['full_name'] ?? 'Khozna User',
                                          avatar: sender['avatar_url'] ?? 'https://via.placeholder.com/150',
                                          location: 'Kathmandu, Nepal',
                                          totalListings: 0,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Colors.grey[100],
                                      backgroundImage: sender != null && sender['avatar_url'] != null
                                          ? NetworkImage(sender['avatar_url'])
                                          : null,
                                      child: sender == null || sender['avatar_url'] == null
                                          ? Icon(Icons.person, color: Colors.grey[400], size: 28)
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(note['type']),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: Icon(_getTypeIcon(note['type']), size: 10, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              
                              // CONTENT
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: GoogleFonts.outfit(fontSize: 14, color: Colors.black, height: 1.3),
                                        children: [
                                          TextSpan(
                                            text: sender != null ? sender['full_name'] + ' ' : '',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: note['message'] ?? note['title'] ?? ''),
                                          TextSpan(
                                            text: '  ' + _formatTime(note['created_at']),
                                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // DELETE BUTTON (SUBTLE)
                              IconButton(
                                onPressed: () => _confirmDelete(id, index),
                                icon: Icon(Icons.more_horiz, color: Colors.grey[300]),
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

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
                child: Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey[200]),
              ),
              const SizedBox(height: 20),
              Text(
                'No activity yet',
                style: GoogleFonts.outfit(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Notifications about your listings,\nbookings, and saves will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id, int index) async {
    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Remove notification?', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('This will permanently delete this alert from your feed.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _notifications.removeAt(index));
      await SupabaseService.deleteNotification(id);
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'love_alert': return Icons.favorite_rounded;
      case 'booking_alert':
      case 'saved_booking_alert': return Icons.home_work_rounded;
      case 'message': return Icons.chat_bubble_rounded;
      case 'kyc_update': return Icons.verified_user_rounded;
      case 'security': return Icons.security_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'love_alert': return Colors.red;
      case 'booking_alert':
      case 'saved_booking_alert': return Colors.orange;
      case 'message': return AppTheme.brandColor;
      case 'kyc_update': return Colors.green;
      case 'security': return Colors.black;
      default: return Colors.grey;
    }
  }
}
