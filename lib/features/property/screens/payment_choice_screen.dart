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
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/widgets/khozna_image.dart';

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
  
  // Selected option: 'khozna_esewa', 'owner_esewa', 'owner_khalti', 'owner_qr'
  String _selectedMethod = 'khozna_esewa'; 
  UserModel? _ownerProfile;
  File? _proofImage;
  late BookingModel _currentBooking;
  late String _currentTitle;

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
      // Calculate draft price (1 month if month price exists, else full price)
      double price = p.priceMonth > 0 ? p.priceMonth : (double.tryParse(p.price) ?? 0);
      
      _currentBooking = BookingModel(
        id: 'draft_${p.id}',
        propertyId: p.id,
        guestId: Supabase.instance.client.auth.currentUser?.id ?? '',
        ownerId: p.ownerId,
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 30)),
        totalPrice: price,
        khoznaFee: price * 0.05, // 5% fee estimation
        status: 'pending_approval',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        propertyTitle: p.title,
      );
    }
  }

  Future<void> _loadOwnerPaymentDetails() async {
    try {
      final profile = await SupabaseService.getUserProfile(
        _currentBooking.ownerId,
      );
      if (mounted) {
        setState(() {
          _ownerProfile = profile;
          _isLoadingOwner = false;
          
          // Autofill starting selection based on what owner has
          if (_ownerProfile != null) {
            if (_ownerProfile!.esewaNumber != null && _ownerProfile!.esewaNumber!.isNotEmpty) {
              // Stay with khozna_esewa as default or default to owner if preferred
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  String get _paymentDestination {
    if (_selectedMethod == 'khozna_esewa') return 'khozna';
    return 'owner';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Payment',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripSummaryCard(),
            const SizedBox(height: 24),
            _buildSafetyGuarantee(),
            const SizedBox(height: 28),
            Center(
              child: Text(
                'Select Payment Method',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isLoadingOwner
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.brandColor)))
                : _buildVerticalPaymentMethods(),
            const SizedBox(height: 32),
            _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummaryCard() {
    final checkInStr = DateFormat('EEE, MMM d, yyyy').format(_currentBooking.checkIn);
        
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.property?.imageUrl != null
                      ? Image.network(widget.property!.imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                      : (widget.booking?.propertyId != null 
                          ? KhoznaImage(imageUrl: '', width: 80, height: 80) // Fallback handled by widget
                          : Container(width: 80, height: 80, color: Colors.grey[100], child: const Icon(Icons.home_work_rounded, color: Colors.grey))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RESERVATION DETAILS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            checkInStr,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
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
          const Divider(height: 1),
          // Price Summary Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), 
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (NPR)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'NPR. ',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                      TextSpan(
                        text: PriceFormatter.format(_currentBooking.totalPrice.toString()),
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
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

  Widget _buildVerticalPaymentMethods() {
    final showOwnerEsewa = _ownerProfile?.esewaNumber != null && _ownerProfile!.esewaNumber!.isNotEmpty;
    final showOwnerKhalti = _ownerProfile?.khaltiNumber != null && _ownerProfile!.khaltiNumber!.isNotEmpty;
    final showOwnerQr = _ownerProfile?.qrCodeUrl != null && _ownerProfile!.qrCodeUrl!.isNotEmpty;

    return Column(
      children: [
        // Option 1: eSewa Secure Pay (via Khozna)
        _buildPaymentMethodTile(
          id: 'khozna_esewa',
          title: 'Secure Pay via Khozna (eSewa)',
          subtitle: 'Khozna escrow guarantees refund if property has issues.',
          logoPath: 'assets/images/esewa.webp',
          expandableContent: _buildKhoznaEsewaDetails(),
        ),
        const SizedBox(height: 12),

        // Option 2: Direct Pay to Owner's eSewa
        if (showOwnerEsewa) ...[
          _buildPaymentMethodTile(
            id: 'owner_esewa',
            title: 'Direct Pay to Host\'s eSewa',
            subtitle: 'Pay directly to landlord\'s eSewa wallet.',
            logoPath: 'assets/images/esewa.webp',
            expandableContent: _buildOwnerEsewaDetails(),
          ),
          const SizedBox(height: 12),
        ],

        // Option 3: Direct Pay to Host's Khalti
        if (showOwnerKhalti) ...[
          _buildPaymentMethodTile(
            id: 'owner_khalti',
            title: 'Direct Pay to Host\'s Khalti',
            subtitle: 'Pay directly to landlord\'s Khalti wallet.',
            logoPath: 'assets/images/khalti.png',
            expandableContent: _buildOwnerKhaltiDetails(),
          ),
          const SizedBox(height: 12),
        ],

        // Option 4: Direct Pay via QR Code Scan
        if (showOwnerQr)
          _buildPaymentMethodTile(
            id: 'owner_qr',
            title: 'Scan Host\'s QR Code',
            subtitle: 'Scan and pay using any banking app or local wallet.',
            iconData: Icons.qr_code_scanner_rounded,
            expandableContent: _buildOwnerQrDetails(),
          ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String title,
    required String subtitle,
    String? logoPath,
    IconData? iconData,
    required Widget expandableContent,
  }) {
    final isSelected = _selectedMethod == id;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedMethod = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.brandColor.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Radio Selector button
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.brandColor : Colors.grey[400]!,
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
                              color: AppTheme.brandColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  // Logo/Icon
                  if (logoPath != null)
                    Image.asset(logoPath, width: 28, height: 28, fit: BoxFit.contain)
                  else if (iconData != null)
                    Icon(iconData, size: 28, color: Colors.blueGrey),
                  const SizedBox(width: 14),
                  // Titles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Expanded body with animation
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: expandableContent,
                  ),
                ],
              ),
              crossFadeState: isSelected ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  // Option Content A: Khozna Escrow eSewa Details
  Widget _buildKhoznaEsewaDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF60BB46).withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF60BB46).withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Image.asset('assets/images/esewa.webp', width: 30, height: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('eSewa ID (Khozna Escrow)', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('9863590097', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF60BB46))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF60BB46)),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: '9863590097'));
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('eSewa ID copied to clipboard!'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () async {
              final Uri appUrl = Uri.parse('esewa://');
              final Uri webUrl = Uri.parse('https://esewa.com.np');
              try {
                await launchUrl(appUrl, mode: LaunchMode.externalApplication);
              } catch (_) {
                try {
                  await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                } catch (_) {}
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF60BB46)),
            label: Text(
              'Open eSewa App',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF60BB46)),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: const Color(0xFF60BB46).withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildUploadProofSection(),
      ],
    );
  }

  // Option Content B: Direct Host eSewa Details
  Widget _buildOwnerEsewaDetails() {
    final String esewaNum = _ownerProfile?.esewaNumber ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCopyDetailCard('Host eSewa Number', esewaNum, const Color(0xFF60BB46), 'assets/images/esewa.webp'),
        if (_ownerProfile?.accountHolderName != null && _ownerProfile!.accountHolderName!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTextMetaCard('Registered Name', _ownerProfile!.accountHolderName!, Icons.badge_outlined),
        ],
        const SizedBox(height: 20),
        _buildUploadProofSection(),
      ],
    );
  }

  // Option Content C: Direct Host Khalti Details
  Widget _buildOwnerKhaltiDetails() {
    final String khaltiNum = _ownerProfile?.khaltiNumber ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCopyDetailCard('Host Khalti Number', khaltiNum, const Color(0xFF5C2D91), 'assets/images/khalti.png'),
        if (_ownerProfile?.accountHolderName != null && _ownerProfile!.accountHolderName!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTextMetaCard('Registered Name', _ownerProfile!.accountHolderName!, Icons.badge_outlined),
        ],
        const SizedBox(height: 20),
        _buildUploadProofSection(),
      ],
    );
  }

  // Option Content D: Host QR Scanner card
  Widget _buildOwnerQrDetails() {
    final String qrUrl = _ownerProfile?.qrCodeUrl ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Scan this QR code using your wallet app to transfer rent:',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade100),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                qrUrl,
                width: 180,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildUploadProofSection(),
      ],
    );
  }

  Widget _buildCopyDetailCard(String label, String value, Color themeColor, String logoAsset) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Image.asset(logoAsset, width: 28, height: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: themeColor)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 18, color: themeColor),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copied to clipboard!'), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextMetaCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              Text(value, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Payment Screenshot',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFBFDFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _proofImage != null ? AppTheme.brandColor : Colors.grey.shade300,
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
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 14,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 12, color: Colors.white),
                            onPressed: () => setState(() => _proofImage = null),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: Colors.grey[400], size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to Upload Screenshot',
                        style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _transactionController,
          decoration: InputDecoration(
            hintText: 'Enter Transaction ID',
            labelText: 'Transaction ID (Optional)',
            labelStyle: GoogleFonts.inter(fontSize: 12.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyGuarantee() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.brandColor.withOpacity(0.08), Colors.blue.withOpacity(0.01)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.brandColor.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khozna Safety Guarantee',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Your payment is 100% protected',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGuaranteeItem(
            Icons.lock_clock_rounded,
            'Escrow Security',
            'We hold your money safely and only pay the landlord AFTER you check in.',
          ),
          const SizedBox(height: 12),
          _buildGuaranteeItem(
            Icons.assignment_return_rounded,
            'Full Refund Guarantee',
            'Get 100% money back if the room doesn\'t match the photos or description.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'तपाइँको भुक्तानी Khozna मा सुरक्षित रहनेछ। कोठा हेरेर चित्त बुझेपछि मात्र घरधनीले पैसा पाउनेछन्।',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.brandColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.brandColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
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
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _proceed,
            icon: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
            label: Text(
              _paymentDestination == 'owner'
                  ? 'Confirm Direct Payment'
                  : 'Submit Payment Proof',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              disabledBackgroundColor: AppTheme.brandColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                children: [
                  const TextSpan(text: 'By proceeding, you agree to our '),
                  TextSpan(
                    text: 'Terms & Privacy Policy.',
                    style: TextStyle(
                      color: AppTheme.brandColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _proceed() async {
    setState(() => _isSubmitting = true);
    
    // Validate proof image for all escrow routes
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload a payment screenshot first!',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      // 1. Upload proof screenshot to Cloudinary
      final imageUrl = await CloudinaryService.uploadImage(_proofImage!);
      if (imageUrl == null) throw 'Failed to upload image. Please try again.';

      // 2. Submit payment to repository
      String finalBookingId = _currentBooking.id;

      // If it's a draft booking from "Book Now", create the booking record first
      if (finalBookingId.startsWith('draft_')) {
        final newBooking = await BookingRepository.createBooking(_currentBooking);
        if (newBooking != null) {
          finalBookingId = newBooking.id;
        } else {
          throw 'Failed to create booking record.';
        }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
