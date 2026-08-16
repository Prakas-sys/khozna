import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/core/utils/formatters.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/models/property_model.dart';

class PaymentChoiceScreen extends StatefulWidget {
  final BookingModel? booking;
  final String? propertyTitle;
  final Property? property;

  const PaymentChoiceScreen({
    super.key,
    this.booking,
    this.propertyTitle,
    this.property,
  });

  @override
  State<PaymentChoiceScreen> createState() => _PaymentChoiceScreenState();
}

class _PaymentChoiceScreenState extends State<PaymentChoiceScreen> {
  final TextEditingController _transactionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingOwner = true;
  String _selectedMethod = 'khozna_esewa';
  UserModel? _ownerProfile;
  File? _proofImage;
  late BookingModel _currentBooking;
  late String _currentTitle;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadOwnerPaymentDetails();
  }

  void _initializeData() {
    if (widget.booking != null) {
      _currentBooking = widget.booking!;
      _currentTitle = widget.propertyTitle ?? 'Property';
    } else if (widget.property != null) {
      final p = widget.property!;
      _currentTitle = p.title;
      double price = p.priceMonth > 0 ? p.priceMonth : (double.tryParse(p.price) ?? 0);
      _currentBooking = BookingModel(
        id: 'draft_${p.id}',
        propertyId: p.id,
        guestId: Supabase.instance.client.auth.currentUser?.id ?? '',
        ownerId: p.ownerId,
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 30)),
        totalPrice: price,
        khoznaFee: price * 0.05,
        status: 'pending_approval',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        propertyTitle: p.title,
      );
    }
  }

  Future<void> _loadOwnerPaymentDetails() async {
    try {
      final profile = await SupabaseService.getUserProfile(_currentBooking.ownerId);
      if (mounted) setState(() { _ownerProfile = profile; _isLoadingOwner = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        HapticFeedback.lightImpact();
        setState(() => _proofImage = File(image.path));
      }
    } catch (_) {}
  }

  String get _paymentDestination => _selectedMethod == 'khozna_esewa' ? 'khozna' : 'owner';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout Bill',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // ── RECEIPT TICKET CARD WITH PIN-CIRCLE / SPIKE BOTTOM ──
            _buildReceiptTicket(),

            const SizedBox(height: 20),

            // ── PAYMENT METHODS ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECT PAYMENT METHOD',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[500],
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingOwner
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: AppTheme.brandColor, strokeWidth: 2),
                          ),
                        )
                      : _buildPaymentMethods(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── SUBMIT BUTTON ──
            _buildSubmitButton(),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptTicket() {
    final String dateStr = DateFormat('MMM d, yyyy').format(_currentBooking.checkIn);
    final String amountStr = PriceFormatter.format(_currentBooking.totalPrice.toString());

    return CustomPaint(
      painter: TicketBorderPainter(),
      child: ClipPath(
        clipper: ReceiptTicketClipper(),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receipt Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.black87,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BOOKING SUMMARY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // Safety Guarantee Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                        Text(
                          '100% Protected',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Property & Date
              Text(
                _currentTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Check-in: $dateStr',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Perforated Dashed Line
              CustomPaint(
                size: const Size(double.infinity, 1),
                painter: DashedLinePainter(),
              ),

              const SizedBox(height: 16),

              // Total Amount Line
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL AMOUNT',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Advance Rent',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/vector of ruppes.svg',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        amountStr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final showOwnerEsewa = _ownerProfile?.esewaNumber?.isNotEmpty == true;
    final showOwnerKhalti = _ownerProfile?.khaltiNumber?.isNotEmpty == true;
    final showOwnerQr = _ownerProfile?.qrCodeUrl?.isNotEmpty == true;

    return Column(
      children: [
        _buildMethodRow(
          id: 'khozna_esewa',
          label: 'Khozna Secure (eSewa)',
          sublabel: 'Escrow protection guaranteed',
          logo: 'assets/images/esewa.webp',
        ),
        if (showOwnerEsewa)
          _buildMethodRow(
            id: 'owner_esewa',
            label: 'Host\'s eSewa Direct',
            sublabel: 'Pay to landlord\'s wallet',
            logo: 'assets/images/esewa.webp',
          ),
        if (showOwnerKhalti)
          _buildMethodRow(
            id: 'owner_khalti',
            label: 'Host\'s Khalti Direct',
            sublabel: 'Pay to landlord\'s wallet',
            logo: 'assets/images/khalti.png',
          ),
        if (showOwnerQr)
          _buildMethodRow(
            id: 'owner_qr',
            label: 'Scan Host\'s QR',
            sublabel: 'Any banking or wallet app',
            icon: Icons.qr_code_scanner_rounded,
          ),
        const SizedBox(height: 12),
        _buildSelectedMethodDetail(),
      ],
    );
  }

  Widget _buildMethodRow({
    required String id,
    required String label,
    required String sublabel,
    String? logo,
    IconData? icon,
  }) {
    final isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMethod = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            if (logo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(logo, width: 24, height: 24, fit: BoxFit.contain),
              )
            else if (icon != null)
              Icon(icon, size: 22, color: Colors.grey[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMethodDetail() {
    if (_selectedMethod == 'khozna_esewa') return _buildKhoznaDetail();
    if (_selectedMethod == 'owner_esewa') return _buildOwnerDetail(
      number: _ownerProfile?.esewaNumber ?? '',
      logo: 'assets/images/esewa.webp',
    );
    if (_selectedMethod == 'owner_khalti') return _buildOwnerDetail(
      number: _ownerProfile?.khaltiNumber ?? '',
      logo: 'assets/images/khalti.png',
    );
    if (_selectedMethod == 'owner_qr') return _buildQrDetail();
    return const SizedBox.shrink();
  }

  Widget _buildKhoznaDetail() {
    const number = '9863590097';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset('assets/images/esewa.webp', width: 22, height: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('eSewa Escrow ID', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    Text(number, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: number));
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('eSewa ID copied!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy_rounded, size: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            try { await launchUrl(Uri.parse('esewa://'), mode: LaunchMode.externalApplication); }
            catch (_) { await launchUrl(Uri.parse('https://esewa.com.np'), mode: LaunchMode.externalApplication); }
          },
          child: Row(
            children: [
              const Icon(Icons.open_in_new_rounded, size: 12, color: Colors.black87),
              const SizedBox(width: 4),
              Text(
                'Open eSewa App',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildProofUpload(),
      ],
    );
  }

  Widget _buildOwnerDetail({required String number, required String logo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.asset(logo, width: 22, height: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Host Wallet Number', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    Text(number, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: number));
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.copy_rounded, size: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        if (_ownerProfile?.accountHolderName?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            'Registered Host Name: ${_ownerProfile!.accountHolderName}',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 16),
        _buildProofUpload(),
      ],
    );
  }

  Widget _buildQrDetail() {
    final qrUrl = _ownerProfile?.qrCodeUrl ?? '';
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(qrUrl, width: 160, height: 160, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildProofUpload(),
      ],
    );
  }

  Widget _buildProofUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Screenshot',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _proofImage != null ? Colors.black : Colors.grey[300]!,
                width: _proofImage != null ? 1.5 : 1,
              ),
            ),
            child: _proofImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(_proofImage!, width: double.infinity, height: 90, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 6, top: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _proofImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 20, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text('Upload Screenshot', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _transactionController,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Transaction ID (Optional)',
            hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _proceed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: _isSubmitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Center(
                child: Text(
                  _paymentDestination == 'owner' ? 'Confirm Payment' : 'Submit Proof',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _proceed() async {
    setState(() => _isSubmitting = true);
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload a payment screenshot first.', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }
    try {
      final imageUrl = await CloudinaryService.uploadImage(_proofImage!);
      if (imageUrl == null) throw 'Failed to upload image.';

      String finalBookingId = _currentBooking.id;
      if (finalBookingId.startsWith('draft_')) {
        final newBooking = await BookingRepository.createBooking(_currentBooking);
        if (newBooking != null) finalBookingId = newBooking.id;
        else throw 'Failed to create booking record.';
      }

      await BookingRepository.submitPayment(
        bookingId: finalBookingId,
        paymentType: _paymentDestination,
        method: 'bank_transfer',
        amount: _currentBooking.totalPrice,
        referenceId: _transactionController.text.trim(),
        proofImageUrl: imageUrl,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ── CUSTOM CLIPPER FOR PERFORATED RECEIPT TICKET (PIN-CIRCLE BORDER AT BOTTOM) ──
class ReceiptTicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 14.0;
    const double circleRadius = 5.0;
    const double spacing = 14.0;

    final path = Path();
    // Top-left
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    // Top line
    path.lineTo(size.width - radius, 0);
    // Top-right
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    // Right side line
    path.lineTo(size.width, size.height);

    // Bottom pin-circles (serrated scalloped receipt edge)
    final int count = (size.width / spacing).floor();
    final double step = size.width / count;

    for (int i = count; i >= 0; i--) {
      final double x = i * step;
      path.arcToPoint(
        Offset(x, size.height),
        radius: const Radius.circular(circleRadius),
        clockwise: false,
      );
    }

    // Left side line back to top
    path.lineTo(0, radius);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ── CUSTOM PAINTER FOR RECEIPT BORDER / SHADOW ──
class TicketBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = ReceiptTicketClipper().getClip(size);
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ── DASHED LINE PAINTER FOR RECEIPT DIVIDER ──
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 5;
    const double dashSpace = 4;
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
