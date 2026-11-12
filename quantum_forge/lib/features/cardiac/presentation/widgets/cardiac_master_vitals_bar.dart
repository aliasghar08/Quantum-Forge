// ============================================================================
// Master Patient Vitals & Hemodynamics Control Bar
// ----------------------------------------------------------------------------
// High-density interactive physiological controller positioned directly
// between the 3D Viewports and the 5-Channel Hospital Bedside Monitor.
// Adjusting any parameter propagates bidirectionally across:
// - 3D Heart Contraction & Cine Fluoroscopy Pulse
// - 5-Channel Oscilloscope & ICU Numeric Tiles
// - 6-Module Diagnostic Workstation (Echo, Auscultation, EP, PV Loop, CHD, Tilt)
// - PyTorch Computational Research Suites (CardioElectrophys-Net & CardioPINN)
// Strictly follows the SaMD 7-Pillar Educational Simulation Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import '../../data/cardiac_master_vitals_state.dart';

class CardiacMasterVitalsBar extends StatelessWidget {
  final CardiacMasterVitalsState vitals;
  final VoidCallback? onReset;

  const CardiacMasterVitalsBar({
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
              // ── Header & Physiological Coupling Badges ─────────────────────
              _buildHeaderRow(context),
              const SizedBox(height: 8),

              // ── Heart Situation Trigger Strip (Auto-Pilot Scenarios) ───────
              _buildSituationTriggerRow(context),
              const SizedBox(height: 10),

              // ── Interactive Parameter Control Sliders ───────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1320;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // HR Slider
                        Expanded(
                          flex: 3,
                          child: _buildSliderTile(
                            label: 'HEART RATE',
                            valueText: '${vitals.heartRateBpm.round()} bpm',
                            value: vitals.heartRateBpm,
                            min: 30.0,
                            max: 220.0,
                            accentColor: const Color(0xFF00E676),
                            onChanged: (v) => vitals.setHeartRate(v),
                            onStepDown: () => vitals.setHeartRate(vitals.heartRateBpm - 5.0),
                            onStepUp: () => vitals.setHeartRate(vitals.heartRateBpm + 5.0),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // SBP / DBP Dual Slider
                        Expanded(
                          flex: 4,
                          child: _buildBpDualTile(context),
                        ),
                        const SizedBox(width: 8),

                        // SpO2 Slider
                        Expanded(
                          flex: 3,
                          child: _buildSliderTile(
                            label: 'O₂ SAT (SpO₂)',
                            valueText: '${vitals.spo2Pct.round()} %',
                            value: vitals.spo2Pct,
                            min: 60.0,
                            max: 100.0,
                            accentColor: const Color(0xFF00E5FF),
                            onChanged: (v) => vitals.setSpo2(v),
                            onStepDown: () => vitals.setSpo2(vitals.spo2Pct - 1.0),
                            onStepUp: () => vitals.setSpo2(vitals.spo2Pct + 1.0),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // RR & EtCO2 Slider
                        Expanded(
                          flex: 4,
                          child: _buildRespDualTile(context),
                        ),
                        const SizedBox(width: 8),

                        // LVEF Contractility Slider
                        Expanded(
                          flex: 3,
                          child: _buildSliderTile(
                            label: 'LV CONTRACTILITY',
                            valueText: '${vitals.lvefPct.round()} % EF',
                            value: vitals.lvefPct,
                            min: 15.0,
                            max: 75.0,
                            accentColor: const Color(0xFFA78BFA),
                            onChanged: (v) => vitals.setLvef(v),
                            onStepDown: () => vitals.setLvef(vitals.lvefPct - 5.0),
                            onStepUp: () => vitals.setLvef(vitals.lvefPct + 5.0),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 220,
                            child: _buildSliderTile(
                              label: 'HEART RATE',
                              valueText: '${vitals.heartRateBpm.round()} bpm',
                              value: vitals.heartRateBpm,
                              min: 30.0,
                              max: 220.0,
                              accentColor: const Color(0xFF00E676),
                              onChanged: (v) => vitals.setHeartRate(v),
                              onStepDown: () => vitals.setHeartRate(vitals.heartRateBpm - 5.0),
                              onStepUp: () => vitals.setHeartRate(vitals.heartRateBpm + 5.0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 240,
                            child: _buildBpDualTile(context),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 210,
                            child: _buildSliderTile(
                              label: 'O₂ SAT (SpO₂)',
                              valueText: '${vitals.spo2Pct.round()} %',
                              value: vitals.spo2Pct,
                              min: 60.0,
                              max: 100.0,
                              accentColor: const Color(0xFF00E5FF),
                              onChanged: (v) => vitals.setSpo2(v),
                              onStepDown: () => vitals.setSpo2(vitals.spo2Pct - 1.0),
                              onStepUp: () => vitals.setSpo2(vitals.spo2Pct + 1.0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 240,
                            child: _buildRespDualTile(context),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 220,
                            child: _buildSliderTile(
                              label: 'LV CONTRACTILITY',
                              valueText: '${vitals.lvefPct.round()} % EF',
                              value: vitals.lvefPct,
                              min: 15.0,
                              max: 75.0,
                              accentColor: const Color(0xFFA78BFA),
                              onChanged: (v) => vitals.setLvef(v),
                              onStepDown: () => vitals.setLvef(vitals.lvefPct - 5.0),
                              onStepUp: () => vitals.setLvef(vitals.lvefPct + 5.0),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSituationHeaderBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF334155), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: Color(0xFF00E5FF), size: 12),
          SizedBox(width: 4),
          Text(
            'HEART SITUATION TRIGGER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSituationChipsList() {
    return CardiacClinicalSituation.values.map((sit) {
      final isCurrent = vitals.activeSituation == sit;
      final isAuto = isCurrent && !vitals.isManualOverride;
      return Padding(
        padding: const EdgeInsets.only(right: 6.0),
        child: InkWell(
          key: Key('situation_chip_${sit.id}'),
          onTap: () {
            vitals.triggerSituation(sit);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: isAuto
                  ? sit.accentColor.withValues(alpha: 0.22)
                  : (isCurrent
                      ? sit.accentColor.withValues(alpha: 0.10)
                      : const Color(0xFF0F172A)),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isAuto
                    ? sit.accentColor
                    : (isCurrent
                        ? sit.accentColor.withValues(alpha: 0.6)
                        : const Color(0xFF1E293B)),
                width: isAuto ? 1.2 : 0.8,
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
                    color: isCurrent ? sit.accentColor : Colors.white24,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  sit.shortLabel,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.white70,
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStatusPill(BuildContext context) {
    if (!vitals.isManualOverride) {
      return Container(
        key: const Key('status_pill_auto'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF00E676), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 12),
            const SizedBox(width: 4),
            Text(
              'AUTO-VITALS: ${vitals.activeSituation.shortLabel.toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const Key('status_pill_manual'),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFFFB300), width: 1.0),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFFFFB300), size: 12),
                SizedBox(width: 4),
                Text(
                  'MANUAL OVERRIDE',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            key: const Key('btn_resync_situation'),
            onTap: () => vitals.syncToActiveSituation(),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF00E5FF), width: 0.9),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync_rounded, color: Color(0xFF00E5FF), size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Sync to Situation',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSituationTriggerRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E293B), width: 0.8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 950;
          if (isNarrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSituationHeaderBadge(),
                  const SizedBox(width: 8),
                  ..._buildSituationChipsList(),
                  const SizedBox(width: 8),
                  _buildStatusPill(context),
                ],
              ),
            );
          }
          return Row(
            children: [
              _buildSituationHeaderBadge(),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildSituationChipsList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        // Title with Pulse Icon
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Icon(Icons.tune_rounded, color: Color(0xFF00E5FF), size: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              'MASTER PATIENT VITALS & HEMODYNAMICS CONTROLLER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),

        // Derived Metrics Badges & Action Buttons
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            _buildBadge('MAP', '${vitals.mapBp.round()} mmHg', const Color(0xFFFF5252)),
            _buildBadge('CO', '${vitals.cardiacOutputLMin.toStringAsFixed(1)} L/min', const Color(0xFF10B981)),
            _buildBadge('BCL', '${vitals.cycleLengthMs.round()} ms', const Color(0xFF00E5FF)),
            _buildBadge('SV', '${vitals.strokeVolumeMl.round()} mL', const Color(0xFFA78BFA)),
            _buildBadge('SVR', '${vitals.estimatedSvrDynes.round()}', const Color(0xFFFFB300)),

            // Reset Button
            InkWell(
              onTap: () {
                vitals.resetToNormalVitals();
                onReset?.call();
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF334155), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white70, size: 12),
                    SizedBox(width: 4),
                    Text('Reset Vitals', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            // Info Dialog Button
            InkWell(
              onTap: () => _showCouplingGuide(context),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF00E5FF), size: 12),
                    SizedBox(width: 4),
                    Text('Coupling Guide', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.7),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontFamily: 'monospace')),
            TextSpan(text: value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ],
        ),
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
    required VoidCallback onStepDown,
    required VoidCallback onStepUp,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E293B), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                valueText,
                style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              _buildStepBtn(Icons.remove, onStepDown),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: accentColor,
                    inactiveTrackColor: const Color(0xFF1E293B),
                    thumbColor: accentColor,
                    overlayColor: accentColor.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: value.clamp(min, max),
                    min: min,
                    max: max,
                    onChanged: onChanged,
                  ),
                ),
              ),
              _buildStepBtn(Icons.add, onStepUp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBpDualTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E293B), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'BP (SBP/DBP)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${vitals.systolicBp.round()}',
                      style: const TextStyle(color: Color(0xFFFF5252), fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    const TextSpan(
                      text: ' / ',
                      style: TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace'),
                    ),
                    TextSpan(
                      text: '${vitals.diastolicBp.round()} mmHg',
                      style: const TextStyle(color: Color(0xFFFFB300), fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              _buildStepBtn(Icons.remove, () {
                vitals.setBloodPressure(vitals.systolicBp - 5.0, vitals.diastolicBp - 3.0);
              }),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 2.5,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5.5),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: Color(0xFFFF5252),
                    inactiveTrackColor: Color(0xFF1E293B),
                    thumbColor: Color(0xFFFF5252),
                  ),
                  child: Slider(
                    value: vitals.systolicBp.clamp(60.0, 220.0),
                    min: 60.0,
                    max: 220.0,
                    onChanged: (v) {
                      final ratio = vitals.diastolicBp / vitals.systolicBp;
                      vitals.setBloodPressure(v, v * ratio);
                    },
                  ),
                ),
              ),
              _buildStepBtn(Icons.add, () {
                vitals.setBloodPressure(vitals.systolicBp + 5.0, vitals.diastolicBp + 3.0);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRespDualTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E293B), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'RR & EtCO₂',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${vitals.respRate.round()}/m',
                      style: const TextStyle(color: Color(0xFFFFAB40), fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    const TextSpan(
                      text: ' • ',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    TextSpan(
                      text: '${vitals.etco2MmHg.round()} mmHg',
                      style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              _buildStepBtn(Icons.remove, () {
                vitals.setRespRate(vitals.respRate - 2.0);
              }),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 2.5,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5.5),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: Color(0xFFFFAB40),
                    inactiveTrackColor: Color(0xFF1E293B),
                    thumbColor: Color(0xFFFFAB40),
                  ),
                  child: Slider(
                    value: vitals.respRate.clamp(6.0, 40.0),
                    min: 6.0,
                    max: 40.0,
                    onChanged: (v) {
                      // Physiological coupling: Hyperventilation (high RR) blows off CO2 (lower EtCO2)
                      final coupledEtco2 = (44.0 - (v - 12.0) * 0.45).clamp(18.0, 55.0);
                      vitals.setRespiration(v, coupledEtco2);
                    },
                  ),
                ),
              ),
              _buildStepBtn(Icons.add, () {
                vitals.setRespRate(vitals.respRate + 2.0);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white70, size: 12),
      ),
    );
  }

  void _showCouplingGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 0.8),
        ),
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: Color(0xFF00E5FF), size: 20),
            SizedBox(width: 8),
            Text(
              'Physiological Coupling Architecture',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How Adjusting Master Vitals Propagates in Real Time:',
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _CouplingItem(
                title: '1. Heart Rate (HR, 30–220 bpm)',
                desc: 'Controls 3D heart myocardial contraction speed, Cine Fluoroscopy pulsatile cadence, 5-channel sweep density, Echo Doppler diastolic filling time, and PyTorch CardioElectrophys-Net pacing BCL (60,000 / HR ms).',
              ),
              _CouplingItem(
                title: '2. Blood Pressure (SBP / DBP mmHg)',
                desc: 'Controls ABP Pa waveform height, dicrotic notch, and MAP tile; shifts arterial elastance (Ea) in the LV Pressure-Volume loop; and updates CardioPINN proximal aortic boundary pressure (Pa).',
              ),
              _CouplingItem(
                title: '3. Oxygen Saturation (SpO₂, 60–100%)',
                desc: 'Controls cyan PLETH wave amplitude, cyan SpO₂ % tile, web-audio pulse pitch, and Congenital Shunt arterial saturation (SaO₂).',
              ),
              _CouplingItem(
                title: '4. Resp Rate & EtCO₂ (6–40 /min, 10–70 mmHg)',
                desc: 'Controls alveolar capnogram breath wave frequency, plateau height, and respiratory baseline wander on ECG & ABP traces.',
              ),
              _CouplingItem(
                title: '5. LV Contractility (LVEF, 15–75%)',
                desc: 'Scales 3D beating heart wall-motion excursion (hypokinesis vs hyperkinesis), tilts the Sagawa Emax elastance slope on the PV Loop, and updates Echo Lab stroke volume & EPSS.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _CouplingItem extends StatelessWidget {
  final String title;
  final String desc;
  const _CouplingItem({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.35)),
        ],
      ),
    );
  }
}
