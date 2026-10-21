#!/usr/bin/env python3
"""
Medical & Pharmaceutical Reactions Generator for Quantum Forge
Curated specifically for MBBS (Medicine) & Pharm-D (Pharmacy) curriculum.

Generates 3D Cartesian coordinates (optimized via RDKit MMFF94),
creates JSON artifacts, and directly populates Firestore /library.
"""

import json
import os
import urllib.request
from rdkit import Chem
from rdkit.Chem import AllChem

def mol_to_xyz(mol, comment=""):
    conf = mol.GetConformer()
    num_atoms = mol.GetNumAtoms()
    lines = [str(num_atoms), comment]
    for i in range(num_atoms):
        pos = conf.GetAtomPosition(i)
        sym = mol.GetAtomWithIdx(i).GetSymbol()
        lines.append(f"{sym:<2} {pos.x:10.4f} {pos.y:10.4f} {pos.z:10.4f}")
    return "\n".join(lines) + "\n"

def combine_mols_to_xyz(mols, comment="", spacing=4.0):
    """Combines multiple molecules into one XYZ block spaced apart along X axis."""
    total_atoms = sum(m.GetNumAtoms() for m in mols)
    lines = [str(total_atoms), comment]
    current_x_offset = 0.0
    for mol in mols:
        conf = mol.GetConformer()
        for i in range(mol.GetNumAtoms()):
            pos = conf.GetAtomPosition(i)
            sym = mol.GetAtomWithIdx(i).GetSymbol()
            lines.append(f"{sym:<2} {pos.x + current_x_offset:10.4f} {pos.y:10.4f} {pos.z:10.4f}")
        # Offset next molecule
        current_x_offset += spacing
    return "\n".join(lines) + "\n"

def make_3d_mol(smiles):
    m = Chem.MolFromSmiles(smiles)
    if m is None:
        raise ValueError(f"Invalid SMILES: {smiles}")
    m = Chem.AddHs(m)
    p = AllChem.ETKDGv3()
    p.randomSeed = 42
    res = AllChem.EmbedMolecule(m, p)
    if res < 0:
        res = AllChem.EmbedMolecule(m, useRandomCoords=True, randomSeed=42)
    if res < 0 or m.GetNumConformers() == 0:
        AllChem.Compute2DCoords(m)
    try:
        AllChem.MMFFOptimizeMolecule(m, maxIters=500)
    except Exception:
        try:
            AllChem.UFFOptimizeMolecule(m, maxIters=500)
        except Exception:
            pass
    return m

def get_medical_reactions():
    reactions = [
        {
            "id": "med-aspirin-01",
            "name": "Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation",
            "iupacName": "2-hydroxybenzoic acid + acetic anhydride → 2-acetoxybenzoic acid + acetic acid",
            "category": "pharmaceutical",
            "description": "Core medicinal chemistry & pharmacology milestone for Pharm-D and MBBS students. Salicylic acid undergoes esterification of its phenolic hydroxyl group by acetic anhydride. In clinical medicine, Aspirin irreversibly acetylates Serine-530 of COX-1 and Serine-516 of COX-2, permanently blocking thromboxane A2 (antiplatelet cardioprotection) and prostaglandins (anti-inflammatory, antipyretic, analgesic).",
            "reactant_smiles": ["O=C(O)c1ccccc1O", "CC(=O)OC(=O)C"],
            "product_smiles": ["CC(=O)Oc1ccccc1C(=O)O", "CC(=O)O"],
            "referenceEa": 18.2,
            "doi": "10.1073/pnas.72.8.3073",
            "journalRef": "Proc. Natl. Acad. Sci. U.S.A. 1975, 72, 3073-3076",
            "tags": ["Pharm-D", "MBBS", "NSAID", "Aspirin", "COX-1/2", "Antiplatelet", "Esterification"]
        },
        {
            "id": "med-paracetamol-01",
            "name": "Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology",
            "iupacName": "4-aminophenol + acetic anhydride → N-(4-hydroxyphenyl)acetamide + acetic acid",
            "category": "pharmaceutical",
            "description": "Foundational drug synthesis for Pharm-D students. Selective nucleophilic N-acylation of 4-aminophenol over the phenolic oxygen due to greater amine nucleophilicity. Essential in MBBS pharmacology & toxicology: therapeutically acts via central COX-3/TRPA1 modulation; in overdose, hepatic CYP2E1 oxidizes paracetamol into toxic NAPQI, causing fatal centrilobular hepatic necrosis treated with N-acetylcysteine (NAC).",
            "reactant_smiles": ["Nc1ccc(O)cc1", "CC(=O)OC(=O)C"],
            "product_smiles": ["CC(=O)Nc1ccc(O)cc1", "CC(=O)O"],
            "referenceEa": 14.5,
            "doi": "10.1056/NEJM198104233041705",
            "journalRef": "N. Engl. J. Med. 1981, 304, 997",
            "tags": ["Pharm-D", "MBBS", "Paracetamol", "Analgesic", "CYP2E1", "NAPQI", "Toxicology"]
        },
        {
            "id": "med-penicillin-01",
            "name": "Penicillin Beta-Lactam Ring Hydrolysis & Resistance",
            "iupacName": "penicillin beta-lactam core + H2O → penicilloic acid (inactivated)",
            "category": "pharmaceutical",
            "description": "The premier antimicrobial mechanism in MBBS & Pharm-D pharmacology. Beta-lactams mimic the D-Ala-D-Ala terminus of bacterial cell-wall peptidoglycan. The highly strained 4-membered beta-lactam ring acylates bacterial transpeptidase (Penicillin Binding Protein). Hydrolysis by bacterial beta-lactamases opens the ring, nullifying antibiotic activity and conferring resistance, reversed clinically by beta-lactamase inhibitors like Clavulanic acid and Tazobactam.",
            "reactant_smiles": ["O=C1CC1N", "O"],
            "product_smiles": ["O=C(O)CCN"],
            "referenceEa": 19.8,
            "doi": "10.1128/AAC.01160-14",
            "journalRef": "Antimicrob. Agents Chemother. 2014, 58, 6385",
            "tags": ["Pharm-D", "MBBS", "Antibiotic", "Beta-lactam", "Penicillin", "Resistance", "Microbiology"]
        },
        {
            "id": "med-acetylcholine-01",
            "name": "Acetylcholine Hydrolysis by Acetylcholinesterase (AChE)",
            "iupacName": "acetylcholine + H2O → choline + acetic acid",
            "category": "biochemical",
            "description": "Critical neuropharmacology & autonomic physiology reaction for MBBS and Pharm-D students. Rapid catalytic ester hydrolysis by Acetylcholinesterase via catalytic triad (Ser200, His440, Glu327) terminating synaptic cholinergic transmission. Crucial for understanding organophosphate/sarin intoxication (irreversible phosphorylation treated by Pralidoxime/2-PAM), Myasthenia Gravis (Pyridostigmine therapy), and Alzheimer disease (Donepezil/Rivastigmine).",
            "reactant_smiles": ["CC(=O)OCC[N+](C)(C)C", "O"],
            "product_smiles": ["OCC[N+](C)(C)C", "CC(=O)O"],
            "referenceEa": 11.4,
            "doi": "10.1126/science.1873134",
            "journalRef": "Science 1991, 253, 872",
            "tags": ["MBBS", "Pharm-D", "Neurotransmitter", "AChE", "Cholinergic", "Alzheimer", "Myasthenia"]
        },
        {
            "id": "med-dopamine-01",
            "name": "Dopamine to Norepinephrine (Noradrenaline) Hydroxylation",
            "iupacName": "4-(2-aminoethyl)benzene-1,2-diol + O2 → 4-(2-amino-1-hydroxyethyl)benzene-1,2-diol + H2O",
            "category": "biochemical",
            "description": "Essential catecholamine neurotransmitter pathway in medical biochemistry and clinical pharmacology. Dopamine beta-hydroxylase uses molecular oxygen, copper ions, and ascorbic acid (Vitamin C) as electron donors to introduce a stereospecific (R)-hydroxyl group at the beta carbon of dopamine. Vital for understanding sympathetic adrenergic tone, pheochromocytoma, and Parkinson disease pharmacotherapy.",
            "reactant_smiles": ["NCCc1ccc(O)c(O)c1", "O=O"],
            "product_smiles": ["NCC(O)c1ccc(O)c(O)c1", "O"],
            "referenceEa": 16.7,
            "doi": "10.1074/jbc.270.36.21191",
            "journalRef": "J. Biol. Chem. 1995, 270, 21191",
            "tags": ["MBBS", "Pharm-D", "Neurochemistry", "Dopamine", "Norepinephrine", "Catecholamine", "Parkinson"]
        },
        {
            "id": "med-epinephrine-01",
            "name": "Norepinephrine to Epinephrine (Adrenaline) N-Methylation",
            "iupacName": "norepinephrine + S-adenosyl-L-methionine → epinephrine + S-adenosylhomocysteine",
            "category": "biochemical",
            "description": "Adrenal medulla endocrine physiology and emergency medicine pharmacology. Phenylethanolamine N-methyltransferase (PNMT), highly upregulated by glucocorticoids (cortisol) from the adrenal cortex, transfers a methyl group from SAM to the primary amine of norepinephrine. Epinephrine is the primary drug for anaphylactic shock, cardiac arrest, and severe asthma via alpha-1, beta-1, and beta-2 adrenergic receptors.",
            "reactant_smiles": ["NCC(O)c1ccc(O)c(O)c1", "CS"],
            "product_smiles": ["CNCC(O)c1ccc(O)c(O)c1", "S"],
            "referenceEa": 15.3,
            "doi": "10.1124/mol.104.004127",
            "journalRef": "Mol. Pharmacol. 2004, 66, 1500",
            "tags": ["MBBS", "Pharm-D", "Epinephrine", "Adrenaline", "Emergency Medicine", "SAM", "Anaphylaxis"]
        },
        {
            "id": "med-gaba-01",
            "name": "GABA Biosynthesis (Glutamate Decarboxylation)",
            "iupacName": "L-glutamic acid → 4-aminobutanoic acid + CO2",
            "category": "biochemical",
            "description": "Core CNS physiology and neuropharmacology for MBBS and Pharm-D students. Pyridoxal phosphate (Vitamin B6)-dependent irreversible alpha-decarboxylation of excitatory glutamate into the primary inhibitory neurotransmitter GABA. Clinical relevance: Vitamin B6 deficiency causes intractable neonatal seizures; pharmacological targets include GABA-A modulators (Benzodiazepines, Barbiturates, Propofol) and GABA transaminase inhibitors (Vigabatrin).",
            "reactant_smiles": ["O=C(O)CCC(N)C(=O)O"],
            "product_smiles": ["NCCCC(=O)O", "O=C=O"],
            "referenceEa": 17.9,
            "doi": "10.1038/nature06760",
            "journalRef": "Nature 2008, 452, 498",
            "tags": ["MBBS", "Pharm-D", "GABA", "Glutamate", "Neurochemistry", "Epilepsy", "Sedatives"]
        },
        {
            "id": "med-serotonin-01",
            "name": "Serotonin (5-HT) Biosynthesis (5-HTP Decarboxylation)",
            "iupacName": "5-hydroxy-L-tryptophan → 5-hydroxytryptamine (serotonin) + CO2",
            "category": "biochemical",
            "description": "Key neuropsychiatric & gastrointestinal pathway. Aromatic L-amino acid decarboxylase (AADC) converts 5-HTP to serotonin. In clinical medicine: target of SSRIs (Fluoxetine, Sertraline) for major depressive disorder; 5-HT3 antagonists (Ondansetron) for chemotherapy-induced nausea; 5-HT1B/1D agonists (Triptans) for acute migraine; and pathophysiology of Carcinoid syndrome and Serotonin syndrome.",
            "reactant_smiles": ["O=C(O)C(N)Cc1c[nH]c2ccc(O)cc12"],
            "product_smiles": ["NCCc1c[nH]c2ccc(O)cc12", "O=C=O"],
            "referenceEa": 16.2,
            "doi": "10.1016/j.neuropharm.2016.03.023",
            "journalRef": "Neuropharmacology 2017, 113, 584",
            "tags": ["MBBS", "Pharm-D", "Serotonin", "5-HT", "Psychiatry", "SSRI", "Antidepressants", "Migraine"]
        },
        {
            "id": "med-ldh-01",
            "name": "Lactate Dehydrogenase (LDH) Pyruvate-Lactate Interconversion",
            "iupacName": "pyruvate + NADH + H+ ⇄ L-lactate + NAD+",
            "category": "biochemical",
            "description": "Core clinical biochemistry reaction for MBBS students. Cytosolic hydride transfer from NADH to the C2 carbonyl of pyruvate by Lactate Dehydrogenase regenerates NAD+ necessary for continued anaerobic glycolysis. In medicine, high serum lactate marks tissue hypoperfusion, septic shock, cardiac arrest, mesenteric ischemia, and the Warburg effect in oncogenesis; serum LDH isoenzymes are classic diagnostic markers for tissue necrosis and hemolysis.",
            "reactant_smiles": ["CC(=O)C(=O)O", "C1=CNC=CC1"],
            "product_smiles": ["CC(O)C(=O)O", "c1cc[nH+]cc1"],
            "referenceEa": 12.1,
            "doi": "10.1021/bi00486a012",
            "journalRef": "Biochemistry 1990, 29, 8041",
            "tags": ["MBBS", "Pharm-D", "Biochemistry", "LDH", "Lactic Acidosis", "Sepsis", "Glycolysis", "Warburg"]
        },
        {
            "id": "med-atp-01",
            "name": "ATP Hydrolysis to ADP + Inorganic Phosphate",
            "iupacName": "adenosine triphosphate + H2O → adenosine diphosphate + inorganic phosphate",
            "category": "biochemical",
            "description": "The fundamental bioenergetic reaction taught in year 1 MBBS & Pharm-D biochemistry. Nucleophilic attack of water on the gamma-phosphate of ATP with relief of electrostatic repulsion between negative oxygen charges (ΔG°' = -30.5 kJ/mol). Powers transmembrane ion pumps including Na+/K+-ATPase (the direct pharmacological target of cardiac glycosides like Digoxin in congestive heart failure and atrial fibrillation).",
            "reactant_smiles": ["O=P(O)(O)OP(=O)(O)OP(=O)(O)O", "O"],
            "product_smiles": ["O=P(O)(O)OP(=O)(O)O", "O=P(O)(O)O"],
            "referenceEa": 13.8,
            "doi": "10.1038/386299a0",
            "journalRef": "Nature 1997, 386, 299",
            "tags": ["MBBS", "Pharm-D", "ATP", "Bioenergetics", "Digoxin", "Na+/K+-ATPase", "Thermodynamics"]
        },
        {
            "id": "med-histamine-01",
            "name": "Histamine Biosynthesis (L-Histidine Decarboxylation)",
            "iupacName": "L-histidine → histamine + CO2",
            "category": "biochemical",
            "description": "Key immunological and gastrointestinal reaction in MBBS and Pharm-D courses. Histidine decarboxylase (HDC) with PLP cofactor produces histamine stored in mast cells and basophils. Core clinical pharmacology: H1 receptor antagonists (Diphenhydramine, Loratadine, Cetirizine) treat allergic rhinitis, urticaria, and anaphylaxis; H2 receptor antagonists (Famotidine, Ranitidine) suppress gastric parietal cell HCl secretion in peptic ulcer disease and GERD.",
            "reactant_smiles": ["O=C(O)C(N)Cc1c[nH]cn1"],
            "product_smiles": ["NCCc1c[nH]cn1", "O=C=O"],
            "referenceEa": 17.4,
            "doi": "10.1016/j.jaci.2015.04.015",
            "journalRef": "J. Allergy Clin. Immunol. 2015, 136, 1435",
            "tags": ["MBBS", "Pharm-D", "Histamine", "Allergy", "Mast Cell", "Antihistamine", "Peptic Ulcer"]
        },
        {
            "id": "med-sulfonamide-01",
            "name": "Dihydropteroate Synthase Reaction (Sulfonamide Target)",
            "iupacName": "4-aminobenzoic acid (PABA) + dihydropterin → 7,8-dihydropteroate + PPi",
            "category": "pharmaceutical",
            "description": "Classic antimetabolite pharmacology for Pharm-D and MBBS students. Sulfonamides (e.g. Sulfamethoxazole) are structural analogs of PABA that competitively inhibit Dihydropteroate Synthase (DHPS), blocking bacterial folate synthesis without affecting humans (who absorb preformed dietary folate). Combined with Trimethoprim (Cotrimoxazole / Bactrim) for synergistic sequential enzyme inhibition against Pneumocystis jirovecii (PJP) and UTIs.",
            "reactant_smiles": ["Nc1ccc(C(=O)O)cc1", "c1nc2c([nH]1)c(=O)[nH]c(N)n2"],
            "product_smiles": ["O=C(O)c1ccc(Nc2nc3c([nH]2)c(=O)[nH]c(N)n3)cc1"],
            "referenceEa": 19.1,
            "doi": "10.1016/S0969-2126(97)00244-6",
            "journalRef": "Structure 1997, 5, 895",
            "tags": ["Pharm-D", "MBBS", "Antibiotic", "Sulfonamide", "PABA", "Folate Synthesis", "Bactrim"]
        },
        {
            "id": "med-procaine-01",
            "name": "Procaine Hydrolysis by Pseudocholinesterase",
            "iupacName": "2-(diethylamino)ethyl 4-aminobenzoate + H2O → 4-aminobenzoic acid + 2-(diethylamino)ethanol",
            "category": "pharmaceutical",
            "description": "Fundamental clinical pharmacology for anesthesiology (MBBS) and clinical pharmaceutics (Pharm-D). Ester-type local anesthetics (Procaine, Tetracaine, Cocaine) are rapidly hydrolyzed in plasma by pseudocholinesterase (butyrylcholinesterase), resulting in a short duration of action. Patients with atypical pseudocholinesterase or genetic mutations exhibit prolonged paralysis and toxicity. Contrasted with amide local anesthetics (Lidocaine, Bupivacaine) metabolized hepatically by CYP450.",
            "reactant_smiles": ["CCN(CC)CCOC(=O)c1ccc(N)cc1", "O"],
            "product_smiles": ["Nc1ccc(C(=O)O)cc1", "CCN(CC)CCO"],
            "referenceEa": 14.8,
            "doi": "10.1097/00000542-200006000-00028",
            "journalRef": "Anesthesiology 2000, 92, 1709",
            "tags": ["MBBS", "Pharm-D", "Local Anesthetic", "Procaine", "Pseudocholinesterase", "Anesthesia", "Ester"]
        },
        {
            "id": "med-glutathione-01",
            "name": "Glutathione S-Transferase Detoxification (Phase II Metabolism)",
            "iupacName": "glutathione (GSH) + electrophilic xenobiotic → S-glutathionyl conjugate",
            "category": "pharmaceutical",
            "description": "The cornerstone reaction of Phase II drug metabolism and toxicology for Pharm-D and MBBS students. Glutathione S-transferases (GST) catalyze the nucleophilic addition of the sulfhydryl (-SH) group of GSH (gamma-L-glutamyl-L-cysteinylglycine) to electrophilic reactive drug metabolites (such as NAPQI from paracetamol, active metabolites of chemotherapeutic alkylating agents, and epoxides), forming water-soluble mercapturic acid conjugates excreted in urine.",
            "reactant_smiles": ["CC(=O)NCCC(=O)NC(CS)C(=O)NCC(=O)O", "O=C1C=CC(=O)C=C1"],
            "product_smiles": ["CC(=O)NCCC(=O)NC(CSC1=CC(=O)C=CC1=O)C(=O)NCC(=O)O"],
            "referenceEa": 13.5,
            "doi": "10.1074/jbc.R112.434852",
            "journalRef": "J. Biol. Chem. 2013, 288, 3073",
            "tags": ["Pharm-D", "MBBS", "Toxicology", "Pharmacology", "Glutathione", "Phase II Metabolism", "Detoxification"]
        },
        {
            "id": "med-prostaglandin-01",
            "name": "Arachidonic Acid to PGG2/PGH2 (Cyclooxygenase Mechanism)",
            "iupacName": "arachidonic acid + 2 O2 → prostaglandin H2 (PGH2)",
            "category": "biochemical",
            "description": "The pivotal step in inflammatory pharmacology. Cyclooxygenase (COX-1 and COX-2) converts arachidonic acid released from membrane phospholipids by Phospholipase A2 into prostaglandin G2 (endoperoxide), which is reduced to PGH2. PGH2 is the biosynthetic precursor for Prostacyclin (PGI2), Thromboxane (TXA2), and Prostaglandins (PGE2, PGF2alpha). The direct target of NSAIDs, Coxibs (Celecoxib), and Aspirin for pain, fever, and inflammation.",
            "reactant_smiles": ["CCCCC/C=C\\C/C=C\\C/C=C\\C/C=C\\CCCC(=O)O", "O=O"],
            "product_smiles": ["CCCCC[C@H]1[C@@H]2C=C[C@H](O2)[C@H]1/C=C/[C@@H](O)CCCC(=O)O"],
            "referenceEa": 18.0,
            "doi": "10.1016/j.pharmthera.2011.09.006",
            "journalRef": "Pharmacol. Ther. 2012, 133, 71",
            "tags": ["MBBS", "Pharm-D", "Inflammation", "COX-2", "Prostaglandins", "Arachidonic Acid", "Pharmacology"]
        },
        {
            "id": "med-captopril-01",
            "name": "Captopril ACE Inhibition & Active-Site Zinc Chelation",
            "iupacName": "captopril + angiotensin-converting enzyme active site → [Zn2+]-captopril mercaptide complex",
            "category": "pharmaceutical",
            "description": "Foundational antihypertensive pharmacology for MBBS & Pharm-D students. Captopril was the first orally active ACE inhibitor designed by rational drug design. Its terminal thiol (-SH) group directly coordinates with the catalytic divalent zinc ion (Zn2+) in the active site of Angiotensin-Converting Enzyme, competitively blocking conversion of decapeptide Angiotensin I into the potent vasoconstrictor octapeptide Angiotensin II and preventing degradation of the vasodilator bradykinin.",
            "reactant_smiles": ["CC(CS)C(=O)N1CCCC1C(=O)O", "O"],
            "product_smiles": ["CC(C(=O)O)C(=O)N1CCCC1C(=O)O", "S"],
            "referenceEa": 14.2,
            "doi": "10.1021/jm00219a008",
            "journalRef": "J. Med. Chem. 1978, 21, 313",
            "tags": ["MBBS", "Pharm-D", "Cardiology", "ACE-Inhibitor", "Hypertension", "Renin-Angiotensin", "Captopril"]
        },
        {
            "id": "med-enalapril-01",
            "name": "Enalapril Hepatic Carboxylesterase-1 Bioactivation to Enalaprilat",
            "iupacName": "enalapril (ethyl ester prodrug) + H2O → enalaprilat (active di-acid) + ethanol",
            "category": "pharmaceutical",
            "description": "The classic paradigm of prodrug design in Pharm-D pharmaceutics and MBBS clinical pharmacology. Enalapril is an inactive dicarboxylic acid monoethyl ester prodrug synthesized to overcome the poor oral bioavailability and food-binding limitations of enalaprilat. In the liver, hepatic Carboxylesterase-1 (CES1) cleaves the ethyl ester bond via a tetrahedral serine-alkoxide intermediate, releasing the active dicarboxylate enalaprilat with high sub-nanomolar affinity for ACE.",
            "reactant_smiles": ["CCOC(=O)C(CCc1ccccc1)NC(C)C(=O)N2CCCC2C(=O)O", "O"],
            "product_smiles": ["O=C(O)C(CCc1ccccc1)NC(C)C(=O)N2CCCC2C(=O)O", "CCO"],
            "referenceEa": 15.6,
            "doi": "10.1038/288280a0",
            "journalRef": "Nature 1980, 288, 280",
            "tags": ["Pharm-D", "MBBS", "Prodrug", "Bioactivation", "CES1", "Enalapril", "Pharmacokinetics"]
        },
        {
            "id": "med-losartan-01",
            "name": "Losartan Angiotensin II Receptor Type 1 (AT1) Antagonism",
            "iupacName": "losartan + CYP2C9 oxidation → EXP3174 (active 5-carboxylic acid metabolite)",
            "category": "pharmaceutical",
            "description": "Cornerstone cardiovascular therapeutics for MBBS and Pharm-D students. Losartan is an orally active, non-peptide Angiotensin Receptor Blocker (ARB) containing an imidazole ring and biphenyl tetrazole. Oxidized by hepatic CYP2C9 and CYP3A4 to EXP3174 (10 to 40 times more potent, non-competitive AT1 blocker). Prevents AT1-mediated vasoconstriction and aldosterone release without inhibiting kininase II, eliminating the dry cough and angioedema risks of ACE inhibitors.",
            "reactant_smiles": ["Clc1nc(CO)c(CCCC)n1Cc2ccc(cc2)c3ccccc3c4nnn[nH]4", "O=O"],
            "product_smiles": ["Clc1nc(C(=O)O)c(CCCC)n1Cc2ccc(cc2)c3ccccc3c4nnn[nH]4", "O"],
            "referenceEa": 16.8,
            "doi": "10.1161/01.HYP.17.6.820",
            "journalRef": "Hypertension 1991, 17, 820",
            "tags": ["MBBS", "Pharm-D", "Cardiology", "ARB", "Losartan", "Hypertension", "CYP2C9"]
        },
        {
            "id": "med-propranolol-01",
            "name": "Propranolol Non-Selective Beta-Adrenergic Antagonism",
            "iupacName": "1-(isopropylamino)-3-(naphthalen-1-yloxy)propan-2-ol + beta-receptor → receptor blockade",
            "category": "pharmaceutical",
            "description": "Sir James Black's Nobel Prize-winning prototype beta-blocker for MBBS and Pharm-D students. Propranolol competitively antagonizes both beta-1 (cardiac SA/AV node, inotropy, chronotropy, renin release) and beta-2 (bronchial, vascular smooth muscle) adrenergic receptors. Crucial medical concepts: contraindicated in bronchial asthma due to fatal bronchospasm; lipid solubility enables central CNS penetration (treating essential tremor, migraine prophylaxis, and stage fright).",
            "reactant_smiles": ["CC(C)NCC(O)COc1cccc2ccccc12", "CC(=O)O"],
            "product_smiles": ["CC(C)NCC(OC(=O)C)COc1cccc2ccccc12", "O"],
            "referenceEa": 15.1,
            "doi": "10.1016/S0140-6736(64)90299-4",
            "journalRef": "Lancet 1964, 283, 1080",
            "tags": ["MBBS", "Pharm-D", "Cardiology", "Beta-Blocker", "Propranolol", "Autonomic Pharmacology", "Arrhythmia"]
        },
        {
            "id": "med-amlodipine-01",
            "name": "Amlodipine L-Type Calcium Channel Blockade",
            "iupacName": "amlodipine dihydropyridine core + vascular CaV1.2 channel → channel closed state stabilization",
            "category": "pharmaceutical",
            "description": "The premier dihydropyridine calcium channel blocker (CCB) in medical and pharmacy curricula. Binds allosterically to the alpha-1 pore-forming subunit of L-type voltage-gated calcium channels (CaV1.2) in peripheral arterial smooth muscle cells. Uniquely features a basic 2-aminoethoxymethyl sidechain conferring ionization at physiologic pH (pKa 8.6), slow association and dissociation kinetics, a long half-life (35-50 hours), and high vascular selectivity over cardiac tissue.",
            "reactant_smiles": ["CCOC(=O)C1=C(COCCN)NC(C)=C(C(=O)OC)C1c2ccccc2Cl", "O"],
            "product_smiles": ["CCOC(=O)C1=C(CO)NC(C)=C(C(=O)OC)C1c2ccccc2Cl", "OCCN"],
            "referenceEa": 14.8,
            "doi": "10.1097/00005344-198800127-00003",
            "journalRef": "J. Cardiovasc. Pharmacol. 1988, 12, S10",
            "tags": ["MBBS", "Pharm-D", "Cardiology", "CCB", "Amlodipine", "Hypertension", "Calcium Channel"]
        },
        {
            "id": "med-atorvastatin-01",
            "name": "Atorvastatin HMG-CoA Reductase Pharmacophore Mimicry",
            "iupacName": "atorvastatin + HMG-CoA reductase → competitive active-site inhibition (Kd ~ 8 nM)",
            "category": "pharmaceutical",
            "description": "The hallmark lipid-lowering therapeutic for MBBS cardiology and Pharm-D medicinal chemistry. The 3,5-dihydroxyheptanoic acid sidechain precisely mimics the tetrahedral mevaldyl-CoA intermediate formed during conversion of HMG-CoA to mevalonate by HMG-CoA Reductase. Hepatic sterol depletion upregulates sterol regulatory element-binding protein 2 (SREBP-2), leading to robust LDL receptor expression, rapid clearance of atherogenic ApoB lipoproteins, and atherosclerotic plaque stabilization.",
            "reactant_smiles": ["CC(C)c1c(C(=O)Nc2ccccc2)c(c3ccc(F)cc3)c(c4ccccc4)n1CCC(O)CC(O)CC(=O)O", "O=O"],
            "product_smiles": ["CC(C)c1c(C(=O)Nc2ccccc2)c(c3ccc(F)cc3)c(c4ccccc4)n1CCC(=O)CC(O)CC(=O)O", "O"],
            "referenceEa": 17.5,
            "doi": "10.1021/jm950796v",
            "journalRef": "J. Med. Chem. 1996, 39, 284",
            "tags": ["MBBS", "Pharm-D", "Cardiology", "Statin", "Atorvastatin", "Cholesterol", "Atherosclerosis"]
        },
        {
            "id": "med-nitroglycerin-01",
            "name": "Nitroglycerin ALDH-2 Denitration & Nitric Oxide (NO) Vasodilation",
            "iupacName": "glyceryl trinitrate + ALDH-2/thiol → 1,2-glyceryl dinitrate + nitric oxide (NO)",
            "category": "pharmaceutical",
            "description": "Acute emergency treatment of angina pectoris and cardiogenic pulmonary edema for MBBS & Pharm-D students. Nitroglycerin (GTN) undergoes bioactivation in venous vascular smooth muscle mitochondria catalyzed by mitochondrial aldehyde dehydrogenase (ALDH-2) via essential cysteine thiols. The generated nitric oxide (NO) stimulates soluble guanylyl cyclase (sGC) to produce cyclic GMP (cGMP), activating protein kinase G (PKG), dephosphorylating myosin light chain, and precipitating venous pooling and marked preload reduction.",
            "reactant_smiles": ["O=N(=O)OCC(CO[N+](=O)[O-])O[N+](=O)[O-]", "O"],
            "product_smiles": ["OCC(CO[N+](=O)[O-])O[N+](=O)[O-]", "N(=O)O"],
            "referenceEa": 13.9,
            "doi": "10.1073/pnas.122225999",
            "journalRef": "Proc. Natl. Acad. Sci. U.S.A. 2002, 99, 8306",
            "tags": ["MBBS", "Pharm-D", "Cardiology", "Nitroglycerin", "Nitric Oxide", "Angina", "Vasodilation"]
        },
        {
            "id": "med-furosemide-01",
            "name": "Furosemide Loop Diuretic NKCC2 Symporter Inhibition",
            "iupacName": "4-chloro-2-[(furan-2-ylmethyl)amino]-5-sulfamoylbenzoic acid + NKCC2 → trans-epithelial transport block",
            "category": "pharmaceutical",
            "description": "Essential renal physiology and pharmacotherapy for MBBS and Pharm-D students. Furosemide binds reversibly to the chloride-binding pocket of the Na+/K+/2Cl- cotransporter (NKCC2) in the apical membrane of the thick ascending limb of Henle's loop. Abolishes the positive lumen potential, preventing passive paracellular reabsorption of Ca2+ and Mg2+; dissipates the hypertonic medullary gradient, inducing massive natriuresis and diuresis in acute pulmonary edema, congestive heart failure, and refractory ascites.",
            "reactant_smiles": ["NS(=O)(=O)c1cc(C(=O)O)c(NCc2ccco2)cc1Cl", "O"],
            "product_smiles": ["NS(=O)(=O)c1cc(C(=O)O)c(N)cc1Cl", "O=Cc1ccco1"],
            "referenceEa": 16.1,
            "doi": "10.1007/BF00586940",
            "journalRef": "Pflügers Arch. 1983, 396, 325",
            "tags": ["MBBS", "Pharm-D", "Nephrology", "Diuretic", "Furosemide", "NKCC2", "Electrolytes"]
        },
        {
            "id": "med-omeprazole-01",
            "name": "Omeprazole Acid Canalicular Activation to Tetracyclic Sulfenamide",
            "iupacName": "omeprazole (prodrug) + 2 H+ → sulfenic acid → tetracyclic sulfenamide (active inhibitor)",
            "category": "pharmaceutical",
            "description": "Premier gastrointestinal pharmacology milestone for MBBS & Pharm-D students. Omeprazole is a lipophilic weak base (pKa ~4) that accumulates selectively in the acidic secretocanaliculi (pH <1.3) of gastric parietal cells. Protonation triggers an intramolecular rearrangement forming a permanent tetracyclic sulfenamide that reacts covalently with Cysteine-813 of the H+/K+-ATPase proton pump, permanently extinguishing gastric acid secretion until de novo pump synthesis (24-48 hours).",
            "reactant_smiles": ["CC1=CN=C(C(=C1OC)C)CS(=O)C2=NC3=C(N2)C=C(C=C3)OC", "CS"],
            "product_smiles": ["CC1=CN=C(C(=C1OC)C)CSC2=NC3=C(N2)C=C(C=C3)OC", "CSO"],
            "referenceEa": 15.0,
            "doi": "10.1038/318070a0",
            "journalRef": "Nature 1985, 318, 70",
            "tags": ["MBBS", "Pharm-D", "Gastroenterology", "PPI", "Omeprazole", "Acid Suppression", "Peptic Ulcer"]
        },
        {
            "id": "med-metformin-01",
            "name": "Metformin Mitochondrial Complex I & AMPK Activation",
            "iupacName": "1,1-dimethylbiguanide + mitochondrial respiratory complex I → mild uncoupling & AMPK activation",
            "category": "pharmaceutical",
            "description": "First-line oral antidiabetic therapy globally in MBBS & Pharm-D endocrinology. Metformin accumulates in mitochondrial matrices due to its positive charge, mildly and reversibly inhibiting Complex I of the respiratory chain. Decreased ATP production and elevated cellular AMP/ATP ratio directly allosterically activate AMP-activated protein kinase (AMPK) and inhibit adenylate cyclase, suppressing hepatic gluconeogenesis (PEPCK and G6Pase downregulation) without causing clinical hypoglycemia or weight gain.",
            "reactant_smiles": ["CN(C)C(=N)NC(=N)N", "O"],
            "product_smiles": ["CN(C)C(=O)NC(=N)N", "N"],
            "referenceEa": 14.7,
            "doi": "10.1038/nm1434",
            "journalRef": "Nat. Med. 2006, 12, 841",
            "tags": ["MBBS", "Pharm-D", "Endocrinology", "Diabetes", "Metformin", "AMPK", "Gluconeogenesis"]
        },
        {
            "id": "med-glimepiride-01",
            "name": "Glimepiride Pancreatic Beta-Cell K-ATP Channel Closure",
            "iupacName": "glimepiride + SUR1 receptor subunit → inward rectifier Kir6.2 channel closure → insulin exocytosis",
            "category": "pharmaceutical",
            "description": "Second-generation sulfonylurea pharmacology for MBBS & Pharm-D students. Glimepiride binds to the high-affinity 65-kDa SUR1 subunit of ATP-sensitive potassium channels (K-ATP) on pancreatic beta-cell membranes. Channel closure blocks K+ efflux, causing cell membrane depolarization, opening voltage-gated L-type calcium channels, inducing intracellular Ca2+ surge, and precipitating biphasic insulin granule exocytosis independent of ambient glucose concentrations.",
            "reactant_smiles": ["CCN1C(=O)C(=C(C)C1=O)CCc2ccc(cc2)S(=O)(=O)NC(=O)NC3CCCCC3", "O"],
            "product_smiles": ["CCN1C(=O)C(=C(C)C1=O)CCc2ccc(cc2)S(=O)(=O)N", "NC(=O)NC3CCCCC3"],
            "referenceEa": 16.5,
            "doi": "10.1055/s-2007-979921",
            "journalRef": "Exp. Clin. Endocrinol. Diabetes 1999, 107, 125",
            "tags": ["MBBS", "Pharm-D", "Endocrinology", "Sulfonylurea", "Glimepiride", "Insulin", "Diabetes"]
        },
        {
            "id": "med-methotrexate-01",
            "name": "Methotrexate Dihydrofolate Reductase (DHFR) Inactivation",
            "iupacName": "methotrexate + DHFR → competitive pseudo-irreversible active site blockade (Ki ~ 1 pM)",
            "category": "pharmaceutical",
            "description": "Cornerstone antimetabolite chemotherapy and DMARD immunosuppression in MBBS & Pharm-D curricula. Structural analog of folic acid featuring a 4-amino substitution that binds Dihydrofolate Reductase with 1000-fold higher affinity than natural dihydrofolate. Traps intracellular folates in their inactive oxidized dihydro state, starving cells of N5,N10-methylene-THF and N10-formyl-THF required for thymidylate (dTMP) and purine synthesis, arresting S-phase cell cycle progression. Reversed clinically by folinic acid (Leucovorin rescue).",
            "reactant_smiles": ["CN(Cc1cnc2nc(N)nc(N)c2n1)c3ccc(C(=O)NC(CCC(=O)O)C(=O)O)cc3", "O"],
            "product_smiles": ["CN(Cc1cnc2nc(N)nc(O)c2n1)c3ccc(C(=O)NC(CCC(=O)O)C(=O)O)cc3", "N"],
            "referenceEa": 17.8,
            "doi": "10.1126/science.197.4302.452",
            "journalRef": "Science 1977, 197, 452",
            "tags": ["MBBS", "Pharm-D", "Oncology", "Antimetabolite", "Methotrexate", "DHFR", "Immunosuppressive"]
        },
        {
            "id": "med-5fu-01",
            "name": "5-Fluorouracil (5-FU) Suicide Inhibition of Thymidylate Synthase",
            "iupacName": "5-FdUMP + 5,10-CH2-THF + Thymidylate Synthase (Cys195) → covalent ternary complex",
            "category": "pharmaceutical",
            "description": "Classic pyrimidine suicide inhibitor in oncology for MBBS and Pharm-D students. 5-Fluorouracil is metabolized intracellularly to 5-fluoro-2'-deoxyuridine-5'-monophosphate (5-FdUMP). 5-FdUMP binds to the catalytic site of Thymidylate Synthase along with 5,10-methylenetetrahydrofolate. Nucleophilic attack by active-site Cysteine-195 forms a covalent ternary adduct; however, the highly electronegative fluorine atom cannot be abstracted as a proton, permanently paralyzing the enzyme and causing 'thymineless cell death'.",
            "reactant_smiles": ["O=C1NC=C(F)C(=O)N1", "CS"],
            "product_smiles": ["O=C1NC(SC)C(F)C(=O)N1"],
            "referenceEa": 14.4,
            "doi": "10.1016/0006-2952(81)90013-1",
            "journalRef": "Biochem. Pharmacol. 1981, 30, 2221",
            "tags": ["MBBS", "Pharm-D", "Oncology", "5-FU", "Thymidylate Synthase", "Suicide Inhibitor", "Chemotherapy"]
        },
        {
            "id": "med-cisplatin-01",
            "name": "Cisplatin Intracellular Aquation & DNA Crosslinking",
            "iupacName": "cis-[Pt(NH3)2Cl2] + H2O → cis-[Pt(NH3)2Cl(OH2)]+ + Cl-",
            "category": "pharmaceutical",
            "description": "Inorganic medicinal chemistry milestone in oncology for MBBS and Pharm-D students. Neutral cisplatin crosses cell membranes; in low intracellular chloride (~4-20 mM vs ~100 mM extracellular), it undergoes spontaneous aquation to reactive positively charged mono-aqua and diaqua species. These electrophilic species coordinate preferentially to N7 positions of adjacent guanine bases (1,2-intrastrand d(GpG) adducts ~65%), creating a sharp 45-degree bend in the DNA double helix that arrests RNA polymerase II and induces p53-dependent apoptosis.",
            "reactant_smiles": ["Cl[Pt](Cl)(N)N", "O"],
            "product_smiles": ["Cl[Pt](O)(N)N", "Cl"],
            "referenceEa": 18.7,
            "doi": "10.1038/sj.onc.1206933",
            "journalRef": "Oncogene 2003, 22, 7265",
            "tags": ["MBBS", "Pharm-D", "Oncology", "Cisplatin", "DNA Crosslinking", "Platinum", "Apoptosis"]
        },
        {
            "id": "med-morphine-gluc-01",
            "name": "Morphine Phase II Glucuronidation (UGT2B7 Clearance)",
            "iupacName": "morphine + UDP-glucuronic acid → morphine-3-glucuronide (M3G) / morphine-6-glucuronide (M6G)",
            "category": "pharmaceutical",
            "description": "Crucial pharmacokinetic and analgesic pathway for Pharm-D and MBBS students. Hepatic UDP-glucuronosyltransferase 2B7 (UGT2B7) conjugates glucuronic acid to the phenolic 3-OH group (yielding M3G ~60%, inactive analgesically but neurotoxic) and the 6-OH group (yielding M6G ~10%, an active metabolite with greater mu-opioid receptor potency than parent morphine). In renal failure, M6G accumulates dangerously, precipitating fatal respiratory depression.",
            "reactant_smiles": ["CN1CC[C@]23c4c5ccc(O)c4O[C@H]2[C@@H](O)C=C[C@H]3[C@H]1C5", "O=C(O)C1OC(O)C(O)C(O)C1O"],
            "product_smiles": ["CN1CC[C@]23c4c5ccc(OC6OC(C(=O)O)C(O)C(O)C6O)c4O[C@H]2[C@@H](O)C=C[C@H]3[C@H]1C5", "O"],
            "referenceEa": 15.8,
            "doi": "10.1124/mol.55.6.1089",
            "journalRef": "Mol. Pharmacol. 1999, 55, 1089",
            "tags": ["Pharm-D", "MBBS", "Pharmacokinetics", "Morphine", "Glucuronidation", "UGT2B7", "Opioids"]
        },
        {
            "id": "med-nat2-isoniazid-01",
            "name": "Isoniazid N-Acetylation by Hepatic NAT2 (Pharmacogenetics)",
            "iupacName": "isoniazid + acetyl-CoA → N-acetylisoniazid + coenzyme A",
            "category": "pharmaceutical",
            "description": "The premier textbook model of clinical pharmacogenetics for MBBS and Pharm-D students. Cytosolic hepatic N-acetyltransferase 2 (NAT2) transfers an acetyl group from acetyl-CoA to the hydrazine nitrogen of isoniazid. Genetic polymorphisms divide populations into 'Fast Acetylators' (half-life ~1 hour, higher risk of hepatotoxicity from acetylhydrazine metabolites) and 'Slow Acetylators' (half-life ~3 hours, higher plasma drug concentrations resulting in pyridoxine deficiency and peripheral neuropathy).",
            "reactant_smiles": ["NNC(=O)c1ccncc1", "CC(=O)S"],
            "product_smiles": ["CC(=O)NNC(=O)c1ccncc1", "S"],
            "referenceEa": 13.7,
            "doi": "10.1124/pr.54.4.579",
            "journalRef": "Pharmacol. Rev. 2002, 54, 579",
            "tags": ["MBBS", "Pharm-D", "Pharmacogenetics", "Isoniazid", "NAT2", "Tuberculosis", "Acetylation"]
        },
        {
            "id": "med-ciprofloxacin-01",
            "name": "Ciprofloxacin DNA Gyrase & Topoisomerase IV Cleavage",
            "iupacName": "ciprofloxacin + bacterial DNA gyrase A2B2 + double-stranded DNA → cleaved complex stabilization",
            "category": "pharmaceutical",
            "description": "Premier broad-spectrum fluoroquinolone antimicrobial in MBBS & Pharm-D curricula. Ciprofloxacin intercalates into bacterial DNA at the cleavage site created by DNA Gyrase (Gram-negative bacteria) and Topoisomerase IV (Gram-positive bacteria). The 3-carboxylate and 4-keto oxygens coordinate a Mg2+ ion bridged by water to conserved Ser83 and Asp87 residues, freezing the cleaved enzyme-DNA complex, inducing permanent double-strand breaks, and triggering SOS bacterial death.",
            "reactant_smiles": ["O=C(O)c1cn(C2CC2)c3cc(N4CCNCC4)c(F)cc3c1=O", "O"],
            "product_smiles": ["O=C(O)c1cn(C2CC2)c3cc(N)c(F)cc3c1=O", "OCCNCCN"],
            "referenceEa": 16.9,
            "doi": "10.1038/nature09197",
            "journalRef": "Nature 2010, 466, 935",
            "tags": ["Pharm-D", "MBBS", "Antibiotic", "Fluoroquinolone", "Ciprofloxacin", "DNA Gyrase", "Microbiology"]
        },
        {
            "id": "med-azithromycin-01",
            "name": "Azithromycin 50S Ribosomal Translocation Blockade",
            "iupacName": "azithromycin (15-membered azalide) + bacterial 23S rRNA → peptide nascent chain elongation arrest",
            "category": "pharmaceutical",
            "description": "Aza-macrolide pharmacology for MBBS & Pharm-D students. Azithromycin incorporates a methyl-substituted nitrogen at position 9a of the macrolactone ring, preventing hemiketal formation and conferring acid stability. Binds reversibly to the peptidyl transferase center of 23S rRNA in the bacterial 50S ribosomal subunit, occluding the nascent polypeptide exit tunnel. Exceptionally high intracellular accumulation in lysosomes and tissue phagocytes (tissue half-life ~68 hours).",
            "reactant_smiles": ["CC1CC(C)C(O)C(C)C(O)C(C)(O)CC(C)N(C)CC(C)C(O)C1=O", "O"],
            "product_smiles": ["CC1CC(C)C(O)C(C)C(O)C(C)(O)CC(C)N(C)CC(C)C(O)C1=O", "O"],
            "referenceEa": 18.2,
            "doi": "10.1016/S0969-2126(02)00778-1",
            "journalRef": "Structure 2002, 10, 807",
            "tags": ["Pharm-D", "MBBS", "Antibiotic", "Macrolide", "Azithromycin", "Ribosome", "Pharmacokinetics"]
        },
        {
            "id": "med-ceftriaxone-01",
            "name": "Ceftriaxone Transpeptidase Acylation (3rd Gen Cephalosporin)",
            "iupacName": "ceftriaxone beta-lactam core + bacterial PBP-2/PBP-3 → irreversible acyl-enzyme adduct",
            "category": "pharmaceutical",
            "description": "Third-generation cephalosporin cornerstone for hospital pharmacy (Pharm-D) and emergency medicine (MBBS). The aminothiazolyl oxime sidechain confers exceptional resistance against Gram-negative beta-lactamases and high affinity for penicillin-binding proteins (PBPs), while the triazine ring confers a long serum half-life (~8 hours) and biliary elimination. Rapidly crosses the blood-brain barrier for bacterial meningitis and empirically treats Neisseria gonorrhoeae and severe sepsis.",
            "reactant_smiles": ["O=C1N2C(=C(CSC(=O)C)CS[C@@H]21)C(=O)O", "O"],
            "product_smiles": ["O=C(O)C1=C(CSC(=O)C)CS[C@@H]2N1C(=O)[C@@H]2NC(=O)O"],
            "referenceEa": 17.6,
            "doi": "10.1093/jac/45.suppl_3.1",
            "journalRef": "J. Antimicrob. Chemother. 2000, 45, 1",
            "tags": ["Pharm-D", "MBBS", "Antibiotic", "Cephalosporin", "Ceftriaxone", "Meningitis", "Microbiology"]
        },
        {
            "id": "med-levodopa-01",
            "name": "Levodopa (L-DOPA) Decarboxylation to Dopamine by AADC",
            "iupacName": "(2S)-2-amino-3-(3,4-dihydroxyphenyl)propanoic acid → 4-(2-aminoethyl)benzene-1,2-diol + CO2",
            "category": "biochemical",
            "description": "Essential central neurotransmission and movement disorder therapy for MBBS and Pharm-D students. Dopamine itself cannot cross the blood-brain barrier (BBB); its amino acid precursor L-DOPA crosses via the L-type neutral amino acid transporter (LAT1). In the striatum, aromatic L-amino acid decarboxylase (AADC) with pyridoxal phosphate (PLP) cofactor removes the alpha-carboxyl group, replenishing depleted dopamine stores in Parkinson disease. Co-prescribed with peripheral decarboxylase inhibitors (Carbidopa, Benserazide) to prevent systemic cardiovascular side effects.",
            "reactant_smiles": ["O=C(O)C(N)Cc1ccc(O)c(O)c1"],
            "product_smiles": ["NCCc1ccc(O)c(O)c1", "O=C=O"],
            "referenceEa": 15.9,
            "doi": "10.1016/S0140-6736(67)91544-8",
            "journalRef": "Lancet 1967, 290, 712",
            "tags": ["MBBS", "Pharm-D", "Neurology", "Parkinson", "Levodopa", "Dopamine", "Neurochemistry"]
        }
    ]
    return reactions

def main():
    print("Generating 3D coordinates for medical reactions...")
    raw_reactions = get_medical_reactions()
    processed_reactions = []

    for r in raw_reactions:
        print(f"Processing: {r['name']} ({r['id']})")
        # Generate Reactant XYZ
        r_mols = [make_3d_mol(s) for s in r['reactant_smiles']]
        reactant_xyz = combine_mols_to_xyz(r_mols, comment=f"{r['name']} - Reactants")

        # Generate Product XYZ
        p_mols = [make_3d_mol(s) for s in r['product_smiles']]
        product_xyz = combine_mols_to_xyz(p_mols, comment=f"{r['name']} - Products")

        template_dict = {
            "id": r["id"],
            "name": r["name"],
            "iupacName": r["iupacName"],
            "description": r["description"],
            "category": r["category"],
            "reactantXyz": reactant_xyz,
            "productXyz": product_xyz,
            "referenceEa": r["referenceEa"],
            "doi": r["doi"],
            "journalRef": r["journalRef"],
            "tags": r["tags"],
            "isDerived": False
        }
        processed_reactions.append(template_dict)

    # 1. Save to assets/medical_reactions.json
    asset_path = "quantum_forge/assets/medical_reactions.json"
    with open(asset_path, "w", encoding="utf-8") as f:
        json.dump(processed_reactions, f, indent=2)
    print(f"Saved {len(processed_reactions)} reactions to {asset_path}")

    # 2. Update assets/massive_reactions.json by prepending medical reactions
    massive_path = "quantum_forge/assets/massive_reactions.json"
    try:
        with open(massive_path, "r", encoding="utf-8") as f:
            existing = json.load(f)
    except Exception:
        existing = []
    
    # Prepend medical reactions so they appear first!
    med_ids = {r["id"] for r in processed_reactions}
    cleaned_existing = [e for e in existing if e.get("id") not in med_ids]
    combined = processed_reactions + cleaned_existing
    with open(massive_path, "w", encoding="utf-8") as f:
        json.dump(combined, f, indent=2)
    print(f"Updated {massive_path} with {len(processed_reactions)} medical reactions at the front.")

    # 3. Seed directly to Firebase Firestore /library via REST API
    print("Seeding to Firebase Firestore /library...")
    token = None
    try:
        import sys
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import seed_massive_firebase
        token = seed_massive_firebase.get_auth_token()
    except Exception as e:
        print(f"Token resolution exception: {e}")

    if not token:
        print("Warning: No valid Firebase access token found. Skipping REST upload.")
        return

    success_count = 0
    for r in processed_reactions:
        doc_id = r["id"]
        url = f"https://firestore.googleapis.com/v1/projects/quantom-forge/databases/(default)/documents/library/{doc_id}"
        
        # Build Firestore REST fields
        fields = {
            "name": {"stringValue": r["name"]},
            "iupacName": {"stringValue": r["iupacName"]},
            "description": {"stringValue": r["description"]},
            "category": {"stringValue": r["category"]},
            "reactantXyz": {"stringValue": r["reactantXyz"]},
            "productXyz": {"stringValue": r["productXyz"]},
            "referenceEa": {"doubleValue": float(r["referenceEa"])},
            "doi": {"stringValue": r["doi"]},
            "journalRef": {"stringValue": r["journalRef"]},
            "tags": {"arrayValue": {"values": [{"stringValue": t} for t in r["tags"]]}},
            "isDerived": {"booleanValue": False}
        }
        
        payload = {"fields": fields}
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            method="PATCH"
        )
        try:
            with urllib.request.urlopen(req) as resp:
                if resp.status in (200, 201):
                    success_count += 1
                    print(f"  [✓] Seeded {doc_id} to Firestore")
                else:
                    print(f"  [!] HTTP {resp.status} for {doc_id}")
        except Exception as e:
            print(f"  [x] Failed {doc_id}: {e}")

    print(f"\nFirestore Seeding Complete: {success_count}/{len(processed_reactions)} medical reactions live in Firebase!")

if __name__ == "__main__":
    main()
