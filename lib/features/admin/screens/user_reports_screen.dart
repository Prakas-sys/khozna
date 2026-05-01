import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/features/profile/repositories/user_repository.dart';
import 'package:khozna/core/models/user_model.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  State<UserReportsScreen> createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  late Future<List<UserReportModel>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => _reportsFuture = UserRepository.getUserReports());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Reports', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
      body: FutureBuilder<List<UserReportModel>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) return const Center(child: Text('No reports found.'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final report = reports[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.1))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(radius: 18, backgroundImage: report.reportedUserAvatar != null ? CachedNetworkImageProvider(report.reportedUserAvatar!) : null, child: report.reportedUserAvatar == null ? const Icon(Icons.person) : null),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(report.reportedUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Reported by: ${report.reporterName}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ])),
                      IconButton(onPressed: () => _deleteReport(report.id), icon: const Icon(Icons.delete_outline, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 12),
                    Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Text(report.reason, style: GoogleFonts.inter(fontSize: 13, color: Colors.red[900]))),
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
      await UserRepository.deleteReport(id);
      _refresh();
    } catch (_) {}
  }
}

