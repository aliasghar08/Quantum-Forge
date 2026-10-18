// ============================================================================
// Clinical & Veterinary Pharmacopeia Database for Quantum Forge
// Research-level compendium for MBBS, Pharm-D, DVM and Specialist Practitioners.
// ============================================================================

import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';

const List<MedicinePharmacologyProfile> kClinicalPharmacopeiaDatabase = [
  // ── CARDIOLOGY & HEMODYNAMICS ─────────────────────────────────────────────
  MedicinePharmacologyProfile(
    id: 'pharma-aspirin',
    genericName: 'Aspirin (Acetylsalicylic Acid)',
    iupacName: '2-acetoxybenzoic acid',
    brandNames: ['Bayer Aspirin', 'Disprin', 'Ecotrin', 'Bufferin'],
    targetDisciplines: [
      TargetDiscipline.mbbs,
      TargetDiscipline.pharmD,
      TargetDiscipline.dvm,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.cardiology,
    chemicalClass: 'Salicylate / Irreversible Cyclooxygenase (COX) Inhibitor',
    therapeuticIndications:
        'Human: Secondary prevention of myocardial infarction (MI), acute coronary syndromes (STEMI/NSTEMI), ischemic stroke, and transient ischemic attacks (TIAs). Analgesic, antipyretic, anti-inflammatory in rheumatic fever. Veterinary: Prevention of feline aortic thromboembolism (FATE) secondary to hypertrophic cardiomyopathy (HCM) at ultra-low doses; canine canine heartworm-induced pulmonary endarteritis.',
    clinicalStaging:
        'ACC/AHA Class I indication for acute coronary syndromes (162–325 mg non-enteric chewable loading dose immediately upon presentation). Chronic secondary prevention: 75–100 mg daily indefinitely.',
    sourceAndOrigin:
        'Natural product origin: Salicin isolated from willow bark (Salix alba) and meadowsweet (Filipendula ulmaria). Industrial synthesis via Kolbe-Schmitt carboxylation of sodium phenoxide to salicylic acid, followed by acetylation with acetic anhydride catalyzed by trace sulfuric or phosphoric acid.',
    discoveryHistory:
        'Edward Stone described antipyretic effects of willow bark in 1763. Pure salicylic acid was synthesized by Charles Gerhardt in 1853 and stabilized by Felix Hoffmann at Bayer in 1897.',
    syntheticRoute:
        'Sodium phenolate + CO₂ (125 °C, 100 atm) → Sodium salicylate → H⁺ → Salicylic acid + (CH₃CO)₂O → Acetylsalicylic acid + CH₃COOH.',
    molecularTarget:
        'Prostaglandin G/H Synthase 1 & 2 (Cyclooxygenase COX-1 and COX-2).',
    pdbAccession: '1PTH / 1CX2',
    modeOfAction:
        'Aspirin enters the COX active site hydrophobic tunnel and transfers its acetyl moiety covalently to the hydroxyl oxygen of Serine-530 in COX-1 (and Serine-516 in COX-2). In COX-1, the bulky acetyl group sterically hinders arachidonic acid from accessing the catalytic Tyrosine-385, irreversibly destroying thromboxane A₂ (TXA₂) synthesis in anucleate platelets for their entire 8–10 day lifespan. In COX-2, modified enzyme shifts oxygenation to generate 15R-HETE, which is converted to anti-inflammatory 15-epi-lipoxins ("aspirin-triggered lipoxins").',
    downstreamSignaling:
        'Abrogation of TXA₂-mediated Gq-protein coupled platelet activation, intracellular Ca²⁺ mobilization, and GPIIb/IIIa integrin receptor conformational cross-linking. Preservation of endothelial prostacyclin (PGI₂) recovery due to endothelial de novo protein synthesis.',
    absorptionAndDistribution:
        'Rapidly absorbed from stomach and upper small intestine via passive non-ionic diffusion. Bioavailability ~50–70% due to extensive first-pass deacetylation in gut wall and liver. High protein binding (80–90% to albumin). Volume of distribution (Vd): 0.15–0.20 L/kg.',
    metabolismAndElimination:
        'Hydrolyzed to salicylate by plasma and tissue esterases with a half-life of 15–20 minutes. Salicylate is eliminated via hepatic conjugation with glycine to salicyluric acid, glucuronidation, and renal excretion of free salicylate (pH-dependent: urinary alkalinization dramatically accelerates clearance).',
    eliminationHalfLifeHours: 0.33, // Parent drug (salicylate is dose-dependent 2–30h)
    comparativeSpeciesPharmacology:
        '🐾 DVM Warning: Felines have a marked deficiency in UDP-glucuronosyltransferase (UGT1A6 isoform), resulting in an extremely prolonged salicylate half-life of 38–45 hours (vs. 8 hours in canines and 2–3 hours in humans). In cats, aspirin must be dosed no more frequently than once every 48 to 72 hours (5–10 mg/kg q48–72h) to avoid fatal salicylic toxicity, respiratory alkalosis, metabolic acidosis, and hepatic lipidosis.',
    transitionStateDescription:
        'Nucleophilic addition of the Ser530 hydroxyl oxygen to the electrophilic carbonyl carbon of aspirin, forming a tetrahedral intermediate stabilized by the catalytic oxyanion hole, followed by concerted elimination of the phenolate (salicylate leaving group).',
    activationBarrierKcalMol: 18.2,
    catalyticResidues: 'Ser-530, Tyr-385, Arg-120, Val-523',
    associatedReactionId: 'med-aspirin-01',
    contraindications:
        'Active peptic ulcer disease, bleeding diatheses, severe hepatic/renal impairment, pregnancy (3rd trimester: premature closure of fetal ductus arteriosus), children/adolescents with viral illness (Reye syndrome risk).',
    adverseEffectsAndToxicity:
        'Gastric erosions, peptic ulcers, microvascular GI bleeding, tinnitus (salicylism marker), acute bronchospasm in "aspirin-exacerbated respiratory disease" (AERD / Samter triad) due to leukotriene diversion.',
    blackBoxWarning:
        'Reye Syndrome in pediatric and teenage patients with viral prodromes (varicella, influenza); high mortality acute microvesicular fatty liver with encephalopathy.',
    antidoteAndRescue:
        'Emergency management of overdose: Sodium bicarbonate IV (urinary alkalinization to pH > 7.5 promotes ion trapping and renal elimination), hemodialysis for plasma salicylate > 90–100 mg/dL, activated charcoal if within 2 hours of ingestion.',
    clinicalGuidelines: [
      'ACC/AHA Guidelines for the Management of Patients with Acute Coronary Syndromes',
      'ESC Guidelines on Cardiovascular Disease Prevention in Clinical Practice',
      'ACVIM Consensus Statement: Feline Arterial Thromboembolism & Antithrombotic Therapy',
    ],
    primaryDoi: '10.1056/NEJMra052711',
    pubmedId: '16339097',
    highYieldExamPearls: [
      'Aspirin is the ONLY irreversible NSAID due to covalent acetylation of Ser-530.',
      'Platelets lack nuclei and ribosomes; they cannot synthesize new COX-1, making platelet inhibition irreversible.',
      'Cats metabolize aspirin over 38-45 hours due to absent UGT1A6 glucuronidation.',
      'Tinnitus is the classic early sensory sign of salicylate toxicity.',
    ],
  ),

  MedicinePharmacologyProfile(
    id: 'pharma-atorvastatin',
    genericName: 'Atorvastatin Calcium',
    iupacName:
        '(3R,5R)-7-[2-(4-fluorophenyl)-3-phenyl-4-(phenylcarbamoyl)-5-propan-2-ylpyrrol-1-yl]-3,5-dihydroxyheptanoic acid',
    brandNames: ['Lipitor', 'Atorva', 'Torvast'],
    targetDisciplines: [
      TargetDiscipline.mbbs,
      TargetDiscipline.pharmD,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.cardiology,
    chemicalClass: 'Synthetic HMG-CoA Reductase Inhibitor (Statin)',
    therapeuticIndications:
        'Primary and secondary prevention of atherosclerotic cardiovascular disease (ASCVD), hypercholesterolemia, dyslipidemia, familial hypercholesterolemia, acute coronary syndromes (early high-intensity statin therapy).',
    clinicalStaging:
        'ACC/AHA High-Intensity Statin Therapy (40–80 mg daily): Indicated for patients with established ASCVD, LDL-C ≥ 190 mg/dL, or diabetes mellitus aged 40–75 with 10-year ASCVD risk ≥ 7.5%. Reduces LDL-C by ≥ 50%.',
    sourceAndOrigin:
        'Unlike first-generation statins (lovastatin, pravastatin) derived from Aspergillus terreus and Penicillium citrinum fermentation, atorvastatin is a fully synthetic pyrrole-heptanoic acid derivative designed by Bruce Roth at Parke-Davis in 1985.',
    discoveryHistory:
        'Synthesized to optimize hydrophobic contacts in the catalytic groove of human HMG-CoA reductase. Approved by FDA in 1996 and became the highest-selling prescription medication in pharmaceutical history.',
    syntheticRoute:
        'Multi-step convergent synthesis: Paal-Knorr pyrrole condensation between a chiral 1,4-diketone and a protected chiral (3R,5R)-dihydroxyheptanoic acid derivative, followed by deprotection and calcium salt precipitation.',
    molecularTarget:
        '3-Hydroxy-3-Methylglutaryl-Coenzyme A Reductase (HMG-CoA Reductase).',
    pdbAccession: '1HW8 / 1HW9',
    modeOfAction:
        'Atorvastatin acts as a potent reversible competitive inhibitor of HMG-CoA reductase, mimicking the 3,5-dihydroxypentanoic acid substrate transition state. Its rigid substituted pyrrole ring extends into a hydrophobic groove formed by residues Leu-562, Val-683, and Leu-853, achieving a binding affinity (Ki ≈ 8 nM) that is 10,000-fold tighter than the endogenous substrate HMG-CoA. Inhibition halts conversion of HMG-CoA to mevalonate, the rate-limiting step in hepatic de novo cholesterol biosynthesis.',
    downstreamSignaling:
        'Depletion of intracellular cholesterol triggers SREBP-2 (Sterol Regulatory Element-Binding Protein 2) cleavage and nuclear translocation, upregulating hepatic LDL receptor (LDLR) gene transcription. Increased cell-surface LDLR clearance removes circulating LDL and VLDL remnants. Pleiotropic effects: stabilization of atherosclerotic plaques, reduction of oxidative stress, improvement of endothelial nitric oxide synthase (eNOS) activity, and inhibition of vascular smooth muscle proliferation via depletion of isoprenoid intermediates (farnesyl pyrophosphate and geranylgeranyl pyrophosphate).',
    absorptionAndDistribution:
        'Rapid oral absorption with Tmax 1–2 hours. Absolute bioavailability is only ~14% due to extensive presystemic gastrointestinal and hepatic extraction. Plasma protein binding is ≥ 98%. Vd: 381 L.',
    metabolismAndElimination:
        'Extensively metabolized by hepatic Cytochrome P450 3A4 (CYP3A4) to active ortho- and para-hydroxylated metabolites (which account for ~70% of circulating HMG-CoA reductase inhibitory activity). Elimination is predominantly biliary/fecal (< 2% renal).',
    eliminationHalfLifeHours: 14.0, // Terminal half-life (inhibitory activity half-life is 20–30h)
    comparativeSpeciesPharmacology:
        'Statins are predominantly human therapeutics. In veterinary medicine, canines and felines carry high HDL-to-LDL ratios and rarely develop spontaneous atheroma or myocardial infarctions; consequently, statins are not utilized for lipid lowering in veterinary species. Furthermore, canines exhibit high susceptibility to statin-induced skeletal myopathy at equivalent human doses.',
    transitionStateDescription:
        'Mimicry of the high-energy mevaldyl-CoA hemithioacetal transition state through dynamic hydrogen-bonding between the (3R,5R)-dihydroxy carboxylate tail and Lys-691, Lys-735, Arg-590, and Asp-690.',
    activationBarrierKcalMol: 16.5,
    catalyticResidues: 'Lys-691, Lys-735, Asp-690, Arg-590, Ser-684',
    associatedReactionId: 'med-atorvastatin-01',
    contraindications:
        'Active liver disease, unexplained persistent elevations of serum transaminases, pregnancy (Category X: teratogenic disruption of embryonic cholesterol), breastfeeding.',
    adverseEffectsAndToxicity:
        'Statin-Associated Muscle Symptoms (SAMS) ranging from mild myalgia to severe rhabdomyolysis with myoglobinuria and acute kidney injury; asymptomatic transaminase elevations; new-onset type 2 diabetes mellitus (slight glycemic index increase).',
    blackBoxWarning:
        'Contraindicated in pregnancy due to essential role of cholesterol in fetal development. Concomitant administration with potent CYP3A4 inhibitors (ketoconazole, clarithromycin, ritonavir, grapefruit juice) dramatically elevates systemic exposure and rhabdomyolysis risk.',
    antidoteAndRescue:
        'Discontinuation of statin. For rhabdomyolysis: aggressive isotonic saline intravenous hydration (target urine output 200–300 mL/hr) and urinary alkalinization to prevent renal tubular precipitation of ferrihemate.',
    clinicalGuidelines: [
      'AHA/ACC Multi-Society Guideline on the Management of Blood Cholesterol',
      'ESC/EAS Guidelines for the Management of Dyslipidaemias',
      'National Lipid Association (NLA) Statin Safety Consensus',
    ],
    primaryDoi: '10.1016/S0140-6736(03)12948-0',
    pubmedId: '12686036',
    highYieldExamPearls: [
      'Atorvastatin and rosuvastatin have long half-lives and can be taken at any time of day (unlike simvastatin, which requires bedtime dosing).',
      'Ortho- and para-hydroxy metabolites provide 70% of circulating inhibitory activity.',
      'CYP3A4 interactions are critical: macrolides, azoles, and grapefruit juice raise levels.',
      'SREBP-2 upregulation of LDL receptors is the actual mechanism of circulating LDL reduction.',
    ],
  ),

  MedicinePharmacologyProfile(
    id: 'pharma-captopril',
    genericName: 'Captopril',
    iupacName: '(2S)-1-[(2S)-2-methyl-3-sulfanylpropanoyl]pyrrolidine-2-carboxylic acid',
    brandNames: ['Capoten', 'Capozide'],
    targetDisciplines: [
      TargetDiscipline.mbbs,
      TargetDiscipline.pharmD,
      TargetDiscipline.dvm,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.cardiology,
    chemicalClass: 'Sulfhydryl-containing Angiotensin-Converting Enzyme (ACE) Inhibitor',
    therapeuticIndications:
        'Essential hypertension, heart failure with reduced ejection fraction (HFrEF), diabetic nephropathy in Type 1 Diabetes Mellitus, left ventricular dysfunction post-myocardial infarction. Veterinary: Congestive heart failure in dogs and feline hypertension/proteinuric chronic kidney disease (CKD).',
    clinicalStaging:
        'Pivotal landmark trial (SAVE Trial) demonstrated 19% reduction in mortality post-MI with asymptomatic LV dysfunction (EF ≤ 40%). First-line agent in diabetic microalbuminuria.',
    sourceAndOrigin:
        'Structure-based drug design inspired by teprotide, a peptide isolated from the venom of the Brazilian pit viper (Bothrops jararaca) by Sérgio Ferreira and John Vane.',
    discoveryHistory:
        'Designed in 1975 by Miguel Ondetti and David Cushman at Squibb using a model of carboxypeptidase A. Captopril was the very first successful orally bioavailable structure-based drug design milestone.',
    syntheticRoute:
        'Coupling of L-proline with (2S)-3-acetylthio-2-methylpropanoyl chloride followed by basic deprotection of the thioester to reveal the free catalytic sulfhydryl group.',
    molecularTarget:
        'Angiotensin I-Converting Enzyme (Dipeptidyl Carboxypeptidase, ACE).',
    pdbAccession: '1UZF / 2X8Z',
    modeOfAction:
        'The free thiol (-SH) group of captopril coordinates directly with the catalytic catalytic divalent zinc ion (Zn²⁺) embedded in the ACE catalytic site, while its terminal proline carboxylate forms an electrostatic salt bridge with Arg-522. This high-affinity competitive binding prevents ACE from cleaving the C-terminal dipeptide (His-Leu) from Angiotensin I, halting its conversion to the potent vasoconstrictor Angiotensin II. Concurrently, captopril blocks the degradation of bradykinin (kallikrein-kinin system), promoting endothelial nitric oxide (NO) and prostacyclin release.',
    downstreamSignaling:
        'Reduction in circulating Angiotensin II eliminates AT₁-receptor-mediated arteriolar vasoconstriction, decreases aldosterone secretion from the adrenal cortex (reducing renal Na⁺ and H₂O reabsorption while sparing K⁺), and promotes efferent arteriolar vasodilation in the renal glomerulus, lowering intraglomerular capillary hydrostatic pressure.',
    absorptionAndDistribution:
        'Rapidly absorbed with peak plasma concentrations in 1 hour. Oral bioavailability is ~70% on an empty stomach (food decreases absorption by 30–40%; must be taken 1 hour before meals). Protein binding is 25–30%. Vd: 0.7 L/kg.',
    metabolismAndElimination:
        'Rapidly metabolized by disulfide exchange forming captopril-cysteine and captopril-glutathione disulfides. ~40–50% excreted unchanged in urine via glomerular filtration and tubular secretion.',
    eliminationHalfLifeHours: 1.9,
    comparativeSpeciesPharmacology:
        'Veterinary DVM Clinical Pearl: In canine and feline heart failure/CKD, newer dicarboxylate ACE inhibitors (Enalapril, Benazepril) are generally preferred over captopril because enalapril/benazepril are dosed once daily (q24h) or twice daily, whereas captopril requires dosing three times daily (TID) due to its short 2-hour half-life. Benazepril is specifically favored in feline chronic renal failure because of its dual 55:45 biliary-to-renal elimination, protecting patients with deteriorating kidneys.',
    transitionStateDescription:
        'Zinc-thiol coordination complex stabilizing a distorted tetrahedral coordination geometry mimicking the transition state of angiotensin I peptide bond hydrolysis.',
    activationBarrierKcalMol: 14.8,
    catalyticResidues: 'Zn²⁺, Arg-522, Glu-384, Tyr-523',
    associatedReactionId: 'med-captopril-01',
    contraindications:
        'History of ACE-inhibitor-induced angioedema, bilateral renal artery stenosis (or unilateral stenosis in a solitary kidney), concomitant use of sacubitril/valsartan (requires 36-hour washout), pregnancy (2nd and 3rd trimesters: fatal oligohydramnios and renal dysgenesis).',
    adverseEffectsAndToxicity:
        'Dry persistent non-productive cough (seen in 10–20% of patients due to bradykinin/substance P accumulation in bronchopulmonary mucosa), hyperkalemia, acute kidney injury, skin rash, dysgeusia (loss/alteration of taste due to the sulfhydryl group), angioedema.',
    blackBoxWarning:
        'Fetal Toxicity: Can cause injury and death to the developing fetus when used in pregnancy (Category D: renal hypoplasia, anuria, skull hypoplasia).',
    antidoteAndRescue:
        'For acute hypotension: IV normal saline volume expansion. For angioedema: immediate airway protection, epinephrine 1:1000 IM, icatibant (bradykinin B₂ receptor antagonist). For severe hyperkalemia: calcium gluconate IV, insulin + dextrose, patiromer.',
    clinicalGuidelines: [
      'KDIGO Clinical Practice Guideline for the Management of Blood Pressure in CKD',
      'AHA/ACC/HFSA Guideline for the Management of Heart Failure',
      'ACVIM Consensus Guidelines for the Diagnosis and Treatment of Myxomatous Mitral Valve Disease in Dogs',
    ],
    primaryDoi: '10.1056/NEJM199209033271001',
    pubmedId: '1386652',
    highYieldExamPearls: [
      'Captopril is an active drug, NOT a prodrug (unlike enalapril, ramipril, and perindopril).',
      'The sulfhydryl group causes taste alteration (dysgeusia) and skin rash.',
      'Dilates the EFFERENT arteriole > afferent arteriole, lowering intraglomerular pressure and reducing proteinuria.',
      'Absolute contraindication in bilateral renal artery stenosis due to precipitous loss of GFR.',
    ],
  ),

  MedicinePharmacologyProfile(
    id: 'pharma-pimobendan',
    genericName: 'Pimobendan',
    iupacName:
        '4,5-dihydro-6-[2-(4-methoxyphenyl)-1H-benzimidazol-5-yl]-5-methylpyridazin-3(2H)-one',
    brandNames: ['Vetmedin', 'Acardi', 'Pimodin'],
    targetDisciplines: [
      TargetDiscipline.dvm,
      TargetDiscipline.pharmD,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.cardiology,
    chemicalClass: 'Benzimidazole-pyridazinone Inodilator (Calcium Sensitizer & PDE3 Inhibitor)',
    therapeuticIndications:
        'Veterinary: First-line cornerstone management of canine congestive heart failure (CHF) secondary to Myxomatous Mitral Valve Disease (MMVD / Endocardiosis) and Dilated Cardiomyopathy (DCM). Human: Approved in Japan for acute and chronic decompensated heart failure.',
    clinicalStaging:
        'ACVIM MMVD Stage B2 (asymptomatic cardiomegaly with structural enlargement) and Stage C (active or past congestive pulmonary edema). Landmark QUEST and EPIC trials proved pimobendan delays onset of clinical heart failure by an average of 15 months.',
    sourceAndOrigin:
        'Synthetically designed non-glycoside, non-catecholamine inotrope developed by Boehringer Ingelheim to overcome the arrhythmogenic and calcium-overload risks of digitalis (digoxin) and milrinone.',
    discoveryHistory:
        'Investigated in 1980s; revolutionized veterinary cardiology after the 2016 EPIC clinical trial demonstrated unprecedented survival prolongation in canine cardiac remodeling.',
    syntheticRoute:
        'Condensation of 4-methoxybenzaldehyde with 4-(4-amino-3-nitrophenyl)morpholine derivatives, reductive cyclization to the benzimidazole core, followed by construction of the methylpyridazinone ring.',
    molecularTarget:
        'Cardiac Troponin C (Calcium sensitization) and Phosphodiesterase-3 (PDE3).',
    pdbAccession: '2L1R / 1J1E',
    modeOfAction:
        'Dual "inodilator" mechanism: (1) Inotropic action: Selectively sensitizes cardiac myofilaments to calcium by binding to the N-domain of Cardiac Troponin C (cTnC), stabilizing its active conformation during systole without increasing intracellular free calcium concentrations ([Ca²⁺]i). This augments myocardial contractility with minimal oxygen consumption and zero pro-arrhythmic energy penalty. (2) Vasodilator action: Inhibits phosphodiesterase-3 (PDE3) in vascular smooth muscle cells, preventing the breakdown of cyclic AMP (cAMP). Elevated cAMP promotes protein kinase A (PKA) activation, leading to calcium extrusion and profound peripheral arterial and venous vasodilation (reducing both afterload and preload).',
    downstreamSignaling:
        'cTnC conformational stabilization + vascular smooth muscle cAMP accumulation → decreased systemic vascular resistance, reduced pulmonary capillary wedge pressure, augmented stroke volume and cardiac output.',
    absorptionAndDistribution:
        'Rapid oral bioavailability of ~60–65%. Marked food effect: administration with food dramatically decreases bioavailability by > 50%. Must be given on an empty stomach at least 1 hour before feeding. High protein binding (90–95%).',
    metabolismAndElimination:
        'Rapidly demethylated in the liver to its active metabolite, O-desmethylpimobendan (UD-CG 212), which is 8-fold more potent than parent drug in PDE3 inhibition. Excretion is > 95% via feces through biliary secretion.',
    eliminationHalfLifeHours: 0.5, // Parent drug (active metabolite is ~2.0h)
    comparativeSpeciesPharmacology:
        '🐾 DVM Essential: Pimobendan is the single most important inotropic agent in canine medicine. In felines with hypertrophic cardiomyopathy (HCM), pimobendan is strictly contraindicated if dynamic left ventricular outflow tract obstruction (LVOTO / SAM of the mitral valve) is present, as enhanced inotropy worsens systolic anterior motion and dynamic subaortic gradient.',
    transitionStateDescription:
        'Binding to the hydrophobic pocket of troponin C, promoting spatial rapprochement of Gly-34 and Asp-65 to enhance Ca²⁺ off-rate regulation without energetic waste.',
    activationBarrierKcalMol: 15.6,
    catalyticResidues: 'Troponin C Gly-34, Asp-65; PDE3A Gln-988, Phe-1004',
    associatedReactionId: 'vet-pimobendan-01',
    contraindications:
        'Hypertrophic cardiomyopathy with outflow tract obstruction (HOCM), severe aortic or pulmonic stenosis, severe hepatic impairment.',
    adverseEffectsAndToxicity:
        'Mild tachycardia, anorexia, vomiting, lethargy. Extreme overdoses: excessive hypotension, chordae tendineae rupture in predisposed mitral valves.',
    blackBoxWarning:
        'Do not administer to animals with obstructive outflow cardiomyopathies (aortic stenosis, SAM/LVOTO). Must be administered on an empty stomach.',
    antidoteAndRescue:
        'Supportive therapy: beta-blockers (esmolol, atenolol) to counteract excessive inotropic/chronotropic stimulus; IV vasopressors (phenylephrine) for refractory systemic vasodilation.',
    clinicalGuidelines: [
      'ACVIM Consensus Guidelines for the Diagnosis and Treatment of Myxomatous Mitral Valve Disease in Dogs (2019)',
      'ACVIM Consensus Statement: Guidelines for the Classification, Diagnosis, and Management of Cardiomyopathies in Cats (2020)',
    ],
    primaryDoi: '10.1111/jvim.14586',
    pubmedId: '27678080',
    highYieldExamPearls: [
      'Pimobendan is an INODILATOR: Sensitizes troponin C to Ca²⁺ (inotropy) + inhibits PDE3 (vasodilation).',
      'Does NOT increase intracellular calcium, avoiding the myocardial oxygen penalty and arrhythmias of digoxin.',
      'Must ALWAYS be administered on an empty stomach (food cuts absorption in half).',
      'Contraindicated in feline HCM with left ventricular outflow tract obstruction (LVOTO).',
    ],
  ),

  // ── INFECTIOUS DISEASES & ANTIMICROBIALS ───────────────────────────────────
  MedicinePharmacologyProfile(
    id: 'pharma-amox-clav',
    genericName: 'Amoxicillin + Clavulanic Acid (Co-Amoxiclav)',
    iupacName:
        '(2S,5R,6R)-6-[[(2R)-2-amino-2-(4-hydroxyphenyl)acetyl]amino]-3,3-dimethyl-7-oxo-4-thia-1-azabicyclo[3.2.0]heptane-2-carboxylic acid + (2R,5R,Z)-3-(2-hydroxyethylidene)-7-oxo-4-oxa-1-azabicyclo[3.2.0]heptane-2-carboxylic acid',
    brandNames: ['Augmentin', 'Clavamox', 'Amoclav', 'Synulox'],
    targetDisciplines: [
      TargetDiscipline.mbbs,
      TargetDiscipline.pharmD,
      TargetDiscipline.dvm,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.infectiousDiseases,
    chemicalClass: 'Aminopenicillin + Suicide Beta-Lactamase Inhibitor',
    therapeuticIndications:
        'Human: Acute bacterial rhinosinusitis, otitis media, community-acquired pneumonia (CAP), human/animal bite wound infections, complicated urinary tract infections, diabetic foot infections. Veterinary (Clavamox/Synulox): Feline and canine bacterial dermatitis, periodontal disease, feline lower urinary tract infections, wound infections.',
    clinicalStaging:
        'IDSA First-line guideline empiric therapy for animal and human bite wounds (covers Pasteurella multocida, Eikenella corrodens, anaerobes, and Staphylococcus aureus).',
    sourceAndOrigin:
        'Amoxicillin is a semisynthetic penicillin derived from 6-aminopenicillanic acid (6-APA) fermented from Penicillium chrysogenum. Clavulanic acid is a natural oxapenam isolated from the actinomycete bacterium Streptomyces clavuligerus.',
    discoveryHistory:
        'Discovered by Beecham Pharmaceuticals in the 1970s. Clavulanic acid was identified in 1976 and combined with amoxicillin in 1981 to neutralize resistant beta-lactamase-producing bacteria.',
    syntheticRoute:
        'Acylation of 6-APA with D-(-)-4-hydroxyphenylglycine Dane salt yielding amoxicillin, co-formulated with potassium clavulanate fermented from S. clavuligerus.',
    molecularTarget:
        'Amoxicillin: Bacterial Penicillin-Binding Proteins (PBP-1a, PBP-1b, PBP-2, PBP-3). Clavulanate: Serine Beta-Lactamases (TEM, SHV, Richmond-Sykes Class A, C, D).',
    pdbAccession: '1HVB / 1BLC',
    modeOfAction:
        'Amoxicillin acts as a structural mimic of the terminal D-Ala-D-Ala dipeptide of bacterial peptidoglycan precursors, covalently acylating the active site serine of PBPs and preventing transpeptidase cross-linking of the cell wall, causing autolytic cell death. Clavulanic acid acts as a "suicide / mechanism-based inhibitor": its oxapenam ring is cleaved by bacterial beta-lactamase, forming an acyl-enzyme intermediate that undergoes secondary rearrangement to generate an irreversible, dead-end covalent adduct, permanently protecting amoxicillin from hydrolysis.',
    downstreamSignaling:
        'Inhibition of peptidoglycan cross-linking triggers bacterial autolysins (murein hydrolases), resulting in loss of osmotic structural integrity and rapid bactericidal osmotic lysis.',
    absorptionAndDistribution:
        'Amoxicillin has excellent oral bioavailability (~80–90%), substantially superior to ampicillin, and unaffected by food. Clavulanic acid bioavailability is ~60–70%. Widely distributed into lungs, sputum, pleural fluid, middle ear mucosa, and peritoneal fluid; poor CSF penetration unless meninges are inflamed.',
    metabolismAndElimination:
        'Amoxicillin is eliminated primarily by renal glomerular filtration and active tubular secretion (> 70% unchanged in urine). Clavulanate is partially metabolized and excreted via renal and non-renal pathways.',
    eliminationHalfLifeHours: 1.1,
    comparativeSpeciesPharmacology:
        '🐾 DVM Critical Alert: Broad-spectrum penicillins and beta-lactamase inhibitors like co-amoxiclav must NEVER be administered orally to hindgut fermenters (guinea pigs, rabbits, hamsters, chinchillas). Destruction of normal Gram-positive cecal microflora triggers lethal overgrowth of Clostridium difficile / Clostridium spiroforme, causing acute fatal enterotoxemia within 48–72 hours.',
    transitionStateDescription:
        'Acyl-enzyme formation via nucleophilic attack of the catalytic serine on the strained beta-lactam carbonyl carbon, followed by oxapenam fragmentation and active site cross-linking.',
    activationBarrierKcalMol: 17.4,
    catalyticResidues: 'PBP Ser-337, Lys-340; Beta-lactamase Ser-70, Lys-73, Glu-166',
    associatedReactionId: 'med-amox-01',
    contraindications:
        'History of severe immediate hypersensitivity (anaphylaxis) to penicillins or beta-lactams; history of amoxicillin-clavulanate-associated cholestatic jaundice or hepatic dysfunction.',
    adverseEffectsAndToxicity:
        'Gastrointestinal hypermotility and diarrhea (clavulanate stimulates intestinal motility directly), nausea, Clostridioides difficile colitis, maculopapular rash (prominent in Epstein-Barr virus / Infectious Mononucleosis patients: pseudo-allergy).',
    blackBoxWarning:
        'Hypersensitivity reactions: Serious and occasionally fatal anaphylaxis can occur. Verify allergy history before administration.',
    antidoteAndRescue:
        'For anaphylaxis: immediate intramuscular Epinephrine (1:1000), airway control, high-flow oxygen, IV crystalloids, H1/H2 antihistamines and corticosteroids.',
    clinicalGuidelines: [
      'IDSA Practice Guidelines for the Diagnosis and Management of Skin and Soft Tissue Infections',
      'ATS/IDSA Guidelines on the Management of Community-Acquired Pneumonia',
      'ISCAID Guidelines for the Diagnosis and Management of Bacterial Urinary Tract Infections in Dogs and Cats',
    ],
    primaryDoi: '10.1093/cid/ciu296',
    pubmedId: '24973422',
    highYieldExamPearls: [
      'Clavulanic acid has minimal intrinsic antibacterial activity; it is a suicide inhibitor protecting amoxicillin.',
      'Drug of choice for animal and human bite wounds because it covers Pasteurella multocida and anaerobes.',
      'Giving ampicillin/amoxicillin to a patient with Mononucleosis (EBV) triggers a diffuse maculopapular rash (not a true IgE allergy).',
      'Contraindicated orally in rabbits and guinea pigs due to fatal Clostridial enterotoxemia.',
    ],
  ),

  MedicinePharmacologyProfile(
    id: 'pharma-enrofloxacin',
    genericName: 'Enrofloxacin',
    iupacName:
        '1-cyclopropyl-7-(4-ethylpiperazin-1-yl)-6-fluoro-4-oxoquinoline-3-carboxylic acid',
    brandNames: ['Baytril', 'Enroquin', 'Enrosite'],
    targetDisciplines: [
      TargetDiscipline.dvm,
      TargetDiscipline.pharmD,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.infectiousDiseases,
    chemicalClass: 'Fluoroquinolone Antimicrobial (Concentration-dependent Bactericidal)',
    therapeuticIndications:
        'Veterinary: Severe, refractory Gram-negative and intracellular infections in canines, felines, exotic mammals, birds, and reptiles: deep pyoderma, complicated prostatitis, osteomyelitis, respiratory tract infections (Pasteurella, Bordetella, Pseudomonas aeruginosa), and avian chlamydiosis.',
    clinicalStaging:
        'Reserved as a high-potency second-tier antimicrobial for culture-confirmed fluoroquinolone-susceptible pathogens. Concentration-dependent bactericidal action governed by Cmax:MIC ratio (optimal ≥ 8–10:1) and AUC:MIC ratio (optimal ≥ 100–125).',
    sourceAndOrigin:
        'Fully synthetic fluorinated quinolone developed by Bayer Animal Health in the late 1980s as the ethyl-derivative analog of ciprofloxacin.',
    discoveryHistory:
        'Derived from the 1962 discovery of nalidixic acid by George Lesher. Addition of a 6-fluorine atom and a 7-piperazine ring conferred 100-fold higher potency and broad Gram-negative/Gram-positive coverage.',
    syntheticRoute:
        'Condensation of 2,4-dichloro-5-fluorobenzoyl chloride with ethyl 3-(dimethylamino)acrylate, cyclization with cyclopropylamine, and substitution with 1-ethylpiperazine.',
    molecularTarget:
        'Bacterial DNA Gyrase (Topoisomerase II, specifically GyrA and GyrB subunits) and Topoisomerase IV (ParC and ParE subunits).',
    pdbAccession: '2XCT / 3FV5',
    modeOfAction:
        'Enrofloxacin binds to the cleaved DNA-enzyme complex, stabilizing the covalent phospho-tyrosine intermediate between DNA and the catalytic tyrosine of DNA gyrase / Topoisomerase IV. This "poisons" the enzyme, trapping it on the replication fork, preventing re-ligation of double-stranded DNA breaks. The stalled replication forks collapse, releasing fragmented chromosomes and triggering irreversible SOS-mediated bactericidal death.',
    downstreamSignaling:
        'Bacterial chromosome fragmentation triggers the LexA/RecA-mediated bacterial SOS repair response, hydroxyl radical cascade formation, and lethal bacterial cellular autolysis.',
    absorptionAndDistribution:
        'Rapid oral bioavailability (~80–100% in canines/felines). Exceptional tissue penetration: achieves intracellular concentrations in alveolar macrophages, neutrophils, bronchial epithelium, bone, and prostate that exceed plasma concentrations by 2- to 10-fold. Large Vd: 2.5–3.5 L/kg.',
    metabolismAndElimination:
        'Extensively de-ethylated in the liver (15–40%) to its active metabolite, CIPROFLOXACIN. Both parent enrofloxacin and ciprofloxacin are eliminated via dual renal (glomerular filtration + active tubular secretion) and non-renal biliary mechanisms.',
    eliminationHalfLifeHours: 4.5,
    comparativeSpeciesPharmacology:
        '🐾 DVM Toxicity Alerts: (1) Feline Retinal Degeneration: Felines lack effective ABCG2 (breast cancer resistance protein) retinal blood-barrier transport. Enrofloxacin accumulates in the feline retina and undergoes light-induced photochemical excitation, generating reactive oxygen species that cause IRREVERSIBLE, permanent diffuse retinal atrophy and blindness at doses > 5 mg/kg/day. (2) Canine Arthropathy: Chelation of magnesium in growing articular cartilage leads to chondrocyte necrosis and cartilage erosion; contraindicated in growing puppies (< 8–12 months in small breeds, < 18 months in giant breeds).',
    transitionStateDescription:
        'Intercalation into cleaved double-stranded DNA via water-metal (Mg²⁺) bridge coordination to the 4-keto and 3-carboxylate quinolone oxygens.',
    activationBarrierKcalMol: 19.1,
    catalyticResidues: 'DNA Gyrase Tyr-122, Arg-121, Ser-83; ParC Ser-80',
    associatedReactionId: 'vet-enrofloxacin-01',
    contraindications:
        'Growing juvenile canines (chondrotoxicity), felines above 5 mg/kg/day (retinal toxicity), horses (severe cartilage damage and cecal dysbiosis), patients with pre-existing central nervous system seizure disorders.',
    adverseEffectsAndToxicity:
        'Irreversible acute retinal blindness in cats, cartilage erosions and lameness in young dogs, emesis, diarrhea, lowering of seizure threshold (GABA-A antagonism).',
    blackBoxWarning:
        'FELINE RETINOTOXICITY: Exceeding 5 mg/kg/day in cats can produce sudden, permanent, irreversible blindness within 24–48 hours.',
    antidoteAndRescue:
        'Immediate cessation. In cases of acute accidental overdose: oral administration of magnesium or aluminum hydroxide antacids (sucralfate/Maalox) to chelate quinolone and block GI absorption.',
    clinicalGuidelines: [
      'ISCAID Guidelines for the Treatment of Urinary Tract Infections in Dogs and Cats',
      'AAHA/AAFP Antimicrobial Stewardship Guidelines for Dogs and Cats',
    ],
    primaryDoi: '10.2460/ajvr.2001.62.1932',
    pubmedId: '11765039',
    highYieldExamPearls: [
      'Enrofloxacin is partially metabolized in vivo into ciprofloxacin.',
      'Causes IRREVERSIBLE retinal degeneration and acute blindness in felines at doses > 5 mg/kg.',
      'Contraindicated in growing puppies due to articular cartilage bubbling and erosions.',
      'Activity is concentration-dependent: high peak-to-MIC ratio (Cmax:MIC ≥ 10) prevents resistance development.',
    ],
  ),

  MedicinePharmacologyProfile(
    id: 'pharma-isoniazid',
    genericName: 'Isoniazid (INH / Isonicotinic Acid Hydrazide)',
    iupacName: 'pyridine-4-carbohydrazide',
    brandNames: ['Nydrazid', 'Laniazid', 'Rimifon'],
    targetDisciplines: [
      TargetDiscipline.mbbs,
      TargetDiscipline.pharmD,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.infectiousDiseases,
    chemicalClass: 'Hydrazide Antimycobacterial Prodrug',
    therapeuticIndications:
        'Cornerstone first-line bactericidal component of multi-drug regimens for active tuberculosis caused by Mycobacterium tuberculosis (RIPE regimen: Rifampin, Isoniazid, Pyrazinamide, Ethambutol). Monotherapy or combination therapy for latent tuberculosis infection (LTBI).',
    clinicalStaging:
        'WHO & CDC First-Line Intensive Phase (2 months of RIPE) followed by Continuation Phase (4 months of INH + Rifampin). Standard adult dose 300 mg daily or 900 mg twice weekly.',
    sourceAndOrigin:
        'Synthetic compound first prepared in 1912 by Hans Meyer and Josef Mally at Charles University in Prague. Its potent antitubercular properties were independently discovered in 1952 by Hoffman-La Roche, Squibb, and Bayer.',
    discoveryHistory:
        'Transformed tuberculosis from an incurable, sanitarium-confined fatal infection into a curable disease. Introduced alongside streptomycin and PAS.',
    syntheticRoute:
        'Condensation of methyl isonicotinate with hydrazine hydrate at elevated temperature, followed by recrystallization.',
    molecularTarget:
        'Mycobacterial Catalase-Peroxidase (KatG) and Enoyl-Acyl Carrier Protein Reductase (InhA).',
    pdbAccession: '1ZID / 2B35',
    modeOfAction:
        'Isoniazid is a prodrug that passively diffuses across the waxy mycobacterial cell wall. Inside M. tuberculosis, INH is bioactivated by the mycobacterial catalase-peroxidase enzyme KatG, generating an isonicotinic acyl radical. This radical spontaneously couples with the nicotinamide ring of NAD⁺ and NADP⁺ to form covalent INH-NAD and INH-NADP adducts. The INH-NAD adduct is a picomolar competitive inhibitor of InhA (enoyl-ACP reductase), shutting down fatty acid synthase II (FAS-II). This halts the synthesis of mycolic acids (long-chain alpha-alkyl beta-hydroxy fatty acids), destroying the mycobacterial cell envelope.',
    downstreamSignaling:
        'Collapse of the mycolic acid barrier causes osmotic instability, acid-fastness loss, and bactericidal death of rapidly dividing tubercle bacilli.',
    absorptionAndDistribution:
        'Readily absorbed orally with bioavailability > 90%. Excellent penetration into all body fluids and tissues, including caseous tuberculous granulomas, necrotic cavities, and cerebrospinal fluid (CSF:plasma ratio 0.8–1.0). Large Vd: 0.6–0.7 L/kg.',
    metabolismAndElimination:
        'Metabolized in the liver by N-acetyltransferase 2 (NAT2) to inactive acetyl-isoniazid, which is hydrolyzed to isonicotinic acid and monoacetylhydrazine. Genetic polymorphism: "Fast acetylators" (half-life ~1 hour) vs. "Slow acetylators" (half-life ~3–5 hours).',
    eliminationHalfLifeHours: 2.0,
    comparativeSpeciesPharmacology:
        'Veterinary DVM Alert: Mycobacterium bovis and M. tuberculosis infections in livestock and companion animals are reportable zoonoses under strict public health statutory control in most jurisdictions. Treatment of bovine tuberculosis with isoniazid is generally prohibited due to the risk of creating drug-resistant reservoirs and human food-chain contamination.',
    transitionStateDescription:
        'Heme-mediated single-electron oxidation of the hydrazine moiety by KatG Compound I, yielding an isonicotinoyl free radical that undergoes radical addition to the C4 position of the NAD⁺ pyridine ring.',
    activationBarrierKcalMol: 16.9,
    catalyticResidues: 'KatG Trp-107, Arg-418, His-270; InhA Phe-149, Tyr-158',
    associatedReactionId: 'med-isoniazid-01',
    contraindications:
        'Previous isoniazid-associated severe hepatic injury; acute active liver disease; severe pre-existing peripheral neuropathy.',
    adverseEffectsAndToxicity:
        'Hepatotoxicity (ranges from asymptomatic transaminitis in 10–20% to fatal acute liver necrosis, accelerated by monoacetylhydrazine); Peripheral Neuropathy (due to competitive inhibition of pyridoxal kinase and urinary excretion of pyridoxine/Vitamin B6); Lupus-like syndrome (drug-induced lupus with anti-histone antibodies in slow acetylators); Sideroblastic anemia.',
    blackBoxWarning:
        'Severe and sometimes fatal hepatitis may occur even after many months of treatment. Patient monitoring of transaminases and counseling regarding early symptoms of hepatitis (anorexia, nausea, jaundice) is mandatory.',
    antidoteAndRescue:
        'Co-administration of Pyridoxine (Vitamin B6, 25–50 mg daily) prevents peripheral neuropathy. For acute isoniazid overdose (presents with refractory status epilepticus, coma, severe metabolic acidosis): Pyridoxine IV gram-for-gram equivalent to ingested INH dose (or 5 g IV if dose unknown).',
    clinicalGuidelines: [
      'CDC/ATS/IDSA Guidelines for Treatment of Drug-Susceptible Tuberculosis',
      'WHO Consolidated Guidelines on Tuberculosis: Module 4: Treatment',
    ],
    primaryDoi: '10.1056/NEJMra070624',
    pubmedId: '18499567',
    highYieldExamPearls: [
      'INH is a prodrug activated by mycobacterial KatG into an INH-NAD adduct that inhibits InhA.',
      'Always co-prescribe Pyridoxine (Vitamin B6) to prevent dose-dependent peripheral neuropathy.',
      'High risk of drug-induced lupus erythematosus (DILE) with positive anti-histone antibodies in slow acetylators.',
      'Acute INH toxicity triad: Refractory seizures, profound anion-gap metabolic acidosis, and coma — treated with IV Pyridoxine.',
    ],
  ),

  // ── NEUROLOGY, PSYCHIATRY & NEUROPHARMACOLOGY ────────────────────────────
  MedicinePharmacologyProfile(
    id: 'pharma-levodopa',
    genericName: 'Levodopa + Carbidopa',
    iupacName:
        '(2S)-2-amino-3-(3,4-dihydroxyphenyl)propanoic acid + (2S)-3-(3,4-dihydroxyphenyl)-2-hydrazinyl-2-methylpropanoic acid',
    brandNames: ['Sinemet', 'Stalevo', 'Rytary', 'Duopa'],
    targetDisciplines: [
      TargetDiscipline.mbbs,
      TargetDiscipline.pharmD,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.neurology,
    chemicalClass: 'Dopamine Precursor + Peripheral DOPA Decarboxylase Inhibitor',
    therapeuticIndications:
        'Parkinson\'s disease (idiopathic parkinsonism), post-encephalitic parkinsonism, dopamine-responsive dystonia (Segawa disease), symptomatic parkinsonism following carbon monoxide or manganese intoxication.',
    clinicalStaging:
        'Gold-standard, most effective symptomatic medical therapy for motor symptoms (resting tremor, cogwheel rigidity, bradykinesia, postural instability) across all Hoehn and Yahr stages of Parkinson\'s disease.',
    sourceAndOrigin:
        'L-DOPA was first isolated from the seedlings of the broad bean (Vicia faba) by Markus Guggenheim in 1913. Carbidopa is a synthetic alpha-methyl hydrazino analog of DOPA designed by Merck.',
    discoveryHistory:
        'Arvid Carlsson demonstrated that dopamine is a major neurotransmitter in the brain (Nobel Prize 2000). Oleh Hornykiewicz showed striatal dopamine deficiency in Parkinson\'s. George Cotzias pioneered high-dose oral L-DOPA therapy in 1967.',
    syntheticRoute:
        'Enzymatic or asymmetric hydrogenation of 2-acetamido-3-(3,4-dihydroxyphenyl)acrylic acid using chiral Rh-DIPAMP catalyst (Monsanto L-DOPA process, William Knowles Nobel Prize 2001).',
    molecularTarget:
        'L-Aromatic Amino Acid Decarboxylase (AADC / DOPA Decarboxylase) and Central Dopamine D₂/D₁ Receptors.',
    pdbAccession: '1JS3 / 6VMS',
    modeOfAction:
        'Dopamine cannot cross the blood-brain barrier (BBB) because it lacks an active carrier. Levodopa, being a large neutral amino acid, actively traverses the BBB via the LAT1 (L-type amino acid transporter 1 / SLC7A5). Once in the central nervous system, surviving dopaminergic neurons in the substantia nigra pars compacta take up levodopa and decarboxylate it into dopamine via AADC. Carbidopa does NOT cross the blood-brain barrier; it selectively inhibits peripheral AADC in gut and liver, preventing peripheral conversion of levodopa to dopamine. This raises the fraction of levodopa reaching the brain from < 1% to > 10% and abolishes peripheral dopamine-mediated emesis and orthostatic hypotension.',
    downstreamSignaling:
        'Restoration of striatal dopamine balances the direct (striatonigral D₁: Gs/cAMP/PKA activation promoting movement) and indirect (striatopallidal D₂: Gi/adenylyl cyclase inhibition suppressing unwanted movement) basal ganglia motor loops.',
    absorptionAndDistribution:
        'Absorbed in the proximal small intestine via active saturable transport by LAT1. Food rich in dietary protein competes directly for LAT1 absorption and decreases brain penetration (patients advised to take levodopa 30–60 minutes before meals). Bioavailability ~30% with carbidopa.',
    metabolismAndElimination:
        'Decarboxylation by AADC to dopamine, and O-methylation by Catechol-O-Methyltransferase (COMT) to 3-O-methyldopa (3-OMD). Dopamine is subsequently metabolized by MAO-B and COMT to DOPAC and homovanillic acid (HVA) excreted in urine.',
    eliminationHalfLifeHours: 1.5,
    comparativeSpeciesPharmacology:
        'Idiopathic Parkinson\'s disease is a uniquely human neurodegenerative disorder; spontaneous alpha-synuclein Lewy body pathology does not occur in domestic canines, felines, or equines. However, levodopa is widely used in veterinary translational research using MPTP-induced parkinsonian primate models and canine neuro-toxicology studies.',
    transitionStateDescription:
        'Pyridoxal 5\'-phosphate (PLP) dependent Schiff base formation between the amino group of levodopa and the PLP-AADC internal aldimine, followed by heterolytic cleavage of the C-COO⁻ bond producing a quinonoid intermediate.',
    activationBarrierKcalMol: 15.2,
    catalyticResidues: 'AADC Lys-303, His-192, Asp-271, Thr-246',
    associatedReactionId: 'med-levodopa-01',
    contraindications:
        'Concurrent use of non-selective Monoamine Oxidase Inhibitors (MAOIs) within 14 days (risk of severe hypertensive crisis); narrow-angle glaucoma; undiagnosed skin lesions or history of melanoma (levodopa is a melanin precursor).',
    adverseEffectsAndToxicity:
        'Early: Nausea, anorexia, orthostatic hypotension, cardiac arrhythmias. Late (after 3–5 years of therapy): Motor fluctuations ("wearing-off" phenomenon, "on-off" phenomenon), peak-dose choreiform dyskinesias, vivid dreams, hallucinations, dopamine dysregulation syndrome (impulse control disorders).',
    blackBoxWarning:
        'Neuroleptic Malignant-like Syndrome: Abrupt discontinuation or rapid dose reduction of levodopa can trigger a life-threatening syndrome resembling neuroleptic malignant syndrome (severe hyperthermia, muscle rigidity, altered mental status, autonomic instability).',
    antidoteAndRescue:
        'For motor fluctuations: addition of COMT inhibitors (entacapone) or MAO-B inhibitors (rasagiline, safinamide) or dopamine agonists. For peak-dose dyskinesia: amantadine (NMDA antagonist). For psychosis: pimavanserin (selective 5-HT2A inverse agonist).',
    clinicalGuidelines: [
      'American Academy of Neurology (AAN) Practice Guideline: Pharmacologic Treatment of Parkinson Disease',
      'Movement Disorder Society (MDS) Evidence-Based Review of Treatments for Parkinson\'s Disease',
    ],
    primaryDoi: '10.1056/NEJMoa033447',
    pubmedId: '15590952',
    highYieldExamPearls: [
      'Levodopa crosses the BBB via LAT1; Dopamine cannot cross the BBB.',
      'Carbidopa only inhibits PERIPHERAL AADC because it does not cross the BBB.',
      'High protein meals decrease levodopa absorption due to competitive amino acid transport.',
      'Long-term complication is the "on-off" phenomenon and peak-dose dyskinesia.',
    ],
  ),

  MedicinePharmacologyProfile(
    id: 'pharma-xylazine',
    genericName: 'Xylazine Hydrochloride',
    iupacName: 'N-(2,6-dimethylphenyl)-5,6-dihydro-4H-1,3-thiazin-2-amine',
    brandNames: ['Rompun', 'Sedazine', 'AnaSed', 'Chanazine'],
    targetDisciplines: [
      TargetDiscipline.dvm,
      TargetDiscipline.specialist,
      TargetDiscipline.pharmD,
    ],
    specialty: PharmacologicalSpecialty.neurology,
    chemicalClass: 'Clonidine-analog Alpha-2 Adrenergic Agonist',
    therapeuticIndications:
        'Veterinary: Potent sedative, central muscle relaxant, and visceral analgesic widely used in horses, cattle, sheep, goats, canines, felines, and exotic zoo species for chemical restraint, pre-anesthetic sedation, minor surgical procedures, and diagnostic imaging. Emesis induction in felines.',
    clinicalStaging:
        'Equine: 0.5–1.1 mg/kg IV produces deep sedation and standing chemical restraint within 3–5 minutes. Bovine: Highly sensitive; requires only 1/10th of the equine dose (0.05–0.1 mg/kg IM).',
    sourceAndOrigin:
        'Synthetic derivative developed by Bayer AG in 1962 as an experimental antihypertensive agent in humans; human trials were abandoned due to profound hypotensive and central depressant effects.',
    discoveryHistory:
        'Repurposed in the late 1960s exclusively for veterinary medicine. Recently emerged as a major illicit adulterant in the human drug supply ("Tranq / Tranq-Dope"), combined with illicit fentanyl, causing severe necrotic skin ulcers.',
    syntheticRoute:
        'Reaction of 2,6-dimethylphenyl isothiocyanate with 3-amino-1-propanol, followed by acid-catalyzed cyclization of the intermediate thiourea into the 1,3-thiazine ring.',
    molecularTarget:
        'Central and Peripheral Alpha-2A and Alpha-2D Adrenergic Receptors (α2:α1 selectivity ratio ~160:1).',
    pdbAccession: '6KUW / 7D77',
    modeOfAction:
        'Xylazine selectively stimulates presynaptic alpha-2 adrenergic auto-receptors in the locus coeruleus and spinal cord dorsal horn. Activation of the coupled Gi/o protein inhibits adenylyl cyclase, reducing intracellular cAMP, while opening inwardly rectifying potassium channels (GIRK) and closing voltage-gated N-type calcium channels. This hyperpolarizes neurons and shuts down the release of norepinephrine and substance P, producing deep central sedation, hypnosis, muscle relaxation, and analgesia.',
    downstreamSignaling:
        'Gi/o activation → decreased cAMP + PKA inhibition → reduced presynaptic vesicle fusion (synaptotagmin/SNARE complex arrest) → cessation of sympathetic adrenergic outflow.',
    absorptionAndDistribution:
        'Rapidly absorbed following intramuscular or intravenous injection. Onset of action: 1–2 minutes IV, 5–10 minutes IM. Highly lipophilic, rapidly crossing the blood-brain barrier. Vd: 1.9–2.5 L/kg.',
    metabolismAndElimination:
        'Rapidly metabolized by hepatic cytochrome P450 enzymes into approximately 20 metabolites (predominantly 2,6-dimethylaniline and thiazine-cleaved products). Only < 8% excreted unchanged in urine.',
    eliminationHalfLifeHours: 0.8, // Equine 50 mins; canine 30 mins
    comparativeSpeciesPharmacology:
        '🐾 DVM High-Yield Species Sensitivity Gradient: Ruminants (cattle, sheep, goats) are 10 TIMES MORE SENSITIVE to xylazine than horses, dogs, or cats due to the presence of the unique α2D-adrenergic receptor subtype in ruminants. Bovine dose is strictly 1/10th of the equine dose. Furthermore, in sheep, xylazine triggers acute pulmonary edema and hypoxia through activation of pulmonary intravascular macrophages (PIMs). In felines, xylazine reliably triggers the chemoreceptor trigger zone (CTZ), making it the classic veterinary drug of choice to induce emesis for gastric decontamination.',
    transitionStateDescription:
        'Hydrogen bonding of the protonated nitrogen with Asp-113 in the transmembrane helix 3 (TM3) of the alpha-2 receptor, with the 2,6-dimethylphenyl ring nestled into a hydrophobic pocket formed by Phe-412 and Trp-388.',
    activationBarrierKcalMol: 14.1,
    catalyticResidues: 'Alpha-2A Asp-113, Ser-200, Phe-412, Trp-388',
    associatedReactionId: 'vet-xylazine-01',
    contraindications:
        'Severe cardiac disease (produces marked 1st and 2nd degree AV block and severe bradycardia), advanced dehydration, respiratory depression, mechanical intestinal obstruction, late-stage pregnancy in cattle (can induce premature labor due to oxytocin-like uterine contractions).',
    adverseEffectsAndToxicity:
        'Severe bradycardia (biphasic blood pressure: transient hypertension followed by sustained hypotension and low cardiac output), second-degree atrioventricular block, hypothermia, ruminal bloat (tympaty), hyperglycemia (inhibition of insulin release from pancreatic beta cells). In humans ("Tranq"): necrotic skin ulcerations.',
    blackBoxWarning:
        'NOT APPROVED FOR HUMAN USE. In veterinary medicine: Ruminants require 10% of equine dose; can cause fatal acute pulmonary edema in sheep.',
    antidoteAndRescue:
        'SPECIFIC RECEPTOR ANTAGONISTS AVAILABLE: Atipamezole (Antisedan) or Yohimbine or Tolazoline. Immediate IV or IM administration of atipamezole competitive alpha-2 antagonist rapidly reverses sedation and bradycardia within 2–5 minutes.',
    clinicalGuidelines: [
      'ACVAA Anesthesia & Analgesia Guidelines for Equine, Ruminant, and Small Animal Practice',
      'AAEP Equine Chemical Restraint and Anesthetic Standards',
    ],
    primaryDoi: '10.1016/j.forsciint.2021.110903',
    pubmedId: '34418659',
    highYieldExamPearls: [
      'Bovine dose of xylazine is 1/10th of the equine dose due to extreme α2D sensitivity.',
      'Classic drug used to induce emesis in cats (activates CTZ).',
      'Causes biphasic hemodynamics: initial peripheral vasoconstriction followed by sustained bradycardia and hypotension.',
      'Reversed completely and specifically by Atipamezole or Yohimbine.',
    ],
  ),

  // ── NEPHROLOGY & RENAL PHARMACOKINETICS ──────────────────────────────────
  MedicinePharmacologyProfile(
    id: 'pharma-furosemide',
    genericName: 'Furosemide',
    iupacName: '4-chloro-2-(furan-2-ylmethylamino)-5-sulfamoylbenzoic acid',
    brandNames: ['Lasix', 'Salix', 'Frusid', 'Dimazon'],
    targetDisciplines: [
      TargetDiscipline.mbbs,
      TargetDiscipline.pharmD,
      TargetDiscipline.dvm,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.nephrology,
    chemicalClass: 'Anthranilic Acid Sulfonamide High-Ceiling Loop Diuretic',
    therapeuticIndications:
        'Human: Acute pulmonary edema, congestive heart failure (NYHA Class II–IV), hepatic cirrhosis with ascites, nephrotic syndrome, acute hypercalcemia, hypertensive crises. Veterinary: Canine and feline cardiogenic pulmonary edema (congestive heart failure), exercise-induced pulmonary hemorrhage (EIPH) in racehorses ("bleeder" medication).',
    clinicalStaging:
        'First-line emergency diuretic in acute decompensated heart failure with volume overload. IV administration produces immediate venodilation within 5 minutes, followed by profound diuresis starting within 15–20 minutes.',
    sourceAndOrigin:
        'Synthetically created anthranilic acid derivative developed by Hoechst AG in 1962, combining a sulfonamide moiety with a furanmethyl substituent to maximize luminal Na-K-2Cl cotransporter inhibition.',
    discoveryHistory:
        'Introduced in 1964 as the prototype "high-ceiling" loop diuretic, replacing toxic mercurial diuretics and revolutionizing acute cardiopulmonary resuscitation.',
    syntheticRoute:
        'Nucleophilic aromatic substitution of 2,4-dichloro-5-sulfamoylbenzoic acid with 2-(aminomethyl)furan in the presence of base.',
    molecularTarget:
        'Luminal Na⁺/K⁺/2Cl⁻ Cotransporter Isoform 2 (NKCC2 / SLC12A1) in the Thick Ascending Limb (TAL) of the Loop of Henle.',
    pdbAccession: '7W6Q / 6N38',
    modeOfAction:
        'Furosemide must reach the tubular lumen to act. It is > 95% protein bound and reaches the lumen via active organic anion transporter (OAT1/OAT3) secretion in the proximal convoluted tubule. In the thick ascending limb (TAL), it reversibly competes with chloride ions for the Cl⁻-binding site on the luminal NKCC2 cotransporter. Blocking NKCC2 abolishes the reabsorption of 25% of the filtered sodium load. By stopping active Na⁺ and Cl⁻ pumping into the medullary interstitium, furosemide eliminates the corticomedullary osmotic gradient, preventing water reabsorption from the collecting duct even in the presence of ADH (vasopressin). Furthermore, inhibition of NKCC2 collapses the positive lumen-potential (+8 to +10 mV) generated by ROMK potassium recycling, causing secondary renal wasting of Ca²⁺ and Mg²⁺.',
    downstreamSignaling:
        'Massive natriuresis and chloriuresis; acute renal production of prostaglandin E₂ (PGE₂) which increases renal blood flow and causes immediate systemic venous capacitance relaxation before diuresis begins.',
    absorptionAndDistribution:
        'Oral bioavailability is variable (10–90%, average ~50%). Protein binding is extremely high (95–99% to albumin). Volume of distribution: 0.1–0.2 L/kg.',
    metabolismAndElimination:
        'Excreted predominantly unchanged via the kidneys (~65–80%) through active proximal tubular secretion (OAT1/3). A small fraction is glucuronidated in the kidney. In renal failure, systemic half-life is significantly prolonged.',
    eliminationHalfLifeHours: 1.5,
    comparativeSpeciesPharmacology:
        '🐾 DVM Equine & Small Animal Pearl: (1) In thoroughbred racehorses, furosemide is administered 4 hours pre-race to prevent Exercise-Induced Pulmonary Hemorrhage (EIPH / epistaxis) by lowering peak pulmonary artery pressures during maximum exertion. (2) In cats with acute congestive heart failure, over-diuresis quickly causes severe prerenal azotemia and dehydration due to small feline blood volume; dosing must be carefully titrated (1–2 mg/kg IV/IM).',
    transitionStateDescription:
        'Coordination of the sulfonamide and carboxylate oxygen atoms to the central ion translocation pore of the NKCC2 homodimer, directly competing with the second chloride ion binding pocket.',
    activationBarrierKcalMol: 16.0,
    catalyticResidues: 'NKCC2 Leu-219, Tyr-305, Pro-220, Ile-223',
    associatedReactionId: 'med-furosemide-01',
    contraindications:
        'Anuria refractory to test doses, severe hypokalemia, severe hyponatremia, hepatic coma/encephalopathy, hypersensitivity to sulfonamides.',
    adverseEffectsAndToxicity:
        'Hypokalemia (can trigger fatal digoxin toxicity or ventricular arrhythmias), hypomagnesemia, hypocalcemia (unlike thiazides which cause hypercalcemia), contraction metabolic alkalosis, ototoxicity (tinnitus, permanent sensorineural hearing loss, especially when combined with aminoglycosides), hyperuricemia (gout).',
    blackBoxWarning:
        'POTENT DIURETIC: Profound diuresis with water and electrolyte depletion may lead to circulatory collapse, hypovolemic shock, and fatal thromboembolism if unmonitored.',
    antidoteAndRescue:
        'For over-diuresis and volume contraction: immediate intravenous isotonic saline (0.9% NaCl) and aggressive potassium chloride (KCl) repletion. Ototoxicity risk is minimized by administering IV doses at slow infusion rates (≤ 4 mg/min).',
    clinicalGuidelines: [
      'AHA/ACC/HFSA Guideline for the Management of Heart Failure (Class I recommendation)',
      'ACVIM Consensus Statement: Guidelines for the Diagnosis and Treatment of Myxomatous Mitral Valve Disease in Dogs',
    ],
    primaryDoi: '10.1056/NEJMoa1005419',
    pubmedId: '21366472',
    highYieldExamPearls: [
      'Acts on the thick ascending limb of loop of Henle by inhibiting NKCC2.',
      'Loop diuretics "lose" calcium (hypocalcemia), whereas Thiazide diuretics "save" calcium (hypercalcemia).',
      'Causes hypokalemic hypochloremic contraction metabolic alkalosis.',
      'Ototoxicity is exacerbated when co-administered with aminoglycoside antibiotics.',
    ],
  ),

  // ── VETERINARY ZOONOTICS & ANTHELMINTICS ──────────────────────────────────
  MedicinePharmacologyProfile(
    id: 'pharma-ivermectin',
    genericName: 'Ivermectin (22,23-dihydroavermectin B1a + B1b)',
    iupacName:
        'Mixture of 5-O-demethyl-22,23-dihydroavermectin A1a (~80%) and 5-O-demethyl-25-de(1-methylpropyl)-22,23-dihydro-25-(1-methylethyl)avermectin A1a (~20%)',
    brandNames: ['Heartgard', 'Stromectol', 'Ivomec', 'Noromectin', 'Soolantra'],
    targetDisciplines: [
      TargetDiscipline.dvm,
      TargetDiscipline.mbbs,
      TargetDiscipline.pharmD,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.veterinaryMedicine,
    chemicalClass: 'Macrocyclic Lactone Endectocide (Avermectin derivative)',
    therapeuticIndications:
        'Veterinary: Canine heartworm prophylaxis (Dirofilaria immitis microfilaricide), gastrointestinal nematodes, sarcoptic and demodectic mange, ear mites (Otodectes cynotis). Livestock: Cattle/sheep gastrointestinal roundworms, lungworms, sucking lice, mange mites, and cattle grubs (Hypoderma bovis). Human: Onchocerciasis (river blindness caused by Onchocerca volvulus), lymphatic filariasis (elephantiasis), strongyloidiasis, and crusted scabies.',
    clinicalStaging:
        'Human WHO Essential Medicine (Mectizan Donation Program). Veterinary monthly preventive dose in canines: 6 µg/kg PO (heartworm prophylaxis); therapeutic acariasis dose: 300–600 µg/kg PO/SC.',
    sourceAndOrigin:
        'Semisynthetic derivative of avermectins, naturally produced by the soil-dwelling actinobacterium Streptomyces avermitilis, discovered by Satoshi Ōmura in Kawana, Japan, and isolated by William C. Campbell at Merck.',
    discoveryHistory:
        'Satoshi Ōmura and William C. Campbell were awarded the 2015 Nobel Prize in Physiology or Medicine for the discovery of avermectins, which virtually eradicated river blindness in West Africa.',
    syntheticRoute:
        'Selective catalytic hydrogenation of avermectin B1 using Wilkinson\'s rhodium catalyst (RhCl(PPh₃)₃) to saturate the 22,23-double bond while leaving the 3,4 and 8,9-double bonds intact.',
    molecularTarget:
        'Glutamate-Gated Chloride Channels (GluCl) and secondary GABA-gated chloride channels in invertebrate nematodes and arthropods.',
    pdbAccession: '3RIF / 3RHW',
    modeOfAction:
        'Ivermectin binds with high selectivity and nanomolar affinity to the transmembrane domain of invertebrate-specific glutamate-gated chloride (GluCl) channels located in nematode pharyngeal and somatic nerve and muscle cells. It acts as an allosteric agonist, locking the channel in an open, activated state. The resulting persistent, irreversible influx of chloride ions hyperpolarizes the parasite\'s resting membrane potential, preventing action potential generation. This paralyzes the pharyngeal pump (preventing ingestion of nutrients) and causes flaccid somatic muscle paralysis, leading to clearance by the host immune system.',
    downstreamSignaling:
        'Invertebrate neuron/muscle hyperpolarization via unregulated chloride influx → loss of neuromuscular transmission → flaccid muscular paralysis and parasite starvation.',
    absorptionAndDistribution:
        'High lipophilicity. Well absorbed orally and topically; subcutaneous formulations form a tissue depot in subcutaneous fat providing sustained microfilarial suppression. Vd is large (2.4–4.7 L/kg). Poor penetration across an intact mammalian blood-brain barrier due to active P-glycoprotein efflux.',
    metabolismAndElimination:
        'Extensively metabolized by hepatic CYP3A into hydroxylated metabolites. Excreted almost entirely in feces (> 98%) via biliary transport, with < 2% in urine.',
    eliminationHalfLifeHours: 18.0, // Canine 18–48h; bovine up to 5–7 days
    comparativeSpeciesPharmacology:
        '🐾 DVM High-Yield Genetic Toxicological Pearl: In normal mammals, ivermectin does NOT cross the blood-brain barrier because the BBB endothelial cells express P-glycoprotein (P-gp), encoded by the ABCB1 (MDR1) gene, which actively pumps ivermectin back into systemic circulation. However, ~70% of Collie-lineage herding breeds (Rough Collies, Smooth Collies, Australian Shepherds, Shetland Sheepdogs) carry a homozygous 4-base pair deletion mutation (ABCB1-1Δ / MDR1 mutation). In these dogs, P-gp is truncated and non-functional. High-dose ivermectin (used for mange: 300–600 µg/kg) penetrates the CNS unchecked, binds to mammalian GABA-A receptors, and causes severe neurotoxicity: mydriasis, ataxia, tremors, hypersalivation, coma, and respiratory death! Note: the monthly heartworm preventative dose (6 µg/kg) is safe even in MDR1-mutant dogs.',
    transitionStateDescription:
        'Binding to the subunit interface in the upper transmembrane domain of GluCl, inserting between M1 and M3 helices and expanding the pore diameter to trap the open channel conformation.',
    activationBarrierKcalMol: 18.8,
    catalyticResidues: 'GluCl Leu-218, Ser-260, Thr-285, Ile-222',
    associatedReactionId: 'vet-ivermectin-01',
    contraindications:
        'High-dose therapy (> 100 µg/kg) in dogs homozygous for the ABCB1/MDR1 mutation; turtles, tortoises, and indigo snakes (ivermectin crosses their blood-brain barrier causing fatal flaccid paralysis); microfilaria-positive heartworm dogs without supervision (massive microfilarial die-off triggers fatal anaphylactoid shock).',
    adverseEffectsAndToxicity:
        'Mazzotti reaction in human onchocerciasis (fever, hypotension, pruritus, arthralgia due to death of microfilariae). In MDR1-mutant canines: blindness, stupor, coma, hyper-reflexia, seizures, respiratory arrest.',
    blackBoxWarning:
        'MDR1 (ABCB1) GENETIC TESTING MANDATORY before administering high-dose macrocyclic lactones to Collies, Australian Shepherds, and related breeds.',
    antidoteAndRescue:
        'No specific competitive receptor reversal agent exists. Intensive supportive care: mechanical ventilation, intravenous lipid emulsion (ILE / "lipid rescue" 20% Intralipid) to partition the lipophilic ivermectin out of CNS tissue into a circulating vascular lipid sink.',
    clinicalGuidelines: [
      'American Heartworm Society (AHS) Canine Guidelines for Prevention and Treatment',
      'CAPC (Companion Animal Parasite Council) Guidelines on Dirofilaria immitis',
      'WHO Guidelines for the Treatment of Onchocerciasis and Lymphatic Filariasis',
    ],
    primaryDoi: '10.1038/nature10206',
    pubmedId: '21743477',
    highYieldExamPearls: [
      'Binds selectively to glutamate-gated chloride (GluCl) channels unique to invertebrates.',
      'Satoshi Ōmura & William Campbell won the 2015 Nobel Prize for its discovery.',
      'P-glycoprotein (MDR1/ABCB1) keeps ivermectin out of the mammalian brain.',
      'Collies with homozygous MDR1 mutation suffer fatal neurotoxicity due to absent P-gp efflux.',
      'Lipid rescue (IV Intralipid) is the emergency management protocol for avermectin overdose.',
    ],
  ),

  // ── ONCOLOGY & CHEMOTHERAPY ───────────────────────────────────────────────
  MedicinePharmacologyProfile(
    id: 'pharma-methotrexate',
    genericName: 'Methotrexate (MTX / Amethopterin)',
    iupacName:
        '(2S)-2-[[4-[(2,4-diaminopteridin-6-yl)methyl-methylamino]benzoyl]amino]pentanedioic acid',
    brandNames: ['Trexall', 'Otrexup', 'Rasuvo', 'Rheumatrex'],
    targetDisciplines: [
      TargetDiscipline.mbbs,
      TargetDiscipline.pharmD,
      TargetDiscipline.specialist,
    ],
    specialty: PharmacologicalSpecialty.oncology,
    chemicalClass: 'Antifolate Antimetabolite',
    therapeuticIndications:
        'Oncology: Acute lymphoblastic leukemia (ALL), non-Hodgkin lymphoma, osteosarcoma, choriocarcinoma, head and neck cancers, breast cancer. Rheumatology & Dermatology: Severe rheumatoid arthritis (first-line disease-modifying antirheumatic drug / DMARD), recalcitrant psoriasis, Crohn\'s disease, ectopic pregnancy medical termination.',
    clinicalStaging:
        'High-dose MTX (> 500 mg/m² IV) in pediatric ALL and osteosarcoma protocols requires mandatory systemic Leucovorin (folinic acid) rescue and urinary alkalinization.',
    sourceAndOrigin:
        'Synthetic antimetabolite synthesized in 1947 by Yellapragada Subbarow and Sidney Farber at Lederle Laboratories as a 4-amino, N10-methyl structural analogue of folic acid.',
    discoveryHistory:
        'Sidney Farber noticed that folic acid accelerated acute leukemia in children; he developed folate antagonists (aminopterin and methotrexate) to induce the first remissions in childhood leukemia, founding modern cancer chemotherapy.',
    syntheticRoute:
        'Condensation of 2,4,5,6-tetraaminopyrimidine with 1,1,3-trichloroacetone and 4-(methylamino)benzoyl-L-glutamic acid.',
    molecularTarget:
        'Dihydrofolate Reductase (DHFR) and secondary Thymidylate Synthase.',
    pdbAccession: '1U72 / 4DFR',
    modeOfAction:
        'Methotrexate enters mammalian cells via the Reduced Folate Carrier 1 (RFC1 / SLC19A1). Intracellularly, folylpolyglutamate synthetase (FPGS) sequentially adds glutamate residues to MTX, forming polyglutamated MTX (MTX-Glu_n), which is trapped within the cell. MTX-Glu competitive binds to the catalytic pocket of Dihydrofolate Reductase (DHFR) with a dissociation constant (Kd ≈ 0.01 nM) that is 1,000-fold tighter than the natural substrate dihydrofolate (DHF). Inhibition of DHFR blocks the regeneration of tetrahydrofolate (THF), starving cells of single-carbon methyl donors (N5,N10-methylene-THF) essential for the de novo synthesis of thymidylate (dTMP) from dUMP, and for purine biosynthesis (IMP). This halts DNA replication and triggers S-phase cell cycle arrest and apoptosis.',
    downstreamSignaling:
        'Thymine-less death: Depletion of dTTP leads to incorporation of dUTP into replicating DNA; futile DNA repair glycosylase cycles produce double-stranded breaks and p53-dependent apoptotic death.',
    absorptionAndDistribution:
        'Dose-dependent oral absorption (saturable active transport in gut; high doses must be given parenterally). Protein binding is ~50%. Widely distributed, but poor baseline CSF penetration unless administered intrathecally or at ultra-high intravenous doses (> 1 g/m²). MTX accumulates in "third-space" fluid collections (ascites, pleural effusions) which act as slow-release reservoirs causing prolonged toxicity.',
    metabolismAndElimination:
        'Partially converted to 7-hydroxymethotrexate by hepatic aldehyde oxidase. Excretion is > 80–90% renal via glomerular filtration and active proximal tubular secretion (inhibited by NSAIDs, penicillins, and proton pump inhibitors).',
    eliminationHalfLifeHours: 6.0, // Terminal phase 3–15h
    comparativeSpeciesPharmacology:
        'Used in canine veterinary oncology for refractory lymphoma and osteosarcoma. However, dogs exhibit lower gastrointestinal tolerance to antifolates than humans, frequently developing severe hemorrhagic enteritis and sloughing of intestinal crypt cells; consequently, lower relative dosing protocols are mandatory in veterinary patients.',
    transitionStateDescription:
        'Pteridine ring protonation at N1 forming an exceptionally stable bifurcated hydrogen bond network with Asp-27 and NADPH cofactor in the deep catalytic cleft of DHFR.',
    activationBarrierKcalMol: 16.8,
    catalyticResidues: 'DHFR Asp-27, Ile-5, Phe-31, Arg-57',
    associatedReactionId: 'med-methotrexate-01',
    contraindications:
        'Pregnancy (Category X: potent teratogen / abortifacient), breastfeeding, severe pre-existing renal insufficiency (GFR < 30 mL/min), severe liver disease, pre-existing bone marrow aplasia.',
    adverseEffectsAndToxicity:
        'Bone marrow suppression (myelosuppression: neutropenia, thrombocytopenia), mucosal ulcerations (stomatitis, mucositis), hepatotoxicity (steatohepatitis and cirrhosis with chronic low-dose use), acute nephrotoxicity (MTX crystals precipitating in renal tubules in acidic urine), hypersensitivity pneumonitis.',
    blackBoxWarning:
        'FATAL TOXICITY WARNING: Methotrexate for rheumatoid arthritis or psoriasis is taken ONCE WEEKLY, NOT DAILY. Accidental daily dosing has caused fatal bone marrow suppression and GI perforation. High-dose chemotherapy requires Leucovorin rescue.',
    antidoteAndRescue:
        'LEUCOVORIN (Folinic acid / 5-formyl-THF) RESCUE: Leucovorin bypasses DHFR, providing downstream reduced folate to rescue non-cancerous cells. For acute renal failure with toxic MTX concentrations: GLUCARPIDASE (Voraxaze / carboxypeptidase G2) rapidly cleaves extracellular MTX into inactive DAMPA, dropping plasma levels by > 95% in 15 minutes.',
    clinicalGuidelines: [
      'NCCN Clinical Practice Guidelines in Oncology: Pediatric Acute Lymphoblastic Leukemia',
      'ACR (American College of Rheumatology) Guideline for the Treatment of Rheumatoid Arthritis',
    ],
    primaryDoi: '10.1056/NEJMra1314811',
    pubmedId: '24694326',
    highYieldExamPearls: [
      'Methotrexate competitively and pseudoirreversibly inhibits Dihydrofolate Reductase (DHFR).',
      'Intracellular polyglutamation by FPGS traps MTX inside cells and dramatically increases potency.',
      'Leucovorin (folinic acid) bypasses DHFR and rescues bone marrow and gastrointestinal cells.',
      'Drug interactions: NSAIDs, penicillins, and PPIs compete for renal tubular secretion, causing fatal MTX toxicity.',
      'Glucarpidase is the recombinant rescue enzyme for life-threatening methotrexate toxicity.',
    ],
  ),
];
