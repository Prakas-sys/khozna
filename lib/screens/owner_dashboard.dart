import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/supabase_service.dart';
import 'user_management_screen.dart';
import 'property_moderation_screen.dart';
import '../utils/security_utils.dart';

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
          style: GoogleFonts.inter(
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
          final stats =
              snapshot.data ??
              {
                'totalUsers': 0,
                'totalProperties': 0,
                'pendingKyc': 0,
                'pendingReports': 0,
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
                    style: GoogleFonts.inter(
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
                        _buildStatCard(
                          'Total Users',
                          stats['totalUsers'].toString(),
                          Icons.people_outline,
                          Colors.blue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserManagementScreen(),
                            ),
                          ),
                        ),
                        _buildStatCard(
                          'Pending KYC',
                          stats['pendingKyc'].toString(),
                          Icons.verified_user_outlined,
                          Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KycReviewScreen(),
                            ),
                          ).then((_) => _refreshStats()),
                        ),
                        _buildStatCard(
                          'Properties',
                          stats['totalProperties'].toString(),
                          Icons.home_work_outlined,
                          Colors.purple,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PropertyModerationScreen(),
                            ),
                          ).then((_) => _refreshStats()),
                        ),
                        _buildStatCard(
                          'Active Bookings',
                          stats['activeBookings'].toString(),
                          Icons.calendar_today_outlined,
                          Colors.green,
                          onTap: () {
                            // Navigation to BookingManagementScreen (to be added)
                          },
                        ),
                        _buildStatCard(
                          'User Reports',
                          stats['pendingReports'].toString(),
                          Icons.report_problem_outlined,
                          Colors.red,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserReportsScreen(),
                            ),
                          ).then((_) => _refreshStats()),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  Text(
                    'Management Actions',
                    style: GoogleFonts.inter(
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
                    badge: stats['pendingKyc']! > 0
                        ? stats['pendingKyc'].toString()
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KycReviewScreen(),
                      ),
                    ).then((_) => _refreshStats()),
                  ),
                  _buildActionItem(
                    'Property Moderation',
                    'Verify or remove listings',
                    Icons.gavel_outlined,
                    Colors.redAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PropertyModerationScreen(),
                      ),
                    ).then((_) => _refreshStats()),
                  ),
                  _buildActionItem(
                    'User Management',
                    'Search or block users',
                    Icons.manage_accounts_outlined,
                    Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    ),
                  ),
                  _buildActionItem(
                    'User Reports',
                    'Manage reported users and scams',
                    Icons.report_problem_outlined,
                    Colors.red,
                    badge: stats['pendingReports']! > 0
                        ? stats['pendingReports'].toString()
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserReportsScreen(),
                      ),
                    ).then((_) => _refreshStats()),
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.exit_to_app, color: Colors.grey),
                      label: Text(
                        'Exit Owner Mode',
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Live Data Dashboard',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                if (onTap != null)
                  const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    String? badge,
    VoidCallback? onTap,
  }) {
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
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
  final Map<String, bool> _processingKycs =
      {}; // Track which KYC is being processed
  final Map<String, String?> _successStatus =
      {}; // Track 'verified' or 'rejected' status

  @override
  void initState() {
    super.initState();
    // Use a small delay to ensure the window flag is properly cleared on Android
    Future.delayed(const Duration(milliseconds: 500), () {
      SecurityUtils.setSecure(false);
    });
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
        title: Text(
          'KYC Review',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
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
              child: Text(
                'No pending KYCs!',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final kyc = list[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kyc['full_name'],
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                kyc['phone_number'],
                                style: GoogleFonts.inter(color: Colors.grey),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _confirmPermanentDelete(kyc['id']),
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                              size: 22,
                            ),
                            tooltip: 'Permanently Delete Record',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Citizenship: ${kyc['citizenship_number']}',
                        style: GoogleFonts.inter(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildMiniThumb('Front', kyc['front_image_url']),
                          const SizedBox(width: 8),
                          _buildMiniThumb('Back', kyc['back_image_url']),
                          const SizedBox(width: 8),
                          _buildMiniThumb('Selfie', kyc['selfie_image_url']),
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
                                gradient: const LinearGradient(
                                  colors: [Colors.green, Color(0xFF27AE60)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    _processingKycs[kyc['id']] == true ||
                                        _successStatus[kyc['id']] != null
                                    ? null
                                    : () => _processKyc(
                                        kyc['id'],
                                        kyc['user_id'],
                                        'verified',
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                ),
                                child: _processingKycs[kyc['id']] == true
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : _successStatus[kyc['id']] == 'verified'
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Approved ✅',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Approve',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed:
                                    _processingKycs[kyc['id']] == true ||
                                        _successStatus[kyc['id']] != null
                                    ? null
                                    : () => _showRejectDialog(
                                        kyc['id'],
                                        kyc['user_id'],
                                      ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      _successStatus[kyc['id']] == 'rejected'
                                      ? Colors.red
                                      : Colors.red,
                                  backgroundColor:
                                      _successStatus[kyc['id']] == 'rejected'
                                      ? Colors.red.withOpacity(0.1)
                                      : null,
                                  side: BorderSide(
                                    color:
                                        _successStatus[kyc['id']] == 'rejected'
                                        ? Colors.red
                                        : Colors.red,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _successStatus[kyc['id']] == 'rejected'
                                    ? const Text(
                                        'Rejected ❌',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : const Text(
                                        'Reject',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processKyc(
                kycId,
                userId,
                'rejected',
                reason: reasonController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Reject Now',
              style: TextStyle(color: Colors.white),
            ),
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
            image: url != null
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
          ),
          child: url == null ? const Icon(Icons.image_not_supported) : null,
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  void _processKyc(
    String kycId,
    String userId,
    String status, {
    String? reason,
  }) async {
    if (_processingKycs[kycId] == true) return;

    try {
      setState(() => _processingKycs[kycId] = true);
      await SupabaseService.updateKycStatus(
        kycId,
        userId,
        status,
        reason: reason,
      );

      if (mounted) {
        setState(() {
          _processingKycs.remove(kycId);
          _successStatus[kycId] = status;
        });

        // Add a small delay so the user can see the "Approved" / "Rejected" button state
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          _refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'KYC ${status == 'verified' ? 'Approved ✅' : 'Rejected ❌'}!',
              ),
              backgroundColor: status == 'verified' ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _processingKycs[kycId] = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _confirmPermanentDelete(String kycId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent Delete?'),
        content: const Text(
          'This will totally remove this KYC record from the database. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.deleteKycPermanently(kycId);
        _refresh();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('KYC Record Deleted.')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }
}

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  State<UserReportsScreen> createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _reportsFuture = SupabaseService.getUserReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Reports',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final reports = snapshot.data ?? [];
          if (reports.isEmpty)
            return const Center(child: Text('No reports found.'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final report = reports[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage:
                              report['reported']['avatar_url'] != null
                              ? NetworkImage(report['reported']['avatar_url'])
                              : null,
                          child: report['reported']['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report['reported']['full_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Reported by: ${report['reporter']['full_name'] ?? 'System'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _deleteReport(report['id']),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report['reason'] ?? 'No reason provided',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteReport(String id) async {
    try {
      await SupabaseService.deleteReport(id);
      _refresh();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report dismissed.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
