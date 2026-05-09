import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class MapLauncher {
  static Future<void> openMap(double lat, double lng, String title) async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    String appleUrl = 'https://maps.apple.com/?q=$lat,$lng';

    try {
      if (Platform.isIOS) {
        if (await canLaunchUrl(Uri.parse(appleUrl))) {
          await launchUrl(Uri.parse(appleUrl));
        } else {
          await launchUrl(Uri.parse(googleUrl));
        }
      } else {
        // Android
        final String googleMapUri = "google.navigation:q=$lat,$lng";
        if (await canLaunchUrl(Uri.parse(googleMapUri))) {
          await launchUrl(Uri.parse(googleMapUri));
        } else {
          await launchUrl(
            Uri.parse(googleUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      }
    } catch (e) {
      debugPrint('Could not launch maps: $e');
      // Fallback to web browser
      await launchUrl(
        Uri.parse(googleUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
