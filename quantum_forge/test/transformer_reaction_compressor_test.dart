import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/algorithms/transformer_reaction_compressor.dart';
import 'package:quantum_forge/core/utils/molecule_parser.dart';

void main() {
  group('TransformerReactionCompressor', () {
    test('handles Paracetamol synthesis heavy reaction with attention and max pooling', () {
      // 4-aminophenol (C6H7NO) + acetic anhydride (C4H6O3) -> Paracetamol + acetic acid
      // 33 atoms system
      const reactantXyz = '''33
Reactant: 4-aminophenol + acetic anhydride
C -2.41 1.25 0.01
C -1.04 1.28 0.01
C -0.31 0.05 0.00
C -1.01 -1.18 -0.01
C -2.38 -1.21 -0.01
C -3.10 0.02 0.00
N 1.07 0.02 0.01
H 1.54 0.88 0.01
H 1.53 -0.85 0.01
O -4.45 0.00 -0.01
H -4.84 -0.86 -0.01
H -2.96 2.19 0.02
H -0.52 2.22 0.02
H -0.47 -2.13 -0.02
H -2.91 -2.16 -0.02
C 3.20 1.20 0.00
O 3.00 2.38 0.00
C 4.50 0.45 0.00
H 4.55 -0.15 0.89
H 4.55 -0.15 -0.89
H 5.30 1.20 0.00
O 2.10 0.35 0.00
C 2.10 -1.05 0.00
O 1.15 -1.78 0.00
C 3.45 -1.70 0.00
H 3.45 -2.35 0.89
H 3.45 -2.35 -0.89
H 4.25 -0.95 0.00
H 0.0 0.0 0.0
H 0.0 0.0 0.0
H 0.0 0.0 0.0
H 0.0 0.0 0.0
H 0.0 0.0 0.0
''';

      const productXyz = '''33
Product: Paracetamol + acetic acid
C -2.45 1.22 0.01
C -1.08 1.25 0.01
C -0.35 0.02 0.00
C -1.05 -1.21 -0.01
C -2.42 -1.24 -0.01
C -3.14 -0.01 0.00
N 1.03 0.00 0.01
H 1.52 -0.88 0.01
O -4.49 -0.03 -0.01
H -4.88 -0.89 -0.01
H -3.00 2.16 0.02
H -0.56 2.19 0.02
H -0.51 -2.16 -0.02
H -2.95 -2.19 -0.02
C 1.85 1.12 0.01
O 1.35 2.24 0.01
C 3.35 0.95 0.01
H 3.70 0.42 0.90
H 3.70 0.42 -0.88
H 3.80 1.95 0.01
O 4.20 -1.10 0.00
C 4.20 -2.35 0.00
O 3.25 -3.10 0.00
C 5.55 -3.00 0.00
H 5.55 -3.65 0.89
H 5.55 -3.65 -0.89
H 6.35 -2.25 0.00
H 3.25 -0.65 0.00
H 0.0 0.0 0.0
H 0.0 0.0 0.0
H 0.0 0.0 0.0
H 0.0 0.0 0.0
H 0.0 0.0 0.0
''';

      final result = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 18.4,
      );

      // Verify trajectory frames
      expect(result.trajectoryFrames.length, 21);
      expect(result.energyProfile.length, 21);
      expect(result.energyProfileEv.length, 21);
      expect(result.maxEnergyIndex, 10);
      expect(result.activationEnergyKcalMol, 18.4);

      // Verify imaginary frequency (negative frequency for TS saddle point)
      expect(result.vibrationalModes.isNotEmpty, true);
      expect(result.vibrationalModes.first.frequency, lessThan(0.0));
      expect(result.vibrationalModes.first.vectors.length, greaterThan(0));

      // Verify each trajectory frame has 33 atoms and can be parsed
      for (int i = 0; i < result.trajectoryFrames.length; i++) {
        final frame = result.trajectoryFrames[i];
        final atoms = MoleculeParser.tryParse(frame, 'xyz');
        expect(atoms.length, 33, reason: 'Frame $i should contain 33 atoms');
      }

      // Verify peak energy occurs around maxEnergyIndex
      final maxE = result.energyProfile.reduce((a, b) => a > b ? a : b);
      expect(result.energyProfile[10], closeTo(maxE, 0.5));
    });

    test('reconstructs cleanly even with very large 100+ atom reaction paths', () {
      final rSb = StringBuffer()..writeln('100')..writeln('Reactant Large Polymer');
      final pSb = StringBuffer()..writeln('100')..writeln('Product Large Polymer');

      for (int i = 0; i < 100; i++) {
        final x = (i % 10) * 1.5;
        final y = ((i ~/ 10) % 5) * 1.5;
        final z = (i ~/ 50) * 1.5;
        rSb.writeln('C $x $y $z');
        pSb.writeln('C ${x + 0.3} ${y - 0.2} ${z + 0.4}');
      }

      final result = TransformerReactionCompressor.process(
        reactantXyz: rSb.toString(),
        productXyz: pSb.toString(),
        referenceEa: 24.0,
      );

      expect(result.trajectoryFrames.length, 21);
      expect(result.vibrationalModes.first.vectors.length, 100);
      final frameMidAtoms = MoleculeParser.tryParse(result.trajectoryFrames[10], 'xyz');
      expect(frameMidAtoms.length, 100);
    });

    test('strictly normalizes ground-state reactant energy to zero', () {
      const r = '2\nReactant\nC 0 0 0\nO 0 0 1.2\n';
      const p = '2\nProduct\nC 0 0 0\nO 0 0 1.4\n';
      final res = TransformerReactionCompressor.process(
        reactantXyz: r,
        productXyz: p,
        referenceEa: 15.0,
      );

      expect(res.energyProfile[0], 0.0);
      expect(res.energyProfileEv[0], 0.0);
      expect(res.energyProfile[res.maxEnergyIndex], closeTo(15.0, 1.5));
    });

    test('accurately pairs atoms even when product atom ordering is permuted', () {
      // Reactant: C1 at origin, C2 at x=2
      const r = '2\nReactant\nC 0.0 0.0 0.0\nC 2.0 0.0 0.0\n';
      // Product: permuted order (C2 first at x=2.1, C1 second at x=0.1)
      const p = '2\nProduct\nC 2.1 0.0 0.0\nC 0.1 0.0 0.0\n';
      final res = TransformerReactionCompressor.process(
        reactantXyz: r,
        productXyz: p,
        referenceEa: 12.0,
      );

      // In the middle frame (t=0.5), atoms should be near x=0.05 and x=2.05, NOT colliding at x=1.05!
      final midAtoms = MoleculeParser.tryParse(res.trajectoryFrames[10], 'xyz');
      expect(midAtoms.length, 2);
      final xCoords = midAtoms.map((a) => a.x).toList()..sort();
      expect(xCoords[0], closeTo(0.05, 0.2));
      expect(xCoords[1], closeTo(2.05, 0.2));
    });
  });
}
