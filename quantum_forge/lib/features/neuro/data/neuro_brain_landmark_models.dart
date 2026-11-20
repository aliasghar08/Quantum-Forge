// ============================================================================
// NeuroLab 3D: Micro-Anatomical Brain Landmark Models
// ----------------------------------------------------------------------------
// High-yield anatomical landmarks across the cerebrum, Circle of Willis,
// ventricular system, cranial nerves, and spinal cord tracts (C1–L5).
// Includes USMLE & Neurosurgery Board clinical pearls and vascular supplies.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';

enum NeuroTagCategory {
  all('All Landmarks'),
  cortical('Cortical & Deep Nuclei'),
  vessels('Circle of Willis'),
  csf('CSF & Ventricles'),
  cranialNerves('Cranial Nerves'),
  spinal('Spinal Tracts (C1–L5)');

  final String label;
  const NeuroTagCategory(this.label);
}

class NeuroLandmarkTag {
  final String id;
  final String label;
  final String shortCode;
  final NeuroTagCategory category;
  final String vascularSupply;
  final String functionalRole;
  final String clinicalPearl;
  final double x3D;
  final double y3D;
  final double z3D;
  final Color badgeColor;

  const NeuroLandmarkTag({
    required this.id,
    required this.label,
    required this.shortCode,
    required this.category,
    required this.vascularSupply,
    required this.functionalRole,
    required this.clinicalPearl,
    required this.x3D,
    required this.y3D,
    required this.z3D,
    this.badgeColor = const Color(0xFF00E5FF),
  });
}

const List<NeuroLandmarkTag> kNeuroTags = [
  // ── Cortical & Deep Nuclei ──────────────────────────────────────────────
  NeuroLandmarkTag(
    id: 'primary_motor_cortex',
    label: 'Precentral Gyrus (Motor Homunculus)',
    shortCode: 'M1 Cortex',
    category: NeuroTagCategory.cortical,
    vascularSupply: 'ACA (medial leg/foot) & MCA (lateral face/hand)',
    functionalRole: 'Primary voluntary somatic motor output (Brodmann Area 4 via corticospinal tract).',
    clinicalPearl: 'Focal ischemia triggers contralateral hemiparesis. MCA territory preferentially paralyzes face and arm; ACA preferentially paralyzes leg and foot.',
    x3D: -25,
    y3D: 40,
    z3D: 10,
    badgeColor: Color(0xFFEF4444),
  ),
  NeuroLandmarkTag(
    id: 'brocas_area',
    label: "Broca's Motor Speech Area (Pars Opercularis)",
    shortCode: "Broca's",
    category: NeuroTagCategory.cortical,
    vascularSupply: 'Left MCA Superior Division (Anterior branches)',
    functionalRole: 'Motor expressive speech planning & grammatical articulation (Brodmann Areas 44 & 45).',
    clinicalPearl: 'Expressive (non-fluent) aphasia with preserved comprehension. Patients exhibit telegraphic, halting speech and intense frustration because awareness is intact.',
    x3D: -45,
    y3D: 25,
    z3D: 30,
    badgeColor: Color(0xFFF59E0B),
  ),
  NeuroLandmarkTag(
    id: 'wernickes_area',
    label: "Wernicke's Sensory Speech Area (Superior Temporal)",
    shortCode: "Wernicke's",
    category: NeuroTagCategory.cortical,
    vascularSupply: 'Left MCA Inferior Division',
    functionalRole: 'Receptive auditory language decoding and semantic comprehension (Brodmann Area 22).',
    clinicalPearl: 'Fluent (receptive) aphasia: effortless "word salad" with neologisms and complete lack of comprehension, typically paired with anosognosia (unawareness of deficit).',
    x3D: -50,
    y3D: 5,
    z3D: -15,
    badgeColor: Color(0xFF10B981),
  ),
  NeuroLandmarkTag(
    id: 'somatosensory_cortex',
    label: 'Postcentral Gyrus (Primary Somatosensory)',
    shortCode: 'S1 Cortex',
    category: NeuroTagCategory.cortical,
    vascularSupply: 'MCA & ACA cortical branches',
    functionalRole: 'Discriminative touch, proprioception, pain and temperature localization (Brodmann Areas 3, 1, 2).',
    clinicalPearl: 'Lesions cause contralateral cortical sensory loss: loss of two-point discrimination, astereognosis, and agraphesthesia with preserved crude pain.',
    x3D: -25,
    y3D: 38,
    z3D: -8,
    badgeColor: Color(0xFF38BDF8),
  ),
  NeuroLandmarkTag(
    id: 'basal_ganglia',
    label: 'Basal Ganglia (Caudate & Putamen Striatum)',
    shortCode: 'Striatum',
    category: NeuroTagCategory.cortical,
    vascularSupply: 'Lateral Lenticulostriate Arteries (from M1 MCA)',
    functionalRole: 'GABAergic motor loop gating, action selection, and procedural habit formation.',
    clinicalPearl: 'Charcot-Bouchard microaneurysms from chronic HTN rupture here, triggering classic hypertensive deep intracerebral hemorrhage (ICH) with dense contralateral hemiplegia.',
    x3D: -18,
    y3D: 10,
    z3D: 12,
    badgeColor: Color(0xFFA855F7),
  ),

  // ── Circle of Willis ───────────────────────────────────────────────────
  NeuroLandmarkTag(
    id: 'm1_mca_trunk',
    label: 'Middle Cerebral Artery (M1 Sphenoidal Trunk)',
    shortCode: 'M1 MCA',
    category: NeuroTagCategory.vessels,
    vascularSupply: 'Terminal branch of Internal Carotid Artery (ICA)',
    functionalRole: 'Supplies 70% of the cerebral hemisphere including lateral convexity and internal capsule.',
    clinicalPearl: 'Target of emergency mechanical thrombectomy! LVO acute occlusion yields global hemiplegia, forced gaze toward lesion, and global aphasia (left) or neglect (right).',
    x3D: -24,
    y3D: -12,
    z3D: 18,
    badgeColor: Color(0xFF00E5FF),
  ),
  NeuroLandmarkTag(
    id: 'acom_aneurysm',
    label: 'Anterior Communicating Artery (ACom)',
    shortCode: 'ACom Junction',
    category: NeuroTagCategory.vessels,
    vascularSupply: 'Bridges left and right A1 segments of Anterior Cerebral Arteries',
    functionalRole: 'Collateral cross-filling between anterior hemispheric circulations.',
    clinicalPearl: 'Most common site of saccular "berry" aneurysms (~35% of all intracranial aneurysms). Rupture produces severe aneurysmal subarachnoid hemorrhage (thunderclap headache) and CN III palsy.',
    x3D: 0,
    y3D: -14,
    z3D: 30,
    badgeColor: Color(0xFFEC4899),
  ),
  NeuroLandmarkTag(
    id: 'basilar_artery',
    label: 'Basilar Artery Trunk',
    shortCode: 'Basilar',
    category: NeuroTagCategory.vessels,
    vascularSupply: 'Formed by confluence of left and right Vertebral Arteries',
    functionalRole: 'Perfuses pons, midbrain, superior cerebellum, and posterior cerebral arteries (PCA).',
    clinicalPearl: 'Basilar tip or trunk thrombosis causes "Locked-In Syndrome" (intact consciousness with quadriplegia and loss of horizontal eye movements; vertical gaze and blinking preserved).',
    x3D: 0,
    y3D: -32,
    z3D: -10,
    badgeColor: Color(0xFF38BDF8),
  ),
  NeuroLandmarkTag(
    id: 'carotid_siphon',
    label: 'Internal Carotid Artery (Cavernous Siphon)',
    shortCode: 'Carotid Siphon',
    category: NeuroTagCategory.vessels,
    vascularSupply: 'Ascending petrous/cavernous segment of ICA',
    functionalRole: 'Primary anterior circulation inflow to Circle of Willis.',
    clinicalPearl: 'S-shaped siphon dampens systolic arterial pressure pulses before microvascular entry. Cavernous sinus thrombosis or aneurysm here compresses CN III, IV, V1, V2, and VI.',
    x3D: -14,
    y3D: -24,
    z3D: 10,
    badgeColor: Color(0xFF6366F1),
  ),

  // ── CSF & Ventricles ────────────────────────────────────────────────────
  NeuroLandmarkTag(
    id: 'lateral_ventricle',
    label: 'Lateral Ventricle (Anterior Horn)',
    shortCode: 'Lateral Ventricle',
    category: NeuroTagCategory.csf,
    vascularSupply: 'Choroid plexus supplied by Anterior/Posterior Choroidal Arteries',
    functionalRole: 'CSF production (500 mL/day) and hydro-dynamic brain cushioning.',
    clinicalPearl: 'Hydrocephalus (communicating vs non-communicating). In Normal Pressure Hydrocephalus (NPH), ventriculomegaly presents with classic triad: wet (incontinence), wacky (dementia), and wobbly (magnetic gait).',
    x3D: -15,
    y3D: 18,
    z3D: 15,
    badgeColor: Color(0xFF06B6D4),
  ),
  NeuroLandmarkTag(
    id: 'aqueduct_sylvius',
    label: 'Cerebral Aqueduct of Sylvius (Midbrain)',
    shortCode: 'Aqueduct',
    category: NeuroTagCategory.csf,
    vascularSupply: 'Surrounded by Periaqueductal Gray (PAG)',
    functionalRole: 'Narrow conduit channeling CSF from Third to Fourth Ventricle.',
    clinicalPearl: 'Narrowest point in CSF pathway (~1.5 mm diameter). Stenosis from tectal glioma or congenital web causes obstructive non-communicating hydrocephalus with Parinaud syndrome (upward gaze palsy).',
    x3D: 0,
    y3D: -8,
    z3D: -12,
    badgeColor: Color(0xFF0EA5E9),
  ),

  // ── Cranial Nerves ──────────────────────────────────────────────────────
  NeuroLandmarkTag(
    id: 'optic_chiasm',
    label: 'Optic Chiasm (Cranial Nerve II)',
    shortCode: 'CN II Chiasm',
    category: NeuroTagCategory.cranialNerves,
    vascularSupply: 'Ophthalmic & Superior Hypophyseal Arteries',
    functionalRole: 'Decussation of nasal retinal ganglion fibers transmitting contralateral visual fields.',
    clinicalPearl: 'Pituitary adenoma or anterior skull base meningioma expanding superiorly compresses chiasmal decussation, generating classic Bitemporal Hemianopsia ("tunnel vision").',
    x3D: 0,
    y3D: -16,
    z3D: 22,
    badgeColor: Color(0xFFFFD600),
  ),
  NeuroLandmarkTag(
    id: 'oculomotor_nerve',
    label: 'Oculomotor Nerve (Cranial Nerve III)',
    shortCode: 'CN III',
    category: NeuroTagCategory.cranialNerves,
    vascularSupply: 'PCom & Superior Cerebellar Artery (SCA) branches',
    functionalRole: 'Extraocular motility (SR, IR, MR, IO, levator) and parasympathetic pupillary constriction.',
    clinicalPearl: 'Uncal herniation (temporal lobe squeezing over tentorium) or PCom aneurysm compresses outer parasympathetic fibers first -> "blown pupil" (mydriasis, non-reactive), followed by "down and out" gaze.',
    x3D: -8,
    y3D: -22,
    z3D: 4,
    badgeColor: Color(0xFFF97316),
  ),
  NeuroLandmarkTag(
    id: 'trigeminal_ganglion',
    label: 'Trigeminal Nerve & Gasserian Ganglion (CN V)',
    shortCode: 'CN V Ganglion',
    category: NeuroTagCategory.cranialNerves,
    vascularSupply: 'Pons basilar perforators and Meckel cave dural arteries',
    functionalRole: 'Facial sensory dermatomes (V1 ophthalmic, V2 maxillary, V3 mandibular) and muscles of mastication.',
    clinicalPearl: 'Neurovascular compression by aberrant SCA loop at root entry zone causes Trigeminal Neuralgia (tic douloureux): paroxysmal electric lancinating facial pain treated with Carbamazepine or Janetta decompression.',
    x3D: -16,
    y3D: -28,
    z3D: -4,
    badgeColor: Color(0xFFEAB308),
  ),

  // ── Spinal Tracts (C1–L5) ───────────────────────────────────────────────
  NeuroLandmarkTag(
    id: 'lateral_corticospinal',
    label: 'Lateral Corticospinal Tract (Spinal Motor Column)',
    shortCode: 'Corticospinal',
    category: NeuroTagCategory.spinal,
    vascularSupply: 'Anterior Spinal Artery (ASA)',
    functionalRole: 'Carries descending voluntary motor commands to distal limb muscles (crossed at medullary pyramids).',
    clinicalPearl: 'Upper Motor Neuron (UMN) lesion yields spastic paralysis, hyperreflexia, positive Babinski sign, and clonus. Anterior cord syndrome (ASA infarct) paralyzes both sides below the lesion.',
    x3D: -6,
    y3D: -70,
    z3D: -4,
    badgeColor: Color(0xFFEF4444),
  ),
  NeuroLandmarkTag(
    id: 'dorsal_columns',
    label: 'Dorsal Columns (Fasciculus Gracilis & Cuneatus)',
    shortCode: 'DCML Column',
    category: NeuroTagCategory.spinal,
    vascularSupply: 'Posterior Spinal Arteries (PSA)',
    functionalRole: 'Ascending conscious proprioception, vibratory sense, and fine discriminative touch.',
    clinicalPearl: 'Subacute Combined Degeneration (Vitamin B12 deficiency) or Tabes Dorsalis (tertiary syphilis) demyelinates dorsal columns -> sensory ataxia with positive Romberg sign (swaying when eyes close).',
    x3D: 0,
    y3D: -72,
    z3D: -10,
    badgeColor: Color(0xFF10B981),
  ),
  NeuroLandmarkTag(
    id: 'spinothalamic_tract',
    label: 'Lateral Spinothalamic Tract (Anterolateral System)',
    shortCode: 'Spinothalamic',
    category: NeuroTagCategory.spinal,
    vascularSupply: 'Anterior Spinal Artery (ASA) pial plexus',
    functionalRole: 'Ascending pain, temperature, and crude touch sensations (decussates at anterior white commissure).',
    clinicalPearl: 'Syringomyelia (fluid cavity expanding within central canal) compresses crossing anterior commissure fibers first, creating "cape-like" bilateral loss of pain & temperature across upper extremities.',
    x3D: 8,
    y3D: -74,
    z3D: 0,
    badgeColor: Color(0xFFF59E0B),
  ),
];

const List<NeuroLandmarkTag> kDefaultNeuroBrainTags = kNeuroTags;
