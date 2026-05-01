import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/features/auth/repositories/auth_repository.dart';
import 'package:khozna/features/profile/repositories/user_repository.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/features/property/repositories/property_repository.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/profile/repositories/notification_repository.dart';
import 'package:khozna/features/admin/repositories/admin_repository.dart';
import 'package:khozna/features/chat/repositories/chat_repository.dart';
import 'package:khozna/features/profile/repositories/vote_repository.dart';
import 'package:khozna/core/models/admin_model.dart';
import 'package:khozna/core/models/chat_model.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/core/models/property_model.dart';

/// Legacy wrapper for Supabase services. 
/// NOTE: Direct use of specialized repositories is preferred for new code.
class SupabaseService {
  static String get currentUserId => AuthRepository.currentUserId;

  // Profile / User
  static Future<UserModel?> getUserProfile(String userId) => UserRepository.getUserProfile(userId);
  static Future<void> syncUserWithSupabase(User user) => AuthRepository.syncUserWithSupabase(user);
  static Future<List<UserModel>> getAllUsers() => UserRepository.getAllUsers();
  static Future<List<UserModel>> searchUsers(String query) => UserRepository.searchUsers(query);
  static Future<void> deleteUserPermanently(String userId) => UserRepository.deleteUserPermanently(userId);
  static Future<void> reportUser(String userId, String reporterId, String reason) => UserRepository.reportUser(userId, reporterId, reason);
  static Future<List<UserReportModel>> getUserReports() => UserRepository.getUserReports();
  static Future<void> deleteReport(String reportId) => UserRepository.deleteReport(reportId);

  // Property
  static Future<void> fetchSavedPropertyIds() => PropertyRepository.fetchSavedPropertyIds();
  static Future<void> toggleSaveProperty(String propertyId) => PropertyRepository.toggleSaveProperty(propertyId);
  static Future<List<Property>> getSavedProperties() => PropertyRepository.getSavedProperties();
  static Future<List<Property>> getAllPropertiesForAdmin() => PropertyRepository.getAllPropertiesForAdmin();
  static Future<void> updatePropertyStatus(String id, String status) => PropertyRepository.updatePropertyStatus(id, status);
  static Future<void> deletePropertyPermanently(String id) => PropertyRepository.deletePropertyPermanently(id);

  // Booking
  static Future<void> fetchBookedPropertyIds() => BookingRepository.fetchBookedPropertyIds();
  static Future<void> bookProperty(String propertyId, String title, String ownerId) => BookingRepository.createBookingRequest(
    propertyId: propertyId, 
    propertyTitle: title, 
    ownerId: ownerId,
    moveInDate: DateTime.now().add(const Duration(days: 7)),
    durationMonths: 1,
    guestCount: 1,
    purpose: 'other',
    message: 'Interested in booking this property.',
  );
  static Future<void> createBookingRequest({
    required String propertyId,
    required String propertyTitle,
    required String ownerId,
    required DateTime moveInDate,
    required int durationMonths,
    required int guestCount,
    required String purpose,
    required String message,
  }) => BookingRepository.createBookingRequest(
    propertyId: propertyId,
    propertyTitle: propertyTitle,
    ownerId: ownerId,
    moveInDate: moveInDate,
    durationMonths: durationMonths,
    guestCount: guestCount,
    purpose: purpose,
    message: message,
  );
  static Future<void> approveBooking({
    required String propertyId,
    required String propertyTitle,
    required String requesterId,
    required String ownerName,
    required String notificationId,
  }) => BookingRepository.approveBooking(
    propertyId: propertyId,
    propertyTitle: propertyTitle,
    requesterId: requesterId,
    ownerName: ownerName,
    notificationId: notificationId,
  );
  static Future<void> rejectBooking({
    required String propertyId,
    required String propertyTitle,
    required String requesterId,
    required String notificationId,
    String? reason,
  }) => BookingRepository.rejectBooking(
    propertyId: propertyId,
    propertyTitle: propertyTitle,
    requesterId: requesterId,
    notificationId: notificationId,
    reason: reason,
  );
  static Future<void> cancelBooking(String propertyId) => BookingRepository.cancelBooking(propertyId);
  static Future<BookingModel?> getBookingById(String bookingId) => BookingRepository.getBookingById(bookingId);
  static Future<List<BookingModel>> getMyBookings() => BookingRepository.getMyBookings();
  static Future<List<BookingModel>> getBookingRequestsForOwner() => BookingRepository.getBookingRequestsForOwner();

  // Admin
  static Future<AdminStatsModel> getOwnerStats() => AdminRepository.getAdminStats();
  static Future<List<KycVerificationModel>> getPendingKycs() => AdminRepository.getPendingKycs();
  static Future<void> updateKycStatus(String kycId, String userId, String status, {String? reason}) => AdminRepository.updateKycStatus(kycId, userId, status, reason: reason);
  static Future<void> deleteKycPermanently(String kycId) => AdminRepository.deleteKycPermanently(kycId);
  static void listenToOwnerAlerts(Function onNewEvent) => AdminRepository.listenToAdminAlerts(onNewEvent);

  // Auth
  static Future<void> signInWithGoogleNative({required String idToken, String? accessToken}) => AuthRepository.signInWithIdToken(idToken: idToken, accessToken: accessToken);
  static Future<void> signInWithGoogle() => AuthRepository.signInWithGoogle();
  static Future<void> signInWithFacebook() => AuthRepository.signInWithFacebook();

  // Notifications
  static void initRealtimeListeners({Function? onOwnerEvent}) => NotificationRepository.initRealtimeListeners();
  static Future<void> saveDeviceToken(String token) => NotificationRepository.saveDeviceToken(token);
  static Future<List<Map<String, dynamic>>> getUserNotifications() => NotificationRepository.getUserNotifications();
  static Future<void> deleteNotification(String id) => NotificationRepository.deleteNotification(id);
  static Future<void> deleteAllNotifications() => NotificationRepository.deleteAllNotifications();
  static Future<void> markNotificationsAsRead() => NotificationRepository.markNotificationsAsRead();
  static Future<void> fetchUnreadNotificationCount() => NotificationRepository.fetchUnreadNotificationCount();

  // Chat
  static Future<List<ChatConversation>> getConversations() => ChatRepository.getConversations();
  static Future<String> getOrCreateChat(String otherUserId) => ChatRepository.getOrCreateChat(otherUserId);
  static Stream<List<ChatMessage>> getMessagesStream(String chatId) => ChatRepository.getMessagesStream(chatId);
  static Future<void> sendMessage(String chatId, String text) => ChatRepository.sendMessage(chatId, text);
  static Future<void> markChatAsRead(String chatId) => ChatRepository.markChatAsRead(chatId);
  static Future<void> fetchUnreadMessageCount() => ChatRepository.fetchUnreadMessageCount();
  static Future<void> markAllMessagesAsRead() => ChatRepository.markAllMessagesAsRead();
  static Future<void> deleteMessage(String messageId, String chatId) => ChatRepository.deleteMessage(messageId, chatId);
  static Future<void> deleteChat(String chatId) => ChatRepository.deleteChat(chatId);
  static Future<void> sendImageMessage(String chatId, String imageUrl) => ChatRepository.sendImageMessage(chatId, imageUrl);

  // Trust Votes
  static Future<int> getVoteCount(String targetId) => VoteRepository.getVoteCount(targetId);
  static Future<bool> hasVoted(String targetId) => VoteRepository.hasVoted(targetId);
  static Future<bool> castVote(String targetId) => VoteRepository.castVote(targetId);
  static Future<bool> removeVote(String targetId) => VoteRepository.removeVote(targetId);
}
