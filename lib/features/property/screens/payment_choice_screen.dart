import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
const _bg        = Color(0xFFF8FAFC);
const _card      = Colors.white;
const _ink       = Color(0xFF0F172A);
const _sub       = Color(0xFF64748B);
const _bdr       = Color(0xFFE2E8F0);
const _brand     = AppTheme.brandColor;
const _brandSoft = Color(0xFFEFF6FF);

// ─────────────────────────────────────────────────────────────────────────────
// Payment Method Enum
// ─────────────────────────────────────────────────────────────────────────────

enum _PayMethod { esewa, khalti, bankTransfer, qr }

extension _PayMethodExt on _PayMethod {
  String get label {
    switch (this) {
      case _PayMethod.esewa:        return 'eSewa';
      case _PayMethod.khalti:       return 'Khalti';
      case _PayMethod.bankTransfer: return 'Bank';
      case _PayMethod.qr:           return 'QR Code';
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

  IconData get icon {
    switch (this) {
      case _PayMethod.esewa:        return Icons.account_balance_wallet_rounded;
      case _PayMethod.khalti:       return Icons.account_balance_wallet_outlined;
      case _PayMethod.bankTransfer: return Icons.account_balance_rounded;
      case _PayMethod.qr:           return Icons.qr_code_scanner_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _PayMethod.esewa:        return const Color(0xFF60B246);
      case _PayMethod.khalti:       return const Color(0xFF5C2D91);
      case _PayMethod.bankTransfer: return const Color(0xFF2563EB);
      case _PayMethod.qr:           return _brand;
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
  _PayMethod _selectedMethod = _PayMethod.esewa;
  final _refCtrl = TextEditingController();
  File? _proofImage;
  bool _isSubmitting = false;
  bool _isLoadingOwner = true;
  UserModel? _ownerProfile;

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
      final p = await SupabaseService.getUserProfile(widget.booking.ownerId);
      if (mounted) {
        setState(() {
          _ownerProfile = p;
          _isLoadingOwner = false;
          // Pre-select first available method if present
          if (p?.esewaNumber?.isNotEmpty == true) {
            _selectedMethod = _PayMethod.esewa;
          } else if (p?.khaltiNumber?.isNotEmpty == true) {
            _selectedMethod = _PayMethod.khalti;
          } else if (p?.accountHolderName?.isNotEmpty == true) {
            _selectedMethod = _PayMethod.bankTransfer;
          } else if (p?.qrCodeUrl?.isNotEmpty == true) {
            _selectedMethod = _PayMethod.qr;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _proofImage = File(picked.path));
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
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Submit Payment',
          style: GoogleFonts.plusJakartaSans(
            color: _ink, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBookingSummaryHeader(),
            const SizedBox(height: 14),
            _buildUnifiedPaymentCard(),
            const SizedBox(height: 14),
            _buildDisclaimerBox(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  // ─── Booking Summary Header ───────────────────────────────────────────────

  Widget _buildBookingSummaryHeader() {
    final nights = widget.booking.nights;
    final total  = NumberFormat('#,##0').format(widget.booking.totalPrice);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bdr),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home_work_rounded, color: _brand, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.propertyTitle ?? 'Property Booking',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      widget.booking.formattedBookingId,
                      style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.w600),
                    ),
                    Text(' • ', style: TextStyle(color: _sub.withValues(alpha: 0.5))),
                    Text(
                      '$nights ${nights == 1 ? "night" : "nights"}',
                      style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.w500),
                    ),
                    Text(' • ', style: TextStyle(color: _sub.withValues(alpha: 0.5))),
                    Text(
                      '${widget.booking.guestCount} ${widget.booking.guestCount == 1 ? "guest" : "guests"}',
                      style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _brandSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'NPR $total',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _brand),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Unified Payment Card (Single Screen / Low Cognitive Load) ──────────────

  Widget _buildUnifiedPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bdr),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step 1 Header & Method Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('1', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select Payment Method',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMethodTabs(),
              ],
            ),
          ),

          const Divider(height: 1, color: _bdr),

          // Owner Details Dynamic Display for selected method
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSelectedMethodOwnerDetails(),
          ),

          const Divider(height: 1, color: _bdr),

          // Step 2 Input & Proof Upload
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('2', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Enter Reference & Screenshot',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _refCtrl,
                  style: GoogleFonts.inter(fontSize: 14, color: _ink, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'Transaction ID / Wallet Number (Required)',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: _sub.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.receipt_long_rounded, color: _sub, size: 18),
                    fillColor: _bg,
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _bdr)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _bdr)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _brand, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                _buildProofUploadTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payment Method Tabs ──────────────────────────────────────────────────

  Widget _buildMethodTabs() {
    return Row(
      children: _PayMethod.values.map((m) {
        final selected = _selectedMethod == m;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedMethod = m);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: m == _PayMethod.values.last ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? m.color.withValues(alpha: 0.12) : _bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? m.color : _bdr, width: selected ? 1.5 : 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m.icon, size: 18, color: selected ? m.color : _sub),
                  const SizedBox(height: 4),
                  Text(
                    m.label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? m.color : _sub,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Owner Details per Selected Method ────────────────────────────────────

  Widget _buildSelectedMethodOwnerDetails() {
    if (_isLoadingOwner) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(color: _brand, strokeWidth: 2)),
      );
    }

    String? value;
    String label = _selectedMethod.label;

    switch (_selectedMethod) {
      case _PayMethod.esewa:
        value = _ownerProfile?.esewaNumber;
        break;
      case _PayMethod.khalti:
        value = _ownerProfile?.khaltiNumber;
        break;
      case _PayMethod.bankTransfer:
        value = _ownerProfile?.accountHolderName;
        break;
      case _PayMethod.qr:
        value = _ownerProfile?.qrCodeUrl;
        break;
    }

    if (value == null || value.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No $label payment details registered by owner. Please choose another method or contact owner directly.',
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFB45309), height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedMethod == _PayMethod.qr) {
      return Column(
        children: [
          Text(
            'Scan Owner\'s Payment QR Code',
            style: GoogleFonts.inter(fontSize: 12, color: _sub, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showQrEnlarged(value!),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      value,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code_rounded, size: 80, color: _sub),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap QR to expand',
            style: GoogleFonts.inter(fontSize: 11, color: _sub),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _selectedMethod.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _selectedMethod.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _selectedMethod.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_selectedMethod.icon, color: _selectedMethod.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Owner\'s $label Details',
                  style: GoogleFonts.inter(fontSize: 10.5, color: _sub, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value!));
              _showSnack('$label details copied to clipboard!', _selectedMethod.color);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _selectedMethod.color.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 13, color: _selectedMethod.color),
                  const SizedBox(width: 5),
                  Text(
                    'Copy',
                    style: GoogleFonts.inter(fontSize: 11, color: _selectedMethod.color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
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
              Text('Owner Payment QR Code', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(qrUrl, width: 240, height: 240, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _brand)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Proof Upload Tile (No Right Overflow!) ───────────────────────────────

  Widget _buildProofUploadTile() {
    return GestureDetector(
      onTap: _pickProofImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _proofImage != null ? _brandSoft : _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _proofImage != null ? _brand : _bdr,
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
                        Text(
                          'Screenshot Attached ✓',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _brand),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to replace payment proof',
                          style: GoogleFonts.inter(fontSize: 11, color: _sub),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_rounded, color: _brand, size: 18),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _bdr.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, color: _sub, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attach Payment Receipt',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Optional • Speeds up owner verification',
                          style: GoogleFonts.inter(fontSize: 11, color: _sub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _sub, size: 20),
                ],
              ),
      ),
    );
  }

  // ─── Disclaimer Box ───────────────────────────────────────────────────────

  Widget _buildDisclaimerBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  // ─── Bottom CTA ───────────────────────────────────────────────────────────

  Widget _buildBottomCTA() {
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
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brand,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              disabledBackgroundColor: _brand.withValues(alpha: 0.5),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 19),
                      const SizedBox(width: 8),
                      Text(
                        'I\'ve Made Payment — Submit',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
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
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.4),
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
              color: _brandSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _brand.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.confirmation_number_rounded, color: _brand, size: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Reference', style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.w600)),
                    Text(bookingId, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w900, color: _brand, letterSpacing: 0.8)),
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
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: Text('Done', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
