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
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
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
                        color: Colors.white.withOpacity(0.05),
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
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Total Amount to Pay',
                                style: GoogleFonts.inter(
                                  fontSize: 14, 
                                  color: Colors.grey[300], 
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '₹',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF00FFB2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                PriceFormatter.format(widget.booking.totalPrice.toString()),
                                style: GoogleFonts.outfit(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.5,
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
                subtitle: 'via Khozna',
                icon: Icons.shield_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStrategyCard(
                id: 'owner',
                title: 'Direct Pay',
                subtitle: 'to Owner',
                icon: Icons.person_outline,
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
    required IconData icon,
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
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'KHOZNA OFFICIAL ACCOUNT',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _paymentDetailItem('eSewa / Khalti ID', '9800000000', Colors.blue),
          const SizedBox(height: 12),
          _paymentDetailItem('Account Name', 'Khozna Rentals Pvt. Ltd.', Colors.blue),
          const SizedBox(height: 12),
          _paymentDetailItem('Payment Note', 'Ref: ${widget.booking.id.substring(0, 8)}', Colors.blue),
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
              style: GoogleFonts.mukta(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade900,
                height: 1.2,
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
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.badge_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Holder Name',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _ownerProfile?.accountHolderName ??
                        _ownerProfile?.fullName ??
                        'Not provided',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),

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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
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
                ? const CircularProgressIndicator(color: Colors.white)
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
