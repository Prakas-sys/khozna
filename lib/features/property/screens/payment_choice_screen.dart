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
  int _currentStep = 0; // 0 = Select Method & Review, 1 = Pay & Upload Proof
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          children: [
            Text(
              _currentStep == 0 ? 'Confirm & Pay' : 'Complete Payment',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              'Step ${_currentStep + 1} of 2',
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            backgroundColor: Colors.grey[100],
            color: Colors.black,
            minHeight: 3,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _currentStep == 0 ? _buildStepOne() : _buildStepTwo(),
      ),
    );
  }

  // ── STEP 1: REVIEW RESERVATION & CHOOSE METHOD ──
  Widget _buildStepOne() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReceiptTicket(),

                const SizedBox(height: 20),

                Text(
                  'PAYMENT METHOD',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[500],
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                _isLoadingOwner
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: AppTheme.brandColor, strokeWidth: 2),
                        ),
                      )
                    : _buildPaymentMethodsList(),
              ],
            ),
          ),
        ),

        // Bottom Sticky Action Button
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _currentStep = 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Payment',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 2: VIEW DETAILS & UPLOAD PROOF ──
  Widget _buildStepTwo() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected Payment Method Detail Box
                _buildSelectedPaymentCard(),

                const SizedBox(height: 20),

                // Upload Section
                _buildProofUploadSection(),

                const SizedBox(height: 20),

                // Protection Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your funds stay safe in Khozna Escrow until you inspect the property in person.',
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Sticky Action Button
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
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
                          'Submit Payment & Confirm',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── RECEIPT TICKET ──
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
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.black87,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'BOOKING SUMMARY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 11, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 3),
                        Text(
                          '100% Protected',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
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

              CustomPaint(
                size: const Size(double.infinity, 1),
                painter: DashedLinePainter(),
              ),

              const SizedBox(height: 16),

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
                      Transform.translate(
                        offset: const Offset(0, 1),
                        child: SvgPicture.asset(
                          'assets/icons/vector of ruppes.svg',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        amountStr,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: -0.5,
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

  // ── PAYMENT METHOD SELECTOR LIST ──
  Widget _buildPaymentMethodsList() {
    final showOwnerEsewa = _ownerProfile?.esewaNumber?.isNotEmpty == true;
    final showOwnerKhalti = _ownerProfile?.khaltiNumber?.isNotEmpty == true;
    final showOwnerQr = _ownerProfile?.qrCodeUrl?.isNotEmpty == true;

    return Column(
      children: [
        _buildMethodOptionTile(
          id: 'khozna_esewa',
          title: 'Khozna Secure (eSewa)',
          subtitle: 'Protected by Escrow refund guarantee',
          logo: 'assets/images/esewa.webp',
        ),
        if (showOwnerEsewa)
          _buildMethodOptionTile(
            id: 'owner_esewa',
            title: 'Host\'s eSewa Direct',
            subtitle: 'Transfer directly to landlord',
            logo: 'assets/images/esewa.webp',
          ),
        if (showOwnerKhalti)
          _buildMethodOptionTile(
            id: 'owner_khalti',
            title: 'Host\'s Khalti Direct',
            subtitle: 'Transfer directly to landlord',
            logo: 'assets/images/khalti.png',
          ),
        if (showOwnerQr)
          _buildMethodOptionTile(
            id: 'owner_qr',
            title: 'Scan Host\'s QR Code',
            subtitle: 'Scan using any banking app',
            icon: Icons.qr_code_scanner_rounded,
          ),
      ],
    );
  }

  Widget _buildMethodOptionTile({
    required String id,
    required String title,
    required String subtitle,
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
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[200]!,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.04 : 0.01),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
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
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            if (logo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(logo, width: 28, height: 28, fit: BoxFit.contain),
              )
            else if (icon != null)
              Icon(icon, size: 26, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SELECTED METHOD DISPLAY (STEP 2) ──
  Widget _buildSelectedPaymentCard() {
    if (_selectedMethod == 'khozna_esewa') {
      return _buildCopyDetailCard(
        title: 'Khozna eSewa Escrow ID',
        number: '9863590097',
        logo: 'assets/images/esewa.webp',
        showOpenEsewa: true,
      );
    }
    if (_selectedMethod == 'owner_esewa') {
      return _buildCopyDetailCard(
        title: 'Host eSewa Number',
        number: _ownerProfile?.esewaNumber ?? '',
        logo: 'assets/images/esewa.webp',
        holderName: _ownerProfile?.accountHolderName,
      );
    }
    if (_selectedMethod == 'owner_khalti') {
      return _buildCopyDetailCard(
        title: 'Host Khalti Number',
        number: _ownerProfile?.khaltiNumber ?? '',
        logo: 'assets/images/khalti.png',
        holderName: _ownerProfile?.accountHolderName,
      );
    }
    if (_selectedMethod == 'owner_qr') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(
              'Scan Host QR Code',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(_ownerProfile?.qrCodeUrl ?? '', width: 170, height: 170, fit: BoxFit.cover),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCopyDetailCard({
    required String title,
    required String number,
    required String logo,
    bool showOpenEsewa = false,
    String? holderName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(logo, width: 28, height: 28, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  number,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: number));
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ID copied to clipboard!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded, size: 14, color: Colors.black),
                      const SizedBox(width: 4),
                      Text('Copy', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (holderName != null && holderName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Account Name: $holderName',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
          if (showOpenEsewa) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try { await launchUrl(Uri.parse('esewa://'), mode: LaunchMode.externalApplication); }
                  catch (_) { await launchUrl(Uri.parse('https://esewa.com.np'), mode: LaunchMode.externalApplication); }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.black),
                label: Text(
                  'Open eSewa App',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── PROOF UPLOAD (STEP 2) ──
  Widget _buildProofUploadSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPLOAD PAYMENT SCREENSHOT',
            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _proofImage != null ? Colors.black : Colors.grey[300]!,
                  width: _proofImage != null ? 1.8 : 1,
                ),
              ),
              child: _proofImage != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_proofImage!, width: double.infinity, height: 110, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 8, top: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _proofImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 26, color: Colors.grey[400]),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to upload transfer receipt',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transactionController,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Transaction ID / Ref No. (Optional)',
              hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
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

// ── PERFORATED RECEIPT CLIPPER & PAINTERS ──
class ReceiptTicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 14.0;
    const double circleRadius = 5.0;
    const double spacing = 14.0;

    final path = Path();
    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height);

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

    path.lineTo(0, radius);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

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
