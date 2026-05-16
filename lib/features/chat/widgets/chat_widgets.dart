import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/chat_model.dart';

class ChatBanner extends StatelessWidget {
  final ScrollController controller;
  const ChatBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: double.infinity,
      color: const Color(0xFFFFEBEE),
      child: ListView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'अग्रिम पैसा कहिल्यै नपठाउनुहोस्! • Never send advance payment before visiting!',
                  style: GoogleFonts.inter(
                    color: Colors.red[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 60),
                const Icon(Icons.shield_rounded, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Use KHOZNA Safe Payment for 100% money protection. • खोज्न सुरक्षित भुक्तानी प्रयोग गर्नुहोस्!',
                  style: GoogleFonts.inter(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 0.5),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: (message.imageUrl != null)
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: message.isDeleted
                    ? Colors.grey[100]
                    : isMe
                    ? AppTheme.brandColor
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: isMe
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                border: Border.all(
                  color: message.isDeleted
                      ? Colors.grey.shade200
                      : isMe
                      ? Colors.black.withOpacity(0.08)
                      : Colors.grey.shade200,
                ),
              ),
              child: message.isDeleted
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        '🗑️ Message deleted',
                        style: GoogleFonts.inter(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : message.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isMe ? 15 : 3),
                        bottomRight: Radius.circular(isMe ? 3 : 15),
                      ),
                      child: KhoznaImage(
                        imageUrl: message.imageUrl!,
                        width: MediaQuery.sizeOf(context).width * 0.6,
                        height: MediaQuery.sizeOf(context).width * 0.5,
                        fit: BoxFit.cover,
                      ),
                    )
                  : message.audioUrl != null
                  ? VoiceMessageBubble(
                      audioUrl: message.audioUrl!,
                      duration: message.audioDuration ?? 0,
                      isMe: isMe,
                    )
                  : Text(
                      message.text ?? '',
                      style: GoogleFonts.inter(
                        color: isMe ? Colors.white : const Color(0xFF1A1A1A),
                        fontSize: 16,
                        height: 1.25,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4, left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMe) ...[
                    Icon(
                      message.isOptimistic
                          ? Icons.access_time_rounded
                          : (message.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded),
                      size: 14,
                      color: message.isRead ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    DateFormat('h:mm a').format(message.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int duration;
  final bool isMe;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPlaying = !_isPlaying),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.white.withOpacity(0.2) : AppTheme.brandColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isMe ? Colors.white : AppTheme.brandColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(15, (index) {
                    final height = [10, 15, 8, 20, 12, 18, 14, 10, 16, 22, 10, 14, 18, 12, 8][index];
                    return Container(
                      width: 2,
                      height: height.toDouble(),
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: widget.isMe ? Colors.white.withOpacity(0.6) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '0:${widget.duration.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: widget.isMe ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickReplyBar extends StatelessWidget {
  final List<String> replies;
  final Function(String) onReplySelected;
  const QuickReplyBar({
    super.key,
    required this.replies,
    required this.onReplySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: replies.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => onReplySelected(replies[index]),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  replies[index],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
