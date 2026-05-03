import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/features/auth/screens/login_screen.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/app_notifiers.dart';

class FavouriteButton extends StatefulWidget {
  final String propertyId;
  final double size;
  final Color? color;
  final bool showShadow;

  const FavouriteButton({
    super.key,
    required this.propertyId,
    this.size = 28,
    this.color,
    this.showShadow = true,
  });

  @override
  State<FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<FavouriteButton> {
  void _showSaveBottomSheet(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bool isValid = nameController.text.trim().isNotEmpty;
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 24),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Save Property (सेभ गर्नुहोस्)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Name your List (लिस्टको नाम दिनुहोस्)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Text Field
                    TextField(
                      controller: nameController,
                      maxLength: 50,
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'List Name (जस्तै: मनपरेका घरहरू)',
                        hintStyle: GoogleFonts.mukta(color: Colors.grey[400], fontSize: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.brandColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        counterStyle: GoogleFonts.mukta(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isValid
                              ? () async {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                  await SupabaseService.toggleSaveProperty(widget.propertyId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Saved to ${nameController.text.trim()}',
                                          style: GoogleFonts.mukta(fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor: Colors.black87,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isValid ? Colors.black : Colors.grey[300],
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: savedPropertiesStore,
      builder: (context, savedIds, _) {
        final bool isLiked = savedIds.contains(widget.propertyId);

        return GestureDetector(
          onTap: () async {
            if (Supabase.instance.client.auth.currentUser == null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              return;
            }

            // Haptic Feedback for premium feel
            HapticFeedback.mediumImpact();

            if (isLiked) {
              // Immediately unlike if already liked
              await SupabaseService.toggleSaveProperty(widget.propertyId);
            } else {
              // Show the Airbnb-style wishlist bottom sheet
              _showSaveBottomSheet(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: SvgPicture.string(
              '''
              <svg viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" style="display: block; fill: ${isLiked ? '#FF385C' : 'rgba(0, 0, 0, 0.4)'}; height: ${widget.size}px; width: ${widget.size}px; stroke: #ffffff; stroke-width: 2.2; overflow: visible;">
                <path d="M16 28c7-4.733 14-10 14-17 0-4.418-3.582-8-8-8a7.965 7.965 0 0 0-6 2.733A7.965 7.965 0 0 0 10 3c-4.418 0-8 3.582-8 8 0 7 7 12.267 14 17z"></path>
              </svg>
              ''',
              width: widget.size,
              height: widget.size,
            ),
          ),
        );
      },
    );
  }
}

