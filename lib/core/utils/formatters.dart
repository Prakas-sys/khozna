import 'package:intl/intl.dart';

class PriceFormatter {
  static String format(String priceStr) {
    try {
      // Remove any non-numeric characters EXCEPT decimal points
      final cleanPrice = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleanPrice.isEmpty) return priceStr;

      double price = double.parse(cleanPrice);

      if (price >= 10000000) {
        // Crore
        double formatted = price / 10000000;
        return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)} Cr';
      } else if (price >= 100000) {
        // Lakh
        double formatted = price / 100000;
        return '${formatted.toStringAsFixed(formatted.truncateToDouble() == formatted ? 0 : 1)} Lakh';
      } else {
        // Thousands / Normal
        return price.toInt().toString();
      }
    } catch (e) {
      return priceStr;
    }
  }
}
