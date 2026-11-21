// ============================================================================
// DentoLab 3D: Dental, Endodontic & Maxillofacial Data Models
// ----------------------------------------------------------------------------
// High-yield anatomical, radiological, and clinical telemetric data models
// for BDS, DDS, and NBDE/INBDE dental curricula.
//
// Strictly Educational In-Silico Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';

enum DentalLayerMode {
  all('All-in-One', 'all', Icons.all_inclusive_rounded),
  enamel('Enamel & Crown', 'enamel', Icons.shield_outlined),
  pulp('Pulp & Canals', 'pulp', Icons.water_drop_outlined),
  periodontium('Periodontium & Bone', 'periodontium', Icons.layers_outlined),
  nerve('Trigeminal V2/V3', 'nerve', Icons.alt_route_rounded),
  vasculature('Vasculature', 'vasculature', Icons.bloodtype_outlined),
  pathology('Pathology Map', 'pathology', Icons.warning_amber_rounded);

  final String label;
  final String keyName;
  final IconData icon;
  const DentalLayerMode(this.label, this.keyName, this.icon);
}

enum DentalRadiographyMode {
  pa('Periapical (PA)', 'pa', 'High-resolution view of crowns, roots, and periapical tissues'),
  bitewing('Bitewing (BW)', 'bitewing', 'Coronal halves of maxillary/mandibular teeth; detects interproximal caries & bone crest'),
  panoramic('Panoramic (OPG)', 'panoramic', 'Full maxillofacial panoramic arc from condyle to condyle'),
  cbct('3D CBCT Cross-Section', 'cbct', 'Sub-millimeter volumetric slice for implant planning & canal anatomy');

  final String label;
  final String keyName;
  final String description;
  const DentalRadiographyMode(this.label, this.keyName, this.description);
}

enum EndoRctStep {
  none('Standard Anatomy', 'none'),
  access('1. Access Cavity', 'access'),
  file('2. NiTi Rotary Shaping', 'file'),
  irrigate('3. NaOCl Irrigation', 'irrigate'),
  obturate('4. Gutta-Percha Obturation', 'obturate');

  final String label;
  final String keyName;
  const EndoRctStep(this.label, this.keyName);
}

enum ImplantStep {
  none('Standard Ridge', 'none'),
  osteotomy('1. Osteotomy Preparation', 'osteotomy'),
  fixture('2. Titanium Fixture Seated', 'fixture'),
  abutment('3. Abutment Torqued', 'abutment'),
  crown('4. Zirconia Crown Cemented', 'crown');

  final String label;
  final String keyName;
  const ImplantStep(this.label, this.keyName);
}

class DentalToothDefinition {
  final int universalNumber; // 1 to 32
  final String fdiNotation; // e.g. 11, 21, 36, 46
  final String name;
  final String arch; // maxillary, mandibular
  final String type; // incisor, canine, premolar, molar
  final int roots;
  final int typicalCanals;

  const DentalToothDefinition({
    required this.universalNumber,
    required this.fdiNotation,
    required this.name,
    required this.arch,
    required this.type,
    required this.roots,
    required this.typicalCanals,
  });

  static const List<DentalToothDefinition> kAll32Teeth = [
    // Maxillary Right
    DentalToothDefinition(universalNumber: 1, fdiNotation: '18', name: 'Maxillary Right 3rd Molar (Wisdom)', arch: 'Maxillary', type: 'Molar', roots: 3, typicalCanals: 3),
    DentalToothDefinition(universalNumber: 2, fdiNotation: '17', name: 'Maxillary Right 2nd Molar', arch: 'Maxillary', type: 'Molar', roots: 3, typicalCanals: 3),
    DentalToothDefinition(universalNumber: 3, fdiNotation: '16', name: 'Maxillary Right 1st Molar (6-yr)', arch: 'Maxillary', type: 'Molar', roots: 3, typicalCanals: 4),
    DentalToothDefinition(universalNumber: 4, fdiNotation: '15', name: 'Maxillary Right 2nd Premolar', arch: 'Maxillary', type: 'Premolar', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 5, fdiNotation: '14', name: 'Maxillary Right 1st Premolar', arch: 'Maxillary', type: 'Premolar', roots: 2, typicalCanals: 2),
    DentalToothDefinition(universalNumber: 6, fdiNotation: '13', name: 'Maxillary Right Canine (Cuspid)', arch: 'Maxillary', type: 'Canine', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 7, fdiNotation: '12', name: 'Maxillary Right Lateral Incisor', arch: 'Maxillary', type: 'Incisor', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 8, fdiNotation: '11', name: 'Maxillary Right Central Incisor', arch: 'Maxillary', type: 'Incisor', roots: 1, typicalCanals: 1),
    // Maxillary Left
    DentalToothDefinition(universalNumber: 9, fdiNotation: '21', name: 'Maxillary Left Central Incisor', arch: 'Maxillary', type: 'Incisor', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 10, fdiNotation: '22', name: 'Maxillary Left Lateral Incisor', arch: 'Maxillary', type: 'Incisor', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 11, fdiNotation: '23', name: 'Maxillary Left Canine (Cuspid)', arch: 'Maxillary', type: 'Canine', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 12, fdiNotation: '24', name: 'Maxillary Left 1st Premolar', arch: 'Maxillary', type: 'Premolar', roots: 2, typicalCanals: 2),
    DentalToothDefinition(universalNumber: 13, fdiNotation: '25', name: 'Maxillary Left 2nd Premolar', arch: 'Maxillary', type: 'Premolar', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 14, fdiNotation: '26', name: 'Maxillary Left 1st Molar (6-yr)', arch: 'Maxillary', type: 'Molar', roots: 3, typicalCanals: 4),
    DentalToothDefinition(universalNumber: 15, fdiNotation: '27', name: 'Maxillary Left 2nd Molar', arch: 'Maxillary', type: 'Molar', roots: 3, typicalCanals: 3),
    DentalToothDefinition(universalNumber: 16, fdiNotation: '28', name: 'Maxillary Left 3rd Molar (Wisdom)', arch: 'Maxillary', type: 'Molar', roots: 3, typicalCanals: 3),
    // Mandibular Left
    DentalToothDefinition(universalNumber: 17, fdiNotation: '38', name: 'Mandibular Left 3rd Molar (Wisdom)', arch: 'Mandibular', type: 'Molar', roots: 2, typicalCanals: 2),
    DentalToothDefinition(universalNumber: 18, fdiNotation: '37', name: 'Mandibular Left 2nd Molar', arch: 'Mandibular', type: 'Molar', roots: 2, typicalCanals: 3),
    DentalToothDefinition(universalNumber: 19, fdiNotation: '36', name: 'Mandibular Left 1st Molar (6-yr)', arch: 'Mandibular', type: 'Molar', roots: 2, typicalCanals: 3),
    DentalToothDefinition(universalNumber: 20, fdiNotation: '35', name: 'Mandibular Left 2nd Premolar', arch: 'Mandibular', type: 'Premolar', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 21, fdiNotation: '34', name: 'Mandibular Left 1st Premolar', arch: 'Mandibular', type: 'Premolar', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 22, fdiNotation: '33', name: 'Mandibular Left Canine (Cuspid)', arch: 'Mandibular', type: 'Canine', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 23, fdiNotation: '32', name: 'Mandibular Left Lateral Incisor', arch: 'Mandibular', type: 'Incisor', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 24, fdiNotation: '31', name: 'Mandibular Left Central Incisor', arch: 'Mandibular', type: 'Incisor', roots: 1, typicalCanals: 1),
    // Mandibular Right
    DentalToothDefinition(universalNumber: 25, fdiNotation: '41', name: 'Mandibular Right Central Incisor', arch: 'Mandibular', type: 'Incisor', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 26, fdiNotation: '42', name: 'Mandibular Right Lateral Incisor', arch: 'Mandibular', type: 'Incisor', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 27, fdiNotation: '43', name: 'Mandibular Right Canine (Cuspid)', arch: 'Mandibular', type: 'Canine', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 28, fdiNotation: '44', name: 'Mandibular Right 1st Premolar', arch: 'Mandibular', type: 'Premolar', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 29, fdiNotation: '45', name: 'Mandibular Right 2nd Premolar', arch: 'Mandibular', type: 'Premolar', roots: 1, typicalCanals: 1),
    DentalToothDefinition(universalNumber: 30, fdiNotation: '46', name: 'Mandibular Right 1st Molar (6-yr)', arch: 'Mandibular', type: 'Molar', roots: 2, typicalCanals: 3),
    DentalToothDefinition(universalNumber: 31, fdiNotation: '47', name: 'Mandibular Right 2nd Molar', arch: 'Mandibular', type: 'Molar', roots: 2, typicalCanals: 3),
    DentalToothDefinition(universalNumber: 32, fdiNotation: '48', name: 'Mandibular Right 3rd Molar (Wisdom)', arch: 'Mandibular', type: 'Molar', roots: 2, typicalCanals: 2),
  ];
}

class DentalLandmarkDefinition {
  final String id;
  final String name;
  final String category;
  final String clinicalPearl;

  const DentalLandmarkDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.clinicalPearl,
  });
}

class ProjectedDentalLandmark {
  final String id;
  final String name;
  final String category;
  final double x;
  final double y;
  final double normX;
  final double normY;
  final double depth;
  final bool visible;
  final String clinicalPearl;

  const ProjectedDentalLandmark({
    required this.id,
    required this.name,
    required this.category,
    required this.x,
    required this.y,
    required this.normX,
    required this.normY,
    required this.depth,
    required this.visible,
    required this.clinicalPearl,
  });
}

class DentalClinicalCase {
  final String id;
  final String title;
  final String subtitle;
  final String chiefComplaint;
  final String radiographicFinding;
  final String recommendedTreatment;
  final int focusTooth;
  final double eptMicroAmps;
  final double pocketDepthMm;
  final double ldfFlowPercent;
  final double masseterEmgMicroVolts;

  const DentalClinicalCase({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.chiefComplaint,
    required this.radiographicFinding,
    required this.recommendedTreatment,
    required this.focusTooth,
    required this.eptMicroAmps,
    required this.pocketDepthMm,
    required this.ldfFlowPercent,
    required this.masseterEmgMicroVolts,
  });

  static const List<DentalClinicalCase> kPresets = [
    DentalClinicalCase(
      id: 'healthy',
      title: 'Healthy Dentition & Class I Molar Relationship',
      subtitle: 'Intact enamel, lamina dura continuous, physiological pulp vitality',
      chiefComplaint: 'Routine 6-month preventive exam and hygiene recall.',
      radiographicFinding: 'Crestal bone 1.5 mm apical to CEJ. Intact lamina dura, uniform PDL space, no furcation involvement.',
      recommendedTreatment: 'Prophylaxis, fluoride varnish application, 6-month follow-up.',
      focusTooth: 19,
      eptMicroAmps: 26.0,
      pocketDepthMm: 2.0,
      ldfFlowPercent: 88.0,
      masseterEmgMicroVolts: 22.0,
    ),
    DentalClinicalCase(
      id: 'pulpitis_19',
      title: 'Acute Irreversible Pulpitis with Symptomatic Apical Periodontitis (#19)',
      subtitle: 'Spontaneous throbbing pain lingering >30s after cold stimulus; percussion tenderness',
      chiefComplaint: 'Severe throbbing left lower jaw pain waking patient from sleep, radiating to left ear.',
      radiographicFinding: 'Deep disto-occlusal radiolucency approximating mesiobuccal pulp horn. PDL space widening at mesial root apex.',
      recommendedTreatment: 'Root canal therapy (RCT) on #19: access, rotary NiTi shaping, 5.25% NaOCl irrigation, gutta-percha obturation + crown.',
      focusTooth: 19,
      eptMicroAmps: 12.0, // Hypersensitive early, progressing to non-vital >80
      pocketDepthMm: 3.0,
      ldfFlowPercent: 98.0, // Hyperemic inflammatory pulp flow
      masseterEmgMicroVolts: 65.0,
    ),
    DentalClinicalCase(
      id: 'impacted_32',
      title: 'Horizontally Impacted Mandibular 3rd Molar (#32)',
      subtitle: 'Winter classification horizontal impaction abutting #31 distal root',
      chiefComplaint: 'Recurrent swelling, halitosis, and trismus (limited mouth opening) at right retromolar pad.',
      radiographicFinding: 'Tooth #32 crown impacted against cervical third of #31 root. Roots closely approximating superior cortical border of mandibular canal.',
      recommendedTreatment: 'Surgical odontectomy with crown sectioning under local anesthesia (IAN block); CBCT evaluation for nerve clearance.',
      focusTooth: 32,
      eptMicroAmps: 30.0,
      pocketDepthMm: 6.5, // Pericoronal pseudopocket
      ldfFlowPercent: 82.0,
      masseterEmgMicroVolts: 110.0, // Trismus & spasm
    ),
    DentalClinicalCase(
      id: 'periodontitis',
      title: 'Stage III Grade C Generalized Periodontitis',
      subtitle: 'Generalized severe horizontal & angular bone loss with Grade II furcation',
      chiefComplaint: 'Bleeding gums when brushing, loose back teeth, and persistent bad breath.',
      radiographicFinding: '40–50% horizontal bone loss, angular bony defect on #19 and #30, loss of lamina dura.',
      recommendedTreatment: 'Quadrant scaling & root planing (SRP), systemic Amoxicillin + Metronidazole adjunctive therapy, periodontal surgery.',
      focusTooth: 19,
      eptMicroAmps: 34.0,
      pocketDepthMm: 7.5,
      ldfFlowPercent: 62.0,
      masseterEmgMicroVolts: 35.0,
    ),
    DentalClinicalCase(
      id: 'implant_sinus',
      title: 'Posterior Maxillary Edentulous Ridge (#3) with Sinus Lift',
      subtitle: 'Post-extraction alveolar resorption leaving 3.5 mm residual vertical bone height',
      chiefComplaint: 'Unable to chew food effectively on upper right side since extraction 2 years ago.',
      radiographicFinding: 'Maxillary sinus pneumatization. Vertical bone height from alveolar crest to sinus floor: 3.5 mm (D3 bone density).',
      recommendedTreatment: 'Lateral window sinus lift with xenograft particulate bone + placement of 4.3 x 10 mm titanium fixture (35 Ncm torque).',
      focusTooth: 3,
      eptMicroAmps: 0.0,
      pocketDepthMm: 0.0,
      ldfFlowPercent: 0.0,
      masseterEmgMicroVolts: 20.0,
    ),
    DentalClinicalCase(
      id: 'tmj_displacement',
      title: 'Temporomandibular Joint Anterior Disc Displacement with Reduction',
      subtitle: 'Reciprocal opening & closing clicking with masseteric tenderness',
      chiefComplaint: 'Loud click in front of left ear when yawning, followed by jaw tightness and morning headache.',
      radiographicFinding: 'Condyle seated posteriorly in glenoid fossa at rest. Anteriorly displaced articular disc recapturing at 25 mm opening.',
      recommendedTreatment: 'Hard occlusal stabilization splint (nightguard), NSAIDs, physical therapy, avoidance of extreme opening.',
      focusTooth: 19,
      eptMicroAmps: 28.0,
      pocketDepthMm: 2.5,
      ldfFlowPercent: 80.0,
      masseterEmgMicroVolts: 145.0, // Severe masseteric clenching
    ),
  ];
}

class DentalTelemetryState {
  double heartRateBpm;
  double bloodPressureSys;
  double bloodPressureDia;
  double spo2Percent;
  double eptMicroAmps; // Electric Pulp Test (normal 15-40 µA, non-vital >80 µA)
  double pocketDepthMm; // Periodontal probing depth (1-3 normal, >5 deep)
  double ldfPulpFlowPercent; // Laser Doppler Flowmetry (0-100%)
  double masseterEmgMicroVolts; // Surface EMG (20-40 baseline, >100 clenching)
  int mobilityGrade; // 0, 1, 2, 3

  DentalTelemetryState({
    this.heartRateBpm = 75.0,
    this.bloodPressureSys = 120.0,
    this.bloodPressureDia = 80.0,
    this.spo2Percent = 99.0,
    this.eptMicroAmps = 24.0,
    this.pocketDepthMm = 2.0,
    this.ldfPulpFlowPercent = 85.0,
    this.masseterEmgMicroVolts = 25.0,
    this.mobilityGrade = 0,
  });

  void applyCase(DentalClinicalCase c) {
    eptMicroAmps = c.eptMicroAmps;
    pocketDepthMm = c.pocketDepthMm;
    ldfPulpFlowPercent = c.ldfFlowPercent;
    masseterEmgMicroVolts = c.masseterEmgMicroVolts;
    if (c.id == 'pulpitis_19') {
      heartRateBpm = 94.0;
      bloodPressureSys = 138.0;
      bloodPressureDia = 88.0;
    } else if (c.id == 'impacted_32') {
      heartRateBpm = 86.0;
      bloodPressureSys = 130.0;
      bloodPressureDia = 84.0;
    } else {
      heartRateBpm = 72.0;
      bloodPressureSys = 118.0;
      bloodPressureDia = 78.0;
    }
  }
}

class DentalPharmacologyDrug {
  final String name;
  final String classCategory;
  final String mechanismOfAction;
  final String dosageAndRoute;
  final String maxDose;
  final String dentalIndication;
  final String reactionWorkspaceSlug;

  const DentalPharmacologyDrug({
    required this.name,
    required this.classCategory,
    required this.mechanismOfAction,
    required this.dosageAndRoute,
    required this.maxDose,
    required this.dentalIndication,
    required this.reactionWorkspaceSlug,
  });

  static const List<DentalPharmacologyDrug> kDrugs = [
    DentalPharmacologyDrug(
      name: 'Lidocaine 2% with 1:100,000 Epinephrine',
      classCategory: 'Amide Local Anesthetic + Alpha-1 Vasoconstrictor',
      mechanismOfAction: 'Reversibly blocks voltage-gated Nav1.7 sodium channels in sensory nerve axons, preventing action potential generation and nociceptive conduction. Epinephrine stimulates local alpha-1 adrenergic receptors, inducing arteriolar vasoconstriction to prolong pulpal anesthesia (up to 60-90 min) and reduce surgical bleeding.',
      dosageAndRoute: '1.7 mL cartridge (34 mg lidocaine + 0.017 mg epinephrine) via Inferior Alveolar Nerve Block (IANB) or local infiltration.',
      maxDose: '7.0 mg/kg with epinephrine (maximum 500 mg / ~14.5 cartridges in a 70 kg healthy adult). Cardiac limit: 0.04 mg epinephrine (~2 cartridges).',
      dentalIndication: 'Gold-standard local anesthesia for cavity preparations, root canal therapy, and surgical extractions.',
      reactionWorkspaceSlug: 'aspirin-synthesis', // Linked to reaction viewer
    ),
    DentalPharmacologyDrug(
      name: 'Articaine 4% with 1:100,000 Epinephrine',
      classCategory: 'Thiophene-Ring Amide Local Anesthetic',
      mechanismOfAction: 'Possesses a thiophene ring increasing lipid solubility, allowing superior diffusion through dense cortical mandibular and maxillary bone. Hydrolyzed rapidly by plasma carboxylesterases (90-95%), yielding an ultra-short elimination half-life of ~20-27 minutes.',
      dosageAndRoute: '1.7 mL cartridge (68 mg articaine + 0.017 mg epinephrine) via maxillary/mandibular infiltration.',
      maxDose: '7.0 mg/kg (maximum 500 mg / ~7 cartridges in adult).',
      dentalIndication: 'Preferred infiltration agent in maxillary molars and mandibular incisors/premolars; high success in irreversible pulpitis.',
      reactionWorkspaceSlug: 'aspirin-synthesis',
    ),
    DentalPharmacologyDrug(
      name: 'Amoxicillin / Clavulanate (Augmentin)',
      classCategory: 'Aminopenicillin + Beta-Lactamase Inhibitor',
      mechanismOfAction: 'Amoxicillin binds penicillin-binding proteins (PBPs), inhibiting bacterial cell wall peptidoglycan transpeptidation. Potassium clavulanate irreversibly inhibits beta-lactamase enzymes produced by anaerobic odontogenic pathogens (Prevotella, Porphyromonas, Fusobacterium).',
      dosageAndRoute: '875/125 mg orally every 12 hours for 5 to 7 days.',
      maxDose: '2000 mg/day amoxicillin component.',
      dentalIndication: 'Spreading odontogenic fascial space infections, Ludwig’s angina prophylaxis, acute apical abscess with systemic involvement (fever, lymphadenopathy, trismus).',
      reactionWorkspaceSlug: 'aspirin-synthesis',
    ),
    DentalPharmacologyDrug(
      name: 'Clindamycin',
      classCategory: 'Lincosamide Antibiotic',
      mechanismOfAction: 'Reversibly binds the 50S ribosomal subunit of susceptible bacteria, inhibiting peptide bond formation and transpeptidation. Excellent bone penetration reaching 60–80% of serum levels in the mandible and maxilla.',
      dosageAndRoute: '300 mg orally every 6 hours for 5 to 7 days.',
      maxDose: '1800 mg/day orally.',
      dentalIndication: 'First-line alternative in patients with true IgE-mediated severe penicillin/beta-lactam allergy with bone involvement.',
      reactionWorkspaceSlug: 'aspirin-synthesis',
    ),
    DentalPharmacologyDrug(
      name: 'Ibuprofen 600 mg + Acetaminophen 500 mg',
      classCategory: 'Dual-Mechanism Analgesic Protocol',
      mechanismOfAction: 'Synergistic multimodal analgesia: Ibuprofen inhibits peripheral COX-1 and COX-2 enzymes, suppressing inflammatory prostaglandin E2 (PGE2) synthesis in the inflamed pulp/PDL. Acetaminophen acts centrally on serotonergic pain pathways and inhibits central prostaglandin peroxidase.',
      dosageAndRoute: 'Ibuprofen 600 mg + APAP 500 mg orally every 6 hours as needed.',
      maxDose: 'Ibuprofen 2400 mg/day; Acetaminophen 3000 mg/day.',
      dentalIndication: 'First-line evidence-based non-opioid multimodal management of post-operative endodontic and oral surgery pain.',
      reactionWorkspaceSlug: 'aspirin-synthesis',
    ),
    DentalPharmacologyDrug(
      name: 'Chlorhexidine Gluconate 0.12%',
      classCategory: 'Bisbiguanide Cationic Antimicrobial Rinse',
      mechanismOfAction: 'Positively charged chlorhexidine molecules bind negatively charged bacterial cell walls, disrupting osmotic equilibrium and precipitating cytoplasmic contents. Exhibits prolonged substantivity (adsorbs to hydroxyapatite and pellicle, releasing over 8-12 hours).',
      dosageAndRoute: '15 mL undiluted swished for 30 seconds twice daily 30 min after tooth brushing.',
      maxDose: 'Topical oral rinse (not for systemic ingestion).',
      dentalIndication: 'Pre-procedural bacterial aerosol reduction, periodontal pocket decontamination, post-surgical implant maintenance.',
      reactionWorkspaceSlug: 'aspirin-synthesis',
    ),
  ];
}
