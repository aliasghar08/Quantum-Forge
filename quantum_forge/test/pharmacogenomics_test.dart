import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/screens/pharmacogenomics_screen.dart';

void main() {
  testWidgets('PharmacogenomicsScreen renders SaMD banner and mutator options',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: PharmacogenomicsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify SaMD legal banner
    expect(
      find.textContaining('Educational Simulation Only — Not for Clinical Diagnosis'),
      findsWidgets,
    );

    // Verify liability lock modal appears
    expect(find.text('Pharmacogenomics Educational Liability Lock'), findsOneWidget);
    expect(find.text('I Understand & Accept (Educational Use)'), findsOneWidget);

    // Dismiss liability lock modal
    await tester.tap(find.text('I Understand & Accept (Educational Use)'));
    await tester.pumpAndSettle();

    // Verify enzyme selector chips exist
    expect(find.text('CYP2C9 (S-Warfarin)'), findsOneWidget);
    expect(find.text('CYP2D6 (Codeine)'), findsOneWidget);

    // Verify phenotype selection
    expect(find.text('Poor Metabolizer'), findsOneWidget);
    expect(find.text('Extensive (Normal)'), findsOneWidget);

    // Switch to Extensive
    await tester.tap(find.text('Extensive (Normal)'));
    await tester.pumpAndSettle();

    // Verify activation barrier readout exists
    expect(find.textContaining('ACTIVATION BARRIER'), findsOneWidget);
  });
}
