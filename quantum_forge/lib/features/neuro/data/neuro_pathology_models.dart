// ============================================================================
// NeuroLab 3D: Brain, Neurovascular & Spinal Cord — Pathology Models
// ----------------------------------------------------------------------------
// Clinical models, anatomical layers, spinal cord cross-sectional syndromes,
// and neurovascular scenarios.
// Strictly adheres to SaMD 7-Pillar Educational Simulation Standards.
// ============================================================================

import 'package:flutter/material.dart';

enum NeuroAnatomicalLayer {
  all('all', 'All Structures', 'Translucent brain, Circle of Willis, ventricles, full spinal cord and nerves.'),
  cortical('cortical', 'Cortical & Deep Nuclei', 'Frontal, parietal, temporal, occipital lobes, central sulcus, Sylvian fissure & basal ganglia.'),
  vessels('vessels', 'Circle of Willis & Sinuses', 'ICA, MCA (M1/M2), ACA (A1/A2), ACom, Basilar, Vertebral and Superior Sagittal Sinus.'),
  ventricles('ventricles', 'CSF & Ventricles', 'Lateral ventricles (anterior/body/atrium/posterior/temporal horns), 3rd/4th ventricles and CSF particles.'),
  spine('spine', 'Full Spinal Cord (C1–L5)', 'Cervical & lumbar enlargements, conus medullaris, cauda equina and color-coded internal tracts.'),
  nerves('nerves', 'Cranial Nerves (I–XII)', 'Optic chiasm (CN II), Trigeminal (CN V), and major cranial nerve root exits.'),
  penumbra('penumbra', 'Ischemic Penumbra Map', 'Irreversible ischemic infarct core (crimson) vs. salvageable hypoxic penumbra (amber).');

  final String id;
  final String label;
  final String description;

  const NeuroAnatomicalLayer(this.id, this.label, this.description);
}

enum DsaProjection {
  ap('ap', 'AP Frontal', 'Anterior-Posterior projection separating left/right hemispheres and ACA/MCA bifurcations.'),
  lateral('lateral', 'Straight Lateral (90°)', 'True 90° lateral projection isolating the carotid siphon, pericallosal ACA, and Sylvian MCA course.');

  final String id;
  final String label;
  final String description;

  const DsaProjection(this.id, this.label, this.description);
}

enum SpinalSyndrome {
  normal(
    id: 'normal',
    label: 'Normal Cord Baseline',
    shortBadge: 'NORMAL',
    description: 'Intact corticospinal (motor), dorsal column (fine touch/vibration/proprioception), and spinothalamic (pain/temperature) pathways.',
    ipsilateralDeficit: 'None',
    contralateralDeficit: 'None',
    ssepStatus: 'SSEP 100% baseline amplitude & normal latency (19.8 ms)',
    mepStatus: 'MEP 100% robust compound muscle action potential',
    accentColor: Color(0xFF00E676),
  ),
  brownSequard(
    id: 'brown_sequard',
    label: 'Brown-Séquard Hemicord Syndrome',
    shortBadge: 'HEMICORD',
    description: 'Unilateral spinal cord hemisection (knife wound or lateral mass fracture): ipsilateral UMN paralysis and dorsal column loss, with contralateral pain and temperature loss 1–2 levels below.',
    ipsilateralDeficit: 'Spastic paresis (Corticospinal) + Loss of vibration & proprioception (Dorsal Columns)',
    contralateralDeficit: 'Loss of pain & temperature sensation 1-2 segments below lesion (Spinothalamic)',
    ssepStatus: 'Unilateral ipsilateral SSEP N20/P25 amplitude drop > 65%',
    mepStatus: 'Unilateral ipsilateral transcranial MEP complete loss',
    accentColor: Color(0xFFFF5252),
  ),
  anteriorCord(
    id: 'anterior_cord',
    label: 'Anterior Spinal Artery Cord Syndrome',
    shortBadge: 'ANT-CORD',
    description: 'Anterior spinal artery ischemia / aortic cross-clamp: bilateral corticospinal (paraplegia/quadriplegia) and spinothalamic loss with preserved dorsal columns (light touch/vibration intact).',
    ipsilateralDeficit: 'Bilateral complete flaccid/spastic motor paralysis below lesion (Bilateral CST)',
    contralateralDeficit: 'Bilateral loss of pain & temperature (Spinothalamic); Dorsal Columns spared',
    ssepStatus: 'SSEP preserved (Dorsal column posterior 1/3 cord perfusion intact)',
    mepStatus: 'MEP bilateral flatline (Anterior 2/3 spinal cord motor ischemia)',
    accentColor: Color(0xFFFF7043),
  ),
  centralCord(
    id: 'central_cord',
    label: 'Syringomyelia / Central Cord Syndrome',
    shortBadge: 'CENTRAL',
    description: 'Cervical hyperextension or cavitation (syrinx): suspended "cape-like" bilateral loss of pain/temperature crossing the anterior white commissure. Upper extremity weakness > Lower extremity.',
    ipsilateralDeficit: 'Upper extremity motor weakness & intrinsic hand atrophy > lower extremities',
    contralateralDeficit: 'Suspended bilateral "cape-like" dissociation of pain & temperature across dermatomes',
    ssepStatus: 'SSEP preserved until late advanced dorsal extension',
    mepStatus: 'Upper extremity MEP amplitude diminished by 55%; Lower extremity MEP preserved',
    accentColor: Color(0xFFFFD740),
  ),
  subacuteCombined(
    id: 'subacute_combined',
    label: 'Subacute Combined Degeneration (B12)',
    shortBadge: 'SCD (B12)',
    description: 'Vitamin B12 deficiency (pernicious anemia): progressive demyelination of posterior (dorsal) columns and lateral corticospinal tracts. Sensory ataxia with positive Romberg sign.',
    ipsilateralDeficit: 'Bilateral profound loss of vibration & position sense + positive Romberg test',
    contralateralDeficit: 'Bilateral spasticity, hyperreflexia, extensor plantar responses (Babinski +)',
    ssepStatus: 'Bilateral marked SSEP latency prolongation (> 26 ms) and severe attenuation',
    mepStatus: 'Bilateral delayed central motor conduction time (CMCT)',
    accentColor: Color(0xFFA78BFA),
  ),
  caudaEquina(
    id: 'cauda_equina',
    label: 'Cauda Equina Syndrome (Lumbosacral)',
    shortBadge: 'CAUDA',
    description: 'Massive central disc herniation / canal stenosis below L2: flaccid paraparesis, saddle anesthesia (S3–S5), urinary retention with overflow incontinence, and fecal incontinence.',
    ipsilateralDeficit: 'LMN flaccid lower extremity weakness, absent ankle jerk reflexes (S1)',
    contralateralDeficit: 'Bilateral "saddle anesthesia" (perineum, buttocks, inner thighs - S3-S5)',
    ssepStatus: 'Pudendal & posterior tibial SSEP latency delayed or absent',
    mepStatus: 'LMN denervation; absent motor evoked potentials in gastrocnemius/tibialis',
    accentColor: Color(0xFFFF1744),
  );

  final String id;
  final String label;
  final String shortBadge;
  final String description;
  final String ipsilateralDeficit;
  final String contralateralDeficit;
  final String ssepStatus;
  final String mepStatus;
  final Color accentColor;

  const SpinalSyndrome({
    required this.id,
    required this.label,
    required this.shortBadge,
    required this.description,
    required this.ipsilateralDeficit,
    required this.contralateralDeficit,
    required this.ssepStatus,
    required this.mepStatus,
    required this.accentColor,
  });
}

enum SpinalLevel {
  c5('C5', 'Cervical C5 (Deltoid / Biceps)', -13.5),
  t6('T6', 'Thoracic T6 (Xiphoid / Upper Trunk)', -23.0),
  l2('L2', 'Lumbar L2 (Iliopsoas / Hip Flexor)', -33.0),
  cauda('Cauda', 'Cauda Equina (S1–S5 Saddle / Sphincter)', -42.0);

  final String code;
  final String label;
  final double yPos;

  const SpinalLevel(this.code, this.label, this.yPos);
}

enum EegPattern {
  normalAlpha('alpha', 'Normal 10 Hz Posterior Alpha Rhythm', '10 Hz continuous sinusoidal rhythm, symmetrical background, reactive to eye opening.'),
  focalDeltaSlowing('delta', 'Focal Polymorphic Delta Slowing (1–3 Hz)', 'Unilateral hemispheric polymorphic delta slowing over the ischemic MCA territory indicating acute cortical injury.'),
  spikeAndWave('spike_wave', 'Generalized 3 Hz Spike-and-Wave Paroxysm', 'High-voltage, synchronous 3 Hz spike-and-wave discharges pathognomonic for generalized seizure activity / Status Epilepticus.'),
  burstSuppression('burst_suppression', 'Deep Burst Suppression', 'Alternating high-voltage polyphasic sharp bursts followed by isoelectric flatlines (<10 uV), indicating severe coma or deep sedation.');

  final String id;
  final String label;
  final String description;

  const EegPattern(this.id, this.label, this.description);

  String get shortCode => id.toUpperCase();
}

class NeuroClinicalScenario {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final double defaultIcp;       // mmHg
  final double defaultMap;       // mmHg
  final double defaultHeartRate; // bpm
  final EegPattern eegPattern;
  final bool hasM1Occlusion;
  final bool hasAneurysm;
  final SpinalSyndrome defaultSpineSyndrome;
  final String clinicalSummary;
  final String recommendedDrugMoa;

  const NeuroClinicalScenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.defaultIcp,
    required this.defaultMap,
    required this.defaultHeartRate,
    required this.eegPattern,
    required this.hasM1Occlusion,
    required this.hasAneurysm,
    required this.defaultSpineSyndrome,
    required this.clinicalSummary,
    required this.recommendedDrugMoa,
  });

  /// Cerebral Perfusion Pressure: CPP = MAP - ICP (normal 60–70 mmHg)
  double get defaultCpp => defaultMap - defaultIcp;
  double get icpMmHg => defaultIcp;
  double get mapMmHg => defaultMap;

  static const List<NeuroClinicalScenario> presets = [
    NeuroClinicalScenario(
      id: 'left_m1_stroke',
      title: 'Acute Left M1 MCA Occlusion (Large-Vessel Ischemic Stroke)',
      subtitle: 'Acute right hemiplegia, global aphasia, left gaze preference (NIHSS 18)',
      badge: 'LVO STROKE (M1)',
      badgeColor: Color(0xFFFF1744),
      defaultIcp: 14.0,
      defaultMap: 110.0,
      defaultHeartRate: 88.0,
      eegPattern: EegPattern.focalDeltaSlowing,
      hasM1Occlusion: true,
      hasAneurysm: false,
      defaultSpineSyndrome: SpinalSyndrome.normal,
      clinicalSummary: 'Abrupt left M1 trunk cutoff on biplane DSA. Large salvageable penumbra in the MCA territory. Emergent mechanical thrombectomy (Stent Retriever) and IV Tenecteplase indicated.',
      recommendedDrugMoa: 'Tenecteplase / Alteplase (tPA Fibrinolysis) & Levetiracetam (Neuroprotection)',
    ),
    NeuroClinicalScenario(
      id: 'ruptured_acom_sah',
      title: 'Ruptured ACom Aneurysm & Subarachnoid Hemorrhage',
      subtitle: '"Worst headache of life" (thunderclap), meningismus, Hunt & Hess 3, Fisher 3',
      badge: 'RUPTURED ANEURYSM',
      badgeColor: Color(0xFFFF5252),
      defaultIcp: 32.0,
      defaultMap: 135.0,
      defaultHeartRate: 52.0,
      eegPattern: EegPattern.focalDeltaSlowing,
      hasM1Occlusion: false,
      hasAneurysm: true,
      defaultSpineSyndrome: SpinalSyndrome.normal,
      clinicalSummary: 'Saccular ACom aneurysm with contrast extravasation. Severe ICP elevation (32 mmHg) eliciting the Cushing Triad (reflex hypertension MAP 135 mmHg and bradycardia 52 bpm). Endovascular coiling + Nimodipine indicated.',
      recommendedDrugMoa: 'Nimodipine (L-type CCB Vasospasm Prevention) & Mannitol / 3% NaCl (Osmotherapy)',
    ),
    NeuroClinicalScenario(
      id: 'status_epilepticus',
      title: 'Generalized Convulsive Status Epilepticus',
      subtitle: 'Continuous tonic-clonic convulsions > 15 min, unresponsiveness, autonomic storm',
      badge: 'STATUS EPILEPTICUS',
      badgeColor: Color(0xFFFF9100),
      defaultIcp: 24.0,
      defaultMap: 122.0,
      defaultHeartRate: 142.0,
      eegPattern: EegPattern.spikeAndWave,
      hasM1Occlusion: false,
      hasAneurysm: false,
      defaultSpineSyndrome: SpinalSyndrome.normal,
      clinicalSummary: 'Continuous generalized 3 Hz spike-and-wave discharges with sympathetic surge (HR 142 bpm). Excitotoxic neuronal necrosis risk; emergent IV Lorazepam + Levetiracetam infusion required.',
      recommendedDrugMoa: 'Lorazepam (GABA-A Positive Allosteric Modulator) & Levetiracetam (SV2A Blocker)',
    ),
    NeuroClinicalScenario(
      id: 'c5_brown_sequard',
      title: 'Traumatic Cervical C5 Hemicord Injury (Brown-Séquard)',
      subtitle: 'Penetrating lateral cervical trauma: asymmetric motor and dissociated sensory loss',
      badge: 'BROWN-SÉQUARD',
      badgeColor: Color(0xFF00E5FF),
      defaultIcp: 10.0,
      defaultMap: 92.0,
      defaultHeartRate: 74.0,
      eegPattern: EegPattern.normalAlpha,
      hasM1Occlusion: false,
      hasAneurysm: false,
      defaultSpineSyndrome: SpinalSyndrome.brownSequard,
      clinicalSummary: 'Left C5 hemisection: ipsilateral spastic paresis and loss of vibration/proprioception with contralateral spinothalamic pain/temperature loss below C6. SSEP and MEP drop ipsilaterally.',
      recommendedDrugMoa: 'High-Dose Methylprednisolone (Controversial) & Surgical Decompression',
    ),
    NeuroClinicalScenario(
      id: 'ant_spinal_artery',
      title: 'Anterior Spinal Artery Infarction (Anterior Cord)',
      subtitle: 'Acute bilateral paraplegia and loss of pain/temp below T6 with preserved vibration',
      badge: 'ANTERIOR CORD',
      badgeColor: Color(0xFFFF7043),
      defaultIcp: 11.0,
      defaultMap: 88.0,
      defaultHeartRate: 70.0,
      eegPattern: EegPattern.normalAlpha,
      hasM1Occlusion: false,
      hasAneurysm: false,
      defaultSpineSyndrome: SpinalSyndrome.anteriorCord,
      clinicalSummary: 'Artery of Adamkiewicz / anterior spinal artery thrombosis during aortic repair. Bilateral corticospinal paraplegia and spinothalamic loss; dorsal column light touch/vibration intact.',
      recommendedDrugMoa: 'CSF Drainage (Optimize Spinal Perfusion Pressure) & Hemodynamic Augmentation',
    ),
  ];
}

typedef NeuroScenario = NeuroClinicalScenario;
const List<NeuroClinicalScenario> kNeuroScenarios = NeuroClinicalScenario.presets;

