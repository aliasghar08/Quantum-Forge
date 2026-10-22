import 'package:quantum_forge/core/utils/xyz_parser.dart';

class TrajectoryInterpolator {
  /// Smoothly interpolates an XYZ trajectory so it has at least [minFrames] frames.
  ///
  /// If [frames] already has >= [minFrames] or < 2 frames, it is returned as-is.
  static List<String> interpolate(
    List<String> frames, {
    int minFrames = 40,
  }) {
    if (frames.length < 2 || frames.length >= minFrames) {
      return frames;
    }

    // Parse each frame into atoms
    final parsedFrames = <List<Atom>>[];
    for (final f in frames) {
      final atoms = XyzParser.parse(f);
      if (atoms.isNotEmpty) {
        parsedFrames.add(atoms);
      }
    }

    if (parsedFrames.length < 2) return frames;

    final originalCount = parsedFrames.length;
    // Calculate how many sub-steps per segment to reach at least minFrames
    final segments = originalCount - 1;
    final neededSubSteps = ((minFrames - originalCount) / segments).ceil();
    final stepsPerSegment = neededSubSteps + 1;

    final interpolatedXyz = <String>[];

    for (int i = 0; i < segments; i++) {
      final fA = parsedFrames[i];
      final fB = parsedFrames[i + 1];

      // If atom counts differ between frames, avoid invalid index access
      final atomCount = fA.length < fB.length ? fA.length : fB.length;

      for (int step = 0; step < stepsPerSegment; step++) {
        // Only include the last endpoint on the very last segment
        if (i < segments - 1 && step == stepsPerSegment) continue;

        final t = step / stepsPerSegment.toDouble();
        // Smooth Hermite / smoothstep blending: 3t^2 - 2t^3
        final smoothT = t * t * (3.0 - 2.0 * t);

        final sb = StringBuffer();
        sb.writeln(atomCount);
        sb.writeln('Interpolated Frame (${(i * stepsPerSegment + step + 1)})');

        for (int a = 0; a < atomCount; a++) {
          final atomA = fA[a];
          final atomB = fB[a];

          final x = atomA.x + (atomB.x - atomA.x) * smoothT;
          final y = atomA.y + (atomB.y - atomA.y) * smoothT;
          final z = atomA.z + (atomB.z - atomA.z) * smoothT;

          sb.writeln(
            '${atomA.symbol} ${x.toStringAsFixed(5)} ${y.toStringAsFixed(5)} ${z.toStringAsFixed(5)}',
          );
        }

        interpolatedXyz.add(sb.toString());
      }
    }

    // Add the final frame
    interpolatedXyz.add(frames.last);

    return interpolatedXyz;
  }

  /// Also interpolates the energy profile to match the interpolated trajectory length.
  static List<double>? interpolateEnergies(
    List<double>? energies, {
    required int targetLength,
  }) {
    if (energies == null || energies.length < 2 || energies.length >= targetLength) {
      return energies;
    }

    final result = <double>[];
    final originalCount = energies.length;
    for (int i = 0; i < targetLength; i++) {
      final norm = i / (targetLength - 1).toDouble();
      final origIdx = norm * (originalCount - 1);
      final lowIdx = origIdx.floor();
      final highIdx = (lowIdx + 1).clamp(0, originalCount - 1);
      final frac = origIdx - lowIdx;
      final smoothFrac = frac * frac * (3.0 - 2.0 * frac);

      final val = energies[lowIdx] + (energies[highIdx] - energies[lowIdx]) * smoothFrac;
      result.add(val);
    }
    return result;
  }
}
