import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/utils/xyz_parser.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/molecular_viewer_widget.dart';

void main() {
  const sampleXyz = '''3
Water
O 0.000 0.000 0.000
H 0.000 0.757 0.586
H 0.000 -0.757 0.586
''';

  testWidgets('renders MolecularViewerWidget with reaction mechanism header and controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MolecularViewerWidget(
            currentXyzData: sampleXyz,
            showTrajectoryHeader: true,
          ),
        ),
      ),
    );
    await tester.pump();

    // Check header title and default TS stage
    expect(find.text('Reaction Mechanism'), findsOneWidget);
    expect(find.text('Transition State'), findsOneWidget);

    // Check speed selector chips
    expect(find.text('0.25x'), findsOneWidget);
    expect(find.text('0.5x'), findsOneWidget);
    expect(find.text('1.0x'), findsOneWidget);
    expect(find.text('2.0x'), findsOneWidget);

    // Check play/pause button
    expect(find.byTooltip('Pause Animation'), findsOneWidget);

    // Pause animation
    await tester.tap(find.byTooltip('Pause Animation'));
    await tester.pump();
    expect(find.byTooltip('Play Animation'), findsOneWidget);

    // Step navigation (< and >)
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pump();
    expect(find.text('Approach'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(find.text('Transition State'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(find.text('Products'), findsOneWidget);

    // Switch speed chip to 1.0x
    await tester.tap(find.text('1.0x'));
    await tester.pump();
    expect(find.text('1.0x'), findsOneWidget);
  });
}
