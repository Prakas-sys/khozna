import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/widgets/khozna_image.dart';

class PaymentChoiceScreen extends StatefulWidget {
  final BookingModel booking;
  final String propertyTitle;

  const PaymentChoiceScreen({
    super.key,
    required this.booking,
    required this.propertyTitle,
  });

  @override
  State<PaymentChoiceScreen> createState() => _PaymentChoiceScreenState();
}

class _PaymentChoiceScreenState extends State<PaymentChoiceScreen> {
  String? _selectedType;
  bool _isSubmitting = false;
  bool _isLoadingOwner = true;
  String? _ownerEsewa;
  String? _ownerQr;

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
  }

  Future<void> _loadOwnerInfo() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('esewa_number, qr_code_url')
          .eq('id', widget.booking.ownerId)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _ownerEsewa = data?['esewa_number'];
          _ownerQr = data?['qr_code_url'];
          _isLoadingOwner = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'भुक्तानीको प्रकार (Payment)',
          style: GoogleFonts.mukta(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: _isLoadingOwner 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildSectionTitle('भुक्तानी विधि छान्नुहोस्', 'Select how you want to pay'),
                  const SizedBox(height: 20),
                  
                  // Option 1: Direct to Owner
                  _buildChoiceCard(
                    id: 'direct',
                    title: 'घरबेटीलाई सिधै तिर्ने',
                    englishTitle: 'Pay Owner Direct',
                    subtitle: 'छिटो र सजिलो (Fast & Simple)',
                    description: 'तपाईंले घरबेटीको eSewa नम्बरमा सिधै पैसा पठाउनुहुन्छ। खोज्नाले यसको जिम्मेवारी लिने छैन।',
                    fee: '५% सेवा शुल्क (5% Fee)',
                    esewa: _ownerEsewa ?? 'Not provided',
                    qrUrl: _ownerQr,
                    icon: Icons.flash_on_rounded,
                    color: Colors.orange,
                    isRecommended: false,
                    protection: false,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Option 2: Pay Khozna (Recommended)
                  _buildChoiceCard(
                    id: 'khozna',
                    title: 'खोज्नालाई तिर्ने',
                    englishTitle: 'Pay Khozna',
                    subtitle: 'सुरक्षित र भरपर्दो (Recommended)',
                    description: 'तपाईंको पैसा खोज्नाको खातामा सुरक्षित रहन्छ। केहि समस्या भएमा पूर्ण फिर्ता पाइनेछ।',
                    fee: '१०% सेवा शुल्क (10% Fee)',
                    esewa: '9800000000', // Khozna's main number
                    qrUrl: null, // We can add Khozna's QR here
                    icon: Icons.verified_user_rounded,
                    color: AppTheme.brandColor,
                    isRecommended: true,
                    protection: true,
                  ),

                  const SizedBox(height: 32),
                  _buildProtectionBox(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.brandColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
              'बुकिङ विवरण',
              style: GoogleFonts.mukta(color: AppTheme.brandColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.propertyTitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'जेठ १५ - १६ (${widget.booking.totalPrice} - १ रात)',
                style: GoogleFonts.mukta(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String nepali, String english) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nepali, style: GoogleFonts.mukta(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
        Text(english, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildChoiceCard({
    required String id,
    required String title,
    required String englishTitle,
    required String subtitle,
    required String description,
    required String fee,
    required String esewa,
    required String? qrUrl,
    required IconData icon,
    required Color color,
    required bool isRecommended,
    required bool protection,
  }) {
    final isSelected = _selectedType == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedType = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]
            : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: GoogleFonts.mukta(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(englishTitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.brandColor, borderRadius: BorderRadius.circular(10)),
                    child: Text('RECOMMENDED', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(subtitle, style: GoogleFonts.mukta(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            const SizedBox(height: 8),
            Text(description, style: GoogleFonts.mukta(color: Colors.grey[600], fontSize: 13, height: 1.4)),
            
            if (qrUrl != null && isSelected) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _viewFullQr(qrUrl),
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: KhoznaImage(imageUrl: qrUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Tap to enlarge QR Code', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('eSewa Number:', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(esewa, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fee, style: GoogleFonts.mukta(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                    if (!protection) 
                      Text('⚠️ No protection', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewFullQr(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: KhoznaImage(imageUrl: url, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtectionBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.brandColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.brandColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('खोज्ना किन रोज्ने?', style: GoogleFonts.mukta(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'खोज्नाबाट पैसा तिर्दा तपाईंको पैसा सुरक्षित रहन्छ। यदि घरबेटीले बुकिङ रद्द गरेमा वा कोठा खराब भएमा, हामी तपाईंको पैसा तुरुन्त फिर्ता गर्छौं।',
                  style: GoogleFonts.mukta(color: Colors.grey[700], fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    if (_selectedType == null) return const SizedBox.shrink();

    final feePercent = _selectedType == 'khozna' ? 0.10 : 0.05;
    final feeAmount = widget.booking.totalPrice * feePercent;
    final total = widget.booking.totalPrice + feeAmount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('कुल रकम (Total Amount)', style: GoogleFonts.mukta(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(
                    'Rs. ${NumberFormat('#,##,###').format(total)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('अगाडी बढ्नुहोस्', style: GoogleFonts.mukta(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToPayment() async {
    setState(() => _isSubmitting = true);
    try {
      await BookingRepository.submitPayment(
        bookingId: widget.booking.id,
        paymentType: _selectedType!,
        method: 'esewa',
        amount: widget.booking.totalPrice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Submitted! Waiting for verification.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
