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
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const _bg    = Color(0xFFF8FAFC);
const _card  = Colors.white;
const _ink   = Color(0xFF0F172A);
const _sub   = Color(0xFF64748B);
const _bdr   = Color(0xFFE2E8F0);
const _brand = AppTheme.brandColor;

// ─────────────────────────────────────────────────────────────────────────────
// Payment Method enum
// ─────────────────────────────────────────────────────────────────────────────

enum _PayMethod { esewa, khalti, bankTransfer, qr }

extension _PayMethodExt on _PayMethod {
  String get label {
    switch (this) {
      case _PayMethod.esewa:       return 'eSewa';
      case _PayMethod.khalti:      return 'Khalti';
      case _PayMethod.bankTransfer: return 'Bank Transfer';
      case _PayMethod.qr:          return 'QR Code';
    }
  }

  String get key {
    switch (this) {
      case _PayMethod.esewa:       return 'esewa';
      case _PayMethod.khalti:      return 'khalti';
      case _PayMethod.bankTransfer: return 'bank_transfer';
      case _PayMethod.qr:          return 'qr';
    }
  }

  IconData get icon {
    switch (this) {
      case _PayMethod.esewa:       return Icons.payment_rounded;
      case _PayMethod.khalti:      return Icons.account_balance_wallet_rounded;
      case _PayMethod.bankTransfer: return Icons.account_balance_rounded;
      case _PayMethod.qr:          return Icons.qr_code_scanner_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _PayMethod.esewa:        return const Color(0xFF60B246);
      case _PayMethod.khalti:       return const Color(0xFF5C2D91);
      case _PayMethod.bankTransfer: return const Color(0xFF1D4ED8);
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
  _PayMethod? _selectedMethod;
  final _refCtrl  = TextEditingController();
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
      if (mounted) setState(() { _ownerProfile = p; _isLoadingOwner = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _proofImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (_selectedMethod == null) {
      _showSnack('Please select a payment method.', const Color(0xFFE11D48));
      return;
    }
    if (_refCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a transaction reference or wallet number.', const Color(0xFFE11D48));
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      String? proofUrl;
      if (_proofImage != null) {
        // Upload proof screenshot to Supabase Storage
        final bytes = await _proofImage!.readAsBytes();
        final fileName = 'proof_${widget.booking.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final client = Supabase.instance.client;
        await client.storage.from('payment_proofs').uploadBinary(fileName, bytes);
        proofUrl = client.storage.from('payment_proofs').getPublicUrl(fileName);
      }

      await BookingRepository.submitPayment(
        bookingId: widget.booking.id,
        method: _selectedMethod!.key,
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

  // ─── Build ────────────────────────────────────────────────────────────────

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
              color: _ink, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBookingSummary(),
            const SizedBox(height: 16),
            _buildOwnerPaymentDetails(),
            const SizedBox(height: 16),
            _buildMethodSelector(),
            const SizedBox(height: 14),
            _buildReferenceField(),
            const SizedBox(height: 14),
            _buildProofUpload(),
            const SizedBox(height: 14),
            _buildDisclaimerBox(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  // ─── Booking Summary ────────────────────────────────────────────────────────

  Widget _buildBookingSummary() {
    final nights = widget.booking.nights;
    final total  = NumberFormat('#,##0').format(widget.booking.totalPrice);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: _brand.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.home_work_rounded, color: _brand, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.booking.propertyTitle ?? 'Booking',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(widget.booking.formattedBookingId,
                  style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.w600)),
            ])),
          ]),
          const SizedBox(height: 12),
          Container(height: 1, color: _bdr),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _infoChip(Icons.calendar_today_rounded, '$nights ${nights == 1 ? "night" : "nights"}'),
            _infoChip(Icons.people_rounded, '${widget.booking.guestCount} ${widget.booking.guestCount == 1 ? "guest" : "guests"}'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _brand.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Text('NPR $total',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _brand)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: _sub),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.inter(fontSize: 12, color: _sub, fontWeight: FontWeight.w600)),
    ]);
  }

  // ─── Owner Payment Details ─────────────────────────────────────────────────

  Widget _buildOwnerPaymentDetails() {
    if (_isLoadingOwner) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _bdr)),
        child: const Center(child: CircularProgressIndicator(color: _brand, strokeWidth: 2)),
      );
    }

    final hasEsewa   = _ownerProfile?.esewaNumber?.isNotEmpty == true;
    final hasKhalti  = _ownerProfile?.khaltiNumber?.isNotEmpty == true;
    final hasBank    = _ownerProfile?.accountHolderName?.isNotEmpty == true;
    final hasQr      = _ownerProfile?.qrCodeUrl?.isNotEmpty == true;
    final hasAny     = hasEsewa || hasKhalti || hasBank || hasQr;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_circle_rounded, color: _brand, size: 20),
            const SizedBox(width: 8),
            Text('Pay the Property Owner',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
          ]),
          const SizedBox(height: 4),
          Text('Transfer the amount to the owner using any of their payment methods below.',
              style: GoogleFonts.inter(fontSize: 12, color: _sub, height: 1.4)),
          const SizedBox(height: 14),
          if (!hasAny)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
              child: Text(
                'The owner hasn\'t added payment details yet. Please contact them via chat to arrange payment.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFD97706), height: 1.4),
              ),
            )
          else ...[ 
            if (hasEsewa)  _ownerDetailRow('eSewa',    Icons.payment_rounded,                const Color(0xFF60B246), _ownerProfile!.esewaNumber!),
            if (hasKhalti) _ownerDetailRow('Khalti',   Icons.account_balance_wallet_rounded, const Color(0xFF5C2D91), _ownerProfile!.khaltiNumber!),
            if (hasBank)   _ownerDetailRow('Bank',     Icons.account_balance_rounded,        const Color(0xFF1D4ED8), _ownerProfile!.accountHolderName!),
            if (hasQr) ...[
              const SizedBox(height: 10),
              Center(
                child: Column(children: [
                  Text('Scan QR Code', style: GoogleFonts.inter(fontSize: 12, color: _sub, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_ownerProfile!.qrCodeUrl!, width: 140, height: 140, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code_rounded, size: 80, color: _sub)),
                  ),
                ]),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _ownerDetailRow(String method, IconData icon, Color color, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(method, style: GoogleFonts.inter(fontSize: 10.5, color: _sub, fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            _showSnack('$method number copied!', _brand);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _brand.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _brand.withOpacity(0.2)),
            ),
            child: Text('Copy', style: GoogleFonts.inter(fontSize: 11, color: _brand, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  // ─── Method Selector ──────────────────────────────────────────────────────

  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _bdr)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How did you pay?',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _PayMethod.values.map((m) {
              final selected = _selectedMethod == m;
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedMethod = m); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? m.color.withOpacity(0.1) : _bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? m.color : _bdr, width: selected ? 1.5 : 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(m.icon, size: 16, color: selected ? m.color : _sub),
                    const SizedBox(width: 7),
                    Text(m.label,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? m.color : _ink)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Reference Field ──────────────────────────────────────────────────────

  Widget _buildReferenceField() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _bdr)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transaction Reference / ID',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text('Enter the transaction ID, wallet number, or confirmation code from your payment.',
              style: GoogleFonts.inter(fontSize: 11.5, color: _sub, height: 1.4)),
          const SizedBox(height: 10),
          TextField(
            controller: _refCtrl,
            style: GoogleFonts.inter(fontSize: 14, color: _ink, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'e.g. TXN123456789',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: _sub, fontWeight: FontWeight.w500),
              prefixIcon: const Icon(Icons.receipt_long_rounded, color: _sub, size: 18),
              fillColor: _bg,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _bdr)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _bdr)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _brand, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Proof Upload ─────────────────────────────────────────────────────────

  Widget _buildProofUpload() {
    return GestureDetector(
      onTap: _pickProofImage,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _proofImage != null ? _brand : _bdr, width: _proofImage != null ? 1.5 : 1),
        ),
        child: _proofImage != null
            ? Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_proofImage!, width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Screenshot Added ✓',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _brand)),
                  const SizedBox(height: 3),
                  Text('Tap to change screenshot', style: GoogleFonts.inter(fontSize: 11.5, color: _sub)),
                ])),
                Icon(Icons.edit_rounded, color: _sub, size: 18),
              ])
            : Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: _bdr.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add_photo_alternate_rounded, color: _sub, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Attach Payment Screenshot',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _sub.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                      child: Text('Optional', style: GoogleFonts.inter(fontSize: 10, color: _sub, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Text('Recommended for faster verification', style: GoogleFonts.inter(fontSize: 11, color: _sub)),
                  ]),
                ])),
              ]),
      ),
    );
  }

  // ─── Disclaimer ───────────────────────────────────────────────────────────

  Widget _buildDisclaimerBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'By submitting, you confirm you\'ve paid the owner directly. KHOZNA does not process or hold payments. The owner will verify and confirm your booking.',
            style: GoogleFonts.inter(fontSize: 11.5, color: Color(0xFF92400E), height: 1.45),
          ),
        ),
      ]),
    );
  }

  // ─── Bottom CTA ───────────────────────────────────────────────────────────

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      decoration: BoxDecoration(
        color: _card,
        border: const Border(top: BorderSide(color: _bdr)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brand,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              disabledBackgroundColor: _brand.withOpacity(0.5),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text("I've Made Payment — Submit",
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
                  ]),
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
            width: 72, height: 72,
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0), width: 2)),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 36),
          ),
          const SizedBox(height: 20),
          Text('Payment Info Submitted!',
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('The owner will verify your payment and confirm your booking.\nWe\'ll notify you once it\'s confirmed.',
              style: GoogleFonts.inter(fontSize: 14, color: _sub, height: 1.55),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _brand.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _brand.withOpacity(0.2)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.confirmation_number_rounded, color: _brand, size: 18),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Booking Reference', style: GoogleFonts.inter(fontSize: 11, color: _sub, fontWeight: FontWeight.w600)),
                Text(bookingId, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: _brand, letterSpacing: 1)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('Done', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
