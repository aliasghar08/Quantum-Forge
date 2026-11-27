import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:quantum_forge/core/utils/xyz_parser.dart';
import 'package:quantum_forge/core/widgets/ngl/avogadro_geometry.dart';
import 'package:quantum_forge/core/widgets/ngl/avogadro_sdf.dart';

/// Input parameters for trajectory background calculation.
class TrajectoryIsolateInput {
  final String reactionId;
  final String reactantXyz;
  final String productXyz;
  final String templateName;
  final double referenceEa;
  final int frameCount;

  const TrajectoryIsolateInput({
    required this.reactionId,
    required this.reactantXyz,
    required this.productXyz,
    required this.templateName,
    required this.referenceEa,
    this.frameCount = 121,
  });
}

/// Output computed bundle containing 121 frames, static bonds, energy profile, and multi-model SDF.
class TrajectoryBundle {
  final String reactionId;
  final List<String> frames;
  final List<double> energyProfile;
  final int tsFrame;
  final String? trajectorySdf;
  final List<PerceivedBond> staticBonds;
  final int reactantFragments;
  final int productFragments;

  const TrajectoryBundle({
    required this.reactionId,
    required this.frames,
    required this.energyProfile,
    required this.tsFrame,
    this.trajectorySdf,
    this.staticBonds = const [],
    this.reactantFragments = 1,
    this.productFragments = 1,
  });
}

/// Standalone top-level isolate computation function.
/// Can be invoked with `compute(computeTrajectoryInIsolate, input)`.
TrajectoryBundle computeTrajectoryInIsolate(TrajectoryIsolateInput input) {
  final reactant = XyzParser.parse(input.reactantXyz);
  final product = XyzParser.parse(input.productXyz);

  final frameCount = input.frameCount <= 0 ? 121 : input.frameCount;
  final tsFrame = frameCount ~/ 2;

  // Energy profile (Eckart)
  const double beta = 6.0;
  final double dH = -input.referenceEa * 0.3;
  final double a = input.referenceEa - dH / 2;
  final double b = dH / 2;

  final energyProfile = List<double>.generate(frameCount, (i) {
    final double t = frameCount <= 1 ? 0.0 : i / (frameCount - 1);
    final double x = beta * (t - 0.5);
    final double ex = math.exp(x);
    final double emx = math.exp(-x);
    final double coshX = (ex + emx) / 2.0;
    final double sechSq = 1.0 / (coshX * coshX);
    final double tanhX = (ex - emx) / (ex + emx);
    return a * sechSq + b * tanhX + dH / 2;
  });

  if (reactant.isEmpty || product.isEmpty) {
    final fallbackFrames = [
      if (input.reactantXyz.isNotEmpty) input.reactantXyz,
      if (input.productXyz.isNotEmpty) input.productXyz,
    ];
    return TrajectoryBundle(
      reactionId: input.reactionId,
      frames: fallbackFrames.isNotEmpty ? fallbackFrames : const [''],
      energyProfile: energyProfile,
      tsFrame: tsFrame,
    );
  }

  final int maxLen = math.max(reactant.length, product.length);
  final List<Atom> rAtoms = _padAtoms(reactant, maxLen, unmatchedSource: product);
  final List<Atom> pAtoms = _padAtoms(product, maxLen, unmatchedSource: reactant);

  final frames = List<String>.generate(frameCount, (frame) {
    final double t = frameCount <= 1 ? 0.0 : frame / (frameCount - 1);
    final double s = 0.5 * (1.0 - math.cos(math.pi * t));

    final buffer = StringBuffer()
      ..writeln(rAtoms.length)
      ..writeln('${input.templateName} — frame ${frame + 1}/$frameCount');

    for (var i = 0; i < rAtoms.length; i++) {
      final r = rAtoms[i];
      final p = pAtoms[i];
      buffer.writeln(
        '${r.symbol.padRight(2)} '
        '${(r.x + (p.x - r.x) * s).toStringAsFixed(4).padLeft(10)} '
        '${(r.y + (p.y - r.y) * s).toStringAsFixed(4).padLeft(10)} '
        '${(r.z + (p.z - r.z) * s).toStringAsFixed(4).padLeft(10)}',
      );
    }
    return buffer.toString();
  });

  // Perceive static bonds & fragments from Frame 1
  final staticBonds = AvogadroBondPerception.perceive(rAtoms);
  final reactantFrags = AvogadroBondPerception.fragmentCount(rAtoms.length, staticBonds);
  final productBonds = AvogadroBondPerception.perceive(pAtoms);
  final productFrags = AvogadroBondPerception.fragmentCount(pAtoms.length, productBonds);

  // Pre-generate parsed atoms per frame for multi-model SDF
  final allFrameAtoms = <List<Atom>>[];
  for (var frame = 0; frame < frameCount; frame++) {
    final double t = frameCount <= 1 ? 0.0 : frame / (frameCount - 1);
    final double s = 0.5 * (1.0 - math.cos(math.pi * t));
    final frameAtoms = List<Atom>.generate(rAtoms.length, (i) {
      final r = rAtoms[i];
      final p = pAtoms[i];
      return Atom(
        r.symbol,
        r.x + (p.x - r.x) * s,
        r.y + (p.y - r.y) * s,
        r.z + (p.z - r.z) * s,
        r.color,
        r.radius,
        r.covalentRadius,
      );
    });
    allFrameAtoms.add(frameAtoms);
  }

  final trajectorySdf = AvogadroSdfWriter.writeTrajectory(allFrameAtoms, staticBonds);

  return TrajectoryBundle(
    reactionId: input.reactionId,
    frames: frames,
    energyProfile: energyProfile,
    tsFrame: tsFrame,
    trajectorySdf: trajectorySdf,
    staticBonds: staticBonds,
    reactantFragments: reactantFrags,
    productFragments: productFrags,
  );
}

List<Atom> _padAtoms(
  List<Atom> atoms,
  int targetLength, {
  required List<Atom> unmatchedSource,
}) {
  if (atoms.length == targetLength) return atoms;
  if (atoms.length > targetLength) return atoms.sublist(0, targetLength);

  const double phantomEjectionDistance = 25.0;
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

/// Service providing isolate computation + in-memory LRU cache (max 12 trajectories).
class TrajectoryIsolateService {
  TrajectoryIsolateService._();
  static final TrajectoryIsolateService instance = TrajectoryIsolateService._();

  static const int _maxLruEntries = 12;
  final Map<String, TrajectoryBundle> _lruCache = {};
  final Map<String, Future<TrajectoryBundle>> _inFlight = {};

  bool hasCached(String reactionId) => _lruCache.containsKey(reactionId);

  TrajectoryBundle? getCached(String reactionId) {
    final cached = _lruCache[reactionId];
    if (cached != null) {
      // Refresh LRU order
      _lruCache.remove(reactionId);
      _lruCache[reactionId] = cached;
    }
    return cached;
  }

  Future<TrajectoryBundle> getOrCompute(TrajectoryIsolateInput input) async {
    final cached = getCached(input.reactionId);
    if (cached != null) return cached;

    final inFlightFuture = _inFlight[input.reactionId];
    if (inFlightFuture != null) return inFlightFuture;

    final future = _runCompute(input);
    _inFlight[input.reactionId] = future;
    try {
      final result = await future;
      _cachePut(input.reactionId, result);
      return result;
    } finally {
      _inFlight.remove(input.reactionId);
    }
  }

  Future<TrajectoryBundle> _runCompute(TrajectoryIsolateInput input) async {
    // On web or in unit tests, compute() falls back safely or runs on worker.
    try {
      return await compute(computeTrajectoryInIsolate, input);
    } catch (_) {
      // Fallback to direct synchronous execution if compute is unavailable
      return computeTrajectoryInIsolate(input);
    }
  }

  void _cachePut(String key, TrajectoryBundle bundle) {
    if (_lruCache.length >= _maxLruEntries) {
      final oldestKey = _lruCache.keys.first;
      _lruCache.remove(oldestKey);
    }
    _lruCache[key] = bundle;
  }

  void clearCache() {
    _lruCache.clear();
    _inFlight.clear();
  }
}
