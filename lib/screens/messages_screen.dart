import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../utils/supabase_service.dart';
import 'package:khozna/screens/chat_screen.dart' as chat_page;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['All', 'Unread', 'Groups'];

  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // Clear global badge first so the list shows 0 unread
    await SupabaseService.markAllMessagesAsRead();
    if (mounted) {
      await _loadChats();
    }
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.getConversations();
    if (mounted) {
      setState(() {
        _chats = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── BRANDED HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Messages',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.brandColor,
                      letterSpacing: -1.0,
                    ),
                  ),
                  Row(
                    children: [
                      // Search Icon
                      _buildHeaderIcon(Icons.search),
                      const SizedBox(width: 12),
                      // Settings Icon with Menu
                      PopupMenuButton<String>(
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        elevation: 4,
                        child: _buildHeaderIcon(Icons.settings_outlined),
                        onSelected: (val) {
                          if (val == 'export') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Exporting chats to PDF...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded,
                                    size: 20, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Text(
                                  'Export Chats (PDF)',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            enabled: false,
                            child: SizedBox(
                              width: 240,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded,
                                          size: 16, color: Colors.orange),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Important Notice',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Messages older than 30 days are permanently deleted for privacy. Please export your chats to your phone if you need to save details.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── FILTER TABS (AIRBNB STYLE WITH BRAND COLOR) ──
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _tabs.length,
                itemBuilder: (context, i) {
                  final label = _tabs[i];
                  final selected = i == _selectedTab;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.brandColor : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected ? AppTheme.brandColor : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── CHAT LIST ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _chats.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadChats,
                          child: ListView.builder(
                            itemCount: _chats.length,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            itemBuilder: (context, index) {
                              final chat = _chats[index];
                              final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                              Map<String, dynamic> otherUser;
                              if (chat['sender'] != null) {
                                otherUser = chat['sender'];
                              } else {
                                final participants = List<Map<String, dynamic>>.from(chat['profiles'] ?? []);
                                otherUser = participants.firstWhere(
                                  (p) => p['id'] != currentUserId,
                                  orElse: () => {'full_name': 'Unknown', 'avatar_url': null},
                                );
                              }

                              return _buildChatTile(chat, otherUser);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: AppTheme.brandColor, size: 22),
    );
  }

  void _showDeleteChatDialog(String chatId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Conversation',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
            'This will permanently delete this chat for you. The other person will still see it.',
            style: GoogleFonts.plusJakartaSans(color: Colors.grey[600])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.deleteChat(chatId);
              _loadChats();
            },
            child: Text('Delete', style: GoogleFonts.plusJakartaSans()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/icons/message.svg',
                width: 64,
                height: 64,
                colorFilter: const ColorFilter.mode(
                  AppTheme.brandColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Messages Yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'When you connect with property owners, your conversations will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat, Map<String, dynamic> otherUser) {
    final lastMessage = chat['last_message_text'] ?? 'No messages yet';
    final lastTime = chat['last_message_time'] != null 
        ? DateTime.parse(chat['last_message_time']).toLocal() 
        : null;
    final unreadCount = chat['unread_count'] ?? 0;

    return Dismissible(
      key: Key(chat['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.redAccent,
        margin: const EdgeInsets.only(bottom: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        bool confirm = false;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Conversation',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            content: Text(
                'Are you sure you want to delete this conversation?',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey[600])),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () {
                  confirm = true;
                  Navigator.pop(ctx);
                },
                child: Text('Delete', style: GoogleFonts.plusJakartaSans()),
              ),
            ],
          ),
        );
        return confirm;
      },
      onDismissed: (direction) async {
        await SupabaseService.deleteChat(chat['id']);
        _loadChats();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: InkWell(
          onLongPress: () => _showDeleteChatDialog(chat['id']),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => chat_page.ChatScreen(
                  chatId: chat['id'],
                  name: otherUser['full_name'] ?? 'User',
                  avatar: otherUser['avatar_url'] ?? '',
                  online: true,
                ),
              ),
            );
            // Refresh after returning from chat
            _loadChats();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: unreadCount > 0 
                  ? AppTheme.brandColor.withOpacity(0.03) 
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: unreadCount > 0 
                    ? AppTheme.brandColor.withOpacity(0.1) 
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                if (unreadCount > 0)
                  BoxShadow(
                    color: AppTheme.brandColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFF7F7F7),
                      backgroundImage: (otherUser['avatar_url'] != null && 
                                      otherUser['avatar_url']!.isNotEmpty && 
                                      !otherUser['avatar_url']!.contains('pravatar.cc'))
                          ? NetworkImage(otherUser['avatar_url'])
                          : null,
                      child: (otherUser['avatar_url'] == null || 
                              otherUser['avatar_url']!.isEmpty || 
                              otherUser['avatar_url']!.contains('pravatar.cc'))
                          ? Icon(Icons.person, color: Colors.grey[400], size: 28)
                          : null,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.brandColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            otherUser['full_name'] ?? 'User',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w700,
                              color: const Color(0xFF222222),
                            ),
                          ),
                          Text(
                            lastTime != null ? _formatTime(lastTime) : '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: unreadCount > 0 ? AppTheme.brandColor : const Color(0xFF717171),
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: unreadCount > 0 ? const Color(0xFF1A1A1A) : const Color(0xFF717171),
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(time).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
