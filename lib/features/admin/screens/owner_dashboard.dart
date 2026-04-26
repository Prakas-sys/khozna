import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/admin_model.dart';
import 'package:khozna/features/admin/repositories/admin_repository.dart';
import 'package:khozna/features/admin/screens/user_management_screen.dart';
import 'package:khozna/features/admin/screens/property_moderation_screen.dart';
import 'package:khozna/features/admin/screens/kyc_review_screen.dart';
import 'package:khozna/features/admin/screens/user_reports_screen.dart';
import 'package:khozna/features/admin/widgets/owner_widgets.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  late Future<AdminStatsModel> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
    AdminRepository.listenToAdminAlerts(() {
      if (mounted) _refreshStats();
    });
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = AdminRepository.getAdminStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Owner Command Center', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppTheme.brandColor), onPressed: _refreshStats),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<AdminStatsModel>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final stats = snapshot.data ?? AdminStatsModel(totalUsers: 0, totalProperties: 0, pendingKyc: 0, pendingReports: 0, activeBookings: 0);

          return RefreshIndicator(
            onRefresh: () async => _refreshStats(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OwnerWelcomeCard(),
                  const SizedBox(height: 24),
                  Text('Business Overview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                        OwnerStatCard(title: 'Total Users', value: stats.totalUsers.toString(), icon: Icons.people_outline, color: Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()))),
                        OwnerStatCard(title: 'Pending KYC', value: stats.pendingKyc.toString(), icon: Icons.verified_user_outlined, color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycReviewScreen())).then((_) => _refreshStats())),
                        OwnerStatCard(title: 'Properties', value: stats.totalProperties.toString(), icon: Icons.home_work_outlined, color: Colors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyModerationScreen())).then((_) => _refreshStats())),
                        OwnerStatCard(title: 'Active Bookings', value: stats.activeBookings.toString(), icon: Icons.calendar_today_outlined, color: Colors.green),
                        OwnerStatCard(title: 'User Reports', value: stats.pendingReports.toString(), icon: Icons.report_problem_outlined, color: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserReportsScreen())).then((_) => _refreshStats())),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text('Management Actions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  OwnerActionItem(title: 'KYC Approvals', subtitle: 'Review pending identity verifications', icon: Icons.assignment_ind_outlined, color: Colors.orange, badge: stats.pendingKyc > 0 ? stats.pendingKyc.toString() : null, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycReviewScreen())).then((_) => _refreshStats())),
                  OwnerActionItem(title: 'Property Moderation', subtitle: 'Verify or remove listings', icon: Icons.gavel_outlined, color: Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyModerationScreen())).then((_) => _refreshStats())),
                  OwnerActionItem(title: 'User Management', subtitle: 'Search or block users', icon: Icons.manage_accounts_outlined, color: Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()))),
                  OwnerActionItem(title: 'User Reports', subtitle: 'Manage reported users and scams', icon: Icons.report_problem_outlined, color: Colors.red, badge: stats.pendingReports > 0 ? stats.pendingReports.toString() : null, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserReportsScreen())).then((_) => _refreshStats())),
                  const SizedBox(height: 40),
                  Center(child: TextButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.exit_to_app, color: Colors.grey), label: Text('Exit Owner Mode', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w600)))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
