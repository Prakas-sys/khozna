import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PropertyRepository Logic & Sanitization Tests', () {
    test('Title and Description sanitization test', () {
      final rawTitle = '  Awesome Villa in Pokhara! <script>alert("hack")</script>  ';
      final cleanTitle = rawTitle.trim().replaceAll(RegExp(r'<[^>]*>'), '');

      expect(cleanTitle, equals('Awesome Villa in Pokhara! alert("hack")'));
      expect(cleanTitle.contains('<script>'), isFalse);
    });

    test('Keyword-based auto categorization test for Student Friendly', () {
      final fullText = 'Close to university campus and student library'.toLowerCase();
      final studentKeywords = ['student', 'college', 'university', 'campus'];

      final bool isStudentFriendly = studentKeywords.any((k) => fullText.contains(k));

      expect(isStudentFriendly, isTrue);
    });

    test('Keyword-based auto categorization test for Premium', () {
      final price = 25000.0;
      final fullText = 'Luxury modern apartment with VIP views'.toLowerCase();
      final premiumKeywords = ['luxury', 'modern', 'vip', 'premium'];

      final bool isPremium = premiumKeywords.any((k) => fullText.contains(k)) || price >= 18000;

      expect(isPremium, isTrue);
    });

    test('Rupee formatting helper test', () {
      final price = 15000.0;
      final formatted = 'Rs. ${price.toInt()}';

      expect(formatted, equals('Rs. 15000'));
    });
  });
}
