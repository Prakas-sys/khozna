import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/supabase_service.dart';
import '../utils/kyc_ai_analyser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _usersFuture = SupabaseService.getAllUsers();
    });
  }

  void _search(String query) {
    setState(() {
      _usersFuture = query.isEmpty
          ? SupabaseService.getAllUsers()
          : SupabaseService.searchUsers(query);
    });
  }

  Future<Map<String, dynamic>?> _fetchKycData(String userId) async {
    try {
      final result = await Supabase.instance.client
          .from('kyc_verifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return result;
    } catch (_) {
      return null;
    }
  }

  void _openUserDetail(Map<String, dynamic> user) async {
    final kycData = await _fetchKycData(user['id']);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _KycDetailSheet(
        user: user,
        kycData: kycData,
        onRefresh: _refresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'User Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20),
        ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Text('No users found.', style: GoogleFonts.inter(color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              final String fullName = user['full_name']?.toString() ?? 'Unknown User';
              final String kycStatus = user['kyc_status']?.toString() ?? 'none';
              final String? avatarUrl = user['avatar_url']?.toString();

              return GestureDetector(
                onTap: () => _openUserDetail(user),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.brandColor.withOpacity(0.1),
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brandColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fullName,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(user['phone_number'] ?? 'No Phone',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      _StatusBadge(status: kycStatus),
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'verified': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _confirmPermanentDelete(String userId, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text(
          'This will permanently remove this user and all their data. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.deleteUserPermanently(userId);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KYC DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _KycDetailSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? kycData;
  final VoidCallback onRefresh;

  const _KycDetailSheet({
    required this.user,
    required this.kycData,
    required this.onRefresh,
  });

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
    HapticFeedback.mediumImpact();

    final result = await KycAiAnalyser.analyseKycDocuments(
      frontImageUrl: kyc['front_image_url'] ?? '',
      backImageUrl: kyc['back_image_url'] ?? '',
      selfieImageUrl: kyc['selfie_image_url'] ?? '',
      fullName: kyc['full_name'] ?? '',
      citizenshipNumber: kyc['citizenship_number'] ?? '',
      latitude: kyc['latitude'] != null ? double.tryParse(kyc['latitude'].toString()) : null,
      longitude: kyc['longitude'] != null ? double.tryParse(kyc['longitude'].toString()) : null,
    );

    if (mounted) setState(() { _aiResult = result; _isAnalysing = false; });
  }

  Future<void> _approve() async {
    final kyc = widget.kycData;
    if (kyc == null) return;
    await SupabaseService.updateKycStatus(kyc['id'], widget.user['id'], 'verified');
    if (mounted) {
      Navigator.pop(context);
      widget.onRefresh();
    }
  }

  Future<void> _reject() async {
    final kyc = widget.kycData;
    if (kyc == null) return;
    final reason = await _showRejectDialog();
    if (reason == null) return;
    await SupabaseService.updateKycStatus(kyc['id'], widget.user['id'], 'rejected', reason: reason);
    if (mounted) {
      Navigator.pop(context);
      widget.onRefresh();
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rejection Reason', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter reason for rejection...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kyc = widget.kycData;
    final user = widget.user;
    final kycStatus = user['kyc_status']?.toString() ?? 'none';

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['full_name'] ?? 'Unknown',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                        Text(
                          user['email'] ?? user['phone_number'] ?? '',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: kycStatus, large: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  if (kyc == null) ...[
                    const SizedBox(height: 40),
                    Icon(Icons.assignment_late_outlined, size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No KYC documents submitted yet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.grey[500]),
                    ),
                  ] else ...[
                    // User Info
                    _InfoRow(label: 'Citizenship No.', value: kyc['citizenship_number'] ?? '-'),
                    _InfoRow(label: 'Phone', value: kyc['phone_number'] ?? '-'),
                    if (kyc['latitude'] != null)
                      _InfoRow(
                        label: 'GPS',
                        value: '${double.tryParse(kyc['latitude'].toString())?.toStringAsFixed(4)}, '
                            '${double.tryParse(kyc['longitude'].toString())?.toStringAsFixed(4)}',
                      ),
                    const SizedBox(height: 20),

                    // Document Images
                    Text('Documents', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _DocImage(url: kyc['front_image_url'], label: 'Front ID'),
                        const SizedBox(width: 8),
                        _DocImage(url: kyc['back_image_url'], label: 'Back ID'),
                        const SizedBox(width: 8),
                        _DocImage(url: kyc['selfie_image_url'], label: 'Selfie'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // AI Analysis Button
                    if (_aiResult == null && !_isAnalysing)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _runAiAnalysis,
                          icon: const Text('🤖', style: TextStyle(fontSize: 20)),
                          label: Text(
                            'Analyse with AI',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),

                    if (_isAnalysing) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.brandColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.brandColor.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: AppTheme.brandColor),
                            const SizedBox(height: 12),
                            Text('AI is analysing documents...',
                                style: GoogleFonts.inter(color: AppTheme.brandColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],

                    if (_aiResult != null) _AiResultCard(result: _aiResult!),

                    const SizedBox(height: 24),

                    // Approve / Reject buttons
                    if (kycStatus == 'pending') ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _approve,
                              icon: const Icon(Icons.check_circle_rounded),
                              label: Text('Approve', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _reject,
                              icon: const Icon(Icons.cancel_rounded),
                              label: Text('Reject', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// AI RESULT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _AiResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _AiResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final verdict = result['verdict']?.toString() ?? 'ERROR';
    final confidence = result['confidence'] ?? 0;
    final notes = result['notes']?.toString() ?? '';
    final redFlags = List<String>.from(result['red_flags'] ?? []);

    Color verdictColor;
    IconData verdictIcon;
    String verdictLabel;
    switch (verdict) {
      case 'PASS':
        verdictColor = Colors.green;
        verdictIcon = Icons.verified_rounded;
        verdictLabel = 'PASS — Safe to Approve';
        break;
      case 'FAIL':
        verdictColor = Colors.red;
        verdictIcon = Icons.dangerous_rounded;
        verdictLabel = 'FAIL — Likely Fake';
        break;
      case 'ERROR':
        verdictColor = Colors.grey;
        verdictIcon = Icons.error_outline_rounded;
        verdictLabel = 'ERROR — Try again';
        break;
      default:
        verdictColor = Colors.orange;
        verdictIcon = Icons.help_rounded;
        verdictLabel = 'UNCERTAIN — Review manually';
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: verdictColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: verdictColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict Header
          Row(
            children: [
              Icon(verdictIcon, color: verdictColor, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Verdict',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    Text(verdictLabel,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: verdictColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: verdictColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$confidence%',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: verdictColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Detailed Checklist
          Text('Verification Checks',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 10),
          _CheckRow(label: 'Genuine Nepali नागरिकता Card', value: result['is_genuine_nepali_id'] == true),
          _CheckRow(label: 'Name Matches Document', value: result['name_match'] == true),
          _CheckRow(label: 'ID Number Matches', value: result['id_number_match'] == true),
          _CheckRow(label: 'Face Matches Card Photo', value: result['face_match'] == true),
          _CheckRow(label: 'Physical Card in Selfie', value: result['physical_card_in_selfie'] == true),
          _CheckRow(label: 'GPS Location in Nepal', value: result['location_valid'] == true),

          // Red Flags
          if (redFlags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text('Red Flags Detected',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...redFlags.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 12, color: Colors.red)),
                        Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 12, color: Colors.red[800]))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          // AI Notes
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(notes,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700], height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  const _CheckRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: value ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[800])),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOCUMENT IMAGE THUMBNAIL (tappable → full screen)
// ─────────────────────────────────────────────────────────────────────────────
class _DocImage extends StatelessWidget {
  final String? url;
  final String label;
  const _DocImage({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Expanded(
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _FullScreenImageViewer(url: url!, label: label)),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL SCREEN IMAGE VIEWER with pinch-to-zoom
// ─────────────────────────────────────────────────────────────────────────────
class _FullScreenImageViewer extends StatelessWidget {
  final String url;
  final String label;
  const _FullScreenImageViewer({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 6.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 60),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  final bool large;
  const _StatusBadge({required this.status, this.large = false});

  Color get _color {
    switch (status) {
      case 'verified': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 6 : 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: large ? 12 : 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
