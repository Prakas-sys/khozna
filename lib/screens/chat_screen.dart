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
  late TextEditingController _messageController;
  late ScrollController _bannerScrollController;

  final List<Map<String, dynamic>> _messages = [];

  // Owner auto-reply messages pool
  final List<String> _ownerReplies = [
    'हजुर, कोठा अझै खाली छ! कहिले हेर्न आउनुहुन्छ?',
    'ठिकै छ। तपाईंसँग कुरा गर्न पाउँदा खुसी लाग्यो! 😊',
    'हजुर, पानी र बिजुली दुवै सुविधा छ। २४ सै घण्टा।',
    'पार्किङको राम्रो व्यवस्था छ। बाइक र कार दुवैको लागि।',
    'भाडा मिलाउन सकिन्छ। सिधै भेटेर कुरा गरौं!',
    'ठिकै छ! भोलि बिहान १० बजे हेर्न आउनुस् न।',
    'WiFi को राम्रो सुविधा छ। ५० Mbps को कनेक्शन छ।',
    'धन्यवाद! कुनै अन्य प्रश्न भए सोध्नुस्। 🙏',
  ];
  int _replyIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _bannerScrollController = ScrollController();

    // Auto-scroll banner animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBannerAnimation();
    });

    // Pre-load owner welcome messages - EMPTY AS REQUESTED
    _messages.clear();
  }

  void _startBannerAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_bannerScrollController.hasClients) {
        final maxScroll = _bannerScrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          await _bannerScrollController.animateTo(
            maxScroll,
            duration: Duration(milliseconds: (maxScroll * 40).toInt()),
            curve: Curves.linear,
          );
          await Future.delayed(const Duration(seconds: 1));
          if (_bannerScrollController.hasClients) {
            _bannerScrollController.jumpTo(0);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _bannerScrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      final userMsg = _messageController.text.trim();
      setState(() {
        _messages.add({
          'text': userMsg,
          'isMe': true,
          'time': 'अहिले',
        });
        _messageController.clear();
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Owner auto-reply after short delay - REMOVED AS REQUESTED
      /*
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _messages.add({
              'text': _ownerReplies[_replyIndex % _ownerReplies.length],
              'isMe': false,
              'time': 'अहिले',
            });
            _replyIndex++;
          });
          // Scroll again after owner reply
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
      */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.avatar),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Owner • ${widget.online ? 'Online' : 'Offline'}',
                  style: GoogleFonts.outfit(
                    color: widget.online ? Colors.green : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            )
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined, color: Colors.black, size: 22), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black, size: 22), onPressed: () {}),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // SAFETY BANNER
          Container(
            height: 36,
            width: double.infinity,
            color: const Color(0xFFFFEBEE),
            child: ListView(
              controller: _bannerScrollController,
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'अग्रिम पैसा कहिल्यै नपठाउनुहोस्! • Never send advance payment before visiting! • कोठा हेरेर मात्र पैसा दिनुहोला! • Only pay after seeing the room!',
                        style: GoogleFonts.outfit(
                          color: Colors.red[800], 
                          fontWeight: FontWeight.w600, 
                          fontSize: 12
                        ),
                      ),
                      const SizedBox(width: 200), // Extra space for smooth loop
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // CHAT MESSAGES
          Expanded(
            child: _messages.isEmpty 
              ? const SizedBox.shrink() // Removed bulky UI as requested
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final bool isMe = msg['isMe'];
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.brandColor : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg['text'],
                              style: GoogleFonts.outfit(
                                color: isMe ? Colors.white : const Color(0xFF1A1A1A),
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  msg['time'],
                                  style: GoogleFonts.outfit(
                                    color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey[500],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.done_all_rounded, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),

          // GREETING ABOVE INPUT (CLICKABLE)
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                _messageController.text = 'नमस्ते 🙏';
                _sendMessage();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'नमस्ते',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('🙏', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),

          // FLOATING MESSAGE INPUT - Simplified Single Layer
          // PERFECT CLEAN FLOATING INPUT
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 50),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9), // Slightly deeper slate for better float contrast
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blueGrey, size: 24),
                                onPressed: () {},
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                maxLines: 5,
                                minLines: 1,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type message...',
                                  hintStyle: GoogleFonts.outfit(
                                    color: const Color(0xFF94A3B8), 
                                    fontSize: 15
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.brandColor, AppTheme.brandColor.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brandColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
