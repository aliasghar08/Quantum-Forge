// ============================================================================
// Copyright Watermark & Legal Protection Badge Tests
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/widgets/floating_copyright_watermark.dart';

void main() {
  group('FloatingCopyrightWatermark Tests', () {
    Widget buildWatermarkTestApp(Size surfaceSize) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: Stack(
              children: const [
                Center(child: Text('Underlying App Content')),
                FloatingCopyrightWatermark(),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('Renders author name and email on desktop viewport', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(buildWatermarkTestApp(const Size(1200, 800)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ali Asghar'), findsOneWidget);
      expect(find.textContaining('aliasgharinnocent@yahoo.com'), findsOneWidget);
      expect(find.textContaining('Quantum Forge'), findsOneWidget);
      expect(find.textContaining('All Rights Reserved'), findsOneWidget);
      expect(find.textContaining('DMCA Protected'), findsOneWidget);

      // Verify descendant IgnorePointer is ignoring
      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(FloatingCopyrightWatermark),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('Adapts responsively on mobile viewport', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 800));
      await tester.pumpWidget(buildWatermarkTestApp(const Size(480, 800)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ali Asghar'), findsOneWidget);
      expect(find.textContaining('aliasgharinnocent@yahoo.com'), findsOneWidget);
    });

    testWidgets('Underlying content can be tapped through IgnorePointer', (tester) async {
      var tapped = false;
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 700,
              child: Stack(
                children: [
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => tapped = true,
                        child: const Text('Click Behind Watermark'),
                      ),
                    ),
                  ),
                  const FloatingCopyrightWatermark(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click Behind Watermark'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
