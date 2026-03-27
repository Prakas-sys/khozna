import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../utils/supabase_service.dart';
import 'chat_screen.dart';

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
    _loadChats();
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87, size: 26),
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    'Messages',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.black87, size: 26),
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── SEARCH BAR ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search, color: AppTheme.brandColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        textAlignVertical: TextAlignVertical.center,
                        style: GoogleFonts.outfit(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search messages',
                          hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
                          isCollapsed: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(Icons.tune, color: Colors.grey[400], size: 18),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── FILTER TABS ──
            SizedBox(
              height: 40,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ..._tabs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final label = entry.value;
                      final selected = i == _selectedTab;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTab = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.brandColor : const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                              color: selected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.add, size: 18, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── CHAT LIST ──
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _chats.isEmpty
                  ? Center(child: Text('No messages yet', style: GoogleFonts.outfit(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _loadChats,
                      child: ListView.builder(
                        itemCount: _chats.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemBuilder: (context, index) {
                          final chat = _chats[index];
                          // Find the other participant (not the current user)
                          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                          final participants = List<Map<String, dynamic>>.from(chat['profiles'] ?? []);
                          final otherUser = participants.firstWhere(
                            (p) => p['id'] != currentUserId,
                            orElse: () => {'full_name': 'Unknown', 'avatar_url': null},
                          );
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      chatId: chat['id'],
                                      name: otherUser['full_name'] ?? 'User',
                                      avatar: otherUser['avatar_url'] ?? 'https://i.pravatar.cc/150',
                                      online: true, // Mock online status for now
                                    ),
                                  ),
                                );
                              },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar + online dot
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade100, width: 1),
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.grey[100],
                                    backgroundImage: NetworkImage(otherUser['avatar_url'] ?? 'https://i.pravatar.cc/150'),
                                  ),
                                ),
                                if (true) // Mock online status
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            // Name + message
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        otherUser['full_name'] ?? 'User',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Just now', // Mock time
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Check your messages', // Mock last message for now
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: Colors.grey[500],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                },
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
