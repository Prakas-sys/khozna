import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/chat_model.dart';
import 'package:khozna/features/chat/repositories/chat_repository.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:intl/intl.dart';

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
  }

  Future<void> _loadChats() async {
    if (!mounted) return;

    // 1. Instant rendering from cache if available
    if (chatListCache.value != null && _chats.isEmpty) {
      setState(() {
        _chats = chatListCache.value!;
        _isLoading = false;
      });
    } else if (_chats.isEmpty) {
      setState(() => _isLoading = true);
    }

    // 2. Fetch fresh data
    try {
      final data = await SupabaseService.getConversations();
      if (mounted) {
        setState(() {
          _chats = data;
          _isLoading = false;
        });
        chatListCache.value = data; // Update cache
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
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: -1.2,
                    ),
                  ),
                  Row(
                    children: [
                      _buildHeaderIcon(Icons.search),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white,
                        elevation: 4,
                        child: _buildHeaderIcon(Icons.settings_outlined),
                        onSelected: (val) {
                          if (val == 'export') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Exporting chats to PDF...'),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 20,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Export Chats (PDF)',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                      margin: const EdgeInsets.only(right: 10),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.brandColor.withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppTheme.brandColor.withOpacity(0.3)
                              : const Color(0xFFE5E7EB),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? AppTheme.brandColor
                              : const Color(0xFF6B7280),
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.brandColor,
                      ),
                    )
                  : _chats.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadChats,
                      color: AppTheme.brandColor,
                      child: ListView.builder(
                        itemCount: _chats.length,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) =>
                            _buildChatTile(_chats[index]),
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
        color: const Color(
          0xFFF3F4F6,
        ), // Subtle grey background instead of brand color
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Icon(icon, color: Colors.black, size: 22),
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
                'assets/icons/Message neww.svg',
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
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'When you connect with property owners, your conversations will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF666666),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(ChatConversation chat) {
    final lastMessage = chat.lastMessage ?? 'No messages yet';
    final unreadCount = chat.unreadCount;
    final timeStr = _formatLastMessageTime(chat.lastMessageTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
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
          _showDeleteConfirm(chat);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF0F2F5),
                backgroundImage: chat.otherUserAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(chat.otherUserAvatar)
                    : null,
                child: chat.otherUserAvatar.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey, size: 30)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chat.otherUserName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111B21),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: unreadCount > 0
                                ? AppTheme.brandColor
                                : const Color(0xFF667781),
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF667781),
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: AppTheme.brandColor,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            child: Center(
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
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

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0 && now.day == time.day) {
      return DateFormat('h:mm a').format(time);
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != time.day)) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('MM/dd/yy').format(time);
    }
  }

  void _showDeleteConfirm(ChatConversation chat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this entire chat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
  }
}
