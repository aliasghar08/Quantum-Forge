// ============================================================================
// Cardiac Clinical Info Tooltip System, Interactive Guide & Legal Shield
// ----------------------------------------------------------------------------
// Provides:
// 1. Rich hoverable & clickable `ⓘ` (`CardiacInfoButton`) widgets across the
//    entire CardioCath 3D Lab (View Modes, Dual-Circulation Vessels, Chambers,
//    Interventional Toolkit, Fluoroscopy, C-Arm Gantry, IVUS/OCT, and ECG/Pa/Pd).
// 2. Dual-tier explanation architecture:
//    - Tier 1 (Plain-English Summary): Intuitive, crystal-clear explanation
//      for students and general users.
//    - Tier 2 (Advanced Biophysics & Clinical Cardiology): Equations, normal
//      hemodynamic pressures, O2 saturations, and board exam pearls.
// 3. Comprehensive 7-Pillar Legal, Regulatory (FDA 21 U.S.C. § 360j(o) / EU MDR),
//    Tort/Malpractice, Nominative Trademark Fair-Use, Zero-PHI Privacy, and
//    In-Silico AI Liability Protection Shield (`CardiacLegalShieldDialog`).
// ============================================================================

import 'package:flutter/material.dart';

class CardiacInfoTopic {
  final String id;
  final String title;
  final String category;
  final Color accentColor;
  final String plainLanguageSummary;
  final String advancedMechanism;
  final String normalReferenceRange;
  final String clinicalBoardPearl;
  final String howToInteract;

  const CardiacInfoTopic({
    required this.id,
    required this.title,
    required this.category,
    required this.accentColor,
    required this.plainLanguageSummary,
    required this.advancedMechanism,
    required this.normalReferenceRange,
    required this.clinicalBoardPearl,
    required this.howToInteract,
  });
}

/// Comprehensive Knowledge Base of Cardiac Anatomy, Dual-Circulation Hemodynamics,
/// Interventional Cath Lab Devices, Electrophysiology, and Regulatory Shields.
const Map<String, CardiacInfoTopic> kCardiacInfoTopics = {
  // ── 1. 3D HEART VIEW MODES ────────────────────────────────────────────────
  'mode_anatomy': CardiacInfoTopic(
    id: 'mode_anatomy',
    title: '3D Translucent Living Anatomy Mode',
    category: '3D HEART VIEWPORT MODE',
    accentColor: Color(0xFFEF4444),
    plainLanguageSummary:
        'Shows the outer muscular walls of the heart (myocardium) with medical glassmorphic translucency so you can see both the surface vessels and the beating chambers inside at the same time.',
    advancedMechanism:
        'Renders the hyperelastic left and right ventricular myocardium using Fresnel rim-lighting and subsurface scattering approximations. The Left Ventricle (LV) forms the apex and posterior-lateral border (wall thickness 10–12 mm) to pump against systemic resistance, while the crescent-shaped Right Ventricle (RV, thickness 3–4 mm) wraps anteriorly to pump into the low-resistance pulmonary circuit.',
    normalReferenceRange:
        'LV Wall Thickness: 8–11 mm | RV Wall Thickness: 3–5 mm | Pericardial Fluid: 15–50 mL | Resting Heart Rate: 60–100 bpm',
    clinicalBoardPearl:
        'The anterior surface of the heart in the chest is predominantly the Right Ventricle (RV), making the RV the most commonly injured chamber in penetrating anterior stab wounds to the parasternal chest.',
    howToInteract:
        'Drag anywhere on the 3D heart to orbit 360°, pinch or scroll to zoom, and toggle the label icon to inspect surface landmarks.',
  ),
  'mode_chambers': CardiacInfoTopic(
    id: 'mode_chambers',
    title: '4-Chamber Cutaway & Valve Mechanics Mode',
    category: '3D HEART VIEWPORT MODE',
    accentColor: Color(0xFFF59E0B),
    plainLanguageSummary:
        'Slices open the front wall of the heart so you can directly watch all 4 internal chambers (RA, RV, LA, LV), the dividing muscular wall (septum), and the 4 one-way heart valves opening and closing with every beat.',
    advancedMechanism:
        'Demonstrates synchronized atrioventricular (Tricuspid & Mitral) and semilunar (Pulmonic & Aortic) valve kinematics anchored by papillary muscles and chordae tendineae. During diastole, AV valves open while semilunar valves remain closed; during systole (after isovolumetric contraction), AV valves snap shut (S1 heart sound) and semilunar valves open to eject stroke volume.',
    normalReferenceRange:
        'RA: 2–6 mmHg | RV: 25/4 mmHg | LA: 6–12 mmHg | LV: 120/8 mmHg | LVEF: 55–70% | Stroke Volume: ~70 mL/beat',
    clinicalBoardPearl:
        'Posteromedial papillary muscle rupture after an Inferior MI (RCA occlusion) causes acute severe mitral regurgitation because it has a single blood supply (PDA), whereas the anterolateral papillary muscle has dual supply (LAD + LCx).',
    howToInteract:
        'Use the 120-Frame FSI Physics bar to slow playback to 0.25x or scrub frame-by-frame to watch Mitral/Tricuspid closure vs. Aortic/Pulmonic opening.',
  ),
  'mode_bloodFlow': CardiacInfoTopic(
    id: 'mode_bloodFlow',
    title: 'Full Dual-Circulation Blood Flow Mode (Incoming & Outgoing)',
    category: '3D HEART VIEWPORT MODE',
    accentColor: Color(0xFF00E5FF),
    plainLanguageSummary:
        'Highlights the complete two-circuit plumbing of the heart: blue deoxygenated blood flowing IN from the body and OUT to the lungs, simultaneously with red oxygenated blood flowing IN from the lungs and OUT through the aorta and coronary arteries.',
    advancedMechanism:
        'Visualizes Lagrangian particle advection across both right-heart (systemic venous return -> pulmonary arterial) and left-heart (pulmonary venous -> systemic & coronary arterial) circuits:\n'
        '• INCOMING DEOXYGENATED (Cyan/Blue): Superior Vena Cava (SVC), Inferior Vena Cava (IVC), and Coronary Sinus (CS) empty into the Right Atrium (RA) -> Tricuspid Valve -> Right Ventricle (RV).\n'
        '• OUTGOING PULMONARY (Blue): RV ejects through the Pulmonic Valve into the Main Pulmonary Artery & Left/Right branches.\n'
        '• INCOMING OXYGENATED (Bright Red/Pink): 4 Pulmonary Veins (LSPV, LIPV, RSPV, RIPV) deliver oxygenated blood into the Left Atrium (LA) -> Mitral Valve -> Left Ventricle (LV).\n'
        '• OUTGOING SYSTEMIC & CORONARY (Red): LV ejects into the Ascending Aorta, Aortic Arch, and Epicardial Coronary Tree.',
    normalReferenceRange:
        'Cardiac Output (CO): 5.0 L/min | Venous SvO2: ~75% | Arterial SaO2: 97–100% | Coronary Sinus ScsO2: ~30% (highest O2 extraction in body)',
    clinicalBoardPearl:
        'Because the LV myocardium compresses intramyocardial vessels during systole, ~80% of Left Coronary Artery (LAD/LCx) blood flow occurs during DIASTOLE, driven by the aortic diastolic pressure minus LV end-diastolic pressure (CPP = DBP - LVEDP).',
    howToInteract:
        'Switch between Normal Circulation and STEMI scenarios to see how proximal LAD or RCA occlusion halts downstream red arterial perfusion while venous return continues.',
  ),
  'mode_conduction': CardiacInfoTopic(
    id: 'mode_conduction',
    title: 'Electrical Cardiac Conduction Network Mode',
    category: '3D HEART VIEWPORT MODE',
    accentColor: Color(0xFF10B981),
    plainLanguageSummary:
        'Reveals the heart’s internal electrical wiring system that generates the heartbeat spark and coordinates contraction from the top chambers (atria) to the bottom pumping chambers (ventricles).',
    advancedMechanism:
        'Tracks action potential propagation across the specialized pacemaker and conduction tissue synchronized to the Lead II ECG:\n'
        '1. Sinoatrial (SA) Node (Right atrial roof near SVC): Fires spontaneously at 60–100 bpm via funny current (If / HCN4 channels) -> triggers P-Wave (phi = 0.08–0.17).\n'
        '2. Atrioventricular (AV) Node (Koch’s triangle): Introduces a physiological ~100 ms delay (PR segment, phi = 0.17–0.23) allowing atrial kick to finish filling the ventricles.\n'
        '3. Bundle of His, Left/Right Bundle Branches & Purkinje Network: Rapid Na+ (Nav1.5) conduction (2–4 m/s) depolarizing ventricular myocardium from endocardium to epicardium -> razor-sharp QRS complex (phi = 0.23–0.31).',
    normalReferenceRange:
        'PR Interval: 120–200 ms | QRS Duration: < 100 ms | QT Interval (QTc): < 440 ms (men) / < 460 ms (women)',
    clinicalBoardPearl:
        'The AV node is supplied by the AV nodal branch of the PDA (arising from the RCA in 85–90% of people). Therefore, Acute Inferior MI (RCA occlusion) frequently presents with sinus bradycardia and 1st- or 2nd-degree Mobitz I (Wenckebach) AV block.',
    howToInteract:
        'Watch the golden action-potential sparks travel from the SA node (green) through the AV node (amber) into the cyan His-Purkinje fibers in exact phase-lock with the bottom ECG strip.',
  ),
  'mode_coronaries': CardiacInfoTopic(
    id: 'mode_coronaries',
    title: 'Vessels Mode (Dual-Circulation Arterial Supply & Venous Drainage)',
    category: '3D HEART VIEWPORT MODE',
    accentColor: Color(0xFF38BDF8),
    plainLanguageSummary:
        'Isolates and highlights the heart’s complete vascular network—showing BOTH the incoming venous pipes bringing blood into the heart (Vena Cava, Pulmonary Veins, and Coronary Sinus) AND the outgoing arterial pipes feeding the heart muscle and body (Aorta, Pulmonary Trunk, LAD, LCx, RCA).',
    advancedMechanism:
        'Renders full dual-circulation vascular anatomy with simultaneously active incoming and outgoing particle streams:\n'
        '• INCOMING GREAT VEINS: Superior Vena Cava (SVC) & Inferior Vena Cava (IVC) -> RA; 4 Pulmonary Veins -> LA.\n'
        '• INCOMING CORONARY VENOUS RETURN: Great Cardiac Vein (GCV) ascends alongside the LAD in the anterior interventricular sulcus, wraps around the left AV groove as the Coronary Sinus (CS), and drains deoxygenated myocardial blood directly into the posterior floor of the Right Atrium.\n'
        '• OUTGOING GREAT ARTERIES & CORONARY TREE: Ascending Aorta & Arch, Pulmonary Trunk, Left Main (LM), Left Anterior Descending (LAD + D1/D2 diagonals), Left Circumflex (LCx + OM1), and Right Coronary Artery (RCA + PDA).',
    normalReferenceRange:
        'Coronary Blood Flow: ~250 mL/min (5% of Cardiac Output) | Left Main Diameter: 4.0–5.0 mm | Proximal LAD Diameter: 3.0–4.0 mm',
    clinicalBoardPearl:
        'The Great Cardiac Vein accompanies the LAD anteriorly, while the Middle Cardiac Vein accompanies the PDA posteriorly. Both drain into the Coronary Sinus, whose orifice in the Right Atrium is guarded by the Thebesian valve.',
    howToInteract:
        'Click "Inject Contrast Dye" or "Simulate PCI Stent" while in Vessels mode to watch radiopaque contrast and stent restoration across the coronary tree alongside continuous venous return.',
  ),
  'mode_ischemiaMap': CardiacInfoTopic(
    id: 'mode_ischemiaMap',
    title: 'AHA 17-Segment Myocardial Perfusion & Ischemia Map',
    category: '3D HEART VIEWPORT MODE',
    accentColor: Color(0xFFA855F7),
    plainLanguageSummary:
        'Colors the heart muscle like a thermal weather map to show which regions are getting healthy blood flow (green), borderline flow (amber), or starving for oxygen due to a blocked artery (dark purple/red).',
    advancedMechanism:
        'Maps the standardized American Heart Association (AHA) 17-Segment Left Ventricular model onto the 3D myocardium:\n'
        '• LAD Territory (Segments 1, 2, 7, 8, 13, 14, 17): Basal/Mid Anterior, Anteroseptal, and Apical cap.\n'
        '• RCA Territory (Segments 3, 4, 9, 10, 15): Basal/Mid Inferior and Inferoseptal wall.\n'
        '• LCx Territory (Segments 5, 6, 11, 12, 16): Basal/Mid/Apical Anterolateral and Inferolateral free wall.\n'
        'Perfusion color is driven by local Fractional Flow Reserve (FFR) and myocardial oxygen supply/demand ratio.',
    normalReferenceRange:
        'Normal Segmental Perfusion: FFR > 0.85 (Emerald Green) | Inducible Ischemia: FFR <= 0.80 (Amber/Purple-Red) | Infarct Core: TIMI 0',
    clinicalBoardPearl:
        'Transmural ischemia begins in the subendocardium first because subendocardial myocardium experiences the highest intramyocardial compressive wall stress (Law of Laplace: T = P * r / 2h) and is farthest from epicardial coronary arteries.',
    howToInteract:
        'Select "Acute Anterior STEMI" to see the anterior/apical LAD territory turn dark ischemic purple, then click "Simulate PCI Stent" to watch immediate green reperfusion.',
  ),
  'mode_colorDoppler': CardiacInfoTopic(
    id: 'mode_colorDoppler',
    title: 'Echocardiographic Color Doppler Velocity Mode (BART Convention)',
    category: '3D HEART VIEWPORT MODE',
    accentColor: Color(0xFF00B0FF),
    plainLanguageSummary:
        'Simulates hospital ultrasound Color Doppler, coloring blood RED when it flows toward the heart apex (filling) and BLUE when it shoots away from the apex (pumping out), with yellow-green mosaic flashes where blood swirls turbulently.',
    advancedMechanism:
        'Applies the clinical Doppler frequency-shift equation (Δf = 2 * f0 * v * cos(θ) / c) using the standard BART convention (Blue Away, Red Toward transducer at the apex):\n'
        '• Diastolic Mitral/Tricuspid Inflow: Directed toward the ventricular apex -> High-intensity RED jet.\n'
        '• Systolic LVOT/Aortic & RVOT/Pulmonic Ejection: Directed superiorly away from the apex -> High-velocity BLUE jet.\n'
        '• Nyquist Limit Aliasing: High Reynolds-number (Re > 2000) stenotic or regurgitant jets exceed the Nyquist velocity limit, producing a turbulent yellow/cyan mosaic.',
    normalReferenceRange:
        'Mitral E-Wave Velocity: 0.6–1.0 m/s | LVOT / Aortic Peak Velocity: 1.0–1.7 m/s | Tricuspid Inflow: 0.3–0.7 m/s',
    clinicalBoardPearl:
        'In severe Aortic Stenosis, peak continuous-wave Doppler jet velocity exceeds 4.0 m/s, corresponding to a mean transvalvular pressure gradient > 40 mmHg via the simplified Bernoulli equation (ΔP = 4v²).',
    howToInteract:
        'Observe the alternation between red diastolic ventricular filling jets and blue systolic outflow tract ejection jets synchronized with the heartbeat.',
  ),

  // ── 2. ANATOMICAL & VASCULAR STRUCTURES (INCOMING vs OUTGOING) ────────────
  'struct_venous_inflow': CardiacInfoTopic(
    id: 'struct_venous_inflow',
    title: 'Incoming Systemic Venous Return (SVC, IVC & Coronary Sinus → RA)',
    category: 'INCOMING VENOUS CIRCULATION',
    accentColor: Color(0xFF38BDF8),
    plainLanguageSummary:
        'Three major blue venous pipes bring oxygen-depleted blood BACK INTO the Right Atrium of the heart: the Superior Vena Cava (from head/arms), Inferior Vena Cava (from lower body), and Coronary Sinus (from the heart muscle itself).',
    advancedMechanism:
        'Venous return to the Right Atrium (RA) is driven by the pressure gradient between Mean Systemic Filling Pressure (Psf ~ 7 mmHg) and Right Atrial Pressure (RAP / CVP ~ 2–6 mmHg). The RA pressure waveform exhibits 3 characteristic peaks and 2 descents:\n'
        '• a-wave: Atrial contraction (end-diastole, after P-wave).\n'
        '• c-wave: Bulging of closed tricuspid valve into RA during early isovolumetric RV contraction.\n'
        '• x-descent: Atrial relaxation and downward pulling of the tricuspid annulus.\n'
        '• v-wave: Passive venous filling of RA from SVC/IVC/CS against a closed tricuspid valve.\n'
        '• y-descent: Rapid RA emptying into RV when the tricuspid valve opens in early diastole.',
    normalReferenceRange:
        'Central Venous Pressure (CVP / RAP): 2–6 mmHg | Mixed Venous O2 Sat (SvO2): 70–75% | Coronary Sinus O2 Sat (ScsO2): ~30%',
    clinicalBoardPearl:
        'Loss of the x-descent with giant c-v fusion waves on the jugular venous pulse (JVP) is pathognomonic for Tricuspid Regurgitation, while absent a-waves indicate Atrial Fibrillation.',
    howToInteract:
        'Select "Vessels" or "Blood Flow" mode to watch cyan-blue venous particles stream down the SVC, up the IVC, and around the Coronary Sinus into the Right Atrium.',
  ),
  'struct_pulmonary_inflow': CardiacInfoTopic(
    id: 'struct_pulmonary_inflow',
    title: 'Incoming Pulmonary Venous Return (4 Pulmonary Veins → LA)',
    category: 'INCOMING OXYGENATED CIRCULATION',
    accentColor: Color(0xFFF43F5E),
    plainLanguageSummary:
        'Four pulmonary veins (two from the left lung, two from the right lung) bring freshly oxygenated bright-red blood BACK INTO the Left Atrium of the heart.',
    advancedMechanism:
        'The Left Superior, Left Inferior, Right Superior, and Right Inferior Pulmonary Veins are the ONLY veins in the adult body that carry oxygenated blood (SaO2 ~ 98%, PO2 ~ 100 mmHg). They enter the smooth posterior wall of the Left Atrium without valves. Left Atrial pressure (measured clinically via Pulmonary Capillary Wedge Pressure, PCWP) reflects LV preload.',
    normalReferenceRange:
        'Left Atrial Pressure / PCWP: 6–12 mmHg | Pulmonary Venous O2 Sat: 97–100% | Pulmonary Venous S/D Ratio: > 1.0',
    clinicalBoardPearl:
        'The muscular sleeves extending from the Left Atrium into the ostia of the 4 Pulmonary Veins are the primary ectopic trigger site (>90%) for paroxysmal Atrial Fibrillation, targeted by circumferential Pulmonary Vein Isolation (PVI) catheter ablation.',
    howToInteract:
        'Rotate the 3D heart horizontally to inspect the posterior Left Atrium where the 4 red pulmonary veins enter and fill the LA/LV.',
  ),
  'struct_aortic_outflow': CardiacInfoTopic(
    id: 'struct_aortic_outflow',
    title: 'Outgoing Systemic & Pulmonary Arterial Outflow (Aorta & PA)',
    category: 'OUTGOING ARTERIAL CIRCULATION',
    accentColor: Color(0xFFEF4444),
    plainLanguageSummary:
        'The two massive outgoing arterial trunks at the top of the heart: the Aorta pumps oxygen-rich red blood out of the Left Ventricle to the entire body, while the Pulmonary Trunk pumps oxygen-poor blue blood out of the Right Ventricle to the lungs.',
    advancedMechanism:
        '• Ascending Aorta & Arch: Begins at the aortic annulus with the 3 Sinuses of Valsalva (Left Coronary, Right Coronary, and Non-Coronary sinus). Elastic Windkessel recoil of the aortic wall converts pulsatile LV ejection (120/80 mmHg) into continuous downstream organ and diastolic coronary perfusion. Gives off the Brachiocephalic Trunk, Left Common Carotid, and Left Subclavian arteries.\n'
        '• Pulmonary Trunk: Arises anteriorly from the RV infundibulum (conus arteriosus), courses superiorly and posteriorly beneath the aortic arch, and bifurcates into Right and Left Pulmonary Arteries (25/10 mmHg).',
    normalReferenceRange:
        'Aortic Pressure: 120/80 mmHg (MAP ~ 93 mmHg) | Pulmonary Artery Pressure: 25/10 mmHg (Mean PAP < 20 mmHg)',
    clinicalBoardPearl:
        'During embryonic development, the truncus arteriosus undergoes a 180° spiral division by the aorticopulmonary septum (driven by neural crest cells); failure to spiral results in d-Transposition of the Great Arteries (Aorta anterior and to the right of PA).',
    howToInteract:
        'Watch the systolic surge of red particles up the Ascending Aorta and blue particles up the Pulmonary Trunk following each QRS spike.',
  ),
  'struct_coronary_tree': CardiacInfoTopic(
    id: 'struct_coronary_tree',
    title: 'Epicardial Coronary Arterial Tree (LM, LAD, LCx, RCA)',
    category: 'CORONARY ARTERIAL CIRCULATION',
    accentColor: Color(0xFFFF5252),
    plainLanguageSummary:
        'The heart’s own dedicated fuel lines branching right off the base of the aorta. The Left Main splits into the LAD ("Widowmaker" down the front) and LCx (wrapping left), while the RCA wraps around the right side.',
    advancedMechanism:
        '• Left Main (LM): Originates from the Left Sinus of Valsalva (length 10–15 mm) and bifurcates into LAD and LCx.\n'
        '• Left Anterior Descending (LAD): Courses in the anterior interventricular groove to the apex, giving off Septal Perforators (supplying anterior 2/3 of IV septum & bundle branches) and Diagonal branches (D1, D2 supplying anterior LV wall).\n'
        '• Left Circumflex (LCx): Courses in the left atrioventricular groove, giving off Obtuse Marginal (OM1, OM2) branches to the lateral LV wall.\n'
        '• Right Coronary Artery (RCA): Originates from the Right Sinus of Valsalva, courses in the right AV groove, supplying the SA node (60%), RV free wall (Acute Marginal), AV node (90%), and—in 85% Right-Dominant hearts—the Posterior Descending Artery (PDA).',
    normalReferenceRange:
        'FFR: > 0.80 (Normal ~ 0.96–1.00) | iFR: > 0.89 | TIMI Grade: TIMI 3 ( brisk complete antegrade filling)',
    clinicalBoardPearl:
        'Left Main stenosis > 50% or proximal 3-vessel disease (LAD + LCx + RCA) with reduced LVEF or diabetes carries a Class I indication for Coronary Artery Bypass Grafting (CABG) using the Left Internal Mammary Artery (LIMA -> LAD).',
    howToInteract:
        'Switch between Right-Dominant, Left-Dominant, and Co-Dominant bars to watch the PDA dynamically re-route between the RCA and LCx.',
  ),

  // ── 3. SCENARIOS & DOMINANCE ──────────────────────────────────────────────
  'section_scenarios': CardiacInfoTopic(
    id: 'section_scenarios',
    title: 'Clinical Scenarios & Coronary Pathology Presets',
    category: 'CLINICAL PATHOLOGY SIMULATION',
    accentColor: Color(0xFF00E5FF),
    plainLanguageSummary:
        'Lets you switch the virtual patient between a healthy heart and three classic life-threatening cardiac emergencies seen in the hospital Cath Lab.',
    advancedMechanism:
        'Dynamically reconfigures the 0D–1D coupled Navier-Stokes hemodynamics solver, 3D plaque geometry, fluoroscopic contrast advection cutoff, and 12-lead ischemic ST-segment vector:\n'
        '1. Normal Coronary Circulation: Patent vessels (0% stenosis, FFR 0.98, TIMI 3, BP 120/80 mmHg).\n'
        '2. Acute Anterior STEMI: 95% proximal LAD atherothrombotic occlusion -> FFR drops to 0.42, ST elevation +4.5 mm in V1–V4, reciprocal depression in II/III/aVF, anterior/apical akinesis.\n'
        '3. Acute Inferior MI: 100% mid-RCA occlusion -> TIMI 0 cutoff, ischemic sinus bradycardia (52 bpm), ST elevation +3.2 mm in II, III, aVF.\n'
        '4. Critical Left Main Stenosis & Catheter Damping: 85% ostial LM lesion wedged by the catheter tip -> severe pressure ventricularization (85/35 mmHg) and loss of dicrotic notch.',
    normalReferenceRange:
        'Door-to-Balloon (D2B) Target in STEMI: <= 90 minutes | Fibrinolysis Target (if non-PCI center): <= 30 minutes',
    clinicalBoardPearl:
        'In Inferior MI, ST elevation in Lead III > Lead II strongly predicts an RCA culprit lesion (because Lead III’s +120° vector points directly rightward/inferiorly), whereas ST elevation in II >= III suggests a Left Circumflex (LCx) culprit.',
    howToInteract:
        'Click any scenario chip to immediately update the 3D Heart, X-Ray Fluoroscopy, IVUS/OCT cross-section, and ECG/Pressure telemetry.',
  ),
  'section_dominance': CardiacInfoTopic(
    id: 'section_dominance',
    title: 'Coronary Arterial Dominance (PDA & AV Node Origin)',
    category: 'ANATOMICAL VARIATION',
    accentColor: Color(0xFF00E5FF),
    plainLanguageSummary:
        'Determines which main artery—the Right Coronary (RCA), the Left Circumflex (LCx), or both—feeds the bottom back wall of the heart via the Posterior Descending Artery (PDA).',
    advancedMechanism:
        'Anatomical dominance is defined strictly by the vessel that gives rise to the Posterior Descending Artery (PDA) supplying the inferior interventricular septum and AV node:\n'
        '• Right-Dominant (~85% of humans): PDA arises from the distal RCA at the cardiac crux.\n'
        '• Left-Dominant (~8% of humans): PDA arises from the distal LCx; the RCA is small and terminates before the crux.\n'
        '• Co-Dominant / Balanced (~7% of humans): Dual posterior septal perfusion from both distal RCA and LCx.',
    normalReferenceRange:
        'Population Distribution: 85% Right-Dominant | 8% Left-Dominant | 7% Co-Dominant',
    clinicalBoardPearl:
        'Even though the Left Coronary Artery supplies ~70% of total LV myocardial mass in almost everyone, "Right Dominance" refers ONLY to the origin of the PDA. In a Left-Dominant patient, a Left Main occlusion is almost universally fatal because the entire LV and septum lose blood supply simultaneously.',
    howToInteract:
        'Toggle the 3 dominance chips and watch the posterior vessel geometry update in both the 3D Heart and X-Ray Fluoroscopy viewports.',
  ),

  // ── 4. INTERVENTIONAL TOOLKIT & DEVICES ───────────────────────────────────
  'section_toolkit': CardiacInfoTopic(
    id: 'section_toolkit',
    title: 'Interventional Cath Lab Toolkit & Physiology Suite',
    category: 'INTERVENTIONAL CARDIOLOGY',
    accentColor: Color(0xFF10B981),
    plainLanguageSummary:
        'Your virtual Cath Lab instrument tray: choose specialized guide catheters, insert a microscopic pressure-sensing wire to measure blockage severity (FFR/iFR), drill away hard calcium with a diamond burr, or turn on an aortic balloon pump.',
    advancedMechanism:
        'Models real-time catheter-vessel mechanics and intracoronary physiology:\n'
        '• Guide Catheters (JL4, JR4, EBU 3.5, AL1): Provide coaxial lumen access for contrast injection, guidewires, and stent delivery.\n'
        '• Pressure Sensor Guidewire (FFR/iFR): Measures distal coronary pressure (Pd) relative to aortic root pressure (Pa).\n'
        '• Rotational Atherectomy Burr (160,000 RPM): Elliptical diamond-coated burr that pulverizes inelastic calcified rings into <5 µm microparticles cleared by the reticuloendothelial system.\n'
        '• Intra-Aortic Balloon Pump (IABP 1:1): Counterpulsation balloon in the descending thoracic aorta.',
    normalReferenceRange:
        'FFR Ischemic Threshold: <= 0.80 | iFR Ischemic Threshold: <= 0.89 | Activated Clotting Time (ACT) for PCI: 250–300 s',
    clinicalBoardPearl:
        'Per the landmark FAME and DEFER trials, deferring stenting in angiographically intermediate lesions with FFR > 0.80 (or iFR > 0.89 per DEFINE-FLAIR / iFR-SWEDEHEART) reduces MACE compared to routine angiography-guided stenting.',
    howToInteract:
        'Click "PressureWire X (FFR)" to overlay the yellow distal coronary pressure (Pd) curve on the monitor, or click "Rotablator Burr" and "Virtual IVUS / OCT" to inspect plaque modification.',
  ),
  'tool_catheters': CardiacInfoTopic(
    id: 'tool_catheters',
    title: 'Coronary Guide Catheters (JL4, JR4, EBU 3.5, AL1)',
    category: 'INTERVENTIONAL CATHETERS',
    accentColor: Color(0xFF00E5FF),
    plainLanguageSummary:
        'Pre-shaped flexible tubes threaded from the wrist (radial artery) or groin (femoral artery) up to the base of the aorta to hook into the left or right coronary artery opening.',
    advancedMechanism:
        '• JL4 (Judkins Left 4.0 cm curve): Primary diagnostic/interventional curve engineered to drop coaxially into the Left Main ostium without manipulation.\n'
        '• JR4 (Judkins Right 4.0 cm curve): Requires a 60–90° clockwise torque rotation in the right sinus of Valsalva to engage the anterior-rightward RCA ostium.\n'
        '• EBU 3.5 (Extra Backup 3.5): Contralateral aortic wall support catheter providing high passive backup force for complex LAD/LCx stent delivery.\n'
        '• AL1 (Amplatz Left 1): Aggressive deep-seating curve for anomalous ostia or chronic total occlusions (CTOs), carrying a higher risk of ostial dissection or pressure damping.',
    normalReferenceRange:
        'Diagnostic Catheter Size: 5F or 6F (1 French = 0.33 mm outer diameter) | Guide Catheter Size: 6F or 7F',
    clinicalBoardPearl:
        'Deep-seating an aggressive AL1 guide catheter into a stenotic Left Main or RCA ostium causes immediate "pressure ventricularization" (damping of Pa with loss of the dicrotic notch)—requiring immediate catheter retraction.',
    howToInteract:
        'Select different guide catheters and watch how AL1 in a critical Left Main scenario triggers hemodynamic pressure damping on the monitor.',
  ),
  'tool_pressure_wire': CardiacInfoTopic(
    id: 'tool_pressure_wire',
    title: 'Coronary Pressure Sensor Guidewire (FFR & iFR Physiology)',
    category: 'INTRACORONARY PHYSIOLOGY',
    accentColor: Color(0xFFFFEB3B),
    plainLanguageSummary:
        'A hair-thin 0.014-inch wire with a microscopic pressure sensor at its tip that crosses the blockage to measure how much blood pressure is lost across the narrowing.',
    advancedMechanism:
        '• Fractional Flow Reserve (FFR = Pd / Pa during maximal hyperemia): Under IV/IC Adenosine (which binds A2A receptors to maximally dilate coronary microvasculature and eliminate microvascular resistance), coronary blood flow becomes linearly proportional to perfusion pressure. An FFR of 0.72 means the stenosis restricts maximal myocardial blood flow to 72% of normal.\n'
        '• Instantaneous Wave-Free Ratio (iFR = Pd / Pa during the diastolic Wave-Free Window, phi = 0.72–0.88): Measures resting pressure gradient during mid-to-late diastole when microvascular resistance is naturally constant and minimal—eliminating the need for adenosine.',
    normalReferenceRange:
        'Normal FFR: 0.95–1.00 | Hemodynamically Significant Ischemia: FFR <= 0.80 or iFR <= 0.89',
    clinicalBoardPearl:
        'When you activate the PressureWire, look at the bottom pressure monitor: the yellow Distal Coronary Pressure (Pd) curve separates from the red Aortic Pressure (Pa) curve primarily during DIASTOLE because left coronary flow surges during diastole!',
    howToInteract:
        'Toggle "PressureWire X (FFR)" on to display the live yellow Pd trace and Pd/Pa ischemic gradient on the bottom oscilloscope.',
  ),
  'tool_rotablator': CardiacInfoTopic(
    id: 'tool_rotablator',
    title: 'Rotational Atherectomy Burr (160,000 RPM Calcific Modification)',
    category: 'PLAQUE MODIFICATION',
    accentColor: Color(0xFF38BDF8),
    plainLanguageSummary:
        'A microscopic diamond-encrusted football-shaped drill spinning at 160,000 RPM that sands away rock-hard calcium deposits so a balloon and stent can expand properly.',
    advancedMechanism:
        'Operates on two biophysical principles:\n'
        '1. Differential Cutting: Elastic soft tissue (healthy arterial wall) deflects away from the spinning 20–30 µm diamond micro-crystals, whereas inelastic rigid calcified plaque cannot deflect and is selectively ablated into <5 µm microparticles (smaller than red blood cells).\n'
        '2. Orthogonal Displacement of Friction: At >140,000 RPM, longitudinal friction vector is eliminated, allowing the burr to advance smoothly using a gentle "pecking" motion (<15 seconds per run).',
    normalReferenceRange:
        'Rotational Speed: 140,000–160,000 RPM | Optimal Burr-to-Artery Ratio: 0.5–0.6 | Deceleration Limit: < 5,000 RPM drop',
    clinicalBoardPearl:
        'Attempting to deploy a stent inside a 270°–360° "napkin-ring" calcified lesion without prior atherectomy or intravascular lithotripsy (IVL) results in stent under-expansion—the #1 mechanical predictor of acute stent thrombosis and in-stent restenosis.',
    howToInteract:
        'Open "Virtual IVUS / OCT" to view the calcific ring, then click "Rotablator Burr" to ablate the calcium before deploying the PCI stent.',
  ),
  'tool_iabp': CardiacInfoTopic(
    id: 'tool_iabp',
    title: 'Intra-Aortic Balloon Pump (IABP 1:1 Counterpulsation)',
    category: 'MECHANICAL CIRCULATORY SUPPORT',
    accentColor: Color(0xFFA78BFA),
    plainLanguageSummary:
        'A helium-filled sausage-shaped balloon placed in the descending aorta that inflates when the heart relaxes (pushing extra blood into the coronary arteries) and deflates right before the heart squeezes (making it easier for the heart to pump).',
    advancedMechanism:
        'Synchronized to the Lead II ECG R-wave or arterial pressure curve:\n'
        '• Inflation at the Dicrotic Notch (Middle of T-Wave / Aortic Valve Closure, phi = 0.57): Displaces 40 mL of blood proximally and distally, creating a suprasystolic Diastolic Augmentation wave that boosts Coronary Perfusion Pressure (CPP).\n'
        '• Rapid Deflation in Late Diastole (Just prior to QRS R-Wave / Isometric Contraction): Creates a presystolic pressure vacuum ("assisted end-diastolic pressure") that reduces LV afterload, decreases LV wall tension, and lowers myocardial oxygen consumption (MVO2).',
    normalReferenceRange:
        'Helium Shuttle Gas Volume: 30–50 mL | Trigger: ECG R-Wave | Contraindication: Moderate-to-Severe Aortic Regurgitation or Aortic Dissection',
    clinicalBoardPearl:
        'IABP is ABSOLUTELY CONTRAINDICATED in severe Aortic Regurgitation (AR) because diastolic balloon inflation forces blood backward through the incompetent aortic valve directly into the Left Ventricle, worsening acute LV volume overload!',
    howToInteract:
        'Toggle "IABP 1:1" on and look at the red Aortic Pressure (Pa) curve on the monitor to see the classic twin-peak "Diastolic Augmentation Bump" right after the dicrotic notch.',
  ),
  'tool_ivus_oct': CardiacInfoTopic(
    id: 'tool_ivus_oct',
    title: 'Virtual IVUS (40 MHz) & OCT (10 µm Near-Infrared) Pullback',
    category: 'INTRAVASCULAR IMAGING',
    accentColor: Color(0xFF00E5FF),
    plainLanguageSummary:
        'Switches the right-hand screen to a 360° "inside-the-artery" camera so you can see the microscopic plaque buildup, thin fibrous cap, calcium rings, and expanded stent struts.',
    advancedMechanism:
        'Compares the two clinical gold-standard intravascular imaging modalities:\n'
        '• OCT (Optical Coherence Tomography, ~1300 nm near-infrared light): Ultra-high axial resolution (10–15 µm, 10x sharper than IVUS) capable of measuring Thin-Cap Fibroatheroma (TCFA < 65 µm), macrophage infiltration, thrombus, and individual stent strut malapposition, but requires contrast flushing to clear red blood cells and has shallower tissue penetration (1–2 mm).\n'
        '• IVUS (Intravascular Ultrasound, 20–60 MHz piezoelectric catheter): Deeper tissue penetration (4–8 mm) allowing visualization of the entire External Elastic Membrane (EEM) and total plaque burden without contrast flushing, though dense calcium causes acoustic shadowing.',
    normalReferenceRange:
        'Non-LM Minimum Lumen Area (MLA) Threshold: > 4.0 mm² | Left Main MLA Threshold: > 6.0 mm² | Vulnerable TCFA Cap: < 65 µm',
    clinicalBoardPearl:
        'Large randomized trials (ULTIMATE, ILUMIEN IV, RENOVATE-COMPLEX-PCI) proved that IVUS/OCT-guided PCI significantly reduces target-vessel failure and stent thrombosis compared to angiography-guided PCI alone.',
    howToInteract:
        'Click "Virtual IVUS / OCT", toggle between OCT and IVUS tabs, and drag the 0–30 mm Pullback slider across the culprit lesion.',
  ),

  // ── 5. ALARA RADIATION & CONTRAST STEWARDSHIP ─────────────────────────────
  'section_alara': CardiacInfoTopic(
    id: 'section_alara',
    title: 'ALARA Radiation Safety & Contrast Nephrotoxicity Stewardship',
    category: 'PATIENT & OPERATOR SAFETY',
    accentColor: Color(0xFF10B981),
    plainLanguageSummary:
        'Tracks two real-world hospital safety limits during a Cath Lab procedure: X-ray radiation dose (to protect skin and organs) and iodine contrast dye volume (to protect the kidneys).',
    advancedMechanism:
        '• Fluo Time & Frame Rate: Modern pulsed fluoroscopy runs at 7.5–15 frames/sec (FPS) to minimize ionizing X-ray exposure.\n'
        '• Air Kerma (mGy, cumulative dose at interventional reference point): Measures deterministic skin injury risk. Thresholds: >2,000 mGy (2 Gy) triggers transient erythema; >5,000 mGy (5 Gy) is a sentinel event requiring patient dermatological follow-up for radiation skin necrosis.\n'
        '• DAP (Dose Area Product, Gy·cm²): Product of radiation dose and X-ray field area; correlates with stochastic long-term malignancy risk.\n'
        '• Contrast Stewardship (Max Volume <= 3 x eGFR): Iodinated contrast causes medullary vasoconstriction and direct tubular reactive oxygen species (ROS) injury. Keeping total contrast volume below 3x the patient’s estimated GFR (mL/min/1.73m²) prevents Contrast-Induced Acute Kidney Injury (CI-AKI).',
    normalReferenceRange:
        'Diagnostic Air Kerma: < 500 mGy | Skin Injury Alert: > 2,000 mGy | Safe Contrast Volume: < 3 x eGFR (or < 195 mL at eGFR 65)',
    clinicalBoardPearl:
        'The single most effective proven prophylaxis against Contrast-Induced Nephropathy (CIN / CI-AKI) in high-risk CKD patients is peri-procedural intravenous isotonic crystalloid hydration (0.9% Normal Saline at 1–1.5 mL/kg/hr) plus minimizing contrast volume.',
    howToInteract:
        'Notice how each click on "Inject Contrast Dye" adds +15 mL to the cumulative contrast tracker and triggers a red warning if the 3 x eGFR limit is exceeded.',
  ),

  // ── 6. 120-FRAME FSI BIOMECHANICAL ENGINE ─────────────────────────────────
  'section_fsi': CardiacInfoTopic(
    id: 'section_fsi',
    title: '120-Frame Fluid-Structure Interaction (FSI) Biomechanics Engine',
    category: 'COMPUTATIONAL BIOPHYSICS',
    accentColor: Color(0xFF38BDF8),
    plainLanguageSummary:
        'Controls the high-precision 120-frame-per-heartbeat physics engine, allowing you to pause, step frame-by-frame, or play in slow motion (0.25x) to inspect every phase of the cardiac cycle.',
    advancedMechanism:
        'Couples 3D anisotropic hyperelastic myocardial mechanics (Holzapfel-Ogden constitutive law) with pulsatile non-Newtonian blood hemodynamics (Carreau-Yasuda viscosity model) across 120 discrete time-steps per R–R interval:\n'
        '• Frames 010–024 (phi = 0.08–0.20): Atrial Systole (P-Wave booster kick contributing ~20% of ventricular filling).\n'
        '• Frames 030–039 (phi = 0.25–0.33): Isovolumetric Ventricular Contraction (QRS peak -> Mitral/Tricuspid closed, Aortic/Pulmonic closed).\n'
        '• Frames 040–067 (phi = 0.33–0.56): Rapid & Reduced Ventricular Ejection (Aortic/Pulmonic valves open, peak Pa 120 mmHg).\n'
        '• Frame 068 (phi = 0.57): Dicrotic Notch Incisura (Aortic valve closure at end of T-wave) & onset of Diastolic Coronary Perfusion surge.\n'
        '• Frames 086–106 (phi = 0.72–0.88): Diastolic Wave-Free Window (optimal iFR measurement phase).',
    normalReferenceRange:
        'Cardiac Cycle Duration at 72 bpm: 833 ms (Systole ~ 280 ms, Diastole ~ 553 ms) | Resolution: 6.9 ms per FSI frame',
    clinicalBoardPearl:
        'When heart rate increases (tachycardia), DIASTOLE shortens disproportionately more than systole—severely reducing the time available for Left Coronary Artery perfusion and precipitating demand ischemia in patients with CAD.',
    howToInteract:
        'Click the Pause button or select 0.25x speed, then drag the scrub slider to inspect exact electro-mechanical alignment at any millisecond of the cycle.',
  ),

  // ── 7. FLUOROSCOPY & C-ARM GANTRY ─────────────────────────────────────────
  'viewport_fluoroscopy': CardiacInfoTopic(
    id: 'viewport_fluoroscopy',
    title: 'Real-Time X-Ray Fluoroscopy & Contrast Advection Viewport',
    category: 'X-RAY ANGIOGRAPHY',
    accentColor: Color(0xFF10B981),
    plainLanguageSummary:
        'Simulates the live hospital X-ray monitor. Because blood and arteries are invisible on plain X-rays, injecting iodine contrast dye temporarily turns the inside of the coronary arteries dark grey/white so blockages become visible.',
    advancedMechanism:
        'Solves the Beer-Lambert X-ray attenuation integral (I = I0 * exp(-∫ μ(x) dx)) along the C-arm source-to-image-detector vector:\n'
        '• Iodinated Contrast Medium (Iohexol / Iodixanol, Atomic Number Z = 53): Exhibits a K-shell photoelectric absorption edge at 33.2 keV, perfectly matched to the 65–70 kVp bremsstrahlung X-ray spectrum.\n'
        '• Pulsatile Advection-Diffusion: Contrast bolus propagates distally at TIMI grade velocity, revealing luminal filling defects, subtotal ulcerated plaques, or complete TIMI 0 cutoffs.',
    normalReferenceRange:
        'X-Ray Tube Potential: 65–80 kVp | Frame Rate: 7.5–15 FPS | TIMI Flow Grades: 0 (No flow), 1 (Penetration without perfusion), 2 (Partial/slow), 3 (Normal brisk flow)',
    clinicalBoardPearl:
        'Angiography is only a 2D "lumenogram" (shadow of the inside channel). Because atherosclerotic plaques initially remodel outward into the arterial wall (Glagov positive remodeling), a vessel can harbor a 40% plaque burden before showing any narrowing on angiography!',
    howToInteract:
        'Click "Inject Contrast Dye" to opacify the coronary tree, and click "Simulate PCI Stent" during STEMI scenarios to deploy a metallic stent and restore TIMI 3 flow.',
  ),
  'viewport_c_arm': CardiacInfoTopic(
    id: 'viewport_c_arm',
    title: '3D C-Arm Gantry Digital Twin (LAO/RAO & Cranial/Caudal Angles)',
    category: 'GANTRY GEOMETRY',
    accentColor: Color(0xFF00E5FF),
    plainLanguageSummary:
        'Shows the C-shaped X-ray camera rotating around the patient table. Changing the angle lets you look at the curved heart arteries from different directions so overlapping branches don’t hide a blockage.',
    advancedMechanism:
        'The flat-panel image detector (top of the C-arm) defines the projection name:\n'
        '• LAO (Left Anterior Oblique, +angle): Detector positioned over the patient’s LEFT chest -> separates the LAD (left on screen) from the LCx (right on screen) and displays the RCA in its classic C-shape.\n'
        '• RAO (Right Anterior Oblique, -angle): Detector positioned over the patient’s RIGHT chest -> elongates the LAD and AV groove.\n'
        '• Cranial (+angle): Detector tilted toward the patient’s HEAD -> opens up mid/distal LAD and diagonal bifurcations.\n'
        '• Caudal (-angle): Detector tilted toward the patient’s FEET -> opens up the Left Main bifurcation and proximal LAD/LCx ("Spider View" = LAO/RAO Caudal).',
    normalReferenceRange:
        'LAO/RAO Range: -90° to +90° | Cranial/Caudal Range: -45° to +45° | Standard Diagnostic Series: >= 2 orthogonal views per vessel',
    clinicalBoardPearl:
        'Because coronary plaques are frequently eccentric (crescent-shaped rather than circular), every coronary segment MUST be imaged in at least two orthogonal (90° apart) projections so a slit-like stenosis is never missed en-face!',
    howToInteract:
        'Drag the LAO/RAO and CRAN/CAUD sliders or click preset buttons like "LAO Cranial (LAD Profiler)" and "RAO Caudal (Spider View)" to rotate the fluoroscopy view live.',
  ),

  // ── 8. CATH LAB TELEMETRY, ECG & HEMODYNAMICS ─────────────────────────────
  'viewport_telemetry': CardiacInfoTopic(
    id: 'viewport_telemetry',
    title: 'Cath Lab Oscilloscope: Synchronized Lead II ECG & Dual Pa/Pd Pressure',
    category: 'HEMODYNAMIC & ECG TELEMETRY',
    accentColor: Color(0xFF00E676),
    plainLanguageSummary:
        'The hospital bedside monitor showing the heart’s electrical wave on top (green ECG) and the actual blood pressure pulse inside the aorta and coronary artery on the bottom (red Pa and yellow Pd).',
    advancedMechanism:
        'Enforces strict physiological Wiggers Electro-Mechanical Phase Lock on a calibrated 25 mm/s | 10 mm/mV grid with a 1 mV calibration pulse and sweeping phosphor erase-bar:\n'
        '1. Electrical Depolarization First (Green ECG): P-wave (atrial depolarization, +0.15 mV at phi = 0.125) -> PR delay -> razor-sharp QRS spike (ventricular depolarization, R-peak +1.25 mV at phi = 0.270) -> ST segment & T-wave (repolarization, peak at phi = 0.460, end at phi = 0.560).\n'
        '2. Mechanical Contraction Second (Red Pa Trace): At the R-wave peak (phi = 0.270), the LV is just beginning isovolumetric contraction against a closed aortic valve, so Aortic Pressure (Pa) sits at its diastolic nadir (80 mmHg). Approximately 60–80 ms later (phi = 0.330), LV pressure exceeds 80 mmHg, the aortic valve opens, and the steep systolic Pa upstroke climbs to 120 mmHg (phi = 0.440).\n'
        '3. Dicrotic Notch Alignment: Right at the end of the T-wave (phi = 0.570), ventricular relaxation causes the aortic valve to snap shut, creating the crisp Dicrotic Notch incisura followed by exponential Windkessel diastolic runoff.',
    normalReferenceRange:
        'Calibration: 25 mm/s (1 small box = 40 ms, 1 large box = 200 ms) | 10 mm/mV | Normal BP: 120/80 mmHg (MAP 93 mmHg)',
    clinicalBoardPearl:
        'Electrical activity ALWAYS precedes mechanical pressure generation (Excitation-Contraction Coupling via L-type Ca2+ influx triggering ryanodine receptor RyR2 Ca2+-induced Ca2+ release from the sarcoplasmic reticulum). If you see QRS complexes with no arterial pressure pulse, that is Pulseless Electrical Activity (PEA) arrest!',
    howToInteract:
        'Switch between 12-Lead Territory tabs (Lead II, V1–V4 Anterior, II/III/aVF Inferior, I/aVL Lateral) during STEMI to observe localized ST elevation vs. reciprocal ST depression.',
  ),
  'metric_wss': CardiacInfoTopic(
    id: 'metric_wss',
    title: 'Endothelial Wall Shear Stress (WSS, dyn/cm²)',
    category: 'BIOMECHANICAL TELEMETRY',
    accentColor: Color(0xFF38BDF8),
    plainLanguageSummary:
        'Measures the frictional rubbing force of flowing blood against the inner lining (endothelium) of the coronary artery wall.',
    advancedMechanism:
        'Computed from the radial velocity gradient at the vessel wall: τ_w = μ * (∂u / ∂r)_{r=R} ≈ (4 * μ * Q) / (π * r³).\n'
        '• Physiological Laminar WSS (15–30 dyn/cm²): Stimulates endothelial mechanoreceptors (PECAM-1 / VEGFR2) to upregulate eNOS (endothelial Nitric Oxide Synthase) and KLF2, maintaining an anti-inflammatory, antithrombotic vessel wall.\n'
        '• Low / Oscillatory WSS (< 4 dyn/cm² at outer bifurcation walls): Promotes LDL cholesterol infiltration, VCAM-1 expression, and atherosclerotic plaque initiation.\n'
        '• Pathologically High Stenotic Throat WSS (> 70–100 dyn/cm²): Physically strips endothelial cells, activates platelet vWF unfolding, and triggers fibrous cap rupture (Acute STEMI).',
    normalReferenceRange:
        'Healthy Epicardial Coronary WSS: 15–30 dyn/cm² | Atherogenic Low WSS: < 4 dyn/cm² | Plaque Rupture High WSS: > 70 dyn/cm²',
    clinicalBoardPearl:
        'Because WSS is inversely proportional to the CUBE of vessel radius (1/r³), a 50% diameter reduction (radius halved) increases local throat shear stress by 8-fold (800%)!',
    howToInteract:
        'Watch WSS spike above 90 dyn/cm² in the Acute Anterior STEMI scenario and return to a healthy 18 dyn/cm² immediately after deploying the PCI stent.',
  ),

  // ── 9. TOP APPBAR FEATURES (PROCTOR, OSCE, DRUG MOA, GNN, LEGAL) ──────────
  'feature_gnn': CardiacInfoTopic(
    id: 'feature_gnn',
    title: 'CardioNephroGNN: Multi-Target Drug Affinity & hERG Safety Screener',
    category: 'IN-SILICO AI PHARMACOLOGY',
    accentColor: Color(0xFFA78BFA),
    plainLanguageSummary:
        'An independent Graph Neural Network trained on wet-lab bioassay data (ChEMBL & PubChem) that reads a drug molecule’s chemical structure (SMILES) and predicts both its therapeutic heart/kidney potency and its risk of causing dangerous heart rhythm prolongation (hERG blockade).',
    advancedMechanism:
        'Uses an Attentive-FP / Message-Passing Graph Neural Network trained via scaffold splitting on Apple Silicon MPS across 5 cardiovascular & renal targets:\n'
        '• Therapeutic Targets: ACE (Angiotensin-Converting Enzyme), AGTR1 (AT1 Receptor), ADRB1 (β1-Adrenergic Receptor), and SLC5A2 (Renal SGLT2 Cotransporter).\n'
        '• Cardiotoxicity Target: hERG (KCNH2 / Kv11.1 Potassium Channel mediating the rapid delayed rectifier current IKr). Blockade of hERG delays Phase 3 ventricular repolarization, prolonging the QT interval on ECG and predisposing to Torsades de Pointes (TdP).',
    normalReferenceRange:
        'High Potency: pIC50 >= 7.0 (IC50 <= 100 nM) | Safe hERG Margin: hERG IC50 > 30x free therapeutic Cmax (pIC50 < 5.0)',
    clinicalBoardPearl:
        'Terfenadine (the first non-sedating antihistamine) was withdrawn from the market after causing fatal Torsades de Pointes when co-administered with CYP3A4 inhibitors (ketoconazole/erythromycin); its non-cardiotoxic active carboxylate metabolite is Fexofenadine!',
    howToInteract:
        'Click "CardioNephroGNN" in the top bar to screen benchmark drugs (Enalaprilat, Bisoprolol, Empagliflozin, Losartan, Amiodarone, Terfenadine) or paste any custom SMILES string.',
  ),
  'legal_samd_shield': CardiacInfoTopic(
    id: 'legal_samd_shield',
    title: 'Regulatory, SaMD, Malpractice & IP Legal Protection Shield',
    category: 'LEGAL & REGULATORY COMPLIANCE',
    accentColor: Color(0xFFFFB300),
    plainLanguageSummary:
        'Protects both users and the platform creator by establishing clear legal boundaries: Quantum Forge is strictly an academic, mathematical, and educational science simulator—never a medical device or clinical prescribing tool.',
    advancedMechanism:
        'Engineered in compliance with US FDA 21st Century Cures Act § 3060 (21 U.S.C. § 360j(o)(1)), EU Medical Device Regulation (MDR 2017/745 Article 2), HIPAA/GDPR Zero-PHI standards, and Nominative Fair-Use Doctrine:\n'
        '• Statutory Non-Device Classification: Software intended solely for medical education, physiological visualization, and theoretical computational chemistry is exempt from regulated Medical Device / SaMD classification.\n'
        '• Zero Patient Data (No PHI): All waveforms, 3D meshes, and scenarios are 100% synthetic mathematical equations.\n'
        '• No Clinical Reliance & Malpractice Waiver: Simulated drug regimens, stent interventions, and GNN predictions are pedagogical estimates and do not constitute medical advice.',
    normalReferenceRange:
        'Classification: Exempt Educational Simulation (Non-SaMD) | PHI Storage: 0 Bytes (100% Synthetic) | Clinical Use: Strictly Prohibited',
    clinicalBoardPearl:
        'Always verify real-world clinical decisions against official FDA/EMA package inserts, ACC/AHA/ESC clinical practice guidelines, and licensed attending physician judgment.',
    howToInteract:
        'Click "Legal & Regulatory Shield" at any time to view the complete 7-Pillar Legal Disclaimers, Trademark Non-Affiliation Notice, and Terms of Use.',
  ),
  'diag_echo_lab': CardiacInfoTopic(
    id: 'diag_echo_lab',
    title: 'Virtual 2D/3D Echocardiography, M-Mode & Color Flow Doppler Lab',
    category: 'CARDIAC DIAGNOSTIC WORKSTATION',
    accentColor: Color(0xFF00E5FF),
    plainLanguageSummary:
        'Simulates placing an ultrasound probe on the chest (TTE) or esophagus (TEE) to watch heart valves open and close in a fan-shaped ultrasound beam, measure pumping strength (LVEF%), and see turbulent blood leaks (Color Doppler).',
    advancedMechanism:
        'Models phased-array piezoelectric ultrasound sector imaging (2.5–5.0 MHz), M-Mode time-motion interrogation, Color Flow BART (Blue Away, Red Toward) autocorrelation, and Continuous-Wave (CW) spectral Doppler:\n'
        '• 4 Standard Acoustic Windows: Parasternal Long-Axis (PLAX), Parasternal Short-Axis (PSAX papillary level), Apical 4-Chamber (A4C), and Subcostal 4-Chamber.\n'
        '• Left Ventricular Ejection Fraction: LVEF = (EDV - ESV) / EDV × 100%. Distinguishes HFrEF (LVEF < 40%, dilated cavity, EPSS > 7 mm), HFpEF (LVEF >= 50%, concentric hypertrophy, E/A reversal), and HOCM (asymmetric septal hypertrophy + Systolic Anterior Motion [SAM] of the mitral valve).\n'
        '• Simplified Bernoulli Equation: ΔP = 4 × v_max² (e.g., Peak Aortic Jet Velocity v = 4.5 m/s yields a peak instantaneous gradient ΔP = 81 mmHg in Severe Aortic Stenosis).',
    normalReferenceRange:
        'LVEF: 55–70% | EPSS: < 7 mm | TAPSE: >= 17 mm | Mitral E/A Ratio: 0.8–2.0 | Peak AoV Velocity: 1.0–1.7 m/s (ΔP < 12 mmHg)',
    clinicalBoardPearl:
        'In Hypertrophic Obstructive Cardiomyopathy (HOCM), high-velocity LV outflow tract ejection creates a Venturi/drag effect that pulls the anterior mitral leaflet into the septum (SAM), causing dynamic LVOT obstruction and a late-peaking "dagger-shaped" CW Doppler envelope.',
    howToInteract:
        'Switch between PLAX, PSAX, A4C, and Subcostal acoustic windows, toggle Color Doppler On/Off, and switch hemodynamic phenotypes (Normal, HFrEF, HFpEF, Severe AS, Severe MR, HOCM).',
  ),
  'diag_auscultation_pcg': CardiacInfoTopic(
    id: 'diag_auscultation_pcg',
    title: 'Cardiac Auscultation, Phonocardiography (PCG) & Bedside Maneuvers',
    category: 'CARDIAC DIAGNOSTIC WORKSTATION',
    accentColor: Color(0xFF10B981),
    plainLanguageSummary:
        'Places a virtual stethoscope on the 4 chest listening posts so you can see (and hear) normal heart sounds (S1 "lub", S2 "dub"), extra gallop sounds (S3/S4), and valve murmurs, and test how bedside maneuvers change murmur loudness.',
    advancedMechanism:
        'Synchronizes acoustic heart sound envelopes with the Wiggers ECG and pressure cycle:\n'
        '• S1 (Mitral M1 + Tricuspid T1 closure): Occurs immediately after the QRS R-wave as ventricular pressure exceeds atrial pressure.\n'
        '• S2 (Aortic A2 + Pulmonic P2 closure): Occurs at the dicrotic notch (end of T-wave). Inspiration drops intrathoracic pressure, increasing venous return to the RV and delaying P2 (Physiologic Splitting). Secundum ASD causes Fixed Splitting; LBBB/Severe AS delays A2 causing Paradoxical Splitting.\n'
        '• S3 Gallop (Early Diastole): Rapid ventricular filling into a dilated, compliant LV (HFrEF / Mitral Regurgitation).\n'
        '• S4 Gallop (Late Diastole / Atrial Kick): Atrial contraction into a stiff, hypertrophied LV (HTN / Concentric LVH / HOCM).\n'
        '• Dynamic Maneuvers: Valsalva (Phase II) and Standing decrease preload (most murmurs softer, EXCEPT HOCM louder and MVP click earlier); Squatting increases preload & afterload; Isometric Handgrip increases afterload (intensifies AR, MR, VSD; softens AS and HOCM).',
    normalReferenceRange:
        'Aortic: R 2nd ICS | Pulmonic: L 2nd ICS | Tricuspid: L 4th ICS | Mitral (Apex): L 5th ICS Mid-Clavicular Line',
    clinicalBoardPearl:
        'USMLE Classic: Only two systolic pathology conditions get LOUDER with Valsalva strain or abrupt standing (which decrease LV end-diastolic volume): HOCM (septum moves closer to anterior mitral leaflet) and Mitral Valve Prolapse (click moves earlier, murmur lengthens).',
    howToInteract:
        'Select a precordial post (Aortic, Pulmonic, Tricuspid, Mitral), pick a murmur/sound profile, and click bedside maneuvers (Inspiration, Valsalva, Squatting, Handgrip) to watch real-time PCG amplitude modulation.',
  ),
  'diag_ep_arrhythmia': CardiacInfoTopic(
    id: 'diag_ep_arrhythmia',
    title: 'Electrophysiology (EP) Study, Arrhythmia Mapping, RF Ablation & Pacemaker Lab',
    category: 'CARDIAC DIAGNOSTIC WORKSTATION',
    accentColor: Color(0xFFFFD600),
    plainLanguageSummary:
        'Shows how electrical signals travel inside the heart using 4 internal recording catheters (HRA, His, CS, RVA), simulates dangerous heart rhythm disorders, and lets you burn away abnormal short-circuits (RF Ablation) or turn on a pacemaker.',
    advancedMechanism:
        'Models intracardiac electrograms (EGMs) alongside surface Lead II ECG and connects directly to CardioNephroGNN hERG (IKr) pharmacology:\n'
        '• Intracardiac Intervals: AH interval (AV nodal conduction, normal 50–120 ms, prolonged by Beta-blockers/CCBs/Adenosine) and HV interval (His-Purkinje conduction, normal 35–55 ms, prolonged by Class IA/IC Na+ channel blockers or infra-Hisian Mobitz II disease).\n'
        '• Arrhythmia Mechanisms: WPW Syndrome (Accessory Bundle of Kent bypassing AV node → short PR < 120 ms + slurred Delta wave), AVNRT (dual slow/fast AV nodal pathways), Atrial Flutter (cavotricuspid isthmus macro-reentry at 300 bpm sawtooth F-waves), Complete (3rd-Degree) AV Block (AV dissociation), and Torsades de Pointes (polymorphic VT triggered by Early Afterdepolarizations [EADs] from hERG K+ channel blockade).\n'
        '• Interventions: Radiofrequency (RF) Catheter Ablation (50–65°C thermal lesion eliminating Kent pathway or CTI) and Dual-Chamber DDD/VVI Pacemaker pacing spikes.',
    normalReferenceRange:
        'PA Interval: 25–55 ms | AH Interval: 50–120 ms | HV Interval: 35–55 ms | QTc: < 450 ms (M), < 460 ms (F)',
    clinicalBoardPearl:
        'Mobitz Type I (Wenckebach) occurs IN the AV node (prolonging AH interval, responsive to Atropine), whereas Mobitz Type II occurs BELOW the AV node in the His-Purkinje system (prolonged HV interval) and requires permanent pacemaker implantation due to risk of sudden progression to Complete Heart Block.',
    howToInteract:
        'Choose an arrhythmia (Normal, WPW, AVNRT, Atrial Flutter, 3rd-Degree Block, or Drug-Induced Torsades de Pointes), then click "Deliver RF Catheter Ablation" or toggle "Dual-Chamber DDD Pacemaker".',
  ),
  'diag_pv_loop': CardiacInfoTopic(
    id: 'diag_pv_loop',
    title: 'Left Ventricular Pressure-Volume (P–V) Loop & Sagawa Elastance Simulator',
    category: 'CARDIAC DIAGNOSTIC WORKSTATION',
    accentColor: Color(0xFFF43F5E),
    plainLanguageSummary:
        'Plots Left Ventricular Volume (mL) on the X-axis against Pressure (mmHg) on the Y-axis for a single heartbeat, making it effortless to see how Preload, Afterload, and Inotropy (contractility) change Stroke Volume and Cardiac Output.',
    advancedMechanism:
        'Computed directly from Sagawa Time-Varying Elastance E(t) = P_LV(t) / (V_LV(t) - V_0):\n'
        '• 4 Phases of the P–V Loop: (1) Diastolic Filling along the exponential EDPVR curve (Mitral valve open), (2) Vertical Isovolumetric Contraction (Mitral closes at EDV), (3) Systolic Ejection up to the linear ESPVR line of slope E_max (Aortic valve opens at diastolic Pa), and (4) Vertical Isovolumetric Relaxation (Aortic valve closes at ESV).\n'
        '• Energetics: Stroke Volume SV = EDV - ESV. External Stroke Work (SW) is the area enclosed inside the P–V loop. Potential Energy (PE) is the triangle to the left of the loop bounded by ESPVR and EDPVR. Pressure-Volume Area PVA = SW + PE correlates linearly with myocardial oxygen consumption (MVO2).',
    normalReferenceRange:
        'EDV: ~120 mL | ESV: ~50 mL | Stroke Volume (SV): ~70 mL | LVEF: ~58% | E_max (ESPVR Slope): ~2.0 mmHg/mL',
    clinicalBoardPearl:
        'Increasing Contractility (Dobutamine / Digoxin / Sympathetic β1) steepens the ESPVR slope (↑ E_max), shifting the left vertical border of the loop to the LEFT (↓ ESV, ↑ SV, ↑ EF). Increasing Afterload (Norepinephrine / Aortic Stenosis) increases peak systolic pressure and shifts the left border to the RIGHT (↑ ESV, ↓ SV).',
    howToInteract:
        'Drag the Preload (EDV), Afterload (Ea), and Contractility (Emax) sliders or click 1-tap Drug Challenge presets (Dobutamine, Norepinephrine, Nitroglycerin, Metoprolol, Sacubitril/Valsartan) to compare the live P–V loop against the dashed normal reference loop.',
  ),
  'diag_chd_shunt': CardiacInfoTopic(
    id: 'diag_chd_shunt',
    title: 'Congenital Heart Disease (CHD), Oximetry Step-Up & Qp/Qs Shunt Lab',
    category: 'CARDIAC DIAGNOSTIC WORKSTATION',
    accentColor: Color(0xFFA78BFA),
    plainLanguageSummary:
        'Visualizes congenital holes or abnormal connections in the heart (ASD, VSD, PDA, Tetralogy of Fallot, Eisenmenger) and shows oxygen saturation (SaO2%) in every chamber so you can spot exactly where oxygenated and deoxygenated blood mix.',
    advancedMechanism:
        'Quantifies intracardiac shunting using the Fick Oximetry Run and Pulmonary-to-Systemic Flow Ratio:\n'
        '• Qp / Qs Formula: Qp/Qs = (SaO2 - SvO2) / (SpvO2 - SpaO2), where SvO2 is mixed venous saturation (~75%), SpvO2 is pulmonary venous saturation (~99%), and SpaO2 is pulmonary artery saturation.\n'
        '• Diagnostic Oximetry Step-Ups (Left-to-Right Shunts): Secundum ASD causes an O2 step-up in the Right Atrium (RA >= 85%); Membranous VSD causes an O2 step-up in the Right Ventricle (RV >= 84%); Patent Ductus Arteriosus (PDA) causes an O2 step-up in the Pulmonary Artery (PA >= 83%) with continuous "machinery" murmur.\n'
        '• Right-to-Left Shunts (Qp/Qs < 1.0, Cyanotic): Tetralogy of Fallot (PROVe: Pulmonic stenosis, RVH, Overriding aorta, VSD) and Eisenmenger Syndrome (chronic L→R shunt induces plexiform pulmonary hypertension until PVR > SVR, reversing the shunt to R→L).',
    normalReferenceRange:
        'Normal Qp/Qs: 1.0 | Surgical Shunt Threshold: Qp/Qs >= 1.5 | Normal SaO2: RA/RV/PA = 75%, LA/LV/Ao = 98–99%',
    clinicalBoardPearl:
        'Ductus Arteriosus Pharmacology: Prostaglandin E1 (Alprostadil) keeps the PDA OPEN in ductal-dependent congenital lesions, whereas NSAIDs (Indomethacin / Ibuprofen) inhibit COX prostaglandin synthesis to CLOSE a symptomatic PDA in preterm neonates!',
    howToInteract:
        'Select any congenital lesion (Normal, ASD, VSD, PDA, Tetralogy of Fallot, Eisenmenger) and test pharmacological/physiological interventions (Indomethacin, PGE1 Alprostadil, or Knee-Chest Squatting for Tet Spells).',
  ),
  'diag_neuro_tilt': CardiacInfoTopic(
    id: 'diag_neuro_tilt',
    title: 'Neuro-Cardiology Head-Up Tilt-Table (HUTT) Syncope & Frontal EEG Lab',
    category: 'CARDIAC DIAGNOSTIC WORKSTATION',
    accentColor: Color(0xFFFB923C),
    plainLanguageSummary:
        'Simulates tilting a patient from flat (0°) to upright (70°) on a motorized table while monitoring blood pressure, heart rate, and brainwaves (EEG) to diagnose why a patient faints (Vasovagal Syncope, Orthostatic Hypotension, or POTS).',
    advancedMechanism:
        'Couples baroreceptor autonomic reflex physiology with cerebral autoregulation and cortical electroencephalography (EEG):\n'
        '• Gravitational Venous Pooling: Tilting to 70° shifts 500–800 mL of blood into the splanchnic and lower-extremity capacitance veins, reducing RV/LV preload. Normally, carotid/aortic baroreceptors trigger sympathetic α1 vasoconstriction and β1 mild tachycardia (+10–15 bpm) to maintain Mean Arterial Pressure (MAP) and Cerebral Perfusion Pressure (CPP).\n'
        '• Autonomic Syndromes: (1) Vasovagal (Neurocardiogenic) Syncope — Bezold-Jarisch mechanoreceptor paradoxical reflex causes abrupt cardioinhibition (bradycardia/asystole) and vasodepression (hypotension); (2) POTS — sustained HR increase >= 30 bpm (or > 120 bpm) within 10 min of tilt without orthostatic hypotension; (3) Neurogenic Orthostatic Hypotension — SBP drop >= 20 mmHg or DBP drop >= 10 mmHg with blunted HR response.\n'
        '• ECG–EEG Coupling: When upright MAP falls below the lower limit of cerebral autoregulation (~50–55 mmHg), frontal EEG transitions from normal awake Alpha (8–12 Hz) to high-amplitude Theta/Delta (1–4 Hz) slowing, followed by transient background flattening during frank syncope.',
    normalReferenceRange:
        'Tilt Angle: 60°–70° | POTS Criterion: ΔHR >= +30 bpm without BP drop | Orthostatic Hypotension: ΔSBP <= -20 or ΔDBP <= -10 mmHg',
    clinicalBoardPearl:
        'Physical Counter-Pressure Maneuvers (leg crossing with muscle tensing or isometric handgrip) during the prodromal phase of vasovagal syncope acutely boost venous return and SVR, aborting loss of consciousness and restoring normal alpha EEG activity.',
    howToInteract:
        'Adjust the Tilt Table Angle (0° Supine to 70° Head-Up Tilt), switch between Autonomic Profiles (Normal, Vasovagal Syncope, POTS, Orthostatic Hypotension), and trigger "Leg-Cross Counter-Pressure Maneuver".',
  ),

  // ── 11. COMPUTATIONAL CARDIOLOGY RESEARCH WORKSTATION ────────────────────
  'research_cipa_ap': CardiacInfoTopic(
    id: 'research_cipa_ap',
    title: 'CardioElectrophys-Net: CiPA Ventricular Action Potential & hERG/IKr Coupling',
    category: 'COMPUTATIONAL RESEARCH WORKSTATION',
    accentColor: Color(0xFFA78BFA),
    plainLanguageSummary:
        'Chains our 5-member CardioNephroGNN drug affinity predictions directly into our 1D Temporal ResNet cardiomyocyte model to simulate how a drug changes the 600 ms electrical pulse of a single human heart muscle cell—revealing QT prolongation, Early Afterdepolarizations (EADs), and Torsades de Pointes risk.',
    advancedMechanism:
        'Couples multi-channel Hill pore-blockade equations b_i = 1 / (1 + (IC50_i / [C])^n) across IKr (hERG/Kv11.1, CHEMBL240), ICaL (Cav1.2), INaL (Nav1.5), IKs, and IK1 with our custom PyTorch 1D Temporal ResNet trained on O\'Hara-Rudy (ORd) human ventricular cardiomyocyte trajectories on Apple Silicon M1 Pro Metal GPU:\n'
        '• Action Potential Duration (APD50 & APD90): Selective IKr block (e.g., Terfenadine) delays Phase 3 repolarization, markedly prolonging APD90.\n'
        '• Early Afterdepolarizations (EADs): When Phase 2/3 plateau is prolonged inside the -30 to +10 mV window, L-type Ca2+ channels (ICaL) recover from inactivation and re-open, generating a secondary depolarizing oscillation that triggers Torsades de Pointes (TdP).\n'
        '• CiPA qNet (uC/uF): Integrates net inward/outward electronic charge across the action potential plateau. Drugs with balanced IKr + ICaL block (e.g., Amiodarone, Verapamil) preserve qNet and suppress EADs despite QTc prolongation.',
    normalReferenceRange:
        'Control APD90 (70 bpm): ~280 ms | ΔAPD90 Alert: >= +30 ms | CiPA qNet Low TdP Risk: > 0.060 uC/uF | High TdP Risk: < 0.050 uC/uF',
    clinicalBoardPearl:
        'Under the FDA/ICH S7B & E14 CiPA (Comprehensive in vitro Proarrhythmia Assay) paradigm, hERG block alone does not equal Torsades risk! Amiodarone blocks hERG potently yet has low TdP incidence because its concomitant L-type Ca2+ (ICaL) and late Na+ (INaL) blockade prevent Phase 2/3 EADs.',
    howToInteract:
        'Select any clinical reference molecule (Terfenadine, Amiodarone, Enalaprilat, Bisoprolol, Empagliflozin, Losartan), drag the Free Plasma Concentration slider (0.01–100 uM) and Pacing Heart Rate slider, and compare Control vs. Drug Vm(t) traces.',
  ),
  'research_pinn_wss': CardiacInfoTopic(
    id: 'research_pinn_wss',
    title: 'CardioPINN-Hemodynamics: 1D-0D Navier-Stokes TAWSS, OSI & Reynolds Profiler',
    category: 'COMPUTATIONAL RESEARCH WORKSTATION',
    accentColor: Color(0xFF00E5FF),
    plainLanguageSummary:
        'Uses a custom Physics-Informed Neural Network (PINN) trained on Apple Silicon MPS to compute blood pressure drop, frictional wall shear stress (TAWSS), flow reversal (OSI), and turbulence (Reynolds number) millimeter-by-millimeter along a narrowed coronary artery.',
    advancedMechanism:
        'Solves 1D Poiseuille/Navier-Stokes momentum conservation coupled with Kirkeeide viscous resistance, Borda-Carnot convective flow separation, and 3-Element Windkessel (Rp, C, Rd) distal microvascular impedance:\n'
        '• Time-Averaged Wall Shear Stress (TAWSS = (1/T) ∫ |τ_w(x,t)| dt): Scales with 1/r(x)³, spiking > 100 dynes/cm² at the stenotic throat (high risk of fibrous cap fissuring and platelet vWF activation).\n'
        '• Oscillatory Shear Index (OSI = 0.5 × [1 - |∫ τ_w dt| / ∫ |τ_w| dt]): Quantifies directional flow reversal (0.0 = unidirectional laminar; 0.5 = purely oscillatory). Post-stenotic recirculation zones exhibit high OSI (> 0.20) and low TAWSS (< 4 dynes/cm²), driving endothelial VCAM-1/NF-κB activation and plaque progression.',
    normalReferenceRange:
        'Physiologic TAWSS: 15–35 dynes/cm² | Plaque Rupture Throat TAWSS: > 70 dynes/cm² | Atherogenic Post-Stenotic OSI: > 0.20 | Laminar Re: < 400',
    clinicalBoardPearl:
        'High throat TAWSS (> 70 dynes/cm²) promotes acute fibrous cap rupture and platelet-rich white thrombus at the stenosis apex, whereas post-stenotic high OSI (> 0.20) + low TAWSS (< 4 dynes/cm²) drives downstream lipid accumulation and negative vessel remodeling.',
    howToInteract:
        'Adjust Diameter Stenosis %, Lesion Length (mm), and Reference Vessel Diameter (mm), inspect the spatial P(x), TAWSS(x), and OSI(x) curves, and toggle "Project 3D Coronary WSS Heatmap" to visualize shear stress on the 3D coronary tree.',
  ),
  'research_virtual_cohort': CardiacInfoTopic(
    id: 'research_virtual_cohort',
    title: 'Monte Carlo Virtual Patient Cohort (N=50–500) & Sobol Sensitivity Tornado Plot',
    category: 'COMPUTATIONAL RESEARCH WORKSTATION',
    accentColor: Color(0xFF10B981),
    plainLanguageSummary:
        'Runs an instant in-silico clinical trial across up to 500 synthetic patients in under 10 milliseconds using our CardioPINN neural operator, comparing pre-stent vs. post-stent FFR/iFR distributions and ranking which anatomical factors matter most.',
    advancedMechanism:
        'Executes vectorized PyTorch tensor inference across N = 50 to 500 Monte Carlo virtual patients sampled from physiological distributions of stenosis severity, lesion length, reference vessel caliber, microvascular resistance (IMR), heart rate, and arterial blood pressure:\n'
        '• Pre- vs. Post-PCI Population Distributions: Computes mean, standard deviation (SD), and 5th/50th/95th percentiles for FFR, iFR, throat TAWSS, post-stenotic OSI, and ischemic burden (fraction of cohort with FFR <= 0.80).\n'
        '• First-Order Variance Decomposition (Sobol S1 Sensitivity Tornado): Ranks the relative variance contribution of each anatomical and hemodynamic input parameter to distal coronary ischemia.',
    normalReferenceRange:
        'Cohort Inference Latency: < 10 ms (500 Patients on MPS/CPU) | Target Post-PCI FFR: >= 0.90 | Primary Variance Driver: % Diameter Stenosis (S1 ~ 0.65–0.78)',
    clinicalBoardPearl:
        'Diffuse moderate disease (long lesion length in a small-caliber 2.2 mm vessel) can produce an ischemic FFR <= 0.80 even when focal percent diameter stenosis appears < 60%, whereas elevated microvascular resistance (high IMR) blunts hyperemic flow and artificially elevates FFR.',
    howToInteract:
        'Select Cohort Size (N = 50, 100, 250, or 500 Virtual Patients), click "Run Batch In-Silico Trial", and inspect the Baseline vs. Post-PCI histograms and Sobol Sensitivity Tornado chart.',
  ),
  'research_provenance_export': CardiacInfoTopic(
    id: 'research_provenance_export',
    title: 'Reproducible Data Export, SHA-256 Provenance Ledger & 5-Member GNN Epistemic Uncertainty',
    category: 'COMPUTATIONAL RESEARCH WORKSTATION',
    accentColor: Color(0xFFFFD600),
    plainLanguageSummary:
        'Provides peer-review-ready scientific transparency: exports 1,000 Hz waveform CSVs, deterministic SHA-256 parameter hashes, copyable Python/cURL reproduction scripts, verified ChEMBL target IDs, and 5-member GNN bootstrap epistemic uncertainty (σ) with RDKit Tanimoto applicability domain badges.',
    advancedMechanism:
        'Enforces computational reproducibility and chemoinformatics applicability domain standards:\n'
        '• 5-Member Bootstrap Ensemble (member_0.pt..member_4.pt): Quantifies epistemic model uncertainty (σ_pIC50) across 5 independently scaffold-split & bootstrapped GNN models trained on Apple Silicon MPS.\n'
        '• RDKit Morgan Fingerprint (r=2, 2048-bit) Tanimoto Applicability Domain: Flags Out-of-Distribution (OOD) chemical structures when maximum Tanimoto similarity to the ChEMBL training set falls below 0.35 or mean σ > 0.65.\n'
        '• Verified ChEMBL Target Provenance: KCNH2/hERG (CHEMBL240), ACE (CHEMBL1824), AGTR1 (CHEMBL233), ADRB1 (CHEMBL213), and SLC5A2/SGLT2 (CHEMBL5251).',
    normalReferenceRange:
        'Ensemble Committee: 5 PyTorch MPS Checkpoints | In-Domain Tanimoto Threshold: >= 0.35 | High-Confidence Epistemic σ: <= 0.35 pIC50 units',
    clinicalBoardPearl:
        'In regulatory QSAR and computational pharmacology (OECD QSAR Validation Principles), a prediction without a defined Applicability Domain (Tanimoto similarity) and Uncertainty Quantification (bootstrap ensemble σ) is scientifically incomplete.',
    howToInteract:
        'Click "Copy 1,000 Hz CSV Telemetry", "Copy SHA-256 JSON Manifest", or "Copy Python Reproduction Script" to export deterministic research artifacts for notebooks and publications.',
  ),

  // ── 12. INTERVENTIONAL FELLOWSHIP, DIGITAL TWIN & MULTIPLAYER GRAND ROUNDS ─
  'fellowship_bifurcation_cto_structural': CardiacInfoTopic(
    id: 'fellowship_bifurcation_cto_structural',
    title: 'Complex Interventional PCI (DK-Crush vs. Culotte, CTO Crossing) & Structural Heart (TAVR & MitraClip)',
    category: 'FELLOWSHIP & STRUCTURAL SUITE',
    accentColor: Color(0xFF38BDF8),
    plainLanguageSummary:
        'Simulates advanced fellowship-level heart procedures: stenting a Y-shaped arterial fork (Medina 1,1,1 Bifurcation), crossing a 100% chronically blocked artery (CTO) through tiny collateral channels, replacing a calcified aortic valve via catheter (TAVR), and clipping a leaky mitral valve (MitraClip TEER).',
    advancedMechanism:
        'Models complex coronary and structural hemodynamics:\n'
        '• Medina 1,1,1 Bifurcation PCI (DK-Crush vs. Culotte vs. Provisional): Double-Kissing Crush (DK-Crush) with Proximal Optimization Technique (POT) eliminates carina shift, normalizes carina Time-Averaged Wall Shear Stress (TAWSS ~18 dynes/cm²), minimizes recirculation OSI (<0.10), and preserves side-branch FFR (>= 0.94) compared to Provisional crossover (pinched side-branch ostium, FFR ~0.74).\n'
        '• Chronic Total Occlusion (CTO) Hybrid Algorithm: Grades J-CTO difficulty (blunt stump, calcification, >20° bend, length >=20 mm, retry) and models Retrograde Septal Collateral Surfing (Sion/Suoh 03 wire + Corsair microcatheter + Reverse CART).\n'
        '• Structural Heart (TAVR & MitraClip): TAVR (SAPIEN 3 / Evolut FX) expands effective aortic valve area from 0.65 cm² to >2.0 cm², dropping Bernoulli peak pressure gradient ΔP = 4v² from >64 mmHg to <10 mmHg. MitraClip TEER grasps A2–P2 scallops, dropping regurgitant fraction from >50% to <15% and normalizing giant LA V-waves.',
    normalReferenceRange:
        'Post-DK-Crush SB FFR: >= 0.90 | Post-TAVR Mean Gradient: < 10 mmHg (AVA > 1.8 cm²) | Post-MitraClip MR Grade: <= 1+ (Transmitral ΔP < 5 mmHg)',
    clinicalBoardPearl:
        'DKCRUSH-V Trial Pearl: For complex distal Left Main true bifurcations (Medina 1,1,1 or 0,1,1), planned 2-stent DK-Crush significantly reduces target lesion failure and stent thrombosis compared to provisional stenting.',
    howToInteract:
        'Switch between Bifurcation PCI (Provisional, DK-Crush, Culotte), CTO Crossing (Antegrade Escalation, Dissection Re-Entry, Retrograde Reverse CART), and Structural Heart (TAVR SAPIEN 3, TAVR Evolut FX, MitraClip TEER) and toggle Deployment.',
  ),
  'fellowship_inverse_digital_twin': CardiacInfoTopic(
    id: 'fellowship_inverse_digital_twin',
    title: 'Real ECG & Hemodynamic Waveform Ingestion (CardioPINN Zero-PHI Inverse Digital Twin)',
    category: 'FELLOWSHIP & STRUCTURAL SUITE',
    accentColor: Color(0xFF10B981),
    plainLanguageSummary:
        'Lets you load anonymized real-world ICU/Cath Lab waveforms (PhysioNet MIMIC-III, PTB-XL STEMI, MIT-BIH) or paste a CSV trace directly in your browser. CardioPINN works backward from the waveform to discover the patient\'s arterial stiffness (C), microvascular resistance (IMR), and heart squeeze (Emax)—without any patient data ever leaving your device.',
    advancedMechanism:
        'Executes 100% browser-local Zero-PHI parsing (HIPAA Safe Harbor / GDPR compliant) followed by CardioPINN 3-Element Windkessel parameter inversion:\n'
        '• Windkessel Arterial Compliance (C = SV / [SBP - DBP]): Estimates aortic elastic buffering from pulse pressure decay time constant τ = R_d × C during diastole.\n'
        '• Microvascular Resistance (IMR) & Systemic Vascular Resistance (SVR): Fits distal coronary microvascular impedance and systemic afterload from Mean Arterial Pressure (MAP) and ST-segment ischemic shift.\n'
        '• Time-Varying Elastance Contractility (E_max): Inverts end-systolic pressure-volume slope to synchronize the 3D beating heart and P–V loop to the ingested waveform.',
    normalReferenceRange:
        'Arterial Compliance C: 1.4–2.2 mL/mmHg | Normal IMR: < 25 units | Normal E_max: 1.8–2.5 mmHg/mL | Waveform Fit R²: >= 0.96',
    clinicalBoardPearl:
        'Isolated Systolic Hypertension in elderly/HFpEF patients reflects reduced Windkessel aortic compliance (low C): stroke volume is ejected into a rigid aorta, spiking Systolic BP (>160 mmHg) while accelerating diastolic runoff (low Diastolic BP, wide Pulse Pressure), which compromises diastolic coronary perfusion.',
    howToInteract:
        'Select a PhysioNet/MIMIC anonymized waveform preset or paste custom CSV samples (time_ms,ecg_mv,pa_mmhg), click "Invert Digital Twin Parameters", and click "Sync Twin to 3D Beating Heart".',
  ),
  'fellowship_multiplayer_grand_rounds': CardiacInfoTopic(
    id: 'fellowship_multiplayer_grand_rounds',
    title: 'Live Multiplayer Cath Lab & Cardiology Grand Rounds Room ("Pass Catheter" OSCE Mode)',
    category: 'FELLOWSHIP & STRUCTURAL SUITE',
    accentColor: Color(0xFFF43F5E),
    plainLanguageSummary:
        'Creates a synchronized teaching room (`quantumforgeapp.com/#/cardiac?room=...`) where an Attending Professor and fellows share the same live Cath Lab state, trigger sudden life-threatening emergencies, and hand over catheter/defibrillator controls to rescue the patient.',
    advancedMechanism:
        'Synchronizes multi-user Cath Lab state (room ID, active operator, C-arm projection, vitals, and complication state) and scores time-critical interventional bailout drills:\n'
        '• Ellis Type III Coronary Perforation & Tamponade: High-pressure jet extravasation into the pericardium equalizes diastolic pressures (RA = RV = PCWP) and collapses RV filling; rescued by prolonged balloon tamponade, PK Papyrus covered stent deployment, and emergent pericardiocentesis.\n'
        '• Acute Coronary No-Reflow (TIMI 0–1): Distal atherothrombotic microembolization and microvascular spasm after stent deployment; rescued by distal intracoronary Adenosine / Nicardipine / Verapamil.\n'
        '• Drug-Induced Torsades de Pointes (CardioElectrophys-Net hERG Crisis): Polymorphic VT with twisting QRS axis; rescued by 200J biphasic defibrillation + IV Magnesium Sulfate 2g bolus.',
    normalReferenceRange:
        'Target Bailout Time: < 60 sec | Pericardial Tamponade Beck\'s Triad: Hypotension + JVD + Muffled Heart Sounds | Target OSCE Score: 100/100',
    clinicalBoardPearl:
        'In acute coronary No-Reflow after stenting, never administer intracoronary Nitroglycerin expecting microvascular relief—nitroglycerin dilates epicardial conductance arteries (>200 um) but is ineffective on distal resistance arterioles (<100 um). Use intracoronary Adenosine, Nicardipine, Verapamil, or Nitroprusside instead!',
    howToInteract:
        'Copy the shareable Grand Rounds Room URL, click "Pass Catheter to Fellow", trigger an Attending Emergency (Perforation/Tamponade, Acute No-Reflow, or Torsades de Pointes), and execute the matching lifesaving bailout intervention.',
  ),
};

/// Sleek, reusable `ⓘ` Info Button that supports BOTH:
/// 1. Instant rich multi-line hover tooltip (desktop/web mouseover)
/// 2. Click / tap to open the comprehensive `CardiacClinicalInfoModal` deep-dive dialog.
class CardiacInfoButton extends StatelessWidget {
  final String topicId;
  final double size;
  final Color? color;
  final String? customLabel;

  const CardiacInfoButton({
    super.key,
    required this.topicId,
    this.size = 14.0,
    this.color,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final topic = kCardiacInfoTopics[topicId] ?? kCardiacInfoTopics['legal_samd_shield']!;
    final iconColor = color ?? topic.accentColor;

    return Tooltip(
      waitDuration: const Duration(milliseconds: 180),
      showDuration: const Duration(seconds: 6),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B111A).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: topic.accentColor.withValues(alpha: 0.7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: '${topic.category}\n',
            style: TextStyle(
              color: topic.accentColor,
              fontSize: 9.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          TextSpan(
            text: '${topic.title}\n\n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          TextSpan(
            text: '${topic.plainLanguageSummary}\n\n',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.0,
              height: 1.4,
            ),
          ),
          TextSpan(
            text: 'Reference: ${topic.normalReferenceRange}\n',
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 10.0,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const TextSpan(
            text: '\n💡 Click ⓘ for full clinical formulas, board pearls & legal notice',
            style: TextStyle(
              color: Color(0xFFFFD600),
              fontSize: 9.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => showCardiacTopicModal(context, topic),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: customLabel != null ? 6.0 : 3.0,
            vertical: 2.0,
          ),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.45),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: size,
                color: iconColor,
              ),
              if (customLabel != null) ...[
                const SizedBox(width: 4),
                Text(
                  customLabel!,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the detailed multi-section Clinical & Biophysical Reference Modal for a single topic.
void showCardiacTopicModal(BuildContext context, CardiacInfoTopic topic) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0D141F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: topic.accentColor.withValues(alpha: 0.6), width: 1.4),
        ),
        titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: topic.accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: topic.accentColor.withValues(alpha: 0.5)),
              ),
              child: Icon(Icons.info_rounded, color: topic.accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.category,
                    style: TextStyle(
                      color: topic.accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topic.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),

                // 1. Plain-English Easy Summary
                _infoSectionCard(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'PLAIN-ENGLISH SUMMARY (EASY TO UNDERSTAND)',
                  accent: const Color(0xFF10B981),
                  body: topic.plainLanguageSummary,
                ),
                const SizedBox(height: 10),

                // 2. Advanced Biophysics & Physiology
                _infoSectionCard(
                  icon: Icons.science_rounded,
                  label: 'ADVANCED PHYSIOLOGY, BIOPHYSICS & MECHANISM',
                  accent: const Color(0xFF00E5FF),
                  body: topic.advancedMechanism,
                ),
                const SizedBox(height: 10),

                // 3. Normal Reference Ranges
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131C2B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monitor_heart_rounded, color: Color(0xFF38BDF8), size: 15),
                          SizedBox(width: 6),
                          Text(
                            'CLINICAL REFERENCE BENCHMARKS & NORMAL RANGES',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        topic.normalReferenceRange,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 4. High-Yield Board & Cath Lab Pearl
                _infoSectionCard(
                  icon: Icons.school_rounded,
                  label: 'HIGH-YIELD MBBS / USMLE / CATH LAB CLINICAL PEARL',
                  accent: const Color(0xFFFFD600),
                  body: topic.clinicalBoardPearl,
                ),
                const SizedBox(height: 10),

                // 5. How to Interact
                _infoSectionCard(
                  icon: Icons.touch_app_rounded,
                  label: 'HOW TO INTERACT IN QUANTUM FORGE',
                  accent: const Color(0xFFA78BFA),
                  body: topic.howToInteract,
                ),
                const SizedBox(height: 12),

                // 6. Statutory Legal / Non-Clinical Shield
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.gavel_rounded, color: Color(0xFFFFB300), size: 15),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Statutory Regulatory & Legal Notice (21 U.S.C. § 360j(o) / EU MDR): '
                          'This explanation and simulation are strictly for academic instruction and mathematical modeling. '
                          'Never use for clinical patient diagnosis, prescribing, or medical treatment.',
                          style: TextStyle(
                            color: Color(0xFFFFB300),
                            fontSize: 10,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
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
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.menu_book_rounded, size: 15, color: Color(0xFF00E5FF)),
            label: const Text(
              'Browse All 18+ Cath Lab Topics',
              style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              showCardiacInteractiveGuideDialog(context);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: topic.accentColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      );
    },
  );
}

Widget _infoSectionCard({
  required IconData icon,
  required String label,
  required Color accent,
  required String body,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFF121A26),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          body,
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

/// Opens the searchable Master Interactive Guide & Encyclopedia of all Cath Lab topics.
void showCardiacInteractiveGuideDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => const _CardiacInteractiveGuideDialog(),
  );
}

class _CardiacInteractiveGuideDialog extends StatefulWidget {
  const _CardiacInteractiveGuideDialog();

  @override
  State<_CardiacInteractiveGuideDialog> createState() => _CardiacInteractiveGuideDialogState();
}

class _CardiacInteractiveGuideDialogState extends State<_CardiacInteractiveGuideDialog> {
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  static const List<String> _categories = [
    'ALL',
    'FELLOWSHIP & STRUCTURAL SUITE',
    'COMPUTATIONAL RESEARCH WORKSTATION',
    'CARDIAC DIAGNOSTIC WORKSTATION',
    '3D HEART VIEWPORT MODE',
    'INCOMING VENOUS CIRCULATION',
    'INCOMING OXYGENATED CIRCULATION',
    'OUTGOING ARTERIAL CIRCULATION',
    'CORONARY ARTERIAL CIRCULATION',
    'INTERVENTIONAL CARDIOLOGY',
    'HEMODYNAMIC & ECG TELEMETRY',
    'LEGAL & REGULATORY COMPLIANCE',
  ];

  @override
  Widget build(BuildContext context) {
    final allTopics = kCardiacInfoTopics.values.where((t) {
      final matchesCat = _selectedCategory == 'ALL' || t.category == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.plainLanguageSummary.toLowerCase().contains(q) ||
          t.advancedMechanism.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();

    return AlertDialog(
      backgroundColor: const Color(0xFF0B111A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
      ),
      title: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: Color(0xFF00E5FF), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CardioCath 3D Interactive Clinical & Biophysical Guide',
                  style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Plain-English Summaries, Advanced Hemodynamics, Incoming/Outgoing Vessels & Board Pearls',
                  style: TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 540,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search vessels (SVC, Coronary Sinus, LAD), FFR, iFR, Wiggers, ECG, IABP...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 11.5),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00E5FF), size: 18),
                filled: true,
                fillColor: const Color(0xFF131C2B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 8),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSel = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                      backgroundColor: const Color(0xFF131C2B),
                      labelStyle: TextStyle(
                        color: isSel ? const Color(0xFF00E5FF) : Colors.white60,
                        fontSize: 9.5,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Topic Cards List
            Expanded(
              child: ListView.separated(
                itemCount: allTopics.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final t = allTopics[idx];
                  return InkWell(
                    onTap: () => showCardiacTopicModal(context, t),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121A26),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: t.accentColor.withValues(alpha: 0.45)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: t.accentColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t.category,
                                  style: TextStyle(
                                    color: t.accentColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(Icons.open_in_new_rounded, color: Color(0xFF00E5FF), size: 15),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.plainLanguageSummary,
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Normal / Benchmark: ${t.normalReferenceRange}',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.gavel_rounded, color: Color(0xFFFFB300), size: 16),
          label: const Text(
            'View 7-Pillar Legal & Liability Protection Shield',
            style: TextStyle(color: Color(0xFFFFB300), fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            showCardiacLegalShieldDialog(context);
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close Guide', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

/// Comprehensive 7-Pillar Legal, Regulatory, Malpractice, Trademark & Privacy Shield Dialog
/// Specifically engineered to protect the platform creator (Ali Asghar) against all
/// regulatory, tort/malpractice, intellectual property, privacy, and AI liability vectors.
void showCardiacLegalShieldDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0B1018),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB300)),
              ),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFFFFB300), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7-PILLAR LEGAL, REGULATORY & LIABILITY PROTECTION SHIELD',
                    style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Statutory SaMD Exemption, Non-Reliance Covenant & IP Fair-Use Terms',
                    style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white54),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 680,
          height: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legalPillarCard(
                  number: '1',
                  title: 'Statutory Non-Device Exemption (FDA 21 U.S.C. § 360j(o) / EU MDR 2017/745)',
                  body:
                      'Quantum Forge and CardioCath 3D Lab are strictly academic, mathematical, and pedagogical simulation tools designed for university-level science, MBBS, Pharm-D, and biomedical engineering instruction. Pursuant to Section 3060 of the US 21st Century Cures Act (21 U.S.C. § 360j(o)(1)) and EU Medical Device Regulation (MDR 2017/745 Article 2), this software is NOT a Medical Device, NOT Software as a Medical Device (SaMD), and NOT a Clinical Decision Support (CDS) system intended for the diagnosis, cure, mitigation, treatment, or prevention of disease in humans or animals.',
                ),
                const SizedBox(height: 10),
                _legalPillarCard(
                  number: '2',
                  title: 'Medical Malpractice, Tort & Clinical Reliance Waiver (No Duty of Care)',
                  body:
                      'Use of this simulator does NOT create a physician-patient, pharmacist-patient, clinical consulting, or fiduciary relationship between the author (Ali Asghar) and any user. All hemodynamic waveforms, ST-segment deviations, OSCE clinical vignettes, drug mechanisms, dosing examples (e.g., Aspirin, Heparin, Ticagrelor, Atropine, Nitroglycerin), and stent simulations are simplified theoretical approximations. Users expressly covenant NEVER to rely on this software for actual patient care, prescribing, surgical/interventional planning, or emergency triage.',
                ),
                const SizedBox(height: 10),
                _legalPillarCard(
                  number: '3',
                  title: 'Intellectual Property & Nominative Fair-Use Trademark Non-Affiliation',
                  body:
                      'All 3D anatomical meshes, procedural shaders, and Navier-Stokes / Wiggers mathematical solvers in Quantum Forge are 100% original proprietary code created by Ali Asghar. Any clinical catheter curves or interventional device terminology referenced in academic exercises (e.g., Judkins JL4/JR4, Amplatz AL1, EBU, PressureWire, Rotablator, IVUS, OCT) are used strictly under Nominative Fair Use for descriptive educational instruction. Quantum Forge is an independent academic work and is NOT affiliated with, sponsored by, or endorsed by Boston Scientific, Abbott / St. Jude Medical, Medtronic, Cordis, Philips, Siemens Healthineers, or any other medical device or pharmaceutical manufacturer.',
                ),
                const SizedBox(height: 10),
                _legalPillarCard(
                  number: '4',
                  title: 'In-Silico AI & Graph Neural Network (CardioNephroGNN) Uncertainty Disclosure',
                  body:
                      'Predictions generated by CardioNephroGNN (target pIC50 binding affinities across ACE, AGTR1, ADRB1, SGLT2, and hERG potassium channel cardiotoxicity risk scores) and critiques generated by the AI Attending Proctor are statistical in-silico QSAR estimates trained on public bioassay datasets (ChEMBL CC-BY-SA 3.0 / PubChem). Computational models are subject to domain-of-applicability limits, assay variance, and false-positive/false-negative error rates, and can NEVER substitute for GLP wet-lab ICH S7B patch-clamp electrophysiology or regulatory toxicology studies.',
                ),
                const SizedBox(height: 10),
                _legalPillarCard(
                  number: '5',
                  title: 'HIPAA, GDPR & Health Data Privacy (100% Synthetic Zero-PHI Architecture)',
                  body:
                      'CardioCath 3D operates exclusively on synthetic, procedurally generated mathematical equations. The platform does NOT accept, ingest, process, transmit, or store Protected Health Information (PHI), electronic health records (EHR), patient DICOM files, or personally identifiable medical data. Users are strictly prohibited from entering real patient identifiers into any input field.',
                ),
                const SizedBox(height: 10),
                _legalPillarCard(
                  number: '6',
                  title: 'Disclaimer of Warranties & Limitation of Liability ("AS-IS" Academic Software)',
                  body:
                      'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE INTERNATIONAL AND LOCAL LAW, QUANTUM FORGE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR CLINICAL OR SCIENTIFIC PURPOSE, ACCURACY, OR NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHOR (ALI ASGHAR) BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THIS SIMULATION.',
                ),
                const SizedBox(height: 10),
                _legalPillarCard(
                  number: '7',
                  title: 'User Assumption of Risk & Indemnification Agreement',
                  body:
                      'By accessing or interacting with Quantum Forge, the user acknowledges and agrees that they assume full sole responsibility for verifying any scientific, pharmacological, or clinical concepts against official peer-reviewed literature, FDA/EMA prescribing information, and licensed medical authorities, and agrees to hold harmless and indemnify the creator against any third-party claims arising from misuse of this educational tool.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            label: const Text(
              'I Understand & Acknowledge (Educational Use Only)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      );
    },
  );
}

Widget _legalPillarCard({
  required String number,
  required String title,
  required String body,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF131B26),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFB300)),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11.2,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}
