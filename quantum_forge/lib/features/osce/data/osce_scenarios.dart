// ============================================================================
// OSCE Clinical Vignette Scenarios — MBBS, Pharm-D & DVM Compendium
// ----------------------------------------------------------------------------
// Curated clinical emergencies for the timed 3D molecular rescue sandbox.
// Strictly factual clinical parameters, uncopyrightable biochemistry, and DOIs.
// ============================================================================

import 'package:flutter/foundation.dart';

@immutable
class OsceScenario {
  final String id;
  final String title;
  final String discipline; // MBBS, Pharm-D, DVM
  final String patientBrief;
  final String clinicalVitals;
  final String biochemicalCrisis;
  final String targetReceptorName;
  final String correctRescueAgentId;
  final String correctRescueAgentName;
  final List<String> alternativeDistractors;
  final double timeLimitSeconds;
  final String mechanismOfRescue;
  final String contraindicationWarning;
  final String primaryDoi;
  final List<String> highYieldExamPearls;

  const OsceScenario({
    required this.id,
    required this.title,
    required this.discipline,
    required this.patientBrief,
    required this.clinicalVitals,
    required this.biochemicalCrisis,
    required this.targetReceptorName,
    required this.correctRescueAgentId,
    required this.correctRescueAgentName,
    required this.alternativeDistractors,
    this.timeLimitSeconds = 120.0,
    required this.mechanismOfRescue,
    required this.contraindicationWarning,
    required this.primaryDoi,
    required this.highYieldExamPearls,
  });
}

const List<OsceScenario> kOscePresetScenarios = [
  OsceScenario(
    id: 'osce_apap_hepatic_necrosis',
    title: 'Acute Acetaminophen (APAP) Hepatotoxicity',
    discipline: 'MBBS & Pharm-D',
    patientBrief:
        '24-year-old female presents to Emergency 9 hours following an intentional ingestion of 24 tablets (12g) of paracetamol. Patient reports nausea, right upper quadrant pain, and malaise.',
    clinicalVitals: 'HR: 104 bpm | BP: 110/70 mmHg | ALT: 2,450 U/L | Bilirubin: 2.8 mg/dL',
    biochemicalCrisis:
        'Hepatic glutathione (GSH) reserves are exhausted. CYP2E1 oxidation shunts paracetamol into toxic N-acetyl-p-benzoquinone imine (NAPQI), which covalently binds mitochondrial proteins causing centrilobular hepatic necrosis.',
    targetReceptorName: 'CYP2E1 / Hepatocyte Mitochondrial Complex',
    correctRescueAgentId: 'nac',
    correctRescueAgentName: 'N-Acetylcysteine (NAC)',
    alternativeDistractors: ['Naloxone', 'Flumazenil', 'Sodium Bicarbonate', 'Deferoxamine'],
    timeLimitSeconds: 120.0,
    mechanismOfRescue:
        'NAC provides L-cysteine for intracellular glutathione synthesis and directly donates sulfhydryl (-SH) groups to conjugate and neutralize electrophilic NAPQI into non-toxic mercapturic acid conjugates.',
    contraindicationWarning:
        'Deferring NAC administration beyond 8 hours post-ingestion exponentially increases the risk of fulminant hepatic failure requiring emergency liver transplantation.',
    primaryDoi: '10.1056/NEJMra052711',
    highYieldExamPearls: [
      'Rumack-Matthew nomogram plots APAP concentration from 4 to 24 hours post-ingestion.',
      'IV NAC protocol: 150 mg/kg loading over 60 min, 50 mg/kg over 4 hours, then 100 mg/kg over 16 hours.',
      'Anaphylactoid reactions can occur with rapid IV infusion; manage with antihistamines without stopping therapy.',
    ],
  ),
  OsceScenario(
    id: 'osce_organophosphate_crisis',
    title: 'Organophosphate Cholinergic Crisis',
    discipline: 'MBBS & Critical Care',
    patientBrief:
        '48-year-old farm worker presents in acute respiratory distress following insecticide crop spraying. Exam shows pinpoint pupils (miosis), excessive salivation, lacrimation, wheezing, and muscle fasciculations.',
    clinicalVitals: 'HR: 42 bpm (Severe Bradycardia) | BP: 85/50 mmHg | SpO2: 84% on room air',
    biochemicalCrisis:
        'Irreversible covalent organophosphate phosphorylation of Serine-203 in the acetylcholinesterase catalytic triad blocks acetylcholine hydrolysis, precipitating continuous muscarinic and nicotinic hyperstimulation.',
    targetReceptorName: 'Acetylcholinesterase (AChE) Ser-203 Triad',
    correctRescueAgentId: 'atropine_pralidoxime',
    correctRescueAgentName: 'Atropine + Pralidoxime (2-PAM)',
    alternativeDistractors: ['Propranolol', 'Physostigmine', 'Succinylcholine', 'Dantrolene'],
    timeLimitSeconds: 120.0,
    mechanismOfRescue:
        'Pralidoxime (2-PAM) acts as a nucleophilic oxime regenerator that cleaves the phosphate-ester bond before enzymatic "aging" occurs. Atropine competitively blocks muscarinic acetylcholine receptors to reverse life-threatening bronchorrhea.',
    contraindicationWarning:
        'Administering Succinylcholine for rapid sequence intubation is lethal because succinylcholine relies on plasma cholinesterase for breakdown, leading to prolonged apnea.',
    primaryDoi: '10.1016/S0140-6736(07)61869-0',
    highYieldExamPearls: [
      'Remember SLUDGE-M mnemonic: Salivation, Lacrimation, Urination, Defecation, GI cramping, Emesis, Miosis.',
      'Atropine dries bronchial secretions (endpoints: clear chest auscultation, HR > 80 bpm); it does NOT reverse muscle paralysis.',
      '2-PAM reverses nicotinic neuromuscular paralysis at the motor endplate.',
    ],
  ),
  OsceScenario(
    id: 'osce_feline_methemoglobinemia',
    title: 'Feline Paracetamol Toxicity & Methemoglobinemia',
    discipline: 'DVM (Veterinary Medicine)',
    patientBrief:
        '3-year-old domestic shorthair cat presented by owner who administered 1/2 tablet (250 mg) of adult acetaminophen for a perceived fever. Cat is severely lethargic with facial and paw edema, hypothermia, and tachypnea.',
    clinicalVitals: 'Temp: 36.1 °C (97.0 °F) | HR: 180 bpm | RR: 65/min | Blood: Chocolate Brown',
    biochemicalCrisis:
        'Felines have genetic pseudogene mutations in UGT1A6 resulting in deficient glucuronidation. APAP is shunted into reactive metabolites that oxidize hemoglobin iron from Fe2+ to Fe3+, forming methemoglobin and Heinz bodies.',
    targetReceptorName: 'Feline Hemoglobin Ferrous (Fe2+) Heme Porphyrin',
    correctRescueAgentId: 'cysteamine_nac',
    correctRescueAgentName: 'IV N-Acetylcysteine + Cysteamine',
    alternativeDistractors: ['Methylene Blue', 'Aspirin', 'Dexamethasone', 'Ketoprofen'],
    timeLimitSeconds: 120.0,
    mechanismOfRescue:
        'NAC provides sulfhydryl donors to scavenge oxidative radicals and support glutathione synthesis. Ascorbic acid and cimetidine (CYP inhibitor) serve as adjuncts.',
    contraindicationWarning:
        'Methylene blue is CONTRAINDICATED in cats because feline hemoglobin is unusually susceptible to oxidative injury, causing fatal Heinz body hemolytic anemia.',
    primaryDoi: '10.1111/j.1939-1676.2010.0505.x',
    highYieldExamPearls: [
      'Even 10-20 mg/kg of paracetamol in cats is toxic; 250 mg is commonly fatal without immediate decontamination.',
      'Chocolate brown blood that does not turn red upon exposure to 100% oxygen is diagnostic for methemoglobinemia.',
      'Feline hemoglobin has 8 reactive sulfhydryl groups (compared to 2 in dogs/humans), predisposing to Heinz bodies.',
    ],
  ),
  OsceScenario(
    id: 'osce_malignant_hyperthermia',
    title: 'Anesthetic Malignant Hyperthermia Crisis',
    discipline: 'MBBS & Anesthesia',
    patientBrief:
        '32-year-old male undergoing emergency appendectomy under Sevoflurane and Succinylcholine develops sudden masseter muscle jaw rigidity, tachycardia, and a dramatic rise in end-tidal CO2.',
    clinicalVitals: 'Temp: 40.8 °C (Rising) | EtCO2: 82 mmHg | HR: 148 bpm | pH: 7.12 (Severe Acidosis)',
    biochemicalCrisis:
        'Autosomal dominant mutation in the Ryanodine Receptor Type 1 (RYR1) calcium channel in skeletal muscle sarcoplasmic reticulum. Volatile anesthetics trigger uncontrolled Ca2+ release, fueling runaway hypermetabolism.',
    targetReceptorName: 'Sarcoplasmic Reticulum Ryanodine Receptor (RYR1)',
    correctRescueAgentId: 'dantrolene',
    correctRescueAgentName: 'Dantrolene Sodium',
    alternativeDistractors: ['Verapamil', 'Atropine', 'Acetaminophen IV', 'Morphine'],
    timeLimitSeconds: 120.0,
    mechanismOfRescue:
        'Dantrolene directly binds to the RYR1 channel and inhibits calcium release from the sarcoplasmic reticulum into the myoplasm, halting actin-myosin contraction and lactic acid storm.',
    contraindicationWarning:
        'Calcium channel blockers (e.g. Verapamil, Diltiazem) are strictly contraindicated with Dantrolene because the combination precipitates fatal hyperkalemic cardiovascular collapse.',
    primaryDoi: '10.1097/ALN.0000000000002888',
    highYieldExamPearls: [
      'Stop triggering agents immediately and hyperventilate with 100% O2 at high flows (>10 L/min).',
      'Initial Dantrolene dose: 2.5 mg/kg IV push, repeated up to 10 mg/kg until symptoms subside.',
      'Ryanodex formulation contains 250 mg/vial and reconstitutes in 5 mL sterile water (vs old Dantrium 20 mg in 60 mL).',
    ],
  ),
];

