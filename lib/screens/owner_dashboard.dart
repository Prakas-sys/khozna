import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/supabase_service.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
    // Start listening for real-time owner alerts (KYCs, properties, etc.)
    SupabaseService.listenToOwnerAlerts(() {
      if (mounted) _refreshStats();
    });
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = SupabaseService.getOwnerStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Owner Command Center',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.brandColor),
            onPressed: _refreshStats,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {
            'totalUsers': 0,
            'totalProperties': 0,
            'pendingKyc': 0,
            'activeBookings': 0,
          };

          return RefreshIndicator(
            onRefresh: () async => _refreshStats(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),

                  Text(
                    'Business Overview',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: LinearProgressIndicator())
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard('Total Users', stats['totalUsers'].toString(), Icons.people_outline, Colors.blue),
                        _buildStatCard('Pending KYC', stats['pendingKyc'].toString(), Icons.verified_user_outlined, Colors.orange),
                        _buildStatCard('Properties', stats['totalProperties'].toString(), Icons.home_work_outlined, Colors.purple),
                        _buildStatCard('Bookings', stats['activeBookings'].toString(), Icons.calendar_today_outlined, Colors.green),
                      ],
                    ),
                  
                  const SizedBox(height: 24),

                  Text(
                    'Management Actions',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionItem(
                    'KYC Approvals',
                    'Review pending identity verifications',
                    Icons.assignment_ind_outlined,
                    Colors.orange,
                    badge: stats['pendingKyc']! > 0 ? stats['pendingKyc'].toString() : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KycReviewScreen()),
                    ).then((_) => _refreshStats()),
                  ),
                  _buildActionItem(
                    'Property Moderation',
                    'Verify or remove listings',
                    Icons.gavel_outlined,
                    Colors.redAccent,
                    onTap: () {
                      // We'll add this next
                    },
                  ),
                  _buildActionItem(
                    'User Management',
                    'Search or block users',
                    Icons.manage_accounts_outlined,
                    Colors.blue,
                  ),
                  const SizedBox(height: 40),
                  
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.exit_to_app, color: Colors.grey),
                      label: Text(
                        'Exit Owner Mode',
                        style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brandColor, Color(0xFF0079B1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hello, Boss! 👋',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Live Data Dashboard',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon, Color color, {String? badge, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: badge != null 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}

class KycReviewScreen extends StatefulWidget {
  const KycReviewScreen({super.key});

  @override
  State<KycReviewScreen> createState() => _KycReviewScreenState();
}

class _KycReviewScreenState extends State<KycReviewScreen> {
  late Future<List<Map<String, dynamic>>> _kycFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _kycFuture = SupabaseService.getPendingKycs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KYC Review', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _kycFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text('No pending KYCs!', style: GoogleFonts.outfit(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final kyc = list[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(kyc['full_name'], style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(kyc['phone_number'], style: GoogleFonts.outfit(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Citizenship: ${kyc['citizenship_number']}', style: GoogleFonts.outfit()),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildMiniThumb('Front', kyc['document_front_url']),
                          const SizedBox(width: 8),
                          _buildMiniThumb('Back', kyc['document_back_url']),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(colors: [Colors.green, Color(0xFF27AE60)]),
                                boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))],
                              ),
                              child: ElevatedButton(
                                onPressed: () => _processKyc(kyc['id'], kyc['user_id'], 'verified'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: EdgeInsets.zero),
                                child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () => _showRejectDialog(kyc['id'], kyc['user_id']),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRejectDialog(String kycId, String userId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject KYC'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason (e.g. Blurry photo)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processKyc(kycId, userId, 'rejected', reason: reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniThumb(String label, String? url) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
          ),
          child: url == null ? const Icon(Icons.image_not_supported) : null,
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  void _processKyc(String kycId, String userId, String status, {String? reason}) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await SupabaseService.updateKycStatus(kycId, userId, status, reason: reason);
      Navigator.pop(context); // close loading
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KYC $status!')));
    } catch (e) {
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
