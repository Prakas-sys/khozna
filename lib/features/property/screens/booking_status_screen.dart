import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/core/models/booking_model.dart';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Booking Status', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.brandColor), onPressed: _refreshBooking)],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(_booking.status),
                const SizedBox(height: 24),
                _buildPropertyInfo(),
                const SizedBox(height: 24),
                _buildBookingDetails(),
                const SizedBox(height: 24),
                if (_booking.status == 'confirmed') _buildOwnerContact(),
                if (_booking.status == 'rejected') _buildRejectionReason(),
              ],
            ),
          ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color = Colors.orange;
    String title = 'Pending Approval';
    IconData icon = Icons.hourglass_empty_rounded;

    if (status == 'confirmed') {
      color = Colors.green;
      title = 'Booking Confirmed!';
      icon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      color = Colors.red;
      title = 'Request Not Accepted';
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        const SizedBox(width: 16),
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildPropertyInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.home_work_outlined, color: AppTheme.brandColor, size: 30),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_booking.propertyTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Owner: ${_ownerProfile?.fullName ?? 'Loading...'}', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
        ])),
      ]),
    );
  }

  Widget _buildBookingDetails() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Booking Details', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _buildRow(Icons.calendar_today, 'Move-in', DateFormat('MMM dd, yyyy').format(_booking.moveInDate)),
      _buildRow(Icons.timer_outlined, 'Duration', '${_booking.durationMonths} Months'),
      _buildRow(Icons.people_outline, 'Guests', '${_booking.guestsCount} People'),
      _buildRow(Icons.info_outline, 'Purpose', _booking.purpose.toUpperCase()),
    ]);
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Icon(icon, size: 18, color: Colors.grey[600]),
      const SizedBox(width: 12),
      Text(label, style: GoogleFonts.outfit(color: Colors.grey[600])),
      const Spacer(),
      Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
    ]));
  }

  Widget _buildOwnerContact() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Contact Information', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const SizedBox(height: 4),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => chat_page.ChatScreen(ownerId: _booking.ownerId, name: _ownerProfile?.fullName ?? 'Owner', avatar: _ownerProfile?.avatarUrl ?? '', online: true))), icon: const Icon(Icons.chat), label: const Text('Message Owner'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandColor, foregroundColor: Colors.white))),
      ]),
    );
  }

  Widget _buildRejectionReason() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Reason for Rejection', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 8),
        Text(_booking.rejectReason ?? 'No reason provided.'),
      ]),
    );
  }
}
