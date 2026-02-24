import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['All', 'Unread 5', 'Groups 8'];

  final List<Map<String, dynamic>> chats = [
    {
      'name': 'Jenny Wilson',
      'avatar': 'https://i.pravatar.cc/150?img=47',
      'lastMessage': "Hey there! How's your day going?",
      'time': '09:45 AM',
      'unread': 1,
      'online': true,
    },
    {
      'name': 'Cameron Williamson',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'lastMessage': 'Enjoy the weekend!',
      'time': '08:30 AM',
      'unread': 1,
      'online': false,
    },
    {
      'name': 'Leslie Alexander',
      'avatar': 'https://i.pravatar.cc/150?img=32',
      'lastMessage': 'We still on for coffee this morning?',
      'time': '07:25 AM',
      'unread': 1,
      'online': false,
    },
    {
      'name': 'Bessie Cooper',
      'avatar': 'https://i.pravatar.cc/150?img=45',
      'lastMessage': 'Just finished reviewing your work',
      'time': '04:56 PM',
      'unread': 0,
      'online': true,
    },
    {
      'name': 'Albert Flores',
      'avatar': 'https://i.pravatar.cc/150?img=15',
      'lastMessage': 'Those date work for me',
      'time': '02:16 PM',
      'unread': 0,
      'online': false,
    },
    {
      'name': 'Marvin McKinney',
      'avatar': 'https://i.pravatar.cc/150?img=18',
      'lastMessage': 'Is the flat still available?',
      'time': 'Yesterday',
      'unread': 0,
      'online': false,
    },
    {
      'name': 'Savannah Nguyen',
      'avatar': 'https://i.pravatar.cc/150?img=49',
      'lastMessage': 'Thanks for the info!',
      'time': 'Yesterday',
      'unread': 0,
      'online': false,
    },
  ];

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
              child: ListView.builder(
                itemCount: chats.length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final hasUnread = (chat['unread'] as int) > 0;
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          name: chat['name'],
                          avatar: chat['avatar'],
                          online: chat['online'],
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                                  backgroundImage: NetworkImage(chat['avatar']),
                                ),
                              ),
                              if (chat['online'] as bool)
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
                                      chat['name'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      chat['time'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: hasUnread ? AppTheme.brandColor : Colors.grey[500],
                                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        chat['lastMessage'],
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: hasUnread ? Colors.black87 : Colors.grey[500],
                                          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasUnread)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.brandColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            chat['unread'].toString(),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
