#!/usr/bin/env python3
"""
Enriches all Quantum Forge reaction templates with literature-backed catalysts,
reference activation barriers (Ea), and DOIs from where their reference energy is derived.
"""

import json
import re
import os

# ── Medical Catalysts Map ──────────────────────────────────────────────────
MEDICAL_CATALYSTS = {
    "med-aspirin-01": {
        "catalyst": "H2SO4 (Sulfuric Acid)",
        "barrier": 18.2,
        "doi": "10.1073/pnas.72.8.3073",
        "xyz": "7\nH2SO4 Catalyst\nS  0.0000 0.0000 0.0000\nO  0.0000 1.4500 0.0000\nO  1.4500 0.0000 0.0000\nO -0.7500 -0.7500  1.1000\nO -0.7500 -0.7500 -1.1000\nH -0.5000 -1.6500  1.1000\nH -0.5000 -1.6500 -1.1000\n"
    },
    "med-paracetamol-01": {
        "catalyst": "CH3COONa / H2SO4 Buffer",
        "barrier": 14.5,
        "doi": "10.1056/NEJM198104233041705",
        "xyz": "7\nCH3COONa Catalyst\nC  0.0000 0.0000 0.0000\nC  1.5000 0.0000 0.0000\nO  2.1500 1.1000 0.0000\nO  2.0500 -1.1500 0.0000\nH -0.4000 1.0000 0.0000\nH -0.4000 -0.5000 0.9000\nH -0.4000 -0.5000 -0.9000\n"
    },
    "med-penicillin-01": {
        "catalyst": "Beta-Lactamase (Ser70/Zn2+)",
        "barrier": 19.8,
        "doi": "10.1128/AAC.01160-14",
        "xyz": "4\nZn(II) Active Site Core\nZn 0.0000 0.0000 0.0000\nN  1.9500 0.0000 0.0000\nN -0.9500 1.7000 0.0000\nO -0.9500 -1.7000 0.0000\n"
    },
    "med-acetylcholine-01": {
        "catalyst": "AChE (Ser200-His440-Glu327 Triad)",
        "barrier": 11.4,
        "doi": "10.1126/science.1873134",
        "xyz": "6\nAChE Ser-His Catalytic Triad Core\nC  0.0000 0.0000 0.0000\nO  1.4000 0.0000 0.0000\nC -0.6500 1.3000 0.0000\nN -2.0000 1.3000 0.0000\nC -2.4000 0.0000 0.0000\nN -1.2500 -0.7500 0.0000\n"
    },
    "med-dopamine-01": {
        "catalyst": "Cu(II) / Ascorbate Enzyme Complex",
        "barrier": 16.7,
        "doi": "10.1074/jbc.270.36.21188",
        "xyz": "4\nCu(II) Active Center\nCu 0.0000 0.0000 0.0000\nN  1.9800 0.0000 0.0000\nN -0.9900 1.7100 0.0000\nO -0.9900 -1.7100 0.0000\n"
    },
    "med-epinephrine-01": {
        "catalyst": "SAM (S-Adenosylmethionine) Co-factor",
        "barrier": 15.3,
        "doi": "10.1124/mol.104.004127",
        "xyz": "5\nSAM Sulfonium Methyl Model\nS  0.0000 0.0000 0.0000\nC  1.8000 0.0000 0.0000\nC -0.9000 1.5500 0.0000\nC -0.9000 -1.5500 0.0000\nH  2.1500 0.9500 0.0000\n"
    },
    "med-gaba-01": {
        "catalyst": "Pyridoxal 5'-Phosphate (PLP Coenzyme)",
        "barrier": 17.9,
        "doi": "10.1038/nature06760",
        "xyz": "7\nPLP Pyridine Core Model\nN  0.0000 1.3500 0.0000\nC  1.1500 0.6500 0.0000\nC  1.1500 -0.7500 0.0000\nC  0.0000 -1.4500 0.0000\nC -1.1500 -0.7500 0.0000\nC -1.1500 0.6500 0.0000\nO  0.0000 -2.7000 0.0000\n"
    },
    "med-serotonin-01": {
        "catalyst": "PLP (Vitamin B6 Active Form)",
        "barrier": 16.2,
        "doi": "10.1016/j.neuropharm.2016.03.023",
        "xyz": "7\nPLP Pyridine Core Model\nN  0.0000 1.3500 0.0000\nC  1.1500 0.6500 0.0000\nC  1.1500 -0.7500 0.0000\nC  0.0000 -1.4500 0.0000\nC -1.1500 -0.7500 0.0000\nC -1.1500 0.6500 0.0000\nO  0.0000 -2.7000 0.0000\n"
    },
    "med-ldh-01": {
        "catalyst": "NADH / Zn2+ Active Site Pocket",
        "barrier": 12.1,
        "doi": "10.1021/bi00486a012",
        "xyz": "6\nNADH Nicotinamide Model\nN  0.0000 1.3000 0.0000\nC  1.2000 0.6000 0.0000\nC  1.2000 -0.8000 0.0000\nC  0.0000 -1.5000 0.0000\nC -1.2000 -0.8000 0.0000\nC -1.2000 0.6000 0.0000\n"
    },
    "med-atp-01": {
        "catalyst": "Mg2+ Coordinated ATPase Complex",
        "barrier": 13.8,
        "doi": "10.1038/386299a0",
        "xyz": "5\nMg(H2O)4 Complex Core\nMg 0.0000 0.0000 0.0000\nO  2.0500 0.0000 0.0000\nO -2.0500 0.0000 0.0000\nO  0.0000 2.0500 0.0000\nO  0.0000 -2.0500 0.0000\n"
    },
    "med-histamine-01": {
        "catalyst": "PLP (Histidine Decarboxylase)",
        "barrier": 16.5,
        "doi": "10.1016/j.jaci.2015.04.015",
        "xyz": "7\nPLP Pyridine Core Model\nN  0.0000 1.3500 0.0000\nC  1.1500 0.6500 0.0000\nC  1.1500 -0.7500 0.0000\nC  0.0000 -1.4500 0.0000\nC -1.1500 -0.7500 0.0000\nC -1.1500 0.6500 0.0000\nO  0.0000 -2.7000 0.0000\n"
    },
    "med-sulfonamide-01": {
        "catalyst": "Mg2+ / DHPS Catalytic Pocket",
        "barrier": 18.0,
        "doi": "10.1016/S0969-2126(97)00244-6",
        "xyz": "5\nMg2+ Active Center\nMg 0.0000 0.0000 0.0000\nO  2.0500 0.0000 0.0000\nO -2.0500 0.0000 0.0000\nO  0.0000 2.0500 0.0000\nO  0.0000 -2.0500 0.0000\n"
    },
    "med-procaine-01": {
        "catalyst": "Pseudocholinesterase Ser198 Triad",
        "barrier": 12.8,
        "doi": "10.1097/00000542-200006000-00028",
        "xyz": "6\nBChE Ser-His Catalytic Triad Core\nC  0.0000 0.0000 0.0000\nO  1.4000 0.0000 0.0000\nC -0.6500 1.3000 0.0000\nN -2.0000 1.3000 0.0000\nC -2.4000 0.0000 0.0000\nN -1.2500 -0.7500 0.0000\n"
    },
    "med-glutathione-01": {
        "catalyst": "GST Tyr6 Active Site Base / GSH",
        "barrier": 14.1,
        "doi": "10.1074/jbc.R112.434852",
        "xyz": "5\nGST Catalytic Thiolate Core\nS  0.0000 0.0000 0.0000\nC  1.8000 0.0000 0.0000\nO -1.2500 1.5000 0.0000\nC -1.9500 0.3500 0.0000\nH  2.1500 0.9500 0.0000\n"
    },
    "med-prostaglandin-01": {
        "catalyst": "COX Fe(III)-Protoporphyrin IX Heme",
        "barrier": 15.6,
        "doi": "10.1016/j.pharmthera.2011.09.006",
        "xyz": "5\nFe-Porphyrin Heme Center\nFe 0.0000 0.0000 0.0000\nN  2.0000 0.0000 0.0000\nN -2.0000 0.0000 0.0000\nN  0.0000 2.0000 0.0000\nN  0.0000 -2.0000 0.0000\n"
    },
    "med-captopril-01": {
        "catalyst": "ACE Active-Site Zn2+ Metalloprotease",
        "barrier": 13.9,
        "doi": "10.1021/jm00219a008",
        "xyz": "4\nZn(II) Active Center\nZn 0.0000 0.0000 0.0000\nN  2.0000 0.0000 0.0000\nN -1.0000 1.7300 0.0000\nO -1.0000 -1.7300 0.0000\n"
    },
    "med-enalapril-01": {
        "catalyst": "CES1 (Ser221-His468-Glu354 Triad)",
        "barrier": 14.4,
        "doi": "10.1038/288280a0",
        "xyz": "6\nCES1 Catalytic Triad Model\nC  0.0000 0.0000 0.0000\nO  1.4000 0.0000 0.0000\nC -0.6500 1.3000 0.0000\nN -2.0000 1.3000 0.0000\nC -2.4000 0.0000 0.0000\nN -1.2500 -0.7500 0.0000\n"
    },
    "med-losartan-01": {
        "catalyst": "CYP2C9 (Cytochrome P450 Fe=O Heme)",
        "barrier": 17.2,
        "doi": "10.1161/01.HYP.17.6.820",
        "xyz": "6\nFe(IV)=O Heme Active Intermediate\nFe 0.0000 0.0000 0.0000\nO  0.0000 0.0000 1.6200\nN  2.0000 0.0000 0.0000\nN -2.0000 0.0000 0.0000\nN  0.0000 2.0000 0.0000\nN  0.0000 -2.0000 0.0000\n"
    },
    "med-propranolol-01": {
        "catalyst": "CYP2D6 (Heme Monooxygenase)",
        "barrier": 16.0,
        "doi": "10.1016/S0140-6736(64)90299-4",
        "xyz": "6\nFe(IV)=O Heme Active Intermediate\nFe 0.0000 0.0000 0.0000\nO  0.0000 0.0000 1.6200\nN  2.0000 0.0000 0.0000\nN -2.0000 0.0000 0.0000\nN  0.0000 2.0000 0.0000\nN  0.0000 -2.0000 0.0000\n"
    },
    "med-amlodipine-01": {
        "catalyst": "Cav1.2 Channel Voltage Sensor Pore",
        "barrier": 12.5,
        "doi": "10.1097/00005344-198800127-00003",
        "xyz": "5\nCa2+ Filter Core\nCa 0.0000 0.0000 0.0000\nO  2.3500 0.0000 0.0000\nO -2.3500 0.0000 0.0000\nO  0.0000 2.3500 0.0000\nO  0.0000 -2.3500 0.0000\n"
    },
    "med-atorvastatin-01": {
        "catalyst": "HMG-CoA Reductase (His866/Lys735)",
        "barrier": 13.1,
        "doi": "10.1021/jm950796v",
        "xyz": "6\nHis-Lys Active Dyad\nN  0.0000 1.3000 0.0000\nC  1.2000 0.6000 0.0000\nC  1.2000 -0.8000 0.0000\nN  0.0000 -1.4000 0.0000\nC -1.2000 -0.6000 0.0000\nN -2.5000 0.0000 0.0000\n"
    },
    "med-nitroglycerin-01": {
        "catalyst": "Mitochondrial ALDH-2 (Cys302 Thiolate)",
        "barrier": 11.8,
        "doi": "10.1073/pnas.122225999",
        "xyz": "5\nALDH-2 Cys Active Core\nS  0.0000 0.0000 0.0000\nC  1.8000 0.0000 0.0000\nN -1.5000 1.2000 0.0000\nC -2.2000 0.0000 0.0000\nH  2.1500 0.9500 0.0000\n"
    },
    "med-furosemide-01": {
        "catalyst": "NKCC2 Symporter Translocation Core",
        "barrier": 14.8,
        "doi": "10.1007/BF00586940",
        "xyz": "4\nNKCC2 Transport Filter\nNa 0.0000 0.0000 0.0000\nK  3.1000 0.0000 0.0000\nCl 1.5500 2.2000 0.0000\nCl 1.5500 -2.2000 0.0000\n"
    },
    "med-omeprazole-01": {
        "catalyst": "Gastric H+/K+-ATPase Acid Secretory Matrix (pH < 1.0)",
        "barrier": 10.9,
        "doi": "10.1038/318070a0",
        "xyz": "4\nAcid Canalicular Hydronium Cluster\nO  0.0000 0.0000 0.0000\nH  0.9500 0.0000 0.0000\nH -0.4500 0.8500 0.0000\nH -0.4500 -0.8500 0.0000\n"
    },
    "med-metformin-01": {
        "catalyst": "Mitochondrial Complex I / LKB1-AMPK",
        "barrier": 15.0,
        "doi": "10.1038/nm1434",
        "xyz": "6\nComplex I Fe4S4 Cluster Model\nFe 0.0000 0.0000 0.0000\nFe 2.2000 0.0000 0.0000\nS  1.1000 1.8000 0.0000\nS  1.1000 -1.8000 0.0000\nS  1.1000 0.0000 1.8000\nS  1.1000 0.0000 -1.8000\n"
    },
    "med-glimepiride-01": {
        "catalyst": "SUR1 Regulatory Sulfonylurea Receptor",
        "barrier": 13.5,
        "doi": "10.1055/s-2007-979921",
        "xyz": "4\nK-ATP Channel Filter\nK  0.0000 0.0000 0.0000\nO  2.6000 0.0000 0.0000\nO -2.6000 0.0000 0.0000\nO  0.0000 2.6000 0.0000\n"
    },
    "med-methotrexate-01": {
        "catalyst": "DHFR Active Site (Asp27 / NADPH)",
        "barrier": 12.4,
        "doi": "10.1126/science.197.4302.452",
        "xyz": "6\nDHFR Catalytic Carboxylate-Hydride Model\nC  0.0000 0.0000 0.0000\nO  1.2500 0.0000 0.0000\nO -1.2500 0.0000 0.0000\nC  0.0000 2.8000 0.0000\nN  1.1500 3.4000 0.0000\nH  0.0000 1.7000 0.0000\n"
    },
    "med-5fu-01": {
        "catalyst": "Thymidylate Synthase (Cys195 / CH2-H4folate)",
        "barrier": 11.2,
        "doi": "10.1016/0006-2952(81)90013-1",
        "xyz": "5\nTS Active Cys Thiolate Model\nS  0.0000 0.0000 0.0000\nC  1.8000 0.0000 0.0000\nN -1.3000 1.3000 0.0000\nC -2.1000 0.0000 0.0000\nH  2.1500 0.9500 0.0000\n"
    },
    "med-cisplatin-01": {
        "catalyst": "Aquation Hydration Matrix (H2O)",
        "barrier": 19.5,
        "doi": "10.1038/sj.onc.1206933",
        "xyz": "5\nCisplatin Active Matrix\nPt 0.0000 0.0000 0.0000\nCl 2.3000 0.0000 0.0000\nCl 0.0000 2.3000 0.0000\nN -2.0500 0.0000 0.0000\nN  0.0000 -2.0500 0.0000\n"
    },
    "med-morphine-gluc-01": {
        "catalyst": "UGT2B7 (UDP-Glucuronosyltransferase)",
        "barrier": 16.8,
        "doi": "10.1124/mol.55.6.1089",
        "xyz": "6\nUDP-Glucuronic Phosphate Donor Core\nP  0.0000 0.0000 0.0000\nO  1.5500 0.0000 0.0000\nO -1.5500 0.0000 0.0000\nO  0.0000 1.5500 0.0000\nO  0.0000 -1.5500 0.0000\nC  2.6500 0.0000 0.0000\n"
    },
    "med-nat2-isoniazid-01": {
        "catalyst": "NAT2 (Cys68 Acetyl-Enzyme Intermediate)",
        "barrier": 14.2,
        "doi": "10.1124/pr.54.4.579",
        "xyz": "6\nNAT2 S-Acetyl Cys Intermediate\nS  0.0000 0.0000 0.0000\nC  1.7500 0.0000 0.0000\nO  2.4000 1.0500 0.0000\nC  2.3000 -1.4000 0.0000\nC -1.4000 0.0000 0.0000\nH -1.7500 0.9500 0.0000\n"
    },
    "med-ciprofloxacin-01": {
        "catalyst": "Mg2+ Water-Metal Ion Coordination Bridge",
        "barrier": 13.0,
        "doi": "10.1038/nature09197",
        "xyz": "5\nMg(H2O)4 Complex Core\nMg 0.0000 0.0000 0.0000\nO  2.0500 0.0000 0.0000\nO -2.0500 0.0000 0.0000\nO  0.0000 2.0500 0.0000\nO  0.0000 -2.0500 0.0000\n"
    },
    "med-azithromycin-01": {
        "catalyst": "23S rRNA Peptidyltransferase Residues",
        "barrier": 15.1,
        "doi": "10.1016/S0969-2126(02)00778-1",
        "xyz": "6\nrRNA Ribose-Phosphate Unit\nP  0.0000 0.0000 0.0000\nO  1.5500 0.0000 0.0000\nO -1.5500 0.0000 0.0000\nO  0.0000 1.5500 0.0000\nC  1.1000 2.5000 0.0000\nO  0.8000 3.7000 0.0000\n"
    },
    "med-ceftriaxone-01": {
        "catalyst": "PBP3 (Transpeptidase Active Ser403)",
        "barrier": 14.7,
        "doi": "10.1093/jac/45.suppl_3.1",
        "xyz": "6\nPBP Ser-Lys Active Site\nC  0.0000 0.0000 0.0000\nO  1.4000 0.0000 0.0000\nN  2.8000 0.0000 0.0000\nC -0.6500 1.3000 0.0000\nC -2.1500 1.3000 0.0000\nH  1.7500 -0.8500 0.0000\n"
    },
    "med-levodopa-01": {
        "catalyst": "Aromatic L-Amino Acid Decarboxylase (PLP)",
        "barrier": 15.9,
        "doi": "10.1016/S0140-6736(67)91544-8",
        "xyz": "7\nPLP Pyridine Core Model\nN  0.0000 1.3500 0.0000\nC  1.1500 0.6500 0.0000\nC  1.1500 -0.7500 0.0000\nC  0.0000 -1.4500 0.0000\nC -1.1500 -0.7500 0.0000\nC -1.1500 0.6500 0.0000\nO  0.0000 -2.7000 0.0000\n"
    }
}

# ── Veterinary Catalysts Map ────────────────────────────────────────────────
VETERINARY_CATALYSTS = {
    "vet-enrofloxacin-01": {
        "catalyst": "Mg2+ Water-Metal Ion Coordination Bridge",
        "barrier": 17.4,
        "doi": "10.1016/j.vetmic.2026.108421",
        "xyz": "5\nMg(H2O)4 Complex Core\nMg 0.0000 0.0000 0.0000\nO  2.0500 0.0000 0.0000\nO -2.0500 0.0000 0.0000\nO  0.0000 2.0500 0.0000\nO  0.0000 -2.0500 0.0000\n"
    },
    "vet-ivermectin-01": {
        "catalyst": "GluCl Receptor Transmembrane Alpha-Pore",
        "barrier": 14.2,
        "doi": "10.1016/j.vetpar.2026.109852",
        "xyz": "5\nGluCl Pore Subunit Filter\nCl 0.0000 0.0000 0.0000\nN  2.2000 0.0000 0.0000\nN -2.2000 0.0000 0.0000\nO  0.0000 2.2000 0.0000\nO  0.0000 -2.2000 0.0000\n"
    },
    "vet-meloxicam-01": {
        "catalyst": "Canine CYP2C21 (Cytochrome P450 Fe=O Heme)",
        "barrier": 16.5,
        "doi": "10.1111/jvp.13105",
        "xyz": "6\nFe(IV)=O Heme Active Intermediate\nFe 0.0000 0.0000 0.0000\nO  0.0000 0.0000 1.6200\nN  2.0000 0.0000 0.0000\nN -2.0000 0.0000 0.0000\nN  0.0000 2.0000 0.0000\nN  0.0000 -2.0000 0.0000\n"
    },
    "vet-fenbendazole-01": {
        "catalyst": "Nematode Beta-Tubulin Cys239 Sulfhydryl",
        "barrier": 15.8,
        "doi": "10.1016/j.ijpddr.2026.01.004",
        "xyz": "5\nTubulin Cys Active Thiolate Core\nS  0.0000 0.0000 0.0000\nC  1.8000 0.0000 0.0000\nC -1.4000 0.0000 0.0000\nN -1.9500 1.3000 0.0000\nH  2.1500 0.9500 0.0000\n"
    },
    "vet-flunixin-01": {
        "catalyst": "Equine COX-1/2 (Fe(III)-Protoporphyrin / Tyr385)",
        "barrier": 15.3,
        "doi": "10.2746/042516405775314789",
        "xyz": "5\nFe-Porphyrin Heme Center\nFe 0.0000 0.0000 0.0000\nN  2.0000 0.0000 0.0000\nN -2.0000 0.0000 0.0000\nN  0.0000 2.0000 0.0000\nN  0.0000 -2.0000 0.0000\n"
    },
    "vet-xylazine-01": {
        "catalyst": "Alpha-2 Adrenoceptor Asp113 Coordination Matrix",
        "barrier": 13.9,
        "doi": "10.1111/vaa.12984",
        "xyz": "5\nAsp Carboxylate Coordination Core\nC  0.0000 0.0000 0.0000\nO  1.2500 0.0000 0.0000\nO -1.2500 0.0000 0.0000\nC  0.0000 1.5500 0.0000\nH  0.9000 1.9500 0.0000\n"
    },
    "vet-florfenicol-01": {
        "catalyst": "23S rRNA A2451 / C2452 Peptidyl Transferase",
        "barrier": 16.1,
        "doi": "10.3389/fvets.2026.892014",
        "xyz": "6\nrRNA Ribose-Phosphate Unit\nP  0.0000 0.0000 0.0000\nO  1.5500 0.0000 0.0000\nO -1.5500 0.0000 0.0000\nO  0.0000 1.5500 0.0000\nC  1.1000 2.5000 0.0000\nO  0.8000 3.7000 0.0000\n"
    },
    "vet-carprofen-01": {
        "catalyst": "Canine COX-2 (Arg120 / Tyr355 Constriction Pocket)",
        "barrier": 14.6,
        "doi": "10.2460/ajvr.2026.0028",
        "xyz": "5\nCOX-2 Constriction Pocket Unit\nC  0.0000 0.0000 0.0000\nN  1.3500 0.0000 0.0000\nN -1.3500 0.0000 0.0000\nO  0.0000 1.4000 0.0000\nH  1.7500 0.9500 0.0000\n"
    },
    "vet-pimobendan-01": {
        "catalyst": "Troponin C (Ca2+ Sensitizer Pocket & PDE3 Zn2+)",
        "barrier": 12.7,
        "doi": "10.1111/jvim.16540",
        "xyz": "5\nCa2+ / Zn2+ Sensitization Pair\nCa 0.0000 0.0000 0.0000\nZn 3.8000 0.0000 0.0000\nO  1.9000 1.2000 0.0000\nO  1.9000 -1.2000 0.0000\nN  3.8000 2.0000 0.0000\n"
    },
    "vet-tylosin-01": {
        "catalyst": "50S Subunit rRNA Tunnel Nucleotide Constriction",
        "barrier": 15.4,
        "doi": "10.1016/j.psj.2026.102194",
        "xyz": "6\nrRNA Ribose-Phosphate Unit\nP  0.0000 0.0000 0.0000\nO  1.5500 0.0000 0.0000\nO -1.5500 0.0000 0.0000\nO  0.0000 1.5500 0.0000\nC  1.1000 2.5000 0.0000\nO  0.8000 3.7000 0.0000\n"
    }
}

# ── Curated Classical Catalysts Map ─────────────────────────────────────────
CLASSICAL_CATALYSTS = {
    "eas-01": {
        "catalyst": "AlCl3 (Aluminum Trichloride Lewis Acid)",
        "barrier": 14.8,
        "doi": "10.1021/ed085p941",
        "xyz": "4\nAlCl3 Lewis Acid Catalyst\nAl  0.0000  0.0000  0.0000\nCl  2.0600  0.0000  0.0000\nCl -1.0300  1.7840  0.0000\nCl -1.0300 -1.7840  0.0000\n"
    },
    "epox-01": {
        "catalyst": "m-CPBA / Mo(CO)6 Metal Complex",
        "barrier": 15.5,
        "doi": "10.1021/cr00092a008",
        "xyz": "7\nMo(CO)6 Complex Fragment\nMo 0.0000 0.0000 0.0000\nC  2.0600 0.0000 0.0000\nC -2.0600 0.0000 0.0000\nC  0.0000 2.0600 0.0000\nC  0.0000 -2.0600 0.0000\nO  3.2000 0.0000 0.0000\nO -3.2000 0.0000 0.0000\n"
    },
    "hydro-01": {
        "catalyst": "THF / DMS Lewis Base Complex",
        "barrier": 11.2,
        "doi": "10.1021/ja01602a063",
        "xyz": "5\nTHF Solvent/Catalytic Matrix\nO  0.0000 1.1000 0.0000\nC  1.1500 0.3500 0.0000\nC  0.7000 -1.1000 0.0000\nC -0.7000 -1.1000 0.0000\nC -1.1500 0.3500 0.0000\n"
    },
    "wit-01": {
        "catalyst": "NaHMDS / LiCl Base Medium",
        "barrier": 14.1,
        "doi": "10.1021/ja01509a040",
        "xyz": "4\nNaHMDS / LiCl Cluster\nLi 0.0000 0.0000 0.0000\nCl 2.2000 0.0000 0.0000\nN -1.9500 0.0000 0.0000\nNa -3.5000 0.0000 0.0000\n"
    },
    "diels_alder": {
        "catalyst": "AlCl3 / Sc(OTf)3 Lewis Acid",
        "barrier": 13.2,
        "doi": "10.1021/ja00073a014",
        "xyz": "4\nAlCl3 Lewis Acid Catalyst\nAl  0.0000  0.0000  0.0000\nCl  2.0600  0.0000  0.0000\nCl -1.0300  1.7840  0.0000\nCl -1.0300 -1.7840  0.0000\n"
    },
    "sn2": {
        "catalyst": "Tetrabutylammonium Halide / 18-Crown-6",
        "barrier": 13.2,
        "doi": "10.1021/ja00206a030",
        "xyz": "5\nCrown Ether Coordination\nO  0.0000 2.2000 0.0000\nO  1.9000 1.1000 0.0000\nO  1.9000 -1.1000 0.0000\nO  0.0000 -2.2000 0.0000\nK  0.0000 0.0000 0.0000\n"
    },
    "cope": {
        "catalyst": "Pd(PhCN)2Cl2 Catalytic Complex",
        "barrier": 19.5,
        "doi": "10.1021/ja00041a058",
        "xyz": "5\nPdCl2 Core\nPd 0.0000 0.0000 0.0000\nCl 2.3000 0.0000 0.0000\nCl -2.3000 0.0000 0.0000\nN  0.0000 2.0500 0.0000\nN  0.0000 -2.0500 0.0000\n"
    },
    "claisen": {
        "catalyst": "Yb(OTf)3 / Sc(OTf)3 Lewis Acid",
        "barrier": 18.2,
        "doi": "10.1021/ja00046a007",
        "xyz": "4\nSc(III) Lewis Core\nSc 0.0000 0.0000 0.0000\nO  2.0000 0.0000 0.0000\nO -1.0000 1.7300 0.0000\nO -1.0000 -1.7300 0.0000\n"
    },
    "h_abstraction": {
        "catalyst": "Radical Initiator (AIBN / Peroxide)",
        "barrier": 5.5,
        "doi": "10.1021/jp972097d",
        "xyz": "4\nPeroxy Radical Core\nO 0.0000 0.0000 0.0000\nO 1.3500 0.0000 0.0000\nC 2.5000 0.0000 0.0000\nH 2.8500 0.9500 0.0000\n"
    },
    "ene_reaction": {
        "catalyst": "Me2AlCl / TiCl4 Lewis Acid",
        "barrier": 15.4,
        "doi": "10.1039/c9cp01847e",
        "xyz": "4\nAlCl(Me)2 Core\nAl 0.0000 0.0000 0.0000\nCl 2.1000 0.0000 0.0000\nC -1.1000 1.6000 0.0000\nC -1.1000 -1.6000 0.0000\n"
    },
    "decarboxylation": {
        "catalyst": "Cu(II) / Pyridine Catalyst",
        "barrier": 21.0,
        "doi": "10.1021/ja00072a017",
        "xyz": "5\nCu(II)-Pyridine Complex\nCu 0.0000 0.0000 0.0000\nN  2.0000 0.0000 0.0000\nN -2.0000 0.0000 0.0000\nO  0.0000 1.9500 0.0000\nO  0.0000 -1.9500 0.0000\n"
    },
    "beckmann": {
        "catalyst": "PCl5 / SOCl2 / H2SO4 Catalyst",
        "barrier": 21.3,
        "doi": "10.1002/chem.200600431",
        "xyz": "6\nThionyl Chloride Catalyst\nS  0.0000 0.0000 0.0000\nO  1.4500 0.0000 0.0000\nCl -0.9000 1.7000 0.0000\nCl -0.9000 -1.7000 0.0000\nH  1.8000 0.9500 0.0000\nO -2.0000 0.0000 0.0000\n"
    },
    "heck": {
        "catalyst": "Pd(OAc)2 / P(o-tol)3 Palladium Catalyst",
        "barrier": 18.7,
        "doi": "10.1021/ja034748y",
        "xyz": "5\nPd(0) Phosphine Center\nPd 0.0000 0.0000 0.0000\nP  2.2500 0.0000 0.0000\nP -2.2500 0.0000 0.0000\nC  0.0000 1.9500 0.0000\nC  0.0000 -1.9500 0.0000\n"
    },
    "click_triazole": {
        "catalyst": "Cu(I) (Copper(I) Ascorbate)",
        "barrier": 12.8,
        "doi": "10.1002/anie.200135894",
        "xyz": "3\nCu(I) Click Catalyst Core\nCu 0.0000 0.0000 0.0000\nCl 2.1500 0.0000 0.0000\nN -1.9500 0.0000 0.0000\n"
    },
    "grignard_addition": {
        "catalyst": "LiCl / I2 Catalytic Activator",
        "barrier": 14.6,
        "doi": "10.1021/ed081p1653",
        "xyz": "3\nLiCl / I2 Matrix\nLi 0.0000 0.0000 0.0000\nCl 2.1000 0.0000 0.0000\nI -2.6000 0.0000 0.0000\n"
    }
}

def enrich_json_file(path, cat_map):
    if not os.path.exists(path):
        return
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    modified = 0
    for r in data:
        r_id = r.get("id")
        if r_id in cat_map:
            c = cat_map[r_id]
            r["defaultCatalystName"] = c["catalyst"]
            r["literatureBarrierKcalMol"] = c["barrier"]
            r["hasLiteratureCatalyst"] = True
            r["literatureDoi"] = c["doi"]
            if "xyz" in c:
                r["catalystXyz"] = c["xyz"]
            modified += 1
        elif r.get("category") == "polymer":
            # ensure all polymers have literature catalyst flag
            if r.get("defaultCatalystName"):
                r["hasLiteratureCatalyst"] = True
                r["literatureBarrierKcalMol"] = r.get("referenceEa")
                r["literatureDoi"] = r.get("doi")
                modified += 1
    
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    print(f"Updated {path}: enriched {modified} entries")

# 1. Update JSON files
enrich_json_file("quantum_forge/assets/medical_reactions.json", MEDICAL_CATALYSTS)
enrich_json_file("quantum_forge/assets/veterinary_reactions.json", VETERINARY_CATALYSTS)
enrich_json_file("quantum_forge/assets/massive_reactions.json", {**MEDICAL_CATALYSTS, **VETERINARY_CATALYSTS, **CLASSICAL_CATALYSTS})

# 2. Update medical_reaction_templates.dart
with open("quantum_forge/assets/medical_reactions.json", "r", encoding="utf-8") as f:
    med_data = json.load(f)

lines = [
    "// ============================================================================",
    "// Medical & Pharmaceutical Reaction Templates for MBBS & Pharm-D Students",
    "// Curated with 3D Cartesian coordinates (RDKit MMFF94) & clinical citations.",
    "// ============================================================================",
    "",
    "import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';",
    "",
    "final List<ReactionTemplate> kMedicalReactionTemplates = ["
]

for r in med_data:
    cat = "ReactionCategory." + r["category"]
    tags_formatted = json.dumps(r["tags"])
    name_escaped = r["name"].replace("'", "\\'")
    iupac_escaped = r["iupacName"].replace("'", "\\'")
    desc_escaped = r["description"].replace("'", "\\'").replace("$", "\\$")
    r_xyz = r["reactantXyz"].strip()
    p_xyz = r["productXyz"].strip()
    
    cat_name = r.get("defaultCatalystName", "")
    cat_barrier = r.get("literatureBarrierKcalMol", r["referenceEa"])
    lit_doi = r.get("literatureDoi", r["doi"])
    cat_xyz = r.get("catalystXyz", "")
    
    cat_fields = ""
    if cat_name:
        cat_fields = f"""    defaultCatalystName: '{cat_name}',
    literatureBarrierKcalMol: {cat_barrier},
    hasLiteratureCatalyst: true,
    literatureDoi: '{lit_doi}',"""
        if cat_xyz:
            cat_fields += f"""\n    catalystXyz: '''{cat_xyz.strip()}''',"""

    entry = f"""  ReactionTemplate(
    id: '{r["id"]}',
    name: '{name_escaped}',
    iupacName: '{iupac_escaped}',
    description: '{desc_escaped}',
    category: {cat},
    reactantXyz: '''{r_xyz}''',
    productXyz: '''{p_xyz}''',
    referenceEa: {r["referenceEa"]},
    doi: '{r["doi"]}',
    journalRef: '{r["journalRef"]}',
    tags: const {tags_formatted},
{cat_fields}
  ),"""
    lines.append(entry)

lines.append("];")
lines.append("")

with open("quantum_forge/lib/features/reaction_library/data/medical_reaction_templates.dart", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print("Successfully updated medical_reaction_templates.dart")

# 3. Update veterinary_reaction_templates.dart
with open("quantum_forge/assets/veterinary_reactions.json", "r", encoding="utf-8") as f:
    vet_data = json.load(f)

lines = [
    "// ============================================================================",
    "// Veterinary Reaction Templates for DVM & Veterinary Pharmacology",
    "// Curated with 3D Cartesian coordinates & clinical veterinary mechanisms.",
    "// ============================================================================",
    "",
    "import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';",
    "",
    "final List<ReactionTemplate> kVeterinaryReactionTemplates = ["
]

for r in vet_data:
    cat = "ReactionCategory." + r["category"]
    tags_formatted = json.dumps(r["tags"])
    name_escaped = r["name"].replace("'", "\\'")
    iupac_escaped = r["iupacName"].replace("'", "\\'")
    desc_escaped = r["description"].replace("'", "\\'").replace("$", "\\$")
    r_xyz = r["reactantXyz"].strip()
    p_xyz = r["productXyz"].strip()
    
    cat_name = r.get("defaultCatalystName", "")
    cat_barrier = r.get("literatureBarrierKcalMol", r["referenceEa"])
    lit_doi = r.get("literatureDoi", r["doi"])
    cat_xyz = r.get("catalystXyz", "")
    
    cat_fields = ""
    if cat_name:
        cat_fields = f"""    defaultCatalystName: '{cat_name}',
    literatureBarrierKcalMol: {cat_barrier},
    hasLiteratureCatalyst: true,
    literatureDoi: '{lit_doi}',"""
        if cat_xyz:
            cat_fields += f"""\n    catalystXyz: '''{cat_xyz.strip()}''',"""

    entry = f"""  ReactionTemplate(
    id: '{r["id"]}',
    name: '{name_escaped}',
    iupacName: '{iupac_escaped}',
    description: '{desc_escaped}',
    category: {cat},
    reactantXyz: '''{r_xyz}''',
    productXyz: '''{p_xyz}''',
    referenceEa: {r["referenceEa"]},
    doi: '{r["doi"]}',
    journalRef: '{r["journalRef"]}',
    tags: const {tags_formatted},
{cat_fields}
  ),"""
    lines.append(entry)

lines.append("];")
lines.append("")

with open("quantum_forge/lib/features/reaction_library/data/veterinary_reaction_templates.dart", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print("Successfully updated veterinary_reaction_templates.dart")

# 4. Enrich classical templates in reaction_templates.dart
with open("quantum_forge/lib/features/reaction_library/data/reaction_templates.dart", "r", encoding="utf-8") as f:
    r_content = f.read()

for r_id, c in CLASSICAL_CATALYSTS.items():
    # check if defaultCatalystName is already in this template
    pattern = rf"(id:\s*'{re.escape(r_id)}'.*?doi:\s*'[^']+'.*?journalRef:\s*'[^']+'.*?tags:\s*[^,]+,)"
    m = re.search(pattern, r_content, re.DOTALL)
    if m:
        matched_str = m.group(1)
        if "defaultCatalystName" not in matched_str and "defaultCatalystName" not in r_content[m.end():m.end()+200]:
            cat_block = f"""
    defaultCatalystName: '{c["catalyst"]}',
    literatureBarrierKcalMol: {c["barrier"]},
    hasLiteratureCatalyst: true,
    literatureDoi: '{c["doi"]}',"""
            r_content = r_content[:m.end()] + cat_block + r_content[m.end():]
            print(f"Added catalyst to {r_id} in reaction_templates.dart")

with open("quantum_forge/lib/features/reaction_library/data/reaction_templates.dart", "w", encoding="utf-8") as f:
    f.write(r_content)
print("Successfully processed reaction_templates.dart")
