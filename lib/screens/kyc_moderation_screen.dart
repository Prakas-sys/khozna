import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/supabase_service.dart';

class KycModerationScreen extends StatefulWidget {
  const KycModerationScreen({super.key});

  @override
  State<KycModerationScreen> createState() => _KycModerationScreenState();
}

class _KycModerationScreenState extends State<KycModerationScreen> {
  late Future<List<Map<String, dynamic>>> _pendingKycFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _pendingKycFuture = SupabaseService.getPendingKycRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('KYC Moderation', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingKycFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data ?? [];
          
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'All caught up!',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending KYC requests at the moment.',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildKycCard(request);
            },
          );
        },
      ),
    );
  }

  Widget _buildKycCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.brandColor.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.brandColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['full_name'] ?? 'Unknown User',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'ID: ${request['citizenship_number'] ?? 'N/A'}',
                        style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: GoogleFonts.inter(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Documents Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submitted Documents:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildImagePreview('Front', request['front_image_url']),
                    const SizedBox(width: 12),
                    _buildImagePreview('Back', request['back_image_url']),
                    const SizedBox(width: 12),
                    _buildImagePreview('Selfie', request['selfie_image_url']),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(request, isApprove: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(request, isApprove: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String label, String? url) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (url != null) {
            _showFullScreenImage(url, label);
          }
        },
        child: Column(
          children: [
            Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                image: url != null ? DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: url == null ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
            ),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(String url, String label) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(Map<String, dynamic> request, {required bool isApprove}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApprove ? 'Approve KYC?' : 'Reject KYC?'),
        content: Text(isApprove 
            ? 'This will verify the user and allow them to list properties.' 
            : 'This will reject their documents. They will need to submit again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: isApprove ? Colors.green : Colors.red),
            child: Text(isApprove ? 'Yes, Approve' : 'Yes, Reject', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (isApprove) {
          await SupabaseService.approveKyc(request['id'], request['user_id']);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC Approved Successfully!'), backgroundColor: Colors.green));
        } else {
          await SupabaseService.rejectKyc(request['id'], request['user_id']);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC Rejected.'), backgroundColor: Colors.red));
        }
        _refresh();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
