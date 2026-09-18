import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens (Airbnb Style)
// ─────────────────────────────────────────────────────────────────────────────
const _bg        = Color(0xFFF8FAFC);
const _card      = Colors.white;
const _ink       = Color(0xFF111827); // High contrast dark
const _sub       = Color(0xFF6B7280);
const _bdr       = Color(0xFFE5E7EB);
const _airbnbDark = Color(0xFF222222); // Airbnb signature dark color
const _brand     = AppTheme.brandColor;

// ─────────────────────────────────────────────────────────────────────────────
// Payment Method Enum
// ─────────────────────────────────────────────────────────────────────────────

enum _PayMethod { esewa, khalti, bankTransfer, qr }

extension _PayMethodExt on _PayMethod {
  String get title {
    switch (this) {
      case _PayMethod.esewa:        return 'eSewa Wallet';
      case _PayMethod.khalti:       return 'Khalti Wallet';
      case _PayMethod.bankTransfer: return 'Direct Bank Transfer';
      case _PayMethod.qr:           return 'Scan Owner QR Code';
    }
  }

  String get subtitle {
    switch (this) {
      case _PayMethod.esewa:        return 'Pay directly to owner\'s eSewa number';
      case _PayMethod.khalti:       return 'Pay directly to owner\'s Khalti number';
      case _PayMethod.bankTransfer: return 'Transfer via mobile banking / account';
      case _PayMethod.qr:           return 'Scan QR code using any banking app';
    }
  }

  String get key {
    switch (this) {
      case _PayMethod.esewa:        return 'esewa';
      case _PayMethod.khalti:       return 'khalti';
      case _PayMethod.bankTransfer: return 'bank_transfer';
      case _PayMethod.qr:           return 'qr';
    }
  }

  Widget buildLeadingIcon() {
    switch (this) {
      case _PayMethod.esewa:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/esewa.webp',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 32, height: 32,
              color: const Color(0xFF60B246).withValues(alpha: 0.15),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF60B246), size: 20),
            ),
          ),
        );
      case _PayMethod.khalti:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/khalti.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 32, height: 32,
              color: const Color(0xFF5C2D91).withValues(alpha: 0.15),
              child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF5C2D91), size: 20),
            ),
          ),
        );
      case _PayMethod.bankTransfer:
        return Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.account_balance_rounded, color: Color(0xFF2563EB), size: 18),
        );
      case _PayMethod.qr:
        return Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _airbnbDark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.qr_code_2_rounded, color: _airbnbDark, size: 20),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class PaymentChoiceScreen extends StatefulWidget {
  final BookingModel booking;

  const PaymentChoiceScreen({super.key, required this.booking});

  @override
  State<PaymentChoiceScreen> createState() => _PaymentChoiceScreenState();
}

class _PaymentChoiceScreenState extends State<PaymentChoiceScreen> {
  int _currentStep = 0; // Step 0: Review, Step 1: Select Method, Step 2: Transfer Details & Submit
  _PayMethod _selectedMethod = _PayMethod.esewa;
  final _refCtrl = TextEditingController();
  File? _proofImage;
  bool _isSubmitting = false;
  bool _isLoadingOwner = true;
  UserModel? _ownerProfile;
  String? _propertyImageUrl;
  Map<String, dynamic>? _ownerDataMap;
  Map<String, dynamic>? _propertyDataMap;

  @override
  void initState() {
    super.initState();
    _loadOwnerProfile();
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOwnerProfile() async {
    try {
      final ownerRes = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.booking.ownerId)
          .maybeSingle();

      final propRes = await Supabase.instance.client
          .from('properties')
          .select()
          .eq('id', widget.booking.propertyId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _ownerDataMap = ownerRes;
          _propertyDataMap = propRes;
          if (ownerRes != null) {
            _ownerProfile = UserModel.fromMap(ownerRes);
          }
          _isLoadingOwner = false;

          if (propRes != null) {
            final imageUrl = propRes['image_url'] as String?;
            final imagesList = propRes['images'];
            final images = imagesList is List ? imagesList.map((e) => e.toString()).toList() : <String>[];
            _propertyImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
                ? imageUrl
                : (images.isNotEmpty ? images.first : null);
          }

          final esewa = _getPaymentValue(_PayMethod.esewa);
          final khalti = _getPaymentValue(_PayMethod.khalti);
          final bank = _getPaymentValue(_PayMethod.bankTransfer);
          final qr = _getPaymentValue(_PayMethod.qr);

          if (esewa != null && esewa.isNotEmpty) {
            _selectedMethod = _PayMethod.esewa;
          } else if (khalti != null && khalti.isNotEmpty) {
            _selectedMethod = _PayMethod.khalti;
          } else if (bank != null && bank.isNotEmpty) {
            _selectedMethod = _PayMethod.bankTransfer;
          } else if (qr != null && qr.isNotEmpty) {
            _selectedMethod = _PayMethod.qr;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading owner details: $e');
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  String? _getPaymentValue(_PayMethod method) {
    String? checkKeys(Map<String, dynamic>? map, List<String> keys) {
      if (map == null) return null;
      for (final k in keys) {
        final v = map[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      return null;
    }

    String? val;
    switch (method) {
      case _PayMethod.esewa:
        val = checkKeys(_ownerDataMap, ['esewa_number', 'esewa', 'esewa_id']) ??
              checkKeys(_propertyDataMap, ['esewa_number', 'esewa', 'esewa_id']) ??
              _ownerProfile?.esewaNumber;
        // Fallback to phone number if owner profile phone number exists
        val ??= checkKeys(_ownerDataMap, ['phone_number', 'phone']) ?? _ownerProfile?.phoneNumber;
        break;
      case _PayMethod.khalti:
        val = checkKeys(_ownerDataMap, ['khalti_number', 'khalti', 'khalti_id']) ??
              checkKeys(_propertyDataMap, ['khalti_number', 'khalti', 'khalti_id']) ??
              _ownerProfile?.khaltiNumber;
        break;
      case _PayMethod.bankTransfer:
        val = checkKeys(_ownerDataMap, ['account_holder_name', 'bank_details', 'bank_name', 'account_number']) ??
              checkKeys(_propertyDataMap, ['account_holder_name', 'bank_details', 'bank_name', 'account_number']) ??
              _ownerProfile?.accountHolderName;
        break;
      case _PayMethod.qr:
        val = checkKeys(_ownerDataMap, ['qr_code_url', 'qr_url', 'qr_code', 'payment_qr']) ??
              checkKeys(_propertyDataMap, ['qr_code_url', 'qr_url', 'qr_code', 'payment_qr']) ??
              _ownerProfile?.qrCodeUrl;
        break;
    }
    return (val != null && val.isNotEmpty) ? val : null;
  }

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _proofImage = File(picked.path));
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (_refCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a transaction reference or wallet number.', const Color(0xFFE11D48));
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      String? proofUrl;
      if (_proofImage != null) {
        final bytes = await _proofImage!.readAsBytes();
        final fileName = 'proof_${widget.booking.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final client = Supabase.instance.client;
        await client.storage.from('payment_proofs').uploadBinary(fileName, bytes);
        proofUrl = client.storage.from('payment_proofs').getPublicUrl(fileName);
      }

      await BookingRepository.submitPayment(
        bookingId: widget.booking.id,
        method: _selectedMethod.key,
        amount: widget.booking.totalPrice,
        referenceId: _refCtrl.text.trim(),
        proofImageUrl: proofUrl,
      );

      if (!mounted) return;
      _showSuccessSheet();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to submit. Please try again.', const Color(0xFFE11D48));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        bookingId: widget.booking.formattedBookingId,
        onDone: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _prevStep();
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _card,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 18),
            onPressed: _prevStep,
          ),
          title: Text(
            'Confirm and pay',
            style: GoogleFonts.inter(
              color: _ink, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: _bdr,
              valueColor: const AlwaysStoppedAnimation<Color>(_airbnbDark),
              minHeight: 3,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepTitleHeader(),
              const SizedBox(height: 18),
              if (_currentStep == 0) _buildStep1Review(),
              if (_currentStep == 1) _buildStep2PaymentMethod(),
              if (_currentStep == 2) _buildStep3TransferAndSubmit(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomCTABar(),
      ),
    );
  }

  // ─── Header Step Indicator Title ──────────────────────────────────────────

  Widget _buildStepTitleHeader() {
    String stepLabel;
    String stepHeading;

    switch (_currentStep) {
      case 0:
        stepLabel = 'Step 1 of 3';
        stepHeading = 'Review booking details';
        break;
      case 1:
        stepLabel = 'Step 2 of 3';
        stepHeading = 'Select payment method';
        break;
      default:
        stepLabel = 'Step 3 of 3';
        stepHeading = 'Complete transfer';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepLabel.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _sub, letterSpacing: 0.8),
        ),
        const SizedBox(height: 3),
        Text(
          stepHeading,
          style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.4),
        ),
      ],
    );
  }

  // ─── STEP 1: Review Booking Details ───────────────────────────────────────

  Widget _buildStep1Review() {
    final rawNights = widget.booking.nights;
    final nights = (rawNights == 30) ? 1 : rawNights;
    final checkIn = widget.booking.checkIn;
    final checkOut = (rawNights == 30) ? checkIn.add(const Duration(days: 1)) : widget.booking.checkOut;
    final total = NumberFormat('#,##0').format(widget.booking.totalPrice);
    final checkInStr = DateFormat('MMM d, yyyy').format(checkIn);
    final checkOutStr = DateFormat('MMM d, yyyy').format(checkOut);

    return Column(
      children: [
        // ── Unified Spiked Receipt Review Card ────────────────────────────────
        CustomPaint(
          painter: ReceiptTicketBorderPainter(
            borderColor: _bdr,
            spikeHeight: 7.0,
            spikeWidth: 10.0,
            radius: 18.0,
          ),
          child: ClipPath(
            clipper: ReceiptTicketClipper(
              spikeHeight: 7.0,
              spikeWidth: 10.0,
              radius: 18.0,
            ),
            child: Container(
              color: _card,
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [

                  // ── Property header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: _brand.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: (_propertyImageUrl != null && _propertyImageUrl!.isNotEmpty)
                                ? KhoznaImage(
                                    imageUrl: _propertyImageUrl!,
                                    width: 76,
                                    height: 76,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.home_work_rounded, color: _brand, size: 34),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.booking.propertyTitle ?? 'Property Booking',
                                style: GoogleFonts.inter(fontSize: 17.5, fontWeight: FontWeight.w800, color: _ink),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.confirmation_number_outlined, size: 14, color: _sub),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.booking.formattedBookingId,
                                    style: GoogleFonts.inter(fontSize: 13, color: _sub, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(height: 1, color: _bdr),

                  // ── Dates + Guests row ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: _brand),
                                  const SizedBox(width: 6),
                                  Text('CHECK-IN', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _sub, letterSpacing: 0.7)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(checkInStr, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink)),
                              const SizedBox(height: 2),
                              Text('$nights ${nights == 1 ? "night" : "nights"}', style: GoogleFonts.inter(fontSize: 12.5, color: _sub, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 48, color: _bdr),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_busy_rounded, size: 14, color: Color(0xFFE11D48)),
                                    const SizedBox(width: 6),
                                    Text('CHECK-OUT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _sub, letterSpacing: 0.7)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(checkOutStr, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink)),
                                const SizedBox(height: 2),
                                Text('${widget.booking.guestCount} ${widget.booking.guestCount == 1 ? "guest" : "guests"}', style: GoogleFonts.inter(fontSize: 12.5, color: _sub, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(height: 1, color: _bdr),

                  // ── Price breakdown ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _priceRow('Stay ($nights ${nights == 1 ? "night" : "nights"})', total, _sub, _ink, FontWeight.w600, FontWeight.w700, 14.0, valueFontSize: 17.5, iconSize: 13.5),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: _bdr),
                        ),
                        _priceRow('Total Rent', total, _ink, _ink, FontWeight.w800, FontWeight.w800, 15.5, valueFontSize: 21.0, iconSize: 16.5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceRow(
    String label,
    String amountStr,
    Color labelColor,
    Color valueColor,
    FontWeight labelWeight,
    FontWeight valueWeight,
    double fontSize, {
    double? valueFontSize,
    double? iconSize,
  }) {
    final effectiveValueFontSize = valueFontSize ?? fontSize;
    final effectiveIconSize = iconSize ?? (effectiveValueFontSize * 0.78);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: fontSize, color: labelColor, fontWeight: labelWeight)),
        RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Transform.translate(
                  offset: const Offset(0, -1.0),
                  child: SvgPicture.asset(
                    'assets/icons/vector of ruppes.svg',
                    width: effectiveIconSize,
                    height: effectiveIconSize,
                    colorFilter: ColorFilter.mode(valueColor, BlendMode.srcIn),
                  ),
                ),
              ),
              const WidgetSpan(child: SizedBox(width: 3.5)),
              TextSpan(
                text: amountStr,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: effectiveValueFontSize,
                  color: valueColor,
                  fontWeight: valueWeight,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }




  // ─── STEP 2: Select Payment Method (Airbnb Horizontal Single Line Rows) ───

  Widget _buildStep2PaymentMethod() {
    final availableMethods = _PayMethod.values.where((m) => _getPaymentValue(m) != null).toList();
    final methodsToShow = availableMethods.isNotEmpty ? availableMethods : _PayMethod.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose how to pay',
          style: GoogleFonts.inter(fontSize: 13.5, color: _sub, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 14),
        if (availableMethods.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No details provided for this wallet yet. Please contact the owner.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB45309), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        for (final method in methodsToShow) _buildMethodTile(method),
      ],
    );
  }

  Widget _buildMethodTile(_PayMethod method) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedMethod = method);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _airbnbDark : _bdr,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            method.buildLeadingIcon(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.subtitle,
                    style: GoogleFonts.inter(fontSize: 11.5, color: _sub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _airbnbDark : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _airbnbDark : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 3: Transfer Info, Input & Receipt Upload ────────────────────────

  Widget _buildStep3TransferAndSubmit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOwnerPaymentDetailsCard(),
        const SizedBox(height: 16),
        _buildReferenceInputField(),
        const SizedBox(height: 16),
        _buildSendReceiptUploadBox(),
        const SizedBox(height: 16),
        _buildDisclaimerNotice(),
      ],
    );
  }

  Widget _buildOwnerPaymentDetailsCard() {
    if (_isLoadingOwner) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _bdr)),
        child: const CircularProgressIndicator(color: _airbnbDark, strokeWidth: 2),
      );
    }

    final value = _getPaymentValue(_selectedMethod);
    final label = _selectedMethod.title;

    if (value == null || value.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No details provided for this wallet. Please choose another method or contact the owner.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB45309), height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final nonNullVal = value;

    if (_selectedMethod == _PayMethod.qr) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _bdr),
        ),
        child: Column(
          children: [
            Text(
              'Scan Owner\'s Payment QR Code',
              style: GoogleFonts.inter(fontSize: 13, color: _ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showQrEnlarged(nonNullVal),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _bdr),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    nonNullVal,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code_rounded, size: 80, color: _sub),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Tap QR image to expand', style: GoogleFonts.inter(fontSize: 11.5, color: _sub)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer to Owner\'s Account',
            style: GoogleFonts.inter(fontSize: 12, color: _sub, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _selectedMethod.buildLeadingIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.w500)),
                    Text(nonNullVal, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: nonNullVal));
                  _showSnack('$label details copied!', _airbnbDark);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _airbnbDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Copy',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Reference / ID *',
            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the confirmation code or transaction ID from your payment app.',
            style: GoogleFonts.inter(fontSize: 11.5, color: _sub),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _refCtrl,
            style: GoogleFonts.inter(fontSize: 14, color: _ink, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g. TXN123456789 or 9863590097',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: _sub.withValues(alpha: 0.6)),
              prefixIcon: const Icon(Icons.receipt_long_rounded, color: _sub, size: 18),
              fillColor: _bg,
              filled: true,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _bdr)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _bdr)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _airbnbDark, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendReceiptUploadBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Payment Receipt',
            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional • Speeds up owner verification & booking approval',
            style: GoogleFonts.inter(fontSize: 11.5, color: _sub),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickProofImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _proofImage != null ? const Color(0xFFF0FDF4) : _bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _proofImage != null ? const Color(0xFF16A34A) : _bdr,
                  width: _proofImage != null ? 1.5 : 1,
                ),
              ),
              child: _proofImage != null
                  ? Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_proofImage!, width: 44, height: 44, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Receipt Attached ✓', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
                              const SizedBox(height: 2),
                              Text('Tap to change payment receipt', style: GoogleFonts.inter(fontSize: 11, color: _sub)),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_rounded, color: Color(0xFF16A34A), size: 18),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: _bdr.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.add_a_photo_rounded, color: _sub, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Upload Receipt Screenshot', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                              const SizedBox(height: 2),
                              Text('PNG, JPG or WebP images', style: GoogleFonts.inter(fontSize: 11, color: _sub)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _sub, size: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Direct owner payment. Khozna helps facilitate booking details while the property owner verifies your transfer.',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showQrEnlarged(String qrUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Owner Payment QR Code', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(qrUrl, width: 240, height: 240, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _airbnbDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bottom CTA Bar (Airbnb Signature Black Button) ────────────────────────

  Widget _buildBottomCTABar() {
    String buttonText;
    if (_currentStep == 0) {
      buttonText = 'Proceed to Payment';
    } else if (_currentStep == 1) {
      buttonText = 'Next: Payment Details';
    } else {
      buttonText = 'Submit Payment';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: _card,
        border: const Border(top: BorderSide(color: _bdr)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: _airbnbDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: _airbnbDark.withValues(alpha: 0.5),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == 2 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final String bookingId;
  final VoidCallback onDone;

  const _SuccessSheet({required this.bookingId, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'Payment Details Submitted!',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The owner will verify your payment and confirm your booking.\nWe\'ll notify you as soon as it\'s confirmed.',
            style: GoogleFonts.inter(fontSize: 13, color: _sub, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _bdr),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.confirmation_number_rounded, color: _airbnbDark, size: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Reference', style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.w600)),
                    Text(bookingId, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: _airbnbDark, letterSpacing: 0.8)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: _airbnbDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Done', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spiked / Sawtooth Receipt Clipper & Painter
// ─────────────────────────────────────────────────────────────────────────────
class ReceiptTicketClipper extends CustomClipper<Path> {
  final double spikeHeight;
  final double spikeWidth;
  final double radius;

  ReceiptTicketClipper({
    this.spikeHeight = 7.0,
    this.spikeWidth = 10.0,
    this.radius = 18.0,
  });

  @override
  Path getClip(Size size) {
    return _createReceiptPath(size, spikeHeight, spikeWidth, radius);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ReceiptTicketBorderPainter extends CustomPainter {
  final double spikeHeight;
  final double spikeWidth;
  final double radius;
  final Color borderColor;
  final double borderWidth;

  ReceiptTicketBorderPainter({
    this.spikeHeight = 7.0,
    this.spikeWidth = 10.0,
    this.radius = 18.0,
    required this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _createReceiptPath(size, spikeHeight, spikeWidth, radius);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Path _createReceiptPath(Size size, double spikeHeight, double spikeWidth, double radius) {
  final path = Path();
  // Top-left rounded corner
  path.moveTo(0, radius);
  path.quadraticBezierTo(0, 0, radius, 0);

  // Top edge
  path.lineTo(size.width - radius, 0);

  // Top-right rounded corner
  path.quadraticBezierTo(size.width, 0, size.width, radius);

  // Right edge down to spikes
  path.lineTo(size.width, size.height - spikeHeight);

  // Bottom spiked receipt edge (right to left)
  final count = (size.width / spikeWidth).floor();
  final step = size.width / count;
  double x = size.width;

  for (int i = 0; i < count; i++) {
    final midX = x - step / 2;
    path.lineTo(midX, size.height);
    final nextX = x - step;
    path.lineTo(nextX, size.height - spikeHeight);
    x = nextX;
  }

  // Left edge back up to top-left corner
  path.lineTo(0, radius);
  path.close();
  return path;
}
