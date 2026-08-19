import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/profile/screens/owner_profile_screen.dart';
import 'package:khozna/features/property/screens/booking_status_screen.dart';
import 'package:khozna/features/property/screens/owner_bookings_screen.dart';
import 'package:khozna/features/property/screens/payment_choice_screen.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'all') return _notifications;
    return _notifications.where((note) {
      final type = note['type']?.toString() ?? '';
      final titleStr = (note['title'] ?? '').toString();
      final msgStr = (note['message'] ?? '').toString();

      final bool isBookingRequest =
          type == 'booking_request' ||
          msgStr.contains('कोठा हेर्न अनुरोध') ||
          msgStr.contains('visit request');

      final bool isApproved =
          !titleStr.contains('अस्वीकृत') &&
          !msgStr.contains('अस्वीकृत') &&
          type != 'booking_rejected' &&
          (titleStr.contains('स्वीकृत') ||
              msgStr.contains('स्वीकृत') ||
              type == 'booking_approved');

      final bool isPayment =
          type == 'payment_received' ||
          msgStr.contains('भुक्तानी') ||
          titleStr.contains('भुक्तानी');

      if (_selectedFilter == 'pending') return isBookingRequest;
      if (_selectedFilter == 'approved') return isApproved;
      if (_selectedFilter == 'payments') return isPayment;

      return true;
    }).toList();
  }

  int _getCategoryCount(String filterKey) {
    if (filterKey == 'all') return _notifications.length;
    return _notifications.where((note) {
      final type = note['type']?.toString() ?? '';
      final titleStr = (note['title'] ?? '').toString();
      final msgStr = (note['message'] ?? '').toString();

      if (filterKey == 'pending') {
        return type == 'booking_request' ||
            msgStr.contains('कोठा हेर्न अनुरोध') ||
            msgStr.contains('visit request');
      }
      if (filterKey == 'approved') {
        return !titleStr.contains('अस्वीकृत') &&
            !msgStr.contains('अस्वीकृत') &&
            type != 'booking_rejected' &&
            (titleStr.contains('स्वीकृत') ||
                msgStr.contains('स्वीकृत') ||
                type == 'booking_approved');
      }
      if (filterKey == 'payments') {
        return type == 'payment_received' ||
            msgStr.contains('भुक्तानी') ||
            titleStr.contains('भुक्तानी');
      }
      return false;
    }).length;
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);

    try {
      // Execute all queries concurrently in parallel for maximum speed
      final results = await Future.wait([
        SupabaseService.getUserNotifications(),
        SupabaseService.getMyVisits(),
        SupabaseService.getVisitRequestsForOwner(),
        SupabaseService.getDismissedNotificationIds(),
      ]);

      final data = results[0] as List<Map<String, dynamic>>;
      final myVisits = results[1] as List<BookingModel>;
      final ownerRequests = results[2] as List<BookingModel>;
      final dismissedIds = results[3] as Set<String>;

      List<Map<String, dynamic>> combined = List<Map<String, dynamic>>.from(data);

      // 1. Synthesize Guest Visits
      for (final visit in myVisits) {
        final synthId = 'synth_${visit.id}';
        final existing = combined.any(
          (n) => n['booking_id']?.toString() == visit.id || n['id'] == synthId,
        );
        if (!existing && !dismissedIds.contains(synthId)) {
          final timeStr =
              visit.createdAt?.toIso8601String() ??
              DateTime.now().toIso8601String();
          if (visit.status == 'visit_accepted' ||
              visit.status == 'awaiting_payment') {
            combined.add({
              'id': synthId,
              'booking_id': visit.id,
              'property_id': visit.propertyId,
              'title': 'Visit Approved',
              'message':
                  'Your room visit request was approved by the owner. Complete payment to secure your room.',
              'type': 'booking_approved',
              'created_at': timeStr,
            });
          } else if (visit.status == 'paid' ||
              visit.status == 'payment_under_review') {
            combined.add({
              'id': synthId,
              'booking_id': visit.id,
              'property_id': visit.propertyId,
              'title': 'Payment Proof Submitted',
              'message':
                  'Payment proof has been submitted for "${visit.propertyTitle ?? "Property"}". Under review.',
              'type': 'booking_alert',
              'created_at': timeStr,
            });
          } else if (visit.status == 'confirmed') {
            combined.add({
              'id': synthId,
              'booking_id': visit.id,
              'property_id': visit.propertyId,
              'title': 'Booking Confirmed',
              'message':
                  'Booking for "${visit.propertyTitle ?? "Property"}" has been successfully confirmed.',
              'type': 'booking_alert',
              'created_at': timeStr,
            });
          } else if (visit.status == 'pending_approval') {
            combined.add({
              'id': synthId,
              'booking_id': visit.id,
              'property_id': visit.propertyId,
              'title': 'Request Submitted',
              'message': 'Awaiting owner approval for room visit.',
              'type': 'booking_alert',
              'created_at': timeStr,
            });
          }
        }
      }

      // 2. Synthesize Owner Requests
      for (final req in ownerRequests) {
        final bId = req.id;
        final synthId = 'synth_owner_$bId';
        final existing = combined.any(
          (n) => n['booking_id']?.toString() == bId || n['id'] == synthId,
        );
        if (!existing && bId.isNotEmpty && !dismissedIds.contains(synthId)) {
          final propTitle = req.propertyTitle ?? 'Your Property';
          final status = req.status;
          final timeStr = req.createdAt.toIso8601String();

          if (status == 'pending_approval') {
            combined.add({
              'id': synthId,
              'booking_id': bId,
              'property_id': req.propertyId,
              'title': 'New Booking Request',
              'message': 'New visit request received for "$propTitle".',
              'type': 'booking_request',
              'sender': {'id': req.guestId, 'full_name': 'Guest'},
              'created_at': timeStr,
            });
          } else if (status == 'paid') {
            combined.add({
              'id': synthId,
              'booking_id': bId,
              'property_id': req.propertyId,
              'title': 'Payment Received',
              'message': 'Payment received for "$propTitle".',
              'type': 'payment_received',
              'sender': {'id': req.guestId, 'full_name': 'Guest'},
              'created_at': timeStr,
            });
          }
        }
      }

      // Filter out any dismissed notification IDs
      combined.removeWhere((n) => dismissedIds.contains(n['id']?.toString()));

      // Sort by timestamp descending
      combined.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.now();
        final bTime =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.now();
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _notifications = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error synthesizing notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }

    // Mark as read in background without blocking UI load
    SupabaseService.markNotificationsAsRead();
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  String _getHumanMessage(Map<String, dynamic> note, dynamic sender) {
    final type = note['type']?.toString() ?? '';
    final String message = (note['message'] ?? note['title'] ?? '').toString();
    final name = sender?['full_name'] ?? 'Guest';

    if (type == 'booking_request' ||
        message.contains('request') ||
        type == 'visit_request') {
      return '$name requested a room visit.';
    }
    if (type == 'booking_approved' ||
        message.contains('Approved') ||
        type == 'visit_alert' && message.contains('Approved')) {
      return 'Your room visit request was approved!';
    }
    if (message.contains('Declined') ||
        message.contains('Rejected') ||
        type == 'booking_rejected' ||
        (note['title']?.toString() ?? '').contains('Rejected')) {
      return 'Visit request declined: ';
    }
    if (type == 'chat' || type == 'message') {
      return 'New message from $name';
    }
    if (type == 'payment_received' || message.contains('Payment')) {
      return 'Payment received from $name';
    }

    return message.isEmpty ? 'New notification' : message;
  }

  Widget _buildFilterBar() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Requests'},
      {'key': 'approved', 'label': 'Approved'},
      {'key': 'payments', 'label': 'Payments'},
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final key = item['key']!;
          final label = item['label']!;
          final isSelected = _selectedFilter == key;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: 0.2,
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
          : Column(
              children: [
                if (_notifications.isNotEmpty) _buildFilterBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    color: AppTheme.brandColor,
                    child: filtered.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.65,
                              alignment: Alignment.center,
                              child: _buildEmptyStateContent(),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                            itemBuilder: (context, index) {
                              final note = filtered[index];
                              final sender = note['sender'];
                              final String id = note['id'].toString();
                              final String type = note['type']?.toString() ?? '';

                        // -- SPECIAL: Booking Request card with Approve/Reject --
                        final String msgText = (note['message'] ?? '')
                            .toString();
                        final bool isBookingRequest =
                            type == 'booking_request' ||
                            msgText.contains('कोठा हेर्न अनुरोध') ||
                            msgText.contains('visit request');

                        if (isBookingRequest) {
                          return GestureDetector(
                            onLongPress: () => _confirmDelete(id, index),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildBookingRequestCard(
                                note,
                                id,
                                index,
                                sender,
                              ),
                            ),
                          );
                        }

                        // -- SPECIAL: Payment Received card --
                        if (type == 'payment_received') {
                          return GestureDetector(
                            onLongPress: () => _confirmDelete(id, index),
                            child: _buildPaymentReceivedCard(
                              note,
                              id,
                              index,
                              sender,
                            ),
                          );
                        }

                        // -- SPECIAL: Booking Approved (Guest) card --
                        final titleStr = note['title']?.toString() ?? '';
                        final msgStr = note['message']?.toString() ?? '';
                        final isRejected =
                            titleStr.contains('अस्वीकृत') ||
                            msgStr.contains('अस्वीकृत') ||
                            type == 'booking_rejected';

                        final isApproved =
                            !isRejected &&
                            (titleStr.contains('स्वीकृत') ||
                                msgStr.contains('स्वीकृत') ||
                                type == 'booking_approved');

                        if (isApproved) {
                          return GestureDetector(
                            onLongPress: () => _confirmDelete(id, index),
                            child: _buildBookingApprovedCard(
                              note,
                              id,
                              index,
                              sender,
                            ),
                          );
                        }

                        if (isRejected) {
                          return GestureDetector(
                            onLongPress: () => _confirmDelete(id, index),
                            child: _buildBookingRejectedCard(
                              note,
                              id,
                              index,
                              sender,
                            ),
                          );
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
                              if (type == 'booking_approved' ||
                                  type == 'booking_rejected' ||
                                  type == 'booking_alert') {
                                // 1. Check if it's an "Approved" message for the guest to pay
                                final String title =
                                    note['title']?.toString() ?? '';
                                final String message =
                                    note['message']?.toString() ?? '';
                                final bool isApproved =
                                    title.contains('स्वीकृत') ||
                                    message.contains('स्वीकृत');
                                final String bookingId =
                                    note['booking_id']?.toString() ?? '';

                                if (isApproved && bookingId.isNotEmpty) {
                                  // Navigate to payment choice screen

                                  final booking =
                                      await SupabaseService.getVisitById(
                                        bookingId,
                                      );
                                  if (booking != null && mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PaymentChoiceScreen(
                                              booking: booking,
                                              propertyTitle:
                                                  booking.propertyTitle ??
                                                  'Your Property',
                                            ),
                                      ),
                                    );
                                    return;
                                  }
                                }

                                // 2. Fallback to status screen if guest
                                final propertyId = note['property_id'];
                                if (propertyId != null) {
                                  final bookings =
                                      await SupabaseService.getMyVisits();
                                  final filtered = bookings
                                      .where((b) => b.propertyId == propertyId)
                                      .toList();

                                  if (filtered.isNotEmpty && mounted) {
                                    final booking = filtered.first;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookingStatusScreen(
                                              booking: booking,
                                            ),
                                      ),
                                    );
                                  } else {
                                    // 3. Maybe it's an owner notification
                                    if (mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const OwnerBookingsScreen(),
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
                                            builder: (context) =>
                                                OwnerProfileScreen(
                                                  ownerId:
                                                      sender['id']
                                                          ?.toString() ??
                                                      '',
                                                  name:
                                                      sender['full_name'] ??
                                                      'Khozna User',
                                                  avatar:
                                                      sender['avatar_url'] ??
                                                      'https://via.placeholder.com/150',
                                                  location:
                                                      sender?['area_name'] ??
                                                      'Kathmandu, Nepal',
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
                                              ? CachedNetworkImageProvider(
                                                  sender['avatar_url'],
                                                )
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
                                              color: _getTypeColor(
                                                note['type'],
                                              ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                text: _getHumanMessage(
                                                  note,
                                                  sender,
                                                ),
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
                                      color: Colors.red.withValues(alpha: 0.3),
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
                ),
              ],
            ),
    );
  }

  /// Booking request notification card — shown ONLY to the owner
  Widget _buildBookingRequestCard(
    Map<String, dynamic> note,
    String id,
    int index,
    dynamic sender,
  ) {
    final String bookingId = note['booking_id']?.toString() ?? '';
    final String message = note['message']?.toString() ?? '';
    String propertyTitle = 'Your Property';
    if (message.contains('"')) {
      final RegExp titleRegex = RegExp(r'"(.+)"');
      final match = titleRegex.firstMatch(message);
      if (match != null) propertyTitle = match.group(1)!;
    }
    bool acting = false;

    // Real Guest Avatar Fallback
    final String avatarUrl = (sender != null &&
            sender['avatar_url'] != null &&
            sender['avatar_url'].toString().isNotEmpty)
        ? sender['avatar_url'].toString()
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80';

    return StatefulBuilder(
      builder: (context, setCardState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar, Name, Property & Status Pill
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _showGuestProfile(context, sender),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: CachedNetworkImageProvider(avatarUrl),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showGuestProfile(context, sender),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    sender?['full_name'] ?? 'Guest User',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (sender?['kyc_status'] == 'verified') ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: Color(0xFF00A3E1), size: 15),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              propertyTitle,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Pill
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            'Pending',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(note['created_at']),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Request Description Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'New room visit request received. Booking will proceed after owner approval.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: acting
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandColor),
                        ),
                      )
                    : Row(
                        children: [
                          // DECLINE BUTTON
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final String? reason = await _showRejectionReasonPicker(context);
                                if (reason == null) return;

                                setCardState(() => acting = true);
                                try {
                                  await SupabaseService.rejectVisit(
                                    bookingId: bookingId,
                                    notificationId: id,
                                    reason: reason,
                                  );
                                  if (mounted) {
                                    setState(() => _notifications.removeAt(index));
                                  }
                                } catch (_) {
                                  setCardState(() => acting = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                foregroundColor: const Color(0xFF475569),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Decline',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // APPROVE BUTTON
                          Expanded(
                            child: ElevatedButton(
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
                                  if (mounted) {
                                    setState(() => _notifications.removeAt(index));
                                  }
                                } catch (_) {
                                  setCardState(() => acting = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Approve',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
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
  Widget _buildBookingApprovedCard(
    Map<String, dynamic> note,
    String id,
    int index,
    dynamic sender,
  ) {
    final String bookingId = note['booking_id']?.toString() ?? '';
    final String title = (note['title'] ?? 'Booking Approved')
        .toString()
        .replaceAll('✅', '')
        .trim();
    final String message = (note['message'] ?? '')
        .toString()
        .replaceAll('✅', '')
        .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF047857),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _formatTime(note['created_at']),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    'स्वीकृत',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF047857),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (bookingId.isEmpty) return;

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
                icon: const Icon(Icons.credit_card_rounded, size: 18),
                label: Text(
                  'अहिले भुक्तानी गर्नुहोस्',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Booking Rejected card — shown to the guest
  Widget _buildBookingRejectedCard(
    Map<String, dynamic> note,
    String id,
    int index,
    dynamic sender,
  ) {
    final String title = (note['title'] ?? 'Visit Rejected')
        .toString()
        .replaceAll('❌', '')
        .trim();
    final String message = (note['message'] ?? '')
        .toString()
        .replaceAll('❌', '')
        .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFBE123C),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _formatTime(note['created_at']),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Text(
                    'अस्वीकृत',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFFBE123C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (sender != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => chat_page.ChatScreen(
                          ownerId: sender['id']?.toString() ?? '',
                          name: sender['full_name'] ?? 'Owner',
                          avatar: sender['avatar_url'] ?? '',
                          online: true,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OwnerBookingsScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  'घरधनीलाई सन्देश पठाउनुहोस्',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF334155),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.notifications_none_rounded,
              size: 38,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'You\'re all caught up',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'When you receive new booking updates or messages, they will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF717171),
              height: 1.45,
            ),
          ),
        ),
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

  Future<String?> _showRejectionReasonPicker(BuildContext context) async {
    final reasons = [
      'Room occupied',
      'Time unavailable',
      'Students only',
      'Family only',
      'Other reason',
    ];

    return await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              'Select Rejection Reason',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...reasons.map(
              (reason) => ListTile(
                title: Text(
                  reason,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.pop(context, reason),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
      final allIds = _notifications
          .map((n) => n['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      setState(() {
        _notifications.clear();
      });
      await SupabaseService.deleteAllNotifications(allIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
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
  Widget _buildPaymentReceivedCard(
    Map<String, dynamic> note,
    String id,
    int index,
    dynamic sender,
  ) {
    final String propertyId = note['property_id']?.toString() ?? '';
    final String message = note['message']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF1D4ED8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note['title'] ?? 'Payment Received 💸',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _formatTime(note['created_at']),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    'भुक्तानी',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (propertyId.isNotEmpty) {
                    final bookings = await SupabaseService.getMyVisits();
                    final filtered = bookings
                        .where((b) => b.propertyId == propertyId)
                        .toList();

                    if (filtered.isNotEmpty && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingStatusScreen(booking: filtered.first),
                        ),
                      );
                    } else {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const OwnerBookingsScreen(),
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: Text(
                  'विवरण हेर्नुहोस्',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGuestProfile(BuildContext context, dynamic sender) {
    if (sender == null) return;

    final String avatarUrl = (sender['avatar_url'] != null &&
            sender['avatar_url'].toString().isNotEmpty)
        ? sender['avatar_url'].toString()
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFF1F5F9),
              backgroundImage: CachedNetworkImageProvider(avatarUrl),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sender['full_name'] ?? 'Guest User',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (sender['kyc_status'] == 'verified') ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: Colors.blue, size: 20),
                ],
              ],
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _buildGuestInfoRow(
                    Icons.location_on_outlined,
                    'Location / Area',
                    sender['area_name'] ?? 'Not Specified',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _buildGuestInfoRow(
                    Icons.badge_outlined,
                    'Guest Type',
                    sender['user_type'] ?? 'Not Specified',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _buildGuestInfoRow(
                    Icons.security_outlined,
                    'Verification Status',
                    sender['kyc_status'] == 'verified'
                        ? 'KYC Verified Guest'
                        : 'Phone Verified Only',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For privacy and safety, phone number will be revealed after room visit request is approved.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
