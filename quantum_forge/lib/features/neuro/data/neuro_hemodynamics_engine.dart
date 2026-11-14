// ============================================================================
// NeuroLab 3D: Brain, Neurovascular & Spinal Cord — Neuro-Physiology Engine
// ----------------------------------------------------------------------------
// Mathematical 500 Hz waveform synthesis for:
// 1. Dual-Channel Scalp EEG (Left Fp1-C3 vs. Right Fp2-C4)
// 2. Intraoperative SSEP (Somatosensory Evoked Potential N20/P25)
// 3. Transcranial MEP (Motor Evoked Potential CMAP)
// 4. Invasive Intracranial Pressure (ICP) with P1/P2/P3 pulse morphology
// 5. Cerebral Perfusion Pressure (CPP = MAP - ICP) with Cushing reflex
// ============================================================================

import 'dart:math' as math;
import 'neuro_pathology_models.dart';

class NeuroHemodynamicsEngine {
  NeuroHemodynamicsEngine._();

  /// Synthesizes Scalp EEG sample (uV) for Left (Fp1-C3) or Right (Fp2-C4)
  /// at time [timeSeconds] based on clinical pattern [pattern].
  static double computeEegSample({
    required double timeSeconds,
    required bool isLeftHemisphere,
    required EegPattern pattern,
    bool isThrombectomized = false,
  }) {
    final t = timeSeconds;

    switch (pattern) {
      case EegPattern.normalAlpha:
        // Symmetrical 10 Hz alpha rhythm with minor 18 Hz beta harmonics (30–45 uV)
        final alpha = 38.0 * math.sin(t * 10.0 * 2.0 * math.pi);
        final beta = 6.0 * math.sin(t * 19.5 * 2.0 * math.pi + 0.4);
        final background = 4.0 * math.sin(t * 5.2 * 2.0 * math.pi);
        return alpha + beta + background;

      case EegPattern.focalDeltaSlowing:
        if (isLeftHemisphere && !isThrombectomized) {
          // Left M1 stroke: prominent focal polymorphic delta slowing (1.5 Hz, 85 uV)
          final delta = 75.0 * math.sin(t * 1.5 * 2.0 * math.pi);
          final subharmonic = 25.0 * math.sin(t * 0.8 * 2.0 * math.pi + 0.8);
          final noise = 8.0 * math.cos(t * 3.4 * 2.0 * math.pi);
          return delta + subharmonic + noise;
        } else {
          // Contralateral preserved hemisphere: baseline 9.5 Hz alpha
          return 36.0 * math.sin(t * 9.5 * 2.0 * math.pi) + 5.0 * math.sin(t * 18.0 * 2.0 * math.pi);
        }

      case EegPattern.spikeAndWave:
        // Generalized 3 Hz spike-and-wave discharges (Status Epilepticus)
        // 3 Hz period = 333 ms
        final phase = (t * 3.0) % 1.0;
        if (phase < 0.12) {
          // Sharp High-Voltage Spike (+180 uV, 40 ms)
          final spikeTau = phase / 0.12;
          return 180.0 * math.sin(spikeTau * math.pi) - 20.0;
        } else if (phase < 0.70) {
          // Broad High-Voltage Dome Slow Wave (-125 uV, 190 ms)
          final waveTau = (phase - 0.12) / 0.58;
          return -125.0 * math.sin(waveTau * math.pi);
        } else {
          // Short inter-discharge interval
          return 10.0 * math.sin(phase * 12.0 * math.pi);
        }

      case EegPattern.burstSuppression:
        // 2 seconds of high-voltage chaotic spikes followed by 3 seconds of flatline
        final burstCycle = t % 5.0;
        if (burstCycle < 1.8) {
          return 90.0 * math.sin(t * 22.0 * math.pi) * math.cos(t * 7.5 * math.pi);
        } else {
          // Isoelectric suppression (< 5 uV)
          return 2.5 * math.sin(t * 30.0 * math.pi);
        }
    }
  }

  /// Synthesizes Cortical Somatosensory Evoked Potential (SSEP) N20/P25 sample (uV)
  /// Triggers an electrical sweep every 500 ms (2 Hz stimulation rate).
  static double computeSsepSample({
    required double timeSeconds,
    required SpinalSyndrome syndrome,
    bool isLeftSide = true,
  }) {
    // 2 Hz stimulation rate -> 500 ms cycle (0.0 to 0.5s)
    final cycleTimeMs = (timeSeconds % 0.5) * 1000.0;

    // Amplitude attenuation factor based on spinal syndrome
    double ampScale = 1.0;
    double latencyShiftMs = 0.0;

    if (syndrome == SpinalSyndrome.brownSequard) {
      // Ipsilateral dorsal column injury -> >65% amplitude drop
      if (isLeftSide) {
        ampScale = 0.25;
        latencyShiftMs = 2.5;
      }
    } else if (syndrome == SpinalSyndrome.subacuteCombined) {
      // Bilateral demyelination -> latency prolonged (>24 ms) and attenuated
      ampScale = 0.40;
      latencyShiftMs = 5.0;
    } else if (syndrome == SpinalSyndrome.anteriorCord) {
      // Anterior cord syndrome spares dorsal columns -> normal SSEP
      ampScale = 0.95;
    }

    double v = 0.0;
    final n20Time = 20.0 + latencyShiftMs;
    final p25Time = 25.0 + latencyShiftMs;

    // Stimulation artifact at 0–3 ms
    if (cycleTimeMs >= 1.0 && cycleTimeMs <= 3.5) {
      final tau = (cycleTimeMs - 1.0) / 2.5;
      v = 8.0 * math.sin(tau * math.pi);
    }
    // N20 cortical peak (negative upward in clinical EEG convention, here plotted as -2.8 uV)
    else if (cycleTimeMs >= (n20Time - 3.0) && cycleTimeMs <= (n20Time + 2.5)) {
      final tau = (cycleTimeMs - (n20Time - 3.0)) / 5.5;
      v = -2.8 * ampScale * math.sin(tau * math.pi);
    }
    // P25 positive rebound (+3.5 uV)
    else if (cycleTimeMs > (n20Time + 2.5) && cycleTimeMs <= (p25Time + 6.0)) {
      final tau = (cycleTimeMs - (n20Time + 2.5)) / 6.5;
      v = 3.5 * ampScale * math.sin(tau * math.pi);
    } else {
      v = 0.15 * math.sin(cycleTimeMs * 0.4);
    }

    return v;
  }

  /// Synthesizes Transcranial Motor Evoked Potential (MEP) sample (uV)
  /// Triggers a high-voltage compound muscle action potential (CMAP) every 1.0 second.
  static double computeMepSample({
    required double timeSeconds,
    required SpinalSyndrome syndrome,
    bool isLeftExtremity = true,
  }) {
    // 1 Hz stimulation cadence -> 1000 ms cycle
    final cycleTimeMs = (timeSeconds % 1.0) * 1000.0;

    double ampScale = 1.0;
    if (syndrome == SpinalSyndrome.anteriorCord) {
      // Bilateral corticospinal ischemia -> complete MEP flatline
      ampScale = 0.05;
    } else if (syndrome == SpinalSyndrome.brownSequard) {
      // Ipsilateral corticospinal transection -> ipsilateral loss
      if (isLeftExtremity) {
        ampScale = 0.08;
      }
    } else if (syndrome == SpinalSyndrome.centralCord) {
      // Cervical central cord: upper extremity MEP severely reduced
      ampScale = 0.40;
    }

    double v = 0.0;
    // Transcranial stimulus artifact at 2–5 ms
    if (cycleTimeMs >= 2.0 && cycleTimeMs <= 5.0) {
      final tau = (cycleTimeMs - 2.0) / 3.0;
      v = 15.0 * math.sin(tau * math.pi);
    }
    // CMAP polyphasic muscle wave at 28–46 ms latency (+55 uV, -42 uV)
    else if (cycleTimeMs >= 28.0 && cycleTimeMs <= 38.0) {
      final tau = (cycleTimeMs - 28.0) / 10.0;
      v = 55.0 * ampScale * math.sin(tau * math.pi);
    } else if (cycleTimeMs > 38.0 && cycleTimeMs <= 48.0) {
      final tau = (cycleTimeMs - 38.0) / 10.0;
      v = -42.0 * ampScale * math.sin(tau * math.pi);
    } else {
      v = 0.25 * math.sin(cycleTimeMs * 0.1);
    }

    return v;
  }

  /// Synthesizes Invasive Intracranial Pressure (ICP) sample (mmHg)
  /// Accurate P1 (percussion), P2 (tidal), P3 (dicrotic) pulse morphology.
  static double computeIcpSample({
    double? phase,
    double? timeSeconds,
    required double baselineIcp,
    double? mapMmHg,
  }) {
    final phi = (phase ?? timeSeconds ?? 0.0) % 1.0;
    final isPoorCompliance = baselineIcp > 20.0; // P2 > P1 rounding when compliance is lost

    double p1Amp = 4.5;
    double p2Amp = isPoorCompliance ? 7.2 : 3.0; // P2 surges in intracranial hypertension
    double p3Amp = 2.0;

    double pulseDelta = 0.0;

    // P1 (Percussion Wave - Arterial choroid plexus pulsation at phi = 0.12 - 0.26)
    if (phi >= 0.12 && phi <= 0.26) {
      final tau = (phi - 0.12) / 0.14;
      pulseDelta += p1Amp * math.sin(tau * math.pi);
    }
    // P2 (Tidal Wave - Intracranial tissue compliance at phi = 0.24 - 0.45)
    if (phi >= 0.24 && phi <= 0.45) {
      final tau = (phi - 0.24) / 0.21;
      pulseDelta += p2Amp * math.sin(tau * math.pi);
    }
    // P3 (Dicrotic Wave - Venous outflow rebound at phi = 0.42 - 0.62)
    if (phi >= 0.42 && phi <= 0.62) {
      final tau = (phi - 0.42) / 0.20;
      pulseDelta += p3Amp * math.sin(tau * math.pi);
    }

    // Gentle diastolic baseline decay
    if (phi > 0.62) {
      final tau = (phi - 0.62) / 0.38;
      pulseDelta -= 0.6 * tau;
    }

    return baselineIcp + pulseDelta;
  }
}
