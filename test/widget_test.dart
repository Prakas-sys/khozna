// Khozna - Smoke Test Suite
//
// KhoznaApp requires live Supabase, Firebase, and dotenv to be initialized.
// These services cannot run in the test harness without a real backend.
//
// This test file validates that:
// 1. Flutter test plumbing is working correctly.
// 2. Standalone widgets render without crashing.
//
// For integration tests with real services, use Flutter Driver or integration_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal stand-alone widget to smoke-test Flutter rendering in CI.
class _StandaloneSmoke extends StatelessWidget {
  const _StandaloneSmoke();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Khozna'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Flutter rendering smoke test', (WidgetTester tester) async {
    // Build a minimal standalone widget (no Supabase/Firebase/dotenv required).
    await tester.pumpWidget(const _StandaloneSmoke());

    // Verify the MaterialApp scaffolds correctly.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Khozna'), findsOneWidget);
  });
}
