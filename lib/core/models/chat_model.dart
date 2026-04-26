class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;
  final bool isDeleted;
  final bool isOptimistic;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
    this.isDeleted = false,
    this.isOptimistic = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'].toString(),
      chatId: map['chat_id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      text: map['text'],
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()).toLocal(),
      isRead: map['is_read'] == true,
      isDeleted: map['is_deleted'] == true,
      isOptimistic: map['is_optimistic'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'is_deleted': isDeleted,
    };
  }
}

class ChatConversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOtherUserOnline;

  ChatConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOtherUserOnline = false,
  });

  factory ChatConversation.fromMap(Map<String, dynamic> map, String currentUserId) {
    // Determine which user is the "other" user
    final bool isUser1Me = map['user1_id'] == currentUserId;
    final otherUser = isUser1Me ? map['user2'] : map['user1'];

    return ChatConversation(
      id: map['id'],
      otherUserId: isUser1Me ? map['user2_id'] : map['user1_id'],
      otherUserName: otherUser?['full_name'] ?? 'Khozna User',
      otherUserAvatar: otherUser?['avatar_url'] ?? '',
      lastMessage: map['last_message'],
      lastMessageTime: DateTime.parse(map['updated_at']).toLocal(),
      unreadCount: map['unread_count'] ?? 0,
    );
  }
}
