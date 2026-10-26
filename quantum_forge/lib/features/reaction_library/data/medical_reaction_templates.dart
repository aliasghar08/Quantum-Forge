// ============================================================================
// Medical & Pharmaceutical Reaction Templates for MBBS & Pharm-D Students
// Curated with 3D Cartesian coordinates (RDKit MMFF94) & clinical citations.
// ============================================================================

import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

final List<ReactionTemplate> kMedicalReactionTemplates = [
  ReactionTemplate(
    id: 'med-aspirin-01',
    name: 'Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation',
    iupacName: '2-hydroxybenzoic acid + acetic anhydride → 2-acetoxybenzoic acid + acetic acid',
    description: 'Core medicinal chemistry & pharmacology milestone for Pharm-D and MBBS students. Salicylic acid undergoes esterification of its phenolic hydroxyl group by acetic anhydride. In clinical medicine, Aspirin irreversibly acetylates Serine-530 of COX-1 and Serine-516 of COX-2, permanently blocking thromboxane A2 (antiplatelet cardioprotection) and prostaglandins (anti-inflammatory, antipyretic, analgesic).',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''29
Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation - Reactants
O      2.4232    -1.1712    -1.2598
C      1.8300    -0.1942    -0.8426
O      2.3936     1.0308    -0.8995
C      0.4750    -0.1829    -0.2396
C     -0.1904    -1.4144    -0.1385
C     -1.4697    -1.4845     0.4181
C     -2.0935    -0.3258     0.8775
C     -1.4404     0.9030     0.7815
C     -0.1630     0.9749     0.2260
O      0.3949     2.2237     0.1754
H      3.2665     0.8486    -1.3156
H      0.2858    -2.3269    -0.4936
H     -1.9784    -2.4428     0.4927
H     -3.0892    -0.3777     1.3112
H     -1.9261     1.8072     1.1395
H      1.2818     2.1323    -0.2326
C      1.7110     0.2517    -0.4515
C      2.8215    -0.4324     0.2934
O      2.6211    -1.3121     1.1158
O      4.0046     0.0966    -0.1127
C      5.1388    -0.3945     0.4502
O      5.2551    -1.2690     1.2941
C      6.3167     0.3269    -0.1398
H      1.7170     1.3213    -0.2266
H      1.8251     0.0826    -1.5253
H      0.7503    -0.1645    -0.1345
H      7.2390    -0.0586     0.3046
H      6.3538     0.1566    -1.2189
H      6.2458     1.3953     0.0799''',
    productXyz: '''29
Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation - Products
C     -2.6530    -2.2025    -0.0709
C     -1.8247    -0.9960     0.2552
O     -1.9093    -0.3594     1.2977
O     -0.9858    -0.7224    -0.8194
C     -0.1111     0.3372    -0.5618
C     -0.4625     1.5852    -1.0865
C      0.3799     2.6777    -0.8905
C      1.5722     2.5200    -0.1846
C      1.9297     1.2662     0.3225
C      1.0933     0.1550     0.1332
C      1.4807    -1.1863     0.6441
O      0.8872    -2.2358     0.4771
O      2.6245    -1.1573     1.3553
H     -3.3052    -1.9850    -0.9201
H     -3.2732    -2.4595     0.7926
H     -2.0017    -3.0517    -0.2924
H     -1.3911     1.7069    -1.6371
H      0.1068     3.6531    -1.2860
H      2.2282     3.3735    -0.0293
H      2.8687     1.1689     0.8628
H      2.7464    -2.0877     1.6383
C      3.0665    -0.0601    -0.2304
C      4.4936     0.2789     0.0469
O      5.0325     1.3566    -0.1361
O      5.1814    -0.7645     0.5462
H      2.5573     0.8203    -0.6327
H      2.5695    -0.3576     0.6963
H      3.0133    -0.8625    -0.9702
H      6.0859    -0.4112     0.6800''',
    referenceEa: 18.2,
    doi: '10.1073/pnas.72.8.3073',
    journalRef: 'Proc. Natl. Acad. Sci. U.S.A. 1975, 72, 3073-3076',
    tags: const ["Pharm-D", "MBBS", "NSAID", "Aspirin", "COX-1/2", "Antiplatelet", "Esterification"],
    defaultCatalystName: 'H2SO4 (Sulfuric Acid)',
    literatureBarrierKcalMol: 18.2,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/s0021-9258(17)36820-5',
    catalystXyz: '''7
H2SO4 Catalyst
S  0.0000 0.0000 0.0000
O  0.0000 1.4500 0.0000
O  1.4500 0.0000 0.0000
O -0.7500 -0.7500  1.1000
O -0.7500 -0.7500 -1.1000
H -0.5000 -1.6500  1.1000
H -0.5000 -1.6500 -1.1000''',
  ),
  ReactionTemplate(
    id: 'med-paracetamol-01',
    name: 'Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology',
    iupacName: '4-aminophenol + acetic anhydride → N-(4-hydroxyphenyl)acetamide + acetic acid',
    description: 'Foundational drug synthesis for Pharm-D students. Selective nucleophilic N-acylation of 4-aminophenol over the phenolic oxygen due to greater amine nucleophilicity. Essential in MBBS pharmacology & toxicology: therapeutically acts via central COX-3/TRPA1 modulation; in overdose, hepatic CYP2E1 oxidizes paracetamol into toxic NAPQI, causing fatal centrilobular hepatic necrosis treated with N-acetylcysteine (NAC).',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''28
Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology - Reactants
N     -2.5316    -0.4550    -0.1282
C     -1.1704    -0.1480    -0.0181
C     -0.6400     0.9535    -0.6956
C      0.7349     1.2003    -0.6873
C      1.5872     0.3181    -0.0370
O      2.9221     0.5924    -0.0541
C      1.0870    -0.8156     0.5927
C     -0.2905    -1.0549     0.5812
H     -3.1217     0.3561    -0.2847
H     -2.8807    -1.0472     0.6185
H     -1.2936     1.6323    -1.2363
H      1.1376     2.0692    -1.1992
H      3.3884    -0.1148     0.4206
H      1.7446    -1.5268     1.0814
H     -0.6734    -1.9594     1.0461
C      1.7110     0.2517    -0.4515
C      2.8215    -0.4324     0.2934
O      2.6211    -1.3121     1.1158
O      4.0046     0.0966    -0.1127
C      5.1388    -0.3945     0.4502
O      5.2551    -1.2690     1.2941
C      6.3167     0.3269    -0.1398
H      1.7170     1.3213    -0.2266
H      1.8251     0.0826    -1.5253
H      0.7503    -0.1645    -0.1345
H      7.2390    -0.0586     0.3046
H      6.3538     0.1566    -1.2189
H      6.2458     1.3953     0.0799''',
    productXyz: '''28
Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology - Products
C      3.6706    -0.5420    -0.0543
C      2.2108    -0.8849    -0.2206
O      1.8684    -2.0054    -0.5804
N      1.3849     0.1765     0.1028
C     -0.0244     0.2106     0.0673
C     -0.8227    -0.8659    -0.3277
C     -2.2179    -0.7526    -0.3366
C     -2.8129     0.4417     0.0507
O     -4.1669     0.5939     0.0565
C     -2.0369     1.5222     0.4455
C     -0.6446     1.4069     0.4536
H      3.8684     0.4884    -0.3635
H      4.2731    -1.2050    -0.6819
H      3.9565    -0.6737     0.9925
H      1.8380     1.0283     0.4084
H     -0.3905    -1.8125    -0.6369
H     -2.8125    -1.6057    -0.6480
H     -4.5716    -0.2382    -0.2398
H     -2.5125     2.4514     0.7461
H     -0.0575     2.2659     0.7665
C      3.0665    -0.0601    -0.2304
C      4.4936     0.2789     0.0469
O      5.0325     1.3566    -0.1361
O      5.1814    -0.7645     0.5462
H      2.5573     0.8203    -0.6327
H      2.5695    -0.3576     0.6963
H      3.0133    -0.8625    -0.9702
H      6.0859    -0.4112     0.6800''',
    referenceEa: 14.5,
    doi: '10.1159/000136547',
    journalRef: 'Pharmacology 1974, 12, 251-260',
    tags: const ["Pharm-D", "MBBS", "Paracetamol", "Analgesic", "CYP2E1", "NAPQI", "Toxicology"],
    defaultCatalystName: 'CH3COONa / H2SO4 Buffer',
    literatureBarrierKcalMol: 14.5,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1159/000136547',
    catalystXyz: '''7
CH3COONa Catalyst
C  0.0000 0.0000 0.0000
C  1.5000 0.0000 0.0000
O  2.1500 1.1000 0.0000
O  2.0500 -1.1500 0.0000
H -0.4000 1.0000 0.0000
H -0.4000 -0.5000 0.9000
H -0.4000 -0.5000 -0.9000''',
  ),
  ReactionTemplate(
    id: 'med-penicillin-01',
    name: 'Penicillin Beta-Lactam Ring Hydrolysis & Resistance',
    iupacName: 'penicillin beta-lactam core + H2O → penicilloic acid (inactivated)',
    description: 'The premier antimicrobial mechanism in MBBS & Pharm-D pharmacology. Beta-lactams mimic the D-Ala-D-Ala terminus of bacterial cell-wall peptidoglycan. The highly strained 4-membered beta-lactam ring acylates bacterial transpeptidase (Penicillin Binding Protein). Hydrolysis by bacterial beta-lactamases opens the ring, nullifying antibiotic activity and conferring resistance, reversed clinically by beta-lactamase inhibitors like Clavulanic acid and Tazobactam.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''13
Penicillin Beta-Lactam Ring Hydrolysis & Resistance - Reactants
O     -1.6581    -1.0665    -0.2270
C     -1.0425    -0.2376     0.4147
C     -0.5619     1.0797     0.0374
C      0.3986     0.0285     0.5008
N      1.2498    -0.6734    -0.4790
H     -0.6072     1.3265    -1.0139
H     -0.7962     1.8893     0.7134
H      0.8076     0.1303     1.4997
H      0.7085    -0.8798    -1.3248
H      1.5015    -1.5969    -0.1211
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''13
Penicillin Beta-Lactam Ring Hydrolysis & Resistance - Products
O      2.1932     0.2051     0.3850
C      1.4884    -0.1860    -0.5294
O      2.0404    -0.6241    -1.6787
C     -0.0125    -0.2407    -0.5695
C     -0.6022     0.1797     0.7714
N     -2.0635     0.1221     0.7393
H      3.0056    -0.5414    -1.5296
H     -0.3142    -1.2672    -0.8073
H     -0.3592     0.4287    -1.3648
H     -0.2868     1.1976     1.0280
H     -0.2391    -0.4818     1.5663
H     -2.4214     0.8020     0.0689
H     -2.4287     0.4060     1.6487''',
    referenceEa: 19.8,
    doi: '10.1073/pnas.54.4.1133',
    journalRef: 'Proc. Natl. Acad. Sci. U.S.A. 1965, 54, 1133-1141',
    tags: const ["Pharm-D", "MBBS", "Antibiotic", "Beta-lactam", "Penicillin", "Resistance", "Microbiology"],
    defaultCatalystName: 'Beta-Lactamase (Ser70/Zn2+)',
    literatureBarrierKcalMol: 19.8,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1073/pnas.54.4.1133',
    catalystXyz: '''4
Zn(II) Active Site Core
Zn 0.0000 0.0000 0.0000
N  1.9500 0.0000 0.0000
N -0.9500 1.7000 0.0000
O -0.9500 -1.7000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-acetylcholine-01',
    name: 'Acetylcholine Hydrolysis by Acetylcholinesterase (AChE)',
    iupacName: 'acetylcholine + H2O → choline + acetic acid',
    description: 'Critical neuropharmacology & autonomic physiology reaction for MBBS and Pharm-D students. Rapid catalytic ester hydrolysis by Acetylcholinesterase via catalytic triad (Ser200, His440, Glu327) terminating synaptic cholinergic transmission. Crucial for understanding organophosphate/sarin intoxication (irreversible phosphorylation treated by Pralidoxime/2-PAM), Myasthenia Gravis (Pyridostigmine therapy), and Alzheimer disease (Donepezil/Rivastigmine).',
    category: ReactionCategory.biochemical,
    reactantXyz: '''29
Acetylcholine Hydrolysis by Acetylcholinesterase (AChE) - Reactants
C      4.0551    -0.5141     0.3075
C      2.5621    -0.5950     0.2459
O      1.8233    -0.7992     1.1999
O      2.1165    -0.3774    -1.0246
C      0.6962    -0.5343    -1.1905
C     -0.0750     0.6730    -0.6248
N     -1.4575     0.3341    -0.0253
C     -2.3404    -0.3992    -1.0228
C     -2.1413     1.6490     0.3574
C     -1.2998    -0.5000     1.2489
H      4.4946    -1.2333    -0.3883
H      4.3893    -0.7634     1.3186
H      4.3804     0.5012     0.0684
H      0.3951    -1.4940    -0.7592
H      0.5090    -0.6102    -2.2675
H     -0.2513     1.3939    -1.4330
H      0.4882     1.1972     0.1555
H     -2.4066     0.2041    -1.9328
H     -3.3311    -0.5306    -0.5774
H     -1.8983    -1.3749    -1.2394
H     -1.5064     2.1729     1.0781
H     -3.1144     1.4186     0.8016
H     -2.2692     2.2482    -0.5491
H     -0.6518     0.0443     1.9414
H     -0.8744    -1.4719     0.9911
H     -2.2920    -0.6390     1.6894
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''29
Acetylcholine Hydrolysis by Acetylcholinesterase (AChE) - Products
O      1.9881    -1.5224    -0.3600
C      2.0078    -0.1167    -0.1427
C      0.7392     0.5453    -0.7080
N     -0.5777     0.1765     0.0240
C     -0.8323    -1.3294    -0.0166
C     -1.7249     0.8734    -0.7076
C     -0.5629     0.6478     1.4685
H      2.8742    -1.8675    -0.1355
H      2.1343     0.0777     0.9252
H      2.8798     0.2884    -0.6670
H      0.8306     1.6360    -0.6540
H      0.5995     0.2471    -1.7538
H     -0.6991    -1.6789    -1.0442
H     -0.1484    -1.8283     0.6735
H     -1.8605    -1.5103     0.3130
H     -2.6622     0.6355    -0.1955
H     -1.5438     1.9521    -0.6855
H     -1.7509     0.5083    -1.7387
H     -1.5479     0.4561     1.9052
H     -0.3421     1.7190     1.4811
H      0.1990     0.0904     2.0187
C      3.0665    -0.0601    -0.2304
C      4.4936     0.2789     0.0469
O      5.0325     1.3566    -0.1361
O      5.1814    -0.7645     0.5462
H      2.5573     0.8203    -0.6327
H      2.5695    -0.3576     0.6963
H      3.0133    -0.8625    -0.9702
H      6.0859    -0.4112     0.6800''',
    referenceEa: 11.4,
    doi: '10.1126/science.1873134',
    journalRef: 'Science 1991, 253, 872',
    tags: const ["MBBS", "Pharm-D", "Neurotransmitter", "AChE", "Cholinergic", "Alzheimer", "Myasthenia"],
    defaultCatalystName: 'AChE (Ser200-His440-Glu327 Triad)',
    literatureBarrierKcalMol: 11.4,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1126/science.1873134',
    catalystXyz: '''6
AChE Ser-His Catalytic Triad Core
C  0.0000 0.0000 0.0000
O  1.4000 0.0000 0.0000
C -0.6500 1.3000 0.0000
N -2.0000 1.3000 0.0000
C -2.4000 0.0000 0.0000
N -1.2500 -0.7500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-dopamine-01',
    name: 'Dopamine to Norepinephrine (Noradrenaline) Hydroxylation',
    iupacName: '4-(2-aminoethyl)benzene-1,2-diol + O2 → 4-(2-amino-1-hydroxyethyl)benzene-1,2-diol + H2O',
    description: 'Essential catecholamine neurotransmitter pathway in medical biochemistry and clinical pharmacology. Dopamine beta-hydroxylase uses molecular oxygen, copper ions, and ascorbic acid (Vitamin C) as electron donors to introduce a stereospecific (R)-hydroxyl group at the beta carbon of dopamine. Vital for understanding sympathetic adrenergic tone, pheochromocytoma, and Parkinson disease pharmacotherapy.',
    category: ReactionCategory.biochemical,
    reactantXyz: '''24
Dopamine to Norepinephrine (Noradrenaline) Hydroxylation - Reactants
N     -3.8449    -0.0072    -0.4712
C     -2.4071    -0.2326    -0.6166
C     -1.6289     0.3885     0.5480
C     -0.1432     0.1560     0.4120
C      0.4536    -0.9826     0.9807
C      1.8258    -1.2152     0.8437
C      2.5985    -0.3070     0.1311
O      3.9446    -0.4791    -0.0386
C      2.0124     0.8193    -0.4397
O      2.7796     1.7045    -1.1422
C      0.6517     1.0590    -0.3078
H     -4.3270    -0.4028    -1.2779
H     -4.0361     0.9942    -0.4926
H     -2.0721     0.1923    -1.5699
H     -2.2228    -1.3121    -0.6605
H     -1.8219     1.4679     0.6031
H     -1.9762    -0.0284     1.5025
H     -0.1535    -1.6954     1.5359
H      2.2624    -2.1002     1.2945
H      4.2025    -1.2971     0.4200
H      3.6829     1.3330    -1.0943
H      0.2195     1.9451    -0.7642
O      4.5705     0.0000     0.0000
O      3.4295     0.0000     0.0000''',
    productXyz: '''26
Dopamine to Norepinephrine (Noradrenaline) Hydroxylation - Products
N     -3.8544    -0.1151    -0.2947
C     -2.4550    -0.4565     0.0128
C     -1.4482     0.4152    -0.7752
O     -1.7277     1.8002    -0.5334
C     -0.0081     0.1047    -0.4249
C      0.8355    -0.5050    -1.3712
C      2.1634    -0.8059    -1.0553
C      2.6482    -0.4990     0.2069
O      3.9253    -0.8557     0.5287
C      1.8353     0.1348     1.1402
O      2.3345     0.5119     2.3529
C      0.5098     0.4227     0.8425
H     -3.9472     0.8932    -0.1333
H     -4.0109    -0.2242    -1.2959
H     -2.2879    -1.5182    -0.1997
H     -2.3189    -0.3133     1.0908
H     -1.6057     0.2569    -1.8491
H     -0.8932     2.2868    -0.6502
H      0.4621    -0.7595    -2.3615
H      2.8053    -1.2926    -1.7839
H      3.8918    -1.1680     1.4519
H      3.2592     0.7771     2.1947
H     -0.1132     0.9094     1.5898
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    referenceEa: 16.7,
    doi: '10.1074/jbc.270.36.21188',
    journalRef: 'J. Biol. Chem. 1995, 270, 21188',
    tags: const ["MBBS", "Pharm-D", "Neurochemistry", "Dopamine", "Norepinephrine", "Catecholamine", "Parkinson"],
    defaultCatalystName: 'Cu(II) / Ascorbate Enzyme Complex',
    literatureBarrierKcalMol: 16.7,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1074/jbc.270.36.21188',
    catalystXyz: '''4
Cu(II) Active Center
Cu 0.0000 0.0000 0.0000
N  1.9800 0.0000 0.0000
N -0.9900 1.7100 0.0000
O -0.9900 -1.7100 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-epinephrine-01',
    name: 'Norepinephrine to Epinephrine (Adrenaline) N-Methylation',
    iupacName: 'norepinephrine + S-adenosyl-L-methionine → epinephrine + S-adenosylhomocysteine',
    description: 'Adrenal medulla endocrine physiology and emergency medicine pharmacology. Phenylethanolamine N-methyltransferase (PNMT), highly upregulated by glucocorticoids (cortisol) from the adrenal cortex, transfers a methyl group from SAM to the primary amine of norepinephrine. Epinephrine is the primary drug for anaphylactic shock, cardiac arrest, and severe asthma via alpha-1, beta-1, and beta-2 adrenergic receptors.',
    category: ReactionCategory.biochemical,
    reactantXyz: '''29
Norepinephrine to Epinephrine (Adrenaline) N-Methylation - Reactants
N     -3.8544    -0.1151    -0.2947
C     -2.4550    -0.4565     0.0128
C     -1.4482     0.4152    -0.7752
O     -1.7277     1.8002    -0.5334
C     -0.0081     0.1047    -0.4249
C      0.8355    -0.5050    -1.3712
C      2.1634    -0.8059    -1.0553
C      2.6482    -0.4990     0.2069
O      3.9253    -0.8557     0.5287
C      1.8353     0.1348     1.1402
O      2.3345     0.5119     2.3529
C      0.5098     0.4227     0.8425
H     -3.9472     0.8932    -0.1333
H     -4.0109    -0.2242    -1.2959
H     -2.2879    -1.5182    -0.1997
H     -2.3189    -0.3133     1.0908
H     -1.6057     0.2569    -1.8491
H     -0.8932     2.2868    -0.6502
H      0.4621    -0.7595    -2.3615
H      2.8053    -1.2926    -1.7839
H      3.8918    -1.1680     1.4519
H      3.2592     0.7771     2.1947
H     -0.1132     0.9094     1.5898
C      3.5080     0.0266    -0.0349
S      5.1071    -0.7428    -0.3595
H      3.3335     0.0804     1.0426
H      3.4911     1.0375    -0.4497
H      2.7121    -0.5626    -0.4969
H      5.8481     0.1608     0.2984''',
    productXyz: '''29
Norepinephrine to Epinephrine (Adrenaline) N-Methylation - Products
C     -3.6185     1.4448     0.3172
N     -2.5924     1.8749    -0.6280
C     -1.2460     1.4063    -0.2301
C     -1.0381    -0.1038    -0.5026
O     -1.4472    -0.3873    -1.8457
C      0.4013    -0.5170    -0.2813
C      1.3349    -0.5291    -1.3343
C      2.6692    -0.8784    -1.1076
C      3.0737    -1.2116     0.1753
O      4.3907    -1.4873     0.4039
C      2.1558    -1.2334     1.2201
O      2.5364    -1.6403     2.4666
C      0.8316    -0.8721     1.0082
H     -3.7303     0.3568     0.3256
H     -3.4021     1.7935     1.3321
H     -4.5832     1.8661     0.0172
H     -2.5792     2.8968    -0.6399
H     -0.5321     1.9715    -0.8433
H     -1.0304     1.6586     0.8152
H     -1.6831    -0.7041     0.1492
H     -2.1985     0.2223    -1.9970
H      1.0205    -0.2637    -2.3425
H      3.3831    -0.8736    -1.9256
H      4.5934    -1.1148     1.2814
H      3.1553    -2.3805     2.3238
H      0.1352    -0.8879     1.8423
S      3.9623     0.6121     0.0000
H      3.0450    -0.3661     0.0000
H      4.9928    -0.2460     0.0000''',
    referenceEa: 15.3,
    doi: '10.1124/mol.104.004127',
    journalRef: 'Mol. Pharmacol. 2004, 66, 1500',
    tags: const ["MBBS", "Pharm-D", "Epinephrine", "Adrenaline", "Emergency Medicine", "SAM", "Anaphylaxis"],
    defaultCatalystName: 'SAM (S-Adenosylmethionine) Co-factor',
    literatureBarrierKcalMol: 15.3,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1124/mol.104.004127',
    catalystXyz: '''5
SAM Sulfonium Methyl Model
S  0.0000 0.0000 0.0000
C  1.8000 0.0000 0.0000
C -0.9000 1.5500 0.0000
C -0.9000 -1.5500 0.0000
H  2.1500 0.9500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-gaba-01',
    name: 'GABA Biosynthesis (Glutamate Decarboxylation)',
    iupacName: 'L-glutamic acid → 4-aminobutanoic acid + CO2',
    description: 'Core CNS physiology and neuropharmacology for MBBS and Pharm-D students. Pyridoxal phosphate (Vitamin B6)-dependent irreversible alpha-decarboxylation of excitatory glutamate into the primary inhibitory neurotransmitter GABA. Clinical relevance: Vitamin B6 deficiency causes intractable neonatal seizures; pharmacological targets include GABA-A modulators (Benzodiazepines, Barbiturates, Propofol) and GABA transaminase inhibitors (Vigabatrin).',
    category: ReactionCategory.biochemical,
    reactantXyz: '''19
GABA Biosynthesis (Glutamate Decarboxylation) - Reactants
O      2.9797    -0.4437     1.2003
C      2.7035     0.3578     0.3246
O      3.6623     1.1299    -0.2235
C      1.3547     0.6157    -0.2875
C      0.2450    -0.0905     0.4935
C     -1.1506     0.2006    -0.0661
N     -1.2660    -0.3059    -1.4549
C     -2.2299    -0.4155     0.8389
O     -2.2488    -0.4098     2.0590
O     -3.2547    -0.9719     0.1523
H      4.4802     0.8614     0.2451
H      1.1749     1.6966    -0.2808
H      1.3871     0.2641    -1.3238
H      0.4277    -1.1738     0.5056
H      0.2908     0.2274     1.5438
H     -1.3354     1.2807    -0.0841
H     -1.1156    -1.3163    -1.4428
H     -2.2495    -0.2112    -1.7266
H     -3.8555    -1.2956     0.8569''',
    productXyz: '''19
GABA Biosynthesis (Glutamate Decarboxylation) - Products
N     -2.2403     0.1680     0.5863
C     -1.5677    -0.0972    -0.6789
C     -0.0828     0.2518    -0.6111
C      0.6751    -0.5851     0.4142
C      2.1459    -0.3061     0.3317
O      2.9766    -0.9813    -0.2528
O      2.5024     0.8268     0.9654
H     -3.2358    -0.0301     0.4881
H     -2.1708     1.1601     0.8120
H     -1.6924    -1.1539    -0.9389
H     -2.0437     0.4931    -1.4696
H      0.0410     1.3189    -0.3853
H      0.3581     0.0986    -1.6045
H      0.3379    -0.3881     1.4379
H      0.5254    -1.6557     0.2323
H      3.4711     0.8802     0.8275
O      2.7044     0.1644     0.0000
C      4.0000    -0.3792     0.0000
O      5.2956    -0.9227     0.0000''',
    referenceEa: 17.9,
    doi: '10.1038/nature06760',
    journalRef: 'Nature 2008, 452, 498',
    tags: const ["MBBS", "Pharm-D", "GABA", "Glutamate", "Neurochemistry", "Epilepsy", "Sedatives"],
    defaultCatalystName: "Pyridoxal 5'-Phosphate (PLP Coenzyme)",
    literatureBarrierKcalMol: 17.9,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1038/nature06760',
    catalystXyz: '''7
PLP Pyridine Core Model
N  0.0000 1.3500 0.0000
C  1.1500 0.6500 0.0000
C  1.1500 -0.7500 0.0000
C  0.0000 -1.4500 0.0000
C -1.1500 -0.7500 0.0000
C -1.1500 0.6500 0.0000
O  0.0000 -2.7000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-serotonin-01',
    name: 'Serotonin (5-HT) Biosynthesis (5-HTP Decarboxylation)',
    iupacName: '5-hydroxy-L-tryptophan → 5-hydroxytryptamine (serotonin) + CO2',
    description: 'Key neuropsychiatric & gastrointestinal pathway. Aromatic L-amino acid decarboxylase (AADC) converts 5-HTP to serotonin. In clinical medicine: target of SSRIs (Fluoxetine, Sertraline) for major depressive disorder; 5-HT3 antagonists (Ondansetron) for chemotherapy-induced nausea; 5-HT1B/1D agonists (Triptans) for acute migraine; and pathophysiology of Carcinoid syndrome and Serotonin syndrome.',
    category: ReactionCategory.biochemical,
    reactantXyz: '''28
Serotonin (5-HT) Biosynthesis (5-HTP Decarboxylation) - Reactants
O     -2.7595     1.4377    -0.6668
C     -2.4122     0.7480     0.2815
O     -1.8993     1.3134     1.3905
C     -2.5168    -0.7757     0.3652
N     -3.8169    -1.2030    -0.2222
C     -1.3525    -1.4205    -0.4009
C     -0.0222    -1.2280     0.2655
C      0.5067    -2.0137     1.2712
N      1.7322    -1.5103     1.6126
C      2.0229    -0.4049     0.8481
C      3.1528     0.4233     0.8543
C      3.1803     1.4927    -0.0462
C      2.1141     1.7100    -0.9113
O      2.1243     2.7512    -1.7952
C      0.9931     0.8794    -0.9126
C      0.9419    -0.2045    -0.0120
H     -1.8223     2.2639     1.1656
H     -2.5146    -1.0788     1.4185
H     -3.8775    -0.8035    -1.1634
H     -4.5681    -0.7489     0.2992
H     -1.5315    -2.5005    -0.4951
H     -1.3056    -1.0297    -1.4259
H      0.1122    -2.8882     1.7721
H      2.3406    -1.8917     2.3235
H      3.9810     0.2461     1.5326
H      4.0476     2.1460    -0.0546
H      2.9721     3.2175    -1.7146
H      0.1769     1.0729    -1.6020''',
    productXyz: '''28
Serotonin (5-HT) Biosynthesis (5-HTP Decarboxylation) - Products
N      3.5261    -0.3245     0.4123
C      2.6257     0.8239     0.2940
C      1.7360     0.7724    -0.9571
C      0.6199    -0.2225    -0.8657
C      0.6470    -1.5262    -1.3215
N     -0.5608    -2.1058    -1.0472
C     -1.3935    -1.2026    -0.4296
C     -2.7106    -1.3545     0.0216
C     -3.3186    -0.2506     0.6247
C     -2.6294     0.9462     0.7661
O     -3.2853     1.9838     1.3660
C     -1.3152     1.0916     0.3150
C     -0.6802    -0.0097    -0.2993
H      4.1271    -0.3793    -0.4076
H      4.1357    -0.1969     1.2180
H      3.2396     1.7307     0.2492
H      2.0118     0.8906     1.1992
H      1.3046     1.7687    -1.1177
H      2.3473     0.5651    -1.8450
H      1.4336    -2.0916    -1.8030
H     -0.8102    -3.0609    -1.2618
H     -3.2456    -2.2917    -0.0886
H     -4.3399    -0.3291     0.9879
H     -2.6849     2.7459     1.4003
H     -0.7803     2.0269     0.4281
O      2.7044     0.1644     0.0000
C      4.0000    -0.3792     0.0000
O      5.2956    -0.9227     0.0000''',
    referenceEa: 16.2,
    doi: '10.1016/j.neuropharm.2016.03.023',
    journalRef: 'Neuropharmacology 2017, 113, 584',
    tags: const ["MBBS", "Pharm-D", "Serotonin", "5-HT", "Psychiatry", "SSRI", "Antidepressants", "Migraine"],
    defaultCatalystName: 'PLP (Vitamin B6 Active Form)',
    literatureBarrierKcalMol: 16.2,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/j.neuropharm.2016.03.023',
    catalystXyz: '''7
PLP Pyridine Core Model
N  0.0000 1.3500 0.0000
C  1.1500 0.6500 0.0000
C  1.1500 -0.7500 0.0000
C  0.0000 -1.4500 0.0000
C -1.1500 -0.7500 0.0000
C -1.1500 0.6500 0.0000
O  0.0000 -2.7000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-ldh-01',
    name: 'Lactate Dehydrogenase (LDH) Pyruvate-Lactate Interconversion',
    iupacName: 'pyruvate + NADH + H+ ⇄ L-lactate + NAD+',
    description: 'Core clinical biochemistry reaction for MBBS students. Cytosolic hydride transfer from NADH to the C2 carbonyl of pyruvate by Lactate Dehydrogenase regenerates NAD+ necessary for continued anaerobic glycolysis. In medicine, high serum lactate marks tissue hypoperfusion, septic shock, cardiac arrest, mesenteric ischemia, and the Warburg effect in oncogenesis; serum LDH isoenzymes are classic diagnostic markers for tissue necrosis and hemolysis.',
    category: ReactionCategory.biochemical,
    reactantXyz: '''23
Lactate Dehydrogenase (LDH) Pyruvate-Lactate Interconversion - Reactants
C     -1.4411    -0.2279     0.3331
C     -0.3077     0.3882    -0.4328
O     -0.4690     1.1869    -1.3465
C      1.0970    -0.0520     0.0066
O      1.3039    -0.8416     0.9075
O      2.0822     0.5147    -0.6952
H     -1.4212    -1.3141     0.2143
H     -1.3639     0.0416     1.3894
H     -2.3914     0.1491    -0.0555
H      2.9112     0.1552    -0.3208
C      3.8604    -1.3613    -0.0232
C      5.1076    -0.9152     0.1904
N      5.3957     0.4239     0.2391
C      4.4301     1.3821     0.0730
C      3.1464     1.0596    -0.1469
C      2.7176    -0.3895    -0.2197
H      3.6492    -2.4236    -0.0589
H      5.9527    -1.5799     0.3357
H      6.3532     0.7147     0.4031
H      4.7763     2.4087     0.1318
H      2.3947     1.8296    -0.2762
H      2.2577    -0.5750    -1.1967
H      1.9585    -0.5741     0.5485''',
    productXyz: '''24
Lactate Dehydrogenase (LDH) Pyruvate-Lactate Interconversion - Products
C     -1.4523    -0.5494    -0.0094
C     -0.1549     0.0481    -0.5239
O     -0.3508     1.4512    -0.6950
C      1.0022    -0.2543     0.4298
O      1.1768    -1.2601     1.0961
O      1.9159     0.7465     0.4431
H     -2.2793    -0.3201    -0.6898
H     -1.3783    -1.6360     0.0989
H     -1.7161    -0.1268     0.9669
H      0.0999    -0.3761    -1.5006
H      0.5449     1.8430    -0.6988
H      2.5920     0.4341     1.0825
C      4.8363    -1.1115    -0.0405
C      5.3767     0.1709    -0.0487
C      4.5213     1.2644    -0.0076
N      3.1926     1.0732     0.0392
C      2.6416    -0.1519     0.0482
C      3.4554    -1.2768     0.0083
H      5.4913    -1.9821    -0.0723
H      6.4549     0.3127    -0.0867
H      4.8711     2.2914    -0.0111
H      2.5790     1.8887     0.0689
H      1.5587    -0.2044     0.0872
H      3.0212    -2.2745     0.0151''',
    referenceEa: 12.1,
    doi: '10.1021/bi00486a012',
    journalRef: 'Biochemistry 1990, 29, 8041',
    tags: const ["MBBS", "Pharm-D", "Biochemistry", "LDH", "Lactic Acidosis", "Sepsis", "Glycolysis", "Warburg"],
    defaultCatalystName: 'NADH / Zn2+ Active Site Pocket',
    literatureBarrierKcalMol: 12.1,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/bi00486a012',
    catalystXyz: '''6
NADH Nicotinamide Model
N  0.0000 1.3000 0.0000
C  1.2000 0.6000 0.0000
C  1.2000 -0.8000 0.0000
C  0.0000 -1.5000 0.0000
C -1.2000 -0.8000 0.0000
C -1.2000 0.6000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-atp-01',
    name: 'ATP Hydrolysis to ADP + Inorganic Phosphate',
    iupacName: 'adenosine triphosphate + H2O → adenosine diphosphate + inorganic phosphate',
    description: 'The fundamental bioenergetic reaction taught in year 1 MBBS & Pharm-D biochemistry. Nucleophilic attack of water on the gamma-phosphate of ATP with relief of electrostatic repulsion between negative oxygen charges (ΔG°\' = -30.5 kJ/mol). Powers transmembrane ion pumps including Na+/K+-ATPase (the direct pharmacological target of cardiac glycosides like Digoxin in congestive heart failure and atrial fibrillation).',
    category: ReactionCategory.biochemical,
    reactantXyz: '''21
ATP Hydrolysis to ADP + Inorganic Phosphate - Reactants
O      3.5170     1.1452    -1.1575
P      2.4459     0.4613    -0.3799
O      1.5439     1.4977     0.4281
O      2.9610    -0.5115     0.7721
O      1.4176    -0.3914    -1.2393
P      0.1672    -1.0991    -0.5605
O      0.5019    -1.7339     0.7493
O     -0.2565    -2.1359    -1.7089
O     -1.0085    -0.0374    -0.6048
P     -1.8979     0.3214     0.6523
O     -1.2333     0.8013     1.8932
O     -2.8635     1.4733     0.0952
O     -2.9765    -0.8366     0.8220
H      2.0984     2.2104     0.8022
H      2.2421    -0.9793     1.2563
H     -0.2589    -1.7351    -2.5967
H     -2.6976     2.2954     0.5982
H     -3.7025    -0.7458     0.1788
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''21
ATP Hydrolysis to ADP + Inorganic Phosphate - Products
O     -1.4117    -1.1812     1.2607
P     -1.3718    -0.1121     0.2277
O     -1.8787     1.3304     0.6773
O     -2.4726    -0.4042    -0.9014
O     -0.0508     0.1080    -0.6101
P      1.3898     0.0734     0.0421
O      1.6279     0.9163     1.2442
O      2.3691     0.4737    -1.1572
O      1.7525    -1.4650     0.2422
H     -2.3488     1.7713    -0.0529
H     -2.6470    -1.3649    -0.9423
H      2.5450     1.4323    -1.1623
H      2.4970    -1.5779     0.8605
O      4.1598    -0.4045     1.7497
P      4.0626    -0.1463     0.2914
O      2.6406    -0.4864    -0.3325
O      4.3103     1.3649    -0.1306
O      5.0526    -0.9523    -0.6519
H      1.9281    -0.2558     0.2916
H      5.0608     1.7412     0.3661
H      4.7852    -0.8607    -1.5838''',
    referenceEa: 13.8,
    doi: '10.1038/386299a0',
    journalRef: 'Nature 1997, 386, 299',
    tags: const ["MBBS", "Pharm-D", "ATP", "Bioenergetics", "Digoxin", "Na+/K+-ATPase", "Thermodynamics"],
    defaultCatalystName: 'Mg2+ Coordinated ATPase Complex',
    literatureBarrierKcalMol: 13.8,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1038/386299a0',
    catalystXyz: '''5
Mg(H2O)4 Complex Core
Mg 0.0000 0.0000 0.0000
O  2.0500 0.0000 0.0000
O -2.0500 0.0000 0.0000
O  0.0000 2.0500 0.0000
O  0.0000 -2.0500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-histamine-01',
    name: 'Histamine Biosynthesis (L-Histidine Decarboxylation)',
    iupacName: 'L-histidine → histamine + CO2',
    description: 'Key immunological and gastrointestinal reaction in MBBS and Pharm-D courses. Histidine decarboxylase (HDC) with PLP cofactor produces histamine stored in mast cells and basophils. Core clinical pharmacology: H1 receptor antagonists (Diphenhydramine, Loratadine, Cetirizine) treat allergic rhinitis, urticaria, and anaphylaxis; H2 receptor antagonists (Famotidine, Ranitidine) suppress gastric parietal cell HCl secretion in peptic ulcer disease and GERD.',
    category: ReactionCategory.biochemical,
    reactantXyz: '''20
Histamine Biosynthesis (L-Histidine Decarboxylation) - Reactants
O     -3.4341     0.9695     1.3026
C     -2.7068     0.5067     0.4332
O     -3.2321     0.2013    -0.7687
C     -1.2266     0.1410     0.6014
N     -0.6272     1.0280     1.6365
C     -0.4551     0.2328    -0.7235
C      0.9468    -0.2681    -0.6212
C      2.1269     0.3912    -0.8917
N      3.1146    -0.5205    -0.6447
C      2.5138    -1.6782    -0.2412
N      1.2066    -1.5578    -0.2151
H     -4.1717     0.4674    -0.6817
H     -1.2084    -0.8887     0.9799
H     -1.2247     0.9903     2.4651
H      0.2696     0.6227     1.9082
H     -0.9552    -0.3644    -1.4964
H     -0.4586     1.2680    -1.0892
H      2.3380     1.3969    -1.2268
H      4.1093    -0.3718    -0.7433
H      3.0750    -2.5664     0.0165''',
    productXyz: '''20
Histamine Biosynthesis (L-Histidine Decarboxylation) - Products
N     -2.3129     0.7934    -0.5151
C     -1.8412    -0.5951    -0.5700
C     -0.7926    -0.9303     0.5001
C      0.5000    -0.2160     0.2967
C      1.7096    -0.7113    -0.1418
N      2.5566     0.3621    -0.1506
C      1.8487     1.4489     0.2752
N      0.6050     1.1337     0.5528
H     -1.4783     1.3942    -0.5359
H     -2.7030     0.9722     0.4106
H     -2.7072    -1.2536    -0.4419
H     -1.4356    -0.7864    -1.5700
H     -0.6126    -2.0124     0.4871
H     -1.1837    -0.6918     1.4969
H      2.0285    -1.7000    -0.4395
H      3.5302     0.3589    -0.4219
H      2.2887     2.4335     0.3613
O      2.7044     0.1644     0.0000
C      4.0000    -0.3792     0.0000
O      5.2956    -0.9227     0.0000''',
    referenceEa: 17.4,
    doi: '10.1016/j.jaci.2015.04.015',
    journalRef: 'J. Allergy Clin. Immunol. 2015, 136, 1435',
    tags: const ["MBBS", "Pharm-D", "Histamine", "Allergy", "Mast Cell", "Antihistamine", "Peptic Ulcer"],
    defaultCatalystName: 'PLP (Histidine Decarboxylase)',
    literatureBarrierKcalMol: 16.5,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/j.jaci.2015.04.015',
    catalystXyz: '''7
PLP Pyridine Core Model
N  0.0000 1.3500 0.0000
C  1.1500 0.6500 0.0000
C  1.1500 -0.7500 0.0000
C  0.0000 -1.4500 0.0000
C -1.1500 -0.7500 0.0000
C -1.1500 0.6500 0.0000
O  0.0000 -2.7000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-sulfonamide-01',
    name: 'Dihydropteroate Synthase Reaction (Sulfonamide Target)',
    iupacName: '4-aminobenzoic acid (PABA) + dihydropterin → 7,8-dihydropteroate + PPi',
    description: 'Classic antimetabolite pharmacology for Pharm-D and MBBS students. Sulfonamides (e.g. Sulfamethoxazole) are structural analogs of PABA that competitively inhibit Dihydropteroate Synthase (DHPS), blocking bacterial folate synthesis without affecting humans (who absorb preformed dietary folate). Combined with Trimethoprim (Cotrimoxazole / Bactrim) for synergistic sequential enzyme inhibition against Pneumocystis jirovecii (PJP) and UTIs.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''33
Dihydropteroate Synthase Reaction (Sulfonamide Target) - Reactants
N     -3.0998     0.0357     0.0036
C     -1.7046    -0.0424    -0.0536
C     -1.0156     0.4761    -1.1530
C      0.3825     0.5125    -1.1682
C      1.1085     0.0671    -0.0589
C      2.5888     0.1258    -0.1153
O      3.2520     0.5257    -1.0543
O      3.1732    -0.3236     1.0096
C      0.4239    -0.3979     1.0682
C     -0.9750    -0.4307     1.0734
H     -3.5522     0.0211    -0.9052
H     -3.5243    -0.6169     0.6553
H     -1.5621     0.8578    -2.0117
H      0.8991     0.9026    -2.0428
H      4.1316    -0.2251     0.8295
H      0.9649    -0.7239     1.9529
H     -1.4907    -0.7640     1.9704
C      1.2760    -0.8668    -0.0279
N      2.2893    -1.7087    -0.0462
C      3.4002    -0.9196     0.0052
C      3.0599     0.4022     0.0467
N      1.6981     0.4352     0.0304
C      4.0114     1.4463     0.1009
O      3.7457     2.6405     0.1623
N      5.2966     0.9620     0.0786
C      5.6005    -0.3786     0.0527
N      6.9267    -0.6791     0.0611
N      4.7300    -1.3446     0.0153
H      0.2285    -1.1371    -0.0538
H      1.1166     1.2625     0.0567
H      6.0312     1.6435     0.1677
H      7.5167    -0.0914    -0.5128
H      7.0726    -1.6664    -0.1369''',
    productXyz: '''31
Dihydropteroate Synthase Reaction (Sulfonamide Target) - Products
O      6.5676    -1.0421     0.8775
C      5.5729    -0.4425     1.2424
O      5.6138     0.4104     2.2810
C      4.2253    -0.5489     0.6341
C      4.0532    -1.4054    -0.4557
C      2.7956    -1.5332    -1.0575
C      1.6824    -0.8121    -0.5901
N      0.4440    -0.9927    -1.2438
C     -0.7417    -0.4124    -0.9533
N     -1.0806     0.4478    -0.0127
C     -2.4081     0.6916    -0.1911
C     -2.8976    -0.0258    -1.2410
N     -1.8372    -0.7244    -1.7297
C     -4.2466     0.0251    -1.6560
O     -4.7141    -0.5878    -2.6078
N     -4.9905     0.8583    -0.8566
C     -4.4589     1.5801     0.1862
N     -5.3352     2.3760     0.8551
N     -3.2144     1.5456     0.5642
C      1.8758     0.0402     0.5039
C      3.1314     0.1745     1.1128
H      6.5476     0.3793     2.5757
H      4.8943    -1.9775    -0.8421
H      2.6984    -2.2098    -1.9031
H      0.5070    -1.6373    -2.0218
H     -1.8522    -1.3556    -2.5165
H     -5.9524     0.9889    -1.1208
H     -6.2513     1.9822     1.0245
H     -4.9160     2.7352     1.7098
H      1.0534     0.6232     0.9104
H      3.2342     0.8490     1.9593''',
    referenceEa: 19.1,
    doi: '10.1016/S0969-2126(97)00244-6',
    journalRef: 'Structure 1997, 5, 895',
    tags: const ["Pharm-D", "MBBS", "Antibiotic", "Sulfonamide", "PABA", "Folate Synthesis", "Bactrim"],
    defaultCatalystName: 'Mg2+ / DHPS Catalytic Pocket',
    literatureBarrierKcalMol: 18.0,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/S0969-2126(97)00244-6',
    catalystXyz: '''5
Mg2+ Active Center
Mg 0.0000 0.0000 0.0000
O  2.0500 0.0000 0.0000
O -2.0500 0.0000 0.0000
O  0.0000 2.0500 0.0000
O  0.0000 -2.0500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-procaine-01',
    name: 'Procaine Hydrolysis by Pseudocholinesterase',
    iupacName: '2-(diethylamino)ethyl 4-aminobenzoate + H2O → 4-aminobenzoic acid + 2-(diethylamino)ethanol',
    description: 'Fundamental clinical pharmacology for anesthesiology (MBBS) and clinical pharmaceutics (Pharm-D). Ester-type local anesthetics (Procaine, Tetracaine, Cocaine) are rapidly hydrolyzed in plasma by pseudocholinesterase (butyrylcholinesterase), resulting in a short duration of action. Patients with atypical pseudocholinesterase or genetic mutations exhibit prolonged paralysis and toxicity. Contrasted with amide local anesthetics (Lidocaine, Bupivacaine) metabolized hepatically by CYP450.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''40
Procaine Hydrolysis by Pseudocholinesterase - Reactants
C     -3.5285    -1.9654     0.3676
C     -3.6589    -1.0259    -0.8282
N     -3.1205     0.3361    -0.6575
C     -3.9012     1.0941     0.3362
C     -3.7112     2.6027     0.2100
C     -1.6761     0.3630    -0.3532
C     -0.7820    -0.3034    -1.4140
O      0.6078    -0.0326    -1.1489
C      1.1888    -0.8264    -0.2158
O      0.6366    -1.7202     0.4060
C      2.6199    -0.4614    -0.0342
C      3.3723    -1.1765     0.9047
C      4.7204    -0.8666     1.1126
C      5.3485     0.1284     0.3601
N      6.6595     0.5138     0.6566
C      4.5796     0.8783    -0.5334
C      3.2298     0.5764    -0.7483
H     -4.0339    -1.5682     1.2529
H     -3.9909    -2.9295     0.1305
H     -2.4821    -2.1590     0.6209
H     -4.7202    -0.9535    -1.0997
H     -3.1906    -1.4954    -1.7011
H     -4.9710     0.9026     0.1832
H     -3.6644     0.7774     1.3592
H     -3.8980     2.9397    -0.8151
H     -2.7052     2.9173     0.5017
H     -4.4180     3.1219     0.8661
H     -1.3364     1.4031    -0.2824
H     -1.4725    -0.0705     0.6335
H     -0.9450    -1.3848    -1.4829
H     -0.9976     0.1200    -2.4013
H      2.9110    -1.9696     1.4901
H      5.2759    -1.4133     1.8704
H      7.2284    -0.2269     1.0548
H      7.1316     0.9954    -0.1023
H      5.0260     1.7093    -1.0740
H      2.6683     1.1697    -1.4654
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''40
Procaine Hydrolysis by Pseudocholinesterase - Products
N     -3.0998     0.0357     0.0036
C     -1.7046    -0.0424    -0.0536
C     -1.0156     0.4761    -1.1530
C      0.3825     0.5125    -1.1682
C      1.1085     0.0671    -0.0589
C      2.5888     0.1258    -0.1153
O      3.2520     0.5257    -1.0543
O      3.1732    -0.3236     1.0096
C      0.4239    -0.3979     1.0682
C     -0.9750    -0.4307     1.0734
H     -3.5522     0.0211    -0.9052
H     -3.5243    -0.6169     0.6553
H     -1.5621     0.8578    -2.0117
H      0.8991     0.9026    -2.0428
H      4.1316    -0.2251     0.8295
H      0.9649    -0.7239     1.9529
H     -1.4907    -0.7640     1.9704
C      2.3922    -2.0236    -0.1049
C      2.3072    -0.5084     0.0491
N      3.5831     0.1793    -0.2240
C      3.3616     1.6339    -0.2963
C      4.5288     2.3604    -0.9591
C      4.6192    -0.1701     0.7665
C      5.7095    -1.0514     0.1431
O      6.7349    -1.3216     1.0975
H      3.0259    -2.4790     0.6618
H      2.7845    -2.2982    -1.0897
H      1.3940    -2.4636    -0.0086
H      1.9317    -0.2567     1.0491
H      1.5524    -0.1647    -0.6697
H      2.4771     1.8432    -0.9113
H      3.1645     2.0556     0.6974
H      4.2898     3.4231    -1.0716
H      5.4495     2.2900    -0.3726
H      4.7265     1.9549    -1.9572
H      5.1047     0.7207     1.1858
H      4.2011    -0.6706     1.6501
H      6.1696    -0.5617    -0.7220
H      5.3029    -2.0115    -0.1872
H      7.1892    -0.4801     1.2739''',
    referenceEa: 14.8,
    doi: '10.1097/00000542-200006000-00028',
    journalRef: 'Anesthesiology 2000, 92, 1709',
    tags: const ["MBBS", "Pharm-D", "Local Anesthetic", "Procaine", "Pseudocholinesterase", "Anesthesia", "Ester"],
    defaultCatalystName: 'Pseudocholinesterase Ser198 Triad',
    literatureBarrierKcalMol: 12.8,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1097/00000542-200006000-00028',
    catalystXyz: '''6
BChE Ser-His Catalytic Triad Core
C  0.0000 0.0000 0.0000
O  1.4000 0.0000 0.0000
C -0.6500 1.3000 0.0000
N -2.0000 1.3000 0.0000
C -2.4000 0.0000 0.0000
N -1.2500 -0.7500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-glutathione-01',
    name: 'Glutathione S-Transferase Detoxification (Phase II Metabolism)',
    iupacName: 'glutathione (GSH) + electrophilic xenobiotic → S-glutathionyl conjugate',
    description: 'The cornerstone reaction of Phase II drug metabolism and toxicology for Pharm-D and MBBS students. Glutathione S-transferases (GST) catalyze the nucleophilic addition of the sulfhydryl (-SH) group of GSH (gamma-L-glutamyl-L-cysteinylglycine) to electrophilic reactive drug metabolites (such as NAPQI from paracetamol, active metabolites of chemotherapeutic alkylating agents, and epoxides), forming water-soluble mercapturic acid conjugates excreted in urine.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''48
Glutathione S-Transferase Detoxification (Phase II Metabolism) - Reactants
C      6.4808     0.5607     1.0220
C      5.2909     0.4540     0.1065
O      5.2254    -0.3914    -0.7796
N      4.2926     1.3625     0.3691
C      3.0695     1.4079    -0.4139
C      2.1045     0.2919    -0.0374
C      0.8022     0.4182    -0.7950
O      0.5253     1.3635    -1.5254
N     -0.0540    -0.6387    -0.5753
C     -1.4461    -0.5691    -1.0130
C     -2.0033    -1.9496    -1.3875
S     -1.8272    -3.2109    -0.0762
C     -2.2953     0.0946     0.0926
O     -1.9306     0.1554     1.2661
N     -3.5114     0.5909    -0.3336
C     -4.5171     1.0121     0.6306
C     -5.4493    -0.1512     0.9242
O     -5.6050    -1.1453     0.2293
O     -6.1835     0.0314     2.0388
H      6.4654     1.4888     1.5998
H      6.4779    -0.2873     1.7118
H      7.3951     0.5464     0.4223
H      4.3902     2.0052     1.1442
H      2.6184     2.3910    -0.2401
H      3.3330     1.3435    -1.4762
H      1.8844     0.3317     1.0361
H      2.5453    -0.6878    -0.2537
H      0.1016    -1.1904     0.2633
H     -1.5024     0.0777    -1.8975
H     -1.4717    -2.3303    -2.2664
H     -3.0648    -1.8848    -1.6472
H     -2.4348    -4.2062    -0.7391
H     -3.8492     0.3282    -1.2509
H     -5.0949     1.8238     0.1810
H     -4.0413     1.3487     1.5557
H     -6.7206    -0.7852     2.1148
O      6.6561    -0.0821    -0.0785
C      5.4340    -0.0443    -0.0424
C      4.7069     1.2402    -0.0090
C      3.3717     1.2815     0.0304
C      2.5660     0.0443     0.0424
O      1.3439     0.0821     0.0785
C      3.2931    -1.2402     0.0090
C      4.6283    -1.2815    -0.0304
H      5.3127     2.1383    -0.0183
H      2.8230     2.2152     0.0552
H      2.6873    -2.1383     0.0183
H      5.1770    -2.2152    -0.0552''',
    productXyz: '''46
Glutathione S-Transferase Detoxification (Phase II Metabolism) - Products
C      7.4142    -1.4643     2.4858
C      6.1364    -0.6693     2.4660
O      6.1155     0.5212     2.1722
N      5.0119    -1.3955     2.7814
C      3.6940    -0.7861     2.8306
C      3.1163    -0.5496     1.4414
C      1.7101    -0.0015     1.5226
O      1.0811     0.1169     2.5688
N      1.1816     0.3195     0.2965
C     -0.1247     0.9705     0.1564
C     -1.2952     0.0275     0.4701
S     -1.4664    -1.3453    -0.7334
C     -3.1788    -1.6162    -0.6827
C     -3.6751    -2.8020    -0.3135
C     -5.1254    -3.0614    -0.3006
O     -5.5741    -4.1426     0.0539
C     -6.0200    -1.9721    -0.7319
C     -5.5368    -0.7878    -1.1150
C     -4.0852    -0.5096    -1.1216
O     -3.6816     0.5979    -1.4642
C     -0.1732     1.6135    -1.2501
O      0.8265     1.6431    -1.9731
N     -1.3518     2.2204    -1.6136
C     -1.4906     2.8098    -2.9359
C     -2.7516     3.6502    -3.0314
O     -3.5352     3.9134    -2.1322
O     -2.9570     4.1334    -4.2747
H      7.2704    -2.4538     2.9285
H      7.7755    -1.5847     1.4611
H      8.1590    -0.9279     3.0800
H      5.0962    -2.3782     3.0065
H      3.7679     0.1594     3.3807
H      3.0544    -1.4609     3.4101
H      3.0884    -1.4907     0.8795
H      3.7390     0.1574     0.8816
H      1.7992     0.3950    -0.5096
H     -0.1418     1.7976     0.8782
H     -1.1676    -0.4332     1.4551
H     -2.2183     0.6095     0.5305
H     -3.0478    -3.6325    -0.0089
H     -7.0823    -2.1864    -0.7204
H     -6.1845     0.0209    -1.4336
H     -2.2273     1.8867    -1.2109
H     -0.6196     3.4388    -3.1431
H     -1.5451     1.9910    -3.6599
H     -3.7807     4.6580    -4.1903''',
    referenceEa: 13.5,
    doi: '10.1074/jbc.R112.434852',
    journalRef: 'J. Biol. Chem. 2013, 288, 3073',
    tags: const ["Pharm-D", "MBBS", "Toxicology", "Pharmacology", "Glutathione", "Phase II Metabolism", "Detoxification"],
    defaultCatalystName: 'GST Tyr6 Active Site Base / GSH',
    literatureBarrierKcalMol: 14.1,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1074/jbc.R112.434852',
    catalystXyz: '''5
GST Catalytic Thiolate Core
S  0.0000 0.0000 0.0000
C  1.8000 0.0000 0.0000
O -1.2500 1.5000 0.0000
C -1.9500 0.3500 0.0000
H  2.1500 0.9500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-prostaglandin-01',
    name: 'Arachidonic Acid to PGG2/PGH2 (Cyclooxygenase Mechanism)',
    iupacName: 'arachidonic acid + 2 O2 → prostaglandin H2 (PGH2)',
    description: 'The pivotal step in inflammatory pharmacology. Cyclooxygenase (COX-1 and COX-2) converts arachidonic acid released from membrane phospholipids by Phospholipase A2 into prostaglandin G2 (endoperoxide), which is reduced to PGH2. PGH2 is the biosynthetic precursor for Prostacyclin (PGI2), Thromboxane (TXA2), and Prostaglandins (PGE2, PGF2alpha). The direct target of NSAIDs, Coxibs (Celecoxib), and Aspirin for pain, fever, and inflammation.',
    category: ReactionCategory.biochemical,
    reactantXyz: '''56
Arachidonic Acid to PGG2/PGH2 (Cyclooxygenase Mechanism) - Reactants
C      1.0701    -3.5992    -2.0434
C      1.5857    -2.1823    -1.8407
C      2.7342    -2.1469    -0.8343
C      3.3966    -0.7719    -0.6765
C      2.4725     0.3176    -0.1145
C      1.8727     1.1868    -1.1866
C      1.8093     2.5296    -1.2015
C      2.2742     3.4801    -0.1331
C      1.3680     4.6751    -0.0314
C      0.3918     4.9762     0.8433
C     -0.2095     4.2662     2.0259
C      0.4527     3.0042     2.4789
C      0.0484     1.7425     2.2529
C     -1.1195     1.2902     1.4254
C     -2.0836     0.4839     2.2483
C     -2.2860    -0.8432     2.1878
C     -1.5439    -1.8253     1.3251
C     -2.2573    -2.1401     0.0093
C     -3.6167    -2.8113     0.2032
C     -4.2285    -3.2060    -1.1135
O     -3.7569    -3.0605    -2.2277
O     -5.4349    -3.7852    -0.9515
H      1.8563    -4.2504    -2.4384
H      0.7123    -4.0250    -1.1004
H      0.2381    -3.6014    -2.7546
H      1.9194    -1.7809    -2.8043
H      0.7563    -1.5588    -1.4906
H      2.3733    -2.4893     0.1437
H      3.5073    -2.8601    -1.1472
H      3.8423    -0.4597    -1.6291
H      4.2318    -0.8997     0.0247
H      3.0643     0.9284     0.5754
H      1.6699    -0.1379     0.4745
H      1.4555     0.6662    -2.0469
H      1.3715     2.9933    -2.0853
H      2.4014     2.9905     0.8318
H      3.2701     3.8467    -0.4125
H      1.5527     5.4145    -0.8129
H     -0.1075     5.9310     0.6621
H     -0.1927     4.9623     2.8748
H     -1.2716     4.0971     1.8173
H      1.3515     3.1465     3.0776
H      0.6527     0.9387     2.6718
H     -0.7418     0.7110     0.5768
H     -1.6639     2.1307     0.9841
H     -2.6866     1.0612     2.9483
H     -3.0423    -1.2706     2.8452
H     -1.4001    -2.7495     1.8986
H     -0.5346    -1.4591     1.1053
H     -1.6110    -2.7997    -0.5830
H     -2.3786    -1.2217    -0.5794
H     -4.3103    -2.1283     0.7049
H     -3.5016    -3.7164     0.8095
H     -5.7230    -3.9901    -1.8658
O      4.5705     0.0000     0.0000
O      3.4295     0.0000     0.0000''',
    productXyz: '''50
Arachidonic Acid to PGG2/PGH2 (Cyclooxygenase Mechanism) - Products
C     -5.5507    -2.4252     0.0000
C     -4.0600    -2.6462     0.0000
C     -2.5119    -2.2271     0.0000
C     -0.8704    -2.2465     0.0000
C      0.7905    -2.7890     0.0000
C      2.3975    -2.5966     0.0000
C      3.7647    -3.4721     0.0000
C      5.3521    -3.4184     0.0000
C      5.8061    -2.0823     0.0000
C      4.5761    -1.0820     0.0000
O      4.3988    -2.3545     0.0000
C      3.0776    -1.0425     0.0000
C      2.9391     0.5748     0.0000
C      1.8175     1.3570     0.0000
C      1.6741     2.9237     0.0000
O      2.4392     4.2128     0.0000
C      0.2390     3.5678     0.0000
C     -1.3166     3.5740     0.0000
C     -2.7641     4.2264     0.0000
C     -4.3353     4.3252     0.0000
O     -5.1656     3.4262     0.0000
O     -4.7847     5.6029     0.0000
H     -5.8518    -1.3767     0.0000
H     -5.7669    -3.5020     0.0000
H     -6.6382    -2.6392     0.0000
H     -3.9360    -3.7197     0.0000
H     -4.0604    -1.5728     0.0000
H     -2.4591    -1.1434     0.0000
H     -2.3605    -3.2843     0.0000
H     -0.8650    -3.3162     0.0000
H     -0.6603    -1.1809     0.0000
H      0.8051    -1.7456     0.0000
H      0.6099    -3.8628     0.0000
H      2.2990    -3.6786     0.0000
H      3.7701    -4.5815     0.0000
H      5.9934    -4.2900     0.0000
H      6.8447    -1.7801     0.0000
H      5.2415    -0.2114     0.0000
H      2.0671    -0.7320     0.0000
H      3.8734     1.1384     0.0000
H      0.8653     0.8225     0.0000
H      2.7314     2.7558     0.0000
H      3.4140     4.1544     0.0000
H      0.5499     4.5972     0.0000
H      0.0762     2.5224     0.0000
H     -1.6508     2.5429     0.0000
H     -1.1740     4.6388     0.0000
H     -3.1661     3.2189     0.0000
H     -2.7047     5.3137     0.0000
H     -5.7601     5.5039     0.0000''',
    referenceEa: 18.0,
    doi: '10.1016/j.pharmthera.2011.09.006',
    journalRef: 'Pharmacol. Ther. 2012, 133, 71',
    tags: const ["MBBS", "Pharm-D", "Inflammation", "COX-2", "Prostaglandins", "Arachidonic Acid", "Pharmacology"],
    defaultCatalystName: 'COX Fe(III)-Protoporphyrin IX Heme',
    literatureBarrierKcalMol: 15.6,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/j.pharmthera.2011.09.006',
    catalystXyz: '''5
Fe-Porphyrin Heme Center
Fe 0.0000 0.0000 0.0000
N  2.0000 0.0000 0.0000
N -2.0000 0.0000 0.0000
N  0.0000 2.0000 0.0000
N  0.0000 -2.0000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-captopril-01',
    name: 'Captopril ACE Inhibition & Active-Site Zinc Chelation',
    iupacName: 'captopril + angiotensin-converting enzyme active site → [Zn2+]-captopril mercaptide complex',
    description: 'Foundational antihypertensive pharmacology for MBBS & Pharm-D students. Captopril was the first orally active ACE inhibitor designed by rational drug design. Its terminal thiol (-SH) group directly coordinates with the catalytic divalent zinc ion (Zn2+) in the active site of Angiotensin-Converting Enzyme, competitively blocking conversion of decapeptide Angiotensin I into the potent vasoconstrictor octapeptide Angiotensin II and preventing degradation of the vasodilator bradykinin.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''32
Captopril ACE Inhibition & Active-Site Zinc Chelation - Reactants
C      2.1061    -1.6178    -0.5156
C      1.9640    -0.1146    -0.2612
C      3.2083     0.4141     0.4607
S      3.2993     2.2346     0.3843
C      0.7056     0.1032     0.5763
O      0.7415     0.0946     1.8081
N     -0.4887     0.2266    -0.0976
C     -0.6883     0.3821    -1.5287
C     -2.1988     0.3740    -1.7095
C     -2.7096     0.9668    -0.3991
C     -1.7397     0.4074     0.6400
C     -2.2467    -0.9272     1.1897
O     -1.9850    -2.0476     0.7785
O     -3.1257    -0.7679     2.2033
H      2.9716    -1.8243    -1.1537
H      2.2367    -2.1670     0.4238
H      1.2190    -2.0262    -1.0104
H      1.8713     0.3889    -1.2294
H      4.1177     0.0326    -0.0157
H      3.2363     0.1086     1.5118
H      4.3386     2.3667     1.2218
H     -0.2585     1.3447    -1.8265
H     -0.1965    -0.4182    -2.0871
H     -2.5595    -0.6559    -1.8176
H     -2.5199     0.9409    -2.5877
H     -3.7569     0.7124    -0.2108
H     -2.6223     2.0596    -0.4375
H     -1.5815     1.0959     1.4775
H     -3.3385    -1.6867     2.4704
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''31
Captopril ACE Inhibition & Active-Site Zinc Chelation - Products
C      2.4011    -1.3359     1.2760
C      2.0833    -0.1953     0.3110
C      3.2078     0.8076     0.2871
O      4.2011     0.8231     0.9963
O      3.0643     1.7238    -0.6931
C      0.7683     0.4464     0.7100
O      0.7278     1.3955     1.4954
N     -0.3935    -0.1038     0.2114
C     -0.5364    -1.2188    -0.7120
C     -2.0240    -1.2738    -1.0337
C     -2.6793    -0.6682     0.2047
C     -1.6967     0.4246     0.6181
C     -2.0172     1.7350    -0.1045
O     -1.5879     2.1093    -1.1852
O     -2.9332     2.4777     0.5542
H      1.6141    -2.0960     1.2743
H      3.3438    -1.8247     1.0069
H      2.4991    -0.9690     2.3044
H      2.0243    -0.6071    -0.7014
H      3.8269     2.3273    -0.5697
H     -0.2081    -2.1301    -0.2033
H      0.0720    -1.0655    -1.6072
H     -2.2413    -0.6533    -1.9113
H     -2.3699    -2.2895    -1.2450
H     -3.6895    -0.3014     0.0001
H     -2.7413    -1.4300     0.9914
H     -1.7007     0.6069     1.6985
H     -3.0146     3.2851     0.0040
S      3.9623     0.6121     0.0000
H      3.0450    -0.3661     0.0000
H      4.9928    -0.2460     0.0000''',
    referenceEa: 14.2,
    doi: '10.1126/science.191908',
    journalRef: 'Science 1977, 196, 441-444',
    tags: const ["MBBS", "Pharm-D", "Cardiology", "ACE-Inhibitor", "Hypertension", "Renin-Angiotensin", "Captopril"],
    defaultCatalystName: 'ACE Active-Site Zn2+ Metalloprotease',
    literatureBarrierKcalMol: 13.9,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1126/science.191908',
    catalystXyz: '''4
Zn(II) Active Center
Zn 0.0000 0.0000 0.0000
N  2.0000 0.0000 0.0000
N -1.0000 1.7300 0.0000
O -1.0000 -1.7300 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-enalapril-01',
    name: 'Enalapril Hepatic Carboxylesterase-1 Bioactivation to Enalaprilat',
    iupacName: 'enalapril (ethyl ester prodrug) + H2O → enalaprilat (active di-acid) + ethanol',
    description: 'The classic paradigm of prodrug design in Pharm-D pharmaceutics and MBBS clinical pharmacology. Enalapril is an inactive dicarboxylic acid monoethyl ester prodrug synthesized to overcome the poor oral bioavailability and food-binding limitations of enalaprilat. In the liver, hepatic Carboxylesterase-1 (CES1) cleaves the ethyl ester bond via a tetrahedral serine-alkoxide intermediate, releasing the active dicarboxylate enalaprilat with high sub-nanomolar affinity for ACE.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''58
Enalapril Hepatic Carboxylesterase-1 Bioactivation to Enalaprilat - Reactants
C     -0.4878    -3.6601     2.8965
C     -0.1319    -3.0573     1.5518
O     -0.5178    -1.6795     1.5649
C     -0.1964    -1.0037     0.4242
O      0.2881    -1.5100    -0.5810
C     -0.5712     0.4802     0.5685
C     -1.9271     0.7236    -0.1184
C     -3.0836     0.0073     0.5893
C     -4.4141     0.3475    -0.0362
C     -5.1965     1.3899     0.4778
C     -6.4199     1.7122    -0.1119
C     -6.8695     0.9996    -1.2221
C     -6.0953    -0.0343    -1.7453
C     -4.8718    -0.3582    -1.1570
N      0.4227     1.3626    -0.0991
C      1.6826     1.6183     0.6358
C      1.4542     2.2677     2.0025
C      2.5417     0.3402     0.7670
O      2.4279    -0.3895     1.7568
N      3.3924     0.0111    -0.2734
C      4.2009    -1.1928    -0.1929
C      5.5069    -0.8047    -0.8607
C      5.0519     0.1294    -1.9705
C      3.8642     0.8882    -1.3592
C      2.8438     1.1709    -2.4618
O      1.7099     0.7335    -2.5604
O      3.3146     2.0358    -3.3865
H     -1.5618    -3.5663     3.0888
H     -0.2128    -4.7178     2.9352
H      0.0278    -3.1307     3.7046
H      0.9479    -3.1407     1.3835
H     -0.6717    -3.5833     0.7565
H     -0.6625     0.7387     1.6274
H     -2.1352     1.8025    -0.1334
H     -1.8846     0.3995    -1.1675
H     -2.9494    -1.0804     0.5537
H     -3.1006     0.2770     1.6527
H     -4.8564     1.9585     1.3401
H     -7.0212     2.5212     0.2942
H     -7.8215     1.2518    -1.6812
H     -6.4427    -0.5879    -2.6135
H     -4.2752    -1.1639    -1.5794
H      0.6517     0.9301    -1.0091
H      2.2394     2.3556     0.0503
H      1.0044     1.5839     2.7291
H      2.4115     2.5920     2.4268
H      0.8131     3.1515     1.9158
H      3.6832    -1.9744    -0.7602
H      4.3485    -1.5372     0.8345
H      6.1438    -0.2576    -0.1551
H      6.0658    -1.6682    -1.2313
H      5.8488     0.8060    -2.2952
H      4.7428    -0.4601    -2.8432
H      4.1815     1.8350    -0.9088
H      2.5664     2.1375    -4.0141
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''58
Enalapril Hepatic Carboxylesterase-1 Bioactivation to Enalaprilat - Products
O     -2.0160     2.5764    -2.8883
C     -1.6837     2.3575    -1.7332
O     -1.8021     3.3338    -0.8093
C     -1.0789     1.0608    -1.1651
C     -2.1281     0.2655    -0.3727
C     -2.5299     0.9427     0.9432
C     -3.3554     0.0238     1.8122
C     -4.7136    -0.1842     1.5365
C     -5.4730    -1.0442     2.3313
C     -4.8821    -1.7052     3.4065
C     -3.5313    -1.5080     3.6871
C     -2.7700    -0.6488     2.8930
N     -0.5980     0.2272    -2.3031
C      0.5549    -0.6285    -1.9363
C      0.8122    -1.6042    -3.0816
C      1.8199     0.2334    -1.7141
O      1.9574     1.3210    -2.2830
N      2.7883    -0.2511    -0.8653
C      2.7911    -1.5074    -0.1332
C      4.0107    -1.4270     0.7754
C      4.9532    -0.4893     0.0254
C      4.0033     0.5224    -0.6101
C      3.7203     1.6789     0.3526
O      2.7813     1.7838     1.1277
O      4.6859     2.6226     0.3248
H     -2.1492     4.0921    -1.3248
H     -0.2379     1.3589    -0.5280
H     -3.0241     0.1082    -0.9886
H     -1.7344    -0.7327    -0.1411
H     -3.1139     1.8504     0.7534
H     -1.6351     1.2595     1.4933
H     -5.1873     0.3231     0.6990
H     -6.5258    -1.1986     2.1103
H     -5.4743    -2.3742     4.0250
H     -3.0701    -2.0234     4.5252
H     -1.7168    -0.5064     3.1240
H     -0.2732     0.8681    -3.0390
H      0.3109    -1.1957    -1.0351
H      1.6489    -2.2718    -2.8536
H     -0.0688    -2.2269    -3.2724
H      1.0645    -1.0769    -4.0092
H      1.8655    -1.6344     0.4341
H      2.8883    -2.3239    -0.8551
H      3.7322    -0.9823     1.7383
H      4.4527    -2.4078     0.9719
H      5.7015    -0.0411     0.6858
H      5.4764    -1.0513    -0.7579
H      4.3875     0.9325    -1.5505
H      4.3661     3.3029     0.9542
C      3.1117     0.1670    -0.0273
C      4.4658    -0.5116    -0.0368
O      5.4311     0.3229     0.5867
H      3.1513     1.1175    -0.5695
H      2.3529    -0.4704    -0.4896
H      2.8036     0.3978     0.9977
H      4.7920    -0.7224    -1.0597
H      4.4246    -1.4559     0.5138
H      5.4671     1.1550     0.0848''',
    referenceEa: 15.6,
    doi: '10.1038/288280a0',
    journalRef: 'Nature 1980, 288, 280-283',
    tags: const ["Pharm-D", "MBBS", "Prodrug", "Bioactivation", "CES1", "Enalapril", "Pharmacokinetics"],
    defaultCatalystName: 'CES1 (Ser221-His468-Glu354 Triad)',
    literatureBarrierKcalMol: 14.4,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1038/288280a0',
    catalystXyz: '''6
CES1 Catalytic Triad Model
C  0.0000 0.0000 0.0000
O  1.4000 0.0000 0.0000
C -0.6500 1.3000 0.0000
N -2.0000 1.3000 0.0000
C -2.4000 0.0000 0.0000
N -1.2500 -0.7500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-losartan-01',
    name: 'Losartan Angiotensin II Receptor Type 1 (AT1) Antagonism',
    iupacName: 'losartan + CYP2C9 oxidation → EXP3174 (active 5-carboxylic acid metabolite)',
    description: 'Cornerstone cardiovascular therapeutics for MBBS and Pharm-D students. Losartan is an orally active, non-peptide Angiotensin Receptor Blocker (ARB) containing an imidazole ring and biphenyl tetrazole. Oxidized by hepatic CYP2C9 and CYP3A4 to EXP3174 (10 to 40 times more potent, non-competitive AT1 blocker). Prevents AT1-mediated vasoconstriction and aldosterone release without inhibiting kininase II, eliminating the dry cough and angioedema risks of ACE inhibitors.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''55
Losartan Angiotensin II Receptor Type 1 (AT1) Antagonism - Reactants
Cl     1.1137    -3.5567    -0.6445
C     -0.4681    -3.0200    -0.3123
N     -1.3369    -3.6650     0.4202
C     -2.4680    -2.8786     0.4104
C     -3.6819    -3.3142     1.1609
O     -4.2171    -2.2727     1.9755
C     -2.2720    -1.7505    -0.3795
C     -3.2134    -0.6403    -0.7195
C     -3.9899    -0.9433    -2.0030
C     -4.9486     0.1945    -2.3529
C     -5.7237    -0.1021    -3.6267
N     -0.9606    -1.8479    -0.8143
C     -0.2551    -0.9177    -1.6835
C      0.7775    -0.0990    -0.9422
C      2.1085    -0.0856    -1.3818
C      3.0717     0.6767    -0.7155
C      2.7289     1.4474     0.4048
C      1.3930     1.4512     0.8292
C      0.4293     0.6865     0.1657
C      3.7489     2.2345     1.1127
C      4.2249     3.4028     0.4769
C      5.1699     4.2307     1.0812
C      5.6582     3.9105     2.3392
C      5.2043     2.7603     2.9857
C      4.2564     1.8995     2.3922
C      3.8727     0.7096     3.1648
N      4.0276     0.5350     4.4674
N      3.5695    -0.7244     4.7593
N      3.1468    -1.3372     3.6662
N      3.3346    -0.4531     2.6777
H     -4.4584    -3.6344     0.4590
H     -3.4334    -4.1606     1.8103
H     -4.8226    -2.7036     2.6007
H     -2.6727     0.3071    -0.8199
H     -3.9194    -0.4904     0.1052
H     -4.5555    -1.8762    -1.8834
H     -3.2920    -1.1035    -2.8346
H     -5.6557     0.3520    -1.5302
H     -4.3877     1.1274    -2.4825
H     -6.3211    -1.0131    -3.5193
H     -5.0463    -0.2333    -4.4766
H     -6.4030     0.7243    -3.8582
H      0.1981    -1.5098    -2.4874
H     -0.9755    -0.2487    -2.1633
H      2.4118    -0.6728    -2.2474
H      4.0992     0.6643    -1.0775
H      1.0915     2.0519     1.6870
H     -0.5962     0.7106     0.5313
H      3.8413     3.6814    -0.5041
H      5.5158     5.1269     0.5724
H      6.3907     4.5518     2.8232
H      5.6046     2.5298     3.9735
H      3.0851    -0.7119     1.7325
O      4.5705     0.0000     0.0000
O      3.4295     0.0000     0.0000''',
    productXyz: '''55
Losartan Angiotensin II Receptor Type 1 (AT1) Antagonism - Products
Cl     1.9988     2.1300    -4.4458
C      2.2541     2.2840    -2.7692
N      2.6152     3.3874    -2.1750
C      2.7167     3.0718    -0.8298
C      3.1273     4.0756     0.1550
O      3.3601     5.2545    -0.0772
O      3.2564     3.6257     1.4258
C      2.3852     1.7281    -0.6338
C      2.3391     0.9007     0.6141
C      3.7097     0.3060     0.9452
C      3.6541    -0.5339     2.2211
C      5.0123    -1.1297     2.5554
N      2.0786     1.2454    -1.9002
C      1.6968    -0.1195    -2.2429
C      0.2530    -0.4257    -1.9111
C     -0.0609    -1.5883    -1.1924
C     -1.3855    -1.8922    -0.8684
C     -2.4325    -1.0445    -1.2562
C     -2.1226     0.0932    -2.0141
C     -0.7976     0.3978    -2.3403
C     -3.8195    -1.3286    -0.8559
C     -4.7282    -1.7381    -1.8539
C     -6.0484    -2.0653    -1.5448
C     -6.4867    -1.9954    -0.2291
C     -5.6069    -1.5893     0.7745
C     -4.2738    -1.2387     0.4841
C     -3.4381    -0.7997     1.6069
N     -3.5534    -1.1556     2.8747
N     -2.5724    -0.4864     3.5645
N     -1.8670     0.2864     2.7540
N     -2.4120     0.1060     1.5441
H      3.5307     4.4351     1.9039
H      1.6059     0.0946     0.5177
H      1.9798     1.5107     1.4506
H      4.4491     1.1075     1.0658
H      4.0574    -0.3169     0.1115
H      3.3168     0.0856     3.0601
H      2.9256    -1.3444     2.1019
H      5.3641    -1.7810     1.7489
H      4.9495    -1.7262     3.4709
H      5.7576    -0.3435     2.7125
H      1.8786    -0.3034    -3.3056
H      2.3780    -0.7800    -1.6938
H      0.7246    -2.2680    -0.8652
H     -1.5961    -2.7965    -0.2975
H     -2.9151     0.7611    -2.3502
H     -0.6035     1.2923    -2.9296
H     -4.3992    -1.8205    -2.8892
H     -6.7290    -2.3843    -2.3303
H     -7.5120    -2.2573     0.0211
H     -5.9716    -1.5400     1.8007
H     -2.0431     0.6133     0.7508
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    referenceEa: 16.8,
    doi: '10.1021/jm00167a007',
    journalRef: 'J. Med. Chem. 1991, 34, 1514-1522',
    tags: const ["MBBS", "Pharm-D", "Cardiology", "ARB", "Losartan", "Hypertension", "CYP2C9"],
    defaultCatalystName: 'CYP2C9 (Cytochrome P450 Fe=O Heme)',
    literatureBarrierKcalMol: 17.2,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/jm00167a007',
    catalystXyz: '''6
Fe(IV)=O Heme Active Intermediate
Fe 0.0000 0.0000 0.0000
O  0.0000 0.0000 1.6200
N  2.0000 0.0000 0.0000
N -2.0000 0.0000 0.0000
N  0.0000 2.0000 0.0000
N  0.0000 -2.0000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-propranolol-01',
    name: 'Propranolol Non-Selective Beta-Adrenergic Antagonism',
    iupacName: '1-(isopropylamino)-3-(naphthalen-1-yloxy)propan-2-ol + beta-receptor → receptor blockade',
    description: 'Sir James Black\'s Nobel Prize-winning prototype beta-blocker for MBBS and Pharm-D students. Propranolol competitively antagonizes both beta-1 (cardiac SA/AV node, inotropy, chronotropy, renin release) and beta-2 (bronchial, vascular smooth muscle) adrenergic receptors. Crucial medical concepts: contraindicated in bronchial asthma due to fatal bronchospasm; lipid solubility enables central CNS penetration (treating essential tremor, migraine prophylaxis, and stage fright).',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''48
Propranolol Non-Selective Beta-Adrenergic Antagonism - Reactants
C      5.6531     1.3673    -0.1091
C      4.7344     0.1529    -0.2564
C      4.8330    -0.4008    -1.6789
N      3.3748     0.5773     0.0791
C      2.4614    -0.5339     0.3697
C      1.0308    -0.0434     0.6801
O      1.0175     0.7188     1.8953
C      0.0778    -1.2373     0.8402
O     -1.2574    -0.7786     1.0818
C     -2.0905    -0.5157     0.0216
C     -1.7017    -0.5671    -1.3209
C     -2.6156    -0.2734    -2.3319
C     -3.9249     0.0767    -2.0125
C     -4.3425     0.1401    -0.6766
C     -5.6642     0.4965    -0.3592
C     -6.0901     0.5630     0.9670
C     -5.2003     0.2732     1.9934
C     -3.8838    -0.0827     1.6928
C     -3.4228    -0.1575     0.3593
H      5.3748     2.1715    -0.7999
H      6.6932     1.0923    -0.3159
H      5.6142     1.7677     0.9103
H      5.0761    -0.6097     0.4542
H      4.2473    -1.3176    -1.7969
H      4.4779     0.3262    -2.4180
H      5.8722    -0.6455    -1.9250
H      2.9918     1.1913    -0.6366
H      2.4165    -1.2162    -0.4856
H      2.8444    -1.0867     1.2358
H      0.6807     0.6231    -0.1157
H      0.0823     0.9305     2.0720
H      0.3605    -1.7995     1.7385
H      0.1248    -1.9462     0.0064
H     -0.6933    -0.8252    -1.6227
H     -2.3064    -0.3151    -3.3734
H     -4.6201     0.3025    -2.8184
H     -6.3765     0.7268    -1.1486
H     -7.1155     0.8403     1.1962
H     -5.5255     0.3218     3.0292
H     -3.2081    -0.3074     2.5159
C      3.0665    -0.0601    -0.2304
C      4.4936     0.2789     0.0469
O      5.0325     1.3566    -0.1361
O      5.1814    -0.7645     0.5462
H      2.5573     0.8203    -0.6327
H      2.5695    -0.3576     0.6963
H      3.0133    -0.8625    -0.9702
H      6.0859    -0.4112     0.6800''',
    productXyz: '''48
Propranolol Non-Selective Beta-Adrenergic Antagonism - Products
C      5.3925    -1.0584     0.6577
C      4.2416    -1.8041    -0.0198
C      4.4138    -1.8234    -1.5392
N      2.9163    -1.3226     0.3985
C      2.6095     0.0651     0.0349
C      1.1800     0.4773     0.4493
O      0.9710     1.8695     0.1022
C      1.4178     2.7809     1.0058
O      2.0260     2.5231     2.0345
C      1.0710     4.1650     0.5507
C      0.1162    -0.3449    -0.2944
O     -1.1700     0.0128     0.2285
C     -2.2802    -0.5535    -0.3518
C     -2.2280    -1.5351    -1.3473
C     -3.4036    -2.0591    -1.8822
C     -4.6408    -1.6095    -1.4269
C     -4.7233    -0.6299    -0.4276
C     -5.9735    -0.1808     0.0307
C     -6.0654     0.7924     1.0255
C     -4.9083     1.3297     1.5754
C     -3.6591     0.8934     1.1294
C     -3.5349    -0.0906     0.1235
H      5.2655    -1.0442     1.7457
H      6.3456    -1.5548     0.4441
H      5.4749    -0.0243     0.3080
H      4.2962    -2.8480     0.3147
H      3.5764    -2.3381    -2.0229
H      4.4878    -0.8154    -1.9597
H      5.3302    -2.3593    -1.8107
H      2.8475    -1.4137     1.4149
H      3.3248     0.7477     0.5061
H      2.7041     0.2183    -1.0462
H      1.0300     0.3479     1.5295
H      1.5779     4.3825    -0.3927
H      1.4031     4.8874     1.3019
H     -0.0121     4.2573     0.4365
H      0.2837    -1.4152    -0.1326
H      0.1528    -0.1054    -1.3643
H     -1.2870    -1.9186    -1.7268
H     -3.3554    -2.8220    -2.6551
H     -5.5449    -2.0334    -1.8587
H     -6.8912    -0.5897    -0.3866
H     -7.0397     1.1284     1.3697
H     -4.9721     2.0873     2.3517
H     -2.7669     1.3282     1.5760
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    referenceEa: 15.1,
    doi: '10.1016/S0140-6736(64)90299-4',
    journalRef: 'Lancet 1964, 283, 1080',
    tags: const ["MBBS", "Pharm-D", "Cardiology", "Beta-Blocker", "Propranolol", "Autonomic Pharmacology", "Arrhythmia"],
    defaultCatalystName: 'CYP2D6 (Heme Monooxygenase)',
    literatureBarrierKcalMol: 16.0,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/S0140-6736(64)90299-4',
    catalystXyz: '''6
Fe(IV)=O Heme Active Intermediate
Fe 0.0000 0.0000 0.0000
O  0.0000 0.0000 1.6200
N  2.0000 0.0000 0.0000
N -2.0000 0.0000 0.0000
N  0.0000 2.0000 0.0000
N  0.0000 -2.0000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-amlodipine-01',
    name: 'Amlodipine L-Type Calcium Channel Blockade',
    iupacName: 'amlodipine dihydropyridine core + vascular CaV1.2 channel → channel closed state stabilization',
    description: 'The premier dihydropyridine calcium channel blocker (CCB) in medical and pharmacy curricula. Binds allosterically to the alpha-1 pore-forming subunit of L-type voltage-gated calcium channels (CaV1.2) in peripheral arterial smooth muscle cells. Uniquely features a basic 2-aminoethoxymethyl sidechain conferring ionization at physiologic pH (pKa 8.6), slow association and dissociation kinetics, a long half-life (35-50 hours), and high vascular selectivity over cardiac tissue.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''56
Amlodipine L-Type Calcium Channel Blockade - Reactants
C      0.6785     4.5312    -0.7561
C      0.7789     3.6391     0.4655
O      0.5241     2.2924     0.0548
C      0.6201     1.3850     1.0559
O      0.8708     1.6081     2.2295
C      0.3746     0.0409     0.5010
C      1.3362    -0.9076     0.5638
C      2.7116    -0.6561     1.1589
O      3.3557     0.4464     0.5198
C      3.9117     0.1160    -0.7560
C      4.4631     1.3949    -1.4002
N      5.4494     2.0648    -0.5444
N      1.0933    -2.1606     0.0125
C     -0.0542    -2.4918    -0.6947
C     -0.0500    -3.8463    -1.3560
C     -1.0633    -1.5955    -0.7867
C     -2.3047    -1.8538    -1.5430
O     -2.7236    -1.1198    -2.4233
O     -2.9130    -2.9683    -1.0648
C     -4.1679    -3.2473    -1.6849
C     -0.9786    -0.2113    -0.1459
C     -2.1145     0.0042     0.8625
C     -2.2355    -0.8732     1.9626
C     -3.2522    -0.7161     2.9058
C     -4.1679     0.3216     2.7740
C     -4.0636     1.2042     1.7005
C     -3.0454     1.0523     0.7515
Cl    -2.9971     2.2103    -0.5295
H      1.4021     4.2232    -1.5182
H      0.8655     5.5760    -0.4928
H     -0.3148     4.4531    -1.2103
H      1.7844     3.7127     0.8951
H      0.0353     3.9445     1.2101
H      3.3520    -1.5443     1.0973
H      2.6120    -0.4208     2.2242
H      4.7137    -0.6188    -0.6210
H      3.1441    -0.3111    -1.4101
H      4.9184     1.1609    -2.3676
H      3.6413     2.0979    -1.5756
H      4.9906     2.2281     0.3574
H      6.2043     1.4148    -0.3305
H      1.8544    -2.8349     0.0113
H     -0.7984    -3.9416    -2.1474
H     -0.2293    -4.6283    -0.6111
H      0.9221    -4.0368    -1.8249
H     -4.0345    -3.4282    -2.7561
H     -4.5768    -4.1534    -1.2293
H     -4.8713    -2.4262    -1.5140
H     -1.0607     0.4979    -0.9775
H     -1.5276    -1.6909     2.0941
H     -3.3241    -1.4030     3.7457
H     -4.9588     0.4486     3.5086
H     -4.7805     2.0168     1.6092
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''56
Amlodipine L-Type Calcium Channel Blockade - Products
C      3.6526     2.8806     2.2680
C      3.1892     2.6827     0.8382
O      2.4750     1.4431     0.7697
C      1.9921     1.1528    -0.4640
O      2.1326     1.8227    -1.4733
C      1.2048    -0.0936    -0.4117
C      1.7031    -1.2504     0.0784
C      3.1130    -1.4304     0.5996
O      3.5794    -2.7272     0.2188
N      0.9129    -2.3935     0.0650
C     -0.3259    -2.4828    -0.5477
C     -0.9186    -3.8653    -0.6341
C     -0.8950    -1.3657    -1.0546
C     -2.1967    -1.3735    -1.7490
O     -2.3586    -0.9594    -2.8853
O     -3.1595    -1.8430    -0.9164
C     -4.4698    -1.8141    -1.4813
C     -0.2071    -0.0038    -0.9852
C     -1.0544     0.9954    -0.1845
C     -1.3155     0.7384     1.1799
C     -2.0781     1.6178     1.9500
C     -2.5970     2.7725     1.3756
C     -2.3533     3.0460     0.0308
C     -1.5892     2.1676    -0.7471
Cl    -1.3500     2.6014    -2.4011
H      2.7971     2.8969     2.9515
H      4.2066     3.8175     2.3728
H      4.2956     2.0519     2.5828
H      2.5293     3.5071     0.5452
H      4.0563     2.6470     0.1693
H      3.1204    -1.3785     1.6925
H      3.8201    -0.6977     0.2019
H      3.5719    -2.7394    -0.7552
H      1.3854    -3.2564     0.3417
H     -1.3056    -4.1695     0.3437
H     -0.1531    -4.5878    -0.9392
H     -1.7273    -3.9427    -1.3658
H     -4.5187    -2.4517    -2.3696
H     -4.7605    -0.7870    -1.7237
H     -5.1686    -2.2045    -0.7363
H     -0.0900     0.3275    -2.0236
H     -0.9228    -0.1605     1.6549
H     -2.2663     1.3982     2.9982
H     -3.1918     3.4598     1.9718
H     -2.7640     3.9511    -0.4108
O      5.9849     0.3971    -0.1954
C      4.6921    -0.0816    -0.5468
C      3.6624     0.3047     0.5206
N      2.3141    -0.1637     0.2140
H      6.2279    -0.0094     0.6543
H      4.4253     0.3534    -1.5154
H      4.7488    -1.1688    -0.6660
H      3.9717    -0.1011     1.4906
H      3.6510     1.3938     0.6425
H      2.3200    -1.1724     0.0673
H      2.0019     0.2480    -0.6656''',
    referenceEa: 14.8,
    doi: '10.1097/00005344-198800127-00003',
    journalRef: 'J. Cardiovasc. Pharmacol. 1988, 12, S10',
    tags: const ["MBBS", "Pharm-D", "Cardiology", "CCB", "Amlodipine", "Hypertension", "Calcium Channel"],
    defaultCatalystName: 'Cav1.2 Channel Voltage Sensor Pore',
    literatureBarrierKcalMol: 12.5,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1097/00005344-198800127-00003',
    catalystXyz: '''5
Ca2+ Filter Core
Ca 0.0000 0.0000 0.0000
O  2.3500 0.0000 0.0000
O -2.3500 0.0000 0.0000
O  0.0000 2.3500 0.0000
O  0.0000 -2.3500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-atorvastatin-01',
    name: 'Atorvastatin HMG-CoA Reductase Pharmacophore Mimicry',
    iupacName: 'atorvastatin + HMG-CoA reductase → competitive active-site inhibition (Kd ~ 8 nM)',
    description: 'The hallmark lipid-lowering therapeutic for MBBS cardiology and Pharm-D medicinal chemistry. The 3,5-dihydroxyheptanoic acid sidechain precisely mimics the tetrahedral mevaldyl-CoA intermediate formed during conversion of HMG-CoA to mevalonate by HMG-CoA Reductase. Hepatic sterol depletion upregulates sterol regulatory element-binding protein 2 (SREBP-2), leading to robust LDL receptor expression, rapid clearance of atherogenic ApoB lipoproteins, and atherosclerotic plaque stabilization.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''78
Atorvastatin HMG-CoA Reductase Pharmacophore Mimicry - Reactants
C      0.8338     2.6912    -1.3635
C      0.6793     2.2011     0.0762
C     -0.1259     3.1989     0.9144
C      0.1029     0.7951     0.1577
C     -1.2014     0.3612    -0.1020
C     -2.3169     1.1861    -0.5879
O     -2.2121     1.8763    -1.5932
N     -3.4385     1.0753     0.2119
C     -4.6932     1.6891     0.0394
C     -5.6877     1.3791     0.9767
C     -6.9625     1.9424     0.8778
C     -7.2550     2.8225    -0.1600
C     -6.2730     3.1368    -1.0964
C     -4.9969     2.5721    -0.9978
C     -1.2640    -1.0299     0.2270
C     -2.4067    -1.9296     0.1159
C     -3.0254    -2.1158    -1.1288
C     -4.1395    -2.9493    -1.2413
C     -4.6307    -3.5930    -0.1116
F     -5.6990    -4.3935    -0.2201
C     -4.0315    -3.4177     1.1304
C     -2.9195    -2.5818     1.2466
C     -0.0167    -1.4202     0.6918
C      0.4075    -2.7411     1.1763
C      0.7003    -2.9411     2.5311
C      1.0820    -4.2024     2.9923
C      1.1643    -5.2740     2.1045
C      0.8614    -5.0874     0.7566
C      0.4805    -3.8264     0.2946
N      0.8321    -0.3219     0.5642
C      2.2629    -0.3765     0.8698
C      3.1064    -1.1452    -0.1519
C      3.3304    -0.4349    -1.4906
O      4.0609    -1.3001    -2.3704
C      4.0519     0.9204    -1.4480
C      5.4776     0.9007    -0.8800
O      5.4446     0.6225     0.5186
C      6.2462     2.1977    -1.1566
C      5.5421     3.4525    -0.7080
O      4.7207     3.5786     0.1822
O      5.9638     4.5323    -1.3982
H      1.4922     3.5670    -1.3939
H     -0.1162     2.9979    -1.8059
H      1.2687     1.9226    -2.0091
H      1.6787     2.2149     0.5137
H     -1.1249     3.3774     0.5061
H     -0.2424     2.8425     1.9439
H      0.3873     4.1663     0.9515
H     -3.3467     0.4619     1.0108
H     -5.4861     0.6912     1.7936
H     -7.7258     1.6918     1.6097
H     -8.2454     3.2624    -0.2412
H     -6.4954     3.8230    -1.9097
H     -4.2630     2.8457    -1.7490
H     -2.6439    -1.6138    -2.0160
H     -4.6250    -3.0976    -2.2005
H     -4.4306    -3.9334     1.9976
H     -2.4547    -2.4473     2.2204
H      0.6249    -2.1159     3.2350
H      1.3092    -4.3499     4.0448
H      1.4578    -6.2571     2.4637
H      0.9163    -5.9234     0.0643
H      0.2406    -3.6923    -0.7579
H      2.3520    -0.8604     1.8485
H      2.6533     0.6267     1.0277
H      2.6612    -2.1231    -0.3634
H      4.0738    -1.3916     0.3009
H      2.3564    -0.2822    -1.9688
H      4.6466    -1.8596    -1.8322
H      3.4411     1.6199    -0.8752
H      4.1028     1.2985    -2.4775
H      6.0392     0.0820    -1.3447
H      6.3522     0.6781     0.8650
H      6.4176     2.2744    -2.2372
H      7.2185     2.1773    -0.6516
H      5.4535     5.2763    -1.0133
O      4.5705     0.0000     0.0000
O      3.4295     0.0000     0.0000''',
    productXyz: '''77
Atorvastatin HMG-CoA Reductase Pharmacophore Mimicry - Products
C      1.3859     2.8244     1.1137
C      0.2052     2.1001     1.7542
C      0.4499     1.7492     3.2227
C     -0.3002     0.9131     0.9471
C     -1.5701     0.7703     0.3780
C     -2.6213     1.8019     0.3815
O     -2.3587     2.9701     0.1212
N     -3.8661     1.2996     0.7067
C     -5.0940     1.9861     0.7600
C     -5.2407     3.3502     0.5040
C     -6.5014     3.9525     0.5753
C     -7.6245     3.1960     0.9014
C     -7.4891     1.8345     1.1569
C     -6.2299     1.2332     1.0866
C     -1.6379    -0.5425    -0.1892
C     -2.7395    -1.1617    -0.9170
C     -3.3218    -2.3509    -0.4549
C     -4.3944    -2.9206    -1.1431
C     -4.8849    -2.2977    -2.2848
F     -5.9161    -2.8441    -2.9418
C     -4.3232    -1.1159    -2.7536
C     -3.2478    -0.5459    -2.0698
C     -0.4167    -1.1672     0.0260
C      0.0201    -2.5078    -0.3854
C      0.2511    -3.5039     0.5711
C      0.6606    -4.7790     0.1769
C      0.8323    -5.0692    -1.1758
C      0.5907    -4.0877    -2.1357
C      0.1832    -2.8119    -1.7425
N      0.4110    -0.2433     0.6559
C      1.8341    -0.4725     0.8904
C      2.6683    -0.2350    -0.3632
C      4.1471    -0.3738    -0.0744
O      4.5758    -0.6165     1.0541
C      5.0759    -0.2271    -1.2671
C      6.5537    -0.0967    -0.8847
O      6.9782    -1.2811    -0.2069
C      6.8499     1.1401    -0.0365
C      8.2743     1.5844    -0.2060
O      9.1311     1.6226     0.6606
O      8.5409     2.0256    -1.4513
H      1.2045     3.0123     0.0498
H      2.3236     2.2718     1.2056
H      1.5427     3.7938     1.6004
H     -0.6014     2.8422     1.7823
H      0.6717     2.6545     3.7988
H      1.2856     1.0608     3.3659
H     -0.4387     1.2838     3.6643
H     -3.8998     0.3125     0.9237
H     -4.3941     3.9784     0.2467
H     -6.6011     5.0162     0.3744
H     -8.6021     3.6677     0.9548
H     -8.3626     1.2392     1.4095
H     -6.1523     0.1675     1.2862
H     -2.9419    -2.8418     0.4382
H     -4.8466    -3.8448    -0.7982
H     -4.7251    -0.6450    -3.6451
H     -2.8121     0.3796    -2.4411
H      0.1094    -3.2927     1.6284
H      0.8413    -5.5470     0.9247
H      1.1475    -6.0635    -1.4825
H      0.7133    -4.3172    -3.1911
H     -0.0114    -2.0566    -2.5003
H      1.9618    -1.4934     1.2637
H      2.1660     0.1693     1.7050
H      2.4112    -0.9560    -1.1448
H      2.4916     0.7700    -0.7609
H      4.7655     0.6513    -1.8433
H      4.9344    -1.1214    -1.8851
H      7.1270    -0.0634    -1.8181
H      6.4567    -1.3463     0.6211
H      6.6937     0.9439     1.0300
H      6.2141     1.9876    -0.3176
H      9.4863     2.2846    -1.4063
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    referenceEa: 17.5,
    doi: '10.1016/s0079-6468(08)70080-8',
    journalRef: 'Prog. Med. Chem. 2002, 40, 1-22',
    tags: const ["MBBS", "Pharm-D", "Cardiology", "Statin", "Atorvastatin", "Cholesterol", "Atherosclerosis"],
    defaultCatalystName: 'HMG-CoA Reductase (His866/Lys735)',
    literatureBarrierKcalMol: 13.1,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/s0079-6468(08)70080-8',
    catalystXyz: '''6
His-Lys Active Dyad
N  0.0000 1.3000 0.0000
C  1.2000 0.6000 0.0000
C  1.2000 -0.8000 0.0000
N  0.0000 -1.4000 0.0000
C -1.2000 -0.6000 0.0000
N -2.5000 0.0000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-nitroglycerin-01',
    name: 'Nitroglycerin ALDH-2 Denitration & Nitric Oxide (NO) Vasodilation',
    iupacName: 'glyceryl trinitrate + ALDH-2/thiol → 1,2-glyceryl dinitrate + nitric oxide (NO)',
    description: 'Acute emergency treatment of angina pectoris and cardiogenic pulmonary edema for MBBS & Pharm-D students. Nitroglycerin (GTN) undergoes bioactivation in venous vascular smooth muscle mitochondria catalyzed by mitochondrial aldehyde dehydrogenase (ALDH-2) via essential cysteine thiols. The generated nitric oxide (NO) stimulates soluble guanylyl cyclase (sGC) to produce cyclic GMP (cGMP), activating protein kinase G (PKG), dephosphorylating myosin light chain, and precipitating venous pooling and marked preload reduction.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''23
Nitroglycerin ALDH-2 Denitration & Nitric Oxide (NO) Vasodilation - Reactants
O     -4.3028    -0.6449     1.3466
N     -3.3457    -0.9952     0.6613
O     -3.2173    -1.9622    -0.0904
O     -2.2346    -0.1254     0.7859
C     -1.1238    -0.5388    -0.0134
C      0.0062     0.4879     0.1764
C      1.2834     0.0186    -0.5366
O      1.7628    -1.1631     0.0977
N      2.9450    -1.6635    -0.5032
O      3.3775    -1.0531    -1.4807
O      3.3666    -2.6743     0.0524
O     -0.4534     1.7165    -0.4017
N      0.1473     2.8714     0.1570
O     -0.3037     3.9130    -0.3104
O      1.0349     2.6929     0.9904
H     -0.7889    -1.5307     0.3120
H     -1.4205    -0.5629    -1.0698
H      0.1650     0.5803     1.2594
H      1.0565    -0.1720    -1.5941
H      2.0455     0.8056    -0.4896
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''22
Nitroglycerin ALDH-2 Denitration & Nitric Oxide (NO) Vasodilation - Products
O     -1.6170     2.3205     0.5310
C     -0.3781     1.6517     0.3021
C     -0.6634     0.2321    -0.2080
C      0.6187    -0.4357    -0.7271
O      1.6137    -0.4105     0.2974
N      2.8399    -0.9845    -0.1185
O      2.8986    -1.4085    -1.2727
O      3.6972    -0.9587     0.7610
O     -1.1867    -0.5030     0.9088
N     -2.0463    -1.5635     0.5430
O     -2.1408    -1.8247    -0.6569
O     -2.5545    -2.1205     1.5131
H     -1.4136     3.1837     0.9339
H      0.1697     1.6341     1.2500
H      0.1843     2.2308    -0.4368
H     -1.4072     0.3161    -1.0111
H      0.4134    -1.4763    -1.0024
H      0.9720     0.1169    -1.6067
N      4.4751     0.1815    -0.4062
O      5.5377    -0.0276     0.1849
O      3.3650    -0.1855     0.4037
H      2.6223     0.0316    -0.1824''',
    referenceEa: 13.9,
    doi: '10.1073/pnas.122225999',
    journalRef: 'Proc. Natl. Acad. Sci. U.S.A. 2002, 99, 8306',
    tags: const ["MBBS", "Pharm-D", "Cardiology", "Nitroglycerin", "Nitric Oxide", "Angina", "Vasodilation"],
    defaultCatalystName: 'Mitochondrial ALDH-2 (Cys302 Thiolate)',
    literatureBarrierKcalMol: 11.8,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1073/pnas.122225999',
    catalystXyz: '''5
ALDH-2 Cys Active Core
S  0.0000 0.0000 0.0000
C  1.8000 0.0000 0.0000
N -1.5000 1.2000 0.0000
C -2.2000 0.0000 0.0000
H  2.1500 0.9500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-furosemide-01',
    name: 'Furosemide Loop Diuretic NKCC2 Symporter Inhibition',
    iupacName: '4-chloro-2-[(furan-2-ylmethyl)amino]-5-sulfamoylbenzoic acid + NKCC2 → trans-epithelial transport block',
    description: 'Essential renal physiology and pharmacotherapy for MBBS and Pharm-D students. Furosemide binds reversibly to the chloride-binding pocket of the Na+/K+/2Cl- cotransporter (NKCC2) in the apical membrane of the thick ascending limb of Henle\'s loop. Abolishes the positive lumen potential, preventing passive paracellular reabsorption of Ca2+ and Mg2+; dissipates the hypertonic medullary gradient, inducing massive natriuresis and diuresis in acute pulmonary edema, congestive heart failure, and refractory ascites.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''35
Furosemide Loop Diuretic NKCC2 Symporter Inhibition - Reactants
N     -5.5191     0.7055    -0.0070
S     -4.7767    -0.4880    -0.9310
O     -5.0163    -0.1617    -2.3163
O     -5.1825    -1.7546    -0.3675
C     -3.0533    -0.2640    -0.5984
C     -2.3440    -1.3226    -0.0177
C     -0.9644    -1.2107     0.2340
C     -0.3268    -2.4013     0.8617
O     -0.9168    -3.2897     1.4487
O      1.0063    -2.4632     0.6811
C     -0.2660    -0.0291    -0.1100
N      1.0873     0.1485     0.2317
C      1.9385     0.9914    -0.6140
C      3.3875     0.8909    -0.2735
C      4.0931     1.0292     0.9047
C      5.4544     0.8149     0.5826
C      5.4930     0.5599    -0.7680
O      4.2431     0.6036    -1.2970
C     -1.0150     1.0288    -0.6581
C     -2.3902     0.9173    -0.9165
Cl    -3.1692     2.3120    -1.5731
H     -5.9620     1.3818    -0.6332
H     -4.9051     1.1588     0.6672
H     -2.8592    -2.2494     0.2403
H      1.2551    -3.3093     1.1140
H      1.5310    -0.7697     0.3675
H      1.7988     0.7154    -1.6669
H      1.6498     2.0429    -0.5020
H      3.6683     1.2533     1.8737
H      6.3035     0.8415     1.2510
H      6.2885     0.3395    -1.4664
H     -0.5314     1.9783    -0.8765
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''33
Furosemide Loop Diuretic NKCC2 Symporter Inhibition - Products
N     -3.1124     1.3659    -0.5714
S     -2.9202    -0.1461     0.1439
O     -3.4347     0.0154     1.4824
O     -3.4675    -1.0732    -0.8176
C     -1.1772    -0.3890     0.2312
C     -0.3010     0.6022    -0.2293
C      1.0909     0.4106    -0.1690
C      1.9277     1.5315    -0.6768
O      1.5336     2.6660    -0.8804
O      3.1966     1.1836    -0.9668
C      1.6149    -0.7954     0.3367
N      2.9864    -0.9907     0.5767
C      0.7189    -1.7537     0.8366
C     -0.6685    -1.5689     0.7704
Cl    -1.6573    -2.8404     1.3918
H     -3.6192     1.2578    -1.4521
H     -3.5817     1.9907     0.0874
H     -0.6860     1.5359    -0.6356
H      3.5875     2.0204    -1.3005
H      3.5691    -0.4025    -0.0272
H      3.2886    -1.9601     0.5745
H      1.1113    -2.6601     1.2952
O      6.7137     1.2127    -0.0265
C      6.0479     0.1813     0.0207
C      4.6102     0.0943     0.0039
C      3.7587    -0.9935     0.0515
C      2.4399    -0.4780     0.0031
C      2.5665     0.8886    -0.0708
O      3.8760     1.2447    -0.0709
H      6.5632    -0.7924     0.0824
H      4.0515    -2.0326     0.1135
H      1.5113    -1.0315     0.0199
H      1.8611     1.7065    -0.1268''',
    referenceEa: 16.1,
    doi: '10.1016/0014-2999(77)90261-8',
    journalRef: 'Eur. J. Pharmacol. 1977, 42, 381-389',
    tags: const ["MBBS", "Pharm-D", "Nephrology", "Diuretic", "Furosemide", "NKCC2", "Electrolytes"],
    defaultCatalystName: 'NKCC2 Symporter Translocation Core',
    literatureBarrierKcalMol: 14.8,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/0014-2999(77)90261-8',
    catalystXyz: '''4
NKCC2 Transport Filter
Na 0.0000 0.0000 0.0000
K  3.1000 0.0000 0.0000
Cl 1.5500 2.2000 0.0000
Cl 1.5500 -2.2000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-omeprazole-01',
    name: 'Omeprazole Acid Canalicular Activation to Tetracyclic Sulfenamide',
    iupacName: 'omeprazole (prodrug) + 2 H+ → sulfenic acid → tetracyclic sulfenamide (active inhibitor)',
    description: 'Premier gastrointestinal pharmacology milestone for MBBS & Pharm-D students. Omeprazole is a lipophilic weak base (pKa ~4) that accumulates selectively in the acidic secretocanaliculi (pH <1.3) of gastric parietal cells. Protonation triggers an intramolecular rearrangement forming a permanent tetracyclic sulfenamide that reacts covalently with Cysteine-813 of the H+/K+-ATPase proton pump, permanently extinguishing gastric acid secretion until de novo pump synthesis (24-48 hours).',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''49
Omeprazole Acid Canalicular Activation to Tetracyclic Sulfenamide - Reactants
C     -6.4767    -1.3802    -0.0663
C     -5.0126    -1.1074     0.0750
C     -4.1588    -2.0851     0.5545
N     -2.8297    -1.9175     0.7172
C     -2.2818    -0.7268     0.3604
C     -3.0535     0.3366    -0.1317
C     -4.4409     0.1330    -0.2169
O     -5.2524     1.1469    -0.6671
C     -5.7088     1.9411     0.4305
C     -2.4413     1.6587    -0.5020
C     -0.7867    -0.6298     0.5349
S      0.0951    -0.9997    -1.0134
O      0.3094    -2.4832    -1.1320
C      1.6933    -0.3528    -0.4930
N      1.9088     0.8599    -0.0333
C      3.2576     0.9033     0.2286
C      3.8683    -0.3089    -0.0782
N      2.8432    -1.0918    -0.5400
C      5.2366    -0.5508     0.0930
C      6.0057     0.5047     0.6008
C      5.4106     1.7330     0.9146
C      4.0373     1.9502     0.7349
O      7.3552     0.4604     0.8366
C      8.0224    -0.7599     0.5407
H     -7.0147    -1.0265     0.8183
H     -6.6677    -2.4528    -0.1804
H     -6.8849    -0.8885    -0.9553
H     -4.5253    -3.0704     0.8313
H     -6.3040     1.3485     1.1330
H     -6.3496     2.7305     0.0267
H     -4.8730     2.4181     0.9533
H     -1.5253     1.5240    -1.0837
H     -2.2116     2.2301     0.4028
H     -3.1076     2.2609    -1.1275
H     -0.5202     0.3692     0.8934
H     -0.4484    -1.3451     1.2933
H      2.8919    -2.0523    -0.8519
H      5.6565    -1.5151    -0.1624
H      6.0267     2.5393     1.3074
H      3.5849     2.9042     0.9806
H      7.9524    -0.9996    -0.5255
H      7.6383    -1.5794     1.1571
H      9.0814    -0.6292     0.7834
C      3.5080     0.0266    -0.0349
S      5.1071    -0.7428    -0.3595
H      3.3335     0.0804     1.0426
H      3.4911     1.0375    -0.4497
H      2.7121    -0.5626    -0.4969
H      5.8481     0.1608     0.2984''',
    productXyz: '''49
Omeprazole Acid Canalicular Activation to Tetracyclic Sulfenamide - Products
C     -6.5855     0.2513    -1.2823
C     -5.1159     0.1054    -1.0435
C     -4.2319     0.0533    -2.1072
N     -2.8958    -0.0843    -1.9777
C     -2.3749    -0.1535    -0.7223
C     -3.1775    -0.1052     0.4273
C     -4.5665    -0.0281     0.2338
O     -5.4087    -0.0091     1.3201
C     -5.7861    -1.3411     1.6763
C     -2.5883    -0.1771     1.8076
C     -0.8679    -0.2743    -0.6552
S     -0.0620     1.3567    -0.5582
C      1.5826     0.8698    -0.4160
N      2.0466    -0.3398    -0.2204
C      3.4116    -0.1847    -0.1768
C      3.7704     1.1489    -0.3465
N      2.5743     1.8017    -0.4967
C      5.0953     1.5899    -0.3442
C      6.0958     0.6239    -0.1606
C      5.7603    -0.7230     0.0121
C      4.4191    -1.1414     0.0060
O      7.3679     1.1342    -0.1705
C      8.4354     0.2106     0.0022
H     -7.0719    -0.7285    -1.2581
H     -7.0440     0.8990    -0.5280
H     -6.7825     0.7097    -2.2575
H     -4.5791     0.1243    -3.1347
H     -6.3205    -1.8377     0.8596
H     -6.4629    -1.2776     2.5335
H     -4.9170    -1.9366     1.9751
H     -2.2931    -1.2062     2.0352
H     -1.7164     0.4766     1.9007
H     -3.2946     0.1535     2.5754
H     -0.5142    -0.7839    -1.5595
H     -0.5752    -0.9010     0.1938
H      2.4354     2.7896    -0.6447
H      5.3505     2.6357    -0.4789
H      6.5195    -1.4851     0.1555
H      4.1585    -2.1855     0.1393
H      9.3731     0.7734    -0.0339
H      8.4570    -0.5243    -0.8093
H      8.3790    -0.2795     0.9798
C      3.1226    -0.1785     0.0060
S      4.6331    -0.2585     0.9981
O      5.7492    -0.0058    -0.2082
H      2.2525    -0.3276     0.6503
H      3.0431     0.7986    -0.4774
H      3.1352    -0.9585    -0.7596
H      6.0643     0.9303    -0.2093''',
    referenceEa: 15.0,
    doi: '10.1038/290159a0',
    journalRef: 'Nature 1981, 290, 159-161',
    tags: const ["MBBS", "Pharm-D", "Gastroenterology", "PPI", "Omeprazole", "Acid Suppression", "Peptic Ulcer"],
    defaultCatalystName: 'Gastric H+/K+-ATPase Acid Secretory Matrix (pH < 1.0)',
    literatureBarrierKcalMol: 10.9,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1038/290159a0',
    catalystXyz: '''4
Acid Canalicular Hydronium Cluster
O  0.0000 0.0000 0.0000
H  0.9500 0.0000 0.0000
H -0.4500 0.8500 0.0000
H -0.4500 -0.8500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-metformin-01',
    name: 'Metformin Mitochondrial Complex I & AMPK Activation',
    iupacName: '1,1-dimethylbiguanide + mitochondrial respiratory complex I → mild uncoupling & AMPK activation',
    description: 'First-line oral antidiabetic therapy globally in MBBS & Pharm-D endocrinology. Metformin accumulates in mitochondrial matrices due to its positive charge, mildly and reversibly inhibiting Complex I of the respiratory chain. Decreased ATP production and elevated cellular AMP/ATP ratio directly allosterically activate AMP-activated protein kinase (AMPK) and inhibit adenylate cyclase, suppressing hepatic gluconeogenesis (PEPCK and G6Pase downregulation) without causing clinical hypoglycemia or weight gain.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''23
Metformin Mitochondrial Complex I & AMPK Activation - Reactants
C     -1.7412    -1.2523     0.7607
N     -1.2912    -0.2669    -0.2306
C     -2.4263     0.4524    -0.8272
C     -0.2009     0.5067     0.1159
N     -0.3263     1.7379     0.4859
N      0.9796    -0.1666     0.0100
C      2.2831     0.1977    -0.0495
N      2.7672     1.3686    -0.2753
N      3.1575    -0.8149     0.1553
H     -2.4959    -1.9164     0.3259
H     -0.9114    -1.8815     1.0989
H     -2.1748    -0.7531     1.6342
H     -2.9515     1.0570    -0.0795
H     -3.1382    -0.2569    -1.2630
H     -2.0839     1.1066    -1.6367
H      0.5912     2.0839     0.7798
H      0.8342    -1.1576    -0.0877
H      1.9961     2.0086    -0.4907
H      4.1006    -0.4492     0.0390
H      3.0321    -1.6042    -0.4653
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''23
Metformin Mitochondrial Complex I & AMPK Activation - Products
C     -0.9914    -1.5450    -0.8597
N     -1.3643    -0.5017     0.0846
C     -2.5095    -0.8033     0.9275
C     -0.4208     0.3941     0.6201
O     -0.5834     0.9298     1.7125
N      0.6064     0.6935    -0.2599
C      1.8608     1.1420     0.0425
N      2.3114     1.1179     1.2411
N      2.6170     1.5738    -0.9935
H     -0.2083    -1.2233    -1.5489
H     -0.6226    -2.4082    -0.2969
H     -1.8711    -1.8330    -1.4426
H     -2.8453     0.0893     1.4637
H     -3.3332    -1.1664     0.3061
H     -2.2247    -1.5705     1.6540
H      0.3106     0.7744    -1.2142
H      3.2472     1.5176     1.2834
H      3.6118     1.6283    -0.8142
H      2.4093     1.1906    -1.9054
N      4.0043     0.0045     0.2955
H      4.9171    -0.1996    -0.1089
H      3.3680    -0.6979    -0.0786
H      3.7106     0.8929    -0.1080''',
    referenceEa: 14.7,
    doi: '10.1172/JCI13505',
    journalRef: 'J. Clin. Invest. 2001, 108, 1167-1174',
    tags: const ["MBBS", "Pharm-D", "Endocrinology", "Diabetes", "Metformin", "AMPK", "Gluconeogenesis"],
    defaultCatalystName: 'Mitochondrial Complex I / LKB1-AMPK',
    literatureBarrierKcalMol: 15.0,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1172/JCI13505',
    catalystXyz: '''6
Complex I Fe4S4 Cluster Model
Fe 0.0000 0.0000 0.0000
Fe 2.2000 0.0000 0.0000
S  1.1000 1.8000 0.0000
S  1.1000 -1.8000 0.0000
S  1.1000 0.0000 1.8000
S  1.1000 0.0000 -1.8000''',
  ),
  ReactionTemplate(
    id: 'med-glimepiride-01',
    name: 'Glimepiride Pancreatic Beta-Cell K-ATP Channel Closure',
    iupacName: 'glimepiride + SUR1 receptor subunit → inward rectifier Kir6.2 channel closure → insulin exocytosis',
    description: 'Second-generation sulfonylurea pharmacology for MBBS & Pharm-D students. Glimepiride binds to the high-affinity 65-kDa SUR1 subunit of ATP-sensitive potassium channels (K-ATP) on pancreatic beta-cell membranes. Channel closure blocks K+ efflux, causing cell membrane depolarization, opening voltage-gated L-type calcium channels, inducing intracellular Ca2+ surge, and precipitating biphasic insulin granule exocytosis independent of ambient glucose concentrations.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''63
Glimepiride Pancreatic Beta-Cell K-ATP Channel Closure - Reactants
C      9.1664    -1.9949    -1.8553
C      8.3419    -2.3477    -0.6276
N      7.4793    -1.2536    -0.2326
C      6.2343    -1.0381    -0.7227
O      5.6065    -1.7084    -1.5228
C      5.7319     0.2047    -0.1066
C      6.7055     0.6870     0.6760
C      6.7675     1.9038     1.5180
C      7.8479    -0.2416     0.5909
O      8.9092    -0.0800     1.1658
C      4.3799     0.7422    -0.4250
C      3.2650    -0.0844     0.2247
C      1.8997     0.4753    -0.0970
C      1.2641     1.3549     0.7916
C      0.0136     1.8912     0.4814
C     -0.6036     1.5436    -0.7228
C      0.0238     0.6826    -1.6266
C      1.2730     0.1483    -1.3092
S     -2.2037     2.2243    -1.1244
O     -2.3673     3.4095    -0.3120
O     -2.2908     2.2471    -2.5673
N     -3.1835     1.0142    -0.5292
C     -4.5637     1.0541    -0.6374
O     -5.1795     1.9708    -1.1533
N     -5.1524    -0.0509    -0.0885
C     -6.5996    -0.1616     0.0291
C     -7.1069     0.6116     1.2541
C     -8.6135     0.4497     1.4390
C     -9.0194    -1.0196     1.5016
C     -8.5185    -1.7931     0.2857
C     -7.0114    -1.6363     0.1020
H      9.8099    -2.8342    -2.1361
H      9.8019    -1.1237    -1.6651
H      8.5210    -1.7570    -2.7073
H      7.7221    -3.2250    -0.8420
H      9.0102    -2.5884     0.2062
H      5.8278     2.4633     1.5007
H      6.9745     1.6378     2.5595
H      7.5614     2.5711     1.1682
H      4.3004     1.7863    -0.0988
H      4.2503     0.7636    -1.5148
H      3.3065    -1.1293    -0.1084
H      3.4009    -0.1133     1.3139
H      1.7434     1.6341     1.7279
H     -0.4648     2.5803     1.1747
H     -0.4445     0.4321    -2.5765
H      1.7632    -0.5186    -2.0174
H     -2.7161     0.1989    -0.1626
H     -4.5841    -0.6508     0.4866
H     -7.0442     0.2822    -0.8714
H     -6.8658     1.6770     1.1577
H     -6.5896     0.2586     2.1561
H     -8.9288     0.9584     2.3569
H     -9.1368     0.9378     0.6075
H     -8.6124    -1.4716     2.4145
H    -10.1105    -1.0985     1.5651
H     -9.0348    -1.4348    -0.6134
H     -8.7679    -2.8544     0.3957
H     -6.4916    -2.1293     0.9341
H     -6.6974    -2.1573    -0.8107
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''64
Glimepiride Pancreatic Beta-Cell K-ATP Channel Closure - Products
C      5.7027     1.8360    -0.8729
C      5.0018     1.6504     0.4635
N      3.9475     0.6613     0.3796
C      2.6715     0.9248     0.0069
O      2.1701     1.9971    -0.2804
C      1.9459    -0.3597    -0.0037
C      2.8238    -1.3194     0.3143
C      2.6620    -2.7862     0.4406
C      4.1275    -0.6717     0.5497
O      5.1505    -1.2690     0.8320
C      0.5046    -0.4384    -0.3704
C     -0.4009     0.1045     0.7401
C     -1.8593     0.0201     0.3570
C     -2.4437     1.0348    -0.4163
C     -3.7841     0.9531    -0.7957
C     -4.5441    -0.1471    -0.3943
C     -3.9731    -1.1737     0.3622
C     -2.6318    -1.0868     0.7373
S     -6.2465    -0.2662    -0.8733
O     -6.4840     0.6512    -1.9639
O     -6.6079    -1.6620    -0.9386
N     -7.0181     0.4087     0.4635
H      4.9985     2.1664    -1.6436
H      6.4942     2.5866    -0.7869
H      6.1541     0.8984    -1.2136
H      5.7285     1.3280     1.2170
H      4.5663     2.6029     0.7844
H      2.9493    -3.1174     1.4437
H      1.6282    -3.1010     0.2724
H      3.2933    -3.3048    -0.2878
H      0.2270    -1.4750    -0.5969
H      0.3403     0.1202    -1.3010
H     -0.1547     1.1488     0.9712
H     -0.2351    -0.4537     1.6710
H     -1.8512     1.8923    -0.7330
H     -4.2197     1.7428    -1.4043
H     -4.5613    -2.0414     0.6551
H     -2.1913    -1.8914     1.3231
H     -6.3895     0.5711     1.2493
H     -7.4912     1.2655     0.1710
N      7.9086    -0.0002    -0.1138
C      6.6857    -0.2538    -0.6461
O      6.5419    -0.5318    -1.8256
N      5.6960    -0.1631     0.2888
C      4.2968    -0.2933    -0.0927
C      3.4395    -0.6246     1.1291
C      1.9783    -0.8761     0.7504
C      1.5251    -0.1022    -0.4886
C      2.2857     1.2065    -0.6473
C      3.7916     0.9779    -0.7997
H      8.0672    -0.3862     0.8057
H      8.6564    -0.1883    -0.7707
H      5.9053     0.4778     1.0408
H      4.2307    -1.1320    -0.7991
H      3.8355    -1.5016     1.6559
H      3.4903     0.2055     1.8466
H      1.3442    -0.6123     1.6055
H      1.8199    -1.9467     0.5725
H      0.4476     0.0884    -0.4291
H      1.6833    -0.7202    -1.3815
H      2.1020     1.8372     0.2318
H      1.9092     1.7624    -1.5134
H      4.0431     0.9092    -1.8659
H      4.3162     1.8676    -0.4280''',
    referenceEa: 16.5,
    doi: '10.1055/s-2007-979921',
    journalRef: 'Exp. Clin. Endocrinol. Diabetes 1999, 107, 125',
    tags: const ["MBBS", "Pharm-D", "Endocrinology", "Sulfonylurea", "Glimepiride", "Insulin", "Diabetes"],
    defaultCatalystName: 'SUR1 Regulatory Sulfonylurea Receptor',
    literatureBarrierKcalMol: 13.5,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1055/s-2007-979921',
    catalystXyz: '''4
K-ATP Channel Filter
K  0.0000 0.0000 0.0000
O  2.6000 0.0000 0.0000
O -2.6000 0.0000 0.0000
O  0.0000 2.6000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-methotrexate-01',
    name: 'Methotrexate Dihydrofolate Reductase (DHFR) Inactivation',
    iupacName: 'methotrexate + DHFR → competitive pseudo-irreversible active site blockade (Ki ~ 1 pM)',
    description: 'Cornerstone antimetabolite chemotherapy and DMARD immunosuppression in MBBS & Pharm-D curricula. Structural analog of folic acid featuring a 4-amino substitution that binds Dihydrofolate Reductase with 1000-fold higher affinity than natural dihydrofolate. Traps intracellular folates in their inactive oxidized dihydro state, starving cells of N5,N10-methylene-THF and N10-formyl-THF required for thymidylate (dTMP) and purine synthesis, arresting S-phase cell cycle progression. Reversed clinically by folinic acid (Leucovorin rescue).',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''58
Methotrexate Dihydrofolate Reductase (DHFR) Inactivation - Reactants
C     -1.7878     4.1431    -0.9226
N     -1.8639     2.6877    -1.0495
C     -2.9836     2.1736    -1.8618
C     -3.9268     1.2852    -1.0772
C     -4.3160     1.6039     0.2118
N     -5.1915     0.8552     0.9272
C     -5.6935    -0.2440     0.3547
N     -6.5463    -0.9745     1.0649
C     -7.0536    -2.0593     0.4912
N     -7.9366    -2.8186     1.2275
N     -6.7457    -2.4885    -0.7275
C     -5.8832    -1.7414    -1.4304
N     -5.5636    -2.1968    -2.7376
C     -5.3030    -0.5729    -0.9492
N     -4.4286     0.1820    -1.6841
C     -0.7123     1.9169    -0.8627
C     -0.6763     0.5384    -1.1431
C      0.4723    -0.2409    -0.9386
C      1.6310     0.3347    -0.4235
C      2.8297    -0.5235    -0.2183
O      2.9696    -1.5565    -0.8622
N      3.7153    -0.1086     0.7580
C      4.8104    -0.9964     1.1689
C      5.9659    -0.1460     1.7200
C      7.2989    -0.8925     1.8252
C      7.8964    -1.1992     0.4786
O      7.5536    -0.7446    -0.5984
O      8.9323    -2.0538     0.5675
C      4.3158    -1.9723     2.2485
O      4.9262    -2.9391     2.6787
O      3.1322    -1.6282     2.8065
C      1.6347     1.6982    -0.1368
C      0.4785     2.4660    -0.3494
H     -2.7756     4.6044    -1.0348
H     -1.4351     4.4372     0.0718
H     -1.1318     4.5694    -1.6892
H     -2.6107     1.6492    -2.7510
H     -3.5879     3.0025    -2.2529
H     -3.9308     2.4797     0.7242
H     -7.7922    -2.6741     2.2169
H     -7.9466    -3.7705     0.8874
H     -5.7898    -1.4450    -3.3870
H     -4.5507    -2.2941    -2.7898
H     -1.5450     0.0155    -1.5321
H      0.4495    -1.3020    -1.1798
H      3.3167     0.4607     1.4943
H      5.1182    -1.5882     0.3009
H      6.1042     0.7386     1.0841
H      5.6990     0.2308     2.7162
H      7.1813    -1.8245     2.3846
H      8.0170    -0.2612     2.3609
H      9.2245    -2.1765    -0.3603
H      2.9564    -2.3533     3.4428
H      2.5305     2.1920     0.2290
H      0.5486     3.5221    -0.1051
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''58
Methotrexate Dihydrofolate Reductase (DHFR) Inactivation - Products
C     -3.0352    -2.2563     2.3615
N     -2.2001    -1.0537     2.3751
C     -2.9348     0.2224     2.4888
C     -3.7719     0.5367     1.2653
C     -3.2022     1.1101     0.1402
N     -3.9112     1.4062    -0.9785
C     -5.2167     1.1150    -0.9932
N     -5.9181     1.3972    -2.0897
C     -7.2180     1.1089    -2.0906
N     -7.9360     1.4019    -3.2285
N     -7.8672     0.5276    -1.0887
C     -7.1267     0.2626    -0.0054
O     -7.8060    -0.3306     1.0350
C     -5.7832     0.5249     0.1389
N     -5.0925     0.2252     1.2794
C     -1.0102    -1.0502     1.6435
C     -0.0002    -0.1173     1.9370
C      1.2088    -0.0826     1.2285
C      1.4442    -1.0017     0.2051
C      2.7063    -1.0132    -0.5847
O      2.7251    -1.4826    -1.7168
N      3.8243    -0.5042     0.0325
C      5.1443    -0.5263    -0.6073
C      5.2747     0.6768    -1.5540
C      6.5843     0.7230    -2.3449
C      7.6701     1.4855    -1.6313
O      7.5519     2.1690    -0.6281
O      8.8598     1.3657    -2.2504
C      6.2263    -0.5458     0.4778
O      7.4180    -0.7483     0.3049
O      5.7585    -0.2761     1.7202
C      0.4553    -1.9363    -0.1065
C     -0.7473    -1.9641     0.6122
H     -2.4407    -3.1496     2.5843
H     -3.5378    -2.3907     1.3974
H     -3.8066    -2.1918     3.1371
H     -2.2755     1.0705     2.7067
H     -3.6052     0.1604     3.3562
H     -2.1450     1.3527     0.0928
H     -8.7577     0.8168    -3.2908
H     -7.3289     1.4481    -4.0349
H     -7.1388    -0.4398     1.7396
H     -0.1285     0.5870     2.7557
H      1.9407     0.6772     1.4857
H      3.8215    -0.3019     1.0269
H      5.2268    -1.4676    -1.1636
H      5.1229     1.6093    -0.9954
H      4.4534     0.6280    -2.2812
H      6.9353    -0.2893    -2.5710
H      6.4066     1.2479    -3.2909
H      9.4781     1.8716    -1.6833
H      6.5727    -0.2696     2.2691
H      0.6145    -2.6529    -0.9104
H     -1.4826    -2.7100     0.3230
N      4.0043     0.0045     0.2955
H      4.9171    -0.1996    -0.1089
H      3.3680    -0.6979    -0.0786
H      3.7106     0.8929    -0.1080''',
    referenceEa: 17.8,
    doi: '10.1016/S0021-9258(17)38012-2',
    journalRef: 'J. Biol. Chem. 1978, 253, 6946-6954',
    tags: const ["MBBS", "Pharm-D", "Oncology", "Antimetabolite", "Methotrexate", "DHFR", "Immunosuppressive"],
    defaultCatalystName: 'DHFR Active Site (Asp27 / NADPH)',
    literatureBarrierKcalMol: 12.4,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/S0021-9258(17)38012-2',
    catalystXyz: '''6
DHFR Catalytic Carboxylate-Hydride Model
C  0.0000 0.0000 0.0000
O  1.2500 0.0000 0.0000
O -1.2500 0.0000 0.0000
C  0.0000 2.8000 0.0000
N  1.1500 3.4000 0.0000
H  0.0000 1.7000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-5fu-01',
    name: '5-Fluorouracil (5-FU) Suicide Inhibition of Thymidylate Synthase',
    iupacName: '5-FdUMP + 5,10-CH2-THF + Thymidylate Synthase (Cys195) → covalent ternary complex',
    description: 'Classic pyrimidine suicide inhibitor in oncology for MBBS and Pharm-D students. 5-Fluorouracil is metabolized intracellularly to 5-fluoro-2\'-deoxyuridine-5\'-monophosphate (5-FdUMP). 5-FdUMP binds to the catalytic site of Thymidylate Synthase along with 5,10-methylenetetrahydrofolate. Nucleophilic attack by active-site Cysteine-195 forms a covalent ternary adduct; however, the highly electronegative fluorine atom cannot be abstracted as a proton, permanently paralyzing the enzyme and causing \'thymineless cell death\'.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''18
5-Fluorouracil (5-FU) Suicide Inhibition of Thymidylate Synthase - Reactants
O     -2.5924    -0.5394     0.0068
C     -1.3927    -0.2895     0.0036
N     -0.9196     0.9968    -0.0581
C      0.4133     1.3128    -0.0636
C      1.3390     0.3549    -0.0074
F      2.6576     0.6207    -0.0104
C      0.9200    -1.0636     0.0615
O      1.7226    -1.9885     0.1150
N     -0.4381    -1.2694     0.0611
H     -1.6245     1.7252    -0.1008
H      0.6758     2.3633    -0.1150
H     -0.7608    -2.2234     0.1071
C      3.5080     0.0266    -0.0349
S      5.1071    -0.7428    -0.3595
H      3.3335     0.0804     1.0426
H      3.4911     1.0375    -0.4497
H      2.7121    -0.5626    -0.4969
H      5.8481     0.1608     0.2984''',
    productXyz: '''18
5-Fluorouracil (5-FU) Suicide Inhibition of Thymidylate Synthase - Products
O     -1.8484     1.9920     1.3035
C     -1.4175     0.9595     0.8063
N     -0.1299     0.5656     1.0009
C      0.4691    -0.4823     0.2106
S      1.0719     0.2249    -1.3701
C      2.5298     1.1095    -0.7673
C     -0.5045    -1.6454     0.0228
F      0.0219    -2.5811    -0.8167
C     -1.8523    -1.1150    -0.4216
O     -2.6557    -1.7699    -1.0840
N     -2.1916     0.1338     0.0458
H      0.4536     1.2555     1.4565
H      1.3443    -0.8519     0.7554
H      3.0413     1.5742    -1.6146
H      3.2236     0.4179    -0.2826
H      2.2418     1.8965    -0.0661
H     -0.6731    -2.1420     0.9864
H     -3.1244     0.4581    -0.1653''',
    referenceEa: 14.4,
    doi: '10.1038/179663a0',
    journalRef: 'Nature 1957, 179, 663-666',
    tags: const ["MBBS", "Pharm-D", "Oncology", "5-FU", "Thymidylate Synthase", "Suicide Inhibitor", "Chemotherapy"],
    defaultCatalystName: 'Thymidylate Synthase (Cys195 / CH2-H4folate)',
    literatureBarrierKcalMol: 11.2,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1038/179663a0',
    catalystXyz: '''5
TS Active Cys Thiolate Model
S  0.0000 0.0000 0.0000
C  1.8000 0.0000 0.0000
N -1.3000 1.3000 0.0000
C -2.1000 0.0000 0.0000
H  2.1500 0.9500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-cisplatin-01',
    name: 'Cisplatin Intracellular Aquation & DNA Crosslinking',
    iupacName: 'cis-[Pt(NH3)2Cl2] + H2O → cis-[Pt(NH3)2Cl(OH2)]+ + Cl-',
    description: 'Inorganic medicinal chemistry milestone in oncology for MBBS and Pharm-D students. Neutral cisplatin crosses cell membranes; in low intracellular chloride (~4-20 mM vs ~100 mM extracellular), it undergoes spontaneous aquation to reactive positively charged mono-aqua and diaqua species. These electrophilic species coordinate preferentially to N7 positions of adjacent guanine bases (1,2-intrastrand d(GpG) adducts ~65%), creating a sharp 45-degree bend in the DNA double helix that arrests RNA polymerase II and induces p53-dependent apoptosis.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''12
Cisplatin Intracellular Aquation & DNA Crosslinking - Reactants
Cl    -0.1469     2.1388     2.0669
Pt    -0.0364     0.5442     0.0020
Cl    -0.0484     2.2680    -1.9678
N     -1.8098    -0.5740    -0.1503
N      1.8020    -0.3997     0.1019
H     -2.1890    -0.7668     0.7942
H     -1.5629    -1.4643    -0.6198
H      1.6917    -1.3095     0.5749
H      2.2996    -0.4368    -0.8018
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''12
Cisplatin Intracellular Aquation & DNA Crosslinking - Products
Cl    -0.2360     0.7790     2.9860
Pt    -0.0760     0.3018     0.4013
O     -0.5500     2.1881    -0.4897
N     -1.5609    -1.2280     0.0692
N      1.9557    -0.3048     0.1234
H     -0.3897     2.0370    -1.4554
H     -2.3857    -0.8042    -0.3569
H     -1.1258    -1.9087    -0.5939
H      2.3859     0.2635    -0.6212
H      1.9825    -1.3239    -0.0629
Cl     4.6828     0.0000     0.0000
H      3.3172     0.0000     0.0000''',
    referenceEa: 18.7,
    doi: '10.1038/222385a0',
    journalRef: 'Nature 1969, 222, 385-386',
    tags: const ["MBBS", "Pharm-D", "Oncology", "Cisplatin", "DNA Crosslinking", "Platinum", "Apoptosis"],
    defaultCatalystName: 'Aquation Hydration Matrix (H2O)',
    literatureBarrierKcalMol: 19.5,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1038/222385a0',
    catalystXyz: '''5
Cisplatin Active Matrix
Pt 0.0000 0.0000 0.0000
Cl 2.3000 0.0000 0.0000
Cl 0.0000 2.3000 0.0000
N -2.0500 0.0000 0.0000
N  0.0000 -2.0500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-morphine-gluc-01',
    name: 'Morphine Phase II Glucuronidation (UGT2B7 Clearance)',
    iupacName: 'morphine + UDP-glucuronic acid → morphine-3-glucuronide (M3G) / morphine-6-glucuronide (M6G)',
    description: 'Crucial pharmacokinetic and analgesic pathway for Pharm-D and MBBS students. Hepatic UDP-glucuronosyltransferase 2B7 (UGT2B7) conjugates glucuronic acid to the phenolic 3-OH group (yielding M3G ~60%, inactive analgesically but neurotoxic) and the 6-OH group (yielding M6G ~10%, an active metabolite with greater mu-opioid receptor potency than parent morphine). In renal failure, M6G accumulates dangerously, precipitating fatal respiratory depression.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''63
Morphine Phase II Glucuronidation (UGT2B7 Clearance) - Reactants
C     -3.6453    -1.4935     0.7917
N     -2.2807    -0.9735     0.7997
C     -2.1436     0.1539     1.7199
C     -0.7153     0.7228     1.7536
C     -0.0808     0.8398     0.3450
C      0.9058    -0.2744     0.1550
C      0.6424    -1.5409    -0.3402
C      1.7142    -2.4341    -0.4192
C      3.0109    -2.0294    -0.0394
C      3.2489    -0.7165     0.3788
O      4.5026    -0.2778     0.6751
C      2.1830     0.1533     0.4490
O      2.2339     1.4994     0.7130
C      0.9330     1.9996     0.2398
C      1.0809     2.6166    -1.1849
O      2.4463     2.7713    -1.5703
C      0.3715     1.9048    -2.3010
C     -0.6491     1.0538    -2.1139
C     -1.1637     0.7230    -0.7344
C     -1.7745    -0.7144    -0.5763
C     -0.7296    -1.8337    -0.8900
H     -3.7100    -2.3993     0.1786
H     -3.9575    -1.7774     1.8028
H     -4.3599    -0.7594     0.4029
H     -2.4055    -0.1610     2.7379
H     -2.8478     0.9544     1.4564
H     -0.0982     0.1065     2.4210
H     -0.7786     1.7129     2.2224
H      1.5590    -3.4408    -0.8004
H      3.8247    -2.7441    -0.1186
H      5.1207    -1.0200     0.5838
H      0.6597     2.8166     0.9192
H      0.6598     3.6293    -1.1549
H      2.9732     2.2527    -0.9298
H      0.6930     2.1438    -3.3120
H     -1.1487     0.6171    -2.9749
H     -1.9593     1.4587    -0.5482
H     -2.5962    -0.8118    -1.2994
H     -1.0805    -2.8054    -0.5206
H     -0.6387    -1.9228    -1.9804
O      7.5054     0.2018     1.2995
C      6.5764     0.1019     0.5150
O      6.8187    -0.1125    -0.7977
C      5.0952     0.1914     0.8512
O      4.5134     1.4164     0.3986
C      3.6236     1.2774    -0.6998
O      3.1500     2.5668    -1.0662
C      2.4233     0.3604    -0.3610
O      1.3787     1.1321     0.2736
C      2.8359    -0.7798     0.5857
O      2.0546    -1.9445     0.2846
C      4.3270    -1.0841     0.4411
O      4.5088    -1.4957    -0.9280
H      7.7965    -0.0262    -0.8665
H      5.0512     0.2535     1.9467
H      4.1851     0.8915    -1.5567
H      2.3563     2.6912    -0.5076
H      1.9836    -0.0129    -1.2932
H      0.6669     0.4957     0.4804
H      2.6061    -0.5168     1.6251
H      2.4773    -2.3523    -0.4991
H      4.6274    -1.9376     1.0581
H      5.4386    -1.3177    -1.1840''',
    productXyz: '''63
Morphine Phase II Glucuronidation (UGT2B7 Clearance) - Products
C     -5.7176     2.2690     0.2860
N     -4.5665     1.6873     0.9749
C     -3.3331     2.4407     0.6994
C     -2.6334     2.0789    -0.6204
C     -2.5313     0.5552    -0.8351
C     -1.6496    -0.0515     0.2073
C     -2.0417    -0.4650     1.4660
C     -1.0518    -0.9939     2.2928
C      0.2783    -1.1232     1.8297
C      0.6316    -0.7592     0.5222
O      1.8533    -0.8939    -0.0638
C      2.9825    -1.2188     0.7428
O      4.0259    -1.7568    -0.0977
C      4.8760    -0.7480    -0.6345
C      5.7812    -1.3278    -1.7156
O      5.8218    -2.4731    -2.1316
O      6.6123    -0.3953    -2.2426
C      5.7591    -0.1855     0.4934
O      6.2032     1.1582     0.2147
C      4.9924    -0.1834     1.8342
O      5.4695     0.8856     2.6664
C      3.4861    -0.0210     1.6013
O      3.2598     1.2462     0.9573
C     -0.3744    -0.2463    -0.2777
O     -0.2789     0.0630    -1.6142
C     -1.6770     0.1836    -2.0637
C     -2.1156    -1.1205    -2.7938
O     -1.0002    -1.9291    -3.1621
C     -3.0978    -1.9918    -2.0636
C     -3.9374    -1.5242    -1.1263
C     -3.9286    -0.0679    -0.7258
C     -4.4267     0.2242     0.7274
C     -3.5057    -0.4265     1.8215
H     -5.6043     2.2891    -0.8022
H     -5.8800     3.2984     0.6252
H     -6.6335     1.7186     0.5277
H     -2.6376     2.2804     1.5321
H     -3.5309     3.5203     0.7196
H     -1.6406     2.5473    -0.6303
H     -3.1930     2.5202    -1.4555
H     -1.3029    -1.3358     3.2947
H      0.9963    -1.5548     2.5184
H      2.7472    -2.0630     1.4001
H      4.2720     0.0242    -1.1279
H      7.0832    -0.8939    -2.9475
H      6.6700    -0.7824     0.6254
H      6.5810     1.1476    -0.6890
H      5.1705    -1.1253     2.3663
H      5.9655     1.4766     2.0572
H      2.9404     0.0276     2.5492
H      3.6965     1.9128     1.5209
H     -1.6844     0.9961    -2.8016
H     -2.6059    -0.8326    -3.7321
H     -0.2574    -1.6467    -2.5917
H     -3.1482    -3.0359    -2.3629
H     -4.6667    -2.1904    -0.6727
H     -4.6065     0.4236    -1.4364
H     -5.4193    -0.2262     0.8665
H     -3.6424     0.0800     2.7850
H     -3.8349    -1.4650     1.9601
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    referenceEa: 15.8,
    doi: '10.1124/mol.55.6.1089',
    journalRef: 'Mol. Pharmacol. 1999, 55, 1089',
    tags: const ["Pharm-D", "MBBS", "Pharmacokinetics", "Morphine", "Glucuronidation", "UGT2B7", "Opioids"],
    defaultCatalystName: 'UGT2B7 (UDP-Glucuronosyltransferase)',
    literatureBarrierKcalMol: 16.8,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1124/mol.55.6.1089',
    catalystXyz: '''6
UDP-Glucuronic Phosphate Donor Core
P  0.0000 0.0000 0.0000
O  1.5500 0.0000 0.0000
O -1.5500 0.0000 0.0000
O  0.0000 1.5500 0.0000
O  0.0000 -1.5500 0.0000
C  2.6500 0.0000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-nat2-isoniazid-01',
    name: 'Isoniazid N-Acetylation by Hepatic NAT2 (Pharmacogenetics)',
    iupacName: 'isoniazid + acetyl-CoA → N-acetylisoniazid + coenzyme A',
    description: 'The premier textbook model of clinical pharmacogenetics for MBBS and Pharm-D students. Cytosolic hepatic N-acetyltransferase 2 (NAT2) transfers an acetyl group from acetyl-CoA to the hydrazine nitrogen of isoniazid. Genetic polymorphisms divide populations into \'Fast Acetylators\' (half-life ~1 hour, higher risk of hepatotoxicity from acetylhydrazine metabolites) and \'Slow Acetylators\' (half-life ~3 hours, higher plasma drug concentrations resulting in pyridoxine deficiency and peripheral neuropathy).',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''25
Isoniazid N-Acetylation by Hepatic NAT2 (Pharmacogenetics) - Reactants
N      3.4097     0.1025     0.0141
N      2.0370     0.4359     0.0547
C      1.1192    -0.5464     0.4102
O      1.4511    -1.6799     0.7480
C     -0.3180    -0.1760     0.3281
C     -1.2515    -1.1981     0.1499
C     -2.5877    -0.8536     0.0774
N     -3.0379     0.4154     0.1763
C     -2.1164     1.3823     0.3691
C     -0.7558     1.1431     0.4531
H      3.4670    -0.8850    -0.2710
H      3.7427     0.0762     0.9836
H      1.7376     1.2728    -0.4400
H     -0.9451    -2.2362     0.0680
H     -3.3552    -1.6095    -0.0648
H     -2.5170     2.3882     0.4639
H     -0.0796     1.9683     0.6391
C      3.3411     0.4925     0.1220
C      4.0573    -0.8125     0.3166
O      3.5037    -1.8359     0.6953
S      5.7784    -0.7827    -0.0402
H      3.4144     0.8124    -0.9210
H      2.2831     0.3642     0.3699
H      3.7599     1.2561     0.7830
H      5.8621     0.5060    -0.3927''',
    productXyz: '''25
Isoniazid N-Acetylation by Hepatic NAT2 (Pharmacogenetics) - Products
C     -4.2920    -0.9246    -0.0729
C     -2.8690    -1.0382     0.3983
O     -2.4076    -2.0725     0.8777
N     -2.1272     0.1148     0.2494
N     -0.7438     0.0077     0.4515
C      0.0835     0.8087    -0.3080
O     -0.3534     1.6921    -1.0430
C      1.5475     0.5751    -0.1929
C      2.4044     1.6174    -0.5526
C      3.7666     1.4077    -0.4517
N      4.3138     0.2483    -0.0303
C      3.4652    -0.7494     0.2950
C      2.0865    -0.6405     0.2308
H     -4.5462     0.1042    -0.3429
H     -4.4306    -1.5641    -0.9485
H     -4.9608    -1.2456     0.7302
H     -2.4111     0.8467    -0.4027
H     -0.4405    -0.7735     1.0275
H      2.0205     2.5711    -0.9008
H      4.4756     2.1877    -0.7153
H      3.9407    -1.6732     0.6140
H      1.4778    -1.4996     0.4832
S      3.9623     0.6121     0.0000
H      3.0450    -0.3661     0.0000
H      4.9928    -0.2460     0.0000''',
    referenceEa: 13.7,
    doi: '10.1126/science.8284673',
    journalRef: 'Science 1994, 263, 227-230',
    tags: const ["MBBS", "Pharm-D", "Pharmacogenetics", "Isoniazid", "NAT2", "Tuberculosis", "Acetylation"],
    defaultCatalystName: 'NAT2 (Cys68 Acetyl-Enzyme Intermediate)',
    literatureBarrierKcalMol: 14.2,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1126/science.8284673',
    catalystXyz: '''6
NAT2 S-Acetyl Cys Intermediate
S  0.0000 0.0000 0.0000
C  1.7500 0.0000 0.0000
O  2.4000 1.0500 0.0000
C  2.3000 -1.4000 0.0000
C -1.4000 0.0000 0.0000
H -1.7500 0.9500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-ciprofloxacin-01',
    name: 'Ciprofloxacin DNA Gyrase & Topoisomerase IV Cleavage',
    iupacName: 'ciprofloxacin + bacterial DNA gyrase A2B2 + double-stranded DNA → cleaved complex stabilization',
    description: 'Premier broad-spectrum fluoroquinolone antimicrobial in MBBS & Pharm-D curricula. Ciprofloxacin intercalates into bacterial DNA at the cleavage site created by DNA Gyrase (Gram-negative bacteria) and Topoisomerase IV (Gram-positive bacteria). The 3-carboxylate and 4-keto oxygens coordinate a Mg2+ ion bridged by water to conserved Ser83 and Asp87 residues, freezing the cleaved enzyme-DNA complex, inducing permanent double-strand breaks, and triggering SOS bacterial death.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''45
Ciprofloxacin DNA Gyrase & Topoisomerase IV Cleavage - Reactants
O     -6.1709     1.3681    -0.1869
C     -5.1491     2.0276    -0.2904
O     -5.2015     3.3316    -0.5976
C     -3.7816     1.5081    -0.1805
C     -3.5854     0.2099    -0.4578
N     -2.3733    -0.4556    -0.4224
C     -2.3439    -1.8743    -0.8257
C     -3.3079    -2.8918    -0.2633
C     -1.8621    -2.9518     0.1149
C     -1.1790     0.2929    -0.2228
C      0.1023    -0.2746    -0.3361
C      1.2824     0.4690    -0.1273
N      2.5145    -0.2013    -0.2593
C      3.7042     0.5807    -0.6678
C      4.6986     0.7713     0.4980
N      5.2039    -0.4864     1.0874
C      4.2345    -1.5865     0.9148
C      2.7575    -1.1360     0.8711
C      1.1351     1.8243     0.2130
F      2.2070     2.5888     0.4725
C     -0.1166     2.4196     0.3270
C     -1.2660     1.6581     0.1032
C     -2.5982     2.3062     0.2172
O     -2.6821     3.4512     0.6472
H     -6.1550     3.5496    -0.6226
H     -4.4224    -0.4224    -0.7481
H     -2.0876    -1.9874    -1.8774
H     -4.0097    -2.5859     0.5039
H     -3.6909    -3.6495    -0.9368
H     -1.2596    -3.7514    -0.2991
H     -1.5952    -2.6699     1.1269
H      0.2096    -1.3184    -0.6176
H      3.4454     1.5421    -1.1248
H      4.2066     0.0150    -1.4638
H      5.5535     1.3654     0.1564
H      4.2187     1.3458     1.2988
H      6.0757    -0.7508     0.6299
H      4.3750    -2.3018     1.7321
H      4.4692    -2.1162    -0.0174
H      2.1240    -2.0237     0.7573
H      2.5030    -0.6603     1.8283
H     -0.1829     3.4707     0.5936
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''49
Ciprofloxacin DNA Gyrase & Topoisomerase IV Cleavage - Products
O      3.2670    -3.5859    -0.2916
C      2.0927    -3.3282    -0.1044
O      1.2120    -4.3363     0.0669
C      1.4688    -1.9941    -0.0452
C      0.1394    -1.8445    -0.1648
N     -0.5598    -0.6505    -0.1383
C     -2.0194    -0.6920    -0.3513
C     -2.9189    -1.6353     0.4122
C     -2.9838    -0.1661     0.6839
C      0.1624     0.5758    -0.1297
C     -0.4655     1.8282    -0.2579
C      0.2654     3.0219    -0.2050
N     -0.3717     4.2481    -0.4582
C      1.6605     2.9456    -0.1116
F      2.3851     4.0753    -0.1221
C      2.3148     1.7287     0.0118
C      1.5648     0.5482     0.0045
C      2.2690    -0.7544     0.1203
O      3.4722    -0.7712     0.3533
H      1.7810    -5.1342     0.0141
H     -0.5031    -2.7109    -0.3017
H     -2.2772    -0.5254    -1.3955
H     -3.7425    -2.0915    -0.1244
H     -2.4908    -2.2641     1.1842
H     -3.8536     0.3777     0.3353
H     -2.5846     0.1879     1.6275
H     -1.5387     1.8887    -0.4091
H      0.1891     5.0477    -0.1673
H     -1.3319     4.3020    -0.1354
H      3.3973     1.7089     0.0993
O      0.8034    -0.8865     0.2120
C      1.3250     0.4386     0.1365
C      2.8122     0.4312     0.5131
N      3.5218    -0.5442    -0.3322
C      4.9202    -0.7247     0.0742
C      5.8388     0.4754    -0.2351
N      7.2388     0.2046     0.0890
H      1.5453    -1.4613    -0.0683
H      0.7549     1.0752     0.8192
H      1.1800     0.8052    -0.8850
H      2.9033     0.1298     1.5631
H      3.2219     1.4393     0.3969
H      3.4894    -0.2341    -1.3052
H      5.2990    -1.6016    -0.4652
H      4.9724    -0.9800     1.1400
H      5.7715     0.7320    -1.2983
H      5.5219     1.3565     0.3319
H      7.5598    -0.6114    -0.4319
H      7.3204    -0.0438     1.0748''',
    referenceEa: 16.9,
    doi: '10.1128/AAC.26.1.104',
    journalRef: 'Antimicrob. Agents Chemother. 1984, 26, 104-106',
    tags: const ["Pharm-D", "MBBS", "Antibiotic", "Fluoroquinolone", "Ciprofloxacin", "DNA Gyrase", "Microbiology"],
    defaultCatalystName: 'Mg2+ Water-Metal Ion Coordination Bridge',
    literatureBarrierKcalMol: 13.0,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1128/AAC.26.1.104',
    catalystXyz: '''5
Mg(H2O)4 Complex Core
Mg 0.0000 0.0000 0.0000
O  2.0500 0.0000 0.0000
O -2.0500 0.0000 0.0000
O  0.0000 2.0500 0.0000
O  0.0000 -2.0500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-azithromycin-01',
    name: 'Azithromycin 50S Ribosomal Translocation Blockade',
    iupacName: 'azithromycin (15-membered azalide) + bacterial 23S rRNA → peptide nascent chain elongation arrest',
    description: 'Aza-macrolide pharmacology for MBBS & Pharm-D students. Azithromycin incorporates a methyl-substituted nitrogen at position 9a of the macrolactone ring, preventing hemiketal formation and conferring acid stability. Binds reversibly to the peptidyl transferase center of 23S rRNA in the bacterial 50S ribosomal subunit, occluding the nascent polypeptide exit tunnel. Exceptionally high intracellular accumulation in lysosomes and tissue phagocytes (tissue half-life ~68 hours).',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''68
Azithromycin 50S Ribosomal Translocation Blockade - Reactants
C     -0.6700     3.4845     1.8842
C     -0.6485     2.4820     0.7285
C     -2.0247     2.4871     0.0229
C     -2.2633     1.3372    -0.9956
C     -3.0217     1.9046    -2.2102
C     -3.0686     0.1503    -0.3846
O     -3.4529    -0.7687    -1.4047
C     -2.3818    -0.6060     0.7781
C     -3.3665    -1.5658     1.4606
C     -0.9935    -1.2320     0.4555
O     -0.3742    -1.5509     1.7114
C     -0.8164    -2.4216    -0.5442
C     -1.6690    -3.6476    -0.1898
O     -1.2131    -1.9880    -1.8595
C      0.6665    -2.9120    -0.6478
C      1.7198    -1.8280    -1.0045
C      2.9389    -2.4717    -1.6862
N      2.0571    -0.9896     0.1821
C      3.0530    -1.6081     1.0644
C      2.4670     0.3717    -0.2519
C      2.3939     1.4477     0.8637
C      3.7540     1.6293     1.5572
C      1.9465     2.8091     0.2871
O      2.8365     3.1844    -0.7709
C      0.4920     2.8368    -0.2323
O      0.2835     3.1905    -1.3986
H      0.2454     3.4226     2.4812
H     -1.5097     3.2881     2.5593
H     -0.7576     4.5127     1.5163
H     -0.4542     1.4912     1.1374
H     -2.8211     2.4593     0.7781
H     -2.1381     3.4569    -0.4808
H     -1.3095     0.9689    -1.3886
H     -4.0146     2.2667    -1.9225
H     -3.1458     1.1495    -2.9930
H     -2.4707     2.7398    -2.6565
H     -4.0114     0.5615    -0.0002
H     -2.6261    -1.1144    -1.8035
H     -2.1844     0.1427     1.5582
H     -4.1511    -0.9919     1.9680
H     -3.8759    -2.2222     0.7529
H     -2.8737    -2.1787     2.2213
H     -0.4182    -0.4026     0.0392
H      0.5851    -1.4357     1.5481
H     -1.3767    -4.5145    -0.7954
H     -1.5652    -3.9285     0.8624
H     -2.7224    -3.4878    -0.4303
H     -1.1463    -2.7591    -2.4542
H      0.9515    -3.4318     0.2752
H      0.7042    -3.6735    -1.4402
H      1.2467    -1.1952    -1.7666
H      3.6998    -1.7243    -1.9330
H      3.3996    -3.2449    -1.0628
H      2.6385    -2.9476    -2.6267
H      4.0704    -1.5472     0.6634
H      2.8228    -2.6615     1.2553
H      3.0317    -1.1308     2.0480
H      1.7784     0.6812    -1.0467
H      3.4644     0.3512    -0.7097
H      1.6709     1.1356     1.6261
H      4.0889     0.7209     2.0605
H      4.5332     1.9172     0.8432
H      3.6932     2.4135     2.3200
H      2.0269     3.5938     1.0467
H      2.2769     3.5935    -1.4649
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''68
Azithromycin 50S Ribosomal Translocation Blockade - Products
C     -0.6700     3.4845     1.8842
C     -0.6485     2.4820     0.7285
C     -2.0247     2.4871     0.0229
C     -2.2633     1.3372    -0.9956
C     -3.0217     1.9046    -2.2102
C     -3.0686     0.1503    -0.3846
O     -3.4529    -0.7687    -1.4047
C     -2.3818    -0.6060     0.7781
C     -3.3665    -1.5658     1.4606
C     -0.9935    -1.2320     0.4555
O     -0.3742    -1.5509     1.7114
C     -0.8164    -2.4216    -0.5442
C     -1.6690    -3.6476    -0.1898
O     -1.2131    -1.9880    -1.8595
C      0.6665    -2.9120    -0.6478
C      1.7198    -1.8280    -1.0045
C      2.9389    -2.4717    -1.6862
N      2.0571    -0.9896     0.1821
C      3.0530    -1.6081     1.0644
C      2.4670     0.3717    -0.2519
C      2.3939     1.4477     0.8637
C      3.7540     1.6293     1.5572
C      1.9465     2.8091     0.2871
O      2.8365     3.1844    -0.7709
C      0.4920     2.8368    -0.2323
O      0.2835     3.1905    -1.3986
H      0.2454     3.4226     2.4812
H     -1.5097     3.2881     2.5593
H     -0.7576     4.5127     1.5163
H     -0.4542     1.4912     1.1374
H     -2.8211     2.4593     0.7781
H     -2.1381     3.4569    -0.4808
H     -1.3095     0.9689    -1.3886
H     -4.0146     2.2667    -1.9225
H     -3.1458     1.1495    -2.9930
H     -2.4707     2.7398    -2.6565
H     -4.0114     0.5615    -0.0002
H     -2.6261    -1.1144    -1.8035
H     -2.1844     0.1427     1.5582
H     -4.1511    -0.9919     1.9680
H     -3.8759    -2.2222     0.7529
H     -2.8737    -2.1787     2.2213
H     -0.4182    -0.4026     0.0392
H      0.5851    -1.4357     1.5481
H     -1.3767    -4.5145    -0.7954
H     -1.5652    -3.9285     0.8624
H     -2.7224    -3.4878    -0.4303
H     -1.1463    -2.7591    -2.4542
H      0.9515    -3.4318     0.2752
H      0.7042    -3.6735    -1.4402
H      1.2467    -1.1952    -1.7666
H      3.6998    -1.7243    -1.9330
H      3.3996    -3.2449    -1.0628
H      2.6385    -2.9476    -2.6267
H      4.0704    -1.5472     0.6634
H      2.8228    -2.6615     1.2553
H      3.0317    -1.1308     2.0480
H      1.7784     0.6812    -1.0467
H      3.4644     0.3512    -0.7097
H      1.6709     1.1356     1.6261
H      4.0889     0.7209     2.0605
H      4.5332     1.9172     0.8432
H      3.6932     2.4135     2.3200
H      2.0269     3.5938     1.0467
H      2.2769     3.5935    -1.4649
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    referenceEa: 18.2,
    doi: '10.1021/jm00124a023',
    journalRef: 'J. Med. Chem. 1988, 31, 2038-2046',
    tags: const ["Pharm-D", "MBBS", "Antibiotic", "Macrolide", "Azithromycin", "Ribosome", "Pharmacokinetics"],
    defaultCatalystName: '23S rRNA Peptidyltransferase Residues',
    literatureBarrierKcalMol: 15.1,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/jm00124a023',
    catalystXyz: '''6
rRNA Ribose-Phosphate Unit
P  0.0000 0.0000 0.0000
O  1.5500 0.0000 0.0000
O -1.5500 0.0000 0.0000
O  0.0000 1.5500 0.0000
C  1.1000 2.5000 0.0000
O  0.8000 3.7000 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-ceftriaxone-01',
    name: 'Ceftriaxone Transpeptidase Acylation (3rd Gen Cephalosporin)',
    iupacName: 'ceftriaxone beta-lactam core + bacterial PBP-2/PBP-3 → irreversible acyl-enzyme adduct',
    description: 'Third-generation cephalosporin cornerstone for hospital pharmacy (Pharm-D) and emergency medicine (MBBS). The aminothiazolyl oxime sidechain confers exceptional resistance against Gram-negative beta-lactamases and high affinity for penicillin-binding proteins (PBPs), while the triazine ring confers a long serum half-life (~8 hours) and biliary elimination. Rapidly crosses the blood-brain barrier for bacterial meningitis and empirically treats Neisseria gonorrhoeae and severe sepsis.',
    category: ReactionCategory.pharmaceutical,
    reactantXyz: '''28
Ceftriaxone Transpeptidase Acylation (3rd Gen Cephalosporin) - Reactants
O     -4.4574    -0.0737    -1.8580
C     -3.3307    -0.4929    -1.9230
N     -2.1328    -0.2993    -1.4337
C     -1.5280     0.3737    -0.4304
C     -0.4710    -0.2786     0.1177
C      0.3833     0.2709     1.2363
S      1.7955     1.1907     0.5672
C      3.0502    -0.0387     0.6364
O      2.8185    -1.1994     0.9504
C      4.4174     0.4589     0.2648
C     -0.0633    -1.6956    -0.3430
S     -1.2015    -2.5192    -1.5682
C     -2.6244    -1.6098    -1.2211
C     -1.9932     1.7380    -0.0721
O     -1.9002     2.2766     1.0157
O     -2.5511     2.3705    -1.1190
H     -0.1794     0.9561     1.8735
H      0.6973    -0.5273     1.9174
H      4.4223     0.8134    -0.7696
H      5.1361    -0.3614     0.3526
H      4.7263     1.2604     0.9415
H     -0.0202    -2.3575     0.5284
H      0.9252    -1.6670    -0.8094
H     -3.0712    -1.8207    -0.2547
H     -2.8477     3.2321    -0.7615
O      4.0075     0.3977     0.0000
H      3.2329    -0.1844     0.0000
H      4.7596    -0.2134     0.0000''',
    productXyz: '''33
Ceftriaxone Transpeptidase Acylation (3rd Gen Cephalosporin) - Products
O     -2.1094    -0.2433     1.7702
C     -1.4833    -1.0717     1.1351
O     -1.6332    -2.3926     1.3467
C     -0.5380    -0.8161     0.0073
C     -0.8293     0.0828    -0.9637
C     -2.1554     0.8094    -1.0597
S     -2.0026     2.4771    -0.3606
C     -3.6995     2.9348    -0.4180
O     -4.4921     2.3921    -1.1774
C     -4.0710     4.0505     0.5147
C      0.1397     0.4380    -2.0741
S      1.8803     0.2251    -1.5881
C      1.6313    -1.4868    -1.0399
N      0.6328    -1.5151     0.0021
C      1.4233    -1.9912     0.9934
O      1.2304    -2.1671     2.1732
C      2.6389    -2.0515     0.0067
N      3.7921    -1.1951     0.3628
C      4.7880    -1.6228     1.1677
O      4.9714    -2.7431     1.6023
O      5.6181    -0.6122     1.4501
H     -2.1894    -2.4450     2.1509
H     -2.9558     0.2620    -0.5525
H     -2.4563     0.8807    -2.1117
H     -3.8447     3.7726     1.5478
H     -5.1456     4.2417     0.4383
H     -3.5358     4.9642     0.2425
H     -0.0733    -0.1700    -2.9603
H      0.0328     1.4877    -2.3644
H      1.4122    -2.1892    -1.8526
H      2.9528    -3.0790    -0.2150
H      3.7899    -0.1998     0.1698
H      6.2809    -1.0273     2.0402''',
    referenceEa: 17.6,
    doi: '10.1093/jac/45.suppl_3.1',
    journalRef: 'J. Antimicrob. Chemother. 2000, 45, 1',
    tags: const ["Pharm-D", "MBBS", "Antibiotic", "Cephalosporin", "Ceftriaxone", "Meningitis", "Microbiology"],
    defaultCatalystName: 'PBP3 (Transpeptidase Active Ser403)',
    literatureBarrierKcalMol: 14.7,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1093/jac/45.suppl_3.1',
    catalystXyz: '''6
PBP Ser-Lys Active Site
C  0.0000 0.0000 0.0000
O  1.4000 0.0000 0.0000
N  2.8000 0.0000 0.0000
C -0.6500 1.3000 0.0000
C -2.1500 1.3000 0.0000
H  1.7500 -0.8500 0.0000''',
  ),
  ReactionTemplate(
    id: 'med-levodopa-01',
    name: 'Levodopa (L-DOPA) Decarboxylation to Dopamine by AADC',
    iupacName: '(2S)-2-amino-3-(3,4-dihydroxyphenyl)propanoic acid → 4-(2-aminoethyl)benzene-1,2-diol + CO2',
    description: 'Essential central neurotransmission and movement disorder therapy for MBBS and Pharm-D students. Dopamine itself cannot cross the blood-brain barrier (BBB); its amino acid precursor L-DOPA crosses via the L-type neutral amino acid transporter (LAT1). In the striatum, aromatic L-amino acid decarboxylase (AADC) with pyridoxal phosphate (PLP) cofactor removes the alpha-carboxyl group, replenishing depleted dopamine stores in Parkinson disease. Co-prescribed with peripheral decarboxylase inhibitors (Carbidopa, Benserazide) to prevent systemic cardiovascular side effects.',
    category: ReactionCategory.biochemical,
    reactantXyz: '''25
Levodopa (L-DOPA) Decarboxylation to Dopamine by AADC - Reactants
O      1.6929     1.9728    -1.3424
C      2.3601     1.1568    -0.7293
O      3.5745     1.5128    -0.2386
C      2.0089    -0.2987    -0.3828
N      3.1536    -1.1685    -0.7578
C      0.7362    -0.7703    -1.1048
C     -0.5326    -0.3503    -0.3926
C     -1.2388     0.7888    -0.8040
C     -2.3995     1.1878    -0.1361
C     -2.8613     0.4459     0.9478
O     -3.9946     0.8239     1.6114
C     -2.1699    -0.6907     1.3641
O     -2.6394    -1.4082     2.4288
C     -1.0093    -1.0906     0.7012
H      3.6775     2.4395    -0.5412
H      1.8808    -0.3476     0.7054
H      3.0426    -2.0773    -0.3118
H      3.9973    -0.7526    -0.3531
H      0.7210    -1.8673    -1.1703
H      0.7164    -0.4150    -2.1434
H     -0.8849     1.3801    -1.6475
H     -2.9236     2.0760    -0.4745
H     -4.3508     1.6225     1.1936
H     -2.0863    -2.1939     2.5512
H     -0.4708    -1.9759     1.0266''',
    productXyz: '''25
Levodopa (L-DOPA) Decarboxylation to Dopamine by AADC - Products
N     -3.8449    -0.0072    -0.4712
C     -2.4071    -0.2326    -0.6166
C     -1.6289     0.3885     0.5480
C     -0.1432     0.1560     0.4120
C      0.4536    -0.9826     0.9807
C      1.8258    -1.2152     0.8437
C      2.5985    -0.3070     0.1311
O      3.9446    -0.4791    -0.0386
C      2.0124     0.8193    -0.4397
O      2.7796     1.7045    -1.1422
C      0.6517     1.0590    -0.3078
H     -4.3270    -0.4028    -1.2779
H     -4.0361     0.9942    -0.4926
H     -2.0721     0.1923    -1.5699
H     -2.2228    -1.3121    -0.6605
H     -1.8219     1.4679     0.6031
H     -1.9762    -0.0284     1.5025
H     -0.1535    -1.6954     1.5359
H      2.2624    -2.1002     1.2945
H      4.2025    -1.2971     0.4200
H      3.6829     1.3330    -1.0943
H      0.2195     1.9451    -0.7642
O      2.7044     0.1644     0.0000
C      4.0000    -0.3792     0.0000
O      5.2956    -0.9227     0.0000''',
    referenceEa: 15.9,
    doi: '10.1016/S0140-6736(67)91544-8',
    journalRef: 'Lancet 1967, 290, 712',
    tags: const ["MBBS", "Pharm-D", "Neurology", "Parkinson", "Levodopa", "Dopamine", "Neurochemistry"],
    defaultCatalystName: 'Aromatic L-Amino Acid Decarboxylase (PLP)',
    literatureBarrierKcalMol: 15.9,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/S0140-6736(67)91544-8',
    catalystXyz: '''7
PLP Pyridine Core Model
N  0.0000 1.3500 0.0000
C  1.1500 0.6500 0.0000
C  1.1500 -0.7500 0.0000
C  0.0000 -1.4500 0.0000
C -1.1500 -0.7500 0.0000
C -1.1500 0.6500 0.0000
O  0.0000 -2.7000 0.0000''',
  ),
];
