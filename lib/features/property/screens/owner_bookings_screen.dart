import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
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

  Future<void> _handleAction(String bookingId, String action) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      if (action == 'approve') {
        await BookingRepository.approveRequest(bookingId);
      } else if (action == 'reject') {
        await BookingRepository.rejectRequest(bookingId);
      } else if (action == 'confirm_payment') {
        await BookingRepository.confirmPayment(bookingId);
      }
      await _fetchBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action successful: $action')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $action: $e')),
        );
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
          'बुकिङ अनुरोधहरू (Booking Requests)',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
          : _bookings.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) => _buildBookingCard(_bookings[index]),
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
                  DateFormat('MMM dd, yyyy').format(DateTime.parse(booking['created_at'])),
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
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
                      '₹${NumberFormat('#,##,###').format(total)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppTheme.brandColor,
                      ),
                    ),
                    Text(
                      'Total Price',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Date Selection
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildDateInfo('पस्ने मिति (Check-in)', checkIn),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 16),
                const Spacer(),
                _buildDateInfo('निस्कने मिति (Check-out)', checkOut),
              ],
            ),
          ),

          // Action Buttons
          if (status == 'pending_approval' || status == 'paid')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (status == 'pending_approval') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleAction(booking['id'], 'reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleAction(booking['id'], 'approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                  if (status == 'paid')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleAction(booking['id'], 'confirm_payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          'भुक्तानी प्राप्त भयो (Payment Received)',
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

  Widget _buildDateInfo(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
        ),
        Text(
          DateFormat('dd MMM yyyy').format(date),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
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
        label = 'स्वीकृत हुन बाँकी (Pending)';
        break;
      case 'awaiting_payment':
        color = Colors.blue;
        label = 'भुक्तानी बाँकी (Awaiting Payment)';
        break;
      case 'paid':
        color = Colors.purple;
        label = 'भुक्तानी प्राप्त (Paid)';
        break;
      case 'confirmed':
        color = const Color(0xFF00C853);
        label = 'पक्का भयो (Confirmed)';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'अस्वीकृत (Rejected)';
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
        style: GoogleFonts.inter(
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
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(Icons.event_note_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            'No booking requests yet',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'New requests from potential guests\nwill appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
