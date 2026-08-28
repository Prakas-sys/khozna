import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:intl/intl.dart';
import 'package:khozna/core/utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:khozna/widgets/khozna_image.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Instant 0ms load using in-memory cache if available (React-style instant transition)
    if (BookingRepository.cachedOwnerBookings.isNotEmpty) {
      _bookings = List<Map<String, dynamic>>.from(BookingRepository.cachedOwnerBookings);
      _isLoading = false;
    }
    _fetchBookings();
  }

  Future<void> _fetchBookings({bool showSpinner = false}) async {
    if (_bookings.isEmpty || showSpinner) {
      setState(() => _isLoading = true);
    }
    try {
      final data = await BookingRepository.getOwnerBookings(forceRefresh: true);
      if (mounted) {
        setState(() {
          _bookings = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching owner bookings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          Clipboard.setData(ClipboardData(text: cleanPhone));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number copied to clipboard!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: cleanPhone));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRejectReasonPicker(String bookingId) async {
    const reasons = [
      'Room already occupied',
      'Requested time unavailable',
      'Students only',
      'Family only',
      'Other',
    ];
    String? selectedReason;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Decline Visit Request',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a reason for declining this visit request:',
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...reasons.map(
                (r) => RadioListTile<String>(
                  title: Text(
                    r,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  value: r,
                  groupValue: selectedReason,
                  activeColor: Colors.red,
                  onChanged: (v) => setS(() => selectedReason = v),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Confirm Decline',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedReason == null) return;
    setState(() => _isLoading = true);
    try {
      await BookingRepository.rejectWithReason(
        bookingId,
        reason: selectedReason,
      );
      await _fetchBookings();
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visit request declined',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showApproveTimePicker(Map<String, dynamic> booking) async {
    DateTime currentCheckIn = DateTime.parse(booking['check_in']);
    DateTime selectedDate = currentCheckIn;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Confirm Visit Time',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: const Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Confirm or adjust the scheduled visit date & time',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                    );
                    if (pickedTime != null) {
                      setS(() {
                        selectedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppTheme.brandColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scheduled Time',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a').format(selectedDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_rounded, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx, selectedDate);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Confirm & Accept Visit',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((finalDate) async {
      if (finalDate != null) {
        setState(() => _isLoading = true);
        try {
          await BookingRepository.approveRequest(booking['id'], newCheckIn: finalDate);
          await _fetchBookings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Visit request approved successfully!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to approve: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _handleAction(String bookingId, String action) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      if (action == 'suggest_time') {
        final b = _bookings.firstWhere((element) => element['id'] == bookingId);
        final guest = b['guest'];
        if (mounted && guest != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => chat_page.ChatScreen(
                ownerId: b['guest_id'],
                name: guest['full_name'] ?? 'Guest',
                avatar: guest['avatar_url'] ?? '',
                online: true,
                initialMessage:
                    'Hi! Regarding your visit request for "${b['properties']?['title']}", could we reschedule to a different time?',
              ),
            ),
          );
        }
        return;
      } else if (action == 'confirm_payment') {
        await BookingRepository.confirmPayment(bookingId);
      } else if (action == 'reject_payment') {
        await BookingRepository.rejectPayment(bookingId);
      }
      await _fetchBookings();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action completed: $action')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteBooking(String bookingId) async {
    HapticFeedback.lightImpact();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Visit Request',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this property visit request?',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. Immediate local UI update
      setState(() {
        _bookings.removeWhere((item) => item['id'] == bookingId);
      });

      try {
        await BookingRepository.deleteBookingRequest(bookingId);
        // 2. Refresh fresh list quietly in background
        await _fetchBookings(showSpinner: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit request deleted permanently'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
      } catch (e) {
        final String errStr = e.toString();
        final String userFriendlyMsg = errStr.contains('SocketException') || errStr.contains('Failed host lookup')
            ? 'Network error: Please check your internet connection and try again.'
            : 'Failed to delete visit request. Please try again.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userFriendlyMsg),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Property Visits',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            )
          : _bookings.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              color: AppTheme.brandColor,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _bookings.length,
                itemBuilder: (context, index) =>
                    _buildBookingCard(_bookings[index]),
              ),
            ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'];
    final guest = booking['guest'] as Map<String, dynamic>?;
    final property = booking['properties'] as Map<String, dynamic>?;
    final checkIn = DateTime.parse(booking['check_in']);
    final total = booking['total_price'] ?? 0;
    final String? message = booking['message']?.toString();
    final String? guestPhone = guest?['phone_number']?.toString();
    final int visitorCount = booking['guests'] ?? booking['guest_count'] ?? booking['visiting_count'] ?? booking['visitors_count'] ?? 1;

    // Extract property image
    String? propertyImg;
    if (property != null && property['images'] != null) {
      final imgs = property['images'];
      if (imgs is List && imgs.isNotEmpty) {
        propertyImg = imgs.first.toString();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Visitor Info + Status Badge + Delete Button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: guest?['avatar_url'] != null
                      ? NetworkImage(guest!['avatar_url'])
                      : null,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: guest?['avatar_url'] == null
                      ? const Icon(Icons.person_rounded, size: 20, color: Color(0xFF64748B))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              guest?['full_name'] ?? 'Visitor',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (guest?['kyc_status'] == 'verified') ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: Color(0xFF00A3E1), size: 13),
                          ],
                          const SizedBox(width: 6),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy').format(DateTime.parse(booking['created_at'])),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Phone & Chat Icons
                if (guestPhone != null && guestPhone.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF16A34A)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _makePhoneCall(guestPhone),
                    tooltip: 'Call visitor',
                  ),
                ],
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/Message neww.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(AppTheme.brandColor, BlendMode.srcIn),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => chat_page.ChatScreen(
                          ownerId: booking['guest_id'],
                          name: guest?['full_name'] ?? 'Visitor',
                          avatar: guest?['avatar_url'] ?? '',
                          online: true,
                        ),
                      ),
                    );
                  },
                  tooltip: 'Chat with visitor',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 19),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _confirmDeleteBooking(booking['id']),
                  tooltip: 'Delete request',
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Property Snapshot Card
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: propertyImg != null && propertyImg.isNotEmpty
                      ? KhoznaImage(
                          imageUrl: propertyImg,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 46,
                          height: 46,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.home_outlined, color: Color(0xFF94A3B8)),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property?['title'] ?? 'Property',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (property?['area_name'] != null)
                        Text(
                          property!['area_name'],
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
                Text(
                  'Rs. ${PriceFormatter.format(total.toString())}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.brandColor,
                  ),
                ),
              ],
            ),
          ),

          // Visit Schedule & Visitor Count Row
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.brandColor),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE, MMM dd • hh:mm a').format(checkIn),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 12, color: Color(0xFF475569)),
                      const SizedBox(width: 4),
                      Text(
                        '$visitorCount ${visitorCount == 1 ? "Visitor" : "Visitors"}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Message / Note from Guest
          if (message != null && message.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/Message neww.svg',
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(Color(0xFFD97706), BlendMode.srcIn),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF92400E),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action Buttons: Pending Approval or Paid
          if (status == 'pending_approval' || status == 'paid')
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  if (status == 'pending_approval') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showRejectReasonPicker(booking['id']),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECDD3)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Decline',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showApproveTimePicker(booking),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Accept Visit',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (status == 'paid') ...[
                    _buildPaymentProofSection(booking),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleAction(booking['id'], 'reject_payment'),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: Text(
                              'Reject Payment',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECDD3)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleAction(booking['id'], 'confirm_payment'),
                            icon: const Icon(Icons.check_circle_rounded, size: 16),
                            label: Text(
                              'Confirm Payment',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending_approval':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'visit_accepted':
        color = Colors.blue;
        label = 'Approved';
        break;
      case 'awaiting_payment':
        color = Colors.indigo;
        label = 'Awaiting Payment';
        break;
      case 'paid':
        color = Colors.purple;
        label = 'Payment Received';
        break;
      case 'confirmed':
        color = const Color(0xFF16A34A);
        label = 'Confirmed';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Declined';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPaymentProofSection(Map<String, dynamic> booking) {
    final paymentsRaw = booking['payments'];
    Map<String, dynamic>? payment;
    if (paymentsRaw is List && paymentsRaw.isNotEmpty) {
      payment = paymentsRaw.first as Map<String, dynamic>?;
    } else if (paymentsRaw is Map<String, dynamic>) {
      payment = paymentsRaw;
    }

    final String? proofUrl = payment?['proof_image_url'] ??
        booking['payment_proof_url'] ??
        booking['proof_image_url'];
    final String? refId = payment?['reference_id'] ?? booking['reference_id'];
    final String method = (payment?['payment_method'] ?? booking['payment_type'] ?? 'esewa')
        .toString()
        .toLowerCase();

    final bool isEsewa = method.contains('esewa');
    final String logoAsset = isEsewa ? 'assets/images/esewa.webp' : 'assets/images/khalti.png';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(logoAsset, width: 22, height: 22),
              const SizedBox(width: 10),
              Text(
                'Booking Receipt',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (refId != null && refId.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: refId));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reference ID copied!'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'ID: $refId',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.copy_rounded, size: 10, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (proofUrl != null && proofUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _showPaymentProofFullscreen(proofUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    KhoznaImage(
                      imageUrl: proofUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Tap image to view full receipt',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('Proof not available', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  void _showPaymentProofFullscreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (ctx, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(24),
                      color: Colors.black87,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.broken_image_rounded, color: Colors.white70, size: 48),
                          SizedBox(height: 12),
                          Text('Unable to load receipt image', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.event_note_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No visit requests yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New requests to visit your property\nwill appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
