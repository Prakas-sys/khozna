import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/kyc_ai_analyser.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/models/admin_model.dart';
import 'package:khozna/features/profile/repositories/user_repository.dart';
import 'package:khozna/features/admin/repositories/admin_repository.dart';
import 'package:khozna/features/admin/widgets/admin_widgets.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<UserModel>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _usersFuture = UserRepository.getAllUsers();
    });
  }

  void _search(String query) {
    setState(() {
      _usersFuture = query.isEmpty ? UserRepository.getAllUsers() : UserRepository.searchUsers(query);
    });
  }

  Future<void> _runBulkAutoPilot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Run KYC Auto-Pilot?'),
        content: const Text('The AI will now automatically analyze and action ALL currently pending KYC submissions in the backlog.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandColor), child: const Text('Start Auto-Pilot')),
        ],
      ),
    );

    if (confirmed != true) return;
    _showProcessingDialog();

    try {
      final pendingKycs = await AdminRepository.getPendingKycs();
      int processed = 0;

      for (var kyc in pendingKycs) {
        final result = await KycAiAnalyser.analyseKycDocuments(
          frontImageUrl: kyc.frontImageUrl,
          backImageUrl: kyc.backImageUrl,
          selfieImageUrl: kyc.selfieImageUrl,
          fullName: kyc.fullName,
          citizenshipNumber: kyc.citizenshipNumber,
          latitude: kyc.latitude,
          longitude: kyc.longitude,
        );

        final verdict = result['verdict'];
        if (verdict == 'PASS') {
          await AdminRepository.updateKycStatus(kyc.id, kyc.userId, 'verified');
          processed++;
        } else if (verdict == 'FAIL') {
          final reason = List<String>.from(result['red_flags'] ?? []).join('\n');
          await AdminRepository.updateKycStatus(kyc.id, kyc.userId, 'rejected', reason: reason);
          processed++;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auto-Pilot finished! $processed KYCs actioned.'), backgroundColor: Colors.green));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auto-Pilot error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text('AI Auto-Pilot is processing...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openUserDetail(UserModel user) async {
    final kycData = await AdminRepository.getKycByUserId(user.id);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _KycDetailSheet(user: user, kycData: kycData, onRefresh: _refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('User Management', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.brandColor), onPressed: _runBulkAutoPilot),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data ?? [];
          if (users.isEmpty) return Center(child: Text('No users found.', style: GoogleFonts.inter(color: Colors.grey)));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              return GestureDetector(
                onTap: () => _openUserDetail(user),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 24, backgroundColor: AppTheme.brandColor.withOpacity(0.1), backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) ? NetworkImage(user.avatarUrl!) : null, child: (user.avatarUrl == null || user.avatarUrl!.isEmpty) ? Text(user.fullName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandColor)) : null),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 2), Text(user.phoneNumber ?? 'No Phone', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]))])),
                      AdminStatusBadge(status: user.kycStatus),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
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
}

class _KycDetailSheet extends StatefulWidget {
  final UserModel user;
  final KycVerificationModel? kycData;
  final VoidCallback onRefresh;

  const _KycDetailSheet({required this.user, required this.kycData, required this.onRefresh});

  @override
  State<_KycDetailSheet> createState() => _KycDetailSheetState();
}

class _KycDetailSheetState extends State<_KycDetailSheet> {
  Map<String, dynamic>? _aiResult;
  bool _isAnalysing = false;

  Future<void> _runAiAnalysis() async {
    final kyc = widget.kycData;
    if (kyc == null) return;

    setState(() => _isAnalysing = true);
    final result = await KycAiAnalyser.analyseKycDocuments(
      frontImageUrl: kyc.frontImageUrl,
      backImageUrl: kyc.backImageUrl,
      selfieImageUrl: kyc.selfieImageUrl,
      fullName: kyc.fullName,
      citizenshipNumber: kyc.citizenshipNumber,
      latitude: kyc.latitude,
      longitude: kyc.longitude,
    );

    if (!mounted) return;
    setState(() { _aiResult = result; _isAnalysing = false; });

    final verdict = result['verdict'];
    if (verdict == 'PASS' || verdict == 'FAIL') {
      if (verdict == 'PASS') {
        await AdminRepository.updateKycStatus(kyc.id, widget.user.id, 'verified');
      } else {
        final reason = List<String>.from(result['red_flags'] ?? []).join('\n');
        await AdminRepository.updateKycStatus(kyc.id, widget.user.id, 'rejected', reason: reason);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Auto-Pilot actioned this KYC as $verdict!'), backgroundColor: verdict == 'PASS' ? Colors.green : Colors.red));
        Navigator.pop(context);
        widget.onRefresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyc = widget.kycData;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.user.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20)), Text(widget.user.phoneNumber ?? '', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]))])), AdminStatusBadge(status: widget.user.kycStatus, large: true)])),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  if (kyc == null) ...[
                    const SizedBox(height: 40),
                    Icon(Icons.assignment_late_outlined, size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No KYC documents submitted yet.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey[500])),
                  ] else ...[
                    AdminInfoRow(label: 'Citizenship No.', value: kyc.citizenshipNumber),
                    AdminInfoRow(label: 'Phone', value: kyc.phoneNumber),
                    const SizedBox(height: 20),
                    Text('Documents', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(children: [AdminDocImage(url: kyc.frontImageUrl, label: 'Front ID'), const SizedBox(width: 8), AdminDocImage(url: kyc.backImageUrl, label: 'Back ID'), const SizedBox(width: 8), AdminDocImage(url: kyc.selfieImageUrl, label: 'Selfie')]),
                    const SizedBox(height: 24),
                    if (_aiResult == null && !_isAnalysing) SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(onPressed: _runAiAnalysis, icon: const Text('🤖', style: TextStyle(fontSize: 20)), label: Text('Analyse with AI', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                    if (_isAnalysing) const Center(child: CircularProgressIndicator()),
                    if (_aiResult != null) AiResultCard(result: _aiResult!),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
