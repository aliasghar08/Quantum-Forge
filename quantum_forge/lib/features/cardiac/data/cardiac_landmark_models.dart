// ============================================================================
// CardioCath 3D: Micro-Anatomical Landmarks & Clinical Pearls
// ----------------------------------------------------------------------------
// 26 High-Yield Anatomical Structures spanning:
// - Valvular & Subvalvular Apparatus (Papillary muscles, Chordae, Annuli, Cusps)
// - Endocardial & Trabecular Micro-Architecture (Trabeculae, Moderator Band, Crista)
// - Conduction System (SA Node, AV Node, His, Bundle Branches, Purkinje)
// - Coronary Microvascular Arborization (LAD, D1, Septal Perforators, LCx, OM1, RCA, PDA)
//
// Supports both WebGL Three.js projection and Flutter vector matrix projection.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

enum LandmarkCategory {
  all('All', 'all'),
  chambers('Chambers & Wall', 'chambers'),
  valves('Valves & Chordae', 'valves'),
  conduction('Conduction', 'conduction'),
  coronaries('Coronary Micro', 'coronaries'),
  micro('Endocardial Micro', 'micro');

  final String label;
  final String keyName;
  const LandmarkCategory(this.label, this.keyName);
}

class CardiacLandmarkDefinition {
  final String id;
  final String name;
  final String category; // chambers, valves, conduction, coronaries, micro
  final double anchorX;
  final double anchorY;
  final double anchorZ;
  final String bloodSupply;
  final String description;
  final String clinicalPearl;

  const CardiacLandmarkDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.anchorX,
    required this.anchorY,
    required this.anchorZ,
    required this.bloodSupply,
    required this.description,
    required this.clinicalPearl,
  });
}

class ProjectedLandmark {
  final String id;
  final String name;
  final String category;
  final double x;
  final double y;
  final double normX;
  final double normY;
  final double depth;
  final bool visible;
  final String bloodSupply;
  final String description;
  final String clinicalPearl;

  const ProjectedLandmark({
    required this.id,
    required this.name,
    required this.category,
    required this.x,
    required this.y,
    required this.normX,
    required this.normY,
    required this.depth,
    required this.visible,
    required this.bloodSupply,
    required this.description,
    required this.clinicalPearl,
  });

  /// Mathematical 3D projection for Flutter custom painter fallback / tests.
  static ProjectedLandmark projectFrom3D({
    required CardiacLandmarkDefinition def,
    required double rotationY,
    required double rotationX,
    required double zoom,
    required Size screenSize,
    bool isCutaway = false,
  }) {
    // 1. Rotate Y (Azimuth)
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final x1 = def.anchorX * cosY - def.anchorZ * sinY;
    final z1 = def.anchorX * sinY + def.anchorZ * cosY;

    // 2. Rotate X (Elevation)
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);
    final y2 = def.anchorY * cosX - z1 * sinX;
    final z2 = def.anchorY * sinX + z1 * cosX;

    // 3. Perspective Projection
    const distance = 3.6;
    final perspective = distance / (distance - z2);
    final scale = math.min(screenSize.width, screenSize.height) * 0.42 * zoom * perspective;

    final screenCenterX = screenSize.width * 0.5;
    final screenCenterY = screenSize.height * 0.5;

    final projX = screenCenterX + x1 * scale;
    final projY = screenCenterY - y2 * scale; // Inverted Y

    // Occlusion check: back-facing when z2 < -0.15 unless cutaway is active
    final isFrontFacing = z2 > -0.22 || isCutaway;
    final inBounds = projX >= 20 && projX <= screenSize.width - 20 &&
                     projY >= 50 && projY <= screenSize.height - 50;

    return ProjectedLandmark(
      id: def.id,
      name: def.name,
      category: def.category,
      x: projX,
      y: projY,
      normX: (projX / screenSize.width).clamp(0.0, 1.0),
      normY: (projY / screenSize.height).clamp(0.0, 1.0),
      depth: z2,
      visible: inBounds && isFrontFacing,
      bloodSupply: def.bloodSupply,
      description: def.description,
      clinicalPearl: def.clinicalPearl,
    );
  }
}

/// Complete Registry of 26 High-Yield Anatomical Cardiac Structures
const List<CardiacLandmarkDefinition> kCardiacLandmarksRegistry = [
  CardiacLandmarkDefinition(
    id: 'sa_node',
    name: 'SA Node (Pacemaker)',
    category: 'conduction',
    anchorX: 0.55,
    anchorY: 0.58,
    anchorZ: 0.06,
    bloodSupply: 'SA Nodal Artery (60% RCA, 40% LCx)',
    description: 'Primary physiological cardiac pacemaker at SVC-RA junction generating 60-100 bpm intrinsic rhythm.',
    clinicalPearl: 'Sinus arrest and sick sinus syndrome commonly complicate acute proximal RCA occlusions.',
  ),
  CardiacLandmarkDefinition(
    id: 'av_node',
    name: 'AV Node (Triangle of Koch)',
    category: 'conduction',
    anchorX: 0.10,
    anchorY: 0.15,
    anchorZ: 0.04,
    bloodSupply: 'AV Nodal Artery (90% RCA from crux, 10% LCx)',
    description: 'Critical electrophysiological gateway delaying impulses (120-200 ms) to ensure complete ventricular filling.',
    clinicalPearl: 'Inferior STEMI frequently produces transient high-grade AV block due to AV nodal ischemia and vagal hyperactivity.',
  ),
  CardiacLandmarkDefinition(
    id: 'bundle_of_his',
    name: 'Bundle of His & Membranous Septum',
    category: 'conduction',
    anchorX: 0.06,
    anchorY: -0.05,
    anchorZ: 0.06,
    bloodSupply: 'Dual supply: AV nodal artery + 1st septal perforator of LAD',
    description: 'Penetrates the central fibrous body to convey impulses from AV node to the bundle branches.',
    clinicalPearl: 'Anterior STEMI causing infranodal His bundle block carries a high mortality rate and mandates temporary pacing.',
  ),
  CardiacLandmarkDefinition(
    id: 'purkinje_network',
    name: 'Purkinje Fiber Arborization',
    category: 'conduction',
    anchorX: -0.18,
    anchorY: -0.78,
    anchorZ: 0.08,
    bloodSupply: 'Branching septal perforators (LAD) and marginals',
    description: 'Subendocardial terminal conduction network propagating action potentials at 2-4 m/s for synchronized ventricular systole.',
    clinicalPearl: 'Ischemic Purkinje tissue is a notorious source of ventricular tachycardia and triggers for ventricular fibrillation.',
  ),
  CardiacLandmarkDefinition(
    id: 'mitral_valve',
    name: 'Mitral (Bicuspid) Valve & Annulus',
    category: 'valves',
    anchorX: -0.22,
    anchorY: 0.18,
    anchorZ: 0.04,
    bloodSupply: 'Avascular leaflets; fibrous ring perfused by atrial branches',
    description: 'Bicuspid left AV valve (anterior & posterior leaflets) anchored to fibrous annulus; prevents backflow during LV systole.',
    clinicalPearl: 'Anterior leaflet forms posterior boundary of LVOT; systolic anterior motion (SAM) causes dynamic obstruction in HOCM.',
  ),
  CardiacLandmarkDefinition(
    id: 'anterolateral_papillary',
    name: 'Anterolateral Papillary Muscle',
    category: 'valves',
    anchorX: -0.26,
    anchorY: -0.32,
    anchorZ: 0.12,
    bloodSupply: 'Dual supply: LAD (diagonals) & LCx (obtuse marginals)',
    description: 'Muscular LV column tethered to anterior and posterior mitral leaflets via primary and secondary chordae tendineae.',
    clinicalPearl: 'Relatively protected from ischemic rupture due to dual vascular perfusion compared to posteromedial papillary muscle.',
  ),
  CardiacLandmarkDefinition(
    id: 'posteromedial_papillary',
    name: 'Posteromedial Papillary Muscle',
    category: 'valves',
    anchorX: -0.28,
    anchorY: -0.30,
    anchorZ: -0.15,
    bloodSupply: 'Single blood supply: PDA (RCA in 85% of patients)',
    description: 'Posteromedial muscular LV pillar anchoring chordae to posterior and anterior mitral leaflets.',
    clinicalPearl: 'High rupture risk 3-5 days post-inferior STEMI, presenting with sudden holosystolic murmur, flash pulmonary edema, and shock.',
  ),
  CardiacLandmarkDefinition(
    id: 'chordae_tendineae',
    name: 'Chordae Tendineae (1°/2°/3° Cords)',
    category: 'valves',
    anchorX: -0.24,
    anchorY: -0.10,
    anchorZ: 0.02,
    bloodSupply: 'Diffusion from intracardiac blood',
    description: 'Collagenous tendinous cords spanning papillary heads to leaflet margins, preventing leaflet prolapse during ventricular systole.',
    clinicalPearl: 'Rupture from infective endocarditis or myxomatous degeneration produces severe acute mitral regurgitation.',
  ),
  CardiacLandmarkDefinition(
    id: 'aortic_valve',
    name: 'Aortic Valve & Nodules of Arantius',
    category: 'valves',
    anchorX: 0.04,
    anchorY: 0.32,
    anchorZ: 0.06,
    bloodSupply: 'Coronary root perfusion',
    description: 'Tricuspid semilunar valve guarding systemic outflow; Nodules of Arantius ensure tight central coaptation during diastole.',
    clinicalPearl: 'Bicuspid aortic valve (1-2% population) undergoes accelerated calcification, leading to premature severe aortic stenosis.',
  ),
  CardiacLandmarkDefinition(
    id: 'sinuses_of_valsalva',
    name: 'Sinuses of Valsalva (Aortic Root)',
    category: 'valves',
    anchorX: 0.06,
    anchorY: 0.38,
    anchorZ: 0.12,
    bloodSupply: 'Aortic lumen blood flow',
    description: 'Three anatomic root dilatations (Left, Right, Non-coronary) generating diastolic eddy currents that prevent leaflet sticking.',
    clinicalPearl: 'Congenital or acquired aneurysm can rupture into RV or RA, creating a continuous machinery-like shunt murmur.',
  ),
  CardiacLandmarkDefinition(
    id: 'tricuspid_valve',
    name: 'Tricuspid Valve & Annulus',
    category: 'valves',
    anchorX: 0.34,
    anchorY: 0.04,
    anchorZ: 0.14,
    bloodSupply: 'Right coronary atrial branches',
    description: 'Right AV valve with anterior, posterior, and septal leaflets anchored by fibrous annulus and chordae tendineae.',
    clinicalPearl: 'Carvallo sign: murmur of tricuspid regurgitation increases in intensity during inspiration due to increased right-heart preload.',
  ),
  CardiacLandmarkDefinition(
    id: 'pulmonic_valve',
    name: 'Pulmonic Semilunar Valve',
    category: 'valves',
    anchorX: 0.16,
    anchorY: 0.34,
    anchorZ: 0.20,
    bloodSupply: 'RVOT branches',
    description: 'Three semilunar cusps guarding the pulmonary trunk at the apex of the infundibulum (RVOT).',
    clinicalPearl: 'Tetralogy of Fallot features infundibular and pulmonic valve stenosis, driving RV hypertrophy and right-to-left shunt.',
  ),
  CardiacLandmarkDefinition(
    id: 'trabeculae_carneae',
    name: 'Trabeculae Carneae (LV/RV)',
    category: 'micro',
    anchorX: -0.16,
    anchorY: -0.62,
    anchorZ: 0.22,
    bloodSupply: 'Subendocardial coronary capillary network',
    description: 'Muscular ridges and columns lining the ventricular walls, preventing suction cavitation and streamlining diastolic inflow.',
    clinicalPearl: 'Left Ventricular Non-Compaction (LVNC) is characterized by prominent trabeculae with deep intertrabecular recesses.',
  ),
  CardiacLandmarkDefinition(
    id: 'moderator_band',
    name: 'Moderator Band (Septomarginal Trabecula)',
    category: 'micro',
    anchorX: 0.18,
    anchorY: -0.38,
    anchorZ: 0.14,
    bloodSupply: 'First or second septal perforator branch',
    description: 'Prominent muscular band in RV traversing from lower septum to base of anterior papillary muscle; conducts Right Bundle Branch.',
    clinicalPearl: 'Crucial anatomic landmark in echocardiography and fetal imaging to unequivocally identify the morphologic Right Ventricle.',
  ),
  CardiacLandmarkDefinition(
    id: 'crista_terminalis',
    name: 'Crista Terminalis (Right Atrium)',
    category: 'micro',
    anchorX: 0.46,
    anchorY: 0.35,
    anchorZ: 0.10,
    bloodSupply: 'Sinus node and right atrial circumflex branches',
    description: 'Smooth vertical muscular crest separating smooth-walled sinus venarum from trabeculated anterior right atrium.',
    clinicalPearl: 'Frequent site of origin for focal atrial tachycardia and anisotropic conduction supporting typical atrial flutter circuits.',
  ),
  CardiacLandmarkDefinition(
    id: 'pectinate_muscles',
    name: 'Pectinate Muscles (Atrial Appendages)',
    category: 'micro',
    anchorX: 0.42,
    anchorY: 0.18,
    anchorZ: 0.25,
    bloodSupply: 'Atrial branches of RCA and LCx',
    description: 'Comb-like muscular ridges lining anterior RA and both atrial appendages (RAA and LAA).',
    clinicalPearl: 'The trabeculated LAA is the nidus for >90% of cardiogenic thrombi in non-valvular Atrial Fibrillation.',
  ),
  CardiacLandmarkDefinition(
    id: 'fossa_ovalis',
    name: 'Fossa Ovalis & Limbus',
    category: 'micro',
    anchorX: 0.06,
    anchorY: 0.26,
    anchorZ: -0.06,
    bloodSupply: 'Interatrial septal branches',
    description: 'Thin central fibrous depression in the interatrial septum representing the closed fetal foramen ovale.',
    clinicalPearl: 'Patent Foramen Ovale (PFO, present in ~25% of population) enables right-to-left paradoxical embolization and cryptogenic stroke.',
  ),
  CardiacLandmarkDefinition(
    id: 'coronary_sinus_ostium',
    name: 'Coronary Sinus Ostium (Thebesian Valve)',
    category: 'micro',
    anchorX: 0.24,
    anchorY: 0.08,
    anchorZ: -0.14,
    bloodSupply: 'Cardiac venous drainage',
    description: 'Main cardiac venous orifice emptying into right atrium between IVC orifice and tricuspid valve.',
    clinicalPearl: 'Cannulated during Cardiac Resynchronization Therapy (CRT) to advance pacing leads into coronary veins over the LV free wall.',
  ),
  CardiacLandmarkDefinition(
    id: 'lad_artery',
    name: 'Left Anterior Descending (LAD) Artery',
    category: 'coronaries',
    anchorX: -0.06,
    anchorY: 0.02,
    anchorZ: 0.40,
    bloodSupply: 'Left Main Coronary Artery',
    description: "'Widowmaker' artery coursing down anterior interventricular sulcus supplying >45% of LV myocardium, anterior septum, and apex.",
    clinicalPearl: 'Acute proximal occlusion causes extensive anterior STEMI (V1-V4), high risk of cardiogenic shock, and mandates primary PCI.',
  ),
  CardiacLandmarkDefinition(
    id: 'diagonal_d1',
    name: 'First Diagonal (D1) Branch',
    category: 'coronaries',
    anchorX: -0.35,
    anchorY: -0.18,
    anchorZ: 0.40,
    bloodSupply: 'LAD artery',
    description: 'Large epicardial branch running anterolaterally across the high anterolateral left ventricular free wall.',
    clinicalPearl: 'Isolated occlusion manifests as high lateral STEMI with ST-elevation in leads I and aVL and reciprocal depression in inferior leads.',
  ),
  CardiacLandmarkDefinition(
    id: 'septal_perforators',
    name: 'Intramyocardial Septal Perforators',
    category: 'coronaries',
    anchorX: -0.04,
    anchorY: -0.15,
    anchorZ: 0.22,
    bloodSupply: 'LAD artery',
    description: 'Perpendicular penetrating arteries plunging into the interventricular septum to supply conduction fascicles and inner myocardium.',
    clinicalPearl: 'Targeted during Alcohol Septal Ablation (infusion of dehydrated ethanol) to relieve LVOT gradient in obstructive HOCM.',
  ),
  CardiacLandmarkDefinition(
    id: 'lcx_artery',
    name: 'Left Circumflex (LCx) Artery',
    category: 'coronaries',
    anchorX: -0.38,
    anchorY: 0.20,
    anchorZ: 0.14,
    bloodSupply: 'Left Main Coronary Artery',
    description: 'Travels in the left atrioventricular sulcus to supply the posterolateral left ventricle and left atrium.',
    clinicalPearl: "Occlusion can be 'electrocardiographically silent' on standard 12-lead ECG, requiring posterior leads (V7-V9) for detection.",
  ),
  CardiacLandmarkDefinition(
    id: 'om1_branch',
    name: 'First Obtuse Marginal (OM1) Branch',
    category: 'coronaries',
    anchorX: -0.56,
    anchorY: -0.15,
    anchorZ: 0.04,
    bloodSupply: 'LCx artery',
    description: 'Epicardial branch descending over the obtuse (lateral) border of the left ventricle.',
    clinicalPearl: 'Key target vessel during CABG; supplies lateral LV wall and anterolateral papillary muscle.',
  ),
  CardiacLandmarkDefinition(
    id: 'rca_artery',
    name: 'Right Coronary Artery (RCA)',
    category: 'coronaries',
    anchorX: 0.52,
    anchorY: 0.0,
    anchorZ: 0.28,
    bloodSupply: 'Right aortic sinus (Sinus of Valsalva)',
    description: 'Courses along the right atrioventricular groove supplying the right ventricle, inferior wall, SA and AV nodes.',
    clinicalPearl: 'Acute occlusion produces Inferior STEMI (II, III, aVF); RV involvement requires volume loading and avoidance of nitrates.',
  ),
  CardiacLandmarkDefinition(
    id: 'pda_artery',
    name: 'Posterior Descending Artery (PDA)',
    category: 'coronaries',
    anchorX: 0.14,
    anchorY: -0.54,
    anchorZ: -0.26,
    bloodSupply: 'RCA (85% right-dominant) or LCx (10% left-dominant)',
    description: 'Runs in posterior interventricular sulcus supplying inferior 1/3 of septum and posteromedial papillary muscle.',
    clinicalPearl: 'Defines coronary dominance; provides sole arterial supply to posteromedial papillary muscle.',
  ),
  CardiacLandmarkDefinition(
    id: 'left_ventricle_apex',
    name: 'Left Ventricular Apex & Myocardium',
    category: 'chambers',
    anchorX: -0.20,
    anchorY: -0.80,
    anchorZ: 0.18,
    bloodSupply: 'LAD artery termination (apical wrap-around)',
    description: 'Muscular apex of the heart formed entirely by the left ventricle; location of apical point of maximal impulse (PMI).',
    clinicalPearl: 'Apical ballooning and hypercontractile basal segments characterize Takotsubo (Stress) Cardiomyopathy.',
  ),
];
