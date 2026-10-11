import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/molecular_data_cards.dart';

void main() {
  testWidgets('MolecularDataCards separates distinct reactants and products', (tester) async {
    // 2 reactants: C3H5NO + H2O spaced 6 Angstroms apart
    const reactantXyz = '''13
Reactant Frame
C  0.0000  0.0000  0.0000
C  1.4000  0.0000  0.0000
C  2.1000  1.2000  0.0000
O  3.4000  1.1500  0.0500
N  1.3000  2.2000  0.0000
H -0.5000  0.9000  0.0000
H -0.5000 -0.9000  0.0000
H  1.9000 -0.9000  0.0000
H  0.3000  2.3000  0.0000
H  1.8000  3.1000  0.0000
O  8.0000  0.0000  0.0000
H  8.9600  0.0000  0.0000
H  7.6800  0.7600  0.0000
''';

    // 1 Product: C3H7NO2 (all atoms connected)
    const productXyz = '''13
Product Frame
C  0.0000  0.0000  0.0000
C  1.4000  0.0000  0.0000
C  2.1000  1.2000  0.0000
O  3.4000  1.1500  0.0500
N  1.3000  2.2000  0.0000
H -0.5000  0.9000  0.0000
H -0.5000 -0.9000  0.0000
H  1.9000 -0.9000  0.0000
H  0.3000  2.3000  0.0000
H  1.8000  3.1000  0.0000
O  3.5000  2.4000  0.0000
H  4.4000  2.4000  0.0000
H  2.2000  3.0000  0.0000
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MolecularDataCards(
              trajectoryFrames: [reactantXyz, productXyz],
            ),
          ),
        ),
      ),
    );

    // Verify Reactants Data and Products Data sections exist
    expect(find.text('Reactants Data'), findsOneWidget);
    expect(find.text('Products Data'), findsOneWidget);

    // Verify 2 components on reactant side
    expect(find.textContaining('Unique'), findsWidgets);
    expect(find.textContaining('H₂O'), findsWidgets);
  });

  testWidgets('MolecularDataCards identifies catalyst when species appears on both sides', (tester) async {
    // Reactants: A + Catalyst (H2O)
    const reactantXyz = '''6
Reactant Frame
C  0.0000  0.0000  0.0000
H  1.0900  0.0000  0.0000
H -0.3600  1.0300  0.0000
O  8.0000  0.0000  0.0000
H  8.9600  0.0000  0.0000
H  7.6800  0.7600  0.0000
''';

    // Products: B + Catalyst (H2O preserved)
    const productXyz = '''6
Product Frame
C  0.0000  0.0000  0.0000
H  1.0000  0.4000  0.0000
H -0.2000  0.9000  0.0000
O  8.0000  0.0000  0.0000
H  8.9600  0.0000  0.0000
H  7.6800  0.7600  0.0000
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MolecularDataCards(
              trajectoryFrames: [reactantXyz, productXyz],
            ),
          ),
        ),
      ),
    );

    // Catalyst banner should be displayed
    expect(find.textContaining('Catalyst / Conserved Species'), findsWidgets);
    expect(find.text('Catalyst'), findsWidgets);
  });
}
