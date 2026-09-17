import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/property/screens/property_details_screen.dart';
import 'package:khozna/features/property/screens/visit_request_screen.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuestVisitDetailsScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? initialBookingData;

  const GuestVisitDetailsScreen({
    super.key,
    required this.bookingId,
    this.initialBookingData,
  });

  @override
  State<GuestVisitDetailsScreen> createState() => _GuestVisitDetailsScreenState();
}

class _GuestVisitDetailsScreenState extends State<GuestVisitDetailsScreen> {
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isActioning = false;
  String _currentStatus = 'pending_approval'; // pending_approval, visit_accepted, rejected, suggested_time
  bool _justAcceptedNewTime = false;
  bool _justSentNewTime = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBookingData != null) {
      _booking = Map<String, dynamic>.from(widget.initialBookingData!);
      _currentStatus = _booking!['status']?.toString() ?? 'pending_approval';
      _isLoading = false;
    }
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final res = await Supabase.instance.client
          .from('bookings')
          .select(
            '*, properties(*), owner:profiles!bookings_owner_id_fkey(id, full_name, avatar_url, phone_number, kyc_status, area_name)',
          )
          .eq('id', widget.bookingId)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _booking = Map<String, dynamic>.from(res);
          _currentStatus = _booking!['status']?.toString() ?? 'pending_approval';
          _isLoading = false;
        });
      } else if (_booking == null && mounted) {
        _setupMockupData();
      }
    } catch (e) {
      debugPrint('Error loading guest visit request details: $e');
      if (_booking == null && mounted) {
        _setupMockupData();
      }
    }
  }

  void _setupMockupData() {
    final visitDate = DateTime(2026, 9, 20, 14, 0); // Sept 20, 2026 at 2:00 PM
    setState(() {
      _booking = {
        'id': widget.bookingId,
        'status': 'suggested_time',
        'check_in': DateTime(2026, 9, 21, 11, 0).toIso8601String(), // Suggested time
        'original_check_in': visitDate.toIso8601String(),
        'guests': 2,
        'message': 'Sept 21 at 11:00 AM works better for us.',
        'rejection_reason': 'Sept 21 at 11:00 AM works better for us.',
        'created_at': DateTime.now().toIso8601String(),
        'properties': {
          'id': 'prop_demo',
          'title': 'Mountain View Villa',
          'location': 'Kavrepalanchok, Kathmandu',
          'area_name': 'Kavrepalanchok, Kathmandu',
          'price': 25000,
          'category': 'Villa',
          'guests': 4,
          'bedrooms': 3,
          'bathrooms': 2,
          'images': [
            'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=800&q=80'
          ],
        },
        'owner': {
          'id': 'owner_demo',
          'full_name': 'Prakas Owner',
          'phone_number': '+977 9800000000',
          'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
          'kyc_status': 'verified',
        },
      };
      _currentStatus = 'suggested_time';
      _isLoading = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic>? get _propertyData => _booking?['properties'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _ownerData => _booking?['owner'] as Map<String, dynamic>?;

  String get _propertyTitle =>
      _propertyData?['title']?.toString() ?? _booking?['property_title']?.toString() ?? 'Mountain View Villa';
  String get _propertyLocation =>
      _propertyData?['location']?.toString() ??
      _propertyData?['area_name']?.toString() ??
      'Kavrepalanchok, Kathmandu';

  String? get _propertyImage {
    final imgs = _propertyData?['images'];
    if (imgs is List && imgs.isNotEmpty) return imgs.first.toString();
    return _booking?['property_image']?.toString() ??
        'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=800&q=80';
  }

  String get _ownerName {
    final name = _ownerData?['full_name']?.toString() ?? _booking?['owner_name']?.toString() ?? 'Property Owner';
    return (name == 'Khozna app' || name.trim().isEmpty) ? 'Property Owner' : name;
  }

  String? get _ownerAvatar =>
      _ownerData?['avatar_url']?.toString() ?? _booking?['owner_avatar']?.toString();

  DateTime get _visitDateTime {
    final raw = _booking?['check_in']?.toString();
    if (raw != null) {
      return DateTime.tryParse(raw) ?? DateTime(2026, 9, 20, 14, 0);
    }
    return DateTime(2026, 9, 20, 14, 0);
  }

  DateTime get _originalVisitDateTime {
    final raw = _booking?['original_check_in']?.toString();
    if (raw != null) {
      return DateTime.tryParse(raw) ?? DateTime(2026, 9, 20, 14, 0);
    }
    return DateTime(2026, 9, 20, 14, 0);
  }

  int get _visitorCount {
    final v = _booking?['guests'] ?? _booking?['guest_count'] ?? _booking?['visiting_count'];
    if (v != null) return int.tryParse(v.toString()) ?? 2;
    return 2;
  }

  String get _ownerNote {
    final note = _booking?['rejection_reason']?.toString() ?? _booking?['message']?.toString();
    if (note != null && note.trim().isNotEmpty) return note;
    if (_currentStatus == 'rejected') return 'Sorry, we are not available at that time.';
    if (_currentStatus == 'suggested_time') return 'Sept 21 at 11:00 AM works better for us.';
    return '';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GUEST ACTIONS: ACCEPT NEW TIME, SUGGEST ANOTHER TIME, CHAT, DIRECTIONS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleAcceptNewTime() async {
    HapticFeedback.mediumImpact();
    setState(() => _isActioning = true);
    try {
      await BookingRepository.guestAcceptNewTime(widget.bookingId);
    } catch (e) {
      debugPrint('Guest accept new time error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _currentStatus = 'visit_accepted';
          _justAcceptedNewTime = true;
          if (_booking != null) _booking!['status'] = 'visit_accepted';
          _isActioning = false;
        });
      }
    }
  }

  Future<void> _handleSuggestAnotherTime() async {
    HapticFeedback.lightImpact();
    DateTime selectedDate = _visitDateTime.add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(_visitDateTime);
    final TextEditingController msgController = TextEditingController();

    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 20, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Suggest Another Visit Time',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Propose a date and time that fits your availability better.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // Date Picker Tile
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      setS(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppTheme.brandColor, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Date', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                            Text(
                              DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_calendar_rounded, color: Color(0xFF94A3B8), size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Time Picker Tile
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setS(() => selectedTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppTheme.brandColor, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Time', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                            Text(
                              selectedTime.format(ctx),
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Optional Message Input
                Text('Optional Message', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                const SizedBox(height: 6),
                TextField(
                  controller: msgController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'e.g., Would 2:30 PM work for you instead?',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 22),

                // Send Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Send New Time',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed == true) {
      setState(() => _isActioning = true);
      final newDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      try {
        await BookingRepository.guestSuggestAnotherTime(
          widget.bookingId,
          newVisitTime: newDateTime,
          message: msgController.text.trim(),
        );
      } catch (e) {
        debugPrint('Error suggesting time: $e');
      } finally {
        if (mounted) {
          setState(() {
            _currentStatus = 'pending_approval';
            _justSentNewTime = true;
            if (_booking != null) {
              _booking!['status'] = 'pending_approval';
              _booking!['check_in'] = newDateTime.toIso8601String();
            }
            _isActioning = false;
          });
        }
      }
    }
  }

  void _openChatWithOwner() {
    HapticFeedback.lightImpact();
    final ownerId = _ownerData?['id']?.toString() ?? _booking?['owner_id']?.toString() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          ownerId: ownerId,
          name: _ownerName,
          avatar: _ownerAvatar ?? '',
          online: true,
          initialMessage: 'Hi $_ownerName, regarding my visit request for "$_propertyTitle"...',
        ),
      ),
    );
  }

  void _openPropertyDetails() {
    HapticFeedback.lightImpact();
    if (_propertyData != null) {
      try {
        final prop = Property.fromMap(_propertyData!);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(property: prop),
          ),
        );
        return;
      } catch (e) {
        debugPrint('Error parsing property model: $e');
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing property details for "$_propertyTitle"...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openDirections() async {
    HapticFeedback.mediumImpact();
    final query = Uri.encodeComponent('$_propertyTitle, $_propertyLocation');
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        _copyLocationToClipboard();
      }
    } catch (_) {
      _copyLocationToClipboard();
    }
  }

  void _copyLocationToClipboard() {
    Clipboard.setData(ClipboardData(text: '$_propertyTitle, $_propertyLocation'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Property location copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleRequestAnotherTime() {
    if (_propertyData != null) {
      try {
        final prop = Property.fromMap(_propertyData!);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VisitRequestScreen(property: prop),
          ),
        );
        return;
      } catch (_) {}
    }
    _handleSuggestAnotherTime();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD SCREEN
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Visit Request Status',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor, strokeWidth: 2),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Header / Banner (Accepted, Declined, New Time Suggested, or Sent)
                  _buildStatusBanner(),

                  const SizedBox(height: 16),

                  // Property Details Card
                  _buildPropertyCard(),

                  const SizedBox(height: 16),

                  // Time Comparison block if owner suggested new time
                  if (_currentStatus == 'suggested_time') ...[
                    _buildTimeComparisonCard(),
                    const SizedBox(height: 16),
                  ],

                  // Visit Info Summary (Date, Time, Visitors, Owner Note)
                  _buildVisitInfoCard(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading ? null : _buildBottomActions(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS BANNERS & CONFIRMATION CARDS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    if (_currentStatus == 'visit_accepted') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _justAcceptedNewTime ? 'Visit Confirmed' : 'Visit Request Accepted ✓',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _justAcceptedNewTime
                        ? 'Your new visit time has been confirmed.'
                        : 'Your visit has been confirmed by the owner.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF047857),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_currentStatus == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF64748B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visit Request Declined',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'The owner has declined your visit request for $_propertyTitle.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_currentStatus == 'suggested_time') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Visit Time Suggested',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'The owner suggested a new time for your visit to $_propertyTitle.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF1D4ED8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Pending
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _justSentNewTime ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _justSentNewTime ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _justSentNewTime ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _justSentNewTime ? Icons.send_rounded : Icons.hourglass_top_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _justSentNewTime ? 'New Time Sent' : 'Visit Request Pending',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _justSentNewTime ? const Color(0xFF9A3412) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _justSentNewTime
                        ? 'The owner has been notified. We’ll let you know when they respond.'
                        : 'Your visit request has been sent to the owner.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _justSentNewTime ? const Color(0xFFC2410C) : const Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROPERTY CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPropertyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _propertyImage != null && _propertyImage!.isNotEmpty
                  ? Image.network(
                      _propertyImage!,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155), width: 1),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6, bottom: 6),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 34,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.key_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155), width: 1),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6, bottom: 6),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 34,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.brandColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.key_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _propertyTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFF64748B), size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _propertyLocation,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openPropertyDetails,
                    child: Text(
                      'View Property Listing',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TIME COMPARISON CARD (SCREEN 4)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTimeComparisonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Comparison',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Original Request', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd').format(_originalVisitDateTime),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                      ),
                      Text(
                        DateFormat('h:mm a').format(_originalVisitDateTime),
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF3B82F6), size: 18),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suggested Time', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1D4ED8))),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd').format(_visitDateTime),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E40AF)),
                      ),
                      Text(
                        DateFormat('h:mm a').format(_visitDateTime),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VISIT INFO CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildVisitInfoCard() {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_visitDateTime);
    final formattedTime = DateFormat('h:mm a').format(_visitDateTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visit Details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),

            // Date Tile
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: AppTheme.brandColor, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    Text(
                      formattedDate,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Time & Visitors Row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.access_time_rounded, color: AppTheme.brandColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                          Text(
                            formattedTime,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.group_rounded, color: Color(0xFF475569), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Visitors', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                          Text(
                            '$_visitorCount people',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Optional Owner Message box if declined or suggested
            if (_ownerNote.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Owner Message',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '“$_ownerNote”',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Step confirmation message if accepted
            if (_currentStatus == 'visit_accepted') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Your visit is confirmed.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM ACTIONS (PER STATUS STATE)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomActions() {
    if (_isActioning) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        color: Colors.white,
        child: const CircularProgressIndicator(color: AppTheme.brandColor, strokeWidth: 2),
      );
    }

    // STATE: ACCEPTED / CONFIRMED (Screen 2 & Screen 5)
    if (_currentStatus == 'visit_accepted') {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _openChatWithOwner,
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: Text(
                        'Message Owner',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: Text(
                        'Get Directions',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // STATE: OWNER SUGGESTS NEW TIME (Screen 4)
    if (_currentStatus == 'suggested_time') {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary: Accept New Time
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleAcceptNewTime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Accept New Time',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _handleSuggestAnotherTime,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Suggest Another Time',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _openChatWithOwner,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF475569)),
                  tooltip: 'Message Owner',
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // STATE: DECLINED (Screen 3)
    if (_currentStatus == 'rejected') {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _openChatWithOwner,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text(
                    'Message Owner',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleRequestAnotherTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Request Another Time',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // DEFAULT / PENDING
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _openChatWithOwner,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  'Message Owner',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openPropertyDetails,
                icon: const Icon(Icons.home_rounded, size: 18),
                label: Text(
                  'View Property',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
