// ============================================================================
// PulmoVent 3D: Micro-Anatomical Pulmonary Landmark & Tag Models
// ----------------------------------------------------------------------------
// 22 Dynamic 3D Projected Landmark Tags with USMLE / Critical Care Board pearls
// categorized across: Conducting Airways, Alveolar Micro, Vasculature, and Pleura.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

enum PulmoTagCategory {
  all('All Structures'),
  conducting('Conducting Airways (Gen 0–16)'),
  alveolar('Alveolar Micro & Gas Exchange'),
  vasculature('Pulmonary Vasculature & Shunt'),
  pleura('Pleura & Chest Wall');

  final String label;
  const PulmoTagCategory(this.label);
}

class PulmoLandmarkTag {
  final String id;
  final String name;
  final String shortName;
  final PulmoTagCategory category;
  final double x; // Relative -1.0 to 1.0
  final double y; // Relative -1.0 to 1.0
  final String clinicalPearl;
  final String usmleQuestion;
  final String boardAnswer;

  const PulmoLandmarkTag({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.x,
    required this.y,
    required this.clinicalPearl,
    required this.usmleQuestion,
    required this.boardAnswer,
  });
}

const List<PulmoLandmarkTag> kPulmoTags = [
  PulmoLandmarkTag(
    id: 'trachea_cartilage',
    name: 'Trachea & C-Shaped Hyaline Cartilage',
    shortName: 'Trachea (Gen 0)',
    category: PulmoTagCategory.conducting,
    x: 0.0,
    y: -0.65,
    clinicalPearl:
        'Contains 16-20 C-shaped hyaline cartilage rings with a posterior membranous wall adjacent to the esophagus. Prevents tracheal collapse during forced expiration.',
    usmleQuestion: 'Why does the trachea contain open C-shaped cartilage rather than continuous circular rings?',
    boardAnswer: 'Allows esophageal expansion during food bolus deglutition while preventing airway collapse under negative intrathoracic pressures.',
  ),
  PulmoLandmarkTag(
    id: 'carina',
    name: 'Carina Tracheae (T4/T5 Angle of Louis)',
    shortName: 'Carina (Gen 1)',
    category: PulmoTagCategory.conducting,
    x: 0.0,
    y: -0.15,
    clinicalPearl:
        'The most sensitive cough-reflex zone, innervated by vagal sensory fibers. Lies at the T4/T5 vertebral disc, corresponding to the sternal angle of Louis.',
    usmleQuestion: 'Endotracheal tube position on chest radiograph should ideally terminate how far above the carina?',
    boardAnswer: '3 to 5 cm above the carina to avoid endobronchial intubation of the right mainstem during neck flexion.',
  ),
  PulmoLandmarkTag(
    id: 'right_main_bronchus',
    name: 'Right Mainstem Bronchus',
    shortName: 'Right Main (Gen 1)',
    category: PulmoTagCategory.conducting,
    x: 0.28,
    y: -0.05,
    clinicalPearl:
        'Shorter (~2.5 cm), wider, and steeper (~25° off midline). Common site for foreign-body aspiration (peanuts, teeth) and accidental right-mainstem intubation.',
    usmleQuestion: 'Why is aspirated foreign material significantly more likely to enter the right mainstem than the left?',
    boardAnswer: 'The right main bronchus is wider, shorter, and takes a more vertical course aligned with the trachea.',
  ),
  PulmoLandmarkTag(
    id: 'left_main_bronchus',
    name: 'Left Mainstem Bronchus',
    shortName: 'Left Main (Gen 1)',
    category: PulmoTagCategory.conducting,
    x: -0.35,
    y: -0.02,
    clinicalPearl:
        'Longer (~5 cm), narrower, and takes a more horizontal angle (~45°) under the aortic arch to accommodate the heart.',
    usmleQuestion: 'Compression of the left main bronchus by massive left atrial enlargement (Ortner syndrome) can cause:',
    boardAnswer: 'Hoarseness due to recurrent laryngeal nerve palsy and chronic dry cough from mechanical bronchial impingement.',
  ),
  PulmoLandmarkTag(
    id: 'terminal_bronchiole',
    name: 'Terminal Bronchiole (Gen 16)',
    shortName: 'Terminal Bronchiole',
    category: PulmoTagCategory.conducting,
    x: 0.55,
    y: 0.15,
    clinicalPearl:
        'Last generation of the conducting zone (anatomic dead space ~150 mL). Lacks cartilage and submucosal glands; lined by simple ciliated cuboidal epithelium and Club (Clara) cells.',
    usmleQuestion: 'What is the primary function of Club (Clara) cells located in terminal and respiratory bronchioles?',
    boardAnswer: 'Secretion of CC16 protective uteroglobin-like proteins, xenobiotic detox via cytochrome P450, and stem cell regeneration.',
  ),
  PulmoLandmarkTag(
    id: 'type1_pneumocyte',
    name: 'Type I Alveolar Epithelial Cell (Squamous)',
    shortName: 'Type I Pneumocyte',
    category: PulmoTagCategory.alveolar,
    x: 0.15,
    y: 0.35,
    clinicalPearl:
        'Covers 95% of alveolar surface area. Ultra-thin (0.1–0.2 μm) cytoplasm optimized for passive Fickian gas diffusion of O2 and CO2 across the basement membrane.',
    usmleQuestion: 'Why are Type I pneumocytes extremely vulnerable to irreversible damage in ARDS?',
    boardAnswer: 'They are end-differentiated and cannot divide; damaged Type I cells must be replaced via hyperplasia of Type II pneumocytes.',
  ),
  PulmoLandmarkTag(
    id: 'type2_pneumocyte',
    name: 'Type II Pneumocyte (Dipalmitoylphosphatidylcholine)',
    shortName: 'Type II Pneumocyte',
    category: PulmoTagCategory.alveolar,
    x: -0.18,
    y: 0.38,
    clinicalPearl:
        'Cuboidal surfactant-secreting stem cells. Store DPPC surfactant in lamellar bodies. Reduces surface tension (Laplace law P=2T/r), preventing small-alveolus atelectasis.',
    usmleQuestion: 'In Neonatal Respiratory Distress Syndrome (NRDS), deficiency of which phospholipid leads to diffuse atelectasis?',
    boardAnswer: 'Dipalmitoylphosphatidylcholine (DPPC), the primary active component of pulmonary surfactant.',
  ),
  PulmoLandmarkTag(
    id: 'blood_gas_barrier',
    name: 'Alveolar-Capillary Membrane (0.5 μm Barrier)',
    shortName: 'Blood-Gas Barrier',
    category: PulmoTagCategory.alveolar,
    x: 0.02,
    y: 0.48,
    clinicalPearl:
        'Tri-laminar membrane consisting of Type I pneumocyte, fused basal lamina, and capillary endothelial cell. Total thickness ~0.2-0.5 μm. Diffusion capacity DLCO drops in fibrosis.',
    usmleQuestion: 'Which physiological law governs gas transfer across the alveolar-capillary barrier?',
    boardAnswer: 'Fick’s Law of Diffusion: Rate = (Surface Area × Diffusion Constant × ΔPressure) / Membrane Thickness.',
  ),
  PulmoLandmarkTag(
    id: 'alveolar_macrophage',
    name: 'Alveolar Macrophage (Dust Cell / Hemosiderin)',
    shortName: 'Alveolar Macrophage',
    category: PulmoTagCategory.alveolar,
    x: -0.28,
    y: 0.42,
    clinicalPearl:
        'Phagocytoses inhaled silica, asbestos, and bacteria. In left heart failure with pulmonary congestion, engulfs extravasated RBCs becoming "heart failure cells" (hemosiderin-laden).',
    usmleQuestion: 'What stain demonstrates hemosiderin-laden macrophages in sputum or bronchoalveolar lavage?',
    boardAnswer: 'Prussian Blue (Perls) stain highlights ferric iron deposits in alveolar macrophages.',
  ),
  PulmoLandmarkTag(
    id: 'west_zone_1',
    name: 'West Zone 1: Apical Lung (PA > Pa > Pv)',
    shortName: 'West Zone 1 (Apex)',
    category: PulmoTagCategory.vasculature,
    x: 0.38,
    y: -0.45,
    clinicalPearl:
        'Alveolar pressure exceeds arterial pressure, compressing capillaries. Normally negligible, but expands during positive-pressure ventilation or hypovolemic shock, creating alveolar dead space.',
    usmleQuestion: 'What occurs physiologically in West Zone 1 when a hypovolemic patient receives high PEEP?',
    boardAnswer: 'Alveolar pressure compresses pulmonary capillaries entirely, abolishing perfusion and creating high alveolar dead space (V/Q = ∞).',
  ),
  PulmoLandmarkTag(
    id: 'west_zone_2',
    name: 'West Zone 2: Mid Lung (Pa > PA > Pv)',
    shortName: 'West Zone 2 (Waterfall)',
    category: PulmoTagCategory.vasculature,
    x: 0.45,
    y: -0.15,
    clinicalPearl:
        'Waterfall or Starling resistor flow: blood flow is determined by the arterial-to-alveolar pressure gradient (Pa - PA), independent of downstream venous pressure.',
    usmleQuestion: 'In West Zone 2, blood flow is directly determined by the difference between which two pressures?',
    boardAnswer: 'Pulmonary arterial pressure (Pa) and alveolar pressure (PA).',
  ),
  PulmoLandmarkTag(
    id: 'west_zone_3',
    name: 'West Zone 3: Basal Dependent Lung (Pa > Pv > PA)',
    shortName: 'West Zone 3 (Base)',
    category: PulmoTagCategory.vasculature,
    x: 0.42,
    y: 0.25,
    clinicalPearl:
        'Continuous blood flow through fully distended capillaries. Highest perfusion and ventilation, with V/Q ~0.6. Site of dependent consolidations and intrapulmonary shunt in ARDS.',
    usmleQuestion: 'Why does prone positioning in severe ARDS improve oxygenation?',
    boardAnswer: 'Recruits dense dependent dorsal lung units (Zone 3) while shifting heart and abdominal weight off the posterior parenchyma.',
  ),
  PulmoLandmarkTag(
    id: 'visceral_pleura',
    name: 'Visceral Pleura (Lung Surface)',
    shortName: 'Visceral Pleura',
    category: PulmoTagCategory.pleura,
    x: 0.62,
    y: -0.1,
    clinicalPearl:
        'Adheres tightly to all lung surfaces and fissures. Innervated by autonomic nerves (insensitive to sharp somatic pain). Rupture of subpleural apical blebs causes primary spontaneous pneumothorax.',
    usmleQuestion: 'Why is visceral pleural irritation perceived as dull ache while parietal pleural irritation causes sharp localized pain?',
    boardAnswer: 'Visceral pleura receives autonomic innervation; parietal pleura is innervated by intercostal and phrenic somatic nerves.',
  ),
  PulmoLandmarkTag(
    id: 'parietal_pleura',
    name: 'Parietal Pleura (Chest Wall / Phrenic)',
    shortName: 'Parietal Pleura',
    category: PulmoTagCategory.pleura,
    x: -0.68,
    y: 0.05,
    clinicalPearl:
        'Lines the thoracic cavity. Mediastinal and diaphragmatic parietal pleura are innervated by the phrenic nerve (C3-C5), referring pain to the ipsilateral shoulder dermatome.',
    usmleQuestion: 'Irritation of the central diaphragmatic parietal pleura refers pain to which anatomical region?',
    boardAnswer: 'The C3–C5 dermatome over the shoulder (Kehr sign) via phrenic nerve sensory afferents.',
  ),
  PulmoLandmarkTag(
    id: 'costophrenic_recess',
    name: 'Costophrenic Recess (Angle of Fluid Accumulation)',
    shortName: 'Costophrenic Recess',
    category: PulmoTagCategory.pleura,
    x: -0.52,
    y: 0.58,
    clinicalPearl:
        'Deepest potential space in the pleural cavity. Normal lateral angle is sharp; blunting on upright PA chest radiograph requires ~175–200 mL of pleural effusion.',
    usmleQuestion: 'What is the minimal volume of pleural fluid required to blunt the costophrenic angle on an upright frontal chest radiograph?',
    boardAnswer: 'Approximately 175 to 200 mL (compared to ~50 mL visible on a lateral film).',
  ),
  PulmoLandmarkTag(
    id: 'diaphragm_dome',
    name: 'Diaphragm (Phrenic Nerve C3, 4, 5)',
    shortName: 'Diaphragm Dome',
    category: PulmoTagCategory.pleura,
    x: 0.0,
    y: 0.68,
    clinicalPearl:
        'Primary muscle of inspiration. Contraction flattens the dome, increasing vertical thoracic volume and creating negative intrapleural pressure (-5 to -8 cmH2O).',
    usmleQuestion: 'Unilateral phrenic nerve transection results in what characteristic finding on upright chest radiography?',
    boardAnswer: 'Paradoxical elevation of the ipsilateral hemidiaphragm during inspiration (sniff test fluoroscopy).',
  ),
  PulmoLandmarkTag(
    id: 'vv_ecmo_cannula',
    name: 'V-V ECMO Jugular Return Cannula',
    shortName: 'V-V ECMO Cannula',
    category: PulmoTagCategory.vasculature,
    x: 0.12,
    y: -0.52,
    clinicalPearl:
        'Reinfuses oxygenated, decarboxylated blood from the membrane lung directly into the right atrium towards the tricuspid valve for refractory hypoxemic ARDS.',
    usmleQuestion: 'What is the primary physiological objective of V-V ECMO compared to V-A ECMO?',
    boardAnswer: 'Provides pure respiratory gas exchange (O2 addition and CO2 removal) while relying entirely on native heart function for cardiac output.',
  ),
];
