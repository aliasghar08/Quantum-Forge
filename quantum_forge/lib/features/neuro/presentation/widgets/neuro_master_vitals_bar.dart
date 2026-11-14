// ============================================================================
// NeuroLab 3D: Master Neuro-Critical Care Vitals & Situation Trigger Bar
// ----------------------------------------------------------------------------
// High-density interactive physiological controller positioned directly
// between the 3D Brain/Biplane Viewports and the 5-Channel IONM Bedside Monitor.
// Adjusting any parameter propagates bidirectionally across:
// - Translucent 3D Brain Perfusion & Circle of Willis Windkessel
// - 5-Channel Hospital Oscilloscope (Dual EEG, SSEP, MEP, ICP P1/P2/P3, CPP)
// - 6-Module Clinical Diagnostic Suite (Cranial Nerves, TCD, qEEG, EMG/NCS, CSF, Plexus)
// - Neurosurgical & Computational Research Suite (NeuroFNO, Flow-Diverter, GNN, Cohort)
// Strictly follows the SaMD 7-Pillar Educational Simulation Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import 'neuro_master_vitals_state.dart';

class NeuroMasterVitalsBar extends StatelessWidget {
  final NeuroMasterVitalsState vitals;
  final VoidCallback? onReset;

  const NeuroMasterVitalsBar({
    super.key,
    required this.vitals,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vitals,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF070B12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1E293B),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header & Physiological Status Badges ────────────────────────
              _buildHeaderRow(context),
              const SizedBox(height: 8),

              // ── Clinical Situation Trigger Strip (Auto-Pilot) ──────────────
              _buildSituationTriggerRow(context),
              const SizedBox(height: 10),

              // ── Telemetry Tiles & Interactive Sliders ───────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1200;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // MAP Slider
                        Expanded(
                          flex: 3,
                          child: _buildSliderTile(
                            label: 'MAP',
                            valueText: '${vitals.mapMmHg.round()} mmHg',
                            value: vitals.mapMmHg,
                            min: 40.0,
                            max: 180.0,
                            accentColor: const Color(0xFF00E5FF),
                            onChanged: (v) => vitals.setManualMap(v),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ICP Slider
                        Expanded(
                          flex: 3,
                          child: _buildSliderTile(
                            label: 'ICP',
                            valueText: '${vitals.icpMmHg.round()} mmHg',
                            value: vitals.icpMmHg,
                            min: 2.0,
                            max: 50.0,
                            accentColor: vitals.isIntracranialHypertension
                                ? const Color(0xFFFF5252)
                                : const Color(0xFFFFA726),
                            onChanged: (v) => vitals.setManualIcp(v),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // CPP Readout Tile (MAP - ICP)
                        _buildComputedCppTile(),
                        const SizedBox(width: 8),

                        // PaCO2 Slider
                        Expanded(
                          flex: 3,
                          child: _buildSliderTile(
                            label: 'PaCO2',
                            valueText: '${vitals.paco2MmHg.round()} mmHg',
                            value: vitals.paco2MmHg,
                            min: 20.0,
                            max: 60.0,
                            accentColor: const Color(0xFF69F0AE),
                            onChanged: (v) => vitals.setManualPaCO2(v),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // SpO2 Slider
                        Expanded(
                          flex: 2,
                          child: _buildSliderTile(
                            label: 'SpO2',
                            valueText: '${vitals.spo2Percent.round()}%',
                            value: vitals.spo2Percent,
                            min: 70.0,
                            max: 100.0,
                            accentColor: const Color(0xFF40C4FF),
                            onChanged: (v) => vitals.setManualSpO2(v),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Temp Slider
                        Expanded(
                          flex: 2,
                          child: _buildSliderTile(
                            label: 'CORE TEMP',
                            valueText: '${vitals.temperatureC.toStringAsFixed(1)}°C',
                            value: vitals.temperatureC,
                            min: 33.0,
                            max: 40.0,
                            accentColor: const Color(0xFFFFAB40),
                            onChanged: (v) => vitals.setManualTemperature(v),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // GCS Badge
                        _buildGcsTile(context),
                      ],
                    );
                  } else {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: 280,
                          child: _buildSliderTile(
                            label: 'MAP',
                            valueText: '${vitals.mapMmHg.round()} mmHg',
                            value: vitals.mapMmHg,
                            min: 40.0,
                            max: 180.0,
                            accentColor: const Color(0xFF00E5FF),
                            onChanged: (v) => vitals.setManualMap(v),
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: _buildSliderTile(
                            label: 'ICP',
                            valueText: '${vitals.icpMmHg.round()} mmHg',
                            value: vitals.icpMmHg,
                            min: 2.0,
                            max: 50.0,
                            accentColor: const Color(0xFFFF5252),
                            onChanged: (v) => vitals.setManualIcp(v),
                          ),
                        ),
                        _buildComputedCppTile(),
                        SizedBox(
                          width: 280,
                          child: _buildSliderTile(
                            label: 'PaCO2',
                            valueText: '${vitals.paco2MmHg.round()} mmHg',
                            value: vitals.paco2MmHg,
                            min: 20.0,
                            max: 60.0,
                            accentColor: const Color(0xFF69F0AE),
                            onChanged: (v) => vitals.setManualPaCO2(v),
                          ),
                        ),
                        _buildGcsTile(context),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monitor_heart, color: Color(0xFF00E5FF), size: 13),
              SizedBox(width: 4),
              Text(
                'NEURO-CRITICAL CARE TELEMETRY CONTROLLER',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Auto-Pilot vs Manual Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: vitals.isAutoPilot
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : const Color(0xFFF59E0B).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: vitals.isAutoPilot ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          ),
          child: Text(
            vitals.isAutoPilot ? 'AUTO-VITALS ACTIVE' : 'MANUAL OVERRIDE',
            style: TextStyle(
              color: vitals.isAutoPilot ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Monro-Kellie / CPP Status Badge
        if (vitals.isCriticalHerniationRisk)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFFF1744)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber, color: Color(0xFFFF1744), size: 12),
                SizedBox(width: 4),
                Text(
                  'CRITICAL: IMPENDING UNCAL HERNIATION',
                  style: TextStyle(
                    color: Color(0xFFFF1744),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          )
        else if (vitals.isIntracranialHypertension)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFFFA726)),
            ),
            child: const Text(
              'ICP ELEVATED (> 20 mmHg) — POOR COMPLIANCE',
              style: TextStyle(
                color: Color(0xFFFFA726),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: const Text(
              'INTACT MONRO-KELLIE COMPLIANCE',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(width: 10),

        // Re-sync Button
        OutlinedButton.icon(
          onPressed: () => vitals.resetToAutoPilot(),
          icon: const Icon(Icons.refresh, size: 12, color: Color(0xFF94A3B8)),
          label: const Text(
            'Re-Sync Auto',
            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: Color(0xFF334155)),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildSituationTriggerRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NeuroClinicalSituation.values.map((sit) {
          final isSelected = vitals.activeSituation == sit;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => vitals.applySituation(sit),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF1E293B),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sit.title,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSliderTile({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required Color accentColor,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                valueText,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: accentColor,
              inactiveTrackColor: const Color(0xFF1E293B),
              thumbColor: accentColor,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComputedCppTile() {
    final cpp = vitals.cppMmHg;
    final isDanger = cpp < 50.0;
    final isWarning = cpp < 60.0;
    final color = isDanger
        ? const Color(0xFFFF1744)
        : (isWarning ? const Color(0xFFFFA726) : const Color(0xFF10B981));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'CPP = MAP - ICP',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${cpp.round()} mmHg',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGcsTile(BuildContext context) {
    final gcs = vitals.totalGcs;
    final color = gcs <= 8
        ? const Color(0xFFFF1744)
        : (gcs <= 12 ? const Color(0xFFFFA726) : const Color(0xFF10B981));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'GLASGOW COMA SCALE',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GCS $gcs',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(E${vitals.gcsEye}V${vitals.gcsVerbal}M${vitals.gcsMotor})',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9.5,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
