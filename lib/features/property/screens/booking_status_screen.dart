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
      final updated = await SupabaseService.getVisitById(_booking.id);
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
          'भ्रमण अवस्था (Visit Status)',
          style: GoogleFonts.mukta(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18),
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
    Color color;
    String title;
    String description;

    switch (_booking.status) {
      case 'awaiting_payment':
        color = Colors.blue;
        title = 'अनुरोध स्वीकृत (Accepted!)';
        description = 'मालिकले भ्रमणको लागि निम्तो दिनुभएको छ। कोठा हेर्न जानुहोला।';
        break;
      case 'paid':
        color = Colors.purple;
        title = 'कोठा मन पर्यो (Liked Room)';
        description = 'तपाईंले कोठा मन पराउनुभयो। अब मालिकसँग कुरा गरेर अगाडि बढ्नुहोस्।';
        break;
      case 'confirmed':
        color = Colors.green;
        title = 'भ्रमण पक्का (Visit Confirmed)';
        description = 'तपाइँको भ्रमण समय पक्का भयो। कोठा हेर्न समयमा पुग्नुहोला!';
        break;
      case 'rejected':
        color = Colors.red;
        title = 'भ्रमण अस्वीकृत (Rejected)';
        description = 'मालिकले अहिले यो समयमा भ्रमण गराउन सक्नुभएन।';
        break;
      default:
        color = Colors.orange;
        title = 'भ्रमण अनुरोध (Visit Requested)';
        description = 'मालिकले तपाइँको भ्रमण अनुरोध हेर्दै हुनुहुन्छ। समय पक्का भएपछि यहाँ देखिनेछ।';
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimelineItem('भ्रमण मिति (VISIT DATE)', _booking.checkIn),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.brandColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Text(
                  'तपाईं कोठा हेर्न जानुभयो? कस्तो लाग्यो?\n(Did you visit the room? Share your experience.)',
                  style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 16, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'If you liked it, proceed to talk about moving in.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Moves to decision stage
                          setState(() {
                            _booking = _booking.copyWith(status: 'awaiting_payment');
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('YES, I LIKED IT'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('NO, SEARCH MORE'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
