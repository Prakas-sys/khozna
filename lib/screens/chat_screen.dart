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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.brandColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '🙏',
                          style: TextStyle(fontSize: 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'नमस्ते',
                        style: GoogleFonts.outfit(
                          color: AppTheme.brandColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.2), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'नमस्ते',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.brandColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🙏', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
          ),

          // FLOATING MESSAGE INPUT
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.brandColor, size: 26),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF1A1A1A)),
                              decoration: InputDecoration(
                                hintText: 'तपाईंको सन्देश लेख्नुहोस्...',
                                hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey, size: 24),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.brandColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
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
