import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/admin/repositories/admin_repository.dart';
import 'package:khozna/core/models/admin_model.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  AdminStatsModel? _stats;
  List<Map<String, dynamic>> _pendingPayments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await AdminRepository.getStats();
      final payments = await AdminRepository.getPendingPayments();
      setState(() {
        _stats = stats;
        _pendingPayments = payments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'KHOZNA ADMIN',
            style: GoogleFonts.zenAntiqueSoft(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            indicatorColor: AppTheme.brandColor,
            tabs: const [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'PAYMENTS'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildPaymentsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatGrid(),
            const SizedBox(height: 24),
            _buildQuickActionCard(
              title: 'Pending KYC',
              count: _stats?.pendingKyc ?? 0,
              icon: Icons.assignment_ind_outlined,
              color: Colors.blue,
            ),
            _buildQuickActionCard(
              title: 'User Reports',
              count: _stats?.pendingReports ?? 0,
              icon: Icons.report_problem_outlined,
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Users', _stats?.totalUsers.toString() ?? '0', Icons.people_outline, Colors.blue),
        _buildStatCard('Properties', _stats?.totalProperties.toString() ?? '0', Icons.home_outlined, Colors.purple),
        _buildStatCard('Active Bookings', _stats?.activeBookings.toString() ?? '0', Icons.bookmark_border, Colors.orange),
        _buildStatCard('Revenue (EST)', 'Rs. 45K', Icons.account_balance_wallet_outlined, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$count items pending review',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    if (_pendingPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No pending payments to verify',
              style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _pendingPayments.length,
        itemBuilder: (context, index) {
          final payment = _pendingPayments[index];
          final booking = payment['bookings'];
          return _buildPaymentVerificationCard(payment, booking);
        },
      ),
    );
  }

  Widget _buildPaymentVerificationCard(Map<String, dynamic> payment, dynamic booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.payment, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment['guest']?['full_name'] ?? 'Unknown Payer',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Booking: ${booking?['properties']?['title'] ?? 'N/A'}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${payment['amount']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, hh:mm a').format(DateTime.parse(payment['created_at'])),
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (payment['proof_image_url'] != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _viewProof(payment['proof_image_url']),
              child: Container(
                height: 140,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(payment['proof_image_url']),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black26,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.zoom_in, color: Colors.white, size: 32),
                        Text(
                          'View Guest Proof',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          // Owner Payout Details Section
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'OWNER PAYOUT DETAILS',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPayoutRow('Owner', booking?['owner']?['full_name'] ?? 'Unknown'),
                _buildPayoutRow('eSewa', booking?['owner']?['esewa_number'] ?? 'Not added'),
                _buildPayoutRow('Khalti', booking?['owner']?['khalti_number'] ?? 'Not added'),
                if (booking?['owner']?['qr_code_url'] != null)
                  TextButton.icon(
                    onPressed: () => _viewProof(booking['owner']['qr_code_url']),
                    icon: const Icon(Icons.qr_code, size: 14),
                    label: const Text('View Owner QR', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleVerification(payment['id'], booking['id'], false),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleVerification(payment['id'], booking['id'], true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Verify \u0026 Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewProof(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(child: Image.network(url)),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVerification(String paymentId, String bookingId, bool approved) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      await AdminRepository.verifyPayment(paymentId, bookingId, approved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? 'Payment verified!' : 'Payment rejected.')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPayoutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700])),
          Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
