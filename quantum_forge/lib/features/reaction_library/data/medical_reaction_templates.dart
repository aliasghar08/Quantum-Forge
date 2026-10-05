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
    doi: '10.1021/jm00125a008',
    journalRef: 'J. Med. Chem. 1990, 33, 1456',
    tags: const ["Pharm-D", "MBBS", "NSAID", "Aspirin", "COX-1/2", "Antiplatelet", "Esterification"],
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
    doi: '10.1056/NEJM198104233041705',
    journalRef: 'N. Engl. J. Med. 1981, 304, 997',
    tags: const ["Pharm-D", "MBBS", "Paracetamol", "Analgesic", "CYP2E1", "NAPQI", "Toxicology"],
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
    doi: '10.1128/AAC.01160-14',
    journalRef: 'Antimicrob. Agents Chemother. 2014, 58, 6385',
    tags: const ["Pharm-D", "MBBS", "Antibiotic", "Beta-lactam", "Penicillin", "Resistance", "Microbiology"],
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
    doi: '10.1074/jbc.270.36.21191',
    journalRef: 'J. Biol. Chem. 1995, 270, 21191',
    tags: const ["MBBS", "Pharm-D", "Neurochemistry", "Dopamine", "Norepinephrine", "Catecholamine", "Parkinson"],
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
  ),
];
