import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:intl/intl.dart';

class AdminPayoutScreen extends StatefulWidget {
  const AdminPayoutScreen({super.key});

  @override
  State<AdminPayoutScreen> createState() => _AdminPayoutScreenState();
}

class _AdminPayoutScreenState extends State<AdminPayoutScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _escrowPayouts = [];
  double _totalEscrowAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchEscrowPayouts();
  }

  Future<void> _fetchEscrowPayouts() async {
    setState(() => _isLoading = true);
    try {
      // Query bookings with paid status
      final response = await Supabase.instance.client
          .from('bookings')
          .select('*, properties:property_id(title, address, owner_id), guest:guest_id(full_name, phone_number)')
          .or('status.eq.paid,status.eq.confirmed,status.eq.payout_pending,status.eq.payout_disbursed')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(response as List);

      // Fetch owner profile for each booking
      final ownerIds = items
          .map((item) => item['properties']?['owner_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> ownerProfiles = {};
      if (ownerIds.isNotEmpty) {
        final profilesResponse = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name, phone_number, esewa_number, khalti_number, account_holder_name')
            .inFilter('id', ownerIds);

        for (final p in profilesResponse as List) {
          ownerProfiles[p['id'].toString()] = Map<String, dynamic>.from(p as Map);
        }
      }

      double total = 0;
      for (var item in items) {
        final ownerId = item['properties']?['owner_id']?.toString() ?? '';
        item['owner'] = ownerProfiles[ownerId] ?? {};
        final double price = (item['total_price'] as num?)?.toDouble() ?? 0;
        if (item['status'] == 'paid' || item['status'] == 'confirmed') {
          total += price;
        }
      }

      if (mounted) {
        setState(() {
          _escrowPayouts = items;
          _totalEscrowAmount = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin payouts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsDisbursed(Map<String, dynamic> payout) async {
    final String bookingId = payout['id'].toString();
    final String ownerId = payout['properties']?['owner_id']?.toString() ?? '';
    final double amount = (payout['total_price'] as num?)?.toDouble() ?? 0;
    final String propTitle = payout['properties']?['title']?.toString() ?? 'your property';

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'payout_disbursed'})
          .eq('id', bookingId);

      // Insert notification for owner informing payout disbursal
      if (ownerId.isNotEmpty) {
        await Supabase.instance.client.from('notifications').insert({
          'user_id': ownerId,
          'title': 'Payout Disbursed',
          'message': 'Khozna has transferred Rs. ${amount.toStringAsFixed(0)} for "$propTitle" to your registered payout account!',
          'type': 'payout_received',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payout marked as Disbursed! Owner notified.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchEscrowPayouts();
      }
    } catch (e) {
      debugPrint('Disbursal update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update payout status: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label "$text" copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Admin Escrow & Owner Payouts',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
          : RefreshIndicator(
              onRefresh: _fetchEscrowPayouts,
              color: AppTheme.brandColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Escrow Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'KHOZNA ESCROW VAULT',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Rs. ${NumberFormat('#,##,###').format(_totalEscrowAmount)}',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Guest Funds Pending Disbursal to Owners',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),
                    Text(
                      'BOOKINGS & OWNER PAYOUT ACCOUNTS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_escrowPayouts.isEmpty)
                      Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: Text(
                          'No guest payments currently in escrow.',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _escrowPayouts.length,
                        itemBuilder: (context, index) {
                          final item = _escrowPayouts[index];
                          return _buildPayoutCard(item);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPayoutCard(Map<String, dynamic> item) {
    final String bookingId = item['id'].toString();
    final String refCode = bookingId.length > 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId.toUpperCase();
    final String status = item['status']?.toString() ?? 'paid';
    final double amount = (item['total_price'] as num?)?.toDouble() ?? 0;
    final propTitle = item['properties']?['title']?.toString() ?? 'Property';

    final guest = item['guest'] as Map<String, dynamic>?;
    final guestName = guest?['full_name']?.toString() ?? 'Guest Payer';
    final guestPhone = guest?['phone_number']?.toString() ?? 'N/A';

    final owner = item['owner'] as Map<String, dynamic>?;
    final ownerName = owner?['full_name']?.toString() ?? 'Property Owner';
    final ownerPhone = owner?['phone_number']?.toString() ?? 'N/A';

    final String esewa = owner?['esewa_number']?.toString().trim() ?? '';
    final String khalti = owner?['khalti_number']?.toString().trim() ?? '';
    final String bankAcc = owner?['account_holder_name']?.toString().trim() ?? '';

    final bool isDisbursed = status == 'payout_disbursed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        propTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ref: $refCode • Guest: $guestName ($guestPhone)',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDisbursed ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDisbursed ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Text(
                    isDisbursed ? 'DISBURSED' : 'HELD IN ESCROW',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isDisbursed ? const Color(0xFF047857) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),

            Text(
              'PAYOUT AMOUNT & OWNER DETAILS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  'Rs. ${amount.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Text(
                  'Owner: $ownerName ($ownerPhone)',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Payout target details box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _payoutAccountRow('eSewa ID', esewa, () => _copyToClipboard(esewa, 'eSewa Number')),
                  const SizedBox(height: 6),
                  _payoutAccountRow('Khalti ID', khalti, () => _copyToClipboard(khalti, 'Khalti Number')),
                  const SizedBox(height: 6),
                  _payoutAccountRow('Bank Account', bankAcc, () => _copyToClipboard(bankAcc, 'Bank Account Details')),
                ],
              ),
            ),

            if (!isDisbursed) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmDisbursalDialog(item),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(
                    'Mark Payout Disbursed to Owner',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _payoutAccountRow(String label, String value, VoidCallback onCopy) {
    final bool hasValue = value.isNotEmpty;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            hasValue ? value : 'Not provided',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
              color: hasValue ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
          ),
        ),
        if (hasValue)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.brandColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onCopy,
            tooltip: 'Copy $label',
          ),
      ],
    );
  }

  void _confirmDisbursalDialog(Map<String, dynamic> item) {
    final double amount = (item['total_price'] as num?)?.toDouble() ?? 0;
    final owner = item['owner'] as Map<String, dynamic>?;
    final ownerName = owner?['full_name']?.toString() ?? 'Owner';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Payout Disbursal',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          'Are you sure you have transferred Rs. ${amount.toStringAsFixed(0)} to $ownerName\'s eSewa or Bank Account?\n\nThis will mark the escrow payout as completed and notify the owner.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _markAsDisbursed(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm Disbursed', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
