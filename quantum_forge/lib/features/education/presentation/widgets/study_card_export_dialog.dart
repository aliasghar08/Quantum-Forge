import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantum_forge/features/cardiac/data/coronary_hemodynamics_engine.dart';

// ============================================================================
// WARD ROUNDS & ANKI FLASHCARD EXPORT DIALOG
// ----------------------------------------------------------------------------
// Generates a 1-page clinical revision sheet and Anki-compatible flashcard
// (Cloze & Q/A format) for medical (MBBS, USMLE, NEET-PG) and pharmacy (Pharm-D)
// students. Integrates live hemodynamic metrics, pharmacology mechanisms, and
// board pearls.
// ============================================================================

class StudyCardExportDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String presentation;
  final String ecgWaveformFindings;
  final String hemodynamics;
  final String mechanism;
  final String boardPearls;
  final String contraindications;
  final String firstLineManagement;
  final List<String> citations;
  final String? disciplineBadge;

  const StudyCardExportDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.presentation,
    required this.ecgWaveformFindings,
    required this.hemodynamics,
    required this.mechanism,
    required this.boardPearls,
    required this.contraindications,
    required this.firstLineManagement,
    this.citations = const [
      'ACC/AHA Guideline for the Management of Acute Coronary Syndromes (JACC 2023)',
      'Goodman & Gilman\'s The Pharmacological Basis of Therapeutics (14th Ed)',
      'Braunwald\'s Heart Disease: A Textbook of Cardiovascular Medicine (12th Ed)',
    ],
    this.disciplineBadge = 'MBBS / PHARM-D / USMLE HIGH-YIELD',
  });

  /// Factory constructor to generate study card from current Oscilloscope rhythm
  factory StudyCardExportDialog.fromOscilloscopeRhythm({
    required OscilloscopeRhythmType rhythm,
    required double sys,
    required double dia,
    required double bpm,
    String? scenarioTitle,
  }) {
    switch (rhythm) {
      case OscilloscopeRhythmType.avb2Mobitz2:
        return StudyCardExportDialog(
          title: 'Second-Degree AV Block: Mobitz Type II',
          subtitle: 'Infranodal Conduction Defect | High Risk of Stokes-Adams Syncope',
          presentation:
              'Elderly patient with fatigue, lightheadedness, or sudden syncope without prodrome. Often associated with extensive anterior wall MI or progressive His-Purkinje fibrosis (Lenègre-Lev disease).',
          ecgWaveformFindings:
              'Intermittent non-conducted P waves with CONSTANT PR intervals in conducted beats. Wide QRS (> 120 ms) in > 70% of cases indicating bundle branch or fascicular block. No progressive PR prolongation (distinguishing it from Mobitz I Wenckebach).',
          hemodynamics:
              'Transient loss of stroke volume during dropped beats producing sudden arterial pulse deficits (ABP ${sys.round()}/${dia.round()} mmHg). Risk of hemodynamic collapse if conduction ratio falls to 2:1 or 3:1.',
          mechanism:
              'Structural disease of the His bundle or bilateral bundle branches (infranodal block). All-or-none conduction failure across refractory sub-nodal tissue.',
          boardPearls:
              '• Constant PR interval before dropped beats is pathognomonic.\n• NEVER responsive to Atropine (atropine increases atrial rate and can worsen infranodal block).\n• Class I indication for definitive Permanent Pacemaker (PPM) regardless of symptoms.',
          contraindications:
              'Strictly avoid beta-blockers, non-dihydropyridine calcium channel blockers (verapamil/diltiazem), and digoxin.',
          firstLineManagement:
              '1. Transcutaneous Pacing (TCP) or temporary transvenous pacing wire for acute stabilization.\n2. Emergent electrophysiology consultation for dual-chamber (DDD) permanent pacemaker implantation.',
        );
      case OscilloscopeRhythmType.torsades:
        return StudyCardExportDialog(
          title: 'Torsades de Pointes (Polymorphic VT)',
          subtitle: 'Drug-Induced Long QT Syndrome | Early Afterdepolarizations (EADs)',
          presentation:
              'Palpitations, sudden syncope, or cardiac arrest in patients receiving QT-prolonging pharmacotherapy (macrolides, fluoroquinolones, antipsychotics, Class Ia/III antiarrhythmics) or with hypokalemia/hypomagnesemia.',
          ecgWaveformFindings:
              'Baseline QTc > 500 ms (often > 540 ms). Polymorphic ventricular tachycardia with undulating, twisting QRS amplitude peaks revolving around the isoelectric line at 180–250 bpm.',
          hemodynamics:
              'Profound systolic hypotension (ABP ${sys.round()}/${dia.round()} mmHg), near-zero effective forward stroke volume, plethysmograph collapse.',
          mechanism:
              'Inhibition of rapid delayed rectifier K+ current (IKr / hERG channel) prolongs Phase 3 repolarization. Prolonged plateau allows reactivated L-type Ca2+ channels to trigger Early Afterdepolarizations (EADs).',
          boardPearls:
              '• Magnesium Sulfate 2g IV push is first-line even if serum magnesium is normal.\n• Class Ia and Class III antiarrhythmics are STRICTLY CONTRAINDICATED (worsen QT prolong).\n• Isoproterenol infusion or overdrive pacing (90–110 bpm) shortens QT if refractory.',
          contraindications:
              'Amiodarone, Sotalol, Procainamide, Haloperidol, Methadone, Ondansetron.',
          firstLineManagement:
              '1. IV Magnesium Sulfate 2 g over 1–2 minutes.\n2. Correct serum potassium to high-normal (4.5–5.0 mEq/L).\n3. Electrical unsynchronized defibrillation if degenerating to pulseless VT/VF.',
        );
      case OscilloscopeRhythmType.svt:
        return StudyCardExportDialog(
          title: 'Supraventricular Tachycardia (AVNRT / AVRT)',
          subtitle: 'Re-entrant Tachyarrhythmia | Dual AV Nodal Physiology',
          presentation:
              'Sudden-onset, rapid, regular "fluttering" in the chest or neck, lightheadedness, mild polyuria (due to atrial natriuretic peptide release). Often triggered by caffeine, stress, or alcohol.',
          ecgWaveformFindings:
              'Regular narrow-complex tachycardia (QRS < 120 ms) at 150–220 bpm. P waves hidden within QRS complex (pseudo-r\' in V1) or appearing just after QRS.',
          hemodynamics:
              'Preserved ABP initially (${sys.round()}/${dia.round()} mmHg) but shortened diastolic filling time limits stroke volume at extreme rates.',
          mechanism:
              'Re-entry through dual AV nodal pathways (slow alpha pathway with short refractory period, fast beta pathway with long refractory period).',
          boardPearls:
              '• First step in stable patient: Vagal maneuvers (modified Valsalva maneuver with leg elevation).\n• First-line drug: IV Adenosine (6 mg rapid bolus through large proximal vein followed by 20 mL saline flush).\n• Adenosine causes brief alarming ~2s asystolic pause before restoring NSR.',
          contraindications:
              'Adenosine contraindicated in active severe bronchospasm/asthma or pre-excited AFib in WPW.',
          firstLineManagement:
              '1. Modified Valsalva maneuver.\n2. IV Adenosine 6 mg rapid push (repeat 12 mg if unsuccessful).\n3. Synchronized DC cardioversion (50–100 J) if hemodynamically unstable.',
        );
      case OscilloscopeRhythmType.sinusBrady:
        return StudyCardExportDialog(
          title: 'Symptomatic Sinus Bradycardia & Conduction Slowing',
          subtitle: 'Vagal Hypertonia, Sinus Node Dysfunction, or Inferior Wall Ischemia',
          presentation:
              'Fatigue, exertional intolerance, presyncope, or acute shock during inferior STEMI (due to RCA occlusion supplying the SA node in 60% of individuals).',
          ecgWaveformFindings:
              'Normal P-QRS-T morphology with regular rhythm at rate < 50 bpm (currently ${bpm.round()} bpm). Normal PR interval (< 200 ms).',
          hemodynamics:
              'Cardiac output = Heart Rate × Stroke Volume; severe bradycardia limits cardiac index, reducing MAP (${((2 * dia + sys) / 3).round()} mmHg).',
          mechanism:
              'Decreased Phase 4 diastolic depolarization of SA nodal pacemaker cells mediated by hyperpolarization or excessive parasympathetic muscarinic M2 receptor activation.',
          boardPearls:
              '• Symptomatic bradycardia: Atropine 1 mg IV push (repeat q3–5m, max 3 mg).\n• Atropine works by competitive muscarinic M2 receptor blockade.\n• In cardiac transplant patients, Atropine is INEFFECTIVE (denervated heart); use Isoproterenol.',
          contraindications:
              'Do not give sub-therapeutic Atropine doses (< 0.5 mg), as central vagal stimulation can paradoxically worsen bradycardia.',
          firstLineManagement:
              '1. Atropine 1 mg IV push.\n2. Transcutaneous Pacing (TCP) if refractory or hemodynamically compromised.\n3. Dopamine or Epinephrine infusion if pacing unavailable.',
        );
      default:
        return StudyCardExportDialog(
          title: scenarioTitle ?? rhythm.label,
          subtitle: 'Clinical Hemodynamics & Bedside Multi-Parameter Correlate',
          presentation:
              'Patient presenting with acute chest discomfort or rhythm abnormality requiring continuous 5-channel bedside telemetry monitoring in the ICU/CCU or Cath Lab.',
          ecgWaveformFindings:
              'Continuous dual-lead monitoring (${rhythm.label}, rate ${bpm.round()} bpm). QRS morphology reflects synchronized ventricular depolarization.',
          hemodynamics:
              'Invasive arterial pressure ${sys.round()}/${dia.round()} mmHg (MAP ${((2 * dia + sys) / 3).round()} mmHg). Plethysmograph perfusion intact.',
          mechanism:
              'Cardiac electro-mechanical coupling under autonomous and neurohormonal regulation.',
          boardPearls:
              '• Synchronize clinical findings with hemodynamic parameters.\n• Correlate invasive arterial dicrotic notch timing with ECG T-wave completion.\n• SpO2 plethysmogram pulse wave arrives ~150 ms after QRS R-wave.',
          contraindications:
              'Tailored to specific underlying etiology and electrolyte disturbances.',
          firstLineManagement:
              'Continuous multi-parameter monitoring, 12-lead diagnostic ECG, and targeted pharmacological stabilization.',
        );
    }
  }

  /// Copies an Anki-compatible flashcard text (Cloze and Q/A format) to the clipboard
  void _copyAnkiFlashcard(BuildContext context) {
    final ankiText = '''
# ── ANKI FLASHCARD: $title ──
# Deck: QuantumForge::USMLE_MBBS::Cardiology

## Front (Question):
What is the clinical presentation, pathognomonic ECG/hemodynamic findings, and first-line management for **$title**?

## Back (Answer):
**Clinical Presentation:**
$presentation

**ECG & Waveform Findings:**
$ecgWaveformFindings

**Hemodynamics:**
$hemodynamics

**Pathophysiology / Mechanism:**
$mechanism

**High-Yield Board Pearls:**
$boardPearls

**Contraindications & Traps:**
$contraindications

**First-Line Management:**
$firstLineManagement

---
*Generated by Quantum Forge Medical Education Engine*
''';

    Clipboard.setData(ClipboardData(text: ankiText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Anki Flashcard copied to clipboard! (Ready to paste into Anki desktop or mobile)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F1722),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Copies a full Markdown Ward Study Sheet to the clipboard
  void _copyWardStudySheet(BuildContext context) {
    final sheetText = '''
# 📋 CLINICAL WARD ROUNDS STUDY DOSSIER: $title
**$subtitle**
*Discipline Focus: $disciplineBadge*

---

### 1. Clinical Presentation & Vignette Correlate
$presentation

### 2. ECG & Hemodynamic Diagnostic Signatures
* **ECG Findings:** $ecgWaveformFindings
* **Hemodynamic Profile:** $hemodynamics

### 3. Molecular Pathophysiology & Mechanism
$mechanism

### 4. High-Yield Medical Board Pearls (USMLE / MBBS / NEET-PG / Pharm-D)
$boardPearls

### 5. Critical Contraindications & Clinical Traps
⚠️ **$contraindications**

### 6. Guideline-Directed First-Line Management
$firstLineManagement

---

### Verified Evidence & References
${citations.map((c) => '• $c').join('\n')}

*Generated by Quantum Forge 3D Health Education Suite • Educational Simulation Only (SaMD 7-Pillar Shield)*
''';

    Clipboard.setData(ClipboardData(text: sheetText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.description_rounded, color: Color(0xFF00E5FF), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Full Ward Study Sheet copied to clipboard! (Formatted Markdown)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F1722),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0F18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 860),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Bar ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF00E5FF), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                disciplineBadge ?? 'WARD ROUNDS STUDY SHEET',
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ANKI & USMLE READY',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Scrollable Body Sections ─────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionCard(
                        title: 'Clinical Presentation & Demographics',
                        icon: Icons.person_search_rounded,
                        accent: const Color(0xFF38BDF8),
                        content: presentation,
                      ),
                      const SizedBox(height: 10),
                      _buildSectionCard(
                        title: 'ECG & Hemodynamic Waveform Signatures',
                        icon: Icons.monitor_heart_rounded,
                        accent: const Color(0xFF00E676),
                        content: '$ecgWaveformFindings\n\n• Hemodynamics: $hemodynamics',
                      ),
                      const SizedBox(height: 10),
                      _buildSectionCard(
                        title: 'Molecular Pathophysiology & Drug Mechanism',
                        icon: Icons.biotech_rounded,
                        accent: const Color(0xFFA78BFA),
                        content: mechanism,
                      ),
                      const SizedBox(height: 10),
                      _buildSectionCard(
                        title: 'High-Yield Medical Board Pearls',
                        icon: Icons.verified_rounded,
                        accent: const Color(0xFFFFD600),
                        content: boardPearls,
                      ),
                      const SizedBox(height: 10),
                      _buildSectionCard(
                        title: 'Critical Contraindications & Clinical Traps',
                        icon: Icons.warning_amber_rounded,
                        accent: const Color(0xFFFF5252),
                        content: contraindications,
                      ),
                      const SizedBox(height: 10),
                      _buildSectionCard(
                        title: 'Guideline-Directed First-Line Management',
                        icon: Icons.medical_services_rounded,
                        accent: const Color(0xFF00E5FF),
                        content: firstLineManagement,
                      ),
                      const SizedBox(height: 12),

                      // Verified Citations
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VERIFIED MEDICAL CITATIONS & GUIDELINES:',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...citations.map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '• $c',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Action Buttons Footer ────────────────────────────────────
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.description_rounded, size: 16),
                    label: const Text('Download Ward Study Sheet (Markdown)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00E5FF),
                      side: const BorderSide(color: Color(0xFF00E5FF)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: () => _copyWardStudySheet(context),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Anki Flashcard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _copyAnkiFlashcard(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accent,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101724),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
