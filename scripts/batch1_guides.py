import os
import re

out_dir = "quantum_forge/web/guides"
os.makedirs(out_dir, exist_ok=True)

from generate_all_8_guides import create_guide_html

# ==============================================================================
# GUIDE 1: Warfarin Pharmacogenomics & VKORC1 Kinetics
# ==============================================================================
slug1 = "warfarin-cyp2c9-vkorc1-dosing.html"
title1 = "Warfarin Pharmacogenomics: VKORC1 Inhibition, CYP2C9*2/*3 Variants & INR Anticoagulation Kinetics"
meta_title1 = "Warfarin Pharmacogenomics: VKORC1 & CYP2C9 Dosing Kinetics"
meta_desc1 = "Comprehensive clinical monograph on Warfarin pharmacogenomics: VKORC1 -1639G>A promoter polymorphism, CYP2C9*2/*3 clearance reduction, Vitamin K epoxide cycle kinetics, and algorithms for safe INR anticoagulation."
category1 = "Pharmacogenomics & Anticoagulation"
read_time1 = "14 min read"

body1 = """
      <h2>1. Executive Summary & Clinical Anticoagulation Landscape</h2>
      <p>
        Warfarin (Coumadin) is an oral 4-hydroxycoumarin anticoagulant prescribed globally for the prophylaxis and treatment of deep vein thrombosis (DVT), pulmonary embolism (PE), systemic thromboembolism in non-valvular atrial fibrillation (NVAF), and thromboembolic prophylaxis following mechanical prosthetic heart valve replacement. Despite the emergence of direct oral anticoagulants (DOACs; such as Apixaban, Rivaroxaban, and Dabigatran), Warfarin remains the mandatory standard of care in patients with mechanical heart valves, moderate-to-severe rheumatic mitral stenosis, and antiphospholipid antibody syndrome (APS).
      </p>
      <p>
        However, Warfarin is characterized by a notoriously narrow therapeutic index (target International Normalized Ratio [INR] typically 2.0–3.0, or 2.5–3.5 for mechanical mitral valves). Subtherapeutic exposure (INR &lt; 2.0) drastically escalates ischemic stroke and thromboembolic risk, whereas supratherapeutic over-anticoagulation (INR &gt; 4.0–5.0) carries catastrophic risks of fatal intracranial hemorrhage (ICH), gastrointestinal bleeding, and retroperitoneal hematoma. Over 50% of inter-individual dose variability (ranging from &lt;1.5 mg/day to &gt;12 mg/day) is governed by genetic polymorphisms within two key loci: <strong>Vitamin K Epoxide Reductase Complex Subunit 1 (VKORC1)</strong> and the <strong>Cytochrome P450 2C9 (CYP2C9)</strong> enzyme.
      </p>

      <h2>2. Enzymatic Mechanism: The Vitamin K Redox Cycle & Gamma-Carboxylation</h2>
      <p>
        Coagulation cascade factors II (prothrombin), VII, IX, and X, alongside the natural endogenous anticoagulant proteins C and S, are synthesized in hepatocytes as inactive zymogen precursors. To achieve biological function in primary and secondary hemostasis, these proteins must undergo post-translational gamma-carboxylation of their amino-terminal glutamic acid (Glu) residues into gamma-carboxyglutamic acid (Gla) domains.
      </p>
      <p>
        This carboxylation is catalyzed by the microsomal enzyme <strong>gamma-glutamyl carboxylase (GGCX)</strong>. The Gla residues possess paired, bidentate carboxylate groups capable of chelating divalent calcium ions (Ca<sup>2+</sup>). Calcium chelation induces a critical conformational rearrangement that exposes hydrophobic membrane-anchoring loops, enabling the clotting factors to assemble into tenase and prothrombinase complexes on the negatively charged phosphatidylserine surfaces of activated platelets.
      </p>

      <div class="math-block">
        [Vitamin K Redox Cycle Reaction]:<br>
        1. Glu-Factor + CO2 + O2 + Vit K Hydroquinone (KH2) &rarr;[GGCX]&rarr; Gla-Factor + H2O + Vit K 2,3-Epoxide (KO)<br>
        2. Vit K 2,3-Epoxide (KO) + 2 e- (DTT/Trx) &rarr;[VKORC1]&rarr; Vit K Quinone (K)<br>
        3. Vit K Quinone (K) + 2 e- &rarr;[VKORC1 / NQO1]&rarr; Vit K Hydroquinone (KH2) [Active Cofactor]
      </div>

      <p>
        During the GGCX reaction, the obligate electron donor—<strong>reduced Vitamin K hydroquinone (KH2)</strong>—is stoichiometrically oxidized into <strong>Vitamin K 2,3-epoxide (KO)</strong>. To sustain ongoing clotting factor carboxylation, this epoxide must be enzymatically recycled back to the quinone and subsequently to the hydroquinone. This two-step reduction is mediated predominantly by <strong>VKORC1</strong>, a 163-amino acid polytopic endoplasmic reticulum transmembrane protein (PDB: 6WVX, 3IRW).
      </p>
      <p>
        Warfarin acts as a potent, non-covalent, competitive inhibitor of VKORC1. By occupying the intracellular hydrophobic substrate-binding pocket of VKORC1, Warfarin traps the enzyme in an inactive state, depleting intrahepatic reserves of Vitamin K hydroquinone. Consequently, newly synthesized factors II, VII, IX, and X exit the Golgi apparatus in an uncarboxylated, decarboxylated state—termed <strong>PIVKA</strong> (Proteins Induced by Vitamin K Absence/Antagonism). PIVKA molecules are completely inert in coagulation due to their inability to chelate calcium or bind activated platelet phospholipid membranes.
      </p>

      <h2>3. Enantiomer Pharmacokinetics & CYP2C9 Catalytic Degradation</h2>
      <p>
        Commercial Warfarin is administered as an equimolar racemic mixture of two enantiomers: <strong>(R)-warfarin</strong> and <strong>(S)-warfarin</strong>. The (S)-enantiomer is roughly <strong>3 to 5 times more potent</strong> as an inhibitor of VKORC1 than the (R)-enantiomer. Consequently, the pharmacokinetic clearance of (S)-warfarin is the primary determinant of in vivo anticoagulation intensity.
      </p>
      <p>
        While (R)-warfarin undergoes multi-pathway elimination catalyzed by CYP1A2, CYP3A4, and CYP2C19, <strong>(S)-warfarin is metabolized almost exclusively (80–85%) via hepatic CYP2C9</strong> into pharmacologically inactive 7-hydroxywarfarin and 6-hydroxywarfarin. Genetic polymorphism within the <em>CYP2C9</em> gene drastically alters enzymatic Michaelis-Menten kinetics (V<sub>max</sub> and K<sub>m</sub>).
      </p>

      <table>
        <thead>
          <tr>
            <th>CYP2C9 Allele</th>
            <th>cDNA Nucleotide Mutation</th>
            <th>Amino Acid Substitution</th>
            <th>In Vitro Intrinsic Clearance (CLint)</th>
            <th>Clinical Warfarin Dose Requirement</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>CYP2C9*1 (Wild-Type)</strong></td>
            <td>Reference sequence</td>
            <td>Arg144 / Ile359</td>
            <td>100% (Normal metabolizer)</td>
            <td>Standard Maintenance (~5.0 mg/day)</td>
          </tr>
          <tr>
            <td><strong>CYP2C9*2</strong></td>
            <td>c.430C&gt;T (rs1799853)</td>
            <td>Arg144Cys (Exon 3)</td>
            <td>~60–70% of wild-type</td>
            <td>Reduced by 15–20% per allele (~3.5–4.0 mg/day)</td>
          </tr>
          <tr>
            <td><strong>CYP2C9*3</strong></td>
            <td>c.1075A&gt;C (rs1057910)</td>
            <td>Ile359Leu (Exon 7)</td>
            <td>~10–15% of wild-type</td>
            <td>Reduced by 35–45% per allele (~1.5–2.5 mg/day)</td>
          </tr>
          <tr>
            <td><strong>CYP2C9*2/*3 or *3/*3</strong></td>
            <td>Compound heterozygous / homozygous</td>
            <td>Compound variants</td>
            <td>&lt;10% of wild-type (Poor metabolizer)</td>
            <td>Extreme sensitivity: 0.5–1.0 mg/day (High bleed risk)</td>
          </tr>
        </tbody>
      </table>

      <p>
        The <em>CYP2C9*3</em> substitution (Ile359Leu) is located near the catalytic heme iron center inside the substrate recognition site 6 (SRS-6). The bulkier leucine side chain impedes the optimal binding orientation of (S)-warfarin, reducing the catalytic turnover rate (k<sub>cat</sub>) by roughly 90%. Patients carrying one or two *3 alleles experience protracted (S)-warfarin half-lives extending beyond 70–100 hours (compared to ~30–40 hours in wild-type individuals), precipitating steep drug accumulation and spontaneous hemorrhage during standard induction protocols. For detailed foundational mechanics of cytochrome P450 monooxygenase active sites, review our guide on <a href="/guides/cyp450-pharmacogenomics-adme.html">Cytochrome P450 Pharmacogenomics & ADME Kinetics</a>.
      </p>

      <h2>4. VKORC1 Promoter Haplotypes: The -1639G&gt;A Regulatory Switch</h2>
      <p>
        While CYP2C9 dictates how fast the body breaks down (S)-warfarin, polymorphisms in <strong>VKORC1</strong> dictate the baseline sensitivity of the target enzyme. The most influential variant is the single nucleotide polymorphism <strong>c.-1639G&gt;A (rs9923231)</strong> located in the promoter region of the <em>VKORC1</em> gene.
      </p>
      <ul>
        <li><strong>G Allele (High-Dose / Normal Expression):</strong> Preserves an intact E-box consensus sequence (CANNTG), allowing strong transcriptional factor binding and robust basal mRNA synthesis of the VKORC1 enzyme. Individuals homozygous for the G allele (GG genotype) require higher baseline maintenance doses (~5.5–7.0 mg/day).</li>
        <li><strong>A Allele (Low-Dose / Sensitive Expression):</strong> Disrupts the promoter regulatory motif, attenuating transcription factor binding and suppressing VKORC1 mRNA expression by roughly 45–50%. Individuals carrying the AA genotype produce half the number of baseline VKORC1 enzyme complexes in their endoplasmic reticulum. Consequently, a much lower serum concentration of Warfarin is required to achieve 80% enzyme saturation, dropping the mean daily dose requirement to ~2.0–3.0 mg/day.</li>
      </ul>

      <div class="callout">
        <h4>Population Genetics Divergence (rs9923231)</h4>
        <p>
          The frequency of the sensitive <em>VKORC1 -1639A</em> allele varies dramatically across biogeographical ancestries: it is present in ~85–92% of East Asian populations (explaining why standard maintenance doses in Japan and China are historically 2.0–3.0 mg daily), ~35–42% of European populations, and only ~10–14% of African populations. In African ancestry populations, alternative variants such as <em>CYP2C9*8</em>, <em>CYP2C9*11</em>, and the <em>rs12777823</em> locus on chromosome 10 play significant roles in dose variability.
        </p>
      </div>

      <h2>5. INR Anticoagulation Kinetics & Factor Half-Life Dynamics</h2>
      <p>
        The International Normalized Ratio (INR) standardizes the Prothrombin Time (PT) across diverse commercial thromboplastin reagents by normalizing against the International Sensitivity Index (ISI):
      </p>

      <div class="math-block">
        INR = ( PT_patient / PT_mean_normal ) ^ ISI
      </div>

      <p>
        Because Warfarin inhibits the <em>de novo</em> carboxylation of new clotting factors without degrading pre-existing circulating factors, the onset and resolution of anticoagulation is entirely governed by the biological degradation half-lives (t<sub>1/2</sub>) of the individual Vitamin K-dependent proteins:
      </p>

      <table>
        <thead>
          <tr>
            <th>Protein</th>
            <th>Role in Hemostasis</th>
            <th>Elimination Half-Life (t1/2)</th>
            <th>Clinical Kinetic Significance</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Factor VII</strong></td>
            <td>Extrinsic pathway trigger (VIIa/TF)</td>
            <td><strong>4 – 6 hours</strong></td>
            <td>Depletes first; causes initial spike in INR at 24–48h without true antithrombotic efficacy.</td>
          </tr>
          <tr>
            <td><strong>Protein C</strong></td>
            <td>Endogenous anticoagulant (Inactivates Va/VIIIa)</td>
            <td><strong>6 – 8 hours</strong></td>
            <td>Rapid depletion creates a transient, dangerous <em>prothrombotic window</em> in the first 24–72 hours.</td>
          </tr>
          <tr>
            <td><strong>Protein S</strong></td>
            <td>Cofactor for activated Protein C</td>
            <td><strong>30 – 42 hours</strong></td>
            <td>Second anticoagulant to fall.</td>
          </tr>
          <tr>
            <td><strong>Factor IX</strong></td>
            <td>Intrinsic tenase complex (IXa/VIIIa)</td>
            <td><strong>20 – 24 hours</strong></td>
            <td>Intermediate clearance kinetics.</td>
          </tr>
          <tr>
            <td><strong>Factor X</strong></td>
            <td>Common pathway prothrombinase (Xa/Va)</td>
            <td><strong>36 – 48 hours</strong></td>
            <td>Slow clearance; rate-limiting for true thrombin suppression.</td>
          </tr>
          <tr>
            <td><strong>Factor II (Prothrombin)</strong></td>
            <td>Ultimate precursor to Thrombin (IIa)</td>
            <td><strong>60 – 72 hours</strong></td>
            <td>Longest half-life (~3 days). True therapeutic antithrombotic protection is not achieved until 5–7 days!</td>
          </tr>
        </tbody>
      </table>

      <h3>The Paradox of Warfarin-Induced Skin Necrosis</h3>
      <p>
        The striking kinetic mismatch between <strong>Protein C (t<sub>1/2</sub> ~ 6–8h)</strong> and <strong>Prothrombin (t<sub>1/2</sub> ~ 60–72h)</strong> explains the severe clinical pathology of <strong>Warfarin-Induced Skin Necrosis</strong>. If a large loading dose of Warfarin (e.g., 10–15 mg) is administered without concomitant therapeutic heparin bridging, the patient's natural anticoagulant Protein C rapidly plummets to near zero within 24 hours, while prothrombotic Prothrombin and Factor X remain fully active in circulation.
      </p>
      <p>
        This creates a hypercoagulable state that precipitates microvascular thrombosis in subcutaneous fat capillary beds (breasts, thighs, buttocks), leading to hemorrhagic infarction and tissue necrosis. Consequently, modern guidelines strictly mandate low-dose initiation (typically &le;5 mg daily) and mandatory parenteral anticoagulation bridging (Unfractionated Heparin or LMWH) for at least 5 days and until the INR is &ge;2.0 for 24 consecutive hours.
      </p>

      <h2>6. Clinical Pharmacogenomic Dosing Algorithms</h2>
      <p>
        The Clinical Pharmacogenetics Implementation Consortium (CPIC) and the International Warfarin Pharmacogenetics Consortium (IWPC) have developed and validated multi-variable regression equations to calculate expected daily Warfarin doses prior to the first pill:
      </p>

      <div class="math-block">
        Estimated Daily Dose (mg) = exp [ 0.686 - 0.0075(Age) + 0.437(BSA) - 0.254(CYP2C9*2) - 0.400(CYP2C9*3) - 0.491(VKORC1 A/G) - 0.831(VKORC1 A/A) + 0.216(Amiodarone) ... ]
      </div>

      <p>
        Key clinical variables integrated alongside genomics include:
      </p>
      <ul>
        <li><strong>Amiodarone Co-administration:</strong> Amiodarone and its active metabolite desethylamiodarone potently inhibit CYP2C9. Concomitant administration decreases (S)-warfarin clearance by 35–50%, requiring an immediate 30–50% empiric dose reduction.</li>
        <li><strong>Body Surface Area (BSA):</strong> Higher volume of distribution requires proportionately higher maintenance dosing.</li>
        <li><strong>Age:</strong> Hepatic blood flow, CYP2C9 clearance, and albumin concentration decline linearly after age 60, reducing dosage requirements by roughly 0.7% per year of life.</li>
        <li><strong>Dietary Vitamin K:</strong> Ingestion of Vitamin K-rich leafy greens (spinach, kale, collard greens) increases intrahepatic quinone pools, directly displacing Warfarin from VKORC1 and lowering INR. Consistency in dietary intake is clinically paramount.</li>
      </ul>

      <div class="interactive-card">
        <h4>Explore Molecular Pharmacogenomics in 3D</h4>
        <p>Simulate microsomal enzyme pockets, transition-state docking, and kinetic models in the live Quantum Forge 3D Workstation.</p>
        <a href="/">Launch 3D Workstation &rarr;</a>
      </div>
"""

refs1 = [
    "Johnson, J. A., et al. (2017). Clinical Pharmacogenetics Implementation Consortium (CPIC) Guideline for Pharmacogenetics-Guided Warfarin Dosing: 2017 Update. <em>Clin. Pharmacol. Ther.</em>, 102(3), 397–404. <a href=\"https://doi.org/10.1002/cpt.668\" target=\"_blank\" rel=\"noopener\">doi:10.1002/cpt.668</a>",
    "Tie, J. K., & Stafford, D. W. (2016). Structural and functional insights into enzymes of the vitamin K cycle. <em>J. Thromb. Haemost.</em>, 14(2), 236–247. <a href=\"https://doi.org/10.1111/jth.13217\" target=\"_blank\" rel=\"noopener\">doi:10.1111/jth.13217</a>",
    "Liu, S., et al. (2021). Structural basis of human VKORC1 inhibition by warfarin. <em>Nature Communications</em>, 12, 1632. <a href=\"https://doi.org/10.1038/s41467-021-21894-w\" target=\"_blank\" rel=\"noopener\">doi:10.1038/s41467-021-21894-w</a> [PDB: 6WVX]",
    "The International Warfarin Pharmacogenetics Consortium. (2009). Estimation of the warfarin dose with clinical and pharmacogenetic data. <em>N. Engl. J. Med.</em>, 360(8), 753–764. <a href=\"https://doi.org/10.1056/NEJMoa0809329\" target=\"_blank\" rel=\"noopener\">doi:10.1056/NEJMoa0809329</a>"
]

amazon_link_pharm = "https://link.amazon/B03y4mxsi"
amazon_title_pharm = "Katzung’s Basic & Clinical Pharmacology (16th Ed.) &rarr;"
amazon_desc_pharm = "Comprehensive clinical reference for receptor kinetics, CYP450 metabolism, pharmacogenomics, and anticoagulant pharmacology."

amazon_link_phys = "https://link.amazon/B05IasrT1"
amazon_title_phys = "Guyton and Hall Textbook of Medical Physiology (14th Ed.) &rarr;"
amazon_desc_phys = "Foundational textbook on systemic hemodynamics, renal clearance, microvascular Starling forces, and respiratory gas exchange."

amazon_link_chem = "https://link.amazon/B0bLTrZvk"
amazon_title_chem = "Atkins’ Physical Chemistry (12th Ed.) &rarr;"
amazon_desc_chem = "Authoritative guide covering quantum mechanics, molecular orbital theory, pericyclic symmetry rules, and chemical reaction dynamics."

html1 = create_guide_html(slug1, title1, meta_title1, meta_desc1, category1, read_time1, body1, amazon_link_pharm, amazon_title_pharm, amazon_desc_pharm, refs1)
with open(os.path.join(out_dir, slug1), "w") as f:
    f.write(html1)
print(f"Generated {slug1}")

# ==============================================================================
# GUIDE 2: Beta-Lactam Antibiotics & Resistance: PBP2a & ESBL
# ==============================================================================
slug2 = "beta-lactam-resistance-tem52-mrsa.html"
title2 = "Beta-Lactam Antibiotics & Antimicrobial Resistance: PBP2a Steric Clash & Extended-Spectrum Beta-Lactamases"
meta_title2 = "Beta-Lactam Antibiotics & Resistance: PBP2a & ESBL"
meta_desc2 = "Detailed structural biochemistry monograph on beta-lactam transpeptidase inhibition, PBP2a allosteric resistance in MRSA (mecA), Class A-D beta-lactamases, and next-generation diazabicyclooctane inhibitors."
category2 = "Microbiology & Antimicrobial Pharmacology"
read_time2 = "15 min read"

body2 = """
      <h2>1. Introduction: The Bacterial Cell Wall & The Beta-Lactam Pharmacophore</h2>
      <p>
        The bacterial peptidoglycan cell wall is an essential macromolecular scaffold that encases the cytoplasmic membrane, maintaining cellular morphology and withstanding internal osmotic turgor pressures exceeding 15 to 20 atmospheres in Gram-positive bacteria and 3 to 5 atmospheres in Gram-negative organisms. Peptidoglycan consists of repeating linear glycan strands of alternating <strong>N-acetylglucosamine (NAG)</strong> and <strong>N-acetylmuramic acid (NAM)</strong> linked by beta-(1,4)-glycosidic bonds, from which short peptide stems extend.
      </p>
      <p>
        Cross-linking of adjacent peptide stems provides three-dimensional mechanical tensile strength. This transpeptidation reaction is executed by a family of membrane-anchored periplasmic enzymes termed <strong>Penicillin-Binding Proteins (PBPs)</strong>. Beta-lactam antibiotics—encompassing penicillins, cephalosporins, monobactams, and carbapenems—are stereochemical structural mimics of the native terminal <strong>D-alanyl-D-alanine (D-Ala-D-Ala)</strong> dipeptide substrate recognized by PBPs.
      </p>

      <h2>2. Transpeptidase Mechanism & Covalent Acylation Kinetics</h2>
      <p>
        The PBP transpeptidase active site harbors an invariant catalytic serine nucleophile (Ser-403 in standard numbering). Under physiological conditions, the Ser hydroxyl group attacks the penultimate D-Ala carbonyl group of a donor peptide stem, displacing the terminal D-Ala residue to create a high-energy covalent <strong>acyl-enzyme intermediate</strong>. Subsequently, the terminal amine of an acceptor stem (or pentaglycine bridge in <em>Staphylococcus aureus</em>) nucleophilically attacks this ester bond, forming a cross-linking peptide bond and regenerating the free catalytic Ser residue.
      </p>

      <div class="math-block">
        [PBP Transpeptidase Reaction]:<br>
        1. PBP-Ser-OH + D-Ala-D-Ala-peptide &rarr; PBP-Ser-O-CO-D-Ala-peptide + D-Ala (leaving group)<br>
        2. PBP-Ser-O-CO-D-Ala-peptide + R-NH2 (Acceptor) &rarr; Cross-linked Peptidoglycan + PBP-Ser-OH (Free Enzyme)<br><br>
        [Beta-Lactam Suicide Inhibition]:<br>
        E + I &hArr;[K_d]&hArr; E:I &rarr;[k_2]&rarr; E-I* (Covalent Penicilloyl Intermediate) &rarr;[k_3]&rarr; E + Degraded Fragment<br>
        where k_3 &approx; 0 (deacylation t_1/2 &gt; 48 hours &rarr; irreversible enzymatic death)
      </div>

      <p>
        Because the strained, four-membered beta-lactam ring possesses high dihedral ring strain (~26 kcal/mol) and planarized nitrogen resonance suppression, the carbonyl carbon is extraordinarily electrophilic. When a beta-lactam enters the PBP active site, the catalytic Serine rapidly attacks the beta-lactam carbonyl (k<sub>2</sub> &gt; 10<sup>4</sup> M<sup>-1</sup> s<sup>-1</sup>), forming a covalent <strong>penicilloyl-enzyme adduct</strong>.
      </p>
      <p>
        Unlike the physiological peptide ester which deacylates in milliseconds, the penicilloyl-enzyme intermediate induces a steric blockade that prevents water molecules from approaching the acyl carbon. The deacylation rate constant (k<sub>3</sub>) drops to near zero (half-lives extending up to 48–96 hours). The bacterium is unable to insert new cross-links into its growing cell wall; ongoing activity of endogenous bacterial autolysins (muramidases and endopeptidases) unbalances wall turnover, causing cell wall rupture and rapid osmotic lysis.
      </p>

      <h2>3. MRSA & The PBP2a Allosteric Resistance Mechanism</h2>
      <p>
        In Methicillin-Resistant <em>Staphylococcus aureus</em> (MRSA), resistance to virtually all standard beta-lactams is conferred by the acquisition of the mobile genetic element <strong>SCCmec</strong> (Staphylococcal Cassette Chromosome mec), which harbors the <strong>mecA</strong> or <strong>mecC</strong> gene.
      </p>
      <p>
        The <em>mecA</em> gene encodes an altered, exogenous 78-kDa transpeptidase designated <strong>PBP2a</strong> (PDB: 1VQQ, 3ZFZ). Standard PBPs (PBP1, PBP2, PBP3, PBP4) in <em>S. aureus</em> remain fully susceptible to beta-lactam acylation and are completely inactivated by methicillin, nafcillin, or oxacillin. However, PBP2a is structurally incapable of binding standard beta-lactams at physiological concentrations, allowing it to autonomously take over the entire transpeptidation burden and preserve bacterial wall synthesis.
      </p>

      <table>
        <thead>
          <tr>
            <th>Structural Domain</th>
            <th>Wild-Type PBP2 (Susceptible)</th>
            <th>PBP2a (MRSA / Resistant)</th>
            <th>Molecular Consequence</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Active Site Conformation</strong></td>
            <td>Open, solvent-accessible catalytic crevice</td>
            <td>Closed, sterically occluded active site cleft</td>
            <td>Standard beta-lactam side chains physically clash with residues Met-641, Tyr-446, and Ser-403.</td>
          </tr>
          <tr>
            <td><strong>Allosteric Triggering</strong></td>
            <td>None (Direct catalytic access)</td>
            <td>Distal allosteric site located <strong>60 &Aring; away</strong> from catalytic Ser-403</td>
            <td>Binding of intact peptidoglycan fragments to the allosteric site triggers a multi-domain conformational opening.</td>
          </tr>
          <tr>
            <td><strong>Acylation Rate (k2 / Kd)</strong></td>
            <td>High: ~10<sup>4</sup> – 10<sup>5</sup> M<sup>-1</sup> s<sup>-1</sup></td>
            <td>Extremely low: &lt; 1 – 10 M<sup>-1</sup> s<sup>-1</sup></td>
            <td>Methicillin minimum inhibitory concentrations (MIC) jump from &le;2 &mu;g/mL to &gt;256 &mu;g/mL.</td>
          </tr>
          <tr>
            <td><strong>Ceftaroline Sensitivity</strong></td>
            <td>High binding affinity</td>
            <td>Unique dual-molecule binding: 1st molecule binds allosteric site; 2nd molecule acylates opened Ser-403</td>
            <td>Ceftaroline acts as a 5th-generation anti-MRSA cephalosporin by pharmacologically unlocking PBP2a.</td>
          </tr>
        </tbody>
      </table>

      <h2>4. Beta-Lactamases: Enzymatic Hydrolysis & The Ambler Classification</h2>
      <p>
        While altered PBPs dominate resistance in Gram-positive cocci, Gram-negative bacilli (such as <em>Escherichia coli</em>, <em>Klebsiella pneumoniae</em>, and <em>Pseudomonas aeruginosa</em>) primarily produce periplasmic hydrolytic enzymes termed <strong>beta-lactamases</strong>. Under the Ambler structural classification scheme, beta-lactamases are categorized into four classes based on primary amino acid homology and catalytic mechanism:
      </p>

      <table>
        <thead>
          <tr>
            <th>Ambler Class</th>
            <th>Catalytic Mechanism</th>
            <th>Representative Enzymes</th>
            <th>Hydrolytic Substrate Spectrum</th>
            <th>Classic Inhibitor Profile</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Class A</strong></td>
            <td>Active Site Serine (Ser-70) nucleophile; Glu-166 deacylation water activator</td>
            <td>TEM-1, TEM-52, SHV-1, CTX-M-15, KPC-2 (Carbapenemase)</td>
            <td>Penicillins, Cephalosporins (ESBL), Monobactams; KPC hydrolyzes all including Carbapenems</td>
            <td>Inhibited by Clavulanic acid, Tazobactam, Avibactam, Vaborbactam</td>
          </tr>
          <tr>
            <td><strong>Class B</strong></td>
            <td><strong>Metallo-beta-lactamases (MBLs)</strong>: 1 or 2 catalytic Zn<sup>2+</sup> ions activating a hydroxide ion</td>
            <td>NDM-1, VIM-1, IMP-1</td>
            <td>All penicillins, cephalosporins, and carbapenems; <em>spares Monobactams (Aztreonam)</em></td>
            <td>Resistant to all classical beta-lactamase inhibitors; chelators (EDTA) inhibit in vitro</td>
          </tr>
          <tr>
            <td><strong>Class C</strong></td>
            <td>Active Site Serine (Ser-64) nucleophile; Tyr-150 catalytic proton shuttle</td>
            <td>AmpC, CMY, FOX</td>
            <td>Penicillins, 1st–3rd gen Cephalosporins, Cephamycins (Cefoxitin); spares Cefepime</td>
            <td>Resistant to Clavulanate/Sulbactam; inhibited by Avibactam</td>
          </tr>
          <tr>
            <td><strong>Class D</strong></td>
            <td>Active Site Serine (Ser-67) utilizing an N-carboxylated Lys-73 base</td>
            <td>OXA-48, OXA-23, OXA-24/40</td>
            <td>Cloxacillin, Cephalosporins; OXA-48 carbapenemases hydrolyze carbapenems poorly inhibited by EDTA</td>
            <td>Poorly inhibited by Clavulanate; inhibited by Avibactam</td>
          </tr>
        </tbody>
      </table>

      <h3>Extended-Spectrum Beta-Lactamases (ESBLs): TEM-52 & CTX-M Evolution</h3>
      <p>
        Classical narrow-spectrum beta-lactamases (e.g., TEM-1) are sterically incapable of accommodating the bulky, bulky oxyimino-side chains of third-generation cephalosporins (Ceftriaxone, Cefotaxime, Ceftazidime). However, point mutations within the active-site Omega loop (residues 164–179) drastically enlarge the catalytic pocket.
      </p>
      <p>
        In <strong>TEM-52</strong>, three sequential substitutions—Glu104Lys, Met182Thr, and Gly238Ser—reposition the flexible B3 beta-strand and expand the substrate-binding groove. This allows oxyimino-cephalosporins to enter and be efficiently cleaved, rendering Ceftriaxone clinically useless. For related pharmacokinetics and drug clearance models, cross-reference our guide on <a href="/guides/cyp450-pharmacogenomics-adme.html">Cytochrome P450 Pharmacogenomics & ADME</a>.
      </p>

      <h2>5. Next-Generation Inhibitors: Boronic Acids & Diazabicyclooctanes</h2>
      <p>
        To counteract evolving ESBLs and carbapenemases, medicinal chemists have synthesized non-beta-lactam scaffold inhibitors:
      </p>
      <ul>
        <li><strong>Avibactam (Diazabicyclooctane, DBO):</strong> Lacks a beta-lactam ring; possesses a rigid bridged bicyclic core with an active carbamate-forming carbamoyl ring. When attacked by the catalytic Serine of Class A, C, or D enzymes, it forms a stable, slowly reversible covalent bond that does not undergo hydrolytic degradation.</li>
        <li><strong>Vaborbactam (Cyclic Boronic Acid):</strong> Acts as a direct transition-state mimic. The electrophilic boron atom adopts a tetrahedral sp<sup>3</sup> geometry with Ser-70 and the active-site water molecule, trapping KPC carbapenemases in an unreactive ground-state complex.</li>
      </ul>

      <div class="interactive-card">
        <h4>Explore PBP & Beta-Lactamase Active Sites in 3D</h4>
        <p>Inspect the Ser-403 transpeptidase pocket, penicilloyl acylation bonds, and ESBL mutations in the live Quantum Forge 3D Workstation.</p>
        <a href="/">Launch 3D Workstation &rarr;</a>
      </div>
"""

refs2 = [
    "Fuda, C., et al. (2004). Opening of the active site of penicillin-binding protein 2a in methicillin-resistant Staphylococcus aureus. <em>Nature Structural & Molecular Biology</em>, 11(10), 988–994. <a href=\"https://doi.org/10.1038/nsmb832\" target=\"_blank\" rel=\"noopener\">doi:10.1038/nsmb832</a> [PDB: 1VQQ]",
    "Bush, K., & Bradford, P. A. (2016). &beta;-Lactams and &beta;-Lactamase Inhibitors: An Overview. <em>Cold Spring Harb. Perspect. Med.</em>, 6(8), a025247. <a href=\"https://doi.org/10.1101/cshperspect.a025247\" target=\"_blank\" rel=\"noopener\">doi:10.1101/cshperspect.a025247</a>",
    "Drawz, S. M., & Bonomo, R. A. (2010). Three decades of &beta;-lactamase inhibitors. <em>Clin. Microbiol. Rev.</em>, 23(1), 160–201. <a href=\"https://doi.org/10.1128/CMR.00037-09\" target=\"_blank\" rel=\"noopener\">doi:10.1128/CMR.00037-09</a>",
    "Hecker, S. J., et al. (2015). Discovery of a cyclic boronic acid &beta;-lactamase inhibitor (RPX7009/Vaborbactam) with utility vs class A serine carbapenemases. <em>J. Med. Chem.</em>, 58(9), 3682–3692. <a href=\"https://doi.org/10.1021/acs.jmedchem.5b00127\" target=\"_blank\" rel=\"noopener\">doi:10.1021/acs.jmedchem.5b00127</a>"
]

html2 = create_guide_html(slug2, title2, meta_title2, meta_desc2, category2, read_time2, body2, amazon_link_pharm, amazon_title_pharm, amazon_desc_pharm, refs2)
with open(os.path.join(out_dir, slug2), "w") as f:
    f.write(html2)
print(f"Generated {slug2}")

# ==============================================================================
# GUIDE 3: HMG-CoA Reductase Kinetics & Statins
# ==============================================================================
slug3 = "statin-hmg-coa-reductase-kinetics.html"
title3 = "HMG-CoA Reductase Inhibition: Competitive Transition-State Mimicry & Lipophilic vs. Hydrophilic Statins"
meta_title3 = "HMG-CoA Reductase Inhibition & Statin Kinetics"
meta_desc3 = "In-depth molecular pharmacology monograph on HMG-CoA reductase structural biology, mevalonate transition-state mimicry, lipophilic vs hydrophilic statin pharmacokinetics, and cardiovascular pleiotropy."
category3 = "Cardiovascular Pharmacology & Enzymology"
read_time3 = "14 min read"

body3 = """
      <h2>1. The Biosynthetic Engine: HMG-CoA Reductase in Cholesterol Homeostasis</h2>
      <p>
        Cholesterol is an indispensable biophysical constituent of eukaryotic cell membranes, conferring membrane fluidity and organizing lipid rafts. It is also the obligate precursor for bile acid synthesis, steroidogenesis (cortisol, aldosterone, androgens, estrogens), and Vitamin D production. Endogenous de novo hepatic cholesterol synthesis contributes roughly 70–80% of total daily systemic cholesterol, with dietary intestinal absorption accounting for the remainder.
      </p>
      <p>
        The committing and rate-limiting step of the mevalonate pathway is catalyzed by <strong>3-hydroxy-3-methylglutaryl-coenzyme A (HMG-CoA) reductase (HMGCR)</strong>. HMGCR is a tetrameric, membrane-anchored glycoprotein embedded in the smooth endoplasmic reticulum (PDB: 1HW8, 1HW9). Catalyzing the four-electron reductive deacylation of (S)-HMG-CoA to (R)-mevalonate using two moles of NADPH, HMGCR activity directly dictates intracellular cholesterol concentrations.
      </p>

      <h2>2. Catalytic Mechanism & High-Energy Transition-State Topology</h2>
      <p>
        The physiological conversion of HMG-CoA to mevalonate proceeds through a sequential, ordered two-step reductive cycle within the catalytic domain:
      </p>

      <div class="math-block">
        [HMGCR Catalytic Cycle]:<br>
        1. (S)-HMG-CoA + NADPH + H+ &hArr; Mevaldyl-CoA Hemithioacetal Transition State &hArr; Mevaldehyde + CoA-SH + NADP+<br>
        2. Mevaldehyde + NADPH + H+ &rarr; (R)-Mevalonate + NADP+<br><br>
        [Overall Stoichiometry]:<br>
        HMG-CoA + 2 NADPH + 2 H+ &rarr; Mevalonate + 2 NADP+ + CoA-SH
      </div>

      <p>
        In the first reduction, hydride transfer from the nicotinamide ring of the first NADPH molecule to the C3 thioester carbonyl carbon of HMG-CoA forms an unstable <strong>mevaldyl-CoA hemithioacetal intermediate</strong>. Cleavage of the high-energy carbon-sulfur bond releases free Coenzyme A (CoA-SH), yielding the enzyme-bound aldehyde intermediate, <strong>mevaldehyde</strong>. In the second reduction, hydride transfer from a second NADPH molecule reduces mevaldehyde to the primary alcohol, generating <strong>(R)-mevalonate</strong>.
      </p>

      <h3>Molecular Basis of Statin Transition-State Mimicry</h3>
      <p>
        Statins (HMGCR inhibitors) are among the most successful therapeutics in cardiovascular medicine. All statin molecules feature a conserved <strong>3,5-dihydroxyheptanoic acid</strong> (or heptenoic acid) pharmacophore headgroup, presented either as an active open hydroxy-acid or as a closed inactive lactone prodrug (e.g., simvastatin, lovastatin) that undergoes hepatic esterase cleavage.
      </p>
      <p>
        X-ray crystallographic studies of human HMGCR complexed with statins (PDB: 1HW8, 1HW9) reveal that this dihydroxycarboxylate moiety serves as a stereochemical mimic of the <strong>mevaldyl-CoA hemithioacetal transition state</strong>. The dihydroxy acid headgroup binds directly into the cis-loop of the catalytic pocket, forming extensive networks of hydrogen bonds and electrostatic salt bridges:
      </p>
      <ul>
        <li>The terminal carboxylate forms salt bridges with Lys-735 and Arg-590.</li>
        <li>The C3-hydroxyl participates in hydrogen bonding with Ser-684 and Asp-690.</li>
        <li>The C5-hydroxyl interacts with Lys-691 and Glu-559.</li>
      </ul>
      <p>
        Because statins mimic the high-energy transition state rather than the ground-state substrate, their binding affinity is extraordinary. Whereas the native substrate HMG-CoA exhibits a Michaelis constant <strong>K<sub>m</sub> of ~4 &mu;M</strong>, statins exhibit inhibition constants <strong>K<sub>i</sub> in the range of 0.1 to 2.3 nM</strong>—representing a 10,000-fold higher affinity for the active site!
      </p>

      <h2>3. Physicochemical Divergence: Lipophilic vs. Hydrophilic Statins</h2>
      <p>
        While the dihydroxyacid pharmacophore is conserved across the entire statin class, the hydrophobic rigid backbone varies dramatically between agents, creating major differences in pharmacokinetics, tissue distribution, and adverse effect profiles:
      </p>

      <table>
        <thead>
          <tr>
            <th>Parameter</th>
            <th>Lipophilic Statins (Atorvastatin, Simvastatin, Lovastatin)</th>
            <th>Hydrophilic Statins (Rosuvastatin, Pravastatin)</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Octanol-Water Log D (pH 7.4)</strong></td>
            <td>Positive (+1.1 to +1.6) — Highly hydrophobic</td>
            <td>Negative (-0.3 to -0.8) — Water-soluble</td>
          </tr>
          <tr>
            <td><strong>Cellular Entry Mechanism</strong></td>
            <td>Passive non-facilitated diffusion through all lipid bilayers</td>
            <td>Active carrier-mediated uptake via hepatic <strong>OATP1B1 / OATP1B3</strong> transporters</td>
          </tr>
          <tr>
            <td><strong>Hepatic Selectivity</strong></td>
            <td>Moderate; distributes widely into extra-hepatic tissues (skeletal muscle, myocardium)</td>
            <td>High; selective hepatic accumulation; minimal passive entry into skeletal myocytes</td>
          </tr>
          <tr>
            <td><strong>CYP450 Metabolism</strong></td>
            <td>Extensively metabolized by <strong>CYP3A4</strong> (Simva, Atorva, Lova)</td>
            <td>Minimal CYP metabolism; Rosuvastatin ~10% via CYP2C9; Pravastatin cleared via sulfation/renal excretion</td>
          </tr>
          <tr>
            <td><strong>Drug Interaction Risk</strong></td>
            <td>High: strong CYP3A4 inhibitors (Clarithromycin, Ketoconazole, Diltiazem) spike AUC 5- to 10-fold</td>
            <td>Low: largely bypasses CYP3A4; vulnerable primarily to OATP1B1 inhibitors (Cyclosporine)</td>
          </tr>
          <tr>
            <td><strong>Myopathy & Rhabdomyolysis Risk</strong></td>
            <td>Higher incidence due to muscular penetration and mitochondrial CoQ10 depletion</td>
            <td>Lower incidence; favored in patients with statin-associated muscle symptoms (SAMS)</td>
          </tr>
        </tbody>
      </table>

      <h2>4. Cellular Feedback & SREBP-2 Up-Regulation of LDL Receptors</h2>
      <p>
        A frequent misconception is that circulating plasma LDL-C is reduced simply because the liver stops secreting cholesterol. In reality, the profound LDL-lowering efficacy of statins (30% to &gt;55% reduction) is mediated by a sophisticated genomic feedback cascade:
      </p>
      <ol>
        <li>Competitive inhibition of HMGCR depletes endoplasmic reticulum membrane cholesterol below a critical threshold (~5 mol% of ER lipids).</li>
        <li>ER cholesterol depletion induces a conformational change in <strong>SCAP</strong> (SREBP Cleavage-Activating Protein), releasing it from its anchor protein <strong>INSIG</strong> (Insulin-Induced Gene).</li>
        <li>SCAP escorts the transcription factor <strong>SREBP-2</strong> (Sterol Regulatory Element-Binding Protein 2) in COPII vesicles from the ER to the Golgi apparatus.</li>
        <li>Within the Golgi, Site-1 Protease (S1P) and Site-2 Protease (S2P) cleave SREBP-2, liberating its active basic helix-loop-helix (bHLH) transcription factor domain.</li>
        <li>Active SREBP-2 translocates to the nucleus, binding Sterol Regulatory Elements (SREs) in the promoter of the <strong>LDL Receptor (LDLR)</strong> gene.</li>
        <li>Massive de novo upregulation of hepatic cell-surface LDL receptors leads to accelerated endocytosis and lysosomal clearance of circulating ApoB-100-containing atherogenic lipoproteins (LDL, VLDL remnants, and IDL) from systemic blood.</li>
      </ol>

      <div class="callout">
        <h4>Statin-Induced PCSK9 Induction & Dual Therapy</h4>
        <p>
          Simultaneously, active SREBP-2 also transcribes <strong>PCSK9</strong> (Proprotein Convertase Subtilisin/Kexin Type 9), an endogenous chaperone that binds LDL receptors and targets them for lysosomal destruction. This compensatory rise in PCSK9 partially blunts the statin response, explaining why doubling a statin dose yields only an additional 6% LDL reduction (the "Rule of 6s"). Combining a statin with a PCSK9 monoclonal antibody (Evolocumab, Alirocumab) or siRNA (Inclisiran) neutralizes this feedback, achieving LDL reductions &gt;80%.
        </p>
      </div>

      <h2>5. Cardiovascular Pleiotropic Effects & Isoprenoid Intermediate Depletion</h2>
      <p>
        The clinical benefits of statins in reducing acute coronary syndromes (ACS) emerge earlier and exceed what would be predicted purely from gradual atherosclerotic plaque regression. These <strong>pleiotropic effects</strong> stem from the upstream inhibition of mevalonate, which blocks the synthesis of essential branched-chain isoprenoid pyrophosphates:
      </p>
      <ul>
        <li><strong>Farnesyl Pyrophosphate (FPP) & Geranylgeranyl Pyrophosphate (GGPP):</strong> These 15- and 20-carbon lipid anchors are required for post-translational <strong>isoprenylation (prenylation)</strong> of small monomeric G-proteins, including <strong>Rho, Rac, and Ras</strong>.</li>
        <li><strong>Endothelial Nitric Oxide Synthase (eNOS) Upregulation:</strong> Inactivated Rho prevents Rho-associated kinase (ROCK) from destabilizing eNOS mRNA, increasing basal endothelial nitric oxide production and restoring microvascular vasodilation.</li>
        <li><strong>Plaque Stabilization & Anti-Inflammatory Effects:</strong> Depletion of Rac-1 prevents NADPH oxidase assembly in vascular macrophages, drastically attenuating reactive oxygen species (ROS) generation, oxidized-LDL uptake, and matrix metalloproteinase (MMP-2, MMP-9) secretion, thereby reinforcing the fibrous cap of vulnerable coronary plaques. Cross-reference our monograph on <a href="/guides/coronary-bifurcation-ffr-hemodynamics.html">Coronary Bifurcation FFR & Hemodynamics</a>.</li>
      </ul>

      <div class="interactive-card">
        <h4>Simulate HMG-CoA Reductase Complex in 3D</h4>
        <p>Explore the active-site cis-loop, dihydroxyacid pharmacophore salt bridges, and statin binding poses in the live Quantum Forge 3D Workstation.</p>
        <a href="/">Launch 3D Workstation &rarr;</a>
      </div>
"""

refs3 = [
    "Istvan, E. S., & Deisenhofer, J. (2001). Structural mechanism for statin inhibition of HMG-CoA reductase. <em>Science</em>, 292(5519), 1160–1164. <a href=\"https://doi.org/10.1126/science.1059880\" target=\"_blank\" rel=\"noopener\">doi:10.1126/science.1059880</a> [PDB: 1HW8, 1HW9]",
    "Brown, M. S., & Goldstein, J. L. (1986). A receptor-mediated pathway for cholesterol homeostasis. <em>Science</em>, 232(4746), 34–47. <a href=\"https://doi.org/10.1126/science.3513311\" target=\"_blank\" rel=\"noopener\">doi:10.1126/science.3513311</a>",
    "Schachter, M. (2005). Chemical, pharmacokinetic and pharmacodynamic properties of statins: an update. <em>Fundam. Clin. Pharmacol.</em>, 19(1), 117–125. <a href=\"https://doi.org/10.1111/j.1472-8206.2004.00299.x\" target=\"_blank\" rel=\"noopener\">doi:10.1111/j.1472-8206.2004.00299.x</a>",
    "Liao, J. K., & Laufs, U. (2005). Pleiotropic effects of statins. <em>Annu. Rev. Pharmacol. Toxicol.</em>, 45, 89–118. <a href=\"https://doi.org/10.1146/annurev.pharmtox.45.120403.095858\" target=\"_blank\" rel=\"noopener\">doi:10.1146/annurev.pharmtox.45.120403.095858</a>"
]

html3 = create_guide_html(slug3, title3, meta_title3, meta_desc3, category3, read_time3, body3, amazon_link_pharm, amazon_title_pharm, amazon_desc_pharm, refs3)
with open(os.path.join(out_dir, slug3), "w") as f:
    f.write(html3)
print(f"Generated {slug3}")

# ==============================================================================
# GUIDE 4: Circle of Willis & Cerebral Hemodynamics
# ==============================================================================
slug4 = "circle-of-willis-cerebral-hemodynamics.html"
title4 = "Cerebral Autoregulation, Circle of Willis Collateral Flow & Ischemic Penumbra Pathophysiology"
meta_title4 = "Circle of Willis Hemodynamics & Ischemic Penumbra"
meta_desc4 = "Clinical neurovascular monograph on Circle of Willis anatomical variants, myogenic and chemical cerebral autoregulation, fluid dynamic collateral rerouting, and ischemic penumbra perfusion kinetics."
category4 = "Neurovascular Physiology & Hemodynamics"
read_time4 = "15 min read"

body4 = """
      <h2>1. Neurovascular Architecture: The Circle of Willis Polygon</h2>
      <p>
        The human brain represents approximately 2% of total body mass, yet demands roughly 15% of resting cardiac output and consumes &gt;20% of total basal body oxygen and glucose. Because cerebral neural tissue possesses negligible intracellular glycogen reserves and cannot tolerate ischemic hypoxia for more than a few minutes, cerebral blood flow (CBF) requires extraordinary anatomical redundancy and physiological autoregulation.
      </p>
      <p>
        This arterial redundancy is embodied by the <strong>Circle of Willis (Circulus Arteriosus Cerebri)</strong>, a heptagonal anastomotic ring situated at the base of the brain in the interpeduncular cistern. The polygon links the anterior anterior-carotid circulation with the posterior vertebrobasilar circulation through specific anastomotic conduit vessels:
      </p>
      <ul>
        <li><strong>Anterior Communicating Artery (ACoA):</strong> A short transverse bridging vessel connecting the bilateral A1 segments of the <strong>Anterior Cerebral Arteries (ACA)</strong>.</li>
        <li><strong>Internal Carotid Arteries (ICA):</strong> Enter the skull base via the carotid canals, emerging into the middle cranial fossa to bifurcate into the Middle Cerebral Artery (MCA) and ACA.</li>
        <li><strong>Posterior Communicating Arteries (PCoA):</strong> Connect the terminal ICA on each side to the ipsilateral P1 segment of the <strong>Posterior Cerebral Artery (PCA)</strong>.</li>
        <li><strong>Basilar Artery:</strong> Formed by the confluence of the bilateral vertebral arteries at the pontomedullary junction, ascending along the clivus to divide into the bilateral P1 segments of the PCA.</li>
      </ul>

      <table>
        <thead>
          <tr>
            <th>Willisian Anatomy Configuration</th>
            <th>Prevalence in Healthy Population</th>
            <th>Hemodynamic Collateral Capacity</th>
            <th>Stroke Vulnerability</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Complete Symmetrical Polygon</strong></td>
            <td><strong>35 – 45%</strong></td>
            <td>Optimal; instantaneous flow reversal through ACoA and PCoA maintains distal MCA perfusion during acute ICA occlusion.</td>
            <td>Low; high tolerance to unilateral high-grade carotid stenosis.</td>
          </tr>
          <tr>
            <td><strong>Hypoplastic / Absent PCoA</strong></td>
            <td><strong>25 – 35%</strong> (Unilateral or bilateral)</td>
            <td>Severely impaired anterior-to-posterior cross-talk; isolates posterior fossa from carotid inflow.</td>
            <td>High vulnerability to PCA watershed infarctions if basilar stenosis occurs.</td>
          </tr>
          <tr>
            <td><strong>Hypoplastic / Absent A1 Segment</strong></td>
            <td><strong>7 – 10%</strong></td>
            <td>Contralateral ICA supplies bilateral distal ACA territories via the ACoA.</td>
            <td>Occlusion of the dominant ICA precipitates bilateral anterior cerebral infarction (paraplegia, abulia).</td>
          </tr>
          <tr>
            <td><strong>Fetal-Type Posterior Cerebral Artery (fPCA)</strong></td>
            <td><strong>15 – 25%</strong> (PCA arises directly from ICA; P1 absent)</td>
            <td>Posterior cerebral circulation is entirely dependent on internal carotid inflow rather than basilar flow.</td>
            <td>Carotid thromboembolism can cause simultaneous MCA and occipital lobe PCA infarctions.</td>
          </tr>
        </tbody>
      </table>

      <h2>2. Cerebral Autoregulation: Myogenic & Metabolic Mechanisms</h2>
      <p>
        Under physiological conditions, global <strong>Cerebral Blood Flow (CBF)</strong> is maintained at a remarkably steady rate of approximately <strong>50 mL per 100 grams of brain tissue per minute</strong> (corresponding to ~750 mL/min for a standard 1,400 g adult brain). This constant perfusion is preserved across wide fluctuations in <strong>Cerebral Perfusion Pressure (CPP)</strong>, defined as:
      </p>

      <div class="math-block">
        CPP = MAP - ICP (or CVP, whichever is higher)<br><br>
        [Poiseuille Flow Equation applied to Cerebrovascular Beds]:<br>
        CBF = CPP / CVR = ( MAP - ICP ) / ( ( 8 &middot; &eta; &middot; L ) / ( &pi; &middot; r^4 ) )
      </div>

      <p>
        The classic <strong>Lassen Autoregulatory Curve</strong> demonstrates that CBF remains constant across Mean Arterial Pressures (MAP) ranging from approximately <strong>60 to 150 mmHg</strong>. This is achieved by dynamically adjusting <strong>Cerebrovascular Resistance (CVR)</strong> through two primary mechanisms:
      </p>

      <h3>1. The Myogenic Response (Bayliss Effect)</h3>
      <p>
        Vascular smooth muscle cells (VSMCs) in cerebral pial and penetrating parenchymal arterioles possess stretch-activated non-selective cation channels (TRPC6, Piezo1). When systemic blood pressure rises, the resulting stretch of the arterial wall activates these channels, causing extracellular Ca<sup>2+</sup> influx and membrane depolarization. This opens L-type voltage-gated calcium channels, promoting calmodulin-dependent Myosin Light Chain Kinase (MLCK) phosphorylation and rapid arteriolar vasoconstriction.
      </p>
      <p>
        Because resistance varies inversely with the fourth power of the vessel radius ($R \propto 1/r^4$), subtle vasoconstriction steeply increases CVR, keeping CBF flat. Conversely, when perfusion pressure drops toward 60 mmHg, myogenic tone is abolished, inducing maximal precapillary arteriolar vasodilation to protect downstream capillary perfusion.
      </p>

      <h3>2. Chemical & Metabolic Coupling (pCO2 & pH)</h3>
      <p>
        Cerebral arterioles are exquisitely sensitive to arterial carbon dioxide tension (PaCO2). Carbon dioxide diffuses freely across the blood-brain barrier into the perivascular space, where it hydrates to form carbonic acid and dissociates into H<sup>+</sup> and HCO<sub>3</sub><sup>-</sup>:
      </p>
      <ul>
        <li><strong>Hypercapnia (PaCO2 &gt; 45 mmHg):</strong> Local perivascular acidosis hyperpolarizes smooth muscle membranes via ATP-sensitive potassium channels (K<sub>ATP</sub>), inducing profound arteriolar vasodilation. CBF changes by roughly <strong>2 to 4% for every 1 mmHg change in PaCO2</strong>.</li>
        <li><strong>Hypocapnia (PaCO2 &lt; 35 mmHg):</strong> Alkalosis induces marked cerebral vasoconstriction. Hyperventilation is utilized clinically in neurotrauma for acute, short-term reduction of elevated Intracranial Pressure (ICP), but must be applied cautiously to prevent iatrogenic cerebral ischemia.</li>
      </ul>

      <h2>3. Collateral Fluid Dynamics: Leptomeningeal Anastomoses</h2>
      <p>
        When an acute embolic occlusion occludes a major cerebral trunk—such as the proximal M1 segment of the Middle Cerebral Artery—the Circle of Willis polygon cannot deliver retrograde flow directly into the obstructed branch. Perfusion of the threatened territory now relies on secondary collateral pathways: <strong>Leptomeningeal (pial) Anastomoses</strong> (the Collaterals of Heubner).
      </p>
      <p>
        These are small-caliber (diameter 100–300 &mu;m) bridging vessels linking the distal cortical branches of the ACA and PCA with distal terminal branches of the MCA over the hemispheric convexities. The driving force for collateral flow is governed by the trans-ischemic pressure gradient:
      </p>

      <div class="math-block">
        &Delta;P_collateral = P_ACA/PCA (systemic pressure) - P_MCA_distal (near zero distal to clot)
      </div>

      <p>
        If robust leptomeningeal collaterals are recruited, retrograde blood flow slows the expansion of the irreversible ischemic core, buying critical hours for acute mechanical thrombectomy or intravenous thrombolysis.
      </p>

      <h2>4. The Ischemic Penumbra: Perfusion Thresholds & Neuronal Viability</h2>
      <p>
        In acute focal ischemic stroke, the affected brain parenchyma is divided into two distinct pathophysiological zones: the <strong>Ischemic Core</strong> and the surrounding <strong>Ischemic Penumbra</strong> (Astrup concept):
      </p>

      <table>
        <thead>
          <tr>
            <th>Perfusion Zone</th>
            <th>CBF Threshold (mL / 100g / min)</th>
            <th>Cellular Bioenergetics & Electrophysiology</th>
            <th>Clinical Outcome & Reversibility</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Normal Tissue</strong></td>
            <td><strong>&gt; 50</strong></td>
            <td>Normal aerobic oxidative phosphorylation; intact ATP synthesis; resting membrane potential -70 mV.</td>
            <td>Physiologically functional.</td>
          </tr>
          <tr>
            <td><strong>Oligemia</strong></td>
            <td><strong>22 – 50</strong></td>
            <td>Mild hypoperfusion; oxygen extraction fraction (OEF) increases; neuronal firing remains intact.</td>
            <td>No structural damage; tissue will not infarct even without reperfusion.</td>
          </tr>
          <tr>
            <td><strong>Ischemic Penumbra</strong></td>
            <td><strong>12 – 20</strong></td>
            <td><strong>Electrical Failure:</strong> Neurons cease synaptic transmission to conserve energy (loss of EEG/evoked potentials); ATP stores preserved at ~50%; Na+/K+ ATPase pumps remain partially functional.</td>
            <td><strong>Structurally salvageable!</strong> Reperfusion restores normal neurological function. If untreated, will progress into core infarction within 6 to 24 hours.</td>
          </tr>
          <tr>
            <td><strong>Ischemic Core</strong></td>
            <td><strong>&lt; 10 – 12</strong></td>
            <td><strong>Membrane & Bioenergetic Collapse:</strong> Complete ATP depletion (&lt;5%); failure of Na+/K+ ATPase; massive Na+ and Ca2+ influx; anoxic depolarization; cytotoxic edema; calpain/caspase activation; necrosis.</td>
            <td><strong>Irreversible cell death</strong> occurring within minutes of complete ischemia. Cannot be salvaged by reperfusion.</td>
          </tr>
        </tbody>
      </table>

      <h3>Cytotoxic Edema & Anoxic Depolarization</h3>
      <p>
        When CBF drops below 10 mL/100g/min, the cessation of oxidative phosphorylation abolishes mitochondrial ATP synthesis. Without ATP, the <strong>Na<sup>+</sup>/K<sup>+</sup>-ATPase pump</strong> stalls. Intracellular sodium accumulates, destroying the transmembrane electrochemical gradient. Chloride and water rush into the neuron down osmotic gradients, precipitating <strong>Cytotoxic Edema</strong> (characterized on MRI by restricted diffusion with hyperintensity on DWI and hypointensity on ADC maps).
      </p>
      <p>
        Simultaneously, unbuffered calcium influx triggers massive vesicular release of <strong>Glutamate</strong> into the synaptic cleft. Inability of astrocytic glutamate reuptake transporters (EAAT2) to clear glutamate produces catastrophic <strong>Excitotoxicity</strong>, over-activating postsynaptic NMDA and AMPA receptors, triggering enzymatic auto-digestion by calpains, endonucleases, and phospholipase A2. For systemic microvascular fluid principles, review our guide on <a href="/guides/coronary-bifurcation-ffr-hemodynamics.html">Coronary Bifurcation FFR & Hemodynamics</a>.
      </p>

      <div class="interactive-card">
        <h4>Explore 3D Neurovascular & Willisian Models</h4>
        <p>Inspect the internal carotid bifurcation, Circle of Willis polygon variants, and cerebral autoregulation curves in the live Quantum Forge 3D Workstation.</p>
        <a href="/">Launch 3D Workstation &rarr;</a>
      </div>
"""

refs4 = [
    "Alastruey, J., et al. (2007). Modelling the circle of Willis to assess the effects of anatomical variations on cerebral perfusion. <em>J. Biomech.</em>, 40(8), 1794–1805. <a href=\"https://doi.org/10.1016/j.jbiomech.2006.07.008\" target=\"_blank\" rel=\"noopener\">doi:10.1016/j.jbiomech.2006.07.008</a>",
    "Astrup, J., Siesjo, B. K., & Symon, L. (1981). Thresholds in cerebral ischemia - the ischemic penumbra. <em>Stroke</em>, 12(6), 723–725. <a href=\"https://doi.org/10.1161/01.str.12.6.723\" target=\"_blank\" rel=\"noopener\">doi:10.1161/01.str.12.6.723</a>",
    "Donnan, G. A., & Davis, S. M. (2002). The ischemic penumbra: pathophysiology and medical therapeutic approach. <em>Curr. Atheroscler. Rep.</em>, 4(4), 278–285. <a href=\"https://doi.org/10.1007/s11883-002-0006-2\" target=\"_blank\" rel=\"noopener\">doi:10.1007/s11883-002-0006-2</a>",
    "Liebeskind, D. S. (2003). Collateral circulation. <em>Stroke</em>, 34(9), 2279–2284. <a href=\"https://doi.org/10.1161/01.STR.0000086465.41263.06\" target=\"_blank\" rel=\"noopener\">doi:10.1161/01.STR.0000086465.41263.06</a>"
]

html4 = create_guide_html(slug4, title4, meta_title4, meta_desc4, category4, read_time4, body4, amazon_link_phys, amazon_title_phys, amazon_desc_phys, refs4)
with open(os.path.join(out_dir, slug4), "w") as f:
    f.write(html4)
print(f"Generated {slug4}")

print("Batch 1 completed successfully!")
