// ============================================================
// BOOST PROMOTION SCREEN — Entry point, redirects to QR payment
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

// ─────────────────────── STEP 1: SELECT PLAN ───────────────────────
class QrPaymentPlanScreen extends StatefulWidget {
  final String propertyId;
  final String title;
  final String imageUrl;

  const QrPaymentPlanScreen({
    super.key,
    required this.propertyId,
    required this.title,
    required this.imageUrl,
  });

  @override
  State<QrPaymentPlanScreen> createState() => _QrPaymentPlanScreenState();
}

class _QrPaymentPlanScreenState extends State<QrPaymentPlanScreen> {
  String _selectedTier = 'boost_3d';

  static const _tiers = [
    {
      'id': 'boost_3d',
      'label': 'Boost (3 Days)',
      'price': 99,
      'priceLabel': 'Rs. 99',
      'desc': 'Extra visibility for a short burst.',
      'icon': Icons.flash_on,
      'color': Colors.orange,
      'isPremium': false,
    },
    {
      'id': 'boost_7d',
      'label': 'Boost (7 Days)',
      'price': 199,
      'priceLabel': 'Rs. 199',
      'desc': 'Stay on top longer.',
      'icon': Icons.trending_up,
      'color': Colors.blue,
      'isPremium': false,
    },
    {
      'id': 'top_highlight',
      'label': 'Top + Highlight',
      'price': 399,
      'priceLabel': 'Rs. 399',
      'desc': 'Maximum attention in all feeds.',
      'icon': Icons.stars,
      'color': Colors.purple,
      'isPremium': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _tiers.firstWhere((t) => t['id'] == _selectedTier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Boost Your Listing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Get More Renters, Faster 🚀', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
            const SizedBox(height: 6),
            Text(
              'तपाईंको कोठाको विज्ञापन बढाउनुहोस्! अधिक किरायेदारहरूले देख्न पाउँछन्।',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),

            // Property Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                color: const Color(0xFFF8F9FB),
              ),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(widget.imageUrl, width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.home)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ]),
            ),
            const SizedBox(height: 28),

            Text('Boost Package छान्नुहोस्', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),

            ..._tiers.map((tier) {
              final isSelected = _selectedTier == tier['id'];
              final color = tier['color'] as Color;
              return GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedTier = tier['id'] as String); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
                    boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))] : [],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(tier['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(tier['label'] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (tier['isPremium'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('BEST VALUE', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 3),
                            Text(tier['desc'] as String, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(tier['priceLabel'] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                          if (isSelected) ...[
                            const SizedBox(height: 4),
                            Icon(Icons.check_circle, color: color, size: 18),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 50),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QrScanPayScreen(
                propertyId: widget.propertyId,
                boostTier: _selectedTier,
                amount: selected['price'] as int,
                priceLabel: selected['priceLabel'] as String,
                label: selected['label'] as String,
              )),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Continue to Pay • ${selected['priceLabel']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── STEP 2: SCAN & PAY ───────────────────────
class QrScanPayScreen extends StatefulWidget {
  final String propertyId;
  final String boostTier;
  final int amount;
  final String priceLabel;
  final String label;

  const QrScanPayScreen({
    super.key,
    required this.propertyId,
    required this.boostTier,
    required this.amount,
    required this.priceLabel,
    required this.label,
  });

  @override
  State<QrScanPayScreen> createState() => _QrScanPayScreenState();
}

class _QrScanPayScreenState extends State<QrScanPayScreen> {
  int _selectedMethod = 0; // 0=eSewa, 1=Khalti, 2=IME Pay, 3=NepalPay

  // ─── QR Placeholder colors (replace with actual QR asset images) ───
  static const List<Map<String, dynamic>> _methods = [
    {'label': 'eSewa',    'color': Color(0xFF60BB46), 'icon': Icons.account_balance_wallet},
    {'label': 'Khalti',   'color': Color(0xFF5C2D91), 'icon': Icons.account_balance_wallet},
    {'label': 'IME Pay',  'color': Color(0xFFE31E24), 'icon': Icons.account_balance_wallet},
    {'label': 'NepalPay', 'color': Color(0xFF003399), 'icon': Icons.account_balance_wallet},
  ];

  @override
  Widget build(BuildContext context) {
    final method = _methods[_selectedMethod];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Scan & Pay', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // Amount box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.brandColor, Color(0xFF00B4F5)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                Text('तिर्नुपर्ने रकम', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(widget.priceLabel, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 36)),
                Text('for ${widget.label}', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 28),

            // Method tabs
            Text('भुक्तानी विधि छान्नुहोस्', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_methods.length, (i) {
                  final m = _methods[i];
                  final sel = _selectedMethod == i;
                  return GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedMethod = i); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? (m['color'] as Color) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: sel ? (m['color'] as Color) : Colors.grey.shade300),
                        boxShadow: sel ? [BoxShadow(color: (m['color'] as Color).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
                      ),
                      child: Text(m['label'] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: sel ? Colors.white : Colors.black87)),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 28),

            // QR Code Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: Column(children: [
                // Header with logo color
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: (method['color'] as Color).withOpacity(0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(method['icon'] as IconData, color: method['color'] as Color, size: 20),
                      const SizedBox(width: 8),
                      Text(method['label'] as String, style: GoogleFonts.outfit(color: method['color'] as Color, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // QR placeholder (replace with Image.asset('assets/qr/esewa_qr.png') etc.)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (method['color'] as Color).withOpacity(0.3), width: 2),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 100, color: (method['color'] as Color)),
                      const SizedBox(height: 8),
                      Text('Place your QR\nimage here', textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text('रकम: ${widget.priceLabel}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                const SizedBox(height: 6),
                Text('माथिको QR स्क्यान गरेर भुक्तानी गर्नुहोस्।\nScan above QR to pay via ${method['label']}.', 
                    textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600], height: 1.5)),
              ]),
            ),
            const SizedBox(height: 20),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text('कसरी भुक्तानी गर्ने?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                ]),
                const SizedBox(height: 10),
                _instRow('1.', '${method['label']} app खोल्नुहोस् र Scan QR मा जानुहोस्।'),
                _instRow('2.', 'माथिको QR स्क्यान गर्नुहोस्।'),
                _instRow('3.', 'रकम: ${widget.priceLabel} भर्नुहोस् र Confirm गर्नुहोस्।'),
                _instRow('4.', 'Transaction ID सम्झिनुहोस् र तलको फर्ममा भर्नुहोस्।'),
              ]),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QrTransactionProofScreen(
                propertyId: widget.propertyId,
                boostTier: widget.boostTier,
                amount: widget.amount,
                priceLabel: widget.priceLabel,
                label: widget.label,
                paymentMethod: _methods[_selectedMethod]['label'] as String,
              )),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('भुक्तानी गरेँ — Submit Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _instRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.amber[800], fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87, height: 1.4))),
        ],
      ),
    );
  }
}

// ─────────────────────── STEP 3: SUBMIT PROOF ───────────────────────
class QrTransactionProofScreen extends StatefulWidget {
  final String propertyId;
  final String boostTier;
  final int amount;
  final String priceLabel;
  final String label;
  final String paymentMethod;

  const QrTransactionProofScreen({
    super.key,
    required this.propertyId,
    required this.boostTier,
    required this.amount,
    required this.priceLabel,
    required this.label,
    required this.paymentMethod,
  });

  @override
  State<QrTransactionProofScreen> createState() => _QrTransactionProofScreenState();
}

class _QrTransactionProofScreenState extends State<QrTransactionProofScreen> {
  final _txnIdCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _receiptImage;
  bool _isSubmitting = false;
  bool _submitted = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _receiptImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      await Supabase.instance.client.from('payments').insert({
        'owner_id': uid,
        'property_id': widget.propertyId,
        'amount': widget.amount,
        'boost_tier_purchased': widget.boostTier,
        'payment_method': widget.paymentMethod,
        'transaction_id': _txnIdCtrl.text.trim(),
        'status': 'pending', // Admin will verify and change to 'completed'
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) setState(() { _isSubmitting = false; _submitted = true; });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Payment Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Security note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('तपाईंको भुक्तानी सुरक्षित छ। Admin ले verify गरेपछि boost activate हुनेछ।',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.green[800]))),
                ]),
              ),
              const SizedBox(height: 24),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFFF8F9FB), border: Border.all(color: Colors.grey.shade200)),
                child: Column(children: [
                  _summRow('Package', widget.label),
                  _summRow('Amount', widget.priceLabel),
                  _summRow('Method', widget.paymentMethod),
                ]),
              ),
              const SizedBox(height: 28),

              Text('Transaction ID *', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('eSewa / Khalti / IME Receipt नम्बर भर्नुहोस्', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 10),
              TextFormField(
                controller: _txnIdCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. ESWA20240001234',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppTheme.brandColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.brandColor, width: 2)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
                  filled: true, fillColor: Colors.white,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Transaction ID अनिवार्य छ';
                  if (v.trim().length < 8) return 'कम्तिमा 8 अक्षर हुनुपर्छ';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              Text('Receipt Photo (वैकल्पिक)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('Screenshot वा receipt को फोटो upload गर्नुस् — छिटो verify हुन्छ।', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _receiptImage != null ? AppTheme.brandColor : Colors.grey.shade300, width: _receiptImage != null ? 2 : 1, style: BorderStyle.solid),
                    color: _receiptImage != null ? AppTheme.brandColor.withOpacity(0.03) : Colors.grey[50],
                  ),
                  child: _receiptImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_receiptImage!, fit: BoxFit.cover))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.upload_file_outlined, size: 36, color: AppTheme.brandColor),
                          const SizedBox(height: 8),
                          Text('Receipt Upload गर्नुहोस्', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppTheme.brandColor)),
                          Text('Gallery बाट छान्नुहोस्', style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
                        ]),
                ),
              ),
              if (_receiptImage != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _receiptImage = null),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: Text('हटाउनुहोस्', style: GoogleFonts.outfit(color: Colors.red, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              minimumSize: const Size(double.infinity, 56),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Submit गर्नुहोस्', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _summRow(String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
          Text(val, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 56),
                ),
                const SizedBox(height: 28),
                Text('Request Submitted! 🎉', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 12),
                Text(
                  'तपाईंको भुक्तानी Request पाइयो।\nAdmin ले 24 घण्टाभित्र verify गरेपछि तपाईंको Boost activate हुनेछ।',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[600], height: 1.6),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Notification पाउनुहुनेछ — तैयार भएपछि थाहा पाउनुहुन्छ।', style: GoogleFonts.outfit(fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandColor,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Home मा जानुहोस्', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
