// ============================================================================
// NeuroLab 3D: Timed Neurology & Neurosurgery OSCE Exam Mode
// ----------------------------------------------------------------------------
// Simulates USMLE Step 2 CS / Step 3 CCS, Royal College / FRCS (NeuroSurg),
// and Neurology Board examination clinical scenarios under timed conditions.
//
// 5 Core Board Examination Stations:
// 1. Acute Left M1 MCA Stroke (3.5h window) -> DSA, Solitaire™ Stent-Retriever (TICI 3), IV Tenecteplase
// 2. Ruptured ACom Aneurysm + Cushing Triad -> Endovascular Coiling, Mannitol 20%, Nimodipine
// 3. Generalized Convulsive Status Epilepticus -> IV Lorazepam + Levetiracetam aborting 3 Hz paroxysms
// 4. Brown-Séquard Hemicord Syndrome (T6) -> Axial localizer: ipsilateral CST/dorsal, contralateral STT
// 5. Acute Cauda Equina Syndrome (L4-L5) -> Emergent decompressive laminectomy
//
// Strictly Educational Simulation — SaMD 7-Pillar Compliant.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/neuro_pathology_models.dart';

class OsceVignette {
  final int stationNumber;
  final String title;
  final String chiefComplaint;
  final String clinicalVignette;
  final String targetScenarioId;
  final List<String> localizationOptions;
  final int correctLocalizationIndex;
  final String localizationRationale;

  final List<String> procedureOptions;
  final int correctProcedureIndex;
  final String procedureRationale;

  final List<String> pharmacologyOptions;
  final int correctPharmacologyIndex;
  final String pharmacologyRationale;

  final String boardGuidelineCitation;

  const OsceVignette({
    required this.stationNumber,
    required this.title,
    required this.chiefComplaint,
    required this.clinicalVignette,
    required this.targetScenarioId,
    required this.localizationOptions,
    required this.correctLocalizationIndex,
    required this.localizationRationale,
    required this.procedureOptions,
    required this.correctProcedureIndex,
    required this.procedureRationale,
    required this.pharmacologyOptions,
    required this.correctPharmacologyIndex,
    required this.pharmacologyRationale,
    required this.boardGuidelineCitation,
  });
}

const List<OsceVignette> kOsceVignettes = [
  OsceVignette(
    stationNumber: 1,
    title: 'Station 1: Hyperacute Ischemic Stroke (LVO)',
    chiefComplaint: 'Sudden right-sided paralysis and inability to speak (NIHSS 18)',
    clinicalVignette:
        'A 68-year-old male is brought to the emergency department with acute onset of right facial droop, flaccid right hemiplegia, and global aphasia. Last known well was 3.5 hours ago. Non-contrast head CT shows no acute intracranial hemorrhage (ASPECTS 9). Continuous telemetry demonstrates focal left hemispheric polymorphic delta slowing (1.5 Hz).',
    targetScenarioId: 'left_m1_stroke',
    localizationOptions: [
      'Left MCA M1 trunk occlusion with large salvageable penumbra',
      'Right ACA A2 branch occlusion with leg-predominant paresis',
      'Left Lacunar posterior limb of internal capsule pure motor stroke',
      'Basilar artery apex top-of-the-basilar occlusion',
    ],
    correctLocalizationIndex: 0,
    localizationRationale:
        'Aphasia + dense right hemiplegia localized to the dominant left hemisphere MCA territory. ASPECTS 9 confirms minimal irreversible core with extensive salvageable penumbra within the therapeutic window.',
    procedureOptions: [
      'Solitaire™ Stent-Retriever Mechanical Thrombectomy (Target TICI 2b/3 Reperfusion)',
      'Emergency decompressive hemicraniectomy prior to angiography',
      'Carotid endarterectomy within 2 hours of arrival',
      'Placement of external ventricular drain (EVD)',
    ],
    correctProcedureIndex: 0,
    procedureRationale:
        'AHA/ASA Level 1A recommendation: Endovascular mechanical thrombectomy with a stent retriever or direct aspiration within 6 hours of onset for anterior circulation LVO.',
    pharmacologyOptions: [
      'IV Tenecteplase 0.25 mg/kg bolus (or Alteplase 0.9 mg/kg)',
      'Subcutaneous unfractionated heparin bolus 5,000 units',
      'Oral clopidogrel 300 mg loading dose immediately',
      'IV labetalol to aggressively lower SBP below 120 mmHg',
    ],
    correctPharmacologyIndex: 0,
    pharmacologyRationale:
        'Patients presenting within 4.5 hours of ischemic stroke symptom onset without contraindications should receive intravenous thrombolysis prior to thrombectomy (bridging therapy).',
    boardGuidelineCitation: '2019 AHA/ASA Acute Ischemic Stroke Endovascular Guidelines (Level 1A Evidence)',
  ),
  OsceVignette(
    stationNumber: 2,
    title: 'Station 2: Ruptured Aneurysmal SAH & Cushing Triad',
    chiefComplaint: 'Sudden thunderclap "worst headache of life" with altered sensorium',
    clinicalVignette:
        'A 52-year-old female presents with sudden-onset explosive occipital headache, projectile vomiting, and progressive stupor. Vitals: BP 198/112 mmHg (MAP 140 mmHg), HR 46 bpm (sinus bradycardia), RR 9/min irregular. Invasive monitoring reveals ICP 34 mmHg with pathological P2 tidal rounding (P2 > P1). Biplane DSA demonstrates a 7 mm saccular Anterior Communicating Artery (ACom) aneurysm.',
    targetScenarioId: 'ruptured_acom_sah',
    localizationOptions: [
      'Anterior Communicating Artery (ACom) saccular aneurysm rupture with severe intracranial hypertension & Cushing reflex',
      'Basilar tip aneurysm rupture with midbrain compression',
      'Hypertensive putaminal intracerebral hemorrhage',
      'Spontaneous intracranial hypotension from spinal CSF leak',
    ],
    correctLocalizationIndex: 0,
    localizationRationale:
        'Thunderclap headache + Hunt & Hess Grade III SAH with Cushing Triad (hypertension, bradycardia, respiratory irregularity) signaling critically exhausted intracranial compliance.',
    procedureOptions: [
      'Axium™ Platinum Endovascular Microcoil Embolization of the ACom dome',
      'Stereotactic radiosurgery (Gamma Knife) within 24 hours',
      'Immediate lumbar puncture for high-volume CSF evacuation',
      'Internal carotid artery balloon occlusion test',
    ],
    correctProcedureIndex: 0,
    procedureRationale:
        'Securing the ruptured aneurysm sac via endovascular coiling (or surgical clipping) within 24 hours prevents catastrophic fatal rebleeding.',
    pharmacologyOptions: [
      'Mannitol 20% (1 g/kg IV) + Oral Nimodipine 60 mg q4h',
      'IV Nitroglycerin infusion + Warfarin reversal',
      'IV Nitroprusside targeting rapid MAP reduction to 70 mmHg',
      'High-dose Dexamethasone 10 mg IV q6h',
    ],
    correctPharmacologyIndex: 0,
    pharmacologyRationale:
        'Osmotherapy (Mannitol or 3% hypertonic saline) rapidly relieves intracranial hypertension across intact BBB. Enteral Nimodipine is a Class 1 recommendation to prevent delayed ischemic neurological deficits (DIND) from cerebral vasospasm.',
    boardGuidelineCitation: 'Neurocritical Care Society Guidelines on Intracranial Pressure & Aneurysmal SAH',
  ),
  OsceVignette(
    stationNumber: 3,
    title: 'Station 3: Refractory Status Epilepticus',
    chiefComplaint: 'Continuous generalized tonic-clonic convulsions lasting 22 minutes',
    clinicalVignette:
        'A 29-year-old male with a history of epilepsy is brought by paramedics with continuous bilateral tonic-clonic convulsions lasting 22 minutes without recovery of consciousness. Temperature 39.1°C, BP 155/95 mmHg, HR 144 bpm. 5-Channel continuous EEG reveals persistent high-voltage 3 Hz spike-and-wave discharges across both hemispheres.',
    targetScenarioId: 'status_epilepticus',
    localizationOptions: [
      'Generalized Convulsive Status Epilepticus (GCSE) — continuous epileptogenic firing',
      'Psychogenic non-epileptic seizures (PNES) with normal background rhythm',
      'Decerebrate posturing secondary to transtentorial uncal herniation',
      'Neuroleptic malignant syndrome with extrapyramidal rigidity',
    ],
    correctLocalizationIndex: 0,
    localizationRationale:
        'Continuous convulsive seizure activity lasting > 5 minutes meets the ILAE definition for operational Stage 1 Status Epilepticus requiring immediate intervention to prevent excitotoxic death.',
    procedureOptions: [
      'Continuous video-EEG telemetry + secure airway with endotracheal intubation if GCSE persists past second-line therapy',
      'Emergency emergent burr hole craniostomy',
      'Stereotactic deep brain stimulation (DBS)',
      'Immediate diagnostic cerebral angiography',
    ],
    correctProcedureIndex: 0,
    procedureRationale:
        'Airway protection, oxygenation, continuous electroencephalographic monitoring, and emergent pharmacotherapy are foundational in status epilepticus management.',
    pharmacologyOptions: [
      'IV Lorazepam 0.1 mg/kg rapid push, followed immediately by IV Levetiracetam 60 mg/kg',
      'Oral Carbamazepine 200 mg via nasogastric tube',
      'Subcutaneous Sumatriptan 6 mg injection',
      'IV Haloperidol 5 mg for behavioral agitation',
    ],
    correctPharmacologyIndex: 0,
    pharmacologyRationale:
        'First-line emergent treatment: IV Lorazepam (positive allosteric modulator of GABA-A). Second-line urgent control: IV Levetiracetam (Keppra), Valproate, or Fosphenytoin per AES guidelines.',
    boardGuidelineCitation: 'American Epilepsy Society (AES) Guidelines for Status Epilepticus Management',
  ),
  OsceVignette(
    stationNumber: 4,
    title: 'Station 4: Spinal Cord Hemisection (Brown-Séquard)',
    chiefComplaint: 'Penetrating thoracic trauma with asymmetric motor and sensory deficits',
    clinicalVignette:
        'A 34-year-old male sustains a knife injury to the right mid-thoracic spine. On neurological evaluation: right lower extremity spastic paralysis with hyperreflexia and right-sided loss of vibratory and position sense below T6. Left lower extremity exhibits complete loss of pain and temperature sensation below T8, with intact motor function and vibration.',
    targetScenarioId: 'c5_brown_sequard',
    localizationOptions: [
      'Right T6 Spinal Cord Hemisection (Brown-Séquard Syndrome)',
      'Anterior Spinal Artery Infarction sparing posterior columns bilaterally',
      'Central Cord Syndrome (Syringomyelia) with suspended cape-like deficit',
      'Complete transverse spinal cord transection at T6',
    ],
    correctLocalizationIndex: 0,
    localizationRationale:
        'Classic Brown-Séquard: Ipsilateral corticospinal spastic paralysis + ipsilateral dorsal column loss (vibration/proprioception) + contralateral spinothalamic loss of pain/temp 1-2 levels below lesion.',
    procedureOptions: [
      'Axial Tract Localization & Neurosurgical exploration/decompression if compressive bone fragment or hematoma present',
      'High-dose systemic thrombolysis with IV Alteplase',
      'Immediate endovascular coiling of the anterior spinal artery',
      'Bilateral thoracic dorsal rhizotomy',
    ],
    correctProcedureIndex: 0,
    procedureRationale:
        'Spinal cord tract mapping confirms the precise anatomical lesion; neurosurgical decompression is indicated if there is mechanical compression or hematoma.',
    pharmacologyOptions: [
      'Maintenance of Spinal Cord Perfusion Pressure (MAP >= 85 mmHg) with IV vasopressors + surgical prep',
      'Immediate full heparin anticoagulation with PTT target 80s',
      'IV Mannitol bolus 2 g/kg q2h for spinal cord edema',
      'Immediate high-dose aspirin 325 mg + clopidogrel 75 mg',
    ],
    correctPharmacologyIndex: 0,
    pharmacologyRationale:
        'American Association of Neurological Surgeons (AANS) guidelines recommend maintaining MAP >= 85–90 mmHg for 7 days post-acute spinal cord injury to optimize spinal cord perfusion.',
    boardGuidelineCitation: 'AANS/CNS Guidelines for the Management of Acute Cervical & Thoracic Spine Injuries',
  ),
  OsceVignette(
    stationNumber: 5,
    title: 'Station 5: Acute Cauda Equina Syndrome',
    chiefComplaint: 'Severe low back pain, bilateral foot weakness, and acute urinary retention',
    clinicalVignette:
        'A 44-year-old warehouse worker presents with severe low back pain radiating down both legs following heavy lifting. He reports inability to void for 14 hours and wet undergarments (overflow incontinence). Exam reveals bilateral lower extremity weakness, absent ankle reflexes (S1), bilateral perianal "saddle anesthesia" (S3–S5), and lax anal sphincter tone. Bladder scan reveals 850 mL residual volume.',
    targetScenarioId: 'left_m1_stroke', // will switch to spinal localizer
    localizationOptions: [
      'Cauda Equina Syndrome (Compression of Lumbosacral Nerve Roots below L2)',
      'Conus Medullaris Syndrome with mixed UMN/LMN features',
      'Diabetic amyotrophy (lumbosacral radiculoplexus neuropathy)',
      'Guillain-Barré Syndrome (acute inflammatory demyelinating polyneuropathy)',
    ],
    correctLocalizationIndex: 0,
    localizationRationale:
        'Saddle anesthesia (S3-S5) + urinary retention with overflow incontinence + lax rectal tone + absent ankle jerks confirms a Lower Motor Neuron (LMN) compression of the cauda equina roots.',
    procedureOptions: [
      'Emergency Emergent Lumbar Decompressive Laminectomy and Microdiscectomy within 24–48 hours',
      'Elective physical therapy and outpatient epidural steroid injection in 2 weeks',
      'Diagnostic lumbar puncture with manometry at L3-L4',
      'Emergent endovascular embolization of lumbar arteries',
    ],
    correctProcedureIndex: 0,
    procedureRationale:
        'Cauda equina syndrome is a surgical emergency. Decompression within 24–48 hours of onset significantly reduces permanent neurogenic bowel, bladder, and erectile dysfunction.',
    pharmacologyOptions: [
      'Urgent urethral catheterization + IV analgesia + surgical prep; avoid anticholinergics and opioids that exacerbate urinary retention',
      'High-dose loop diuretics (Furosemide 80 mg IV) to force diuresis',
      'IV Tenecteplase 0.25 mg/kg bolus for spinal ischemia',
      'Oral Oxybutynin 10 mg for detrusor hyperactivity',
    ],
    correctPharmacologyIndex: 0,
    pharmacologyRationale:
        'Immediate bladder decompression via Foley catheter prevents permanent detrusor overdistension injury; urgent surgical consult takes immediate precedence.',
    boardGuidelineCitation: 'Spine Section / AANS Consensus on Cauda Equina Syndrome Surgical Timing',
  ),
];

class NeuroOsceExamPanel extends StatefulWidget {
  final VoidCallback onExitExamMode;
  final Function(NeuroClinicalScenario) onSyncScenario;
  final VoidCallback onDeployThrombectomy;
  final VoidCallback onDeployCoil;

  const NeuroOsceExamPanel({
    super.key,
    required this.onExitExamMode,
    required this.onSyncScenario,
    required this.onDeployThrombectomy,
    required this.onDeployCoil,
  });

  @override
  State<NeuroOsceExamPanel> createState() => _NeuroOsceExamPanelState();
}

class _NeuroOsceExamPanelState extends State<NeuroOsceExamPanel> {
  int _currentStationIndex = 0;
  int _timeRemainingSeconds = 180; // 3:00 per station
  Timer? _countdownTimer;

  int? _selectedLocalization;
  int? _selectedProcedure;
  int? _selectedPharmacology;

  bool _isStationSubmitted = false;
  final List<int> _stationScores = [];
  int _cumulativeScore = 0;

  @override
  void initState() {
    super.initState();
    _startStation(0);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startStation(int stationIndex) {
    _countdownTimer?.cancel();
    setState(() {
      _currentStationIndex = stationIndex;
      _timeRemainingSeconds = 180;
      _selectedLocalization = null;
      _selectedProcedure = null;
      _selectedPharmacology = null;
      _isStationSubmitted = false;
    });

    final vignette = kOsceVignettes[stationIndex];
    // Sync workstation scenario
    final targetScenario = kNeuroScenarios.firstWhere(
      (s) => s.id == vignette.targetScenarioId,
      orElse: () => kNeuroScenarios[0],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSyncScenario(targetScenario);
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemainingSeconds > 0) {
        setState(() {
          _timeRemainingSeconds--;
        });
      } else {
        timer.cancel();
        if (!_isStationSubmitted) {
          _submitStation(isTimeExpired: true);
        }
      }
    });
  }

  void _submitStation({bool isTimeExpired = false}) {
    _countdownTimer?.cancel();
    final vignette = kOsceVignettes[_currentStationIndex];

    int score = 0;
    // Localization: 30 pts
    if (_selectedLocalization == vignette.correctLocalizationIndex) {
      score += 30;
    }
    // Procedure: 30 pts
    if (_selectedProcedure == vignette.correctProcedureIndex) {
      score += 30;
    }
    // Pharmacology: 25 pts
    if (_selectedPharmacology == vignette.correctPharmacologyIndex) {
      score += 25;
    }
    // Speed: 15 pts (if completed within 120s with remaining > 60s: 15 pts, else 10 pts)
    if (!isTimeExpired) {
      if (_timeRemainingSeconds >= 60) {
        score += 15;
      } else {
        score += 8;
      }
    }

    // Execute active intervention in the 3D viewport for visual feedback
    if (_selectedProcedure == vignette.correctProcedureIndex) {
      if (vignette.stationNumber == 1) {
        widget.onDeployThrombectomy();
      } else if (vignette.stationNumber == 2) {
        widget.onDeployCoil();
      }
    }

    setState(() {
      _isStationSubmitted = true;
      if (_stationScores.length > _currentStationIndex) {
        _stationScores[_currentStationIndex] = score;
      } else {
        _stationScores.add(score);
      }
      _cumulativeScore = _stationScores.reduce((a, b) => a + b);
    });
  }

  void _nextStation() {
    if (_currentStationIndex < kOsceVignettes.length - 1) {
      _startStation(_currentStationIndex + 1);
    } else {
      _showFinalBoardReport();
    }
  }

  void _showFinalBoardReport() {
    final maxTotal = kOsceVignettes.length * 100;
    final percentage = ((_cumulativeScore / maxTotal) * 100).round();

    String tier;
    Color tierColor;
    if (percentage >= 90) {
      tier = 'HONORS PASS (Board Mastery)';
      tierColor = const Color(0xFF00E676);
    } else if (percentage >= 80) {
      tier = 'HIGH PASS (Clinical Competency)';
      tierColor = const Color(0xFF38BDF8);
    } else if (percentage >= 70) {
      tier = 'PASS (Satisfactory Performance)';
      tierColor = const Color(0xFFFFD740);
    } else {
      tier = 'REMEDIATION REQUIRED';
      tierColor = const Color(0xFFFF5252);
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B132B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tierColor, width: 2.0),
        ),
        title: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: tierColor, size: 28),
            const SizedBox(width: 10),
            const Text(
              'OSCE BOARD EXAMINATION REPORT',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tierColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(color: tierColor, fontSize: 36, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier,
                            style: TextStyle(color: tierColor, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cumulative Score: $_cumulativeScore / $maxTotal Points',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Station Performance Summary:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...List.generate(kOsceVignettes.length, (i) {
                final score = i < _stationScores.length ? _stationScores[i] : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('Station ${i + 1}: ${kOsceVignettes[i].title.split(':').last.trim()}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const Spacer(),
                      Text('$score / 100',
                          style: TextStyle(
                            color: score >= 80 ? const Color(0xFF00E676) : const Color(0xFFFFD740),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          )),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Educational Simulation Benchmark: Developed to mirror ACGME Neurology & ABNS Neurosurgery Milestones. SaMD Educational Standard Compliant.',
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startStation(0);
            },
            child: const Text('Retake Examination', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tierColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onExitExamMode();
            },
            child: const Text('Exit to Workstation', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vignette = kOsceVignettes[_currentStationIndex];
    final isTimeUrgent = _timeRemainingSeconds < 30;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Timer & Candidate Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF131D31),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1.0),
                    ),
                    child: const Text(
                      'OSCE #2026-NEURO',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Station ${_currentStationIndex + 1}/${kOsceVignettes.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const Spacer(),

                // Live Countdown Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTimeUrgent ? const Color(0xFF991B1B) : const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isTimeUrgent ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: isTimeUrgent ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_timeRemainingSeconds),
                        style: TextStyle(
                          color: isTimeUrgent ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Exit Exam Mode
                IconButton(
                  tooltip: 'Exit OSCE Exam Mode',
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onExitExamMode,
                ),
              ],
            ),
          ),

          // Station Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vignette Title & Chief Complaint
                  Text(
                    vignette.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CC: "${vignette.chiefComplaint}"',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Clinical Stem Box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF080C14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Text(
                      vignette.clinicalVignette,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Step 1: Localization & Diagnosis
                  _buildQuestionSection(
                    stepNum: 1,
                    title: 'Neuroanatomical Localization & Pathology',
                    options: vignette.localizationOptions,
                    selectedIndex: _selectedLocalization,
                    correctIndex: vignette.correctLocalizationIndex,
                    isSubmitted: _isStationSubmitted,
                    onSelected: (val) {
                      if (!_isStationSubmitted) setState(() => _selectedLocalization = val);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Step 2: Interventional Procedure
                  _buildQuestionSection(
                    stepNum: 2,
                    title: 'Immediate Procedural & Interventional Action',
                    options: vignette.procedureOptions,
                    selectedIndex: _selectedProcedure,
                    correctIndex: vignette.correctProcedureIndex,
                    isSubmitted: _isStationSubmitted,
                    onSelected: (val) {
                      if (!_isStationSubmitted) setState(() => _selectedProcedure = val);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Step 3: Pharmacotherapy
                  _buildQuestionSection(
                    stepNum: 3,
                    title: 'Evidence-Based Pharmacotherapy & Dosing',
                    options: vignette.pharmacologyOptions,
                    selectedIndex: _selectedPharmacology,
                    correctIndex: vignette.correctPharmacologyIndex,
                    isSubmitted: _isStationSubmitted,
                    onSelected: (val) {
                      if (!_isStationSubmitted) setState(() => _selectedPharmacology = val);
                    },
                  ),

                  // Faculty Rationale Box (Post-submission)
                  if (_isStationSubmitted) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school_rounded, color: Color(0xFF00E676), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Station Score: ${_stationScores[_currentStationIndex]} / 100 Points',
                                style: const TextStyle(
                                  color: Color(0xFF00E676),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Faculty Rationale: ${vignette.localizationRationale} ${vignette.procedureRationale} ${vignette.pharmacologyRationale}',
                            style: const TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.35),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Citation: ${vignette.boardGuidelineCitation}',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF080C14),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                if (!_isStationSubmitted)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                    label: const Text('Submit Station Responses', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: (_selectedLocalization != null &&
                            _selectedProcedure != null &&
                            _selectedPharmacology != null)
                        ? () => _submitStation()
                        : null,
                  )
                else
                  ElevatedButton.icon(
                    icon: Icon(
                      _currentStationIndex < kOsceVignettes.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.workspace_premium_rounded,
                      size: 15,
                    ),
                    label: Text(
                      _currentStationIndex < kOsceVignettes.length - 1
                          ? 'Next Station (${_currentStationIndex + 2}/${kOsceVignettes.length})'
                          : 'View Final Board Evaluation',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: _nextStation,
                  ),
                const Spacer(),
                Text(
                  'Cumulative: $_cumulativeScore Pts',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection({
    required int stepNum,
    required String title,
    required List<String> options,
    required int? selectedIndex,
    required int correctIndex,
    required bool isSubmitted,
    required ValueChanged<int> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $stepNum: $title',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...List.generate(options.length, (idx) {
          final isSelected = selectedIndex == idx;
          final isCorrect = idx == correctIndex;

          Color borderColor = const Color(0xFF1E293B);
          Color bgColor = const Color(0xFF0F172A);

          if (isSubmitted) {
            if (isCorrect) {
              borderColor = const Color(0xFF00E676);
              bgColor = const Color(0xFF064E3B).withValues(alpha: 0.4);
            } else if (isSelected && !isCorrect) {
              borderColor = const Color(0xFFFF5252);
              bgColor = const Color(0xFF991B1B).withValues(alpha: 0.3);
            }
          } else if (isSelected) {
            borderColor = const Color(0xFF38BDF8);
            bgColor = const Color(0xFF0284C7).withValues(alpha: 0.2);
          }

          return InkWell(
            onTap: () => onSelected(idx),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2.5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? (isSubmitted && !isCorrect
                            ? Icons.cancel_rounded
                            : Icons.check_circle_rounded)
                        : Icons.radio_button_unchecked,
                    size: 13,
                    color: isSubmitted
                        ? (isCorrect
                            ? const Color(0xFF00E676)
                            : (isSelected ? const Color(0xFFFF5252) : Colors.white38))
                        : (isSelected ? const Color(0xFF38BDF8) : Colors.white38),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      options[idx],
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isSubmitted
                            ? (isCorrect ? const Color(0xFF00E676) : Colors.white70)
                            : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
