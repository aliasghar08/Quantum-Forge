with open("quantum_forge/web/index.html", "r") as f:
    content = f.read()

# 1. Update style for flutter-view, flt-glass-pane
old_style = """    flutter-view, flt-glass-pane {
      min-width: 1280px;
      width: 100% !important;
      height: 100% !important;
    }"""

new_style = """    flutter-view, flt-glass-pane {
      position: absolute;
      top: 0;
      left: 0;
      z-index: 1;
      background-color: #060911;
      min-width: 1280px;
      width: 100% !important;
      height: 100% !important;
    }"""

if old_style in content:
    content = content.replace(old_style, new_style, 1)
    print("Updated flutter-view CSS styling")
else:
    print("Warning: old_style not found directly")

# 2. Remove crawler.style.display = 'none'
old_crawler_hide = """        var crawler = document.getElementById('seo-crawler-content');
        if (crawler) {
          crawler.style.display = 'none';
        }"""

if old_crawler_hide in content:
    content = content.replace(old_crawler_hide, "        // Keep #seo-crawler-content visible in the DOM behind <flutter-view> (z-index: 0)", 1)
    print("Removed crawler display: none")
else:
    print("Warning: old_crawler_hide not found directly")

# 3. Update #seo-crawler-content positioning
old_seo_div = '<div id="seo-crawler-content" style="position: absolute; top: 0; left: 0; width: 100%; min-height: 100vh; background: #090D16; color: #E2E8F0; font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, sans-serif; z-index: 0; padding: 32px 24px; box-sizing: border-box;">'
new_seo_div = '<div id="seo-crawler-content" style="position: relative; width: 100%; min-height: 100vh; background: #090D16; color: #E2E8F0; font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, sans-serif; z-index: 0; padding: 32px 24px; box-sizing: border-box;">'

if old_seo_div in content:
    content = content.replace(old_seo_div, new_seo_div, 1)
    print("Updated #seo-crawler-content to position: relative; z-index: 0;")
else:
    print("Warning: old_seo_div not found directly")

# 4. Update the 16 guides in noscript and in seo-crawler-content
# Let's inspect where the guides list starts and ends in content
old_noscript_guides = """      <h2 style="color: #0369a1; border-bottom: 2px solid #e2e8f0; padding-bottom: 8px; margin-top: 24px;">Published Scientific & Clinical Guides</h2>
      <ul style="line-height: 1.8;">
        <li><a href="guides/aspirin-cox-inhibition-mechanism.html"><strong>Acetylsalicylic Acid:</strong> Irreversible Ser-530 COX-1/COX-2 Acetylation & Clinical Pharmacology</a></li>
        <li><a href="guides/sn1-vs-sn2-reaction-kinetics.html"><strong>Nucleophilic Substitution:</strong> SN1 vs SN2 Transition-State Geometry, Solvent Effects & Eyring Kinetics</a></li>
        <li><a href="guides/transition-state-theory-activation-energy.html"><strong>Transition-State Theory:</strong> Saddle Points, CI-NEB & Activation Barrier Modeling</a></li>
        <li><a href="guides/machine-learning-interatomic-potentials.html"><strong>Neural Force Fields:</strong> Equivariant Message-Passing (MACE, PaiNN) vs Classical MMFF94 & DFT</a></li>
        <li><a href="guides/cyp450-pharmacogenomics-adme.html"><strong>Cytochrome P450 Pharmacogenomics:</strong> Polymorphic Metabolism & Personalized Clearance Curves</a></li>
        <li><a href="guides/acetaminophen-napqi-hepatotoxicity.html"><strong>Acetaminophen Toxicity:</strong> NAPQI Bioactivation, Glutathione Depletion & NAC Rescue</a></li>
        <li><a href="guides/herg-channel-qt-prolongation.html"><strong>hERG Potassium Channel:</strong> Cryo-EM Structure (PDB 5VA1), QT Prolongation & Torsades de Pointes</a></li>
        <li><a href="guides/coronary-bifurcation-ffr-hemodynamics.html"><strong>Coronary Bifurcation Hemodynamics:</strong> Fractional Flow Reserve (FFR/iFR) & Stent Mechanics</a></li>
      </ul>"""

new_noscript_guides = """      <h2 style="color: #0369a1; border-bottom: 2px solid #e2e8f0; padding-bottom: 8px; margin-top: 24px;">Published Scientific & Clinical Monographs (16 Treats)</h2>
      <ul style="line-height: 1.8;">
        <li><a href="/guides/warfarin-cyp2c9-vkorc1-dosing.html"><strong>Warfarin Pharmacogenomics:</strong> VKORC1 Inhibition, CYP2C9*2/*3 Variants & INR Anticoagulation Kinetics</a></li>
        <li><a href="/guides/beta-lactam-resistance-tem52-mrsa.html"><strong>Beta-Lactam Resistance:</strong> PBP2a Steric Clash & Extended-Spectrum Beta-Lactamases</a></li>
        <li><a href="/guides/statin-hmg-coa-reductase-kinetics.html"><strong>HMG-CoA Reductase Kinetics:</strong> Competitive Transition-State Mimicry & Lipophilic vs Hydrophilic Statins</a></li>
        <li><a href="/guides/aspirin-cox-inhibition-mechanism.html"><strong>Acetylsalicylic Acid:</strong> Irreversible Ser-530 COX-1/COX-2 Acetylation & Antiplatelet Pharmacology</a></li>
        <li><a href="/guides/cyp450-pharmacogenomics-adme.html"><strong>Cytochrome P450 Pharmacogenomics:</strong> Polymorphic Metabolism & Personalized Clearance Curves</a></li>
        <li><a href="/guides/acetaminophen-napqi-hepatotoxicity.html"><strong>Acetaminophen Toxicity:</strong> NAPQI Bioactivation, Glutathione Depletion & NAC Rescue</a></li>
        <li><a href="/guides/herg-channel-qt-prolongation.html"><strong>hERG Potassium Channel:</strong> Cryo-EM Structure (PDB 5VA1), QT Prolongation & Torsades de Pointes</a></li>
        <li><a href="/guides/circle-of-willis-cerebral-hemodynamics.html"><strong>Circle of Willis:</strong> Cerebral Autoregulation, Collateral Flow & Ischemic Penumbra Pathophysiology</a></li>
        <li><a href="/guides/nephron-raas-gfr-filtration-dynamics.html"><strong>Renal Glomerular Dynamics:</strong> Starling Forces, RAAS Vasoconstriction & ACEi/ARB Nephroprotection</a></li>
        <li><a href="/guides/ards-mechanical-ventilation-lung-mechanics.html"><strong>ARDS Lung Mechanics:</strong> PEEP Recruitment, Driving Pressure, Compliance Loops & V/Q Matching</a></li>
        <li><a href="/guides/acid-base-anion-gap-henderson-hasselbalch.html"><strong>Clinical Acid-Base Physiology:</strong> Henderson-Hasselbalch Kinetics, Winter's Formula & Anion Gap</a></li>
        <li><a href="/guides/coronary-bifurcation-ffr-hemodynamics.html"><strong>Coronary Bifurcation Hemodynamics:</strong> Fractional Flow Reserve (FFR/iFR) & Stent Mechanics</a></li>
        <li><a href="/guides/diels-alder-pericyclic-frontier-orbitals.html"><strong>Diels-Alder Cycloaddition:</strong> Frontier Molecular Orbital Theory, Endo Rule & Synchronous Transition States</a></li>
        <li><a href="/guides/sn1-vs-sn2-reaction-kinetics.html"><strong>Nucleophilic Substitution:</strong> SN1 vs SN2 Transition-State Geometry, Solvent Effects & Eyring Kinetics</a></li>
        <li><a href="/guides/transition-state-theory-activation-energy.html"><strong>Transition-State Theory:</strong> Saddle Points, CI-NEB & Activation Barrier Modeling</a></li>
        <li><a href="/guides/machine-learning-interatomic-potentials.html"><strong>Neural Force Fields:</strong> Equivariant Message-Passing (MACE, PaiNN) vs Classical MMFF94 & DFT</a></li>
      </ul>"""

if old_noscript_guides in content:
    content = content.replace(old_noscript_guides, new_noscript_guides, 1)
    print("Updated noscript guides list")
else:
    print("Warning: old_noscript_guides not found directly")

# In the main body of #seo-crawler-content, replace the 8 monographs section with 16
old_crawler_section_start = '<!-- 8 Published Scientific & Clinical Guides -->'
old_crawler_section_end = '<!-- Platform Pillars Overview -->'

new_crawler_section = """<!-- 16 Published Scientific & Clinical Monographs -->
        <section style="margin-bottom: 40px;">
          <h2 style="font-size: 1.5rem; color: #00E5FF; border-bottom: 1px solid #1E293B; padding-bottom: 8px; margin-bottom: 20px;">Peer-Reviewed Scientific & Clinical Monographs Library (16 Guides)</h2>
          <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 16px;">
            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Pharmacogenomics &middot; Anticoagulation</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/warfarin-cyp2c9-vkorc1-dosing.html" style="color: #FFFFFF; text-decoration: none;">Warfarin: VKORC1 & CYP2C9*2/*3 Kinetics</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">VKORC1 -1639G>A promoter polymorphism, CYP2C9 clearance reduction, Vitamin K epoxide redox cycle kinetics, and IWPC dosing algorithms.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Microbiology &middot; Resistance</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/beta-lactam-resistance-tem52-mrsa.html" style="color: #FFFFFF; text-decoration: none;">Beta-Lactams: PBP2a & ESBL Resistance</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">PBP transpeptidase acylation kinetics, mecA-encoded PBP2a allosteric resistance in MRSA, Ambler Class A–D beta-lactamases, and avibactam.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Cardiovascular Pharmacology</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/statin-hmg-coa-reductase-kinetics.html" style="color: #FFFFFF; text-decoration: none;">HMG-CoA Reductase & Statin Kinetics</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Mevalonate transition-state mimicry (PDB 1HW8), lipophilic vs hydrophilic statins, SREBP-2 LDL upregulation, and pleiotropy.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Clinical Pharmacology &middot; MBBS</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/aspirin-cox-inhibition-mechanism.html" style="color: #FFFFFF; text-decoration: none;">Acetylsalicylic Acid: Ser-530 COX Acetylation</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Structural biology of Cyclooxygenase-1/2, nucleophilic attack of Serine-530, steric occlusion of arachidonic acid, and antiplatelet pharmacology.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Pharmacogenomics &middot; ADME</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/cyp450-pharmacogenomics-adme.html" style="color: #FFFFFF; text-decoration: none;">Cytochrome P450 Polymorphisms & Clearance</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">CYP2D6, CYP2C19, and CYP2C9 genetic variants, Poor vs Extensive metabolizer phenotypes, and CPIC guideline dosing adaptations.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Toxicology & Emergency Care</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/acetaminophen-napqi-hepatotoxicity.html" style="color: #FFFFFF; text-decoration: none;">Acetaminophen Toxicity & NAC Rescue</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">CYP2E1 bioactivation, glutathione depletion thresholds, mitochondrial permeability transition pore opening, and Rumack-Matthew nomogram.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Electrophysiology & Cardiology</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/herg-channel-qt-prolongation.html" style="color: #FFFFFF; text-decoration: none;">hERG Channel Blockade & Torsades de Pointes</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Kv11.1 cryo-EM structure (PDB 5VA1), aromatic cavity trapping, Phase 3 repolarization delay, Early Afterdepolarizations, and CiPA screening.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Neurovascular &middot; Hemodynamics</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/circle-of-willis-cerebral-hemodynamics.html" style="color: #FFFFFF; text-decoration: none;">Circle of Willis & Cerebral Autoregulation</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Willisian polygon variants, myogenic Bayliss effect, chemical pCO2 autoregulation, leptomeningeal collaterals, and ischemic penumbra kinetics.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Renal Physiology &middot; Hemodynamics</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/nephron-raas-gfr-filtration-dynamics.html" style="color: #FFFFFF; text-decoration: none;">Nephron GFR Dynamics & RAAS Vasoconstriction</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Starling ultrafiltration forces, macula densa tubuloglomerular feedback, Angiotensin II efferent constriction, and ACEi/ARB nephroprotection.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Critical Care &middot; Pulmonology</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/ards-mechanical-ventilation-lung-mechanics.html" style="color: #FFFFFF; text-decoration: none;">ARDS Lung Mechanics & Driving Pressure</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Berlin definition, static respiratory compliance (Crs), driving pressure (&Delta;P &le; 14 cmH2O), baby lung concept, and PROSEVA prone positioning.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Clinical Acid-Base Physiology</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/acid-base-anion-gap-henderson-hasselbalch.html" style="color: #FFFFFF; text-decoration: none;">Acid-Base Physiology & Anion Gap Kinetics</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Henderson-Hasselbalch thermodynamic equilibrium, serum anion gap hypoalbuminemia correction, GOLDMARK differential, and Winter's formula.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Interventional Cardiology</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/coronary-bifurcation-ffr-hemodynamics.html" style="color: #FFFFFF; text-decoration: none;">Coronary Bifurcation FFR & Stent Mechanics</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Navier-Stokes pulsatile coronary flow, Murray's law bifurcation branching, endothelial wall shear stress, and DK-Crush stenting mechanics.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Physical Organic Chemistry</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/diels-alder-pericyclic-frontier-orbitals.html" style="color: #FFFFFF; text-decoration: none;">Diels-Alder [4+2] Cycloaddition & FMO Theory</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Woodward-Hoffmann symmetry rules, frontier molecular orbital HOMO-LUMO gap narrowing, the Alder Endo Rule, and synchronous transition states.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Reaction Kinetics &middot; Pharm-D</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/sn1-vs-sn2-reaction-kinetics.html" style="color: #FFFFFF; text-decoration: none;">Nucleophilic Substitution: SN1 vs SN2 Pathways</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Pentacoordinate transition-state geometry, Walden inversion, carbocation racemization, solvent desolvation, and Eyring activation entropy.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">Quantum Chemistry &middot; Theory</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/transition-state-theory-activation-energy.html" style="color: #FFFFFF; text-decoration: none;">Transition-State Theory & Saddle Points</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">Potential energy surface topology, index-1 Hessian negative eigenvalues, harmonic TST, and Climbing Image Nudged Elastic Band (CI-NEB) algorithms.</p>
            </div>

            <div style="background: #111827; border: 1px solid #1E293B; border-radius: 8px; padding: 18px;">
              <span style="font-size: 0.75rem; color: #00E5FF; font-weight: bold; text-transform: uppercase;">AI & Neural Force Fields &middot; MLIP</span>
              <h3 style="font-size: 1.1rem; color: #FFFFFF; margin: 8px 0;"><a href="/guides/machine-learning-interatomic-potentials.html" style="color: #FFFFFF; text-decoration: none;">Equivariant Neural Force Fields vs MMFF94 & DFT</a></h3>
              <p style="font-size: 0.9rem; color: #94A3B8; line-height: 1.5;">E(3)-equivariant message passing (MACE, PaiNN), body-order tensor expansions, and sub-second ab initio force evaluations in molecular dynamics.</p>
            </div>
          </div>
        </section>
        """

idx1 = content.find(old_crawler_section_start)
idx2 = content.find(old_crawler_section_end)
if idx1 != -1 and idx2 != -1:
    content = content[:idx1] + new_crawler_section + content[idx2:]
    print("Replaced 8 crawler guides with all 16 monographs in #seo-crawler-content")
else:
    print(f"Warning: crawler section delimiters not found: idx1={idx1}, idx2={idx2}")

with open("quantum_forge/web/index.html", "w") as f:
    f.write(content)

print("Saved quantum_forge/web/index.html!")
