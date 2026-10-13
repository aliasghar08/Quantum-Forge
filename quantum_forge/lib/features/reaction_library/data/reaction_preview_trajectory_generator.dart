import 'dart:math' as math;
import 'package:quantum_forge/core/utils/xyz_parser.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

/// Generates smooth, research-grade schematic trajectory paths and Eckart energy profiles
/// for reaction templates. Used by both TemplateDetailScreen and PublicationDetailsScreen.
class ReactionPreviewTrajectoryGenerator {
  /// Number of frames in the preview path.
  static const int previewFrames = 121;

  /// Frame index of the transition state (middle frame).
  static const int tsFrame = previewFrames ~/ 2;

  /// Playback rate for the preview (4 FPS).
  static const int previewFps = 4;

  /// Radial distance, in ångström, that a phantom atom is displaced from its
  /// matched partner's position.
  static const double phantomEjectionDistance = 25.0;

  /// Generates [previewFrames] XYZ documents interpolated between the reactant and
  /// product geometries with cosine easing and radial phantom atom padding.
  static List<String> generateTrajectory(ReactionTemplate template) {
    final reactant = XyzParser.parse(template.reactantXyz);
    final product = XyzParser.parse(template.productXyz);

    if (reactant.isEmpty || product.isEmpty) {
      return [template.reactantXyz, template.productXyz];
    }

    final int maxLen = math.max(reactant.length, product.length);

    final List<Atom> rAtoms = _padToLength(
      reactant,
      maxLen,
      unmatchedSource: product,
    );
    final List<Atom> pAtoms = _padToLength(
      product,
      maxLen,
      unmatchedSource: reactant,
    );

    return List<String>.generate(previewFrames, (frame) {
      final double t = frame / (previewFrames - 1);
      final double s = 0.5 * (1.0 - math.cos(math.pi * t));

      final buffer = StringBuffer()
        ..writeln(rAtoms.length)
        ..writeln(
          '${template.name} — frame ${frame + 1}/$previewFrames',
        );

      for (var a = 0; a < rAtoms.length; a++) {
        final r = rAtoms[a];
        final p = pAtoms[a];
        buffer.writeln(
          '${r.symbol.padRight(2)} '
          '${(r.x + (p.x - r.x) * s).toStringAsFixed(4).padLeft(10)} '
          '${(r.y + (p.y - r.y) * s).toStringAsFixed(4).padLeft(10)} '
          '${(r.z + (p.z - r.z) * s).toStringAsFixed(4).padLeft(10)}',
        );
      }
      return buffer.toString();
    });
  }

  static List<Atom> _padToLength(
    List<Atom> atoms,
    int targetLength, {
    required List<Atom> unmatchedSource,
  }) {
    if (atoms.length == targetLength) return atoms;
    if (atoms.length > targetLength) {
      return atoms.sublist(0, targetLength);
    }

    final padded = List<Atom>.from(atoms);

    final double cx = atoms.fold(0.0, (a, at) => a + at.x) / atoms.length;
    final double cy = atoms.fold(0.0, (a, at) => a + at.y) / atoms.length;
    final double cz = atoms.fold(0.0, (a, at) => a + at.z) / atoms.length;

    final unmatched = unmatchedSource.sublist(atoms.length, targetLength);

    for (final phantom in unmatched) {
      final double dx = phantom.x - cx;
      final double dy = phantom.y - cy;
      final double dz = phantom.z - cz;
      final double r = math.sqrt(dx * dx + dy * dy + dz * dz);

      final double unitX = r > 0.1 ? dx / r : 1.0;
      final double unitY = r > 0.1 ? dy / r : 0.0;
      final double unitZ = r > 0.1 ? dz / r : 0.0;

      padded.add(Atom(
        phantom.symbol,
        phantom.x + unitX * phantomEjectionDistance,
        phantom.y + unitY * phantomEjectionDistance,
        phantom.z + unitZ * phantomEjectionDistance,
        phantom.color,
        phantom.radius,
        phantom.covalentRadius,
      ));
    }
    return padded;
  }

  /// Generates the analytic Eckart energy profile for a given activation energy.
  static List<double> generateEnergyProfile(double ea) {
    const double beta = 6.0;
    final double dH = -ea * 0.3;

    final double a = ea - dH / 2;
    final double b = dH / 2;

    return List<double>.generate(previewFrames, (i) {
      final double t = i / (previewFrames - 1);
      final double x = beta * (t - 0.5);

      final double ex = math.exp(x);
      final double emx = math.exp(-x);
      final double coshX = (ex + emx) / 2.0;
      final double sechSq = 1.0 / (coshX * coshX);
      final double tanhX = (ex - emx) / (ex + emx);

      return a * sechSq + b * tanhX + dH / 2;
    });
  }
}
