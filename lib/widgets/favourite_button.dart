import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khozna/features/TO_BE_FIXED/login_screen.dart';
import 'package:khozna/core/utils/supabase_service.dart';
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

            // This now triggers an optimistic update through the global store!
            await SupabaseService.toggleSaveProperty(widget.propertyId);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isLiked
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF385C).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
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
