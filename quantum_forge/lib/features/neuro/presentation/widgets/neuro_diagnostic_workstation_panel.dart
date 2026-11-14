// ============================================================================
// NeuroLab 3D: Clinical Neurology & Neurophysiology Diagnostic Suite
// ----------------------------------------------------------------------------
// 6 Interactive Bedside Diagnostic Workstation Tabs:
// Tab 1: Cranial Nerves (I–XII) & Brainstem Reflex Lab (Pupillary, RAPD, VOR)
// Tab 2: Transcranial Doppler (TCD) & Lindegaard Vasospasm Lab
// Tab 3: Quantitative EEG (qEEG) Spectrogram & ASM Titration Lab
// Tab 4: EMG & Nerve Conduction Study (NCS) / RNS Neuromuscular Lab
// Tab 5: CSF Lumbar Puncture & AAN Brain Death Protocol Lab
// Tab 6: Brachial/Lumbosacral Plexus, Myotome & Dermatome Localizer
// Strictly follows the SaMD 7-Pillar Educational Simulation Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import 'neuro_master_vitals_state.dart';

class NeuroDiagnosticWorkstationPanel extends StatefulWidget {
  final NeuroMasterVitalsState vitals;

  const NeuroDiagnosticWorkstationPanel({
    super.key,
    required this.vitals,
  });

  @override
  State<NeuroDiagnosticWorkstationPanel> createState() =>
      _NeuroDiagnosticWorkstationPanelState();
}

class _NeuroDiagnosticWorkstationPanelState
    extends State<NeuroDiagnosticWorkstationPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 state: Cranial Nerves & Reflexes
  String _torchTargetEye = 'none'; // 'left', 'right', 'none'
  String _cnLesionSite = 'none'; // 'none', 'left_cn2', 'right_cn3', 'brainstem_pons'

  // Tab 2 state: TCD & Lindegaard
  double _mcaVelocity = 165.0;
  double _icaVelocity = 32.0;
  bool _isNimodipineActive = false;
  bool _isVerapamilActive = false;

  // Tab 3 state: qEEG & ASM
  double _deltaPower = 45.0;
  final double _thetaPower = 25.0;
  double _alphaPower = 20.0;
  final double _betaPower = 10.0;
  double _spikeIndex = 0.65;
  final List<String> _activeAsms = [];

  // Tab 4 state: EMG & NCS
  String _emgPathology = 'myasthenia_gravis';
  String _rnsFrequency = '3hz';
  bool _tensilonGiven = false;

  // Tab 5 state: CSF & Brain Death
  double _csfOpeningPressure = 24.0; // cm H2O
  String _csfScenario = 'sah';
  final Map<String, bool> _brainDeathChecks = {
    'known_cause': false,
    'no_hypothermia_or_toxins': false,
    'absent_pupils': false,
    'absent_corneal': false,
    'absent_oculocephalic': false,
    'absent_gag_cough': false,
    'positive_apnea_test': false,
  };

  // Tab 6 state: Plexus & Radiculopathy
  String _selectedPlexusLesion = 'erbs_palsy';
  String _selectedRootLesion = 'l5';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090E17),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header TabBar
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0B132B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF00E5FF),
              indicatorWeight: 3.0,
              labelColor: const Color(0xFF00E5FF),
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              tabs: const [
                Tab(icon: Icon(Icons.remove_red_eye, size: 14), text: '1. CRANIAL NERVES & REFLEXES'),
                Tab(icon: Icon(Icons.waves, size: 14), text: '2. TCD & LINDEGAARD'),
                Tab(icon: Icon(Icons.show_chart, size: 14), text: '3. qEEG & SEIZURE TITRATION'),
                Tab(icon: Icon(Icons.bolt, size: 14), text: '4. EMG / NCS & RNS LAB'),
                Tab(icon: Icon(Icons.water_drop, size: 14), text: '5. CSF & BRAIN DEATH PROTOCOL'),
                Tab(icon: Icon(Icons.accessibility_new, size: 14), text: '6. PLEXUS & DERMATOMES'),
              ],
            ),
          ),

          // Tab Views
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCranialNervesTab(),
                _buildTcdVasospasmTab(),
                _buildQeegTab(),
                _buildEmgNcsTab(),
                _buildCsfBrainDeathTab(),
                _buildPlexusDermatomeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: Cranial Nerves & Brainstem Reflex Lab
  // ==========================================================================
  Widget _buildCranialNervesTab() {
    // Pupillary calculations
    bool leftConstricts = false;
    bool rightConstricts = false;
    String rapdStatus = 'Normal symmetrical pupillary reflexes';

    if (_torchTargetEye == 'left') {
      if (_cnLesionSite == 'left_cn2') {
        rapdStatus = 'Left Afferent Pupillary Defect (Marcus Gunn Pupil) — Light in left eye yields poor bilateral constriction';
        leftConstricts = false;
        rightConstricts = false;
      } else if (_cnLesionSite == 'right_cn3') {
        leftConstricts = true; // Consensual preserved
        rightConstricts = false; // Right efferent CN III failure -> pupil fixed & dilated
        rapdStatus = 'Right Efferent CN III Palsy — Fixed, mydriatic right pupil with ptosis';
      } else {
        leftConstricts = true;
        rightConstricts = true;
      }
    } else if (_torchTargetEye == 'right') {
      if (_cnLesionSite == 'left_cn2') {
        leftConstricts = true; // Consensual to left intact
        rightConstricts = true; // Direct to right intact
        rapdStatus = 'Light in unaffected right eye yields prompt bilateral constriction (Classic RAPD sign)';
      } else if (_cnLesionSite == 'right_cn3') {
        leftConstricts = true;
        rightConstricts = false; // Efferent deficit
      } else {
        leftConstricts = true;
        rightConstricts = true;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Interactive Pupils & Torch
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1526),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'PUPILLARY LIGHT REFLEX & MARCUS GUNN (RAPD) SIMULATOR',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Left Eye
                          _buildEyeWidget(
                            label: 'LEFT EYE (OS)',
                            isTorchOn: _torchTargetEye == 'left',
                            isConstricted: leftConstricts,
                            isFixedMydriatic: _cnLesionSite == 'left_cn3',
                          ),
                          // Right Eye
                          _buildEyeWidget(
                            label: 'RIGHT EYE (OD)',
                            isTorchOn: _torchTargetEye == 'right',
                            isConstricted: rightConstricts,
                            isFixedMydriatic: _cnLesionSite == 'right_cn3',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _torchTargetEye = _torchTargetEye == 'left' ? 'none' : 'left';
                              });
                            },
                            icon: const Icon(Icons.flashlight_on, size: 14),
                            label: const Text('Torch Left Eye', style: TextStyle(fontSize: 10)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _torchTargetEye == 'left' ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _torchTargetEye = _torchTargetEye == 'right' ? 'none' : 'right';
                              });
                            },
                            icon: const Icon(Icons.flashlight_on, size: 14),
                            label: const Text('Torch Right Eye', style: TextStyle(fontSize: 10)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _torchTargetEye == 'right' ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rapdStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Right Column: Lesion Selector & Brainstem Localization
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1526),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'ANATOMICAL CRANIAL NERVE LESION PRESET',
                        style: TextStyle(
                          color: Color(0xFF69F0AE),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: _cnLesionSite,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('Normal Intact Reflexes')),
                          DropdownMenuItem(value: 'left_cn2', child: Text('Left Optic Nerve (CN II) — Afferent RAPD')),
                          DropdownMenuItem(value: 'right_cn3', child: Text('Right Oculomotor (CN III) — Aneurysm / Uncal')),
                          DropdownMenuItem(value: 'brainstem_pons', child: Text('Pontine Hemorrhage — Pinpoint Pupils')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _cnLesionSite = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'BRAINSTEM REFLEX BATTERY:',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _buildReflexItem('Corneal Reflex (V1 Afferent -> VII Efferent)', 'Bilateral blink intact'),
                      _buildReflexItem('Vestibulo-Ocular (Caloric COWS / Doll Eyes)', 'Cold water induces nystagmus to opposite ear'),
                      _buildReflexItem('Gag & Cough Reflex (CN IX & X)', 'Posterior pharyngeal stimulation triggers bilateral elevation'),
                      _buildReflexItem('Midbrain (CN III, IV) | Pons (V-VIII) | Medulla (IX-XII)', 'Localization intact'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEyeWidget({
    required String label,
    required bool isTorchOn,
    required bool isConstricted,
    required bool isFixedMydriatic,
  }) {
    final pupilDiameter = isFixedMydriatic ? 32.0 : (isConstricted ? 12.0 : 22.0);

    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            shape: BoxShape.circle,
            border: Border.all(
              color: isTorchOn ? const Color(0xFFF59E0B) : const Color(0xFF475569),
              width: isTorchOn ? 2.5 : 1.0,
            ),
            boxShadow: isTorchOn
                ? [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), blurRadius: 10)]
                : null,
          ),
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A), // Iris
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: pupilDiameter,
                  height: pupilDiameter,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isFixedMydriatic
              ? '7 mm (Fixed)'
              : (isConstricted ? '2 mm (Constricted)' : '4 mm (Baseline)'),
          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildReflexItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$title: $desc',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: Transcranial Doppler (TCD) & Lindegaard Vasospasm Lab
  // ==========================================================================
  Widget _buildTcdVasospasmTab() {
    double mca = _mcaVelocity;
    if (_isNimodipineActive) mca *= 0.85;
    if (_isVerapamilActive) mca *= 0.72;

    final lr = mca / _icaVelocity;
    String status = 'Normal Flow';
    Color color = const Color(0xFF10B981);

    if (mca < 120 && lr < 3.0) {
      status = 'Normal Baseline (No Vasospasm)';
      color = const Color(0xFF10B981);
    } else if (mca >= 120 && lr < 3.0) {
      status = 'Hyperemia (High Volume Flow, LR < 3.0)';
      color = const Color(0xFF38BDF8);
    } else if (lr >= 3.0 && lr < 4.5) {
      status = 'Mild Vasospasm (LR 3.0 – 4.5)';
      color = const Color(0xFFFBBF24);
    } else if (lr >= 4.5 && lr < 6.0) {
      status = 'Moderate Vasospasm (LR 4.5 – 6.0)';
      color = const Color(0xFFF97316);
    } else {
      status = 'Severe Vasospasm (LR > 6.0) — High Risk DCI';
      color = const Color(0xFFFF1744);
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left: Velocity Controls
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1526),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'TRANSCRANIAL DOPPLER SPECTRAL VELOCITY CONTROLS',
                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('MCA Mean Flow Velocity: ${mca.round()} cm/s (Normal: < 120 cm/s)',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10)),
                  Slider(
                    value: _mcaVelocity,
                    min: 40.0,
                    max: 300.0,
                    activeColor: color,
                    onChanged: (v) => setState(() => _mcaVelocity = v),
                  ),
                  const SizedBox(height: 6),
                  Text('Extracranial ICA Mean Velocity: ${_icaVelocity.round()} cm/s',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10)),
                  Slider(
                    value: _icaVelocity,
                    min: 15.0,
                    max: 80.0,
                    activeColor: const Color(0xFF94A3B8),
                    onChanged: (v) => setState(() => _icaVelocity = v),
                  ),
                  const SizedBox(height: 10),
                  const Text('RESCUE PHARMACOLOGIC INTERVENTIONS:',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Oral Nimodipine 60mg', style: TextStyle(fontSize: 10)),
                        selected: _isNimodipineActive,
                        selectedColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                        checkmarkColor: const Color(0xFF10B981),
                        onSelected: (val) => setState(() => _isNimodipineActive = val),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('IA Verapamil Infusion', style: TextStyle(fontSize: 10)),
                        selected: _isVerapamilActive,
                        selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                        checkmarkColor: const Color(0xFF00E5FF),
                        onSelected: (val) => setState(() => _isVerapamilActive = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right: Lindegaard Ratio & Advisory
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1526),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('LINDEGAARD RATIO (LR)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    lr.toStringAsFixed(2),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pulsatility Index (Gosling PI): 1.15 | Resistive Index (RI): 0.68\n'
                    'Formula: LR = V_mean(MCA) / V_mean(ICA_extracranial)\n'
                    'Differentiates delayed cerebral ischemia (DCI) vasospasm from post-injury hyperemia.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: Quantitative EEG (qEEG) & ASM Titration Lab
  // ==========================================================================
  Widget _buildQeegTab() {
    final adr = _alphaPower / _deltaPower.clamp(1.0, 100.0);
    final isIschemicWarning = adr < 0.5;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left: Power Spectral Bands
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1526),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'QUANTITATIVE EEG (qEEG) 4-BAND POWER SPECTRUM',
                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildPowerBar('DELTA (0.5 – 4 Hz) Slowing', _deltaPower, const Color(0xFFFF5252)),
                  _buildPowerBar('THETA (4 – 8 Hz) Encephalopathy', _thetaPower, const Color(0xFFFFA726)),
                  _buildPowerBar('ALPHA (8 – 13 Hz) Cortical Baseline', _alphaPower, const Color(0xFF69F0AE)),
                  _buildPowerBar('BETA (13 – 30 Hz) Fast Rhythms', _betaPower, const Color(0xFF40C4FF)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Alpha-Delta Ratio (ADR): ${adr.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isIschemicWarning ? const Color(0xFFFF1744) : const Color(0xFF69F0AE),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                      Text(
                        isIschemicWarning ? 'ISCHEMIA WARNING (ADR < 0.5)' : 'ADEQUATE PERFUSION',
                        style: TextStyle(
                          color: isIschemicWarning ? const Color(0xFFFF1744) : const Color(0xFF69F0AE),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right: Anti-Seizure Medication (ASM) Titration
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1526),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'STATUS EPILEPTICUS PHARMACOTHERAPY',
                    style: TextStyle(color: Color(0xFFFFA726), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Spike-and-Wave Burst Index: ${(_spikeIndex * 100).round()}%',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                  LinearProgressIndicator(
                    value: _spikeIndex,
                    color: const Color(0xFFFF5252),
                    backgroundColor: const Color(0xFF1E293B),
                  ),
                  const SizedBox(height: 10),
                  const Text('ADMINISTER IV DRUGS:',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildAsmButton('Lorazepam 4mg IV Bolus', 'lorazepam', 0.25),
                  _buildAsmButton('Levetiracetam (Keppra) 40mg/kg', 'keppra', 0.20),
                  _buildAsmButton('Propofol Infusion (Burst Suppression)', 'propofol', 0.50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
              Text('${value.round()}%', style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 100.0,
              color: color,
              backgroundColor: const Color(0xFF1E293B),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsmButton(String name, String key, double reduction) {
    final isActive = _activeAsms.contains(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            if (isActive) {
              _activeAsms.remove(key);
              _spikeIndex = (_spikeIndex + reduction).clamp(0.0, 1.0);
            } else {
              _activeAsms.add(key);
              _spikeIndex = (_spikeIndex - reduction).clamp(0.0, 1.0);
              if (key == 'propofol') {
                _deltaPower = 70.0;
                _alphaPower = 5.0;
              }
            }
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.transparent,
          side: BorderSide(color: isActive ? const Color(0xFF10B981) : const Color(0xFF334155)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(color: isActive ? const Color(0xFF10B981) : const Color(0xFFE2E8F0), fontSize: 9.5)),
            if (isActive) const Icon(Icons.check, size: 12, color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 4: EMG & Nerve Conduction Study (NCS) / RNS Lab
  // ==========================================================================
  Widget _buildEmgNcsTab() {
    String verdict = 'Normal';
    double decInc = 0.0;
    double cv = 55.0;

    if (_emgPathology == 'myasthenia_gravis') {
      decInc = _tensilonGiven ? -6.0 : -32.0;
      verdict = 'Myasthenia Gravis: Postsynaptic AChR defect. >10% RNS decrement at 3 Hz.';
      if (_tensilonGiven) verdict += ' (Reversed by Edrophonium/Tensilon)';
      cv = 56.0;
    } else if (_emgPathology == 'lems') {
      decInc = _rnsFrequency == '50hz' ? 250.0 : -14.0;
      verdict = 'Lambert-Eaton (LEMS): Presynaptic P/Q Ca2+ channel defect. >100% facilitation at 50 Hz.';
      cv = 54.0;
    } else if (_emgPathology == 'guillain_barre') {
      decInc = -4.0;
      cv = 28.0;
      verdict = 'Guillain-Barré (AIDP): Demyelinating slowing (<35 m/s), prolonged distal latency (>5 ms).';
    } else {
      decInc = -2.0;
      cv = 51.0;
      verdict = 'ALS: Motor neuron degeneration with active denervation (fibrillations & giant MUPs).';
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left: Pathology selector & frequency
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1526),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('ELECTRODIAGNOSTIC PATHOLOGY PROFILE',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: _emgPathology,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    items: const [
                      DropdownMenuItem(value: 'myasthenia_gravis', child: Text('Myasthenia Gravis (Post-Synaptic AChR)')),
                      DropdownMenuItem(value: 'lems', child: Text('Lambert-Eaton LEMS (Pre-Synaptic Ca2+)')),
                      DropdownMenuItem(value: 'guillain_barre', child: Text('Guillain-Barré AIDP (Demyelinating)')),
                      DropdownMenuItem(value: 'als', child: Text('ALS (Lower + Upper Motor Neuron)')),
                    ],
                    onChanged: (v) => setState(() => _emgPathology = v!),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('RNS Stimulation Rate: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                      ChoiceChip(
                        label: const Text('3 Hz (Low-Frequency)', style: TextStyle(fontSize: 9.5)),
                        selected: _rnsFrequency == '3hz',
                        onSelected: (s) => setState(() => _rnsFrequency = '3hz'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('50 Hz (Tetanic)', style: TextStyle(fontSize: 9.5)),
                        selected: _rnsFrequency == '50hz',
                        onSelected: (s) => setState(() => _rnsFrequency = '50hz'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _tensilonGiven = !_tensilonGiven),
                    icon: Icon(_tensilonGiven ? Icons.undo : Icons.medication, size: 14),
                    label: Text(_tensilonGiven ? 'Withdraw Edrophonium' : 'Perform Tensilon Test (Edrophonium)',
                        style: const TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tensilonGiven ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right: CMAP response display
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1526),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('CMAP TRAIN RESPONSE (STIMULI 1 – 5)',
                      style: TextStyle(color: Color(0xFF69F0AE), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '${decInc > 0 ? "+" : ""}${decInc.toStringAsFixed(1)}% ${decInc > 0 ? "Increment" : "Decrement"}',
                    style: TextStyle(
                      color: decInc < -10.0 ? const Color(0xFFFF5252) : const Color(0xFF69F0AE),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Motor Conduction Velocity: ${cv.toStringAsFixed(1)} m/s',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10)),
                  const SizedBox(height: 6),
                  Text(
                    verdict,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 5: CSF Lumbar Puncture & Brain Death Protocol
  // ==========================================================================
  Widget _buildCsfBrainDeathTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: CSF Manometer & Differential
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1526),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('LUMBAR PUNCTURE MANOMETRY & CSF ANALYSIS',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Opening Pressure: ${_csfOpeningPressure.round()} cm H2O (Normal: 10 – 20 cm H2O)',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10)),
                  Slider(
                    value: _csfOpeningPressure,
                    min: 5.0,
                    max: 45.0,
                    activeColor: _csfOpeningPressure > 20.0 ? const Color(0xFFFF5252) : const Color(0xFF10B981),
                    onChanged: (v) => setState(() => _csfOpeningPressure = v),
                  ),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: _csfScenario,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    items: const [
                      DropdownMenuItem(value: 'sah', child: Text('Aneurysmal SAH (Xanthochromia + RBCs No Clear)')),
                      DropdownMenuItem(value: 'bacterial', child: Text('Bacterial Meningitis (Neutrophils, Low Glucose)')),
                      DropdownMenuItem(value: 'viral', child: Text('Viral / Aseptic Meningitis (Lymphocytes, Normal Glucose)')),
                      DropdownMenuItem(value: 'ms', child: Text('Multiple Sclerosis (Oligoclonal Bands + IgG Index)')),
                    ],
                    onChanged: (v) => setState(() => _csfScenario = v!),
                  ),
                  const SizedBox(height: 8),
                  _buildCsfSummary(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right: AAN Brain Death Checklist
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1526),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('AAN BRAIN DEATH PROTOCOL CHECKLIST',
                      style: TextStyle(color: Color(0xFFFF5252), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ..._brainDeathChecks.keys.map((k) {
                    final label = k.replaceAll('_', ' ').toUpperCase();
                    return CheckboxListTile(
                      title: Text(label, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 9)),
                      value: _brainDeathChecks[k],
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFFFF5252),
                      onChanged: (val) => setState(() => _brainDeathChecks[k] = val ?? false),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCsfSummary() {
    if (_csfScenario == 'sah') {
      return const Text(
        'CSF Profile: Uniform blood in Tubes 1-4 with xanthochromia (centrifuged supernatant yellow from bilirubin). Suggests subarachnoid hemorrhage rather than traumatic tap.',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
      );
    } else if (_csfScenario == 'bacterial') {
      return const Text(
        'CSF Profile: Turbid fluid, opening pressure >25 cm H2O, WBC >1000/uL with >80% PMNs, protein >200 mg/dL, CSF/Serum glucose ratio <0.4.',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
      );
    } else if (_csfScenario == 'viral') {
      return const Text(
        'CSF Profile: Clear fluid, normal/mild pressure elevation, lymphocytic pleocytosis (50-500/uL), normal glucose, normal/mild protein.',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
      );
    } else {
      return const Text(
        'CSF Profile: Mild lymphocytic pleocytosis, normal glucose, >= 2 unique oligoclonal IgG bands not present in serum, elevated CSF IgG index (>0.7).',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
      );
    }
  }

  // ==========================================================================
  // TAB 6: Brachial/Lumbosacral Plexus & Dermatomes
  // ==========================================================================
  Widget _buildPlexusDermatomeTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left: Brachial Plexus
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1526),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('BRACHIAL PLEXUS (C5 – T1) LOCALIZER',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: _selectedPlexusLesion,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    items: const [
                      DropdownMenuItem(value: 'erbs_palsy', child: Text("C5–C6 Upper Trunk (Erb's Palsy / Waiter's Tip)")),
                      DropdownMenuItem(value: 'klumpkes', child: Text("C8–T1 Lower Trunk (Klumpke's Claw Hand)")),
                      DropdownMenuItem(value: 'radial', child: Text('Radial Nerve (Spiral Groove / Wrist Drop)')),
                      DropdownMenuItem(value: 'median', child: Text('Median Nerve (Carpal Tunnel / Ape Hand)')),
                      DropdownMenuItem(value: 'ulnar', child: Text('Ulnar Nerve (Cubital Tunnel / Claw Hand)')),
                    ],
                    onChanged: (v) => setState(() => _selectedPlexusLesion = v!),
                  ),
                  const SizedBox(height: 10),
                  _buildPlexusSummary(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right: Lumbosacral Radiculopathy
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1526),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('LUMBOSACRAL ROOT (L4 – S1) LOCALIZER',
                      style: TextStyle(color: Color(0xFF69F0AE), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: _selectedRootLesion,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    items: const [
                      DropdownMenuItem(value: 'l4', child: Text('L4 Root: Knee Extension / Patellar Reflex Diminished')),
                      DropdownMenuItem(value: 'l5', child: Text('L5 Root: Great Toe Extension (EHL) / Foot Drop (No Reflex)')),
                      DropdownMenuItem(value: 's1', child: Text('S1 Root: Plantarflexion / Achilles Reflex Diminished')),
                    ],
                    onChanged: (v) => setState(() => _selectedRootLesion = v!),
                  ),
                  const SizedBox(height: 10),
                  _buildLumbosacralSummary(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlexusSummary() {
    if (_selectedPlexusLesion == 'erbs_palsy') {
      return const Text(
        "Erb's Palsy (C5-C6): Traction on infant shoulder during delivery or motorcycle trauma. Affects Deltoid, Biceps, Brachioradialis. Limb hangs by side, adducted, medially rotated, forearm pronated ('Waiter's tip').",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
      );
    } else if (_selectedPlexusLesion == 'klumpkes') {
      return const Text(
        "Klumpke's Palsy (C8-T1): Upward traction on arm (e.g. grabbing branch during fall). Affects intrinsic hand muscles. Claw hand with lumbrical paralysis; ipsilateral Horner syndrome if T1 sympathetic fibers torn.",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
      );
    } else if (_selectedPlexusLesion == 'radial') {
      return const Text(
        "Radial Nerve: Mid-shaft humerus fracture or 'Saturday night palsy'. Inability to extend wrist and fingers (wrist drop). Preserved triceps if lesion is distal in spiral groove.",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
      );
    } else if (_selectedPlexusLesion == 'median') {
      return const Text(
        "Median Nerve: Supracondylar fracture (proximal) or carpal tunnel (distal). Loss of thenar opposition ('Ape hand'). Proximal lesion prevents flexing digits 1-3 ('Hand of Benediction').",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
      );
    } else {
      return const Text(
        "Ulnar Nerve: Medial epicondyle fracture or cubital tunnel entrapment. Ulnar claw on attempting to extend fingers (affecting 4th and 5th digits). Froment sign positive (adductor pollicis weakness).",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
      );
    }
  }

  Widget _buildLumbosacralSummary() {
    if (_selectedRootLesion == 'l4') {
      return const Text(
        "L4 Radiculopathy: Quadriceps weakness (difficulty rising from chair), sensory loss over medial leg/foot, diminished patellar (knee jerk) deep tendon reflex.",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
      );
    } else if (_selectedRootLesion == 'l5') {
      return const Text(
        "L5 Radiculopathy: Extensor hallucis longus (EHL) & tibialis anterior weakness -> Foot drop and difficulty walking on heels. Sensory loss over dorsum of foot. No reflex assigned to L5.",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
      );
    } else {
      return const Text(
        "S1 Radiculopathy: Gastrocnemius/soleus weakness -> Inability to walk on toes (plantar flexion). Sensory loss over lateral foot and sole. Diminished or absent Achilles tendon reflex.",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, height: 1.3),
      );
    }
  }
}
