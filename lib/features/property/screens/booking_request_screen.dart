import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:flutter/services.dart';

class BookingRequestScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String ownerId;
  final String ownerName;

  const BookingRequestScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  int _durationMonths = 1;
  int _guestCount = 1;
  String _purpose = 'work';
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  UserModel? _userProfile;

  final List<Map<String, String>> _purposes = [
    {'value': 'student', 'label': 'विद्यार्थी (Student)', 'icon': '🎓'},
    {'value': 'work', 'label': 'जागिर (Work)', 'icon': '💼'},
    {'value': 'family', 'label': 'परिवार (Family)', 'icon': '🏠'},
    {'value': 'other', 'label': 'अन्य (Other)', 'icon': '✨'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await SupabaseService.getUserProfile(SupabaseService.currentUserId);
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    HapticFeedback.lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0EA5E9),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0EA5E9),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showDurationPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('बस्ने अवधि (Duration of Stay)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [1, 3, 6, 12, 24].map((m) {
                final isSelected = _durationMonths == m;
                return GestureDetector(
                  onTap: () {
                    setState(() => _durationMonths = m);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$m महिना ($m Mo)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showGuestPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('पाहुना संख्या (Number of Guests)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(6, (i) => i + 1).map((g) {
                final isSelected = _guestCount == g;
                return GestureDetector(
                  onTap: () {
                    setState(() => _guestCount = g);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$g जना ($g)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.createBookingRequest(
        propertyId: widget.propertyId,
        propertyTitle: widget.propertyTitle,
        ownerId: widget.ownerId,
        moveInDate: _selectedDate,
        durationMonths: _durationMonths,
        guestCount: _guestCount,
        purpose: _purpose,
        message: _messageController.text,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('अनुरोध सफलतापूर्वक पठाइयो (Request Sent Successfully)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF0EA5E9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटि: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'बुकिङ अनुरोध (Booking Request)',
          style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardGroup(
                  title: 'समय र अवधि',
                  subtitle: 'Date & Duration',
                  children: [
                    _buildInputCard(
                      label: 'बस्न सुरु गर्ने मिति (Move-in Date)',
                      value: '${_selectedDate.day} ${_getMonthName(_selectedDate.month)}, ${_selectedDate.year}',
                      icon: Icons.calendar_today_rounded,
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputCard(
                            label: 'अवधि (Duration)',
                            value: '$_durationMonths महिना',
                            icon: Icons.timer_outlined,
                            onTap: _showDurationPicker,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputCard(
                            label: 'संख्या (Guests)',
                            value: '$_guestCount जना',
                            icon: Icons.group_outlined,
                            onTap: _showGuestPicker,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildCardGroup(
                  title: 'बस्नुको उद्देश्य',
                  subtitle: 'Purpose of Stay',
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _purposes.map((p) => _buildPurposeChip(p)).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildCardGroup(
                  title: 'थप जानकारी',
                  subtitle: 'Additional Information',
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'घरबेटीलाई केही सन्देश लेख्नुहोस्... (Optional)',
                          hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
                          contentPadding: const EdgeInsets.all(20),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'घरबेटीले ४८ घण्टा भित्र जवाफ दिनेछन्',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCTA(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGroup({required String title, required String subtitle, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildInputCard({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeChip(Map<String, String> p) {
    final isSelected = _purpose == p['value'];
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _purpose = p['value']!);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p['icon']!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              p['label']!,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -8)),
        ],
      ),
      child: _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
          : ElevatedButton(
              onPressed: _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF0EA5E9).withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                minimumSize: const Size(double.infinity, 58),
              ),
              child: Text(
                'अनुरोध पठाउनुहोस् (Send Request)',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2),
              ),
            ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
