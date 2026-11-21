// ============================================================================
// NephroLab 3D: Nephron & Glomerulus Micro-Anatomical Landmark Models
// ----------------------------------------------------------------------------
// High-yield anatomical landmarks across the renal micro-architecture:
// Glomerulus, Bowman's capsule, podocyte slit diaphragms, PCT SGLT2/NHE3,
// Loop of Henle NKCC2, JGA Macula Densa, DCT NCCT, and Collecting Duct ENaC/AQP2.
// Includes USMLE / Nephrology Board clinical pearls & transport kinetics.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';

enum NephronTagCategory {
  all('All Structures'),
  wholeKidney('Whole Kidney Macro'),
  glomerulus('Glomerulus & Filtration'),
  pctAndLoop('PCT & Loop of Henle'),
  dctAndJga('DCT & JGA (RAAS)'),
  collectingDuct('Collecting Duct'),
  pathology('Biopsy Pathology');

  final String label;
  const NephronTagCategory(this.label);
}

class NephronLandmarkTag {
  final String id;
  final String label;
  final String shortCode;
  final NephronTagCategory category;
  final String transportKinetics;
  final String targetDrug;
  final String clinicalPearl;
  final double x3D;
  final double y3D;
  final double z3D;
  final Color badgeColor;

  const NephronLandmarkTag({
    required this.id,
    required this.label,
    required this.shortCode,
    required this.category,
    required this.transportKinetics,
    required this.targetDrug,
    required this.clinicalPearl,
    required this.x3D,
    required this.y3D,
    required this.z3D,
    this.badgeColor = const Color(0xFF00E5FF),
  });
}

const List<NephronLandmarkTag> kNephronTags = [
  // ── Glomerulus & Filtration ─────────────────────────────────────────────
  NephronLandmarkTag(
    id: 'afferent_arteriole',
    label: 'Afferent Arteriole (Vascular Pole)',
    shortCode: 'Afferent Art.',
    category: NephronTagCategory.glomerulus,
    transportKinetics: 'Autoregulatory myogenic & tubuloglomerular feedback resistance.',
    targetDrug: 'NSAIDs (constrict via PG inhibition)',
    clinicalPearl:
        'Prostaglandins (PGE2/PGI2) maintain afferent vasodilation during hypovolemia. NSAID inhibition causes acute pre-renal azotemia by dropping glomerular capillary pressure.',
    x3D: -38,
    y3D: 32,
    z3D: -12,
    badgeColor: Color(0xFFEF4444),
  ),
  NephronLandmarkTag(
    id: 'efferent_arteriole',
    label: 'Efferent Arteriole',
    shortCode: 'Efferent Art.',
    category: NephronTagCategory.glomerulus,
    transportKinetics: 'Post-glomerular resistance maintaining intraglomerular hydraulic pressure.',
    targetDrug: 'Lisinopril / ACEi / ARBs (dilate)',
    clinicalPearl:
        'Angiotensin II preferentially constricts efferent arterioles to sustain GFR. ACE inhibitors relieve efferent tone, lowering intraglomerular pressure (nephroprotective in diabetes).',
    x3D: -32,
    y3D: 42,
    z3D: 10,
    badgeColor: Color(0xFFF97316),
  ),
  NephronLandmarkTag(
    id: 'capillary_tuft',
    label: 'Glomerular Capillary Tuft',
    shortCode: 'Capillary Tuft',
    category: NephronTagCategory.glomerulus,
    transportKinetics: 'Ultrafiltration across fenestrated endothelium & glomerular basement membrane.',
    targetDrug: 'SGLT2 inhibitors (lower hyperfiltration)',
    clinicalPearl:
        'Net ultrafiltration pressure Puf = (Pgc - Pbs) - (πgc - πbs). Normal GFR is 120 mL/min; loss of negative charge on GBM causes albuminuria (Nephrotic Syndrome).',
    x3D: -25,
    y3D: 25,
    z3D: 0,
    badgeColor: Color(0xFF00E5FF),
  ),
  NephronLandmarkTag(
    id: 'podocyte_pedicels',
    label: 'Podocyte Interdigitating Foot Processes',
    shortCode: 'Podocytes',
    category: NephronTagCategory.glomerulus,
    transportKinetics: 'Nephrin/podocin slit diaphragm sieve (exclusion size ~4 nm).',
    targetDrug: 'Steroids (Minimal Change Disease)',
    clinicalPearl:
        'Podocyte effacement on electron microscopy is the hallmark of Minimal Change Disease. Disruption of the slit diaphragm allows massive non-selective proteinuria (>3.5 g/day).',
    x3D: -20,
    y3D: 35,
    z3D: -4,
    badgeColor: Color(0xFF06B6D4),
  ),

  // ── PCT & Loop of Henle ─────────────────────────────────────────────────
  NephronLandmarkTag(
    id: 'pct_sglt2',
    label: 'PCT SGLT2 Na⁺-Glucose Cotransporter',
    shortCode: 'SGLT2 (PCT)',
    category: NephronTagCategory.pctAndLoop,
    transportKinetics: '1 Na⁺ : 1 Glucose symport, reabsorbing 90% of filtered glucose.',
    targetDrug: 'Dapagliflozin / Empagliflozin (SGLT2i)',
    clinicalPearl:
        'SGLT2 inhibitors block glucose & Na+ reabsorption, delivering more NaCl to macula densa -> activates tubuloglomerular feedback, restoring afferent tone and arresting CKD progression.',
    x3D: -5,
    y3D: 45,
    z3D: 20,
    badgeColor: Color(0xFF10B981),
  ),
  NephronLandmarkTag(
    id: 'pct_brush_border',
    label: 'PCT Apical Brush Border & NHE3 Exchanger',
    shortCode: 'NHE3 (PCT)',
    category: NephronTagCategory.pctAndLoop,
    transportKinetics: 'Na⁺/H⁺ exchange coupled to carbonic anhydrase (CA-IV) HCO3⁻ recovery.',
    targetDrug: 'Acetazolamide (CA inhibitor)',
    clinicalPearl:
        'Reabsorbs 65% of filtered water, Na+, and 85% of HCO3-. CA inhibitors block HCO3- recovery, promoting urinary alkalinization and mild hyperchloremic metabolic acidosis.',
    x3D: 15,
    y3D: 35,
    z3D: 25,
    badgeColor: Color(0xFF38BDF8),
  ),
  NephronLandmarkTag(
    id: 'thin_descending_loop',
    label: 'Thin Descending Limb of Henle (AQP1)',
    shortCode: 'Thin Descending',
    category: NephronTagCategory.pctAndLoop,
    transportKinetics: 'High water permeability via AQP1; impermeable to NaCl.',
    targetDrug: 'Osmotic Diuretics (Mannitol)',
    clinicalPearl:
        'Passive water extraction concentrates tubular fluid up to 1200 mOsm/kg at the hairpin turn, matching the medullary hyperosmolar interstitium.',
    x3D: 28,
    y3D: -20,
    z3D: 15,
    badgeColor: Color(0xFF6366F1),
  ),
  NephronLandmarkTag(
    id: 'tal_nkcc2',
    label: 'Thick Ascending Limb NKCC2 Symporter',
    shortCode: 'NKCC2 (TAL)',
    category: NephronTagCategory.pctAndLoop,
    transportKinetics: 'Electroneutral 1 Na⁺ : 1 K⁺ : 2 Cl⁻ cotransport driven by basolateral Na/K-ATPase.',
    targetDrug: 'Furosemide / Bumetanide (Loop Diuretics)',
    clinicalPearl:
        'Generates the corticomedullary osmolar gradient via countercurrent multiplication. Loop diuretics inhibit NKCC2, collapsing the gradient, causing potent diuresis and Mg²⁺/Ca²⁺ wasting.',
    x3D: 18,
    y3D: -15,
    z3D: -15,
    badgeColor: Color(0xFFEC4899),
  ),
  NephronLandmarkTag(
    id: 'romk_channel',
    label: 'TAL Apical ROMK K⁺ Channel',
    shortCode: 'ROMK Channel',
    category: NephronTagCategory.pctAndLoop,
    transportKinetics: 'Recycles K⁺ back into lumen, generating a lumen-positive transepithelial potential (+8 mV).',
    targetDrug: 'Target in Bartter Syndrome Type II',
    clinicalPearl:
        'Lumen-positive potential drives paracellular reabsorption of Ca²⁺ and Mg²⁺. Inhibiting NKCC2 destroys this positive charge, explaining loop-induced hypercalciuria.',
    x3D: 12,
    y3D: 5,
    z3D: -18,
    badgeColor: Color(0xFFA855F7),
  ),

  // ── DCT & JGA (RAAS) ────────────────────────────────────────────────────
  NephronLandmarkTag(
    id: 'macula_densa',
    label: 'Macula Densa NaCl Sensor (JGA)',
    shortCode: 'Macula Densa',
    category: NephronTagCategory.dctAndJga,
    transportKinetics: 'Specialized TAL cells sensing tubular [NaCl] delivery via NKCC2.',
    targetDrug: 'Modulated by SGLT2i & ACEi',
    clinicalPearl:
        'Low luminal NaCl signals low GFR/hypotension -> stimulates Juxtaglomerular granular cells to release Renin via PGE2. High NaCl triggers adenosine release -> afferent arteriole constriction.',
    x3D: -14,
    y3D: 18,
    z3D: -8,
    badgeColor: Color(0xFFFFB300),
  ),
  NephronLandmarkTag(
    id: 'jg_granular_cells',
    label: 'Juxtaglomerular Granular Cells (Renin Secretion)',
    shortCode: 'JG Cells (Renin)',
    category: NephronTagCategory.dctAndJga,
    transportKinetics: 'Myoepithelial smooth muscle cells on afferent arteriole containing renin granules.',
    targetDrug: 'Aliskiren (Direct Renin Inhibitor)',
    clinicalPearl:
        'Cleaves hepatic Angiotensinogen to Angiotensin I. Stimulated by: 1) low afferent stretch, 2) low macula densa NaCl, and 3) β1-adrenergic sympathetic tone.',
    x3D: -22,
    y3D: 15,
    z3D: -14,
    badgeColor: Color(0xFFEAB308),
  ),
  NephronLandmarkTag(
    id: 'dct_ncct',
    label: 'DCT NCCT Na⁺-Cl⁻ Cotransporter',
    shortCode: 'NCCT (DCT)',
    category: NephronTagCategory.dctAndJga,
    transportKinetics: 'Electroneutral Na⁺-Cl⁻ cotransport reabsorbing 5-8% of filtered NaCl.',
    targetDrug: 'Hydrochlorothiazide / Chlorthalidone',
    clinicalPearl:
        'Thiazides block NCCT, promoting mild natriuresis. Lowering intracellular Na+ enhances basolateral 3Na+/Ca2+ exchange, increasing apical Ca2+ uptake -> causes Hypercalcemia and hypocalciuria.',
    x3D: -2,
    y3D: 22,
    z3D: -25,
    badgeColor: Color(0xFFFFD600),
  ),

  // ── Collecting Duct ─────────────────────────────────────────────────────
  NephronLandmarkTag(
    id: 'principal_cell_enac',
    label: 'Principal Cell ENaC Channel & Na⁺/K⁺ Exchange',
    shortCode: 'ENaC (Principal)',
    category: NephronTagCategory.collectingDuct,
    transportKinetics: 'Apical Epithelial Na⁺ Channel (ENaC) driven by basolateral Na⁺/K⁺-ATPase.',
    targetDrug: 'Amiloride / Spironolactone (MRA)',
    clinicalPearl:
        'Aldosterone upregulates ENaC & ROMK, driving Na+ reabsorption in exchange for K+ secretion. Spironolactone blocks mineralocorticoid receptor, sparing K+ at risk of Hyperkalemia.',
    x3D: -35,
    y3D: -5,
    z3D: -32,
    badgeColor: Color(0xFF10B981),
  ),
  NephronLandmarkTag(
    id: 'principal_cell_aqp2',
    label: 'Principal Cell Aquaporin-2 Water Channels (V2R)',
    shortCode: 'AQP2 (Principal)',
    category: NephronTagCategory.collectingDuct,
    transportKinetics: 'cAMP-mediated trafficking of AQP2 vesicles to apical membrane via Vasopressin V2 receptor.',
    targetDrug: 'Tolvaptan (V2 Receptor Antagonist)',
    clinicalPearl:
        'ADH/Vasopressin inserts AQP2 to reabsorb free water down medullary gradient. Tolvaptan blocks V2R, causing pure aquaresis for euvolemic/hypervolemic hyponatremia (SIADH).',
    x3D: -42,
    y3D: -25,
    z3D: -35,
    badgeColor: Color(0xFF00E5FF),
  ),
  NephronLandmarkTag(
    id: 'alpha_intercalated_h_atpase',
    label: 'α-Intercalated Cell Apical H⁺-ATPase',
    shortCode: 'H⁺-ATPase (α-IC)',
    category: NephronTagCategory.collectingDuct,
    transportKinetics: 'Active H⁺ proton extrusion into lumen; basolateral AE1 Cl⁻/HCO3⁻ exchange.',
    targetDrug: 'Defective in Type 1 Distal RTA',
    clinicalPearl:
        'Acidifies urine down to pH 4.5. Failure of H+-ATPase in Type 1 Distal RTA prevents urinary acidification (urine pH > 5.5), causing metabolic acidosis and calcium phosphate nephrolithiasis.',
    x3D: -48,
    y3D: -50,
    z3D: -38,
    badgeColor: Color(0xFFEF4444),
  ),

  // ── Whole Kidney Macro-Anatomy (Macroscale View) ─────────────────────────
  NephronLandmarkTag(
    id: 'renal_cortex',
    label: 'Renal Cortex (Glomerular Layer)',
    shortCode: 'Renal Cortex',
    category: NephronTagCategory.wholeKidney,
    transportKinetics: 'Houses 1-1.2 million glomeruli, convoluted tubules, and peritubular capillaries.',
    targetDrug: 'Target of cortical perfusion loss in ATN',
    clinicalPearl: 'Normal cortical thickness is >1.0 cm. Cortical thinning indicates chronic irreversible CKD.',
    x3D: 60,
    y3D: 40,
    z3D: 0,
    badgeColor: Color(0xFFE0E7FF),
  ),
  NephronLandmarkTag(
    id: 'medullary_pyramid',
    label: 'Renal Medullary Pyramid',
    shortCode: 'Medullary Pyramid',
    category: NephronTagCategory.wholeKidney,
    transportKinetics: 'Striated medullary rays of loops of Henle and collecting ducts with countercurrent gradient.',
    targetDrug: 'Sensitive to Medullary Hypoxia / NSAIDs / Radiocontrast',
    clinicalPearl: 'The renal medulla has low pO2 (~10-20 mmHg) making it exceptionally prone to ischemic ATN.',
    x3D: 30,
    y3D: 10,
    z3D: 0,
    badgeColor: Color(0xFF818CF8),
  ),
  NephronLandmarkTag(
    id: 'columns_of_bertin',
    label: 'Renal Columns of Bertin',
    shortCode: 'Columns Bertin',
    category: NephronTagCategory.wholeKidney,
    transportKinetics: 'Cortical tissue extensions separating adjacent medullary pyramids, routing interlobar vessels.',
    targetDrug: 'Anatomical landmark in renal ultrasound',
    clinicalPearl: 'Hypertrophied columns of Bertin can mimic renal cell pseudotumor on imaging.',
    x3D: 35,
    y3D: 28,
    z3D: 10,
    badgeColor: Color(0xFFC7D2FE),
  ),
  NephronLandmarkTag(
    id: 'renal_calyces',
    label: 'Minor & Major Calyces',
    shortCode: 'Renal Calyces',
    category: NephronTagCategory.wholeKidney,
    transportKinetics: 'Collects final concentrated urine from papillary ducts of Bellini.',
    targetDrug: 'Site of staghorn calculi (struvite)',
    clinicalPearl: 'Caliceal blunting on ultrasound or IVU is diagnostic of hydronephrosis from distal obstruction.',
    x3D: -5,
    y3D: 5,
    z3D: 0,
    badgeColor: Color(0xFF38BDF8),
  ),
  NephronLandmarkTag(
    id: 'renal_pelvis',
    label: 'Renal Pelvis & Ureteropelvic Junction (UPJ)',
    shortCode: 'Renal Pelvis / UPJ',
    category: NephronTagCategory.wholeKidney,
    transportKinetics: 'Funnel-shaped conduit propelling urine into ureter via smooth muscle peristalsis.',
    targetDrug: 'Target of UPJ obstruction surgery',
    clinicalPearl: 'UPJ obstruction is the most common cause of congenital hydronephrosis in neonates and children.',
    x3D: -25,
    y3D: -5,
    z3D: 0,
    badgeColor: Color(0xFF0284C7),
  ),
  NephronLandmarkTag(
    id: 'main_renal_artery',
    label: 'Main Renal Artery (MRA)',
    shortCode: 'Main Renal Art.',
    category: NephronTagCategory.wholeKidney,
    transportKinetics: 'Delivers 20-25% of total cardiac output (~1,200 mL/min) under systemic arterial pressure.',
    targetDrug: 'Site of Atherosclerotic & FMD Stenosis',
    clinicalPearl: 'Stenosis >60% produces refractory renovascular hypertension and ischemic nephropathy with PSV > 180 cm/s.',
    x3D: -55,
    y3D: 15,
    z3D: -5,
    badgeColor: Color(0xFFDC2626),
  ),
  NephronLandmarkTag(
    id: 'segmental_arteries',
    label: 'Segmental Renal Arteries',
    shortCode: 'Segmental Art.',
    category: NephronTagCategory.wholeKidney,
    transportKinetics: 'End-arteries dividing into apical, anterior superior/inferior, and posterior branches.',
    targetDrug: 'Sample gate for Doppler Resistive Index (RI)',
    clinicalPearl: 'Because segmental arteries are end-arteries without collaterals, occlusion causes wedge-shaped renal infarcts.',
    x3D: -15,
    y3D: 25,
    z3D: -5,
    badgeColor: Color(0xFFEF4444),
  ),
  NephronLandmarkTag(
    id: 'interlobar_arteries',
    label: 'Interlobar Arteries',
    shortCode: 'Interlobar Art.',
    category: NephronTagCategory.wholeKidney,
    transportKinetics: 'Ascend between medullary pyramids through the columns of Bertin toward the corticomedullary junction.',
    targetDrug: 'Resistive Index measurement site',
    clinicalPearl: 'Normal parenchymal Resistive Index (RI) measured here is <0.70. Elevation >0.75 indicates parenchymal injury.',
    x3D: 20,
    y3D: 30,
    z3D: 5,
    badgeColor: Color(0xFFF87171),
  ),
  NephronLandmarkTag(
    id: 'arcuate_arteries',
    label: 'Arcuate Arteries',
    shortCode: 'Arcuate Art.',
    category: NephronTagCategory.wholeKidney,
    transportKinetics: 'Arch over bases of medullary pyramids along the corticomedullary border.',
    targetDrug: 'Boundary landmark between cortex and medulla',
    clinicalPearl: 'Embolization of cholesterol atheroemboli frequently lodges in arcuate and interlobular arterioles after catheterization.',
    x3D: 45,
    y3D: 35,
    z3D: 5,
    badgeColor: Color(0xFFFB923C),
  ),
  NephronLandmarkTag(
    id: 'renal_vein',
    label: 'Main Renal Vein & Hilum Drainage',
    shortCode: 'Renal Vein',
    category: NephronTagCategory.wholeKidney,
    transportKinetics: 'Drains into IVC; left renal vein receives left gonadal and left suprarenal veins.',
    targetDrug: 'Nutcracker Syndrome & Renal Vein Thrombosis',
    clinicalPearl: 'Renal vein thrombosis is a severe complication of Nephrotic Syndrome (especially Membranous Nephropathy) due to urinary AT-III loss.',
    x3D: -50,
    y3D: -15,
    z3D: 5,
    badgeColor: Color(0xFF2563EB),
  ),

  // ── Biopsy & Pathology Landmarks ─────────────────────────────────────────
  NephronLandmarkTag(
    id: 'gbm_lamina_densa',
    label: 'Glomerular Basement Membrane (Type IV Collagen)',
    shortCode: 'GBM α3/α4/α5',
    category: NephronTagCategory.pathology,
    transportKinetics: 'Composed of type IV collagen α3α4α5 network, laminin, and heparan sulfate proteoglycans.',
    targetDrug: 'Anti-GBM (Goodpasture) / Alport syndrome',
    clinicalPearl: 'Alport syndrome is an X-linked defect in COL4A5 leading to basket-weave splitting of GBM and hereditary nephritis with sensorineural deafness.',
    x3D: -18,
    y3D: 28,
    z3D: 5,
    badgeColor: Color(0xFF14B8A6),
  ),
  NephronLandmarkTag(
    id: 'mesangial_matrix',
    label: 'Mesangial Matrix & Cells (IgA Deposition Site)',
    shortCode: 'Mesangium (IgA)',
    category: NephronTagCategory.pathology,
    transportKinetics: 'Phagocytic and contractile cells providing structural support to glomerular capillary loops.',
    targetDrug: 'Target of IgA Nephropathy (Berger disease)',
    clinicalPearl: 'IgA Nephropathy shows prominent mesangial hypercellularity and granular IgA/C3 deposition on immunofluorescence. Presents with episodic synpharyngitic gross hematuria.',
    x3D: -22,
    y3D: 22,
    z3D: 8,
    badgeColor: Color(0xFFA855F7),
  ),
  NephronLandmarkTag(
    id: 'subepithelial_space',
    label: 'Subepithelial Space (Membranous & PSGN Humps)',
    shortCode: 'Subepithelial Humps',
    category: NephronTagCategory.pathology,
    transportKinetics: 'Space between outer GBM and podocyte foot processes.',
    targetDrug: 'Membranous Nephropathy (Anti-PLA2R)',
    clinicalPearl: 'Subepithelial immune complex deposits create spike-and-dome appearance in Membranous Nephropathy, or subepithelial humps in Post-Streptococcal GN.',
    x3D: -15,
    y3D: 32,
    z3D: -8,
    badgeColor: Color(0xFFEC4899),
  ),
  NephronLandmarkTag(
    id: 'subendothelial_space',
    label: 'Subendothelial Space (Lupus Wire Loops & MPGN)',
    shortCode: 'Subendothelial Wire-Loops',
    category: NephronTagCategory.pathology,
    transportKinetics: 'Space between fenestrated endothelium and inner GBM.',
    targetDrug: 'Diffuse Proliferative Lupus Nephritis (Class IV)',
    clinicalPearl: 'Subendothelial immune complex deposits form rigid wire-loop lesions on light microscopy and cause double-contour tram-track GBM reduplication.',
    x3D: -28,
    y3D: 20,
    z3D: -2,
    badgeColor: Color(0xFFF43F5E),
  ),
];

const List<NephronLandmarkTag> kDefaultNephronTags = kNephronTags;
