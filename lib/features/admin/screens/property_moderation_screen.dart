import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/property_repository.dart';
import 'package:khozna/core/models/property_model.dart';

class PropertyModerationScreen extends StatefulWidget {
  const PropertyModerationScreen({super.key});

  @override
  State<PropertyModerationScreen> createState() => _PropertyModerationScreenState();
}

class _PropertyModerationScreenState extends State<PropertyModerationScreen> {
  late Future<List<Property>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _propertiesFuture = PropertyRepository.getAdminProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Property Moderation', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: FutureBuilder<List<Property>>(
        future: _propertiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final properties = snapshot.data ?? [];
          if (properties.isEmpty) return Center(child: Text('No properties found.', style: GoogleFonts.inter(color: Colors.grey)));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            separatorBuilder: (context, index) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final p = properties[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(p.imageUrl, width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)))),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(p.location, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text('रू ${p.price}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.brandColor)),
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _getStatusColor(p.status).withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(p.status.toUpperCase(), style: TextStyle(color: _getStatusColor(p.status), fontSize: 10, fontWeight: FontWeight.bold))),
                      ])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: ElevatedButton(onPressed: () => _updateStatus(p.id, 'available'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Approve'))),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(onPressed: () => _showDeleteConfirm(p.id), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Remove'))),
                  ]),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available': return Colors.green;
      case 'booked': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.blue;
    }
  }

  void _updateStatus(String id, String status) async {
    try {
      await PropertyRepository.updatePropertyStatus(id, status);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Property $status!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Listing?'),
        content: const Text('This will permanently delete this property listing.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            Navigator.pop(context);
            try {
              await PropertyRepository.deletePropertyPermanently(id);
              _refresh();
            } catch (_) {}
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
