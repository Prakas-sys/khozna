import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/features/auth/repositories/auth_repository.dart';
import 'package:khozna/features/profile/repositories/user_repository.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/features/property/repositories/property_repository.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/profile/repositories/notification_repository.dart';
import 'package:khozna/features/chat/repositories/chat_repository.dart';
import 'package:khozna/features/profile/repositories/vote_repository.dart';
import 'package:khozna/core/models/chat_model.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/core/models/property_model.dart';

/// Legacy wrapper for Supabase services.
/// NOTE: Direct use of specialized repositories is preferred for new code.
class SupabaseService {
  static String get currentUserId => AuthRepository.currentUserId;

  // Profile / User
  static Future<UserModel?> getUserProfile(String userId) =>
      UserRepository.getUserProfile(userId);
  static Future<void> syncUserWithSupabase(User user) =>
      AuthRepository.syncUserWithSupabase(user);
  static Future<List<UserModel>> getAllUsers() => UserRepository.getAllUsers();
  static Future<List<UserModel>> searchUsers(String query) =>
      UserRepository.searchUsers(query);
  static Future<void> deleteUserPermanently(String userId) =>
      UserRepository.deleteUserPermanently(userId);
  static Future<void> reportUser(
    String userId,
    String reporterId,
    String reason,
  ) => UserRepository.reportUser(userId, reporterId, reason);
  static Future<List<UserReportModel>> getUserReports() =>
      UserRepository.getUserReports();
  static Future<void> deleteReport(String reportId) =>
      UserRepository.deleteReport(reportId);

  // Property
  static Future<void> fetchSavedPropertyIds() =>
      PropertyRepository.fetchSavedPropertyIds();
  static Future<void> toggleSaveProperty(String propertyId) =>
      PropertyRepository.toggleSaveProperty(propertyId);
  static Future<List<Property>> getSavedProperties() =>
      PropertyRepository.getSavedProperties();
  static Future<List<Property>> getAllPropertiesForAdmin() =>
      PropertyRepository.getAllPropertiesForAdmin();
  static Future<void> updatePropertyStatus(String id, String status) =>
      PropertyRepository.updatePropertyStatus(id, status);
  static Future<void> deletePropertyPermanently(String id) =>
      PropertyRepository.deletePropertyPermanently(id);

  // Visit Requests
  static Future<void> fetchBookedPropertyIds() =>
      BookingRepository.fetchBookedPropertyIds();

  static Future<void> requestVisit(
    String propertyId,
    String title,
    String ownerId,
  ) => BookingRepository.createBookingRequest(
    propertyId: propertyId,
    ownerId: ownerId,
    checkIn: DateTime.now().add(const Duration(days: 1)),
    checkOut: DateTime.now().add(const Duration(days: 31)),
    totalPrice: 0,
    message: 'Interested in visiting this property.',
  );

  static Future<void> createVisitRequest({
    required String propertyId,
    required String ownerId,
    required DateTime visitDate,
    required String message,
  }) => BookingRepository.createBookingRequest(
    propertyId: propertyId,
    ownerId: ownerId,
    checkIn: visitDate,
    checkOut: visitDate.add(const Duration(days: 30)),
    totalPrice: 0,
    message: message,
  );

  static Future<void> approveVisit({
    String? bookingId,
    String? propertyId,
    String? propertyTitle,
    String? requesterId,
    String? ownerName,
    String? notificationId,
  }) async {
    if (bookingId != null) {
      await BookingRepository.approveRequest(bookingId);
      if (notificationId != null) {
        await NotificationRepository.deleteNotification(notificationId);
      }
    }
  }

  static Future<void> rejectVisit({
    String? bookingId,
    String? propertyId,
    String? propertyTitle,
    String? requesterId,
    String? notificationId,
    String? reason,
  }) async {
    if (bookingId != null) {
      await BookingRepository.rejectRequest(bookingId);
      if (notificationId != null) {
        await NotificationRepository.deleteNotification(notificationId);
      }
    }
  }

  static Future<void> cancelVisit(String bookingId) =>
      BookingRepository.rejectRequest(bookingId);
  static Future<BookingModel?> getVisitById(String bookingId) =>
      BookingRepository.getBookingById(bookingId);
  static Future<List<BookingModel>> getMyVisits() =>
      BookingRepository.getMyBookings();
  static Future<List<BookingModel>> getVisitRequestsForOwner() async {
    final data = await BookingRepository.getOwnerBookings();
    return data.map((e) => BookingModel.fromMap(e)).toList();
  }

  // Auth
  static Future<void> signInWithGoogleNative({
    required String idToken,
    String? accessToken,
  }) => AuthRepository.signInWithIdToken(
    idToken: idToken,
    accessToken: accessToken,
  );
  static Future<void> signInWithGoogle() => AuthRepository.signInWithGoogle();
  static Future<void> signInWithFacebook() =>
      AuthRepository.signInWithFacebook();

  // Notifications
  static Future<List<Property>> getAllProperties() async {
    try {
      final response = await Supabase.instance.client
          .from('properties')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((p) => Property.fromMap(p)).toList();
    } catch (e) {
      debugPrint('Error fetching all properties: $e');
      return [];
    }
  }

  static void initRealtimeListeners({Function? onOwnerEvent}) =>
      NotificationRepository.initRealtimeListeners();
  static Future<void> saveDeviceToken(String token) =>
      NotificationRepository.saveDeviceToken(token);
  static Future<List<Map<String, dynamic>>> getUserNotifications() =>
      NotificationRepository.getUserNotifications();
  static Future<void> deleteNotification(String id) =>
      NotificationRepository.deleteNotification(id);
  static Future<void> deleteAllNotifications() =>
      NotificationRepository.deleteAllNotifications();
  static Future<void> markNotificationsAsRead() =>
      NotificationRepository.markNotificationsAsRead();
  static Future<void> fetchUnreadNotificationCount() =>
      NotificationRepository.fetchUnreadNotificationCount();

  // Chat
  static Future<List<ChatConversation>> getConversations() =>
      ChatRepository.getConversations();
  static Future<String> getOrCreateChat(String otherUserId) =>
      ChatRepository.getOrCreateChat(otherUserId);
  static Stream<List<ChatMessage>> getMessagesStream(String chatId) =>
      ChatRepository.getMessagesStream(chatId);
  static Future<void> sendMessage(String chatId, String text) =>
      ChatRepository.sendMessage(chatId, text);
  static Future<void> markChatAsRead(String chatId) =>
      ChatRepository.markChatAsRead(chatId);
  static Future<void> fetchUnreadMessageCount() =>
      ChatRepository.fetchUnreadMessageCount();
  static Future<void> markAllMessagesAsRead() =>
      ChatRepository.markAllMessagesAsRead();
  static Future<void> deleteMessage(String messageId, String chatId) =>
      ChatRepository.deleteMessage(messageId, chatId);
  static Future<void> deleteChat(String chatId) =>
      ChatRepository.deleteChat(chatId);
  static Future<void> sendImageMessage(String chatId, String imageUrl) =>
      ChatRepository.sendImageMessage(chatId, imageUrl);

  // Trust Votes
  static Future<int> getVoteCount(String targetId) =>
      VoteRepository.getVoteCount(targetId);
  static Future<bool> hasVoted(String targetId) =>
      VoteRepository.hasVoted(targetId);
  static Future<bool> castVote(String targetId) =>
      VoteRepository.castVote(targetId);
  static Future<bool> removeVote(String targetId) =>
      VoteRepository.removeVote(targetId);
}
