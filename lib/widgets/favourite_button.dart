import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../utils/supabase_service.dart';

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
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (FirebaseAuth.instance.currentUser == null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          return;
        }
        setState(() {
          isLiked = !isLiked;
        });
        await SupabaseService.toggleSaveProperty(widget.propertyId);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.transparent, 
        child: Icon(
          Icons.favorite_rounded,
          size: widget.size,
          color: isLiked 
              ? const Color(0xFFFF385C) 
              : (widget.color ?? Colors.white),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
