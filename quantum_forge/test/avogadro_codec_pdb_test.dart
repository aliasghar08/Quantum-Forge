// ============================================================================
// Avogadro Codec — PDB format tests
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/utils/avogadro_codec.dart';
import 'package:quantum_forge/core/utils/avogadro_interchange.dart';
import 'package:quantum_forge/core/utils/molecular.dart';

void main() {
  group('PDB format decoding (fromPdb)', () {
    test('round-trips a known structure (methane)', () {
      final atoms = [
        atomFor('C', 0.000, 0.000, 0.000),
        atomFor('H', 0.629, 0.629, 0.629),
        atomFor('H', -0.629, -0.629, 0.629),
        atomFor('H', -0.629, 0.629, -0.629),
        atomFor('H', 0.629, -0.629, -0.629),
      ];
      final structure = AvogadroStructure(
        title: 'Methane CH4',
        atoms: atoms,
        bonds: AvogadroInterchange.perceiveBonds(atoms),
      );

      final pdbText = AvogadroInterchange.toPdb(structure);
      expect(pdbText, contains('TITLE     Methane CH4'));
      expect(pdbText, contains('ATOM      1  C   MOL A   1'));
      expect(pdbText, contains('CONECT    1    2    3    4    5'));

      final decoded = AvogadroCodec.fromPdb(pdbText);
      expect(decoded.title, 'Methane CH4');
      expect(decoded.atomCount, 5);
      expect(decoded.atoms[0].symbol, 'C');
      expect(decoded.atoms[1].symbol, 'H');
      expect(decoded.atoms[0].x, closeTo(0.000, 0.001));
      expect(decoded.atoms[1].x, closeTo(0.629, 0.001));
      expect(decoded.bondsFromSource, isTrue);
      expect(decoded.bondCount, 4);
    });

    test('reads element strictly from columns 77-78 over atom-name column', () {
      // Line with atom name "CA  " (like alpha carbon) but element column 77-78 is " C" -> Carbon
      // Line with atom name "CA  " and element column 77-78 is "CA" -> Calcium
      const pdb = '''
TITLE     Carbon vs Calcium test
ATOM      1  CA  ALA A   1       1.000   2.000   3.000  1.00  0.00           C
ATOM      2  CA  CAL A   2       4.000   5.000   6.000  1.00  0.00          CA
END
''';

      final decoded = AvogadroCodec.fromPdb(pdb);
      expect(decoded.atomCount, 2);
      expect(decoded.atoms[0].symbol, 'C', reason: 'Col 77-78 " C" must be Carbon despite atom name "CA"');
      expect(decoded.atoms[1].symbol, 'Ca', reason: 'Col 77-78 "CA" must be Calcium');
    });

    test('falls back to atom-name column when columns 77-78 are blank', () {
      const pdb = '''
ATOM      1  CA  ALA A   1       1.000   2.000   3.000  1.00  0.00
END
''';
      final decoded = AvogadroCodec.fromPdb(pdb);
      expect(decoded.atomCount, 1);
      expect(decoded.atoms[0].symbol, 'Ca');
    });

    test('uses CONECT records when present and perceives when absent', () {
      // 1. With CONECT:
      const pdbWithConect = '''
ATOM      1  C   MOL A   1       0.000   0.000   0.000  1.00  0.00           C
ATOM      2  H   MOL A   1       1.090   0.000   0.000  1.00  0.00           H
CONECT    1    2
END
''';
      final withConect = AvogadroCodec.fromPdb(pdbWithConect);
      expect(withConect.bondsFromSource, isTrue);
      expect(withConect.bondCount, 1);
      expect(withConect.bonds.first.a, 0);
      expect(withConect.bonds.first.b, 1);

      // 2. Without CONECT:
      const pdbWithoutConect = '''
ATOM      1  C   MOL A   1       0.000   0.000   0.000  1.00  0.00           C
ATOM      2  H   MOL A   1       1.090   0.000   0.000  1.00  0.00           H
END
''';
      final withoutConect = AvogadroCodec.fromPdb(pdbWithoutConect);
      expect(withoutConect.bondsFromSource, isFalse);
      expect(withoutConect.bondCount, 1);
    });

    test('handles altLoc by keeping the first occurrence and dropping rest', () {
      const pdbAltLoc = '''
ATOM      1  N  AALA A   1       1.000   2.000   3.000  0.60 10.00           N
ATOM      1  N  BALA A   1       1.200   2.100   3.100  0.40 12.00           N
ATOM      2  CA AALA A   1       2.000   3.000   4.000  0.60 10.00           C
ATOM      2  CA BALA A   1       2.100   3.100   4.200  0.40 12.00           C
END
''';
      final decoded = AvogadroCodec.fromPdb(pdbAltLoc);
      expect(decoded.atomCount, 2);
      expect(decoded.atoms[0].x, closeTo(1.000, 0.001));
      expect(decoded.atoms[1].x, closeTo(2.000, 0.001));
    });

    test('auto-sniffs format as pdb in resolveFormat', () {
      const pdb = 'ATOM      1  C   MOL A   1       0.000   0.000   0.000  1.00  0.00           C\nEND';
      expect(AvogadroCodec.resolveFormat(pdb, null), 'pdb');
      expect(AvogadroCodec.resolveFormat('anything', 'pdb'), 'pdb');
      expect(AvogadroCodec.resolveFormat('anything', 'ent'), 'pdb');
    });

    test('throws AvogadroCodecException on invalid or malformed payloads', () {
      expect(
        () => AvogadroCodec.fromPdb(''),
        throwsA(isA<AvogadroCodecException>().having((e) => e.message, 'message', contains('empty'))),
      );

      expect(
        () => AvogadroCodec.fromPdb('TITLE Only\nREMARK 200\nEND\n'),
        throwsA(isA<AvogadroCodecException>().having((e) => e.message, 'message', contains('No ATOM'))),
      );

      expect(
        () => AvogadroCodec.fromPdb('ATOM      1  C   MOL A   1   short'),
        throwsA(isA<AvogadroCodecException>().having((e) => e.message, 'message', contains('shorter than 54'))),
      );

      expect(
        () => AvogadroCodec.fromPdb('ATOM      1  C   MOL A   1       abcde   fghij   klmno  1.00  0.00           C'),
        throwsA(isA<AvogadroCodecException>().having((e) => e.message, 'message', contains('Malformed coordinates'))),
      );
    });
  });
}
