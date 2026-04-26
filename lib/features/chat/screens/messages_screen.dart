import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/models/chat_model.dart';
import 'package:khozna/features/chat/repositories/chat_repository.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['All', 'Unread', 'Groups'];

  List<ChatConversation> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _loadChats();
    // Mark messages as read in background so it doesn't block loading the list
    SupabaseService.markAllMessagesAsRead().catchError((e) => debugPrint('Error marking read: $e'));
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getConversations();
      if (mounted) {
        setState(() {
          _chats = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      _buildHeaderIcon(Icons.search),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        elevation: 4,
                        child: _buildHeaderIcon(Icons.settings_outlined),
                        onSelected: (val) {
                          if (val == 'export') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exporting chats to PDF...')),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, size: 20, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Text('Export Chats (PDF)', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                              ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.brandColor : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: selected ? AppTheme.brandColor : const Color(0xFFE5E7EB)),
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
                  : _chats.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadChats,
                          color: AppTheme.brandColor,
                          child: ListView.builder(
                            itemCount: _chats.length,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            itemBuilder: (context, index) => _buildChatTile(_chats[index]),
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
        color: AppTheme.brandColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.brandColor.withOpacity(0.2)),
      ),
      child: Icon(icon, color: AppTheme.brandColor, size: 22),
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
                color: AppTheme.brandColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/icons/message.svg',
                width: 64,
                height: 64,
                colorFilter: const ColorFilter.mode(AppTheme.brandColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Messages Yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'When you connect with property owners, your conversations will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF6B7280), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(ChatConversation chat) {
    final lastMessage = chat.lastMessage ?? 'No messages yet';
    final unreadCount = chat.unreadCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => chat_page.ChatScreen(
                chatId: chat.id,
                name: chat.otherUserName,
                avatar: chat.otherUserAvatar,
                online: true,
              ),
            ),
          );
          _loadChats();
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Conversation'),
              content: const Text('Are you sure you want to permanently delete this entire chat?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ChatRepository.deleteChat(chat.id);
                    _loadChats();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: unreadCount > 0 ? AppTheme.brandColor.withOpacity(0.03) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unreadCount > 0 ? AppTheme.brandColor.withOpacity(0.1) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF7F7F7),
                backgroundImage: chat.otherUserAvatar.isNotEmpty ? CachedNetworkImageProvider(chat.otherUserAvatar) : null,
                child: chat.otherUserAvatar.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
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
                          chat.otherUserName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w700,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppTheme.brandColor, shape: BoxShape.circle),
                            child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: unreadCount > 0 ? Colors.black : Colors.grey,
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
    );
  }
}
