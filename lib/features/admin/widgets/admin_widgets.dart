import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminStatusBadge extends StatelessWidget {
  final String status;
  final bool large;
  const AdminStatusBadge({super.key, required this.status, this.large = false});

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

class AdminInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const AdminInfoRow({super.key, required this.label, required this.value});

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

class AdminDocImage extends StatelessWidget {
  final String? url;
  final String label;
  const AdminDocImage({super.key, required this.url, required this.label});

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
          MaterialPageRoute(builder: (_) => FullScreenImageViewer(url: url!, label: label)),
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

class FullScreenImageViewer extends StatelessWidget {
  final String url;
  final String label;
  const FullScreenImageViewer({super.key, required this.url, required this.label});

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

class AiResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const AiResultCard({super.key, required this.result});

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
          Text('Verification Checks',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 10),
          _CheckRow(label: 'Genuine Nepali नागरिकता Card', value: result['is_genuine_nepali_id'] == true),
          _CheckRow(label: 'Name Matches Document', value: result['name_match'] == true),
          _CheckRow(label: 'ID Number Matches', value: result['id_number_match'] == true),
          _CheckRow(label: 'Real Human Face in Selfie', value: result['human_face_in_selfie'] == true),
          _CheckRow(label: 'GPS Location in Nepal', value: result['location_valid'] == true),
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
