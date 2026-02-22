import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final String avatar;
  final bool online;

  const ChatScreen({
    super.key,
    required this.name,
    required this.avatar,
    required this.online,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _animationController.addListener(() {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _animationController.value * maxScroll;
        _scrollController.jumpTo(currentScroll);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(widget.avatar),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Owner • ${widget.online ? 'Online' : 'Offline'}',
                  style: GoogleFonts.outfit(
                    color: widget.online ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            )
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call, color: Colors.black, size: 24), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black, size: 24), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // SAFETY BANNER (Matching Image Style)
          Container(
            height: 45,
            width: double.infinity,
            color: const Color(0xFFFFEBEE), // Pinkish Red from Image
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'अग्रिम वा आधा पैसा कहिल्यै नपठाउनुहोस्! • Never send advance or half payment before visiting the property!',
                        style: GoogleFonts.outfit(
                          color: Colors.red[800], 
                          fontWeight: FontWeight.bold, 
                          fontSize: 14
                        ),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // EMPTY STATE (Matching Image)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[200]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Start a conversation',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // MESSAGE INPUT
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Type message...',
                          hintStyle: GoogleFonts.outfit(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: AppTheme.brandColor,
                    radius: 24,
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
