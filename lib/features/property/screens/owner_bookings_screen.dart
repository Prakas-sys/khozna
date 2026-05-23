import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:intl/intl.dart';

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
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final data = await BookingRepository.getOwnerBookings();
      setState(() {
        _bookings = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching owner bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showRejectReasonPicker(String bookingId) async {
    const reasons = [
      'कोठा भरिसक्यो (Room occupied)',
      'समय मिलेन (Time unavailable)',
      'विद्यार्थी मात्र (Students only)',
      'परिवार मात्र (Family only)',
      'अन्य (Other)',
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
                'अस्वीकार गर्नुको कारण',
                style: GoogleFonts.notoSansDevanagari(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              Text(
                'Why are you declining this visit?',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...reasons.map(
                (r) => RadioListTile<String>(
                  title: Text(
                    r,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                    style: GoogleFonts.notoSansDevanagari(
                      fontWeight: FontWeight.w800,
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
              'भ्रमण अस्वीकृत गरियो (Visit Declined)',
              style: GoogleFonts.notoSansDevanagari(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
                'भ्रमणको समय पक्का गर्नुहोस्',
                style: GoogleFonts.notoSansDevanagari(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
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
                              'Visit Time',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a').format(selectedDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
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
                    'Confirm & Accept',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.5,
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
              const SnackBar(content: Text('Visit Approved successfully!')),
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
        // Find the booking to get guest details
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
        ).showSnackBar(SnackBar(content: Text('Action successful: $action')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to $action: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'भ्रमण अनुरोधहरू (Visit Requests)',
          style: GoogleFonts.notoSansDevanagari(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
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
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
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
    final checkOut = DateTime.parse(booking['check_out']);
    final total = booking['total_price'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Status Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(status),
                Text(
                  DateFormat(
                    'MMM dd, yyyy',
                  ).format(DateTime.parse(booking['created_at'])),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Property & Guest Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: guest?['avatar_url'] != null
                      ? NetworkImage(guest!['avatar_url'])
                      : null,
                  backgroundColor: Colors.grey[100],
                  child: guest?['avatar_url'] == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest?['full_name'] ?? 'Khozna Guest',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        property?['title'] ?? 'Property',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${NumberFormat('#,##,###').format(total)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppTheme.brandColor,
                      ),
                    ),
                    Text(
                      'Total Price',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Visit Date Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildDateInfo('भ्रमण गर्ने मिति (Visit Date)', checkIn),
                const Spacer(),
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.brandColor,
                  size: 20,
                ),
                const Spacer(),
                Expanded(
                  child: Text(
                    'Time: ${DateFormat('hh:mm a').format(checkIn)}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (status == 'pending_approval' || status == 'paid')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  if (status == 'pending_approval') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _isLoading = false);
                              _showRejectReasonPicker(booking['id']);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _showApproveTimePicker(booking),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Accept Visit'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _handleAction(booking['id'], 'suggest_time'),
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: const Text('Suggest New Time'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                        side: BorderSide(
                          color: Colors.blueGrey.withOpacity(0.3),
                        ),
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  if (status == 'paid') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _handleAction(booking['id'], 'reject_payment'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _handleAction(booking['id'], 'confirm_payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Confirm',
                              style: GoogleFonts.notoSansDevanagari(
                                fontWeight: FontWeight.bold,
                              ),
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

  Widget _buildDateInfo(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          DateFormat('dd MMM yyyy').format(date),
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending_approval':
        color = Colors.orange;
        label = 'भ्रमण अनुरोध (Visit Requested)';
        break;
      case 'visit_accepted':
        color = Colors.blue;
        label = 'भ्रमण स्वीकृत (Visit Approved)';
        break;
      case 'awaiting_payment':
        color = Colors.indigo;
        label = 'भुक्तानी पर्खिंदै (Awaiting Payment)';
        break;
      case 'paid':
        color = Colors.purple;
        label = 'भुक्तानी प्राप्त (Payment Received)';
        break;
      case 'confirmed':
        color = const Color(0xFF00C853);
        label = 'पक्का भयो (Confirmed)';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'अस्वीकृत (Declined)';
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
        style: GoogleFonts.notoSansDevanagari(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
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
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New requests to visit your room\nwill appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
