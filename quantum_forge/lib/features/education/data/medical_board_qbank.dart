import 'dart:convert';
import 'package:quantum_forge/core/services/app_storage.dart';
import 'package:quantum_forge/features/cardiac/data/coronary_hemodynamics_engine.dart';

// ============================================================================
// MEDICAL BOARD QBANK & SM-2 SPACED REPETITION ENGINE
// ----------------------------------------------------------------------------
// Curated clinical vignette repository designed for MBBS, Pharm-D, USMLE
// (Step 1 & Step 2 CK), and NEET-PG candidates. Integrates two-step clinical
// reasoning, hemodynamic waveform correlation, pharmacology mechanisms, and
// the proven SuperMemo SM-2 spaced repetition memory algorithm.
//
// All progress and review schedules are persisted locally via AppStorage.
// ============================================================================

/// Clinical specialty category for board questions.
enum VignetteSpecialty {
  cardiology('Cardiology & Hemodynamics', '🫀'),
  pharmacology('Clinical Pharmacology & Toxicology', '💊'),
  emergencyMedicine('Resuscitation & ACLS', '⚡'),
  electrophysiology('Arrhythmias & Conduction', '📈'),
  valvularHeartDisease('Auscultation & Valvular Disease', '🩺');

  final String label;
  final String icon;
  const VignetteSpecialty(this.label, this.icon);
}

/// A two-step clinical vignette model with exam tags and 3D simulation links.
class ClinicalVignette {
  final String id;
  final VignetteSpecialty specialty;
  final String title;
  final List<String> examTags;
  final String vignette;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final List<String> boardKeywords;
  final String? linkedScenarioId;
  final OscilloscopeRhythmType? linkedRhythm;
  final String? linkedDrug;

  const ClinicalVignette({
    required this.id,
    required this.specialty,
    required this.title,
    required this.examTags,
    required this.vignette,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.boardKeywords,
    this.linkedScenarioId,
    this.linkedRhythm,
    this.linkedDrug,
  });
}

/// SM-2 Spaced Repetition card state for a single vignette.
class Sm2CardState {
  final String id;
  final int repetitions;
  final double intervalDays;
  final double easeFactor;
  final DateTime lastReviewed;
  final DateTime nextDueDate;

  const Sm2CardState({
    required this.id,
    required this.repetitions,
    required this.intervalDays,
    required this.easeFactor,
    required this.lastReviewed,
    required this.nextDueDate,
  });

  bool get isDue => DateTime.now().isAfter(nextDueDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'repetitions': repetitions,
        'intervalDays': intervalDays,
        'easeFactor': easeFactor,
        'lastReviewed': lastReviewed.toIso8601String(),
        'nextDueDate': nextDueDate.toIso8601String(),
      };

  factory Sm2CardState.fromJson(Map<String, dynamic> json) {
    return Sm2CardState(
      id: json['id'] as String,
      repetitions: json['repetitions'] as int? ?? 0,
      intervalDays: (json['intervalDays'] as num?)?.toDouble() ?? 0.0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      lastReviewed: DateTime.tryParse(json['lastReviewed'] as String? ?? '') ??
          DateTime.now(),
      nextDueDate: DateTime.tryParse(json['nextDueDate'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory Sm2CardState.initial(String id) {
    return Sm2CardState(
      id: id,
      repetitions: 0,
      intervalDays: 0,
      easeFactor: 2.5,
      lastReviewed: DateTime.now().subtract(const Duration(days: 1)),
      nextDueDate: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }
}

/// SM-2 Spaced Repetition rating (0 to 4).
enum Sm2Rating {
  again(0, 'Again', '0 days'),
  hard(2, 'Hard', '1 day'),
  good(3, 'Good', '3 days'),
  easy(4, 'Easy', '7 days');

  final int grade;
  final String label;
  final String previewInterval;
  const Sm2Rating(this.grade, this.label, this.previewInterval);
}

/// Singleton manager for the Medical Board QBank and SM-2 Spaced Repetition schedules.
class MedicalBoardQBank {
  static const String _storagePrefix = 'qbank_sm2_';

  // ───────────────────────────────────────────────────────────────────────────
  // 21 High-Yield Medical & Pharmacy Board Vignettes
  // ───────────────────────────────────────────────────────────────────────────
  static final List<ClinicalVignette> vignettes = [
    // 1. RV Infarction & Nitrate Contraindication
    const ClinicalVignette(
      id: 'usmle_cardio_01_rv_infarct',
      specialty: VignetteSpecialty.cardiology,
      title: 'Acute Inferior STEMI with Right Ventricular Involvement',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'MBBS Final Prof'],
      vignette:
          'A 62-year-old male arrives at the emergency department with severe substernal chest pressure, diaphoresis, and nausea. Vitals show BP 118/76 mmHg, HR 58 bpm. An 12-lead ECG demonstrates 3.5 mm ST elevation in leads II, III, and aVF with reciprocal depressions in I and aVL. A sublingual nitroglycerin tablet is administered. Two minutes later, the patient becomes lightheaded and lethargic; repeat BP drops precipitously to 72/42 mmHg with clear lung fields and distended jugular veins.',
      question:
          'Which of the following pathophysiological mechanisms explains this acute hemodynamic collapse?',
      options: [
        'Acute left ventricular papillary muscle rupture causing torrential MR',
        'Loss of right ventricular preload dependency due to venous pooling',
        'Bezold-Jarisch reflex triggering vagal bradycardia and AV nodal block',
        'Anterior wall free wall rupture resulting in acute cardiac tamponade',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: Up to 40% of inferior STEMIs (RCA occlusion) involve the Right Ventricle. The ischemic, stiff RV cannot pump adequately without elevated filling pressures (preload dependency). Nitroglycerin is a potent venodilator that reduces venous return; in RV infarction, this drops RV cardiac output, precipitating catastrophic systemic hypotension. Treatment is urgent IV 0.9% normal saline bolus (fluid loading) to restore RV preload, and immediate avoidance of nitrates and diuretics.',
      boardKeywords: [
        'RV Infarction',
        'Nitrate Contraindication',
        'Preload Dependency',
        'Right Sided Lead V4R',
        'IV Fluid Loading',
      ],
      linkedScenarioId: 'inferior_mi_rca',
      linkedRhythm: OscilloscopeRhythmType.sinusBrady,
      linkedDrug: 'Nitroglycerin',
    ),

    // 2. SVT & Adenosine
    const ClinicalVignette(
      id: 'usmle_cardio_02_svt_adenosine',
      specialty: VignetteSpecialty.electrophysiology,
      title: 'Paroxysmal Supraventricular Tachycardia (AVNRT)',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'MBBS Final Prof', 'Pharm-D'],
      vignette:
          'A 24-year-old medical student presents to urgent care complaining of sudden-onset rapid palpitations and lightheadedness following three cups of coffee. She has no prior cardiac history. Bedside monitor reveals a regular narrow-complex tachycardia at 182 bpm without discernible P waves. Vitals: BP 112/74 mmHg, SpO2 99%. Carotid sinus massage fails to terminate the rhythm.',
      question:
          'What is the next best pharmacotherapeutic step and its mechanism of action?',
      options: [
        'IV Amiodarone 150 mg; prolongs cardiac action potential duration via IKr block',
        'IV Adenosine 6 mg rapid push; stimulates A1 purinergic receptors in the AV node',
        'IV Digoxin 0.25 mg; inhibits Na+/K+ ATPase pump to increase vagal tone',
        'IV Lidocaine 1 mg/kg; blocks voltage-gated fast cardiac sodium channels',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: The rhythm is AVNRT (a regular narrow-complex SVT). Hemodynamically stable patients unresponsive to vagal maneuvers should receive IV Adenosine (6 mg rapid bolus followed by saline flush). Adenosine activates A1 adenosine receptors on the AV node, activating inward rectifier K+ current (IKAdo) and inhibiting L-type Ca2+ current, producing transient profound AV block (often an alarming 2-second asystolic pause) that breaks the re-entrant circuit and restores NSR.',
      boardKeywords: [
        'AVNRT',
        'Adenosine 6 mg Rapid Push',
        'A1 Purinergic Receptor',
        'AV Nodal Conduction Delay',
        'Transient Asystole',
      ],
      linkedScenarioId: 'svt_narrow',
      linkedRhythm: OscilloscopeRhythmType.svt,
      linkedDrug: 'Adenosine',
    ),

    // 3. Mobitz Type II & Pacing
    const ClinicalVignette(
      id: 'usmle_cardio_03_mobitz_2',
      specialty: VignetteSpecialty.electrophysiology,
      title: 'Second-Degree AV Block Mobitz Type II',
      examTags: ['USMLE Step 2 CK', 'MBBS Final Prof', 'NEET-PG'],
      vignette:
          'A 73-year-old male with known coronary artery disease presents with recurrent pre-syncope. Bedside telemetry demonstrates sinus rhythm at 75 bpm with regular P-P intervals. Intermittently, a non-conducted P wave fails to generate a QRS complex. The PR interval preceding the dropped beat is identical to the PR interval of all conducted beats, with a wide QRS complex (130 ms).',
      question:
          'Where is the anatomical level of block, and what is the definitive management?',
      options: [
        'Intranodal (AV node); oral observation or low-dose Atropine',
        'Infranodal (His-Purkinje system); permanent transvenous pacemaker implantation',
        'Sinoatrial node; catheter ablation of pulmonary vein triggers',
        'Left anterior fascicle only; initiation of high-dose beta blocker',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: Mobitz Type II AV block is characterized by constant PR intervals before dropped QRS complexes (no PR prolongation, unlike Mobitz I Wenckebach). It localizes below the AV node in the His-Purkinje system (often accompanied by bundle branch block). Because it unpredictably degenerates into complete 3° heart block or asystole and does NOT respond to Atropine (which may worsen block by speeding atrial rate), temporary transcutaneous pacing (TCP) and definitive permanent pacemaker (PPM) are indicated.',
      boardKeywords: [
        'Mobitz II',
        'Constant PR Interval',
        'Infranodal Block',
        'His-Purkinje System',
        'Pacemaker Indication',
      ],
      linkedScenarioId: 'anterior_stemi_lad',
      linkedRhythm: OscilloscopeRhythmType.avb2Mobitz2,
    ),

    // 4. Torsades de Pointes & Magnesium Sulfate
    const ClinicalVignette(
      id: 'usmle_cardio_04_torsades',
      specialty: VignetteSpecialty.pharmacology,
      title: 'Drug-Induced Long QT Syndrome and Polymorphic VT',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'Pharm-D', 'NEET-PG'],
      vignette:
          'A 48-year-old female taking erythromycin for atypical pneumonia and haloperidol for agitation is found unresponsive on the hospital floor. Bedside telemetry reveals a polymorphic ventricular tachycardia where the QRS axes continuously twist and rotate around the isoelectric line at 210 bpm. Her baseline ECG earlier that morning revealed a QTc of 560 ms and serum K+ was 3.1 mEq/L.',
      question:
          'What is the initial drug of choice for acute stabilization of this arrhythmia?',
      options: [
        'IV Amiodarone 300 mg bolus',
        'IV Magnesium Sulfate 2 g over 1–2 minutes',
        'IV Procainamide 100 mg slow infusion',
        'IV Ibutilide 1 mg over 10 minutes',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: The rhythm is Torsades de Pointes, triggered by drug-induced prolonged QTc (erythromycin + haloperidol both inhibit the hERG/IKr potassium channel). Class Ia (procainamide) and Class III (amiodarone, ibutilide) antiarrhythmics are strictly CONTRAINDICATED as they further prolong the QT interval and worsen the arrhythmia. The first-line treatment is IV Magnesium Sulfate (2 g bolus), which stabilizes cardiac membranes by suppressing early afterdepolarizations (EADs) and inward L-type calcium currents.',
      boardKeywords: [
        'Torsades de Pointes',
        'hERG Channel Blockade',
        'QTc > 500 ms',
        'IV Magnesium Sulfate',
        'Early Afterdepolarizations (EADs)',
      ],
      linkedScenarioId: 'bifurcation_medina_1_1_1',
      linkedRhythm: OscilloscopeRhythmType.torsades,
      linkedDrug: 'Amiodarone (hERG Challenge)',
    ),

    // 5. WPW & Pre-Excited Atrial Fibrillation
    const ClinicalVignette(
      id: 'usmle_cardio_05_wpw_afib',
      specialty: VignetteSpecialty.electrophysiology,
      title: 'Wolff-Parkinson-White with Atrial Fibrillation',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'MBBS Final Prof'],
      vignette:
          'A 28-year-old male presents with palpitations, dyspnea, and dizziness. Telemetry displays an irregularly irregular wide-complex tachycardia with beat-to-beat variability in QRS morphology and rates approaching 250 bpm. A baseline ECG from 2 years ago showed a short PR interval (< 120 ms) and slurred upstrokes on the R wave (delta wave).',
      question:
          'Which of the following medications is strictly contraindicated in this patient?',
      options: [
        'IV Procainamide',
        'IV Ibutilide',
        'IV Verapamil or Diltiazem',
        'Direct Current (DC) Cardioversion',
      ],
      correctIndex: 2,
      explanation:
          'High-Yield Board Concept: This is pre-excited atrial fibrillation in WPW syndrome conducting down the accessory pathway (Bundle of Kent). AV nodal blocking agents (Verapamil, Diltiazem, Beta-blockers, Digoxin, Adenosine - mnemonic "ABCD") are STRICTLY CONTRAINDICATED because blocking the AV node preferentially shunts all chaotic atrial impulses through the accessory pathway (which lacks decremental conduction), causing rapid 1:1 ventricular conduction that rapidly degenerates into Ventricular Fibrillation and sudden cardiac death. Hemodynamically unstable patients receive synchronized cardioversion; stable patients receive IV Procainamide or Ibutilide.',
      boardKeywords: [
        'Wolff-Parkinson-White',
        'Delta Wave',
        'Pre-excited AFib',
        'AV Nodal Blockers Contraindicated',
        'Bundle of Kent',
      ],
      linkedScenarioId: 'svt_narrow',
      linkedRhythm: OscilloscopeRhythmType.afib,
    ),

    // 6. Ventricular Fibrillation & Defibrillation
    const ClinicalVignette(
      id: 'usmle_cardio_06_vfib_arrest',
      specialty: VignetteSpecialty.emergencyMedicine,
      title: 'Sudden Cardiac Arrest with Ventricular Fibrillation',
      examTags: ['USMLE Step 2 CK', 'MBBS Final Prof', 'ACLS'],
      vignette:
          'A 55-year-old male collapses while undergoing coronary angiography. He is unresponsive, apneic, and has no carotid pulse. The oscilloscope strip immediately shifts from sinus rhythm into chaotic, disorganized, undulating baseline deflections without discernible P waves, QRS complexes, or T waves.',
      question:
          'According to ACLS guidelines, what is the immediate priority intervention?',
      options: [
        'Immediate synchronized cardioversion at 50 Joules',
        'Endotracheal intubation and mechanical ventilation',
        'Immediate unsynchronized defibrillation at 200 Joules biphasic',
        'Administration of IV Epinephrine 1 mg prior to CPR',
      ],
      correctIndex: 2,
      explanation:
          'High-Yield Board Concept: The rhythm is Ventricular Fibrillation (VF), a shockable pulseless cardiac arrest rhythm. Immediate unsynchronized high-energy defibrillation (120–200 J biphasic) followed immediately by 2 minutes of uninterrupted high-quality CPR is the definitive life-saving therapy. Synchronized cardioversion cannot be used because there are no R waves to track. Epinephrine 1 mg IV is given after the 2nd shock, and Amiodarone 300 mg IV after the 3rd shock.',
      boardKeywords: [
        'Ventricular Fibrillation',
        'Pulseless Cardiac Arrest',
        'Unsynchronized Defibrillation 200J',
        'High-Quality CPR',
        'ACLS Algorithm',
      ],
      linkedScenarioId: 'critical_lm_shock',
      linkedRhythm: OscilloscopeRhythmType.vfib,
    ),

    // 7. Complete Heart Block (3° AVB)
    const ClinicalVignette(
      id: 'usmle_cardio_07_complete_heart_block',
      specialty: VignetteSpecialty.electrophysiology,
      title: 'Third-Degree (Complete) AV Block with AV Dissociation',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'MBBS Final Prof'],
      vignette:
          'An 80-year-old female presents after an episode of syncope while gardening. On examination, HR is 36 bpm and regular, BP 155/60 mmHg. Intermittent prominent jugular venous pulsations (cannon A-waves) are noted. ECG demonstrates P waves marching regularly at 78 bpm and wide QRS complexes marching regularly at 36 bpm, with no temporal relationship between P waves and QRS complexes.',
      question:
          'What is the hemodynamic hallmark and primary cause of cannon A-waves in this condition?',
      options: [
        'Rapid early passive diastolic filling into a stiff, hypertrophied ventricle',
        'Right atrial contraction against a closed tricuspid valve during AV dissociation',
        'Severe tricuspid regurgitation systolic flow regurgitating into the superior vena cava',
        'Constrictive pericarditis with elevated systemic venous pressures (Kussmaul sign)',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: In 3° Complete Heart Block, the SA node fires independently of the ventricular escape focus (AV dissociation). Whenever the right atrium contracts while the tricuspid valve is closed due to simultaneous ventricular systole, blood cannot enter the right ventricle and shoots backward into the jugular vein, producing visible, intermittent "cannon A-waves". Definitive therapy is temporary transcutaneous or transvenous pacing, followed by permanent pacemaker implantation.',
      boardKeywords: [
        'Third-Degree AV Block',
        'AV Dissociation',
        'Cannon A-Waves',
        'Independent Atrial and Ventricular Rates',
        'Transcutaneous Pacing',
      ],
      linkedScenarioId: 'inferior_mi_rca',
      linkedRhythm: OscilloscopeRhythmType.avb3Complete,
    ),

    // 8. Aortic Stenosis Murmur & Maneuvers
    const ClinicalVignette(
      id: 'usmle_cardio_08_aortic_stenosis',
      specialty: VignetteSpecialty.valvularHeartDisease,
      title: 'Calcific Aortic Stenosis & Dynamic Bedside Auscultation',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'MBBS Final Prof', 'NEET-PG'],
      vignette:
          'A 75-year-old male presents with exertional angina, dyspnea, and an episode of near-syncope while walking up stairs. Physical exam reveals weak and delayed carotid pulses (pulsus parvus et tardus). Auscultation reveals a harsh, crescendo-decrescendo systolic ejection murmur loudest at the right second intercostal space radiating to the carotids, with paradoxical (reversed) splitting of S2.',
      question:
          'Which bedside maneuver will significantly DECREASE the intensity of this murmur?',
      options: [
        'Valsalva strain phase (forced expiration against a closed glottis)',
        'Rapid squatting from standing position',
        'Passive leg raise maneuver',
        'Sustained isometric handgrip exercise',
      ],
      correctIndex: 0,
      explanation:
          'High-Yield Board Concept: The murmur of Aortic Stenosis depends on the volume of blood ejected across the stenotic aortic valve. Maneuvers that decrease LV preload (such as the Valsalva strain phase or standing) reduce venous return, decreasing forward stroke volume across the aortic valve, thereby SOFTENING the murmur. In contrast, hypertrophic cardiomyopathy (HOCM) and mitral valve prolapse (MVP) murals BECOME LOUDER with Valsalva. Handgrip increases afterload and softens AS, but Valsalva is the classic board test of preload reduction.',
      boardKeywords: [
        'Aortic Stenosis',
        'Crescendo-Decrescendo',
        'Pulsus Parvus et Tardus',
        'Paradoxical S2 Splitting',
        'Valsalva Softens Murmur',
      ],
      linkedScenarioId: 'critical_lm_shock',
      linkedRhythm: OscilloscopeRhythmType.nsr,
    ),

    // 9. Hypertrophic Cardiomyopathy (HOCM)
    const ClinicalVignette(
      id: 'usmle_cardio_09_hocm',
      specialty: VignetteSpecialty.valvularHeartDisease,
      title: 'Hypertrophic Cardiomyopathy Dynamic Outflow Obstruction',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'MBBS Final Prof'],
      vignette:
          'A 19-year-old collegiate basketball player experiences syncope during intense practice. Family history is significant for an uncle who died suddenly at age 26. Cardiac examination reveals a brisk carotid pulse (pulsus bisferiens) and a harsh systolic ejection murmur at the left lower sternal border that does not radiate to the neck.',
      question:
          'How does the murmur intensity change with (1) Valsalva strain and (2) Sustained Handgrip?',
      options: [
        '(1) Increases; (2) Decreases',
        '(1) Decreases; (2) Increases',
        '(1) Decreases; (2) Decreases',
        '(1) Increases; (2) Increases',
      ],
      correctIndex: 0,
      explanation:
          'High-Yield Board Concept: HOCM involves asymmetric septal hypertrophy and systolic anterior motion (SAM) of the anterior mitral valve leaflet, creating dynamic LV outflow tract (LVOT) obstruction. Maneuvers that REDUCE LV end-diastolic volume (Valsalva strain, standing) bring the septum and mitral leaflet closer together, worsening obstruction and INCREASING murmur intensity. Conversely, maneuvers that INCREASE LV volume or afterload (squatting, handgrip) widen the outflow tract and DECREASE murmur intensity.',
      boardKeywords: [
        'HOCM',
        'Systolic Anterior Motion (SAM)',
        'Valsalva Increases Murmur',
        'Handgrip Decreases Murmur',
        'Beta-Blockers First-Line',
      ],
      linkedScenarioId: 'anterior_stemi_lad',
      linkedRhythm: OscilloscopeRhythmType.nsr,
    ),

    // 10. Mitral Regurgitation & S3 Gallop
    const ClinicalVignette(
      id: 'usmle_cardio_10_mitral_regurg',
      specialty: VignetteSpecialty.valvularHeartDisease,
      title: 'Chronic Severe Mitral Regurgitation & Heart Failure',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'MBBS Final Prof'],
      vignette:
          'A 58-year-old male with a history of anterior myocardial infarction presents with progressive orthopnea and paroxysmal nocturnal dyspnea. Auscultation at the cardiac apex reveals a high-pitched, blowing holosystolic murmur radiating to the left axilla, accompanied by a low-pitched mid-diastolic sound (S3 gallop).',
      question:
          'What physiological event directly produces the S3 gallop in this patient?',
      options: [
        'Atrial systole forcing blood into a non-compliant, stiff left ventricle',
        'Sudden deceleration of massive passive inflow entering a dilated left ventricle',
        'Vibration of the stenotic mitral leaflets during the opening snap',
        'Early closure of the pulmonary valve relative to aortic valve closure',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: An S3 gallop occurs during the early passive phase of diastole (rapid ventricular filling) right after S2. It is produced by the tensing of the chordae tendineae and ventricular walls when an abnormally large volume of blood rushes into a dilated, volume-overloaded ventricle (as in chronic MR, dilated cardiomyopathy, or high-output states). In contrast, S4 occurs in late diastole and reflects atrial kick against a stiff, hypertrophied ventricle (concentric hypertrophy/chronic hypertension).',
      boardKeywords: [
        'Mitral Regurgitation',
        'Holosystolic Murmur',
        'Axillary Radiation',
        'S3 Gallop',
        'Early Diastolic Inflow',
      ],
      linkedScenarioId: 'anterior_stemi_lad',
      linkedRhythm: OscilloscopeRhythmType.nsr,
    ),

    // 11. Acetaminophen Toxicity & NAPQI / NAC
    const ClinicalVignette(
      id: 'usmle_pharm_11_apap_toxicity',
      specialty: VignetteSpecialty.pharmacology,
      title: 'Acetaminophen Overdose & Toxic Metabolite Detoxification',
      examTags: ['USMLE Step 1', 'Pharm-D', 'MBBS Final Prof', 'NEET-PG'],
      vignette:
          'A 22-year-old female is brought to the ED 6 hours after ingesting 30 tablets of extra-strength acetaminophen (500 mg each). She complains of nausea and right upper quadrant abdominal discomfort. Serum acetaminophen concentration plots above the treatment line on the Rumack-Matthew nomogram.',
      question:
          'Which toxic reactive metabolite mediates this hepatotoxicity, and what is the therapeutic mechanism of N-Acetylcysteine (NAC)?',
      options: [
        'Formic acid; NAC inhibits alcohol dehydrogenase to prevent metabolic acidosis',
        'NAPQI; NAC replenishes hepatic glutathione by donating sulfhydryl groups',
        'Acetaldehyde; NAC blocks aldehyde dehydrogenase to accelerate clearance',
        'Paraquat radical; NAC scavenges singlet oxygen in pulmonary alveoli',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: At therapeutic doses, acetaminophen is glucuronidated and sulfated (>90%). In overdose, these saturation pathways are overwhelmed, and cytochrome P450 (principally CYP2E1) shunts drug into N-acetyl-p-benzoquinone imine (NAPQI), an electrophilic, cytotoxic metabolite. Once hepatic glutathione is depleted by >70%, NAPQI covalently binds hepatocytes, causing centrilobular necrosis. N-acetylcysteine (NAC) acts as a glutathione substitute and precursor (supplying cysteine sulfhydryl groups) to safely neutralize NAPQI.',
      boardKeywords: [
        'Acetaminophen Overdose',
        'NAPQI',
        'CYP2E1',
        'Glutathione Depletion',
        'N-Acetylcysteine (NAC)',
      ],
      linkedScenarioId: 'bifurcation_medina_1_1_1',
      linkedDrug: 'N-Acetylcysteine',
    ),

    // 12. Clopidogrel Resistance & CYP2C19 Loss of Function
    const ClinicalVignette(
      id: 'usmle_pharm_12_cyp2c19_clopidogrel',
      specialty: VignetteSpecialty.pharmacology,
      title: 'Pharmacogenomics of Clopidogrel & Stent Thrombosis',
      examTags: ['USMLE Step 1', 'Pharm-D', 'NEET-PG'],
      vignette:
          'A 54-year-old male undergoes successful drug-eluting stent placement to the LAD for STEMI. He is prescribed Aspirin 81 mg and Clopidogrel 75 mg daily. Four days later, he experiences acute crushing chest pain with recurrent ST elevation; emergency angiography reveals acute in-stent thrombosis. Pharmacogenomic testing reveals CYP2C19*2/*2 genotype.',
      question:
          'What is the mechanistic basis of clopidogrel failure in this patient?',
      options: [
        'Excessive hepatic first-pass glucuronidation leading to rapid renal clearance',
        'Impaired bioactivation of prodrug to its active antiplatelet thiol metabolite',
        'Overexpression of P2Y12 ADP receptors on platelet membranes',
        'Selective inhibition of platelet cyclooxygenase-1 preserving thromboxane A2',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: Clopidogrel is an inactive prodrug requiring a two-step hepatic bioactivation by CYP450 enzymes, predominantly CYP2C19, to generate its active thiol metabolite that irreversibly blocks the P2Y12 ADP receptor. Patients homozygous for non-functional alleles (CYP2C19*2 or *3) are "poor metabolizers" with subtherapeutic antiplatelet effect and significantly elevated risk of stent thrombosis. Alternative P2Y12 inhibitors like Ticagrelor (direct-acting, not a prodrug) or Prasugrel are indicated.',
      boardKeywords: [
        'Clopidogrel',
        'CYP2C19*2 Loss of Function',
        'Prodrug Bioactivation',
        'Stent Thrombosis',
        'Ticagrelor Alternative',
      ],
      linkedScenarioId: 'anterior_stemi_lad',
      linkedDrug: 'Clopidogrel / Ticagrelor',
    ),

    // 13. Codeine Toxicity & CYP2D6 Ultra-Rapid Metabolizer
    const ClinicalVignette(
      id: 'usmle_pharm_13_cyp2d6_codeine',
      specialty: VignetteSpecialty.pharmacology,
      title: 'Codeine Pharmacogenomics: CYP2D6 Ultra-Rapid Metabolizer',
      examTags: ['USMLE Step 1', 'Pharm-D', 'MBBS Final Prof'],
      vignette:
          'A 5-year-old child undergoes uncomplicated tonsillectomy and adenoidectomy for sleep apnea. He is discharged home with oral codeine and acetaminophen for pain control. The following morning, his mother finds him unresponsive and cyanotic in bed. Post-mortem genetic testing demonstrates CYP2D6 gene duplication (*1/*1xN).',
      question:
          'Which pharmacogenetic phenotype led to this fatal outcome?',
      options: [
        'Poor metabolizer status with toxic accumulation of parent codeine',
        'Ultra-rapid metabolizer with rapid supratherapeutic conversion to morphine',
        'Decreased mu-opioid receptor expression in the medulla oblongata',
        'Defective glucuronide conjugation of acetaminophen causing hepatic coma',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: Codeine is an inactive prodrug that requires O-demethylation by hepatic CYP2D6 to morphine for analgesic effect (normally ~10% conversion). Patients with CYP2D6 gene duplications are "Ultra-Rapid Metabolizers" (found in up to 29% of North Africans and Middle Eastern populations). In these patients, therapeutic doses of codeine produce rapid, massive spikes in circulating morphine, causing fatal central respiratory depression. Consequently, codeine is black-box contraindicated in pediatric post-tonsillectomy pain.',
      boardKeywords: [
        'Codeine Prodrug',
        'CYP2D6 Gene Duplication',
        'Ultra-Rapid Metabolizer',
        'Morphine Toxicity',
        'Pediatric Black Box Warning',
      ],
      linkedScenarioId: 'bifurcation_medina_1_1_1',
      linkedDrug: 'Codeine / Morphine',
    ),

    // 14. Digoxin Toxicity & Bidirectional VT
    const ClinicalVignette(
      id: 'usmle_pharm_14_digoxin_toxicity',
      specialty: VignetteSpecialty.pharmacology,
      title: 'Digoxin Toxicity, Hypokalemia, and Vision Changes',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'Pharm-D'],
      vignette:
          'A 76-year-old female with systolic heart failure and atrial fibrillation managed on digoxin, furosemide, and lisinopril presents with confusion, anorexia, nausea, and seeing yellow halos around streetlights (xanthopsia). ECG displays scooped ST-segment depression ("reverse checkmark") and runs of bidirectional ventricular tachycardia. Serum K+ is 2.8 mEq/L.',
      question:
          'Why does hypokalemia dramatically accentuate digoxin toxicity?',
      options: [
        'Low potassium stimulates aldosterone release which impairs digoxin renal excretion',
        'Potassium and digoxin compete for the same binding site on Na+/K+ ATPase',
        'Hypokalemia directly stimulates delayed rectifier potassium channels',
        'Low extracellular potassium increases hepatic glucuronidation of digitalis',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: Digoxin exerts its inotropic effect by reversibly inhibiting the extracellular alpha subunit of the myocardial Na+/K+ ATPase pump. K+ ions and digoxin compete for binding to this ATPase. When extracellular K+ is low (hypokalemia, often triggered by loop diuretics like furosemide), more digoxin binds the pump, dramatically magnifying toxicity even with "normal" serum digoxin levels. This leads to intracellular Na+ accumulation, driving the Na+/Ca2+ exchanger in reverse, causing toxic intracellular Ca2+ overload, delayed afterdepolarizations (DADs), and arrhythmias. Antidote: Digoxin Immune Fab (Digibind).',
      boardKeywords: [
        'Digoxin Toxicity',
        'Na+/K+ ATPase Inhibition',
        'Hypokalemia Risk Factor',
        'Bidirectional VT',
        'Digoxin Immune Fab (Digibind)',
      ],
      linkedScenarioId: 'bifurcation_medina_1_1_1',
      linkedRhythm: OscilloscopeRhythmType.vtach,
      linkedDrug: 'Digoxin',
    ),

    // 15. Norepinephrine in Septic & Cardiogenic Shock
    const ClinicalVignette(
      id: 'usmle_pharm_15_norepi_shock',
      specialty: VignetteSpecialty.emergencyMedicine,
      title: 'Vasoactive Support in Hemodynamic Collapse',
      examTags: ['USMLE Step 2 CK', 'MBBS Final Prof', 'Pharm-D'],
      vignette:
          'A 68-year-old male post-PCI for large anterior STEMI remains hypotensive with BP 76/48 mmHg (MAP 57 mmHg), cool clammy extremities, and urine output of 10 mL/hr despite 2 liters of crystalloid and intra-aortic balloon pump (IABP) activation. Cardiac output is 2.8 L/min with systemic vascular resistance (SVR) of 650 dyn·s/cm5.',
      question:
          'Which first-line vasopressor should be initiated, and what is its primary receptor profile?',
      options: [
        'Epinephrine; pure beta-2 agonist causing systemic vasodilation',
        'Norepinephrine; potent alpha-1 vasoconstriction with modest beta-1 inotropy',
        'Phenylephrine; pure beta-1 inotrope with no peripheral vascular activity',
        'Dopamine low-dose (renal dose); selective D1 receptor stimulation',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: Norepinephrine (Levophed) is the first-line vasopressor in both septic shock and vasodilatory/cardiogenic shock components to achieve a target MAP >= 65 mmHg. It acts as a potent alpha-1 adrenergic agonist, increasing peripheral systemic vascular resistance (SVR) and mean systemic filling pressure, with modest beta-1 receptor agonism that supports cardiac contractility without triggering excessive arrhythmogenic tachycardia (unlike high-dose epinephrine or dopamine).',
      boardKeywords: [
        'Norepinephrine (Levophed)',
        'Alpha-1 Adrenergic Agonist',
        'Target MAP >= 65 mmHg',
        'Cardiogenic Shock',
        'Vasoconstriction with Inotropy',
      ],
      linkedScenarioId: 'critical_lm_shock',
      linkedRhythm: OscilloscopeRhythmType.sinusTachy,
      linkedDrug: 'Norepinephrine',
    ),

    // 16. Atropine in Hemodynamically Unstable Sinus Bradycardia
    const ClinicalVignette(
      id: 'usmle_pharm_16_atropine_brady',
      specialty: VignetteSpecialty.emergencyMedicine,
      title: 'Symptomatic Sinus Bradycardia & Anticholinergic Rescue',
      examTags: ['USMLE Step 2 CK', 'MBBS Final Prof', 'ACLS'],
      vignette:
          'A 70-year-old male presents with sudden dizziness, cold sweats, and near-syncope. The bedside monitor demonstrates Sinus Bradycardia at 42 bpm with narrow QRS complexes. BP is 82/50 mmHg with poor capillary refill. Transcutaneous pacing pads are being placed.',
      question:
          'What is the initial ACLS drug dose and molecular mechanism to rapidly restore heart rate?',
      options: [
        'Atropine 1 mg IV push; competitive antagonist of muscarinic M2 receptors in the SA and AV nodes',
        'Atropine 0.1 mg IV push; partial agonist of nicotinic ACh receptors in autonomic ganglia',
        'Isoproterenol 1 mg IV push; selective antagonist of beta-1 adrenergic receptors',
        'Adenosine 12 mg IV push; stimulant of Gs-coupled myocardial adenylyl cyclase',
      ],
      correctIndex: 0,
      explanation:
          'High-Yield Board Concept: In hemodynamically unstable sinus bradycardia (hypotension, altered mental status, signs of shock), the first-line pharmacologic intervention under ACLS guidelines is Atropine 1 mg IV push (repeat every 3–5 min to max 3 mg). Atropine is a competitive reversible antagonist of muscarinic acetylcholine (M2) receptors, blocking parasympathetic vagal tone on the SA and AV nodes. This increases cAMP, accelerating phase 4 diastolic depolarization of pacemaker cells and speeding conduction velocity through the AV node.',
      boardKeywords: [
        'Sinus Bradycardia',
        'Atropine 1 mg IV Push',
        'Muscarinic M2 Receptor Antagonist',
        'Vagolytic Action',
        'ACLS Bradycardia Algorithm',
      ],
      linkedScenarioId: 'inferior_mi_rca',
      linkedRhythm: OscilloscopeRhythmType.sinusBrady,
      linkedDrug: 'Atropine',
    ),

    // 17. Amiodarone & Class III hERG Pharmacology
    const ClinicalVignette(
      id: 'usmle_pharm_17_amiodarone_herg',
      specialty: VignetteSpecialty.pharmacology,
      title: 'Class III Antiarrhythmic Electrophysiology & hERG Potassium Channels',
      examTags: ['USMLE Step 1', 'Pharm-D', 'NEET-PG'],
      vignette:
          'A medical researcher evaluates the cellular electrophysiology of Class III antiarrhythmics (such as amiodarone, sotalol, and dofetilide). Whole-cell patch-clamp recordings of human ventricular cardiomyocytes demonstrate marked prolongation of the plateau (Phase 2) and rapid repolarization (Phase 3) of the cardiac ventricular action potential.',
      question:
          'Which specific ion channel current is primarily inhibited to produce this action potential prolongation?',
      options: [
        'Inward fast sodium current (INa, Nav1.5)',
        'Rapid delayed rectifier potassium current (IKr, Kv11.1 / hERG)',
        'Transient outward potassium current (Ito, Kv4.3)',
        'Inward hyperpolarization-activated pacemaker current (If, HCN4)',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: The defining hallmark of Vaughan-Williams Class III antiarrhythmics is prolongation of the action potential duration (APD) and effective refractory period (ERP) by blocking potassium efflux during repolarization. Specifically, they inhibit the rapid component of the delayed rectifier potassium current (IKr) encoded by the hERG (KCNH2) gene. This increases the QT interval on surface ECG. While amiodarone has Class I, II, III, and IV properties, its primary Class III antiarrhythmic and QTc-prolonging effect stems from IKr blockade.',
      boardKeywords: [
        'Class III Antiarrhythmics',
        'hERG Potassium Channel',
        'IKr Blockade',
        'Action Potential Duration (Phase 3)',
        'QTc Prolongation',
      ],
      linkedScenarioId: 'bifurcation_medina_1_1_1',
      linkedRhythm: OscilloscopeRhythmType.nsr,
      linkedDrug: 'Amiodarone (hERG Challenge)',
    ),

    // 18. Aortic Regurgitation & Wide Pulse Pressure
    const ClinicalVignette(
      id: 'usmle_cardio_18_aortic_regurg',
      specialty: VignetteSpecialty.valvularHeartDisease,
      title: 'Chronic Aortic Regurgitation & Peripheral Vascular Signs',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'MBBS Final Prof'],
      vignette:
          'A 45-year-old male with a history of bicuspid aortic valve presents for routine evaluation. Physical exam reveals a BP of 165/45 mmHg (pulse pressure 120 mmHg). Head bobbing synchronous with each heartbeat (de Musset sign) and bounding pulses with rapid collapse (Corrigan water-hammer pulse) are noted. Auscultation reveals a high-pitched, blowing early diastolic decrescendo murmur best heard at the left 3rd intercostal space with the patient sitting forward in full expiration.',
      question:
          'What is the fundamental hemodynamic cause of the markedly widened pulse pressure?',
      options: [
        'Decreased systemic arterial compliance combined with elevated pulmonary vascular resistance',
        'Massive regurgitant diastolic run-off into the LV plus elevated forward stroke volume',
        'Dynamic left ventricular outflow tract obstruction during early systole',
        'Isolated severe coarctation of the aorta creating post-stenotic turbulence',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: In chronic Aortic Regurgitation, blood leaks back from the aorta into the left ventricle during diastole (regurgitant volume). This rapid diastolic runoff causes aortic diastolic pressure to drop precipitously (often < 50 mmHg). The LV compensates with eccentric hypertrophy to accommodate the increased volume, producing a supranormal forward stroke volume in systole, elevating systolic BP (e.g. 165 mmHg). The resulting hyperdynamic wide pulse pressure generates the classic peripheral signs (Corrigan pulse, de Musset sign, Quincke nailbed pulses, Duroziez sign).',
      boardKeywords: [
        'Aortic Regurgitation',
        'Diastolic Decrescendo Murmur',
        'Wide Pulse Pressure',
        'Corrigan Water-Hammer Pulse',
        'Eccentric LV Hypertrophy',
      ],
      linkedScenarioId: 'critical_lm_shock',
      linkedRhythm: OscilloscopeRhythmType.nsr,
    ),

    // 19. Mitral Stenosis & Opening Snap
    const ClinicalVignette(
      id: 'usmle_cardio_19_mitral_stenosis',
      specialty: VignetteSpecialty.valvularHeartDisease,
      title: 'Rheumatic Mitral Stenosis & Auscultation Chronometry',
      examTags: ['USMLE Step 1', 'USMLE Step 2 CK', 'MBBS Final Prof', 'NEET-PG'],
      vignette:
          'A 38-year-old female who immigrated from South Asia presents with dyspnea on exertion and hemoptysis. Auscultation at the cardiac apex in the left lateral decubitus position reveals a loud S1, an opening snap (OS) shortly after S2, followed by a low-pitched mid-diastolic rumbling murmur with presystolic accentuation.',
      question:
          'How does the time interval between the second heart sound (S2) and the opening snap (S2–OS interval) correlate with the severity of mitral stenosis?',
      options: [
        'A shorter S2–OS interval indicates more severe stenosis due to higher left atrial pressure',
        'A longer S2–OS interval indicates more severe stenosis due to delayed mitral leaflet opening',
        'The S2–OS interval remains constant and does not correlate with valve gradient',
        'A shorter S2–OS interval indicates mild stenosis due to preserved ventricular compliance',
      ],
      correctIndex: 0,
      explanation:
          'High-Yield Board Concept: The opening snap is produced by the abrupt halting of the doming, fibrotic stenotic mitral valve leaflets in early diastole. When mitral stenosis is severe, left atrial pressure (LAP) is markedly elevated. A higher LAP forces the stenotic mitral valve to open earlier in diastole when LV pressure drops below LAP, shortening the S2–OS interval. Therefore: shorter S2–OS interval = higher LA pressure = MORE SEVERE mitral stenosis.',
      boardKeywords: [
        'Mitral Stenosis',
        'Opening Snap (OS)',
        'S2–OS Interval',
        'Left Atrial Hypertension',
        'Rheumatic Heart Disease',
      ],
      linkedScenarioId: 'anterior_stemi_lad',
      linkedRhythm: OscilloscopeRhythmType.nsr,
    ),

    // 20. Atrial Fibrillation & CHA2DS2-VASc
    const ClinicalVignette(
      id: 'usmle_cardio_20_afib_thromboprophylaxis',
      specialty: VignetteSpecialty.electrophysiology,
      title: 'Atrial Fibrillation & Thromboembolic Risk Stratification',
      examTags: ['USMLE Step 2 CK', 'MBBS Final Prof', 'Pharm-D'],
      vignette:
          'A 71-year-old female with hypertension and type 2 diabetes presents for evaluation. Telemetry demonstrates an irregularly irregular rhythm at 110 bpm with absent P waves and fine baseline fibrillatory waves. Echocardiogram reveals normal LV ejection fraction (60%) and mild left atrial enlargement without valvular pathology.',
      question:
          'Calculate her CHA2DS2-VASc score and identify the guideline-directed stroke prevention therapy:',
      options: [
        'Score = 2; Aspirin 81 mg daily monotherapy',
        'Score = 4; Oral anticoagulation with a Direct Oral Anticoagulant (DOAC, e.g. Apixaban)',
        'Score = 1; Clopidogrel 75 mg daily monotherapy',
        'Score = 0; No antithrombotic therapy required',
      ],
      correctIndex: 1,
      explanation:
          'High-Yield Board Concept: CHA2DS2-VASc score calculation: Congestive heart failure (0), Hypertension (1), Age >= 75 (0), Diabetes mellitus (1), Stroke/TIA (0), Vascular disease (0), Age 65–74 (1), Sex category female (1). Total score = 1 + 1 + 1 + 1 = 4. In non-valvular AFib, guideline criteria indicate oral anticoagulation for males with score >= 2 and females with score >= 3. DOACs (Apixaban, Rivaroxaban, Dabigatran) are preferred over Warfarin due to lower risk of intracranial hemorrhage and no dietary/INR monitoring requirements.',
      boardKeywords: [
        'Atrial Fibrillation',
        'CHA2DS2-VASc Score',
        'DOAC Anticoagulation (Apixaban)',
        'Stroke Prophylaxis',
        'Absence of P Waves',
      ],
      linkedScenarioId: 'svt_narrow',
      linkedRhythm: OscilloscopeRhythmType.afib,
      linkedDrug: 'Apixaban',
    ),

    // 21. Local Anesthetic Systemic Toxicity (LAST) & 20% Lipid Emulsion
    const ClinicalVignette(
      id: 'usmle_pharm_21_last_lipid_rescue',
      specialty: VignetteSpecialty.pharmacology,
      title: 'Bupivacaine Cardiotoxicity & Intralipid Rescue',
      examTags: ['USMLE Step 1', 'Pharm-D', 'ACLS'],
      vignette:
          'A 34-year-old female undergoes an ultrasound-guided femoral nerve block with 0.5% bupivacaine for knee arthroscopy. Five minutes after injection, she develops perioral numbness, metallic taste, slurred speech, and seizures, followed rapidly by cardiovascular collapse with wide-complex ventricular arrhythmias and severe hypotension.',
      question:
          'What is the specific intravenous antidote that acts as a "lipid sink" to reverse this toxicity?',
      options: [
        '20% Intravenous Lipid Emulsion (Intralipid)',
        'Intravenous Methylene Blue 1–2 mg/kg',
        'Intravenous Sodium Bicarbonate 1 mEq/kg',
        'Intravenous Calcium Gluconate 10%',
      ],
      correctIndex: 0,
      explanation:
          'High-Yield Board Concept: This is Local Anesthetic Systemic Toxicity (LAST), most notorious with highly lipophilic, potent amide local anesthetics like Bupivacaine, which binds fast cardiac Nav1.5 sodium channels with slow dissociation ("fast in, slow out"). The specific antidote is 20% Intravenous Lipid Emulsion (Intralipid). It works primarily via the "lipid sink" mechanism—extracting lipophilic bupivacaine from cardiac tissue into an intravascular lipid emulsion phase—along with direct myocardial metabolic and inotropic benefits.',
      boardKeywords: [
        'LAST (Local Anesthetic Systemic Toxicity)',
        'Bupivacaine Cardiotoxicity',
        '20% Lipid Emulsion (Intralipid)',
        'Lipid Sink Mechanism',
        'Sodium Channel Blockade',
      ],
      linkedScenarioId: 'bifurcation_medina_1_1_1',
      linkedRhythm: OscilloscopeRhythmType.vtach,
      linkedDrug: '20% Lipid Emulsion',
    ),
  ];

  // ───────────────────────────────────────────────────────────────────────────
  // SM-2 Persistence & Spaced Repetition Logic
  // ───────────────────────────────────────────────────────────────────────────

  /// Loads the SM-2 state for a specific vignette from AppStorage.
  static Sm2CardState getCardState(String vignetteId) {
    final raw = AppStorage.getString('$_storagePrefix$vignetteId');
    if (raw == null || raw.isEmpty) {
      return Sm2CardState.initial(vignetteId);
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return Sm2CardState.fromJson(map);
    } catch (_) {
      return Sm2CardState.initial(vignetteId);
    }
  }

  /// Reviews a card using the classic SuperMemo SM-2 algorithm:
  /// - rating: 0 (Again), 2 (Hard), 3 (Good), 4 (Easy)
  /// - recalculates easeFactor, repetitions, intervalDays, and nextDueDate
  /// - persists immediately to AppStorage
  static Sm2CardState reviewCard(String vignetteId, Sm2Rating rating) {
    final current = getCardState(vignetteId);
    final grade = rating.grade;

    int newReps;
    double newInterval;
    double newEf = current.easeFactor +
        (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02));
    if (newEf < 1.3) newEf = 1.3;

    if (grade < 3) {
      // Failed or hard review: reset repetitions, interval = 1 day
      newReps = 0;
      newInterval = grade == 0 ? 0.2 : 1.0; // 0.2 days (~5 hrs) for complete fail
    } else {
      // Successful recall
      if (current.repetitions == 0) {
        newInterval = 1.0;
      } else if (current.repetitions == 1) {
        newInterval = 6.0;
      } else {
        newInterval = current.intervalDays * newEf;
      }
      newReps = current.repetitions + 1;
    }

    final now = DateTime.now();
    final nextDue = now.add(Duration(
      minutes: (newInterval * 24 * 60).round(),
    ));

    final updated = Sm2CardState(
      id: vignetteId,
      repetitions: newReps,
      intervalDays: newInterval,
      easeFactor: newEf,
      lastReviewed: now,
      nextDueDate: nextDue,
    );

    AppStorage.setString('$_storagePrefix$vignetteId', jsonEncode(updated.toJson()));
    return updated;
  }

  /// Returns count of vignettes currently due for review.
  static int getDueCount() {
    int due = 0;
    for (final v in vignettes) {
      if (getCardState(v.id).isDue) {
        due++;
      }
    }
    return due;
  }

  /// Returns list of vignettes currently due for review.
  static List<ClinicalVignette> getDueVignettes() {
    return vignettes.where((v) => getCardState(v.id).isDue).toList();
  }

  /// Resets all SM-2 spaced repetition progress back to initial states.
  static void resetAllProgress() {
    for (final v in vignettes) {
      AppStorage.remove('$_storagePrefix${v.id}');
    }
  }
}
