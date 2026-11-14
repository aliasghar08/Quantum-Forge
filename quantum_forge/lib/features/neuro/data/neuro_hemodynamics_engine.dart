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

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../../../core/config/api_endpoints.dart';
import 'neuro_pathology_models.dart';

class CloudHemodynamicsResult {
  final String scenarioId;
  final double icpMmHg;
  final double cppMmHg;
  final double cbfMl100gMin;
  final double cvrMmHgMinMl;
  final double p2P1Ratio;
  final bool isIntracranialHypertension;
  final bool isCushingReflexTriggered;
  final double ischemicCoreVolumeMl;
  final double penumbraVolumeMl;
  final String ticiReperfusionGrade;
  final double mismatchRatio;
  final Map<String, String> vesselPerfusionStatus;
  final String clinicalAdvisory;

  const CloudHemodynamicsResult({
    required this.scenarioId,
    required this.icpMmHg,
    required this.cppMmHg,
    required this.cbfMl100gMin,
    required this.cvrMmHgMinMl,
    required this.p2P1Ratio,
    required this.isIntracranialHypertension,
    required this.isCushingReflexTriggered,
    required this.ischemicCoreVolumeMl,
    required this.penumbraVolumeMl,
    required this.ticiReperfusionGrade,
    required this.mismatchRatio,
    required this.vesselPerfusionStatus,
    required this.clinicalAdvisory,
  });

  factory CloudHemodynamicsResult.fromJson(Map<String, dynamic> json) {
    return CloudHemodynamicsResult(
      scenarioId: json['scenario_id'] as String? ?? 'unknown',
      icpMmHg: (json['icp_mm_hg'] as num?)?.toDouble() ?? 14.0,
      cppMmHg: (json['cpp_mm_hg'] as num?)?.toDouble() ?? 70.0,
      cbfMl100gMin: (json['cbf_ml_100g_min'] as num?)?.toDouble() ?? 50.0,
      cvrMmHgMinMl: (json['cvr_mm_hg_min_ml'] as num?)?.toDouble() ?? 1.4,
      p2P1Ratio: (json['p2_p1_ratio'] as num?)?.toDouble() ?? 0.72,
      isIntracranialHypertension: json['is_intracranial_hypertension'] as bool? ?? false,
      isCushingReflexTriggered: json['is_cushing_reflex_triggered'] as bool? ?? false,
      ischemicCoreVolumeMl: (json['ischemic_core_volume_ml'] as num?)?.toDouble() ?? 0.0,
      penumbraVolumeMl: (json['penumbra_volume_ml'] as num?)?.toDouble() ?? 0.0,
      ticiReperfusionGrade: json['tici_reperfusion_grade'] as String? ?? 'TICI 3',
      mismatchRatio: (json['mismatch_ratio'] as num?)?.toDouble() ?? 1.0,
      vesselPerfusionStatus: (json['vessel_perfusion_status'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      clinicalAdvisory: json['clinical_advisory'] as String? ?? '',
    );
  }
}

class CloudIonmResult {
  final List<double> timePoints;
  final List<double> eegLeftUv;
  final List<double> eegRightUv;
  final List<double> ssepUv;
  final List<double> mepUv;
  final List<double> icpMmHg;
  final int samplingRateHz;
  final double dominantFrequencyHz;
  final double ssepN20LatencyMs;
  final double mepAmplitudeUv;
  final double icpMeanMmHg;
  final double cppMeanMmHg;

  const CloudIonmResult({
    required this.timePoints,
    required this.eegLeftUv,
    required this.eegRightUv,
    required this.ssepUv,
    required this.mepUv,
    required this.icpMmHg,
    required this.samplingRateHz,
    required this.dominantFrequencyHz,
    required this.ssepN20LatencyMs,
    required this.mepAmplitudeUv,
    required this.icpMeanMmHg,
    required this.cppMeanMmHg,
  });

  factory CloudIonmResult.fromJson(Map<String, dynamic> json) {
    return CloudIonmResult(
      timePoints: (json['time_points'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      eegLeftUv: (json['eeg_left_uv'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      eegRightUv: (json['eeg_right_uv'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      ssepUv: (json['ssep_uv'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      mepUv: (json['mep_uv'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      icpMmHg: (json['icp_mm_hg'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      samplingRateHz: (json['sampling_rate_hz'] as num?)?.toInt() ?? 500,
      dominantFrequencyHz: (json['dominant_frequency_hz'] as num?)?.toDouble() ?? 10.0,
      ssepN20LatencyMs: (json['ssep_n20_latency_ms'] as num?)?.toDouble() ?? 19.8,
      mepAmplitudeUv: (json['mep_amplitude_uv'] as num?)?.toDouble() ?? 185.0,
      icpMeanMmHg: (json['icp_mean_mm_hg'] as num?)?.toDouble() ?? 14.0,
      cppMeanMmHg: (json['cpp_mean_mm_hg'] as num?)?.toDouble() ?? 70.0,
    );
  }
}

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

  /// Queries Google Cloud Run NeuroLab Solver for coupled 1D-0D Circle of Willis
  /// autoregulation, Monro-Kellie compliance, CBF, and core/penumbra volumes.
  /// Falls back deterministically to local biophysical math if backend is unavailable.
  static Future<CloudHemodynamicsResult> fetchCloudHemodynamics({
    required String scenarioId,
    required double meanArterialPressure,
    required double heartRateBpm,
    required double baselineIcp,
    double arterialPco2 = 40.0,
    bool hasM1Occlusion = false,
    bool hasAneurysm = false,
    bool isThrombectomized = false,
    bool isCoiled = false,
    double hoursFromOnset = 3.5,
    List<String> drugInterventions = const [],
  }) async {
    final endpoint = ApiEndpoints.neuroHemodynamicsUrl;
    if (endpoint.isNotEmpty && !ApiEndpoints.isLoopback(endpoint)) {
      try {
        final uri = Uri.parse(endpoint);
        final payload = {
          'scenario_id': scenarioId,
          'mean_arterial_pressure': meanArterialPressure,
          'heart_rate_bpm': heartRateBpm,
          'baseline_icp': baselineIcp,
          'arterial_pco2': arterialPco2,
          'has_m1_occlusion': hasM1Occlusion,
          'has_aneurysm': hasAneurysm,
          'is_thrombectomized': isThrombectomized,
          'is_coiled': isCoiled,
          'hours_from_onset': hoursFromOnset,
          'drug_interventions': drugInterventions,
        };

        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return CloudHemodynamicsResult.fromJson(data);
        }
      } catch (_) {
        // Fall back gracefully to local deterministic physics
      }
    }

    // Local deterministic mathematical fallback
    final drugsLower = drugInterventions.map((d) => d.toLowerCase()).toList();
    final hasMannitol = drugsLower.any((d) => d.contains('mannitol') || d.contains('hypertonic'));
    final hasTpa = drugsLower.any((d) => d.contains('tenecteplase') || d.contains('alteplase') || d.contains('tpa'));
    final hasNimodipine = drugsLower.any((d) => d.contains('nimodipine'));

    double effIcp = baselineIcp;
    if (hasAneurysm) {
      effIcp += 16.0;
    } else if (hasM1Occlusion && !isThrombectomized && !hasTpa) {
      effIcp += math.min(18.0, hoursFromOnset * 1.8);
    }
    if (hasMannitol) {
      effIcp = math.max(8.0, effIcp - 11.5);
    }
    if (isCoiled) {
      effIcp = math.max(11.0, effIcp - 6.0);
    }

    final cpp = math.max(5.0, meanArterialPressure - effIcp);
    final p2P1 = effIcp <= 15.0
        ? 0.68 + (effIcp / 15.0) * 0.15
        : 0.85 + ((effIcp - 15.0) / 25.0) * 0.75;

    final isHighIcp = effIcp > 20.0;
    final isCushing = isHighIcp && meanArterialPressure >= 130.0 && heartRateBpm <= 55.0;

    double cbf = 50.0;
    if (cpp < 60.0) {
      cbf = math.max(4.0, (cpp / 60.0) * 50.0);
    } else if (cpp > 140.0) {
      cbf = 50.0 + (cpp - 140.0) * 0.35;
    }
    if (hasNimodipine && hasAneurysm) {
      cbf = math.min(60.0, cbf * 1.25);
    }

    double coreVol = 0.0;
    double penumbraVol = 0.0;
    String tici = 'TICI 3 (Normal Perfusion)';
    if (hasM1Occlusion) {
      if (isThrombectomized || hasTpa) {
        tici = 'TICI 3 (Complete Recanalization)';
        coreVol = math.min(35.0, 18.0 + hoursFromOnset * 1.5);
        penumbraVol = 0.0;
      } else {
        tici = 'TICI 0 (No Perfusion)';
        coreVol = math.min(110.0, 20.0 + hoursFromOnset * 4.2);
        penumbraVol = math.max(0.0, 125.0 - coreVol);
      }
    }

    return CloudHemodynamicsResult(
      scenarioId: scenarioId,
      icpMmHg: double.parse(effIcp.toStringAsFixed(1)),
      cppMmHg: double.parse(cpp.toStringAsFixed(1)),
      cbfMl100gMin: double.parse(cbf.toStringAsFixed(1)),
      cvrMmHgMinMl: double.parse((cpp / math.max(0.1, cbf)).toStringAsFixed(3)),
      p2P1Ratio: double.parse(p2P1.toStringAsFixed(2)),
      isIntracranialHypertension: isHighIcp,
      isCushingReflexTriggered: isCushing,
      ischemicCoreVolumeMl: double.parse(coreVol.toStringAsFixed(1)),
      penumbraVolumeMl: double.parse(penumbraVol.toStringAsFixed(1)),
      ticiReperfusionGrade: tici,
      mismatchRatio: coreVol > 0 ? double.parse(((penumbraVol + coreVol) / coreVol).toStringAsFixed(2)) : 1.0,
      vesselPerfusionStatus: {
        'Left MCA (M1 Trunk)': (hasM1Occlusion && !isThrombectomized && !hasTpa) ? 'Occluded (Thrombus)' : 'Patent (Revascularized)',
        'Anterior Communicating (ACom)': (hasAneurysm && !isCoiled) ? 'Saccular Aneurysm' : (isCoiled ? 'Coiled & Occluded' : 'Normal Patent'),
      },
      clinicalAdvisory: isHighIcp
          ? 'Intracranial hypertension detected. Monitor CPP and consider osmotherapy.'
          : 'Intracranial pressures within compensatory range.',
    );
  }

  /// Queries Google Cloud Run NeuroLab Solver for 500 Hz multi-channel IONM
  /// telemetry sweeps (EEG, SSEP, MEP, ICP). Falls back to local math on offline/timeout.
  static Future<CloudIonmResult> fetchCloudIonmWaveforms({
    required String scenarioId,
    required EegPattern eegPattern,
    required SpinalSyndrome spinalSyndrome,
    required double baselineIcp,
    required double meanArterialPressure,
    bool isThrombectomized = false,
    bool isCoiled = false,
    List<String> drugInterventions = const [],
    double durationSeconds = 1.0,
    int samplingRateHz = 500,
  }) async {
    final endpoint = ApiEndpoints.neuroIonmOscilloscopeUrl;
    if (endpoint.isNotEmpty && !ApiEndpoints.isLoopback(endpoint)) {
      try {
        final uri = Uri.parse(endpoint);
        final payload = {
          'duration_seconds': durationSeconds,
          'sampling_rate_hz': samplingRateHz,
          'scenario_id': scenarioId,
          'eeg_pattern': eegPattern.id,
          'spinal_syndrome': spinalSyndrome.id,
          'baseline_icp': baselineIcp,
          'mean_arterial_pressure': meanArterialPressure,
          'is_thrombectomized': isThrombectomized,
          'is_coiled': isCoiled,
          'drug_interventions': drugInterventions,
        };

        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return CloudIonmResult.fromJson(data);
        }
      } catch (_) {
        // Fall back gracefully
      }
    }

    // Local deterministic waveform generator
    final nSamples = (durationSeconds * samplingRateHz).toInt();
    final timePoints = <double>[];
    final eegLeft = <double>[];
    final eegRight = <double>[];
    final ssep = <double>[];
    final mep = <double>[];
    final icp = <double>[];

    for (int i = 0; i < nSamples; i++) {
      final t = i / samplingRateHz;
      timePoints.add(t);
      eegLeft.add(computeEegSample(
        timeSeconds: t,
        isLeftHemisphere: true,
        pattern: eegPattern,
        isThrombectomized: isThrombectomized,
      ));
      eegRight.add(computeEegSample(
        timeSeconds: t,
        isLeftHemisphere: false,
        pattern: eegPattern,
        isThrombectomized: isThrombectomized,
      ));
      ssep.add(computeSsepSample(
        timeSeconds: t,
        syndrome: spinalSyndrome,
      ));
      mep.add(computeMepSample(
        timeSeconds: t,
        syndrome: spinalSyndrome,
      ));
      icp.add(computeIcpSample(
        timeSeconds: t,
        baselineIcp: baselineIcp,
        mapMmHg: meanArterialPressure,
      ));
    }

    return CloudIonmResult(
      timePoints: timePoints,
      eegLeftUv: eegLeft,
      eegRightUv: eegRight,
      ssepUv: ssep,
      mepUv: mep,
      icpMmHg: icp,
      samplingRateHz: samplingRateHz,
      dominantFrequencyHz: eegPattern == EegPattern.focalDeltaSlowing ? 1.5 : (eegPattern == EegPattern.spikeAndWave ? 3.0 : 10.0),
      ssepN20LatencyMs: spinalSyndrome == SpinalSyndrome.brownSequard ? 22.5 : 19.8,
      mepAmplitudeUv: spinalSyndrome == SpinalSyndrome.anteriorCord ? 5.0 : 185.0,
      icpMeanMmHg: baselineIcp,
      cppMeanMmHg: meanArterialPressure - baselineIcp,
    );
  }
}
