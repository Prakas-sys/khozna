import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static const List<String> defaultAvatarsList = [
    'assets/images/man avatar.jpeg',
    'assets/images/women avatar.jpeg',
    'assets/images/man illustrate png.png',
    'assets/images/girl illustrate.png',
    'assets/images/boy illustrate  png.png',
  ];

  /// Returns one of the custom default avatar assets based on name/seed
  static String getIllustrationAvatar(String? seed) {
    if (seed == null || seed.trim().isEmpty) {
      return 'assets/images/man avatar.jpeg';
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
      final int fHash = lower.codeUnits.fold(0, (prev, elem) => prev + elem);
      return fHash.abs() % 2 == 0
          ? 'assets/images/women avatar.jpeg'
          : 'assets/images/girl illustrate.png';
    }

    final int hash = lower.codeUnits.fold(0, (prev, elem) => prev + elem);
    final int index = hash.abs() % 3;
    if (index == 0) return 'assets/images/man avatar.jpeg';
    if (index == 1) return 'assets/images/man illustrate png.png';
    return 'assets/images/boy illustrate  png.png';
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

  /// Renders a CircleAvatar with network image or custom illustration asset fallback
  static Widget buildAvatarWidget({
    required String? avatarUrl,
    required double radius,
    String? name,
    Color? backgroundColor,
  }) {
    final bool hasNetworkAvatar =
        avatarUrl != null &&
        avatarUrl.trim().isNotEmpty &&
        !avatarUrl.contains('via.placeholder.com') &&
        !avatarUrl.contains('pravatar.cc');

    if (hasNetworkAvatar) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? const Color(0xFFF1F5F9),
        backgroundImage: CachedNetworkImageProvider(avatarUrl.trim()),
      );
    }

    final String assetPath = getIllustrationAvatar(name ?? avatarUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFFF1F5F9),
      backgroundImage: AssetImage(assetPath),
    );
  }
}
