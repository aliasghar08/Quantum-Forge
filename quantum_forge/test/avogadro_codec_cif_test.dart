// ============================================================================
// Avogadro Codec — CIF format tests
// ============================================================================

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/utils/avogadro_codec.dart';
import 'package:quantum_forge/core/utils/avogadro_interchange.dart';
import 'package:quantum_forge/core/utils/molecular.dart';

void main() {
  group('CIF format decoding (fromCif)', () {
    test('round-trips a known structure using Cartesian coordinates', () {
      final atoms = [
        atomFor('C', 0.000, 0.000, 0.000),
        atomFor('H', 0.629, 0.629, 0.629),
        atomFor('H', -0.629, -0.629, 0.629),
      ];
      final structure = AvogadroStructure(
        title: 'Methane fragment',
        atoms: atoms,
        bonds: AvogadroInterchange.perceiveBonds(atoms),
      );

      final cifText = AvogadroInterchange.toCif(structure);
      expect(cifText, contains('data_methane-fragment'));
      expect(cifText, contains('_atom_site_Cartn_x'));

      final decoded = AvogadroCodec.fromCif(cifText);
      expect(decoded.title, 'methane-fragment');
      expect(decoded.atomCount, 3);
      expect(decoded.atoms[0].symbol, 'C');
      expect(decoded.atoms[1].symbol, 'H');
      expect(decoded.atoms[0].x, closeTo(0.000, 0.0001));
      expect(decoded.atoms[1].x, closeTo(0.629, 0.0001));
      expect(decoded.bondCount, 2);
    });

    test('converts fractional coordinates to Cartesian with orthogonal cell', () {
      const cif = '''
data_orthogonal_test
_cell_length_a  10.0000
_cell_length_b  20.0000
_cell_length_c  30.0000
_cell_angle_alpha 90.00
_cell_angle_beta  90.00
_cell_angle_gamma 90.00

loop_
  _atom_site_label
  _atom_site_type_symbol
  _atom_site_fract_x
  _atom_site_fract_y
  _atom_site_fract_z
  C1 C 0.5000 0.2500 0.1000
''';

      final decoded = AvogadroCodec.fromCif(cif);
      expect(decoded.atomCount, 1);
      final atom = decoded.atoms.first;
      expect(atom.symbol, 'C');
      expect(atom.x, closeTo(5.000, 0.001));   // 10 * 0.5
      expect(atom.y, closeTo(5.000, 0.001));   // 20 * 0.25
      expect(atom.z, closeTo(3.000, 0.001));   // 30 * 0.1
    });

    test('converts fractional coordinates to Cartesian with monoclinic cell (beta = 105)', () {
      const cif = '''
data_monoclinic_test
_cell_length_a  10.0000
_cell_length_b  10.0000
_cell_length_c  10.0000
_cell_angle_alpha 90.00
_cell_angle_beta  105.00
_cell_angle_gamma 90.00

loop_
  _atom_site_label
  _atom_site_type_symbol
  _atom_site_fract_x
  _atom_site_fract_y
  _atom_site_fract_z
  Fe1 Fe 0.0000 0.0000 1.0000
''';

      final decoded = AvogadroCodec.fromCif(cif);
      expect(decoded.atomCount, 1);
      final atom = decoded.atoms.first;
      expect(atom.symbol, 'Fe');

      // For alpha=90, gamma=90, beta=105:
      // x = a*xf + c*cos(105)*zf = 10 * cos(105 deg)
      // y = b*yf = 0
      // z = c*sin(105)*zf = 10 * sin(105 deg)
      final expectedX = 10.0 * math.cos(105.0 * math.pi / 180.0);
      final expectedZ = 10.0 * math.sin(105.0 * math.pi / 180.0);

      expect(atom.x, closeTo(expectedX, 0.001));
      expect(atom.y, closeTo(0.000, 0.001));
      expect(atom.z, closeTo(expectedZ, 0.001));
    });

    test('handles standard uncertainties in parentheses (e.g. 5.4309(2))', () {
      const cif = '''
data_uncertainty_test
_cell_length_a  5.4309(2)
_cell_length_b  5.4309(2)
_cell_length_c  5.4309(2)
_cell_angle_alpha 90.00(1)
_cell_angle_beta  90.00(1)
_cell_angle_gamma 90.00(1)

loop_
  _atom_site_label
  _atom_site_type_symbol
  _atom_site_fract_x
  _atom_site_fract_y
  _atom_site_fract_z
  Si1 Si 0.1250(3) 0.1250(3) 0.1250(3)
''';

      final decoded = AvogadroCodec.fromCif(cif);
      expect(decoded.atomCount, 1);
      final atom = decoded.atoms.first;
      expect(atom.symbol, 'Si');
      expect(atom.x, closeTo(5.4309 * 0.125, 0.001));
    });

    test('auto-sniffs format as cif in resolveFormat', () {
      const cif = 'data_test\nloop_\n_atom_site_label\n_atom_site_Cartn_x\n';
      expect(AvogadroCodec.resolveFormat(cif, null), 'cif');
      expect(AvogadroCodec.resolveFormat('anything', 'cif'), 'cif');
      expect(AvogadroCodec.resolveFormat('anything', 'mmcif'), 'cif');
    });

    test('throws AvogadroCodecException on invalid or malformed CIF payloads', () {
      expect(
        () => AvogadroCodec.fromCif(''),
        throwsA(isA<AvogadroCodecException>().having((e) => e.message, 'message', contains('empty'))),
      );

      expect(
        () => AvogadroCodec.fromCif('data_only\n_audit_creation_date 2026-10-02\n'),
        throwsA(isA<AvogadroCodecException>().having((e) => e.message, 'message', contains('No _atom_site loop'))),
      );

      expect(
        () => AvogadroCodec.fromCif('''
data_no_coords
loop_
  _atom_site_label
  _atom_site_type_symbol
  C1 C
'''),
        throwsA(isA<AvogadroCodecException>().having((e) => e.message, 'message', contains('No coordinate columns'))),
      );
    });
  });
}
