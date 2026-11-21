// ============================================================================
// DentoLab 3D: Dental, Endodontic & Maxillofacial Workstation Screen
// ----------------------------------------------------------------------------
// Modeled after CardioCath 3D Lab with full hospital & dental school depth:
// 1. Procedural 3D WebGL Volumetric Maxillofacial & 32-Tooth Dentition Engine
// 2. Full-Screen Micro-Anatomical Tooth Theater with Coronal Cutaway & 22+ Tags
// 3. Digital Dental Radiography & 3D CBCT Twin (PA, Bitewing, Panoramic, CBCT)
// 4. 5-Channel Chairside Hospital & Pulpal Oscilloscope with Emergency Rescue
// 5. Interventional Suite: Endodontic RCT Sequence & Titanium Implant Placement
// 6. Dental Molecular Pharmacology Bridge to 3D Chemical Reaction Viewer
// 7. Permanent SaMD 7-Pillar Legal Shield Banner (Dart Nexus Lab)
// ============================================================================

import 'package:flutter/material.dart';
import '../features/dental/data/dental_models.dart';
import '../features/dental/presentation/widgets/dental_3d_viewport.dart';
import '../features/dental/presentation/widgets/dental_radiography_viewport.dart';
import '../features/dental/presentation/widgets/dental_chairside_monitor_strip.dart';
import '../features/dental/presentation/widgets/dental_pharmacology_dialog.dart';

class DentalScreen extends StatefulWidget {
  final String? initialCaseId;

  const DentalScreen({super.key, this.initialCaseId});

  static Route<void> route({String? initialCaseId}) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: initialCaseId != null ? '/dental?case=$initialCaseId' : '/dental',
      ),
      builder: (_) => DentalScreen(initialCaseId: initialCaseId),
    );
  }

  @override
  State<DentalScreen> createState() => _DentalScreenState();
}

class _DentalScreenState extends State<DentalScreen> {
  late DentalClinicalCase _activeCase;
  DentalLayerMode _selectedLayer = DentalLayerMode.all;
  DentalRadiographyMode _radiographyMode = DentalRadiographyMode.pa;
  int _selectedToothNumber = 19;
  EndoRctStep _rctStep = EndoRctStep.none;
  ImplantStep _implantStep = ImplantStep.none;
  late DentalTelemetryState _telemetry;

  @override
  void initState() {
    super.initState();
    _activeCase = DentalClinicalCase.kPresets.firstWhere(
      (c) => c.id == widget.initialCaseId,
      orElse: () => DentalClinicalCase.kPresets[1], // Default: Irreversible Pulpitis #19
    );
    _selectedToothNumber = _activeCase.focusTooth;
    _telemetry = DentalTelemetryState();
    _telemetry.applyCase(_activeCase);
  }

  void _applyCase(DentalClinicalCase c) {
    setState(() {
      _activeCase = c;
      _selectedToothNumber = c.focusTooth;
      _rctStep = (c.id == 'pulpitis_19') ? EndoRctStep.access : EndoRctStep.none;
      _implantStep = (c.id == 'implant_sinus') ? ImplantStep.fixture : ImplantStep.none;
      _telemetry.applyCase(c);
    });
  }

  void _showSaMdDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 24),
            SizedBox(width: 10),
            Text(
              'SaMD 7-Pillar Regulatory Shield',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DentoLab 3D is strictly an educational in-silico simulation designed for dental students (BDS / DDS), endodontic & maxillofacial residents, and biomedical researchers.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                '1. Non-Diagnostic: Mathematical procedural models do not reflect any specific living patient.\n'
                '2. Non-Interventional: Simulated root canal and implant steps are pedagogical illustrations.\n'
                '3. Pharmacology Reference: Dosing and toxic ceilings follow standard ADA/AAP guidelines.\n'
                '4. Zero Third-Party Copyright: 100% of WebGL geometry is generated mathematically.\n'
                '5. Supervised Clinical Learning: Must not be used for actual chairside patient management.\n'
                '6. Institutional Integrity: Quantum Forge — A Product of Dart Nexus Lab.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            child: const Text('Acknowledge', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020611),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Permanent Amber SaMD 7-Pillar Legal Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              color: const Color(0xFF78350F).withValues(alpha: 0.95),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFDE68A), size: 15),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Educational Simulation Only — Not for Clinical Diagnosis, Treatment Planning, or Patient Care. Quantum Forge — A Product of Dart Nexus Lab.',
                      style: TextStyle(color: Color(0xFFFEF3C7), fontSize: 11, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _showSaMdDialog,
                    child: const Text(
                      '7-Pillar Shield ⓘ',
                      style: TextStyle(color: Color(0xFFFDE68A), fontSize: 11, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Top Navigation & Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF070C18),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                    tooltip: 'Back to Workspace',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.healing_rounded, color: Color(0xFF38BDF8), size: 22),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DentoLab 3D',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Dental, Endodontic & Maxillofacial Workstation',
                        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Clinical Scenario Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DentalClinicalCase>(
                          value: _activeCase,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0F172A),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8)),
                          items: DentalClinicalCase.kPresets.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.title,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newCase) {
                            if (newCase != null) _applyCase(newCase);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Dental Pharmacology Modal Button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.medication_liquid_rounded, size: 16),
                    label: const Text('Dental Rx & MoA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => DentalPharmacologyDialog.show(context),
                  ),
                ],
              ),
            ),

            // 3. Clinical Case Diagnostic Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFF0B132B),
              child: Row(
                children: [
                  const Icon(Icons.assignment_ind_rounded, size: 15, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Chief Complaint: ${_activeCase.chiefComplaint} • Treatment: ${_activeCase.recommendedTreatment}',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 4. Main Workstation Body (Split Viewport + Controls)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: 3D Micro-Anatomy & Interventions
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Expanded(
                            child: Dental3DViewport(
                              selectedLayer: _selectedLayer,
                              onLayerChanged: (l) => setState(() => _selectedLayer = l),
                              selectedToothNumber: _selectedToothNumber,
                              onToothSelected: (t) => setState(() => _selectedToothNumber = t),
                              rctStep: _rctStep,
                              implantStep: _implantStep,
                              onRctStepChanged: (s) => setState(() => _rctStep = s),
                              onImplantStepChanged: (s) => setState(() => _implantStep = s),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Interventional Dental Procedure Bar (RCT & Implant)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF070C18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF1E293B)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'INTERVENTIONAL ENDO & SURGICAL SUITE:',
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                      onPressed: () => setState(() {
                                        _rctStep = EndoRctStep.none;
                                        _implantStep = ImplantStep.none;
                                      }),
                                      child: const Text('Reset Procedure', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // RCT Steps Buttons
                                Row(
                                  children: EndoRctStep.values.where((s) => s != EndoRctStep.none).map((step) {
                                    final isSel = _rctStep == step;
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: InkWell(
                                          onTap: () => setState(() {
                                            _rctStep = step;
                                            _implantStep = ImplantStep.none;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isSel ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(color: isSel ? Colors.white : const Color(0xFF334155)),
                                            ),
                                            child: Center(
                                              child: Text(
                                                step.label,
                                                style: TextStyle(
                                                  color: isSel ? Colors.white : Colors.white70,
                                                  fontSize: 9,
                                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 4),

                                // Implant Steps Buttons
                                Row(
                                  children: ImplantStep.values.where((s) => s != ImplantStep.none).map((step) {
                                    final isSel = _implantStep == step;
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: InkWell(
                                          onTap: () => setState(() {
                                            _implantStep = step;
                                            _rctStep = EndoRctStep.none;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isSel ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(color: isSel ? Colors.white : const Color(0xFF334155)),
                                            ),
                                            child: Center(
                                              child: Text(
                                                step.label,
                                                style: TextStyle(
                                                  color: isSel ? Colors.white : Colors.white70,
                                                  fontSize: 9,
                                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Right Column: Digital Radiography & Clinical Diagnostic HUD
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Expanded(
                            child: DentalRadiographyViewport(
                              mode: _radiographyMode,
                              onModeChanged: (m) => setState(() => _radiographyMode = m),
                              rctStep: _rctStep,
                              implantStep: _implantStep,
                              toothNumber: _selectedToothNumber,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Periodontal & Pulp Examination Sliders HUD
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF070C18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF1E293B)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHAIRSIDE CLINICAL EXAMINATION HUD:',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),

                                // EPT Slider
                                _buildParameterRow(
                                  'Electric Pulp Test (EPT):',
                                  '${_telemetry.eptMicroAmps.toInt()} µA',
                                  _telemetry.eptMicroAmps,
                                  0.0,
                                  100.0,
                                  const Color(0xFFFFB74D),
                                  (v) => setState(() => _telemetry.eptMicroAmps = v),
                                ),

                                // Pocket Depth Slider
                                _buildParameterRow(
                                  'Periodontal Pocket Depth:',
                                  '${_telemetry.pocketDepthMm.toStringAsFixed(1)} mm',
                                  _telemetry.pocketDepthMm,
                                  1.0,
                                  12.0,
                                  const Color(0xFFF59E0B),
                                  (v) => setState(() => _telemetry.pocketDepthMm = v),
                                ),

                                // LDF Flow Slider
                                _buildParameterRow(
                                  'Laser Doppler Pulp Flow:',
                                  '${_telemetry.ldfPulpFlowPercent.toInt()}%',
                                  _telemetry.ldfPulpFlowPercent,
                                  0.0,
                                  100.0,
                                  const Color(0xFF00E5FF),
                                  (v) => setState(() => _telemetry.ldfPulpFlowPercent = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Bottom Chairside 5-Channel CRT Telemetry Monitor
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: DentalChairsideMonitorStrip(
                telemetry: _telemetry,
                onTelemetryChanged: (t) => setState(() => _telemetry = t),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(
    String label,
    String valueText,
    double val,
    double min,
    double max,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 145,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              activeTrackColor: color,
              inactiveTrackColor: const Color(0xFF334155),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: val.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            valueText,
            style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
