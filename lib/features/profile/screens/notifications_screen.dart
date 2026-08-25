import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/property/screens/booking_status_screen.dart';
import 'package:khozna/features/property/screens/owner_bookings_screen.dart';
import 'package:khozna/features/property/screens/payment_choice_screen.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static List<Map<String, dynamic>>? _cachedNotifications;
  List<Map<String, dynamic>> _notifications = _cachedNotifications ?? [];
  bool _isLoading = _cachedNotifications == null;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchNotifications(showLoading: _cachedNotifications == null);
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

  Future<void> _fetchNotifications({bool showLoading = true}) async {
    if (showLoading && _notifications.isEmpty) {
      setState(() => _isLoading = true);
    }

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

      List<Map<String, dynamic>> combined = data.map((item) {
        final copy = Map<String, dynamic>.from(item);
        if (copy['message'] != null) {
          copy['message'] = _cleanMessage(copy['message'].toString());
        }
        return copy;
      }).toList();

      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

      // Remove raw 'visit_request' type DB notifications — these are superseded
      // by the richer synth_owner_ cards that include Accept / Reject buttons.
      combined.removeWhere((n) => n['type']?.toString() == 'visit_request');

      // 1. Synthesize Guest Visits — only if the current user is the GUEST
      for (final visit in myVisits) {
        // Safety: never synthesize a guest card for a booking where we are the owner
        if (visit.ownerId == currentUserId) continue;

        final synthId = 'synth_${visit.id}';
        final existing = combined.any(
          (n) => n['booking_id']?.toString() == visit.id || n['id'] == synthId,
        );
        if (!existing && !dismissedIds.contains(synthId)) {
          final timeStr = visit.createdAt?.toIso8601String()
              ?? DateTime.now().toIso8601String();
          if (visit.status == 'visit_accepted' ||
              visit.status == 'awaiting_payment') {
            combined.add({
              'id': synthId,
              'booking_id': visit.id,
              'property_id': visit.propertyId,
              'title': 'Visit Request Approved! 🎉',
              'message':
                  'Great news! The owner accepted your visit request. Tap to view booking details.',
              'type': 'booking_approved',
              'created_at': timeStr,
            });
          } else if (visit.status == 'paid' ||
              visit.status == 'payment_under_review') {
            combined.add({
              'id': synthId,
              'booking_id': visit.id,
              'property_id': visit.propertyId,
              'title': 'Payment Submitted 💳',
              'message':
                  'Payment proof for "${visit.propertyTitle ?? "Property"}" is currently under review.',
              'type': 'booking_alert',
              'created_at': timeStr,
            });
          } else if (visit.status == 'confirmed') {
            combined.add({
              'id': synthId,
              'booking_id': visit.id,
              'property_id': visit.propertyId,
              'title': 'Booking Confirmed! 🎊',
              'message':
                  'Congratulations! Your room booking for "${visit.propertyTitle ?? "Property"}" is confirmed.',
              'type': 'booking_alert',
              'created_at': timeStr,
            });
          } else if (visit.status == 'pending_approval') {
            combined.add({
              'id': synthId,
              'booking_id': visit.id,
              'property_id': visit.propertyId,
              'title': 'Visit Request Sent ⏳',
              'message': 'Your room visit request has been sent to the owner for review.',
              'type': 'booking_alert',
              'created_at': timeStr,
            });
          }
        }
      }

      // 2. Synthesize Owner Requests — fetch real guest profiles in one batch
      final pendingOwnerRequests = ownerRequests.where((req) =>
        !combined.any((n) => n['id'] == 'synth_owner_${req.id}') &&
        req.id.isNotEmpty &&
        !dismissedIds.contains('synth_owner_${req.id}'),
      ).toList();

      // Batch-fetch real guest profiles for all pending requests
      Map<String, Map<String, dynamic>> guestProfiles = {};
      if (pendingOwnerRequests.isNotEmpty) {
        final guestIds = pendingOwnerRequests.map((r) => r.guestId).where((id) => id.isNotEmpty).toSet().toList();
        try {
          final profiles = await Supabase.instance.client
              .from('profiles')
              .select('id, full_name, avatar_url, kyc_status, user_type, organization, bio, area_name')
              .inFilter('id', guestIds);
          for (final p in profiles as List) {
            guestProfiles[p['id'].toString()] = Map<String, dynamic>.from(p as Map);
          }
        } catch (e) {
          debugPrint('Error fetching guest profiles: $e');
        }
      }

      for (final req in pendingOwnerRequests) {
        final bId = req.id;
        final synthId = 'synth_owner_$bId';
        final propTitle = req.propertyTitle ?? 'Your Property';
        final status = req.status;
        final timeStr = req.createdAt.toIso8601String();
        final guestProfile = guestProfiles[req.guestId] ?? {'id': req.guestId, 'full_name': 'Guest'};

        if (status == 'pending_approval') {
          combined.add({
            'id': synthId,
            'booking_id': bId,
            'property_id': req.propertyId,
            'title': 'New Visit Request 🏡',
            'message': 'Requested a room visit.',
            'type': 'booking_request',
            'sender': guestProfile,
            'created_at': timeStr,
          });
        } else if (status == 'paid') {
          combined.add({
            'id': synthId,
            'booking_id': bId,
            'property_id': req.propertyId,
            'title': 'Payment Received 💳',
            'message': 'Payment received for "$propTitle".',
            'type': 'payment_received',
            'sender': guestProfile,
            'created_at': timeStr,
          });
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

      _cachedNotifications = List.from(combined);

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
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF64748B),
                size: 22,
              ),
              tooltip: 'Clear All',
              onPressed: _confirmClearAll,
            ),
          const SizedBox(width: 6),
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
                        final titleStr = note['title']?.toString() ?? '';
                        final msgStr = note['message']?.toString() ?? '';

                        final bool isOwnerBookingRequest =
                            type == 'booking_request' ||
                            id.startsWith('synth_owner_');

                        final bool isGuestSentRequest =
                            !isOwnerBookingRequest &&
                            (titleStr.contains('Sent') ||
                                msgStr.contains('sent to the owner') ||
                                msgStr.contains('Sent'));

                        if (isOwnerBookingRequest) {
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

                        if (isGuestSentRequest) {
                          return GestureDetector(
                            onLongPress: () => _confirmDelete(id, index),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildGuestSentRequestCard(
                                note,
                                id,
                                index,
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
                        return GestureDetector(
                          onLongPress: () => _confirmDelete(id, index),
                          child: Dismissible(
                          key: Key(id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) async {
                            if (index < _notifications.length) {
                              setState(() => _notifications.removeWhere((n) => n['id']?.toString() == id));
                              _cachedNotifications = List.from(_notifications);
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
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Real avatar with type badge
                                  Stack(
                                    children: [
                                      _buildAvatar(sender, radius: 23),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 17,
                                          height: 17,
                                          decoration: BoxDecoration(
                                            color: _getTypeColor(note['type']),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1.5),
                                          ),
                                          child: Icon(
                                            _getTypeIcon(note['type']),
                                            size: 9,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: sender?['full_name'] != null
                                                    ? '${sender!['full_name']} '
                                                    : '',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF0F172A),
                                                  height: 1.3,
                                                ),
                                              ),
                                              TextSpan(
                                                text: note['message'] ?? note['title'] ?? '',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w400,
                                                  color: const Color(0xFF334155),
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 3,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(note['created_at']),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFFCBD5E1),
                                    size: 18,
                                  ),
                                ],
                              ),
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

  Widget _buildAvatar(dynamic sender, {double radius = 22}) {
    final String? avatarUrl = sender?['avatar_url']?.toString();
    final String name = sender?['full_name']?.toString() ?? 'Guest';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF1F5F9),
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF0F172A),
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }

  /// Slim emotional "Visit Request Sent" card — compact single-row real-feel UI
  Widget _buildGuestSentRequestCard(
    Map<String, dynamic> note,
    String id,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7), // Warm off-white
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Small pulsing amber dot indicator
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Request sent ',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  TextSpan(
                    text: '— awaiting owner response',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatTime(note['created_at']),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFFD97706),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Senior Ultra UI/UX: Booking request notification card
  Widget _buildBookingRequestCard(
    Map<String, dynamic> note,
    String id,
    int index,
    dynamic sender,
  ) {
    final String guestName = sender?['full_name']?.toString() ?? 'Guest';
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
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    _buildAvatar(sender, radius: 24),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.home_work_rounded, size: 9, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  guestName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                if (sender?['kyc_status'] == 'verified') ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: Color(0xFF00A3E1), size: 13),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF475569)),
                                const SizedBox(width: 3),
                                Text(
                                  'Guest Request',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    color: const Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(note['created_at']),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              _cleanMessage(message),
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showGuestProfile(context, sender),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      foregroundColor: const Color(0xFF475569),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: Text(
                      'View Profile',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRequestActionSheet(context, note, id, index, sender),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                    label: Text(
                      'Respond',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
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

  void _showRequestActionSheet(
    BuildContext context,
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
    final String guestName = sender?['full_name']?.toString() ?? 'Guest';
    bool acting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildAvatar(sender, radius: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                guestName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              if (sender?['kyc_status'] == 'verified') ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: Color(0xFF00A3E1), size: 16),
                              ],
                            ],
                          ),
                          Text(
                            sender?['area_name'] ?? 'Room Visit Request',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
                      onPressed: () {
                        Navigator.pop(context);
                        _showGuestProfile(context, sender);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Property',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        propertyTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _cleanMessage(message),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                acting
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: AppTheme.brandColor, strokeWidth: 2),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final String? reason = await _showRejectionReasonPicker(context);
                                if (reason == null) return;
                                setSheetState(() => acting = true);
                                try {
                                  await SupabaseService.rejectVisit(
                                    bookingId: bookingId,
                                    notificationId: id,
                                    reason: reason,
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                  if (mounted) setState(() => _notifications.removeAt(index));
                                } catch (_) {
                                  setSheetState(() => acting = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626), // Clear Crimson Red
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Decline',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                setSheetState(() => acting = true);
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
                                  if (context.mounted) Navigator.pop(context);
                                  if (mounted) setState(() => _notifications.removeAt(index));
                                } catch (_) {
                                  setSheetState(() => acting = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366), // Authentic WhatsApp Green
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Approve',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
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
                    'Approved',
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
                  'Complete Payment',
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
                    'Declined',
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
                  'Message Owner',
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
                  'View Details',
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
            _buildAvatar(sender, radius: 44),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sender['full_name'] ?? 'Guest',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (sender['kyc_status'] == 'verified') ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded, color: Color(0xFF00A3E1), size: 18),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Quick identity tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (sender['kyc_status'] == 'verified')
                  _buildGuestTag(
                    Icons.verified_rounded,
                    'KYC Verified',
                    const Color(0xFF0EA5E9),
                    const Color(0xFFE0F2FE),
                  )
                else
                  _buildGuestTag(
                    Icons.phone_rounded,
                    'Phone Verified',
                    const Color(0xFF64748B),
                    const Color(0xFFF1F5F9),
                  ),
                if ((sender['user_type'] ?? '').toString().isNotEmpty)
                  _buildGuestTag(
                    Icons.person_outline_rounded,
                    sender['user_type'].toString(),
                    const Color(0xFF7C3AED),
                    const Color(0xFFF5F3FF),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildGuestInfoRow(
                    Icons.work_outline_rounded,
                    'Profession',
                    (sender['user_type'] ?? '').toString().isNotEmpty
                        ? sender['user_type'].toString()
                        : 'Not specified',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _buildGuestInfoRow(
                    Icons.business_outlined,
                    'Organization',
                    (sender['organization'] ?? '').toString().isNotEmpty
                        ? sender['organization'].toString()
                        : 'Not specified',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _buildGuestInfoRow(
                    Icons.shield_outlined,
                    'Verification',
                    sender['kyc_status'] == 'verified'
                        ? 'KYC & ID Verified'
                        : 'Phone Verified Only',
                  ),
                  if ((sender['bio'] ?? '').toString().isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote_rounded, size: 20, color: Colors.grey[500]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                sender['bio'].toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: const Color(0xFF334155),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Primary Direct Chat Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => chat_page.ChatScreen(
                        ownerId: (sender['id'] ?? '').toString(),
                        name: (sender['full_name'] ?? 'Guest').toString(),
                        avatar: (sender['avatar_url'] ?? '').toString(),
                        online: true,
                      ),
                    ),
                  );
                },
                icon: SvgPicture.asset(
                  'assets/icons/Message neww.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                label: Text(
                  'Message Guest',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
        Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestTag(
    IconData icon,
    String label,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _cleanMessage(String input) {
    if (input.isEmpty) return 'Requested a room visit.';
    String cleaned = input
        .replaceAll(RegExp(r'Hello[!.,]?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'Hi[!.,]?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'I would like to\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r"I'd like to\s*", caseSensitive: false), '')
        .replaceAll(RegExp(r'for your property', caseSensitive: false), '')
        .replaceAll(RegExp(r'for your room', caseSensitive: false), '')
        .trim();

    if (cleaned.isEmpty ||
        cleaned.toLowerCase() == 'schedule a visit' ||
        cleaned.toLowerCase() == 'visit' ||
        cleaned.toLowerCase() == 'requested a room visit.') {
      return 'Requested a room visit.';
    }

    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}
