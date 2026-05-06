import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/widgets/khozna_image.dart';
import 'package:flutter/services.dart';

class VisitRequestScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String ownerId;
  final String ownerName;
  final String propertyPrice;
  final String thumbnailUrl;

  const VisitRequestScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.ownerId,
    required this.ownerName,
    required this.propertyPrice,
    required this.thumbnailUrl,
  });

  @override
  State<VisitRequestScreen> createState() => _VisitRequestScreenState();
}

class _VisitRequestScreenState extends State<VisitRequestScreen> {
  DateTime _visitDate = DateTime.now().add(const Duration(days: 1));
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
          'भ्रमण अनुरोध समीक्षा (Review your visit request)',
          style: GoogleFonts.mukta(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyCard(),
            const SizedBox(height: 32),
            
            _buildInfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Preferred Visit Date',
              value: '${_visitDate.day} ${_getMonth(_visitDate.month)}, ${_visitDate.year}',
              onTap: () => _selectVisitDate(),
            ),
            
            const SizedBox(height: 24),
            
            _buildInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Visiting',
              value: 'You / 1 person',
            ),
            
            const SizedBox(height: 32),
            
            _buildPriceSection(),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Message to Owner'),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Introduce yourself and suggest a time...',
                fillColor: const Color(0xFFF8FAFC),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildTrustWarning(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomSection(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
    );
  }

  Widget _buildPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: KhoznaImage(
              imageUrl: widget.thumbnailUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.propertyTitle,
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Owned by ${widget.ownerName}',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.brandColor, size: 20),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            if (onTap != null)
              const Icon(Icons.edit_outlined, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.brandColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Rent', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              Text('Rs. ${widget.propertyPrice}', style: GoogleFonts.sora(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.brandColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Final price will be discussed after visit.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '⚠️ Please visit the room before making any payment.',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What do you want to do next?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Schedule Visit', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => chat_page.ChatScreen(
                      ownerId: widget.ownerId,
                      name: widget.ownerName,
                      avatar: '',
                      online: true,
                    ),
                  ),
                );
              },
              child: Text(
                'Chat with Owner',
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.brandColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectVisitDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await BookingRepository.createBookingRequest(
        propertyId: widget.propertyId,
        ownerId: widget.ownerId,
        checkIn: _visitDate,
        checkOut: _visitDate.add(const Duration(days: 30)), 
        totalPrice: 0, 
        message: 'भ्रमण अनुरोध (Visit Request):\n${_messageController.text}',
      );
      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true);
      }
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
