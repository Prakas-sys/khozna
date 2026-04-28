import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/models/chat_model.dart';
import 'package:khozna/core/utils/app_notifiers.dart';

class ChatRepository {
  static final _client = Supabase.instance.client;

  static Future<List<ChatConversation>> getConversations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // 1. Fetch chats
    final response = await _client
        .from('chats')
        .select('*')
        .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
        .not('deleted_for', 'cs', '{"${user.id}"}')
        .order('updated_at', ascending: false);

    final List chatsData = response as List;
    if (chatsData.isEmpty) return [];

    // 2. Identify all "other" user IDs to fetch profiles in bulk
    final Set<String> otherUserIds = {};
    for (var chat in chatsData) {
      final u1 = chat['user1_id']?.toString();
      final u2 = chat['user2_id']?.toString();
      if (u1 != null && u1 != user.id) otherUserIds.add(u1);
      else if (u2 != null && u2 != user.id) otherUserIds.add(u2);
    }

    // 3. Fetch profiles
    Map<String, dynamic> profiles = {};
    if (otherUserIds.isNotEmpty) {
      final profilesResponse = await _client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', otherUserIds.toList());
      
      for (var p in (profilesResponse as List)) {
        profiles[p['id']] = p;
      }
    }

    // 4. Map to models and deduplicate by other user
    final Map<String, ChatConversation> uniqueChats = {};
    for (var e in chatsData) {
      final u1 = e['user1_id']?.toString();
      final u2 = e['user2_id']?.toString();
      final otherId = (u1 != user.id) ? u1 : u2;
      if (otherId == null) continue;
      
      final profile = profiles[otherId];
      final chatTime = DateTime.parse(e['updated_at'] ?? DateTime.now().toIso8601String()).toLocal();
      
      final chat = ChatConversation(
        id: e['id'],
        otherUserId: otherId,
        otherUserName: profile?['full_name'] ?? 'Khozna User',
        otherUserAvatar: profile?['avatar_url'] ?? '',
        lastMessage: e['last_message_text'],
        lastMessageTime: chatTime,
        unreadCount: 0, // In a real app, calculate this or fetch from view
      );
      
      if (!uniqueChats.containsKey(otherId) || chatTime.isAfter(uniqueChats[otherId]!.lastMessageTime)) {
        uniqueChats[otherId] = chat;
      }
    }
    
    final sortedList = uniqueChats.values.where((chat) => chat.otherUserName != 'Khozna User').toList();
    sortedList.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return sortedList;
  }

  static Future<String> getOrCreateChat(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // Sort IDs to ensure consistent chat room identification
    final ids = [user.id, otherUserId]..sort();
    final u1 = ids[0];
    final u2 = ids[1];

    final response = await _client
        .from('chats')
        .select('id')
        .eq('user1_id', u1)
        .eq('user2_id', u2)
        .maybeSingle();

    if (response != null) {
      // If the chat was deleted for this user, restore it
      await _client.rpc('clear_chat_deletion', params: {
        'p_chat_id': response['id'],
        'p_user_id': user.id
      });
      return response['id'];
    }

    final newChat = await _client.from('chats').insert({
      'user1_id': u1,
      'user2_id': u2,
      'participants': [u1, u2],
      'deleted_for': [],
    }).select('id').single();

    return newChat['id'];
  }

  static Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => ChatMessage.fromMap(e)).toList());
  }

  static Future<void> sendMessage(String chatId, String text) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    
    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'text': text,
    });

    // Clear deletion status for both if a new message is sent (so it reappears for both)
    // Or just for the sender if you want to be more specific. Usually, if I send a message, I expect to see the chat.
    await _client.rpc('clear_chat_deletion', params: {
      'p_chat_id': chatId,
      'p_user_id': user.id
    });
  }

  static Future<void> sendImageMessage(String chatId, String imageUrl) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'image_url': imageUrl,
    });

    await _client.rpc('clear_chat_deletion', params: {
      'p_chat_id': chatId,
      'p_user_id': user.id
    });
  }

  static Future<void> markChatAsRead(String chatId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('chat_id', chatId)
        .neq('sender_id', user.id);
  }

  static Future<void> fetchUnreadMessageCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final response = await _client
        .from('messages')
        .select()
        .eq('is_read', false)
        .neq('sender_id', user.id)
        .count(CountOption.exact);
    messageBadgeCount.value = response.count;
  }

  static Future<void> markAllMessagesAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('is_read', false)
        .neq('sender_id', user.id);
  }

  static Future<void> deleteMessage(String messageId, String chatId) async {
    await _client.from('messages').delete().eq('id', messageId);
  }

  static Future<void> deleteChat(String chatId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Use RPC to add user to deleted_for array safely
    await _client.rpc('mark_chat_as_deleted_for_user', params: {
      'p_chat_id': chatId,
      'p_user_id': user.id
    });
  }
}
