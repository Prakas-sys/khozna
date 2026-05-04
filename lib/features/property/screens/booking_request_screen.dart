import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:flutter/services.dart';

class BookingRequestScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String ownerId;
  final String ownerName;

  const BookingRequestScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 2));
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'बुकिङ अनुरोध (Request Booking)',
          style: GoogleFonts.mukta(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyHeader(),
            const SizedBox(height: 32),
            _buildDatePicker(
              label: 'पस्ने मिति (CHECK-IN)',
              date: _checkIn,
              onTap: () => _selectDate(true),
            ),
            const SizedBox(height: 16),
            _buildDatePicker(
              label: 'निस्कने मिति (CHECK-OUT)',
              date: _checkOut,
              onTap: () => _selectDate(false),
            ),
            const SizedBox(height: 32),
            Text(
              'Message to Owner',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Introduce yourself and ask any questions...',
                fillColor: const Color(0xFFF8FAFC),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildPriceSummary(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  Widget _buildPropertyHeader() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.home_work_rounded, color: AppTheme.brandColor, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.propertyTitle,
                style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Owned by ${widget.ownerName}',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  '${date.day} ${_getMonth(date.month)}, ${date.year}',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(Icons.calendar_today_rounded, color: AppTheme.brandColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    final days = _checkOut.difference(_checkIn).inDays;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Duration', style: GoogleFonts.inter(color: Colors.grey)),
              Text('$days Days', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Text(
            'मालिकले तपाईंको अनुरोध स्वीकृत गरेपछि भुक्तानी गर्ने विकल्प आउनेछ।\n(Payment option will appear after the owner approves your request.)',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'अनुरोध पठाउनुहोस् (SEND REQUEST)',
                    style: GoogleFonts.mukta(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: isCheckIn ? DateTime.now() : _checkIn.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut.isBefore(_checkIn.add(const Duration(days: 1)))) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await BookingRepository.createBookingRequest(
        propertyId: widget.propertyId,
        ownerId: widget.ownerId,
        checkIn: _checkIn,
        checkOut: _checkOut,
        totalPrice: 0, // In real app, calculate based on property.price
        message: _messageController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getMonth(int month) {
    return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
  }
}
