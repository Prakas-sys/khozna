import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color airbnbGrey = Color(0xFF717171);

    final List<Map<String, dynamic>> chats = List.generate(10, (index) => {
      'name': 'User Name $index',
      'avatar': 'https://i.pravatar.cc/150?img=${index + 10}',
      'lastMessage': 'Hey! Is the property still available for viewing tomorrow?',
      'time': '12:45 PM',
      'unread': index % 2 == 0 ? 2 : 0,
      'online': index % 3 == 0,
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        title: Text(
          'Messages',
          style: GoogleFonts.playfairDisplay(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR (Matching Image)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search messages...',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // MESSAGES LIST
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final chat = chats[index];
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(name: chat['name'], avatar: chat['avatar'], online: chat['online']))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Row(
                      children: [
                        // AVATAR WITH ONLINE DOT
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: NetworkImage(chat['avatar']),
                            ),
                            if (chat['online'])
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                ),
                              )
                          ],
                        ),
                        const SizedBox(width: 16),
                        // NAME AND MESSAGE (Fixed with Flexible/Expanded)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      chat['name'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    chat['time'],
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
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
                                        fontSize: 14,
                                        color: chat['unread'] > 0 ? Colors.black87 : Colors.grey[600],
                                        fontWeight: chat['unread'] > 0 ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (chat['unread'] > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.brandColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        chat['unread'].toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
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
    );
  }
}
