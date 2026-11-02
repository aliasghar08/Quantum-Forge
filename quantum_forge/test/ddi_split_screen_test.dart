import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/screens/ddi_split_screen.dart';

void main() {
  testWidgets('DdiSplitScreen renders SaMD banner, presets, and steric collision mechanics',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: DdiSplitScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify SaMD legal banner
    expect(
      find.textContaining('Educational Simulation Only — Not for Clinical Diagnosis'),
      findsWidgets,
    );

    // Verify Title & Subtitle
    expect(
      find.text('Steric Exclusion & Drug-Drug Collision Mechanics'),
      findsOneWidget,
    );

    // Verify Superbug preset selection
    expect(find.text('MRSA'), findsWidgets);
    expect(find.text('TEM-52'), findsWidgets);
    expect(find.text('KPC-2'), findsWidgets);

    // Verify Steric Clash is detected when mutation is active
    expect(
      find.textContaining('STERIC RESISTANCE COLLISION DETECTED'),
      findsOneWidget,
    );

    // Switch to TEM-52
    await tester.tap(find.text('TEM-52'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Ser-238 + Glu-104-Lys'),
      findsWidgets,
    );
  });
}
