// ============================================================================
// NeuroLab 3D: Whole Nervous System Workstation Panel
// ----------------------------------------------------------------------------
// Comprehensive clinical and computational lab covering:
// 1. Whole-Body PNS Nerve & Root Lesion Localizer (WholeNeuro-Connectome)
// 2. Autonomic Nervous System (Sympathetic, Parasympathetic & Enteric) Lab
// 3. Neuro-Ophthalmology Visual Field Perimetry & Vestibular Lab
// 4. Synaptic Cleft, Myelin & Neuromuscular Junction (SynapseNet-Axon) Lab
//
// Strictly Educational In-Silico Simulation — SaMD 7-Pillar Compliant.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'neuro_master_vitals_state.dart';

class NeuroWholeSystemPanel extends StatefulWidget {
  final NeuroMasterVitalsState vitals;

  const NeuroWholeSystemPanel({super.key, required this.vitals});

  @override
  State<NeuroWholeSystemPanel> createState() => _NeuroWholeSystemPanelState();
}

class _NeuroWholeSystemPanelState extends State<NeuroWholeSystemPanel> {
  int _activeTab = 0; // 0=PNS Localizer, 1=ANS Lab, 2=Visual & Vestibular, 3=Synapse & NMJ

  // ── Tab 0: PNS State ──────────────────────────────────────────────────────
  String _selectedPnsLesion = 'radial_wrist_drop';
  int _mrcStrength = 1; // 0/5 to 5/5
  String _dermatomePatch = 'Dorsal 1st Webspace (Radial)';
  String _dtrReflex = 'Brachioradialis Absent (0/4), Triceps Preserved (2+)';
  String _topLocation = 'Named Peripheral Nerve (Mononeuropathy)';
  double _connectomeConfidence = 94.5;
  String _recommendedTest = 'Nerve Conduction Studies & Electromyography (NCS/EMG)';

  // ── Tab 1: ANS State ──────────────────────────────────────────────────────
  String _ansCondition = 'horner_syndrome';
  double _sympTone = 30.0;
  double _paraTone = 70.0;
  double _pupilDiameterMm = 2.0;
  bool _ptosis = true;
  bool _anhidrosis = true;
  bool _autonomicDysreflexia = false;

  // ── Tab 2: Visual & Vestibular State ──────────────────────────────────────
  String _selectedVisualSite = 'optic_chiasm';
  String _perimetryPattern = 'Bitemporal Hemianopia (Pituitary Adenoma / Craniopharyngioma)';
  final String _vestibularCanal = 'posterior';
  final bool _dixHallpikeActive = true;
  final double _vorGain = 0.92;
  final double _epleySuccessProb = 88.0;

  // ── Tab 3: Synapse & NMJ State (SynapseNet-Axon) ───────────────────────────
  double _myelinIntegrity = 1.0;
  double _navConductance = 1.0;
  double _cavConductance = 1.0;
  double _snareCompetence = 1.0;
  double _acheActivity = 1.0;
  double _nachrDensity = 1.0;
  double _nmbBlocker = 0.0;
  bool _reversalActive = false;

  double _cvMs = 58.0;
  double _safetyFactor = 2.4;
  double _quanta = 45.0;
  double _eppMv = 35.0;
  double _rnsDec = 0.0;
  String _synapsePattern = 'Physiologically Normal Saltatory Conduction & NMJ Transmission';

  @override
  void initState() {
    super.initState();
    _recomputePnsLesion('radial_wrist_drop');
    _recomputeAns('horner_syndrome');
    _recomputeVisual('optic_chiasm');
    _recomputeSynapse();
  }

  void _recomputePnsLesion(String lesionId) {
    setState(() {
      _selectedPnsLesion = lesionId;
      switch (lesionId) {
        case 'radial_wrist_drop':
          _mrcStrength = 1;
          _dermatomePatch = 'Dorsal 1st Webspace (Thumb/Index)';
          _dtrReflex = 'Brachioradialis 0/4, Triceps 2+ (Preserved)';
          _topLocation = 'Named Peripheral Nerve (Spiral Groove Radial)';
          _connectomeConfidence = 96.2;
          _recommendedTest = 'NCS/EMG (Radial Motor Conduction Block)';
          break;
        case 'carpal_tunnel':
          _mrcStrength = 3;
          _dermatomePatch = 'Palmar Digits 1–3 and lateral half of 4';
          _dtrReflex = 'DTRs Preserved (2+)';
          _topLocation = 'Named Peripheral Nerve (Median at Carpal Tunnel)';
          _connectomeConfidence = 98.4;
          _recommendedTest = 'Median Sensory/Motor NCS (Distal Latency > 3.6 ms)';
          break;
        case 'cubital_tunnel':
          _mrcStrength = 2;
          _dermatomePatch = 'Palmar & Dorsal Digit 5 (Little Finger)';
          _dtrReflex = 'DTRs Preserved (2+)';
          _topLocation = 'Named Peripheral Nerve (Ulnar at Medial Epicondyle)';
          _connectomeConfidence = 95.1;
          _recommendedTest = 'Inching NCS across Cubital Tunnel';
          break;
        case 'peroneal_foot_drop':
          _mrcStrength = 0;
          _dermatomePatch = 'Dorsum of Foot & 1st Interdigital Webspace';
          _dtrReflex = 'Patellar 2+, Achilles 2+ (Preserved)';
          _topLocation = 'Named Peripheral Nerve (Common Fibular at Fibular Neck)';
          _connectomeConfidence = 97.5;
          _recommendedTest = 'Peroneal Motor NCS across Fibular Head';
          break;
        case 'erb_duchenne':
          _mrcStrength = 1;
          _dermatomePatch = 'Lateral Arm & Forearm (C5–C6)';
          _dtrReflex = 'Biceps & Brachioradialis Absent (0/4)';
          _topLocation = 'Brachial Plexus (Upper Trunk Erb\'s C5–C6)';
          _connectomeConfidence = 93.8;
          _recommendedTest = 'Brachial Plexus MRI & EMG';
          break;
        case 'klumpke_palsy':
          _mrcStrength = 1;
          _dermatomePatch = 'Medial Arm & Forearm (C8–T1)';
          _dtrReflex = 'Finger Flexor Reflex Depressed';
          _topLocation = 'Brachial Plexus (Lower Trunk Klumpke\'s C8–T1)';
          _connectomeConfidence = 91.5;
          _recommendedTest = 'Cervical Spine/Apical Lung MRI (Pancoast rule-out)';
          break;
        case 'sciatica_l5_s1':
          _mrcStrength = 2;
          _dermatomePatch = 'Lateral Calf & Plantar Foot (S1)';
          _dtrReflex = 'Achilles Tendon Reflex Absent (0/4)';
          _topLocation = 'Spinal Nerve Roots (L5–S1 Radiculopathy)';
          _connectomeConfidence = 92.0;
          _recommendedTest = 'Lumbar Spine MRI (Disc Herniation)';
          break;
      }
    });
  }

  void _recomputeAns(String condition) {
    setState(() {
      _ansCondition = condition;
      switch (condition) {
        case 'horner_syndrome':
          _sympTone = 20.0;
          _paraTone = 80.0;
          _pupilDiameterMm = 2.0;
          _ptosis = true;
          _anhidrosis = true;
          _autonomicDysreflexia = false;
          break;
        case 'autonomic_dysreflexia':
          _sympTone = 98.0;
          _paraTone = 90.0;
          _pupilDiameterMm = 5.5;
          _ptosis = false;
          _anhidrosis = false;
          _autonomicDysreflexia = true;
          widget.vitals.map = 175.0;
          break;
        case 'orthostatic_hypotension':
          _sympTone = 25.0;
          _paraTone = 75.0;
          _pupilDiameterMm = 3.5;
          _ptosis = false;
          _anhidrosis = false;
          _autonomicDysreflexia = false;
          widget.vitals.map = 68.0;
          break;
        case 'cholinergic_crisis':
          _sympTone = 10.0;
          _paraTone = 100.0;
          _pupilDiameterMm = 1.5;
          _ptosis = false;
          _anhidrosis = false;
          _autonomicDysreflexia = false;
          widget.vitals.map = 78.0;
          break;
        case 'anticholinergic_toxidrome':
          _sympTone = 90.0;
          _paraTone = 10.0;
          _pupilDiameterMm = 7.0;
          _ptosis = false;
          _anhidrosis = true;
          _autonomicDysreflexia = false;
          widget.vitals.map = 115.0;
          break;
      }
    });
  }

  void _recomputeVisual(String site) {
    setState(() {
      _selectedVisualSite = site;
      switch (site) {
        case 'optic_nerve':
          _perimetryPattern = 'Ipsilateral Monocular Blindness (Left Optic Neuritis)';
          break;
        case 'optic_chiasm':
          _perimetryPattern = 'Bitemporal Hemianopia (Pituitary Compression)';
          break;
        case 'meyers_loop':
          _perimetryPattern = 'Contralateral Superior Quadrantanopia ("Pie in the Sky")';
          break;
        case 'parietal_radiation':
          _perimetryPattern = 'Contralateral Inferior Quadrantanopia ("Pie on the Floor")';
          break;
        case 'calcarine_v1':
          _perimetryPattern = 'Contralateral Homonymous Hemianopia (Macular Sparing)';
          break;
      }
    });
  }

  void _recomputeSynapse() {
    final effectiveBlocker = math.max(0.0, _nmbBlocker - (_reversalActive ? 0.85 : 0.0));
    final effectiveNachr = _nachrDensity * (1.0 - 0.9 * effectiveBlocker);

    final cv = 5.0 + 58.0 * math.pow(_myelinIntegrity, 1.5) * math.sqrt(_navConductance);
    final sf = 2.4 * _myelinIntegrity * math.pow(_navConductance, 0.8);
    final q = 45.0 * math.pow(_cavConductance, 2.0) * _snareCompetence;
    final epp = 35.0 * math.pow(effectiveNachr, 1.2) * (q / 45.0);

    double rns = 0.0;
    String pat = 'Physiologically Normal Saltatory Conduction & NMJ Transmission';

    if (effectiveNachr < 0.4) {
      rns = 38.5;
      pat = 'Myasthenia Gravis (Post-synaptic nAChR blockade with RNS decrement)';
    } else if (_cavConductance < 0.4) {
      rns = -32.0;
      pat = 'Lambert-Eaton Myasthenic Syndrome (Pre-synaptic P/Q Ca_v block with facilitation)';
    } else if (_snareCompetence < 0.25) {
      rns = 5.0;
      pat = 'Botulinum Toxin Flaccid Paralysis (SNARE cleavage blocking exocytosis)';
    } else if (_myelinIntegrity < 0.4) {
      rns = 0.0;
      pat = 'Demyelinating Conduction Slowing / Block (Multiple Sclerosis / Guillain-Barré)';
    } else if (_nmbBlocker > 0.4 && !_reversalActive) {
      rns = 45.0;
      pat = 'Neuromuscular Blockade (Non-depolarizing Paralytic)';
    } else if (_nmbBlocker > 0.4 && _reversalActive) {
      rns = 2.0;
      pat = 'Reversed Neuromuscular Blockade (Sugammadex / Neostigmine)';
    }

    setState(() {
      _cvMs = cv;
      _safetyFactor = sf;
      _quanta = q;
      _eppMv = epp;
      _rnsDec = rns;
      _synapsePattern = pat;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF334155)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header & Navigation Bar ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.hub_outlined, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'WHOLE NERVOUS SYSTEM WORKSTATION',
                    style: TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildTabPill(0, 'PNS & Plexuses', Icons.accessibility_new),
                  const SizedBox(width: 6),
                  _buildTabPill(1, 'Autonomic & Enteric', Icons.bolt),
                  const SizedBox(width: 6),
                  _buildTabPill(2, 'Visual & Vestibular', Icons.visibility),
                  const SizedBox(width: 6),
                  _buildTabPill(3, 'Synapse & NMJ', Icons.biotech),
                ],
              ),
            ),
          ),

          // ── Active Tab Content ────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: [
                _buildPnsLocalizerTab(),
                _buildAutonomicAnsTab(),
                _buildVisualVestibularTab(),
                _buildSynapseNmjTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String title, IconData icon) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF475569),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 0: PNS Localizer ──────────────────────────────────────────────────
  Widget _buildPnsLocalizerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPnsLesion,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Peripheral / Plexus Lesion',
                    labelStyle: TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: const [
                    DropdownMenuItem(value: 'radial_wrist_drop', child: Text('Radial Nerve: Mid-Shaft Humerus ("Saturday Night Palsy")')),
                    DropdownMenuItem(value: 'carpal_tunnel', child: Text('Median Nerve: Carpal Tunnel Syndrome ("Ape Hand")')),
                    DropdownMenuItem(value: 'cubital_tunnel', child: Text('Ulnar Nerve: Cubital Tunnel Syndrome ("Claw Hand")')),
                    DropdownMenuItem(value: 'peroneal_foot_drop', child: Text('Common Fibular: Neck of Fibula ("Foot Drop")')),
                    DropdownMenuItem(value: 'erb_duchenne', child: Text('Brachial Plexus: Upper Trunk C5–C6 ("Erb\'s Waiter\'s Tip")')),
                    DropdownMenuItem(value: 'klumpke_palsy', child: Text('Brachial Plexus: Lower Trunk C8–T1 ("Klumpke\'s Claw")')),
                    DropdownMenuItem(value: 'sciatica_l5_s1', child: Text('Lumbosacral Root: L5–S1 Herniation ("Sciatica")')),
                  ],
                  onChanged: (val) {
                    if (val != null) _recomputePnsLesion(val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('MRC Motor Strength', '$_mrcStrength / 5', const Color(0xFFEF4444))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Connectome Confidence', '$_connectomeConfidence%', const Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Cutaneous Sensory Loss:', _dermatomePatch),
                const SizedBox(height: 6),
                _buildInfoRow('Deep Tendon Reflexes:', _dtrReflex),
                const SizedBox(height: 6),
                _buildInfoRow('Predicted Lesion Site:', _topLocation),
                const SizedBox(height: 6),
                _buildInfoRow('Gold-Standard Workup:', _recommendedTest),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Autonomic & Enteric ────────────────────────────────────────────
  Widget _buildAutonomicAnsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _ansCondition,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Autonomic / Enteric Condition',
              labelStyle: TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: const [
              DropdownMenuItem(value: 'horner_syndrome', child: Text('Horner\'s Syndrome (Oculosympathetic Disruption)')),
              DropdownMenuItem(value: 'autonomic_dysreflexia', child: Text('Autonomic Dysreflexia (T6+ Spinal Cord Injury Surge)')),
              DropdownMenuItem(value: 'orthostatic_hypotension', child: Text('Neurogenic Orthostatic Hypotension (Baroreflex Failure)')),
              DropdownMenuItem(value: 'cholinergic_crisis', child: Text('Acute Cholinergic Crisis (Organophosphate SLUDGEM)')),
              DropdownMenuItem(value: 'anticholinergic_toxidrome', child: Text('Anticholinergic Toxidrome (Atropine Overdose)')),
            ],
            onChanged: (val) {
              if (val != null) _recomputeAns(val);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Sympathetic Tone', '${_sympTone.toStringAsFixed(0)}%', const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Parasympathetic', '${_paraTone.toStringAsFixed(0)}%', const Color(0xFF06B6D4))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Pupil Diameter', '${_pupilDiameterMm.toStringAsFixed(1)} mm', const Color(0xFFA855F7))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Ptosis Present:', _ptosis ? 'YES (1-2 mm Müller paresis)' : 'NO (Normal palpebral fissure)'),
                const SizedBox(height: 6),
                _buildInfoRow('Hemifacial Anhidrosis:', _anhidrosis ? 'YES (Loss of sweating)' : 'NO'),
                const SizedBox(height: 6),
                _buildInfoRow('Hypertensive Crisis:', _autonomicDysreflexia ? 'ACTIVE (MAP > 160 mmHg - Emergency Nifedipine)' : 'STABLE'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Visual & Vestibular ────────────────────────────────────────────
  Widget _buildVisualVestibularTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedVisualSite,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Visual Pathway Lesion Site',
              labelStyle: TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: const [
              DropdownMenuItem(value: 'optic_nerve', child: Text('Left Optic Nerve (Pre-Chiasmatic Optic Neuritis)')),
              DropdownMenuItem(value: 'optic_chiasm', child: Text('Optic Chiasm (Pituitary Macroadenoma)')),
              DropdownMenuItem(value: 'meyers_loop', child: Text('Meyer\'s Loop (Inferior Optic Radiations in Temporal Lobe)')),
              DropdownMenuItem(value: 'parietal_radiation', child: Text('Parietal Optic Radiations (Superior Fibers)')),
              DropdownMenuItem(value: 'calcarine_v1', child: Text('Primary Visual Cortex V1 (Calcarine PCA Infarct)')),
            ],
            onChanged: (val) {
              if (val != null) _recomputeVisual(val);
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF38BDF8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GOLDMANN / HUMPHREY VISUAL FIELD DEFECT:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_perimetryPattern, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('BPPV Canal', '$_vestibularCanal Canal', const Color(0xFFA855F7))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('VOR Gain', _vorGain.toStringAsFixed(2), const Color(0xFF10B981))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Dix-Hallpike', _dixHallpikeActive ? 'Torsional Nystagmus' : 'Normal', const Color(0xFF38BDF8))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Epley Cure Rate', '${_epleySuccessProb.toStringAsFixed(0)}%', const Color(0xFFF59E0B))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Synapse & NMJ ──────────────────────────────────────────────────
  Widget _buildSynapseNmjTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSliderField('Myelin Integrity (MS/GBS)', _myelinIntegrity, 0.1, 1.0, (v) {
                  _myelinIntegrity = v;
                  _recomputeSynapse();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSliderField('Presynaptic Ca_v 2.1 (LEMS)', _cavConductance, 0.1, 1.0, (v) {
                  _cavConductance = v;
                  _recomputeSynapse();
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSliderField('Postsynaptic nAChR (MG)', _nachrDensity, 0.1, 1.0, (v) {
                  _nachrDensity = v;
                  _recomputeSynapse();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSliderField('SNARE Competence (Botulism)', _snareCompetence, 0.05, 1.0, (v) {
                  _snareCompetence = v;
                  _recomputeSynapse();
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSliderField('Node Na_v 1.6 Channels', _navConductance, 0.1, 1.0, (v) {
                  _navConductance = v;
                  _recomputeSynapse();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSliderField('AChE Cleft Activity', _acheActivity, 0.1, 1.0, (v) {
                  _acheActivity = v;
                  _recomputeSynapse();
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSliderField('Paralytic NMB Block', _nmbBlocker, 0.0, 1.0, (v) {
                  _nmbBlocker = v;
                  _recomputeSynapse();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    const Text('Reversal (Sugammadex)', style: TextStyle(color: Colors.white, fontSize: 11)),
                    const Spacer(),
                    Switch(
                      value: _reversalActive,
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (val) {
                        setState(() {
                          _reversalActive = val;
                          _recomputeSynapse();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Conduction Velocity', '${_cvMs.toStringAsFixed(1)} m/s', const Color(0xFF38BDF8))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Safety Factor', _safetyFactor.toStringAsFixed(2), _safetyFactor >= 1.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Vesicle Quanta', '${_quanta.toStringAsFixed(0)} q', const Color(0xFF10B981))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('EPP Amplitude', '${_eppMv.toStringAsFixed(1)} mV', const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('3 Hz RNS Change', '${_rnsDec >= 0 ? "+" : ""}${_rnsDec.toStringAsFixed(1)}%', _rnsDec > 10.0 ? const Color(0xFFEF4444) : const Color(0xFF38BDF8))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _synapsePattern,
                    style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderField(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            Text(val.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: val,
            min: min,
            max: max,
            activeColor: const Color(0xFF38BDF8),
            inactiveColor: const Color(0xFF334155),
            onChanged: (newVal) => setState(() => onChanged(newVal)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(val, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 11)),
        ),
      ],
    );
  }
}
