import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/features/profile/screens/owner_profile_screen.dart';
import 'package:khozna/features/property/screens/booking_status_screen.dart';
import 'package:khozna/features/property/screens/owner_bookings_screen.dart';
import 'package:khozna/features/property/screens/payment_choice_screen.dart';
import 'package:khozna/widgets/trust_badge.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.getUserNotifications();
    setState(() {
      _notifications = data;
      _isLoading = false;
    });
    // Mark all as read when the screen is opened/refreshed
    await SupabaseService.markNotificationsAsRead();
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'भर्खरै (Just now)';
      if (diff.inMinutes < 60) return '${diff.inMinutes}मि अघि (${diff.inMinutes}m)';
      if (diff.inHours < 24) return '${diff.inHours}घण्टा अघि (${diff.inHours}h)';
      return '${diff.inDays}दिन अघि (${diff.inDays}d)';
    } catch (_) {
      return '';
    }
  }

  String _getHumanMessage(Map<String, dynamic> note, dynamic sender) {
    final type = note['type']?.toString() ?? '';
    final String message = (note['message'] ?? note['title'] ?? '').toString();
    final name = sender?['full_name'] ?? 'Someone';

    // Remove app name repetition
    String cleanMessage = message.replaceAll('Khozna app', '').trim();
    if (cleanMessage.startsWith('ले')) cleanMessage = cleanMessage.substring(1).trim();

    if (type == 'booking_request' || cleanMessage.contains('कोठा हेर्न अनुरोध')) {
      return '👀 $name wants to visit your room.';
    }
    if (type == 'booking_approved' || cleanMessage.contains('स्वीकृत')) {
      return '✅ Your visit request was accepted!';
    }
    if (type == 'chat' || type == 'message') {
      return '💬 New message from $name';
    }
    if (type == 'payment_received' || cleanMessage.contains('भुक्तानी')) {
      return '💰 Payment received from $name!';
    }

    return cleanMessage.isEmpty ? 'New update for you' : cleanMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'सूचनाहरू',
          style: GoogleFonts.mukta(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.red,
                size: 24,
              ),
              tooltip: 'Clear All',
              onPressed: _confirmClearAll,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.brandColor,
                strokeWidth: 2,
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: AppTheme.brandColor,
              child: _notifications.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.75,
                        alignment: Alignment.center,
                        child: _buildEmptyStateContent(),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      itemBuilder: (context, index) {
                        final note = _notifications[index];
                        final sender = note['sender'];
                        final String id = note['id'].toString();
                        final String type = note['type']?.toString() ?? '';

                        // -- SPECIAL: Booking Request card with Approve/Reject --
                        final String msgText = (note['message'] ?? '').toString();
                        final bool isBookingRequest = type == 'booking_request' || 
                            msgText.contains('कोठा हेर्न अनुरोध') || 
                            msgText.contains('visit request');
                        
                        if (isBookingRequest) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildBookingRequestCard(note, id, index, sender),
                          );
                        }

                        // -- SPECIAL: Payment Received card --
                        if (type == 'payment_received') {
                          return _buildPaymentReceivedCard(note, id, index, sender);
                        }

                        // -- SPECIAL: Booking Approved (Guest) card --
                        final isApproved = (note['title']?.toString().contains('स्वीकृत') == true) || (note['message']?.toString().contains('स्वीकृत') == true);
                        if (type == 'booking_approved' || (type == 'booking_alert' && isApproved)) {
                          return _buildBookingApprovedCard(note, id, index, sender);
                        }

                        // -- Standard notification row --
                        return Dismissible(
                          key: Key(id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) async {
                            if (index < _notifications.length) {
                              setState(() => _notifications.removeAt(index));
                              await SupabaseService.deleteNotification(id);
                            }
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            color: Colors.red.shade50,
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final type = note['type']?.toString() ?? '';
                              if (type == 'booking_approved' || type == 'booking_rejected' || type == 'booking_alert') {
                                  // 1. Check if it's an "Approved" message for the guest to pay
                                  final String title = note['title']?.toString() ?? '';
                                  final String message = note['message']?.toString() ?? '';
                                  final bool isApproved = title.contains('स्वीकृत') || message.contains('स्वीकृत');
                                  final String bookingId = note['booking_id']?.toString() ?? '';

                                  if (isApproved && bookingId.isNotEmpty) {
                                    // Navigate to payment choice screen
                                    
                                    final booking = await SupabaseService.getVisitById(bookingId);
                                    if (booking != null && mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaymentChoiceScreen(
                                            booking: booking,
                                            propertyTitle: booking.propertyTitle ?? 'Your Property',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                  // 2. Fallback to status screen if guest
                                  final propertyId = note['property_id'];
                                  if (propertyId != null) {
                                    final bookings = await SupabaseService.getMyVisits();
                                    final filtered = bookings.where((b) => b.propertyId == propertyId).toList();
                                    
                                    if (filtered.isNotEmpty && mounted) {
                                      final booking = filtered.first;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookingStatusScreen(booking: booking),
                                        ),
                                      );
                                    } else {
                                      // 3. Maybe it's an owner notification
                                      if (mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const OwnerBookingsScreen(),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (sender != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OwnerProfileScreen(
                                              ownerId: sender['id']?.toString() ?? '',
                                              name:
                                                  sender['full_name'] ??
                                                  'Khozna User',
                                              avatar:
                                                  sender['avatar_url'] ??
                                                  'https://via.placeholder.com/150',
                                              location: 'Kathmandu, Nepal',
                                              totalListings: 0,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: Colors.grey[100],
                                          backgroundImage:
                                              sender != null &&
                                                  sender['avatar_url'] != null
                                              ? CachedNetworkImageProvider(sender['avatar_url'])
                                              : null,
                                          child:
                                              sender == null ||
                                                  sender['avatar_url'] == null
                                              ? Icon(
                                                  Icons.person,
                                                  color: Colors.grey[400],
                                                  size: 28,
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: _getTypeColor(note['type']),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              _getTypeIcon(note['type']),
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.black,
                                              height: 1.3,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: _getHumanMessage(note, sender),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    note['message'] ??
                                                    note['title'] ??
                                                    '',
                                              ),
                                              TextSpan(
                                                text:
                                                    '  ${_formatTime(note['created_at'])}',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _confirmDelete(id, index),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.withOpacity(0.3),
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  /// Booking request notification card — shown ONLY to the owner
  Widget _buildBookingRequestCard(Map<String, dynamic> note, String id, int index, dynamic sender) {
    final String bookingId = note['booking_id']?.toString() ?? '';
    // Extract property title from message: "$name wants to rent "$title""  
    final String message = note['message']?.toString() ?? '';
    // Extract property title from message if possible, otherwise use a generic one
    String propertyTitle = 'तपाइँको प्रोपर्टी (Your Property)';
    if (message.contains('"')) {
      final RegExp titleRegex = RegExp(r'"(.+)"');
      final match = titleRegex.firstMatch(message);
      if (match != null) propertyTitle = match.group(1)!;
    }
    bool acting = false;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00A3E1).withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A3E1).withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Text('👀', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'भ्रमण अनुरोध (New Visit Request)',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black),
                          ),
                          Text(
                            _formatTime(note['created_at']),
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Body: requester info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: sender != null && sender['avatar_url'] != null
                              ? CachedNetworkImageProvider(sender['avatar_url']) : null,
                          child: sender == null || sender['avatar_url'] == null
                              ? Icon(Icons.person, color: Colors.grey[400], size: 24) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getHumanMessage(note, sender),
                                style: GoogleFonts.mukta(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w600, height: 1.4),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Text('⚠️', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'पहिला भेट गर्नुहोस्, त्यसपछि मात्र पैसा लिनुहोस्।',
                                        style: GoogleFonts.mukta(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (sender != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    TrustBadge(badge: sender['trust_badge'] ?? 'new', fontSize: 10),
                                    const SizedBox(width: 8),
                                    if (sender['is_verified'] == true)
                                      const Icon(Icons.verified, size: 14, color: Colors.blue),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: acting
                    ? const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ))
                    : Row(
                        children: [
                          if (bookingId.isEmpty)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (sender != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => chat_page.ChatScreen(
                                          ownerId: sender['id']?.toString() ?? '',
                                          name: sender['full_name'] ?? 'User',
                                          avatar: sender['avatar_url'] ?? '',
                                          online: true,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const OwnerBookingsScreen()),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                label: Text('कुरा गर्नुहोस् (Message)', style: GoogleFonts.mukta(fontWeight: FontWeight.w700, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00A3E1),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            )
                          else ...[
                            // REJECT
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  setCardState(() => acting = true);
                                  try {
                                    await SupabaseService.rejectVisit(
                                      bookingId: bookingId,
                                      notificationId: id,
                                    );
                                    if (mounted) setState(() => _notifications.removeAt(index));
                                  } catch (_) {
                                    setCardState(() => acting = false);
                                  }
                                },
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: Text('अस्वीकार (Reject)', style: GoogleFonts.mukta(fontWeight: FontWeight.w700, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // APPROVE
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  setCardState(() => acting = true);
                                  final ownerProfile = await SupabaseService.getUserProfile(
                                    SupabaseService.currentUserId,
                                  );
                                  final ownerName = ownerProfile?.fullName ?? 'The owner';
                                  try {
                                    await SupabaseService.approveVisit(
                                      bookingId: bookingId,
                                      ownerName: ownerName,
                                      notificationId: id,
                                    );
                                    if (mounted) setState(() => _notifications.removeAt(index));
                                  } catch (_) {
                                    setCardState(() => acting = false);
                                  }
                                },
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: Text('स्वीकार (Approve)', style: GoogleFonts.mukta(fontWeight: FontWeight.w700, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Booking Approved card — shown to the guest
  Widget _buildBookingApprovedCard(Map<String, dynamic> note, String id, int index, dynamic sender) {
    final String bookingId = note['booking_id']?.toString() ?? '';
    final String title = note['title'] ?? 'Booking Approved';
    final String message = note['message'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.brandColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppTheme.brandColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black),
                      ),
                      Text(
                        _formatTime(note['created_at']),
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700], height: 1.5),
            ),
          ),
          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (bookingId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: Booking ID missing')),
                    );
                    return;
                  }
                  
                  
                  
                  final booking = await SupabaseService.getVisitById(bookingId);
                  if (booking != null && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentChoiceScreen(
                          booking: booking,
                          propertyTitle: booking.propertyTitle ?? 'Your Property',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: Text('अहिले भुक्तानी गर्नुहोस् (Pay Now)', style: GoogleFonts.mukta(fontWeight: FontWeight.w800, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
            const Icon(
              Icons.notifications_off_outlined,
              size: 50,
              color: AppTheme.brandColor,
            ),
            // Floating decorative icons
            Positioned(
              top: 10,
              right: 15,
              child: Transform.rotate(
                angle: 0.4,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 20,
                  color: Colors.red.withOpacity(0.4),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 10,
              child: Transform.rotate(
                angle: -0.3,
                child: Icon(
                  Icons.chat_bubble_rounded,
                  size: 18,
                  color: AppTheme.brandColor.withOpacity(0.4),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 0,
              child: Icon(
                Icons.home_work_rounded,
                size: 16,
                color: Colors.orange.withOpacity(0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'कुनै नयाँ सूचना छैन',
          style: GoogleFonts.mukta(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'तपाईंका नयाँ सन्देश र बुकिङहरू यहाँ देखा पर्नेछन्।',
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _confirmDelete(String id, int index) async {
    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Remove notification?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will permanently delete this alert from your feed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final String targetId = id;
      if (index < _notifications.length) {
        setState(() => _notifications.removeAt(index));
        await SupabaseService.deleteNotification(targetId);
      }
    }
  }

  void _confirmClearAll() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear all notifications?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete all your notifications.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _notifications.clear();
      });
      await SupabaseService.deleteAllNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications cleared')),
      );
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'love_alert':
        return Icons.favorite_rounded;
      case 'booking_alert':
      case 'saved_booking_alert':
        return Icons.home_work_rounded;
      case 'booking_request':
        return Icons.pending_actions_rounded;
      case 'booking_approved':
        return Icons.check_circle_rounded;
      case 'booking_rejected':
        return Icons.cancel_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'booking':
      case 'kyc_update':
      case 'kyc_alert':
        return Icons.verified_user_rounded;
      case 'report_alert':
        return Icons.flag_rounded;
      case 'security':
        return Icons.security_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'love_alert':
        return Colors.red;
      case 'booking_alert':
      case 'saved_booking_alert':
        return Colors.orange;
      case 'booking_request':
        return const Color(0xFF00A3E1);
      case 'booking_approved':
        return const Color(0xFF22C55E);
      case 'booking_rejected':
        return Colors.red;
      case 'message':
        return AppTheme.brandColor;
      case 'booking':
      case 'kyc_update':
        return Colors.green;
      case 'kyc_alert':
        return Colors.orange;
      case 'report_alert':
        return Colors.red;
      case 'security':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  /// Payment received notification card
  Widget _buildPaymentReceivedCard(Map<String, dynamic> note, String id, int index, dynamic sender) {
    final String propertyId = note['property_id']?.toString() ?? '';
    final String message = note['message']?.toString() ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payments_rounded, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note['title'] ?? 'Payment Notification',
                        style: GoogleFonts.mukta(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black),
                      ),
                      Text(
                        _formatTime(note['created_at']),
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.mukta(fontSize: 14, color: Colors.grey[800], height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Fetch latest booking for this property
                      if (propertyId.isNotEmpty) {
                        final bookings = await SupabaseService.getMyVisits();
                        final filtered = bookings.where((b) => b.propertyId == propertyId).toList();
                        
                        if (filtered.isNotEmpty && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingStatusScreen(booking: filtered.first),
                            ),
                          );
                        } else {
                          // Try owner dashboard if no guest booking found
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const OwnerBookingsScreen()),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'विवरण हेर्नुहोस् (View Details)',
                      style: GoogleFonts.mukta(fontWeight: FontWeight.bold),
                    ),
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
