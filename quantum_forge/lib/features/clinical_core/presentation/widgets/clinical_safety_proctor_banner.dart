// ============================================================================
// Clinical Safety Proctor Banner (Closed-Loop Socratic AI Attending Proctor)
// ----------------------------------------------------------------------------
// Real-time clinical safety interceptor monitoring contraindicated bedside actions
// across CardioCath 3D, NeuroLab 3D, and NephroLab 3D:
// 1. Nitroglycerin in Inferior / RV STEMI (Catastrophic RV preload collapse).
// 2. Hyperventilation (PaCO2 < 25 mmHg) in Acute TBI (Profound cerebral ischemia).
// 3. High-dose NSAIDs / Unadjusted Vancomycin in Renal Impairment (eGFR < 30 mL/min).
//
// Strictly Educational Simulation — 7-Pillar SaMD Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/features/clinical_core/data/multi_organ_patient_state.dart';
import 'package:quantum_forge/features/cardiac/data/cardiac_master_vitals_state.dart';
import 'package:quantum_forge/features/cardiac/data/coronary_hemodynamics_engine.dart';

enum ClinicalContraindicationType {
  nitrateInRvMi(
    title: 'CONTRAINDICATION: Nitroglycerin in Inferior / RV STEMI',
    system: 'Cardiovascular',
    severity: 'CRITICAL / LIFE-THREATENING',
    badge: 'PRELOAD COLLAPSE',
    color: Color(0xFFFF1744),
    summary:
        'Administering nitrates in acute RV infarction causes peripheral venodilation, drops RV preload, and collapses cardiac output.',
    pathophysiology:
        'The ischemic right ventricle is stiff and compliance-restricted, functioning as a passive conduit dependent on elevated venous return (preload) to generate stroke volume. Administering Nitroglycerin causes systemic venodilation, drastically reducing right ventricular end-diastolic volume (RVEDV). This leads to acute circulatory collapse, refractory hypotension, and cardiogenic shock.',
    correctiveAction:
        'Withhold all nitrates and diuretics immediately. Administer aggressive isotonic crystalloid volume expansion (500-1000 mL Normal Saline) to restore RV filling pressure. If bradycardic, administer Atropine 0.5-1 mg IV.',
    guidelineRef: 'ACC/AHA 2023 STEMI Management Guidelines • Class III: Harm',
    socraticQuestion:
        'Why does a patient with an inferior MI and elevated JVP develop immediate syncope and BP 60/40 after sublingual nitroglycerin?',
    options: [
      'Nitrates cause paradoxical coronary spasm of the LAD.',
      'The ischemic RV is exquisitely preload-dependent; venodilation collapses stroke volume.',
      'Nitrates stimulate the Bezold-Jarisch reflex inducing hyperdynamic shock.',
      'Nitrates competitively block beta-1 adrenergic receptors in the AV node.',
    ],
    correctOptionIndex: 1,
  ),
  hyperventilationInTbi(
    title: 'CONTRAINDICATION: Severe Hyperventilation (PaCO₂ < 25 mmHg) in TBI',
    system: 'Neurocritical Care',
    severity: 'HIGH / ISCHEMIC HARM',
    badge: 'CEREBRAL ISCHEMIA',
    color: Color(0xFFFF9100),
    summary:
        'Aggressive hyperventilation causes excessive cerebral arteriolar vasoconstriction, critically decreasing cerebral blood flow (CBF).',
    pathophysiology:
        'Cerebral arterioles are exquisitely sensitive to arterial PaCO₂ (~3-4% change in CBF per mmHg PaCO₂). While hyperventilation transiently lowers ICP by decreasing intracranial blood volume, dropping PaCO₂ < 25 mmHg precipitates profound vasoconstriction that crosses the ischemic threshold (< 18 mL/100g/min). This converts the vulnerable ischemic penumbra into irreversible cerebral infarction.',
    correctiveAction:
        'Maintain normocapnia (PaCO₂ 35-40 mmHg). Use hyperosmolar therapy (Hypertonic 3% Saline or 20% Mannitol) and elevated head of bed (30°) for ICP crises rather than prolonged aggressive hyperventilation.',
    guidelineRef: 'Brain Trauma Foundation Guidelines (4th Ed) • Level IIB Recommendation',
    socraticQuestion:
        'In a patient with severe TBI and ICP 28 mmHg, why is hyperventilating to PaCO₂ 20 mmHg considered detrimental despite lowering ICP?',
    options: [
      'It causes cerebral hyperemia and vasogenic edema.',
      'Severe hypocapnic vasoconstriction reduces cerebral blood flow below ischemic thresholds.',
      'It increases CSF production at the choroid plexus.',
      'It induces sudden metabolic alkalosis that depresses cardiac output.',
    ],
    correctOptionIndex: 1,
  ),
  nsaidInSevereAki(
    title: 'CONTRAINDICATION: Nephrotoxic Dosing in Severe Impairment (eGFR < 30)',
    system: 'Nephrology & Pharmacotherapy',
    severity: 'HIGH / TUBULAR INJURY',
    badge: 'HEMODYNAMIC AKI',
    color: Color(0xFFFF5252),
    summary:
        'NSAIDs block vasodilatory prostaglandins (PGI₂/PGE₂), constricting afferent arterioles and destroying remaining filtration.',
    pathophysiology:
        'In renal impairment or low-flow states, renal perfusion is maintained by local prostaglandin synthesis (PGI₂/PGE₂) that dilates the afferent arteriole to sustain glomerular capillary hydrostatic pressure. Non-selective or COX-2 selective NSAIDs abolish this compensatory mechanism, triggering severe afferent vasoconstriction, precipitous drop in eGFR, acute tubular necrosis (ATN), and hyperkalemia.',
    correctiveAction:
        'Discontinue all NSAIDs (Ketorolac, Ibuprofen, Naproxen). Utilize non-nephrotoxic analgesia (Acetaminophen, topical agents, regional blocks, or short-acting titrated opioids). Adjust renally eliminated antimicrobials per creatinine clearance.',
    guidelineRef: 'KDIGO Clinical Practice Guideline for Acute Kidney Injury',
    socraticQuestion:
        'What is the precise intrarenal hemodynamic consequence of NSAID administration in a patient with cardiorenal syndrome and eGFR 22 mL/min?',
    options: [
      'Afferent arteriolar constriction resulting in loss of intraglomerular pressure.',
      'Efferent arteriolar dilation via kinin inhibition.',
      'Direct cytotoxicity to the macula densa cells.',
      'Immune-mediated deposition of immune complexes in podocyte slit diaphragms.',
    ],
    correctOptionIndex: 0,
  );

  final String title;
  final String system;
  final String severity;
  final String badge;
  final Color color;
  final String summary;
  final String pathophysiology;
  final String correctiveAction;
  final String guidelineRef;
  final String socraticQuestion;
  final List<String> options;
  final int correctOptionIndex;

  const ClinicalContraindicationType({
    required this.title,
    required this.system,
    required this.severity,
    required this.badge,
    required this.color,
    required this.summary,
    required this.pathophysiology,
    required this.correctiveAction,
    required this.guidelineRef,
    required this.socraticQuestion,
    required this.options,
    required this.correctOptionIndex,
  });
}

class ClinicalSafetyProctorBanner extends StatefulWidget {
  final MultiOrganPatientState patientState;
  final bool isMobile;

  const ClinicalSafetyProctorBanner({
    super.key,
    required this.patientState,
    this.isMobile = false,
  });

  @override
  State<ClinicalSafetyProctorBanner> createState() => _ClinicalSafetyProctorBannerState();
}

class _ClinicalSafetyProctorBannerState extends State<ClinicalSafetyProctorBanner> {
  ClinicalContraindicationType? _simulatedDrill;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.patientState,
      builder: (context, _) {
        final activeAlert = _simulatedDrill ?? _detectActiveContraindication();
        if (activeAlert == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: activeAlert.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: activeAlert.color.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: activeAlert.color.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeAlert.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, color: activeAlert.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: activeAlert.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            activeAlert.badge,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'SOCRATIC ATTENDING INTERCEPTOR',
                            style: TextStyle(
                              color: activeAlert.color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeAlert.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeAlert.summary,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                      maxLines: widget.isMobile ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeAlert.color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.school_rounded, size: 14),
                label: const Text('Socratic Review'),
                onPressed: () => _openSocraticDialog(context, activeAlert),
              ),
              if (_simulatedDrill != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Dismiss Drill Simulation',
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  onPressed: () => setState(() => _simulatedDrill = null),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  ClinicalContraindicationType? _detectActiveContraindication() {
    final cardiac = widget.patientState.cardiacVitals;
    final neuro = widget.patientState.neuroVitals;
    final nephro = widget.patientState.nephroVitals;

    // 1. Nitroglycerin in Inferior/RV STEMI
    if (cardiac.activeSituation == CardiacClinicalSituation.inferiorRvMi ||
        (cardiac.targetRhythm == OscilloscopeRhythmType.sinusBrady && cardiac.stElevationMm >= 3.5)) {
      return ClinicalContraindicationType.nitrateInRvMi;
    }

    // 2. Hyperventilation in Acute TBI
    if (neuro.paco2MmHg < 25.0 || (neuro.icpMmHg >= 22.0 && neuro.paco2MmHg < 28.0)) {
      return ClinicalContraindicationType.hyperventilationInTbi;
    }

    // 3. Nephrotoxic risk in severe impairment
    if (nephro.egfrMlMin < 30.0 && nephro.clearanceRatio < 0.35) {
      return ClinicalContraindicationType.nsaidInSevereAki;
    }

    return null;
  }

  void _openSocraticDialog(BuildContext context, ClinicalContraindicationType alert) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _SocraticAttendingDialog(
        alert: alert,
        onResolve: () {
          Navigator.of(ctx).pop();
          if (_simulatedDrill != null) {
            setState(() => _simulatedDrill = null);
          }
        },
      ),
    );
  }
}

class _SocraticAttendingDialog extends StatefulWidget {
  final ClinicalContraindicationType alert;
  final VoidCallback onResolve;

  const _SocraticAttendingDialog({
    required this.alert,
    required this.onResolve,
  });

  @override
  State<_SocraticAttendingDialog> createState() => _SocraticAttendingDialogState();
}

class _SocraticAttendingDialogState extends State<_SocraticAttendingDialog> {
  int? _selectedAnswer;
  bool _hasSubmitted = false;

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final isCorrect = _selectedAnswer == alert.correctOptionIndex;

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: alert.color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: alert.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.school_rounded, color: alert.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACADEMIC ROUNDS: CLINICAL ERROR INTERCEPT',
                          style: TextStyle(
                            color: alert.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alert.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF1E293B), height: 1),
              const SizedBox(height: 14),

              // Pathophysiological Pearl
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔬 Pathophysiological Mechanism',
                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.pathophysiology,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Socratic Question
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: alert.color.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, color: Color(0xFFFFD600), size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Attending Board Question',
                          style: TextStyle(color: Color(0xFFFFD600), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.socraticQuestion,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    for (int i = 0; i < alert.options.length; i++) ...[
                      InkWell(
                        onTap: _hasSubmitted ? null : () => setState(() => _selectedAnswer = i),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getOptionBackgroundColor(i, alert.correctOptionIndex),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _getOptionBorderColor(i, alert.correctOptionIndex)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${String.fromCharCode(65 + i)}.',
                                style: TextStyle(
                                  color: _selectedAnswer == i ? Colors.white : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alert.options[i],
                                  style: TextStyle(
                                    color: _selectedAnswer == i ? Colors.white : const Color(0xFFE2E8F0),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (!_hasSubmitted)
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _selectedAnswer == null ? null : () => setState(() => _hasSubmitted = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: const Text('Submit Answer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? const Color(0xFF00E676).withValues(alpha: 0.15)
                              : const Color(0xFFFF1744).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCorrect ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: isCorrect ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isCorrect
                                    ? 'Correct! You understood the underlying hemodynamics.'
                                    : 'Incorrect. Key target concept: review the pathophysiology above.',
                                style: TextStyle(
                                  color: isCorrect ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Corrective Protocol
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🛡️ Evidence-Based Corrective Protocol',
                      style: TextStyle(color: Color(0xFF00E676), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.correctiveAction,
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Citation: ${alert.guidelineRef}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Dismiss', style: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.onResolve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Apply Safe Protocol', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getOptionBackgroundColor(int index, int correctIndex) {
    if (!_hasSubmitted) {
      return _selectedAnswer == index ? const Color(0xFF1E293B) : Colors.transparent;
    }
    if (index == correctIndex) {
      return const Color(0xFF00E676).withValues(alpha: 0.2);
    }
    if (_selectedAnswer == index) {
      return const Color(0xFFFF1744).withValues(alpha: 0.2);
    }
    return Colors.transparent;
  }

  Color _getOptionBorderColor(int index, int correctIndex) {
    if (!_hasSubmitted) {
      return _selectedAnswer == index ? const Color(0xFF00E5FF) : const Color(0xFF334155);
    }
    if (index == correctIndex) {
      return const Color(0xFF00E676);
    }
    if (_selectedAnswer == index) {
      return const Color(0xFFFF1744);
    }
    return const Color(0xFF334155);
  }
}
