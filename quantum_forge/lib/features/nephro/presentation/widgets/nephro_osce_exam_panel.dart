// ============================================================================
// NephroLab 3D: Interventional Nephrology & Timed Board OSCE Exam Panel
// ----------------------------------------------------------------------------
// 1. Interventional Procedures:
//    - Radiocephalic AV Fistula Creation & Rule-of-6s Maturation
//    - US-Guided Lower Pole Percutaneous Kidney Biopsy
//    - Right IJ Tunneled Cuffed Hemodialysis Catheter (Permcath)
// 2. Timed Board OSCE Exam Simulator (180s Countdown, Scored /100):
//    - 5 masked clinical vignettes covering critical nephrology emergencies.
//
// Strictly Educational Simulation — SaMD 7-Pillar Compliant.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/nephro_master_vitals_state.dart';

class NephroOsceExamPanel extends StatefulWidget {
  final NephroMasterVitalsState vitals;

  const NephroOsceExamPanel({super.key, required this.vitals});

  @override
  State<NephroOsceExamPanel> createState() => _NephroOsceExamPanelState();
}

class _NephroOsceExamPanelState extends State<NephroOsceExamPanel> {
  int _activeTab = 0; // 0=Interventions, 1=OSCE Mode

  // OSCE state
  int _currentVignetteIndex = 0;
  int _timeLeftSec = 180;
  Timer? _timer;
  bool _examStarted = false;
  int _selectedOptionIndex = -1;
  int _score = 0;
  bool _submitted = false;

  final List<Map<String, dynamic>> _vignettes = [
    {
      'title': 'Case 1: Emergency Hyperkalemia with Sine-Wave ECG',
      'stem': 'A 64-year-old dialysis patient misses two sessions and presents with profound weakness. Potassium is 8.4 mEq/L. ECG demonstrates widened QRS merging with T-waves into a sinusoidal wave. What is the most immediate lifesaving next step?',
      'options': [
        'A. Administer 10 units regular insulin + 50 mL D50W IV',
        'B. Administer 10% IV Calcium Gluconate (10-20 mL) over 2-3 minutes',
        'C. Administer oral Sodium Polystyrene Sulfonate (Kayexalate)',
        'D. Immediately transfer to dialysis suite without medications',
      ],
      'correct': 1,
      'explanation': 'Correct: IV Calcium Gluconate (or calcium chloride) immediately antagonizes potassium-induced membrane excitability, normalizing the cardiac resting potential within minutes and narrowing QRS to prevent ventricular fibrillation. Insulin/D50W shifts K+ intracellularly but does NOT stabilize the cardiac membrane.',
    },
    {
      'title': 'Case 2: Cardiorenal Syndrome Type 1',
      'stem': 'A 72-year-old patient with acute decompensated heart failure (EF 25%) develops oliguria and doubling of serum creatinine from 1.1 to 2.3 mg/dL despite high-dose IV loop diuretics. CVP is 20 mmHg. FENa is 0.3%. What is the primary hemodynamic driver?',
      'options': [
        'A. Direct nephrotoxic acute tubular injury from loop diuretics',
        'B. Severe renal venous congestion (high renal afterload) and low cardiac output',
        'C. Allergic acute interstitial nephritis from furosemide',
        'D. Bilateral renal artery thrombosis',
      ],
      'correct': 1,
      'explanation': 'Correct: Cardiorenal Syndrome Type 1 is primarily driven by renal venous hypertension (backward congestion, high CVP) collapsing the trans-renal perfusion pressure gradient (RPP = MAP - CVP), exacerbated by low forward cardiac output.',
    },
    {
      'title': 'Case 3: Pulmonary-Renal Syndrome & RPGN',
      'stem': 'A 28-year-old smoker presents with hemoptysis, dark brown urine, dyspnea, and creatinine 4.5 mg/dL. Renal biopsy shows extensive crescentic GN and linear IgG along the GBM. What autoantibody is causal?',
      'options': [
        'A. Anti-Proteinase 3 (c-ANCA)',
        'B. Anti-Myeloperoxidase (p-ANCA)',
        'C. Anti-Type IV Collagen α3 non-collagenous domain 1 (Anti-GBM)',
        'D. Anti-Double-Stranded DNA (anti-dsDNA)',
      ],
      'correct': 2,
      'explanation': 'Correct: Goodpasture syndrome (Anti-GBM disease) is caused by autoantibodies targeting the NC1 domain of the α3 chain of type IV collagen present in both glomerular and alveolar basement membranes.',
    },
    {
      'title': 'Case 4: Mixed Acid-Base Disorder in Salicylate Toxicity',
      'stem': 'A patient ingests an unknown quantity of aspirin. ABG shows pH 7.42, PaCO2 20 mmHg, HCO3⁻ 12 mEq/L, Na⁺ 140, Cl⁻ 100. What is the diagnosis?',
      'options': [
        'A. Pure Metabolic Acidosis with normal compensation',
        'B. Pure Respiratory Alkalosis with renal compensation',
        'C. Mixed High Anion Gap Metabolic Acidosis + Primary Respiratory Alkalosis',
        'D. Normal acid-base status given the normal pH of 7.42',
      ],
      'correct': 2,
      'explanation': 'Correct: Anion Gap = 140 - (100 + 12) = 28 mEq/L (HAGMA). Winter\'s expected PaCO2 = (1.5 x 12) + 8 = 26 mmHg. Actual PaCO2 is 20 mmHg (< 26), revealing a concomitant primary respiratory alkalosis from direct medullary respiratory center stimulation.',
    },
    {
      'title': 'Case 5: Dialysis Disequilibrium Syndrome (DDS)',
      'stem': 'A patient with newly diagnosed ESRD and initial BUN 165 mg/dL undergoes aggressive first hemodialysis for 4.5 hours with high blood flow (Qb 400 mL/min). Near the end of treatment, the patient becomes confused, nauseated, and develops seizures. What is the mechanism?',
      'options': [
        'A. Acute cerebral ischemic stroke from intradialytic hypotension',
        'B. Rapid urea clearance from blood creating a trans-cerebral osmotic gradient and cerebral edema',
        'C. Acute hypercalcemia from dialysate bath error',
        'D. Dialyzer membrane anaphylactoid reaction',
      ],
      'correct': 1,
      'explanation': 'Correct: Urea exits brain tissue much slower than plasma due to low BBB urea transporters (UT-B). Rapid reduction of plasma urea leaves the brain hyperosmolar, drawing water into neurons and causing acute cerebral edema (DDS). Initial dialysis in severe azotemia must be gentle (2-2.5h, low Qb 200 mL/min).',
    },
  ];

  void _startExam() {
    setState(() {
      _examStarted = true;
      _timeLeftSec = 180;
      _currentVignetteIndex = 0;
      _score = 0;
      _selectedOptionIndex = -1;
      _submitted = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeftSec > 0) {
        setState(() => _timeLeftSec--);
      } else {
        t.cancel();
      }
    });
  }

  void _submitAnswer() {
    if (_selectedOptionIndex == -1) return;
    final vig = _vignettes[_currentVignetteIndex];
    if (_selectedOptionIndex == vig['correct']) {
      _score += 20; // 5 questions x 20 = 100 max
    }
    setState(() => _submitted = true);
  }

  void _nextQuestion() {
    if (_currentVignetteIndex < _vignettes.length - 1) {
      setState(() {
        _currentVignetteIndex++;
        _selectedOptionIndex = -1;
        _submitted = false;
      });
    } else {
      _timer?.cancel();
      setState(() {
        _examStarted = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070D1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Sub-Header Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, size: 14, color: Color(0xFFEAB308)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'INTERVENTIONAL NEPHROLOGY & TIMED OSCE EXAM',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Procedures', style: TextStyle(fontSize: 9.5)),
                  selected: _activeTab == 0,
                  selectedColor: const Color(0xFF0284C7),
                  onSelected: (val) => setState(() => _activeTab = 0),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Timed OSCE', style: TextStyle(fontSize: 9.5)),
                  selected: _activeTab == 1,
                  selectedColor: const Color(0xFFEAB308),
                  onSelected: (val) => setState(() => _activeTab = 1),
                ),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 0 ? _buildInterventionsTab() : _buildOsceExamTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInterventionCard(
            title: '1. Radiocephalic AV Fistula (Cimino-Brescia)',
            tag: 'VASCULAR ACCESS',
            color: const Color(0xFF38BDF8),
            description: 'Surgical side-to-end anastomosis of radial artery to cephalic vein at wrist. First choice access for ESRD hemodialysis.',
            ruleOf6: 'Rule of 6s for Maturation: Flow > 600 mL/min, Diameter > 6 mm, Depth < 6 mm from skin, Evaluated at 6 weeks.',
          ),
          const SizedBox(height: 10),
          _buildInterventionCard(
            title: '2. US-Guided Percutaneous Kidney Biopsy',
            tag: 'PATHOLOGY SAMPLING',
            color: const Color(0xFF10B981),
            description: 'Target: Lower pole cortex of native kidney (or anterosuperior graft). 16-18G spring-loaded automated core needle under continuous real-time ultrasound.',
            ruleOf6: 'Safety Protocol: Coagulation normal (INR < 1.3, Plt > 100k, BP < 140/90). Patient holds breath at end-expiration. Post-biopsy 6h strict bed rest to monitor for retroperitoneal hematoma.',
          ),
          const SizedBox(height: 10),
          _buildInterventionCard(
            title: '3. Tunneled Cuffed Hemodialysis Catheter (Permcath)',
            tag: 'CENTRAL VENOUS',
            color: const Color(0xFFD946EF),
            description: 'Ultrasound-guided puncture of Right Internal Jugular Vein. Subcutaneous tunnel with polyester (Dacron) cuff positioned 2 cm inside tunnel tract.',
            ruleOf6: 'Fluoroscopic Placement: Catheter tip placed at cavoatrial junction or upper right atrium to maximize blood flow (Qb > 350 mL/min) and avoid recirculation.',
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionCard({
    required String title,
    required String tag,
    required Color color,
    required String description,
    required String ruleOf6,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(tag, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
          const SizedBox(height: 4),
          Text(ruleOf6, style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 9.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOsceExamTab() {
    if (!_examStarted && _currentVignetteIndex == 0 && _score == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_rounded, size: 36, color: Color(0xFFEAB308)),
            const SizedBox(height: 10),
            const Text('TIMED NEPHROLOGY BOARD OSCE EXAM', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('5 Clinical Vignettes · 180s Countdown · Instant Scoring & Rationale', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('START 180s EXAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEAB308), foregroundColor: Colors.black),
              onPressed: _startExam,
            ),
          ],
        ),
      );
    }

    if (!_examStarted && _currentVignetteIndex >= _vignettes.length - 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 40, color: Color(0xFF10B981)),
            const SizedBox(height: 10),
            Text('EXAM COMPLETE: $_score / 100', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_score >= 80 ? 'Mastery Passed: Outstanding Nephrology Fellowship Performance!' : 'Review Clinical Vignette Rationales & Re-test.', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _startExam,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              child: const Text('RE-TAKE OSCE EXAM'),
            ),
          ],
        ),
      );
    }

    final vig = _vignettes[_currentVignetteIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('QUESTION ${_currentVignetteIndex + 1} OF ${_vignettes.length}', style: const TextStyle(color: Color(0xFFEAB308), fontSize: 10, fontWeight: FontWeight.bold)),
              Text('⏱️ TIME: ${_timeLeftSec}s | SCORE: $_score / 100', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(vig['title'], style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(vig['stem'], style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5, height: 1.4)),
          const SizedBox(height: 10),
          ...List.generate((vig['options'] as List).length, (idx) {
            final opt = vig['options'][idx];
            final isSelected = _selectedOptionIndex == idx;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: _submitted ? null : () => setState(() => _selectedOptionIndex = idx),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.3) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B)),
                  ),
                  child: Text(opt, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontSize: 10)),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          if (!_submitted)
            ElevatedButton(
              onPressed: _selectedOptionIndex != -1 ? _submitAnswer : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black),
              child: const Text('SUBMIT ANSWER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedOptionIndex == vig['correct'] ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _selectedOptionIndex == vig['correct'] ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              ),
              child: Text(vig['explanation'], style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.4)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black),
              child: Text(_currentVignetteIndex < _vignettes.length - 1 ? 'NEXT QUESTION →' : 'FINISH EXAM', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
