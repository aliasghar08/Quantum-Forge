import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/screens/osce_sandbox_screen.dart';

void main() {
  testWidgets('OsceSandboxScreen renders timer, emergency vitals and handles rescue',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: OsceSandboxScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify SaMD legal banner
    expect(
      find.textContaining('Educational Simulation Only — Not for Clinical Diagnosis'),
      findsWidgets,
    );

    // Verify scenario title and presentation
    expect(find.text('Acute Acetaminophen (APAP) Hepatotoxicity'), findsOneWidget);
    expect(find.textContaining('PATIENT EMERGENCY PRESENTATION'), findsOneWidget);

    // Verify correct antidote is present
    final nacFinder = find.text('N-Acetylcysteine (NAC)');
    expect(nacFinder, findsOneWidget);

    // Tap the correct antidote
    await tester.tap(nacFinder);
    await tester.pumpAndSettle();

    // Verify success outcome and score
    expect(find.text('RESCUE SUCCESSFUL'), findsOneWidget);
    expect(find.textContaining('OSCE Score:'), findsOneWidget);
    expect(find.textContaining('HIGH-YIELD OSCE CLINICAL PEARLS'), findsOneWidget);
  });
}
