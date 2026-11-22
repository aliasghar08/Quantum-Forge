// ============================================================================
// CardioCath 3D: Coronary Angiography & Hemodynamic Lab — Clinical Models
// ----------------------------------------------------------------------------
// Defines coronary anatomy, standard C-arm angiographic projections,
// pathology presets (STEMI, Catheter Damping), and molecular pharmacology links.
// Strictly uncopyrightable anatomical facts and educational parameters.
// ============================================================================

/// Standard Cath Lab C-Arm Angiographic Projections
class CArmProjectionPreset {
  final String id;
  final String name;
  final String clinicalNickname;
  final double laoRaoAngle; // Negative = RAO, Positive = LAO (-90 to +90)
  final double cranCaudAngle; // Negative = Caudal, Positive = Cranial (-45 to +45)
  final String vesselsOptimized;
  final String educationalRationale;

  const CArmProjectionPreset({
    required this.id,
    required this.name,
    required this.clinicalNickname,
    required this.laoRaoAngle,
    required this.cranCaudAngle,
    required this.vesselsOptimized,
    required this.educationalRationale,
  });

  String get formattedAngles {
    final lr = laoRaoAngle < 0
        ? 'RAO ${(-laoRaoAngle).round()}°'
        : (laoRaoAngle > 0 ? 'LAO ${laoRaoAngle.round()}°' : 'AP 0°');
    final cc = cranCaudAngle < 0
        ? 'Caudal ${(-cranCaudAngle).round()}°'
        : (cranCaudAngle > 0 ? 'Cranial ${cranCaudAngle.round()}°' : 'Straight 0°');
    return '$lr / $cc';
  }
}

const List<CArmProjectionPreset> kCArmPresets = [
  CArmProjectionPreset(
    id: 'lao_cranial',
    name: 'LAO Cranial',
    clinicalNickname: 'LAD Profiler',
    laoRaoAngle: 40.0,
    cranCaudAngle: 30.0,
    vesselsOptimized: 'Mid & Distal LAD, Diagonal Branches',
    educationalRationale:
        'Lays out the mid and distal LAD along with diagonal bifurcation without foreshortening.',
  ),
  CArmProjectionPreset(
    id: 'rao_caudal',
    name: 'RAO Caudal',
    clinicalNickname: 'Spider View',
    laoRaoAngle: -20.0,
    cranCaudAngle: -30.0,
    vesselsOptimized: 'Left Main (LM) Bifurcation, Proximal LAD, Proximal LCx',
    educationalRationale:
        'The gold-standard view to inspect distal Left Main stem division into LAD and Circumflex.',
  ),
  CArmProjectionPreset(
    id: 'ap_cranial',
    name: 'AP Cranial',
    clinicalNickname: 'Septal View',
    laoRaoAngle: 0.0,
    cranCaudAngle: 30.0,
    vesselsOptimized: 'LAD, Septal Perforators',
    educationalRationale:
        'Elongates the vertical course of the LAD through the anterior interventricular sulcus.',
  ),
  CArmProjectionPreset(
    id: 'lao_caudal',
    name: 'LAO Caudal',
    clinicalNickname: 'Hepatic View',
    laoRaoAngle: 45.0,
    cranCaudAngle: -20.0,
    vesselsOptimized: 'Left Circumflex (LCx), Obtuse Marginals (OM)',
    educationalRationale:
        'Opens up the Left Circumflex artery and obtuse marginal branches as they course in the AV groove.',
  ),
  CArmProjectionPreset(
    id: 'rao_cranial',
    name: 'RAO Cranial',
    clinicalNickname: 'Mid-LAD View',
    laoRaoAngle: -30.0,
    cranCaudAngle: 30.0,
    vesselsOptimized: 'Mid-LAD, Distal Diagonal Takeoffs',
    educationalRationale:
        'Visualizes diagonal origin takeoff angles and mid-segment coronary plaques.',
  ),
  CArmProjectionPreset(
    id: 'lao_straight',
    name: 'LAO Straight',
    clinicalNickname: 'RCA C-Shape',
    laoRaoAngle: 40.0,
    cranCaudAngle: 0.0,
    vesselsOptimized: 'Right Coronary Artery (RCA) Trunk',
    educationalRationale:
        'Displays the classical C-shaped profile of the entire proximal, mid, and distal RCA.',
  ),
];

/// Coronary vessel branch definition
enum CoronaryVesselBranch {
  aorticRoot,
  leftMain,
  lad,
  diagonal,
  lcx,
  obtuseMarginal,
  rca,
  pda,
}

/// Coronary Circulation Dominance (MBBS / Board Anatomy Core)
enum CoronaryDominance {
  rightDominant(
    'Right-Dominant (85%)',
    'PDA originates from distal RCA; supplies posterior septum & inferior LV wall.',
  ),
  leftDominant(
    'Left-Dominant (8%)',
    'PDA originates from distal LCx; RCA is small and non-dominant.',
  ),
  coDominant(
    'Co-Dominant (7%)',
    'Posterior descending branches arise from both distal RCA and distal LCx.',
  );

  final String label;
  final String description;
  const CoronaryDominance(this.label, this.description);
}

/// Multi-Lead 12-Lead ECG Territory Switcher
enum EcgTerritoryLead {
  leadII('Lead II', 'Systemic rhythm vector & baseline monitoring', 'II'),
  v1V4Anterior('V1–V4 (Anterior)', 'Anteroseptal wall; culprit LAD artery', 'V1–V4'),
  inferiorLeads('II, III, aVF (Inferior)', 'Inferior wall; culprit RCA artery', 'II, III, aVF'),
  lateralLeads('I, aVL, V5–V6 (Lateral)', 'Lateral free wall; culprit LCx artery', 'I, aVL');

  final String label;
  final String description;
  final String shortLabel;
  const EcgTerritoryLead(this.label, this.description, this.shortLabel);
}

/// Cath Lab OSCE Challenge Case Model
class OsceCathCase {
  final String id;
  final String scenarioId;
  final String clinicalVignette;
  final String targetOptimalView;
  final String targetOptimalProjectionId;
  final List<String> vesselChoices;
  final String correctVessel;
  final List<String> treatmentChoices;
  final String correctTreatment;
  final String contraindicationWarning;
  final String teachingPearl;

  const OsceCathCase({
    required this.id,
    required this.scenarioId,
    required this.clinicalVignette,
    required this.targetOptimalView,
    required this.targetOptimalProjectionId,
    required this.vesselChoices,
    required this.correctVessel,
    required this.treatmentChoices,
    required this.correctTreatment,
    required this.contraindicationWarning,
    required this.teachingPearl,
  });

  String get title {
    switch (scenarioId) {
      case 'anterior_stemi_lad':
        return 'Anterior STEMI';
      case 'inferior_mi_rca':
        return 'Inferior MI';
      case 'lm_stenosis_damping':
        return 'Left Main Damping';
      default:
        return 'Cath Case';
    }
  }

  String get prompt => clinicalVignette;
  String get culpritArtery => correctVessel;
  String get correctPharmacology => correctTreatment;
  String get rationale => '$teachingPearl\n\nCONTRAINDICATION / WARNING: $contraindicationWarning';

  double get targetLaoRao {
    switch (targetOptimalProjectionId) {
      case 'lao_cranial':
        return 40.0;
      case 'lao_straight':
        return 40.0;
      case 'rao_caudal':
        return -25.0;
      default:
        return 0.0;
    }
  }

  double get targetCranCaud {
    switch (targetOptimalProjectionId) {
      case 'lao_cranial':
        return 30.0;
      case 'lao_straight':
        return 0.0;
      case 'rao_caudal':
        return -30.0;
      default:
        return 0.0;
    }
  }
}

const List<OsceCathCase> kOsceCathCases = [
  OsceCathCase(
    id: 'osce_case_anterior_stemi',
    scenarioId: 'anterior_stemi_lad',
    clinicalVignette:
        '58-year-old male arrives in emergency 45 min after crushing substernal chest pain radiating to left arm. ECG shows hyperacute T waves and ST elevation across V1-V4. Diagnostic catheter engages left main coronary ostium.',
    targetOptimalView: 'LAO Cranial or RAO Caudal (Spider View)',
    targetOptimalProjectionId: 'lao_cranial',
    vesselChoices: [
      'LAD (Left Anterior Descending)',
      'LCx (Left Circumflex)',
      'RCA (Right Coronary Artery)',
      'PDA (Posterior Descending Artery)',
    ],
    correctVessel: 'LAD (Left Anterior Descending)',
    treatmentChoices: [
      'Deploy PCI Stent + Dual Antiplatelet (Aspirin + P2Y12)',
      'Administer Intracoronary Nitroglycerin bolus only',
      'Discharge on oral Beta-blocker without stenting',
      'Administer IV Calcium Gluconate',
    ],
    correctTreatment: 'Deploy PCI Stent + Dual Antiplatelet (Aspirin + P2Y12)',
    contraindicationWarning:
        'Delaying primary PCI revascularization beyond 90 min door-to-balloon window exponentially increases transmural myocardial necrosis and free wall rupture risk.',
    teachingPearl:
        'Proximal LAD occlusion ("Widowmaker") threatens the anterior LV free wall and bundle branches. Prompt primary stenting restores TIMI 3 flow and aborts cardiogenic shock.',
  ),
  OsceCathCase(
    id: 'osce_case_inferior_mi',
    scenarioId: 'inferior_mi_rca',
    clinicalVignette:
        '64-year-old female presents with epigastric pain, diaphoresis, nausea, and marked hypotension (BP: 85/50 mmHg, HR: 48 bpm). ECG reveals ST elevation in leads II, III, aVF.',
    targetOptimalView: 'LAO Straight (40° LAO / 0°)',
    targetOptimalProjectionId: 'lao_straight',
    vesselChoices: [
      'RCA (Right Coronary Artery)',
      'LAD (Left Anterior Descending)',
      'Left Main Stem',
      'Obtuse Marginal (OM)',
    ],
    correctVessel: 'RCA (Right Coronary Artery)',
    treatmentChoices: [
      'IV Normal Saline fluid bolus + Atropine + PCI Revascularization',
      'Sublingual Nitroglycerin 0.4 mg repeat x3',
      'Immediate IV Beta-Blocker (Metoprolol 5 mg)',
      'Oral Diltiazem for rate control',
    ],
    correctTreatment:
        'IV Normal Saline fluid bolus + Atropine + PCI Revascularization',
    contraindicationWarning:
        'Nitrates and diuretics are CONTRAINDICATED in inferior MI with RV involvement because RV preload is severely compromised; nitrates trigger catastrophic circulatory collapse.',
    teachingPearl:
        'RCA supplies the SA node in 60% and AV node in 90% of patients. Ischemic sinus bradycardia responds to Atropine and volume loading; avoid nitrate-induced preload reduction.',
  ),
  OsceCathCase(
    id: 'osce_case_lm_damping',
    scenarioId: 'lm_stenosis_damping',
    clinicalVignette:
        'Diagnostic catheter advances into the aortic root and engages the left coronary ostium. Immediately, the aortic pressure monitor drops from 125/82 to 85/35 mmHg with loss of dicrotic notch.',
    targetOptimalView: 'RAO Caudal (Spider View)',
    targetOptimalProjectionId: 'rao_caudal',
    vesselChoices: [
      'Left Main (LM) Ostial Stenosis',
      'Distal LAD Perforator',
      'Right Marginal Artery',
      'Non-coronary sinus wedging',
    ],
    correctVessel: 'Left Main (LM) Ostial Stenosis',
    treatmentChoices: [
      'Immediate Catheter Disengagement / Withdrawal into Ascending Aorta',
      'Advance catheter deeper into Left Main trunk',
      'Inject 10 mL contrast dye forcefully under high pressure',
      'Administer high-dose IV Adenosine',
    ],
    correctTreatment:
        'Immediate Catheter Disengagement / Withdrawal into Ascending Aorta',
    contraindicationWarning:
        'Injecting dye or keeping a wedged catheter in an ostial Left Main stenosis causes total antegrade perfusion arrest and triggers refractory ventricular fibrillation.',
    teachingPearl:
        'Pressure damping or ventricularization occurs when the catheter tip seals an ostial stenosis. The operator must immediately disengage the catheter to restore coronary blood flow.',
  ),
];

/// Cardiac Clinical Pathology Scenario
class CardiacPathologyScenario {
  final String id;
  final String title;
  final String subtitle;
  final String anatomicalLesion;
  final double ladStenosisFraction; // 0.0 = patent, 1.0 = total occlusion
  final double lcxStenosisFraction;
  final double rcaStenosisFraction;
  final double baselineBpm;
  final double systolicBp;
  final double diastolicBp;
  final double stElevationMm; // Positive = elevation, Negative = depression
  final bool isCatheterDamped;
  final bool isRevascularized;
  final String ecgFindings;
  final String clinicalPearls;
  final List<CardiacDrugMechanismLink> linkedDrugs;

  const CardiacPathologyScenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.anatomicalLesion,
    this.ladStenosisFraction = 0.0,
    this.lcxStenosisFraction = 0.0,
    this.rcaStenosisFraction = 0.0,
    this.baselineBpm = 72.0,
    this.systolicBp = 120.0,
    this.diastolicBp = 80.0,
    this.stElevationMm = 0.0,
    this.isCatheterDamped = false,
    this.isRevascularized = false,
    required this.ecgFindings,
    required this.clinicalPearls,
    required this.linkedDrugs,
  });

  CardiacPathologyScenario copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? anatomicalLesion,
    double? ladStenosisFraction,
    double? lcxStenosisFraction,
    double? rcaStenosisFraction,
    double? baselineBpm,
    double? systolicBp,
    double? diastolicBp,
    double? stElevationMm,
    bool? isCatheterDamped,
    bool? isRevascularized,
    String? ecgFindings,
    String? clinicalPearls,
    List<CardiacDrugMechanismLink>? linkedDrugs,
  }) {
    return CardiacPathologyScenario(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      anatomicalLesion: anatomicalLesion ?? this.anatomicalLesion,
      ladStenosisFraction: ladStenosisFraction ?? this.ladStenosisFraction,
      lcxStenosisFraction: lcxStenosisFraction ?? this.lcxStenosisFraction,
      rcaStenosisFraction: rcaStenosisFraction ?? this.rcaStenosisFraction,
      baselineBpm: baselineBpm ?? this.baselineBpm,
      systolicBp: systolicBp ?? this.systolicBp,
      diastolicBp: diastolicBp ?? this.diastolicBp,
      stElevationMm: stElevationMm ?? this.stElevationMm,
      isCatheterDamped: isCatheterDamped ?? this.isCatheterDamped,
      isRevascularized: isRevascularized ?? this.isRevascularized,
      ecgFindings: ecgFindings ?? this.ecgFindings,
      clinicalPearls: clinicalPearls ?? this.clinicalPearls,
      linkedDrugs: linkedDrugs ?? this.linkedDrugs,
    );
  }
}

/// Pharmacological Drug Link for the Molecular Bridge
class CardiacDrugMechanismLink {
  final String genericName;
  final String drugClass;
  final String molecularTarget;
  final String biochemicalMechanism;
  final String clinicalRoleInCathLab;
  final String? quantumReactionTemplateId;

  const CardiacDrugMechanismLink({
    required this.genericName,
    required this.drugClass,
    required this.molecularTarget,
    required this.biochemicalMechanism,
    required this.clinicalRoleInCathLab,
    this.quantumReactionTemplateId,
  });
}

const List<CardiacPathologyScenario> kCardiacScenarios = [
  CardiacPathologyScenario(
    id: 'normal_coronary',
    title: 'Normal Coronary Circulation (Right-Dominant)',
    subtitle: 'Patent Left and Right Coronary Trees with Normal Hemodynamics',
    anatomicalLesion: 'No significant atherosclerotic stenosis; TIMI 3 normal distal flow.',
    ladStenosisFraction: 0.0,
    lcxStenosisFraction: 0.0,
    rcaStenosisFraction: 0.0,
    baselineBpm: 72.0,
    systolicBp: 120.0,
    diastolicBp: 80.0,
    stElevationMm: 0.0,
    isCatheterDamped: false,
    ecgFindings: 'Normal Sinus Rhythm (NSR). Isoelectric ST segment, upright T waves in Lead II.',
    clinicalPearls:
        '85% of humans have right-dominant coronary circulation where the posterior descending artery (PDA) arises from the RCA. Standard diagnostic cath evaluates vessel diameters and branches.',
    linkedDrugs: [
      CardiacDrugMechanismLink(
        genericName: 'Aspirin (Acetylsalicylic Acid)',
        drugClass: 'Antiplatelet / Irreversible COX Inhibitor',
        molecularTarget: 'Cyclooxygenase-1 (COX-1) Ser-530',
        biochemicalMechanism:
            'Irreversibly acetylates Ser-530 in COX-1, permanently suppressing Thromboxane A2 (TXA2) generation across platelet lifespan.',
        clinicalRoleInCathLab: 'Pre-procedure antiplatelet prophylaxis for diagnostic or interventional catheterization.',
        quantumReactionTemplateId: 'aspirin_synthesis',
      ),
      CardiacDrugMechanismLink(
        genericName: 'Nitroglycerin (Glyceryl Trinitrate)',
        drugClass: 'Coronary Vasodilator / Organic Nitrate',
        molecularTarget: 'Mitochondrial Aldehyde Dehydrogenase 2 (ALDH2)',
        biochemicalMechanism:
            'Bioactivated by ALDH2 to release nitric oxide (NO), activating soluble guanylyl cyclase (sGC) to elevate cGMP and relax vascular smooth muscle.',
        clinicalRoleInCathLab: 'Administered intracoronary (100-200 mcg) to relieve catheter-induced vasospasm and optimize vessel caliber.',
      ),
    ],
  ),
  CardiacPathologyScenario(
    id: 'anterior_stemi_lad',
    title: 'Acute Anterior STEMI (95% Proximal LAD Occlusion)',
    subtitle: 'Critical "Widowmaker" Lesion with Acute Anteroseptal Ischemia',
    anatomicalLesion: '95% eccentric plaque ulceration and subtotal thrombosis in proximal LAD artery.',
    ladStenosisFraction: 0.95,
    lcxStenosisFraction: 0.0,
    rcaStenosisFraction: 0.0,
    baselineBpm: 92.0,
    systolicBp: 104.0,
    diastolicBp: 68.0,
    stElevationMm: 4.5,
    isCatheterDamped: false,
    ecgFindings: 'Marked ST-Segment Elevation (+4.5 mm) with tombstone morphology; reciprocal ST depression in III/aVF.',
    clinicalPearls:
        'The proximal LAD supplies >45% of left ventricular myocardium. Acute occlusion mandates emergent Primary PCI with goal Door-to-Balloon (D2B) time < 90 minutes to prevent cardiogenic shock.',
    linkedDrugs: [
      CardiacDrugMechanismLink(
        genericName: 'Aspirin',
        drugClass: 'Antiplatelet',
        molecularTarget: 'Platelet COX-1 Ser-530',
        biochemicalMechanism: 'Immediate 325 mg chewed dose blocks thromboxane-dependent platelet recruitment.',
        clinicalRoleInCathLab: 'Core loading antiplatelet mandatory in all STEMI protocols.',
        quantumReactionTemplateId: 'aspirin_synthesis',
      ),
      CardiacDrugMechanismLink(
        genericName: 'Clopidogrel / Ticagrelor',
        drugClass: 'P2Y12 Receptor Antagonist',
        molecularTarget: 'Platelet P2Y12 Purinergic Receptor',
        biochemicalMechanism:
            'Clopidogrel requires 2-step CYP2C19 bioactivation to an active thiol metabolite that covalently inactivates ADP P2Y12 receptors.',
        clinicalRoleInCathLab: 'Dual antiplatelet therapy (DAPT) loading dose (300-600 mg) prior to coronary stent deployment.',
      ),
      CardiacDrugMechanismLink(
        genericName: 'Unfractionated Heparin (UFH)',
        drugClass: 'Anticoagulant',
        molecularTarget: 'Antithrombin III (AT-III) / Thrombin (IIa) & Factor Xa',
        biochemicalMechanism: 'Binds AT-III via a specific pentasaccharide sequence to accelerate inactivation of Factor Xa and Thrombin 1,000-fold.',
        clinicalRoleInCathLab: 'IV bolus (70-100 U/kg) maintaining activated clotting time (ACT) between 250-300 seconds during PCI.',
      ),
    ],
  ),
  CardiacPathologyScenario(
    id: 'inferior_mi_rca',
    title: 'Acute Inferior MI (100% Mid-RCA Occlusion)',
    subtitle: 'Total Cutoff of Right Coronary with Sinus Bradycardia',
    anatomicalLesion: 'Abrupt 100% TIMI 0 cutoff in mid-RCA segment with complete absence of distal PDA/PLV perfusion.',
    ladStenosisFraction: 0.0,
    lcxStenosisFraction: 0.0,
    rcaStenosisFraction: 1.0,
    baselineBpm: 52.0,
    systolicBp: 96.0,
    diastolicBp: 62.0,
    stElevationMm: 3.2,
    isCatheterDamped: false,
    ecgFindings: 'Sinus Bradycardia (52 bpm) with ST elevation in leads II, III, aVF (ST in III > II) indicating RCA culprit.',
    clinicalPearls:
        'RCA supplies the SA node (in 60%) and AV node (in 90%). Acute occlusion often causes ischemic bradycardia or high-grade AV block. Preload sensitivity is critical; avoid nitrates if right ventricular infarction is coexistent.',
    linkedDrugs: [
      CardiacDrugMechanismLink(
        genericName: 'Atropine Sulfate',
        drugClass: 'Antimuscarinic Parasympatholytic',
        molecularTarget: 'M2 Muscarinic Acetylcholine Receptors',
        biochemicalMechanism: 'Competitively antagonizes acetylcholine at cardiac M2 receptors, increasing SA nodal automaticity and AV nodal conduction velocity.',
        clinicalRoleInCathLab: 'First-line antidote for symptomatic bradycardia or transient Bezold-Jarisch reflex during RCA reperfusion.',
      ),
      CardiacDrugMechanismLink(
        genericName: 'Atorvastatin',
        drugClass: 'HMG-CoA Reductase Inhibitor',
        molecularTarget: 'Hepatic HMG-CoA Reductase',
        biochemicalMechanism: 'Competitive inhibitor that suppresses cholesterol biosynthesis, upregulates LDL receptors, and exerts rapid pleiotropic anti-inflammatory stabilization on fibrous caps.',
        clinicalRoleInCathLab: 'High-intensity statin (80 mg) initiated immediately regardless of baseline LDL.',
      ),
    ],
  ),
  CardiacPathologyScenario(
    id: 'lm_stenosis_damping',
    title: 'Critical Left Main Stenosis & Catheter Damping',
    subtitle: 'Ostial Wedging Causing Pressure Ventricularization',
    anatomicalLesion: '85% ostial stenosis of the Left Main trunk with guide catheter occlusion during ostial engagement.',
    ladStenosisFraction: 0.50,
    lcxStenosisFraction: 0.50,
    rcaStenosisFraction: 0.0,
    baselineBpm: 84.0,
    systolicBp: 85.0,
    diastolicBp: 35.0,
    stElevationMm: -2.0, // Subendocardial depression
    isCatheterDamped: true,
    ecgFindings: 'Diffuse ST-segment depression with reciprocal ST elevation in lead aVR; marked hemodynamic pressure damping.',
    clinicalPearls:
        'When the guide catheter tip wedges into a stenotic ostium, the arterial pressure trace is damped or ventricularized (systolic pressure drops and diastolic decays towards zero, mimicking an LV tracing). The operator MUST immediately disengage the catheter to restore coronary flow and prevent ventricular fibrillation!',
    linkedDrugs: [
      CardiacDrugMechanismLink(
        genericName: 'Nitroglycerin Intracoronary',
        drugClass: 'Vasodilator',
        molecularTarget: 'Vascular Smooth Muscle Guanylyl Cyclase',
        biochemicalMechanism: 'Relieves secondary ostial vasospasm once catheter is retracted.',
        clinicalRoleInCathLab: 'Diagnostic test to differentiate fixed anatomical ostial stenosis from catheter-induced spasm.',
      ),
    ],
  ),
];
