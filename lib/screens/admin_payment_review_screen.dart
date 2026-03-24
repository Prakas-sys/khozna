// ============================================================
// ADMIN PAYMENT REVIEW SCREEN — KHOZNA
// Accessible from Owner Dashboard
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class AdminPaymentReviewScreen extends StatefulWidget {
  const AdminPaymentReviewScreen({super.key});

  @override
  State<AdminPaymentReviewScreen> createState() => _AdminPaymentReviewScreenState();
}

class _AdminPaymentReviewScreenState extends State<AdminPaymentReviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _pending;
  late Future<List<Map<String, dynamic>>> _completed;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
  }

  void _refresh() {
    setState(() {
      _pending = Supabase.instance.client
          .from('payments')
          .select('*, profiles(full_name, phone_number), properties(title, area_name)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      _completed = Supabase.instance.client
          .from('payments')
          .select('*, profiles(full_name, phone_number), properties(title, area_name)')
          .eq('status', 'completed')
          .order('created_at', ascending: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Payment Verifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppTheme.brandColor), onPressed: _refresh),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.brandColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.brandColor,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: '⏳ Pending'),
            Tab(text: '✅ Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_pending, showActions: true),
          _buildList(_completed, showActions: false),
        ],
      ),
    );
  }

  Widget _buildList(Future<List<Map<String, dynamic>>> future, {required bool showActions}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(showActions ? 'No pending verifications' : 'No completed verifications',
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 15)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => _buildPaymentCard(list[i], showActions: showActions),
        );
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, {required bool showActions}) {
    final profile = payment['profiles'] as Map<String, dynamic>?;
    final property = payment['properties'] as Map<String, dynamic>?;
    final statusColor = payment['status'] == 'completed' ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(profile?['full_name'] ?? 'Unknown User', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(profile?['phone_number'] ?? '', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(payment['status'].toString().toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const Divider(height: 24),

            // Details
            _detailRow('Property', property?['title'] ?? 'N/A'),
            _detailRow('Area', property?['area_name'] ?? 'N/A'),
            _detailRow('Package', _tierLabel(payment['boost_tier_purchased'])),
            _detailRow('Amount', 'Rs. ${payment['amount']}'),
            _detailRow('Method', payment['payment_method'] ?? 'N/A'),
            _detailRow('Transaction ID', payment['transaction_id'] ?? '—'),
            _detailRow('Submitted', _formatDate(payment['created_at'])),

            // Actions
            if (showActions) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approvePayment(payment),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: Text('Verify & Activate', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPayment(payment),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: Text('Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13))),
          Expanded(child: Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Future<void> _approvePayment(Map<String, dynamic> payment) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      // 1. Mark payment as completed
      await Supabase.instance.client.from('payments').update({'status': 'completed'}).eq('id', payment['id']);

      // 2. Activate boost on property
      final tier = payment['boost_tier_purchased'] as String;
      final days = tier == 'boost_3d' ? 3 : (tier == 'boost_7d' ? 7 : 30);
      final expiresAt = DateTime.now().add(Duration(days: days)).toIso8601String();

      await Supabase.instance.client.from('properties').update({
        'is_boosted': true,
        'boost_tier': tier,
        'boost_expires_at': expiresAt,
      }).eq('id', payment['property_id']);

      // 3. Send notification to owner
      await Supabase.instance.client.from('notifications').insert({
        'user_id': payment['owner_id'],
        'title': '🚀 Boost Activated!',
        'message': 'तपाईंको ${_tierLabel(tier)} Boost activate भयो। ${days} दिनसम्म active रहनेछ।',
        'type': 'general',
      });

      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Payment verified & Boost activated!')));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectPayment(Map<String, dynamic> payment) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await Supabase.instance.client.from('payments').update({'status': 'failed'}).eq('id', payment['id']);

      await Supabase.instance.client.from('notifications').insert({
        'user_id': payment['owner_id'],
        'title': '❌ Payment Rejected',
        'message': 'तपाईंको boost payment verify गर्न सकिएन। Transaction ID फेरि check गर्नुहोस् वा Khozna सँग सम्पर्क गर्नुहोस्।',
        'type': 'general',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment rejected & owner notified.')));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _tierLabel(String? tier) {
    switch (tier) {
      case 'boost_3d': return 'Boost 3 Days (Rs. 99)';
      case 'boost_7d': return 'Boost 7 Days (Rs. 199)';
      case 'top_highlight': return 'Top + Highlight (Rs. 399)';
      default: return tier ?? 'N/A';
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }
}
