import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/property/screens/payment_choice_screen.dart';
import 'package:intl/intl.dart';

class BookingStatusScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingStatusScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  late BookingModel _booking;
  bool _isLoading = false;
  UserModel? _ownerProfile;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _loadOwnerProfile();
  }

  Future<void> _loadOwnerProfile() async {
    final profile = await SupabaseService.getUserProfile(_booking.ownerId);
    if (mounted) setState(() => _ownerProfile = profile);
  }

  Future<void> _refreshBooking() async {
    setState(() => _isLoading = true);
    try {
      final updated = await SupabaseService.getBookingById(_booking.id);
      if (updated != null && mounted) setState(() => _booking = updated);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Status',
          style: GoogleFonts.sora(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.brandColor),
            onPressed: _refreshBooking,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(),
                const SizedBox(height: 32),
                _buildBookingTimeline(),
                const SizedBox(height: 32),
                _buildPropertyCard(),
                const SizedBox(height: 32),
                _buildActionArea(),
              ],
            ),
          ),
    );
  }

  Widget _buildStatusHeader() {
    Color color = Colors.orange;
    String title = 'Pending Approval';
    String description = 'Owner is reviewing your request.';

    switch (_booking.status) {
      case 'awaiting_payment':
        color = Colors.blue;
        title = 'Request Accepted!';
        description = 'Please complete the payment to confirm.';
        break;
      case 'paid':
        color = Colors.purple;
        title = 'Payment Received';
        description = 'Owner is verifying your payment.';
        break;
      case 'confirmed':
        color = Colors.green;
        title = 'Booking Confirmed';
        description = 'Get ready for your stay!';
        break;
      case 'rejected':
        color = Colors.red;
        title = 'Request Declined';
        description = 'The owner could not accept this request.';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: GoogleFonts.sora(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingTimeline() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimelineItem('CHECK-IN', _booking.checkIn),
          const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 20),
          _buildTimelineItem('CHECK-OUT', _booking.checkOut),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(DateFormat('MMM dd').format(date), style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(DateFormat('EEEE').format(date), style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.home_work_rounded, color: AppTheme.brandColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rental Property', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(
                  _booking.propertyTitle ?? 'Khozna Listed Property',
                  style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Host: ${_ownerProfile?.fullName ?? "..."}', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    if (_booking.status == 'awaiting_payment') {
      return SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentChoiceScreen(
                booking: _booking,
                propertyTitle: _booking.propertyTitle ?? 'Property',
              ),
            ),
          ).then((_) => _refreshBooking()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            'PROCEED TO PAYMENT',
            style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
    }

    if (_booking.status == 'confirmed') {
      return Column(
        children: [
          _buildActionButton(
            label: 'MESSAGE HOST',
            icon: Icons.chat_bubble_outline_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => chat_page.ChatScreen(
                  ownerId: _booking.ownerId,
                  name: _ownerProfile?.fullName ?? 'Owner',
                  avatar: _ownerProfile?.avatarUrl ?? '',
                  online: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            label: 'VIEW CHECK-IN DETAILS',
            icon: Icons.key_rounded,
            isPrimary: false,
            onPressed: () {},
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          backgroundColor: isPrimary ? AppTheme.brandColor : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.black,
          side: BorderSide(color: isPrimary ? AppTheme.brandColor : Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
