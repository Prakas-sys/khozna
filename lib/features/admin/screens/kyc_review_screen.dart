import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/features/admin/repositories/admin_repository.dart';
import 'package:khozna/core/models/admin_model.dart';
import 'package:khozna/core/security/security_utils.dart';

class KycReviewScreen extends StatefulWidget {
  const KycReviewScreen({super.key});

  @override
  State<KycReviewScreen> createState() => _KycReviewScreenState();
}

class _KycReviewScreenState extends State<KycReviewScreen> {
  late Future<List<KycVerificationModel>> _kycFuture;
  final Map<String, bool> _processingKycs = {};

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () => SecurityUtils.setSecure(false));
    _refresh();
  }

  void _refresh() => setState(() => _kycFuture = AdminRepository.getPendingKycs());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KYC Review', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
      body: FutureBuilder<List<KycVerificationModel>>(
        future: _kycFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data ?? [];
          if (list.isEmpty) return Center(child: Text('No pending KYCs!', style: GoogleFonts.inter(color: Colors.grey)));

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
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(kyc.fullName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(kyc.phoneNumber, style: GoogleFonts.inter(color: Colors.grey)),
                        ]),
                        IconButton(onPressed: () => _confirmDelete(kyc.id), icon: const Icon(Icons.delete_forever, color: Colors.red)),
                      ]),
                      const SizedBox(height: 8),
                      Text('Citizenship: ${kyc.citizenshipNumber}', style: GoogleFonts.inter()),
                      const SizedBox(height: 16),
                      Row(children: [
                        _buildThumb('Front', kyc.frontImageUrl),
                        const SizedBox(width: 8),
                        _buildThumb('Back', kyc.backImageUrl),
                        const SizedBox(width: 8),
                        _buildThumb('Selfie', kyc.selfieImageUrl),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: ElevatedButton(onPressed: _processingKycs[kyc.id] == true ? null : () => _process(kyc, 'verified'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Approve'))),
                        const SizedBox(width: 12),
                        Expanded(child: OutlinedButton(onPressed: _processingKycs[kyc.id] == true ? null : () => _showRejectDialog(kyc), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Reject'))),
                      ]),
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

  Widget _buildThumb(String label, String url) {
    return Column(children: [
      Container(width: 80, height: 60, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), image: url.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(url), fit: BoxFit.cover) : null), child: url.isEmpty ? const Icon(Icons.image_not_supported) : null),
      Text(label, style: const TextStyle(fontSize: 10)),
    ]);
  }

  void _process(KycVerificationModel kyc, String status, {String? reason}) async {
    setState(() => _processingKycs[kyc.id] = true);
    try {
      await AdminRepository.updateKycStatus(kyc.id, kyc.userId, status, reason: reason);
      _refresh();
    } catch (_) {}
    setState(() => _processingKycs.remove(kyc.id));
  }

  void _showRejectDialog(KycVerificationModel kyc) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Reject KYC'),
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Reason')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { Navigator.pop(context); _process(kyc, 'rejected', reason: controller.text); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Reject', style: TextStyle(color: Colors.white))),
      ],
    ));
  }

  void _confirmDelete(String id) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete KYC?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (ok == true) {
      await AdminRepository.deleteKycPermanently(id);
      _refresh();
    }
  }
}

