import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:khozna/core/models/chat_model.dart';
import 'package:khozna/features/chat/repositories/chat_repository.dart';
import 'package:khozna/features/profile/screens/owner_profile_screen.dart';
import '../widgets/chat_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String name;
  final String avatar;
  final bool online;
  final String ownerId;
  final bool isVerified;
  final bool isOwner;
  final String? initialMessage;

  const ChatScreen({
    super.key,
    this.chatId,
    required this.name,
    required this.avatar,
    required this.online,
    this.ownerId = '',
    this.isVerified = false,
    this.isOwner = false,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ScrollController _scrollController;
  late TextEditingController _messageController;
  final List<ChatMessage> _optimisticMessages = [];

  String? _activeChatId;
  final String _currentUserId =
      supabase.Supabase.instance.client.auth.currentUser?.id ?? '';

  late String _displayName;
  late String _displayAvatar;
  late String _displayLocation;
  late bool _isOwner;

  @override
  void initState() {
    super.initState();
    _activeChatId = widget.chatId;
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _displayName = widget.name;
    _displayAvatar = widget.avatar;
    _displayLocation = 'Kathmandu, Nepal';
    _isOwner = widget.isOwner;

    if (widget.ownerId.isNotEmpty) {
      _loadOwnerProfile();
      if (_activeChatId == null) {
        _initializeChat().then((_) {
          if (widget.initialMessage != null && _activeChatId != null) {
            _sendMessage(widget.initialMessage);
          }
        });
      }
    } else if (_activeChatId != null) {
      ChatRepository.markChatAsRead(_activeChatId!);
    }
  }

  Future<void> _loadOwnerProfile() async {
    final profile = await SupabaseService.getUserProfile(widget.ownerId);
    if (profile != null && mounted) {
      setState(() {
        _displayName = profile.fullName;
        _displayAvatar = profile.avatarUrl ?? _displayAvatar;
        _displayLocation = profile.areaName ?? 'Kathmandu, Nepal';
        _isOwner = profile.isOwner;
      });
    }
  }

  Future<void> _initializeChat() async {
    try {
      final id = await ChatRepository.getOrCreateChat(widget.ownerId);
      if (mounted) {
        setState(() => _activeChatId = id);
        ChatRepository.markChatAsRead(id);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage([String? text]) async {
    final msgText = text ?? _messageController.text.trim();
    if (msgText.isEmpty) return;
    if (text == null) _messageController.clear();

    final tempMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: _activeChatId ?? '',
      senderId: _currentUserId,
      text: msgText,
      createdAt: DateTime.now(),
      isOptimistic: true,
    );

    setState(() => _optimisticMessages.insert(0, tempMsg));
    if (_activeChatId == null && widget.ownerId.isNotEmpty) {
      await _initializeChat();
    }

    if (_activeChatId != null) {
      ChatRepository.sendMessage(_activeChatId!, msgText).catchError((e) {
        if (mounted) setState(() => _optimisticMessages.remove(tempMsg));
      });
    }
  }

  Future<void> _pickAndSendImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (_activeChatId == null && widget.ownerId.isNotEmpty) {
      await _initializeChat();
    }
    if (_activeChatId == null) return;

    try {
      final url = await CloudinaryService.uploadImage(File(picked.path));
      if (url != null) {
        await ChatRepository.sendImageMessage(_activeChatId!, url);
      }
    } catch (_) {}
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
        title: InkWell(
          onTap: () {
            if (widget.ownerId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerProfileScreen(
                    ownerId: widget.ownerId,
                    name: _displayName,
                    avatar: _displayAvatar,
                    location: _displayLocation,
                    totalListings: _isOwner ? 1 : 0,
                  ),
                ),
              );
            }
          },
          child: Row(
            children: [
              AppTheme.buildAvatarWidget(
                avatarUrl: _displayAvatar,
                radius: 18,
                name: _displayName,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.online ? 'Online' : 'Offline',
                    style: GoogleFonts.inter(
                      color: widget.online ? Colors.green : Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [const SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          const ChatBanner(),
          Expanded(
            child: _activeChatId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppTheme.brandColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/Message neww.svg',
                            width: 32,
                            height: 32,
                            colorFilter: const ColorFilter.mode(
                              AppTheme.brandColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Start a Conversation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Send a message to start the conversation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<List<ChatMessage>>(
                    stream: ChatRepository.getMessagesStream(_activeChatId!),
                    builder: (context, snapshot) {
                      final streamMessages = snapshot.data ?? [];
                      final streamTexts = streamMessages
                          .map((m) => m.text)
                          .toSet();
                      final pending = _optimisticMessages
                          .where((m) => !streamTexts.contains(m.text))
                          .toList();
                      final messages = [...pending, ...streamMessages];

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => MessageBubble(
                          message: messages[index],
                          isMe: messages[index].senderId == _currentUserId,
                          onLongPress:
                              messages[index].senderId == _currentUserId
                              ? () => _showDeleteDialog(messages[index].id)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          // if (widget.ownerId.isNotEmpty) QuickReplyBar(replies: _quickReplies, onReplySelected: _sendMessage),
          _buildInputArea(),
        ],
      ),
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Remove this message for everyone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ChatRepository.deleteMessage(id, _activeChatId!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              AppTheme.buildAvatarWidget(
                avatarUrl: _displayAvatar,
                radius: 50,
                name: _displayName,
              ),
              const SizedBox(height: 16),
              Text(
                _displayName,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isOwner ? 'Property Owner' : 'Guest',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionCircle(
                    Icons.person_rounded,
                    'Profile',
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OwnerProfileScreen(
                            ownerId: widget.ownerId,
                            name: _displayName,
                            avatar: _displayAvatar,
                            location: _displayLocation,
                            totalListings: _isOwner ? 1 : 0,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 32),
                  _buildActionCircle(
                    Icons.report_problem_rounded,
                    'Report',
                    Colors.red,
                    () {},
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF6B7280),
                        size: 22,
                      ),
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.inter(fontSize: 15),
                        onChanged: (val) => setState(() {}),
                        onSubmitted: (val) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFF6B7280),
                        size: 22,
                      ),
                      onPressed: _pickAndSendImage,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                if (_messageController.text.trim().isNotEmpty) {
                  _sendMessage();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _messageController.text.trim().isNotEmpty
                      ? AppTheme.brandColor
                      : AppTheme.brandColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
