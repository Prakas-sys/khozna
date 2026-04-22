import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/supabase_service.dart';
import 'chat_screen.dart' as chat_page;

class BookingStatusScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingStatusScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  late Map<String, dynamic> _booking;
  bool _isLoading = false;
  Map<String, dynamic>? _ownerProfile;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _loadOwnerProfile();
  }

  Future<void> _loadOwnerProfile() async {
    final profile = await SupabaseService.getUserProfile(_booking['owner_id']);
    if (mounted) {
      setState(() {
        _ownerProfile = profile;
      });
    }
  }

  Future<void> _refreshBooking() async {
    setState(() => _isLoading = true);
    try {
      final updated = await SupabaseService.getBookingById(_booking['id']);
      if (updated != null && mounted) {
        setState(() {
          _booking = updated;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing booking: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _booking['status']?.toString().toLowerCase() ?? 'pending';
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Status',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.brandColor),
            onPressed: _refreshBooking,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(status),
                const SizedBox(height: 24),
                _buildPropertyInfo(),
                const SizedBox(height: 24),
                _buildBookingDetails(),
                const SizedBox(height: 24),
                if (status == 'confirmed' || status == 'active') _buildOwnerContact(),
                if (status == 'rejected') _buildRejectionReason(),
                const SizedBox(height: 40),
                if (status == 'confirmed') _buildActionButtons(),
              ],
            ),
          ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color;
    String title;
    String subtitle;
    IconData icon;

    switch (status) {
      case 'confirmed':
        color = Colors.green;
        title = 'Booking Confirmed!';
        subtitle = 'Get ready for your move-in.';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        color = Colors.red;
        title = 'Request Not Accepted';
        subtitle = 'The owner declined this request.';
        icon = Icons.cancel_rounded;
        break;
      case 'active':
        color = AppTheme.brandColor;
        title = 'Active Stay';
        subtitle = 'You are currently staying here.';
        icon = Icons.home_rounded;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        title = 'Pending Approval';
        subtitle = 'Owner has 48 hours to respond.';
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color.darker(0.2),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: color.darker(0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.home_work_outlined, color: AppTheme.brandColor, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _booking['property_title'] ?? 'Property',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Owner: ${widget.booking['owner_name'] ?? _ownerProfile?['full_name'] ?? 'Loading...'}',
                  style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Details',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.calendar_today, 'Move-in Date', _booking['move_in_date']),
        _buildDetailRow(Icons.timer_outlined, 'Duration', '${_booking['duration_months']} Months'),
        _buildDetailRow(Icons.people_outline, 'Guests', '${_booking['guests_count']} People'),
        _buildDetailRow(Icons.info_outline, 'Purpose', _booking['purpose']?.toString().toUpperCase() ?? 'OTHER'),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.outfit(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOwnerContact() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 20, color: Colors.green),
              const SizedBox(width: 12),
              Text(
                _ownerProfile?['phone_number'] ?? 'N/A',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => chat_page.ChatScreen(
                      ownerId: _booking['owner_id'],
                      name: _ownerProfile?['full_name'] ?? 'Owner',
                      avatar: _ownerProfile?['avatar_url'] ?? '',
                      online: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Message Owner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReason() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Reason for Rejection',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _booking['reject_reason'] ?? 'No reason provided by owner.',
            style: GoogleFonts.outfit(color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return const SizedBox.shrink(); // Add confirmed actions if needed
  }
}

extension ColorExtension on Color {
  Color darker(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkerHsl = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkerHsl.toColor();
  }
}
