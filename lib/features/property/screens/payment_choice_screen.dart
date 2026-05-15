import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _transactionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingOwner = true;
  String _paymentDestination = 'khozna'; // 'khozna' or 'owner'
  UserModel? _ownerProfile;
  File? _proofImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _proofImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOwnerPaymentDetails();
  }

  Future<void> _loadOwnerPaymentDetails() async {
    try {
      final profile = await SupabaseService.getUserProfile(
        widget.booking.ownerId,
      );
      if (mounted) {
        setState(() {
          _ownerProfile = profile;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Owner Payment Details',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSafetyWarning(),
            const SizedBox(height: 24),
            _buildPaymentStrategySelector(),
            const SizedBox(height: 32),

            // Premium Amount Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.brandColor, AppTheme.brandColor.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Decorative background money icon
                    Positioned(
                      right: -20,
                      top: -10,
                      child: Icon(
                        Icons.payments_rounded,
                        size: 140,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Total Amount to Pay',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '₹',
                                style: GoogleFonts.outfit(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                PriceFormatter.format(widget.booking.totalPrice.toString()),
                                style: GoogleFonts.outfit(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            if (_paymentDestination == 'khozna') _buildKhoznaAccountSection(),
            if (_paymentDestination == 'owner') ...[
              if (_isLoadingOwner)
                const Center(child: CircularProgressIndicator())
              else if (_ownerProfile != null)
                _buildOwnerPaymentInfo()
              else
                Text(
                  'Error loading payment details. Please chat with owner.',
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
                ),
            ],

            if (_paymentDestination == 'khozna') ...[
              const SizedBox(height: 32),
              _buildUploadProofSection(),
            ],
            const SizedBox(height: 40),

            if (_paymentDestination == 'khozna') _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStrategySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Payment Method',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStrategyCard(
                id: 'khozna',
                title: 'Secure Pay',
                subtitle: 'via KHOZNA',
                icon: 'assets/images/original_logo.png',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStrategyCard(
                id: 'owner',
                title: 'Direct Pay',
                subtitle: 'to Owner',
                icon: Icons.account_circle_rounded,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStrategyCard({
    required String id,
    required String title,
    required String subtitle,
    required dynamic icon, // Can be IconData or String (asset path)
    required Color color,
  }) {
    final isSelected = _paymentDestination == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _paymentDestination = id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (icon is IconData)
              Icon(icon, color: isSelected ? color : Colors.grey)
            else if (icon is String)
              Opacity(
                opacity: isSelected ? 1.0 : 0.4,
                child: Image.asset(icon, width: 26, height: 26),
              ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKhoznaAccountSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.brandColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 28, width: 28),
                const SizedBox(width: 10),
                Text(
                  'KHOZNA OFFICIAL ACCOUNT',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // eSewa row
                _buildKhoznaPayRow(
                  assetPath: 'assets/images/esewa.webp',
                  label: 'eSewa ID',
                  value: '9863590097',
                  color: const Color(0xFF60BB46),
                ),
                const SizedBox(height: 12),

                // Khalti row
                _buildKhoznaPayRow(
                  assetPath: 'assets/images/khalti.png',
                  label: 'Khalti ID',
                  value: '9863590097',
                  color: const Color(0xFF5C2D91),
                ),
                const SizedBox(height: 12),

                // Account Name
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/images/original_logo.png', height: 40, width: 40),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account Name', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                          Text('Khozna Nepal Pvt. Ltd.', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Reference ID
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.tag_rounded, color: Colors.orange.shade700, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Note / Remark', style: GoogleFonts.inter(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                          Text('Ref: ${widget.booking.id.substring(0, 8).toUpperCase()}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.orange.shade900)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.copy_rounded, size: 18, color: Colors.orange.shade400),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: 'Ref: ${widget.booking.id.substring(0, 8).toUpperCase()}'));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reference ID copied!'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhoznaPayRow({
    required String assetPath,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(assetPath, width: 26, height: 26, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text(value, style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 18, color: color.withOpacity(0.6)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copied!'), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.gpp_maybe_rounded,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Send payment only after agreement with owner.\nकोठा हेरेर घरबेटीसँग पक्का भएपछि मात्र पैसा पठाउनुहोला।',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner identity row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_circle_rounded,
                  color: Colors.orange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROPERTY OWNER',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    _ownerProfile?.fullName ?? 'Owner',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if ((_ownerProfile?.accountHolderName ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Holder Name',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _ownerProfile!.accountHolderName!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 32),

          if (_ownerProfile?.esewaNumber != null &&
              _ownerProfile!.esewaNumber!.isNotEmpty) ...[
            _paymentDetailItem(
              'eSewa Number',
              _ownerProfile!.esewaNumber!,
              const Color(0xFF60BB46),
              'assets/images/esewa.webp',
            ),
            const SizedBox(height: 16),
          ],

          if (_ownerProfile?.khaltiNumber != null &&
              _ownerProfile!.khaltiNumber!.isNotEmpty) ...[
            _paymentDetailItem(
              'Khalti Number',
              _ownerProfile!.khaltiNumber!,
              const Color(0xFF5C2D91),
              'assets/images/khalti.png',
            ),
            const SizedBox(height: 16),
          ],

          if (_ownerProfile?.qrCodeUrl != null &&
              _ownerProfile!.qrCodeUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Scan QR Code:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _ownerProfile!.qrCodeUrl!,
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentDetailItem(
    String label,
    String value,
    Color color, [
    String? assetIcon,
  ]) {
    return Row(
      children: [
        if (assetIcon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              assetIcon,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.grey),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied to clipboard'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUploadProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Payment Proof',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'प्रमाण अपलोड गर्नुहोस्',
          style: GoogleFonts.mukta(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _proofImage != null
                    ? AppTheme.brandColor
                    : Colors.grey.shade300,
                width: _proofImage != null ? 2 : 1,
              ),
            ),
            child: _proofImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _proofImage!,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: () => setState(() => _proofImage = null),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Screenshot',
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _transactionController,
          decoration: InputDecoration(
            hintText: 'Enter Transaction ID',
            labelText: 'Transaction ID (Optional)',
            labelStyle: GoogleFonts.inter(fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.numbers_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _proceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3.0,
                    ),
                  )
                : Text(
                    _paymentDestination == 'owner'
                        ? 'Confirm Direct Payment'
                        : 'Submit Payment Proof',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
  Future<void> _proceed() async {
    setState(() => _isSubmitting = true);
    if (_paymentDestination == 'khozna' && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload a payment screenshot first!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      String? imageUrl;
      if (_paymentDestination == 'khozna') {
        // 1. Upload to Cloudinary
        imageUrl = await CloudinaryService.uploadImage(_proofImage!);
        if (imageUrl == null) throw 'Failed to upload image. Please try again.';
      }

      // 2. Submit payment
      await BookingRepository.submitPayment(
        bookingId: widget.booking.id,
        paymentType: _paymentDestination,
        method: 'manual',
        amount: widget.booking.totalPrice,
        referenceId: _transactionController.text.trim(),
        proofImageUrl: imageUrl,
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
