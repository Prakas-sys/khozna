import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppTheme {
  static const Color brandColor = Color(0xFF00A3E1);
  static const Color accentColor = Color(0xFF00A3E1);
  static const Color primaryTextColor = Color(0xFF1A1A1A);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color backgroundColor = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandColor,
        primary: brandColor,
        onPrimary: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, color: primaryTextColor),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, color: secondaryTextColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: brandColor),
        ),
      ),
    );
  }

  static const String defaultManAvatar = 'assets/images/man avatar.jpeg';
  static const String defaultWomanAvatar = 'assets/images/women avatar.jpeg';

  /// Returns ONLY man avatar.jpeg or women avatar.jpeg based on seed/name
  static String getIllustrationAvatar(String? seed) {
    if (seed == null || seed.trim().isEmpty) {
      return defaultManAvatar;
    }
    final String lower = seed.trim().toLowerCase();

    // Female indicators
    if (lower.contains('mrs') ||
        lower.contains('ms') ||
        lower.contains('miss') ||
        lower.contains('girl') ||
        lower.contains('woman') ||
        lower.contains('female') ||
        lower.contains('lady') ||
        lower.contains('sita') ||
        lower.contains('maya') ||
        lower.contains('pooja') ||
        lower.contains('rita') ||
        lower.contains('gita') ||
        lower.contains('anita') ||
        lower.contains('sunita')) {
      return defaultWomanAvatar;
    }

    return defaultManAvatar;
  }

  /// Returns a valid high-quality avatar URL.
  static String getAvatarUrl(String? avatarUrl, {String? name}) {
    if (avatarUrl != null &&
        avatarUrl.trim().isNotEmpty &&
        !avatarUrl.contains('via.placeholder.com') &&
        !avatarUrl.contains('pravatar.cc')) {
      return avatarUrl.trim();
    }
    if (name != null && name.trim().isNotEmpty) {
      final encoded = Uri.encodeComponent(name.trim());
      return 'https://ui-avatars.com/api/?name=$encoded&background=00A3E1&color=ffffff&bold=true&size=256';
    }
    return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80';
  }

  /// Renders a CircleAvatar with network image or custom asset fallback
  static Widget buildAvatarWidget({
    required String? avatarUrl,
    required double radius,
    String? name,
    Color? backgroundColor,
  }) {
    final String? trimmed = avatarUrl?.trim();

    // 1. Local asset path
    if (trimmed != null &&
        (trimmed.startsWith('assets/') || trimmed.startsWith('assets\\'))) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? const Color(0xFFF1F5F9),
        backgroundImage: AssetImage(trimmed),
      );
    }

    // 2. Remote Network URL
    final bool isNetworkUrl =
        trimmed != null &&
        (trimmed.startsWith('http://') || trimmed.startsWith('https://')) &&
        !trimmed.contains('via.placeholder.com') &&
        !trimmed.contains('pravatar.cc');

    if (isNetworkUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? const Color(0xFFF1F5F9),
        backgroundImage: CachedNetworkImageProvider(trimmed),
      );
    }

    // 3. Fallback asset avatar
    final String assetPath = getIllustrationAvatar(name ?? trimmed);
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFFF1F5F9),
      backgroundImage: AssetImage(assetPath),
    );
  }
}
