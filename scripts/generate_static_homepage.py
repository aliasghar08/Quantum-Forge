homepage_path = "quantum_forge/static_site/index.html"

html = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Quantum Forge — Reaction Dynamics & Clinical Simulation Workstation</title>
  <meta name="description" content="Quantum Forge by Dart Nexus Lab: Next-generation web-based transition-state MLIP, quantum chemistry reaction dynamics, clinical pharmacology monographs, and 3D organ hemodynamic simulations.">
  <meta name="author" content="Dart Nexus Lab <eliasgharinnocent@yahoo.com>">
  <meta name="copyright" content="Copyright © 2026 Dart Nexus Lab. All Rights Reserved.">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="manifest" href="manifest.json">

  <!-- Google AdSense -->
  <meta name="google-adsense-account" content="ca-pub-9402443776639153">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-9402443776639153" crossorigin="anonymous"></script>

  <!-- Google tag (gtag.js) -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=AW-16732994716"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'AW-16732994716');
  </script>

  <style>
    :root {
      --bg: #090D16;
      --card-bg: #111827;
      --card-border: #1F2937;
      --primary: #00E5FF;
      --accent: #00BFA5;
      --text: #F3F4F6;
      --text-muted: #9CA3AF;
      --font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: var(--font-family);
      line-height: 1.7;
      overflow-x: hidden;
    }
    header {
      background: rgba(17, 24, 39, 0.85);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--card-border);
      position: sticky;
      top: 0;
      z-index: 50;
      padding: 1rem 2rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 1rem;
    }
    .logo-container {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      text-decoration: none;
      color: var(--text);
    }
    .logo-badge {
      background: linear-gradient(135deg, #00BFA5, #00E5FF);
      color: #090D16;
      font-weight: 800;
      font-size: 1.1rem;
      padding: 0.25rem 0.6rem;
      border-radius: 6px;
    }
    .logo-title {
      font-weight: 700;
      font-size: 1.25rem;
      letter-spacing: -0.025em;
    }
    nav {
      display: flex;
      gap: 1.25rem;
      align-items: center;
      flex-wrap: wrap;
    }
    nav a {
      color: var(--text-muted);
      text-decoration: none;
      font-size: 0.95rem;
      font-weight: 500;
      transition: color 0.2s;
    }
    nav a:hover {
      color: var(--primary);
    }
    .nav-cta {
      background: linear-gradient(135deg, #00BFA5, #00E5FF);
      color: #090D16 !important;
      font-weight: 700 !important;
      padding: 0.45rem 1rem;
      border-radius: 6px;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .nav-cta:hover {
      transform: translateY(-1px);
      box-shadow: 0 4px 15px rgba(0, 229, 255, 0.35);
    }
    .container {
      max-width: 1100px;
      margin: 0 auto;
      padding: 0 1.5rem;
    }
    .hero {
      text-align: center;
      padding: 4rem 1rem 3rem 1rem;
      margin: 2rem auto 3rem auto;
      background: linear-gradient(180deg, rgba(17, 24, 39, 0.9) 0%, rgba(9, 13, 22, 0.6) 100%);
      border: 1px solid var(--card-border);
      border-radius: 20px;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5);
    }
    .hero-badge {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      background: rgba(0, 229, 255, 0.1);
      border: 1px solid rgba(0, 229, 255, 0.3);
      color: var(--primary);
      padding: 0.3rem 0.85rem;
      border-radius: 999px;
      font-size: 0.85rem;
      font-weight: 600;
      margin-bottom: 1.5rem;
    }
    .hero h1 {
      font-size: 2.8rem;
      font-weight: 800;
      background: linear-gradient(135deg, #FFFFFF 0%, #00E5FF 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 1.25rem;
      line-height: 1.2;
    }
    .hero p {
      font-size: 1.15rem;
      color: var(--text-muted);
      max-width: 820px;
      margin: 0 auto 2rem auto;
      line-height: 1.7;
    }
    .hero-actions {
      display: flex;
      justify-content: center;
      gap: 1rem;
      flex-wrap: wrap;
      margin-bottom: 2rem;
    }
    .btn-primary {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      background: linear-gradient(135deg, var(--accent), var(--primary));
      color: #090D16;
      font-weight: 700;
      font-size: 1.05rem;
      padding: 0.85rem 2rem;
      border-radius: 8px;
      text-decoration: none;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .btn-primary:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 25px rgba(0, 229, 255, 0.4);
    }
    .btn-secondary {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      background: rgba(17, 24, 39, 0.8);
      border: 1px solid var(--card-border);
      color: var(--text);
      font-weight: 600;
      font-size: 1.05rem;
      padding: 0.85rem 1.75rem;
      border-radius: 8px;
      text-decoration: none;
      transition: border-color 0.2s, color 0.2s;
    }
    .btn-secondary:hover {
      border-color: var(--primary);
      color: var(--primary);
    }
    .quick-chips {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 0.75rem;
      flex-wrap: wrap;
      font-size: 0.88rem;
      color: var(--text-muted);
    }
    .chip {
      background: rgba(15, 23, 42, 0.7);
      border: 1px solid var(--card-border);
      color: #CBD5E1;
      padding: 0.35rem 0.85rem;
      border-radius: 999px;
      text-decoration: none;
      transition: border-color 0.2s, color 0.2s;
    }
    .chip:hover {
      border-color: var(--primary);
      color: var(--primary);
    }
    .category-section {
      margin-bottom: 3.5rem;
    }
    .category-header {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      border-bottom: 1px solid var(--card-border);
      padding-bottom: 0.6rem;
      margin-bottom: 1.5rem;
    }
    .category-title {
      font-size: 1.5rem;
      font-weight: 700;
      color: #FFFFFF;
    }
    .category-badge {
      background: rgba(0, 229, 255, 0.12);
      color: var(--primary);
      font-size: 0.8rem;
      font-weight: 700;
      padding: 0.2rem 0.6rem;
      border-radius: 999px;
    }
    .guides-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
      gap: 1.5rem;
    }
    .guide-card {
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 1.75rem;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      transition: transform 0.2s, border-color 0.2s, box-shadow 0.2s;
    }
    .guide-card:hover {
      transform: translateY(-3px);
      border-color: var(--primary);
      box-shadow: 0 6px 20px rgba(0, 229, 255, 0.15);
    }
    .card-tag {
      display: inline-block;
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      padding: 0.2rem 0.55rem;
      border-radius: 4px;
      background: rgba(0, 229, 255, 0.12);
      color: var(--primary);
      margin-bottom: 0.75rem;
      align-self: flex-start;
    }
    .guide-card h3 {
      font-size: 1.18rem;
      color: #FFFFFF;
      margin-bottom: 0.75rem;
      line-height: 1.4;
    }
    .guide-card p {
      font-size: 0.92rem;
      color: var(--text-muted);
      line-height: 1.6;
      margin-bottom: 1.25rem;
      flex-grow: 1;
    }
    .read-more {
      color: var(--primary);
      text-decoration: none;
      font-size: 0.9rem;
      font-weight: 600;
      display: inline-flex;
      align-items: center;
      gap: 0.25rem;
      transition: gap 0.2s;
    }
    .read-more:hover {
      gap: 0.5rem;
    }
    .methodology-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      gap: 1.5rem;
      margin-bottom: 3.5rem;
    }
    .methodology-card {
      background: #0F172A;
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 1.5rem;
    }
    .methodology-card h4 {
      color: var(--accent);
      font-size: 1.1rem;
      margin-bottom: 0.5rem;
    }
    .methodology-card p {
      color: var(--text-muted);
      font-size: 0.88rem;
      line-height: 1.6;
    }
    .disclaimer {
      background: rgba(245, 158, 11, 0.08);
      border-left: 4px solid #F59E0B;
      padding: 1.25rem 1.5rem;
      border-radius: 0 8px 8px 0;
      margin: 3.5rem 0;
      font-size: 0.9rem;
      color: #D1D5DB;
      line-height: 1.6;
    }
    .disclaimer strong {
      color: #F59E0B;
    }
    footer {
      background: #060911;
      border-top: 1px solid var(--card-border);
      padding: 3rem 1.5rem;
      text-align: center;
      font-size: 0.85rem;
      color: var(--text-muted);
    }
    .footer-links {
      display: flex;
      justify-content: center;
      gap: 1.75rem;
      margin-bottom: 1.25rem;
      flex-wrap: wrap;
    }
    .footer-links a {
      color: var(--text-muted);
      text-decoration: none;
      transition: color 0.2s;
    }
    .footer-links a:hover {
      color: var(--primary);
    }
  </style>
</head>
<body>

  <header>
    <a href="/" class="logo-container">
      <div class="logo-badge">QF</div>
      <div class="logo-title">Quantum Forge</div>
    </a>
    <nav>
      <a href="/app/" class="nav-cta">Launch 3D Lab</a>
      <a href="/guides/">Scientific Guides</a>
      <a href="/about.html">About</a>
      <a href="/contact.html">Contact</a>
      <a href="/privacy.html">Privacy Policy</a>
      <a href="/terms.html">Terms</a>
    </nav>
  </header>

  <main class="container">

    <!-- Hero Section -->
    <section class="hero">
      <div class="hero-badge">Dart Nexus Lab &middot; Theoretical & Computational Sciences</div>
      <h1>Next-Generation Reaction Dynamics &amp; Clinical Simulation Workstation</h1>
      <p>
        Quantum Forge bridges cutting-edge equivariant machine learning interatomic potentials (MACE, PaiNN), climbing-image nudged elastic band (CI-NEB) transition-state searches, collegiate clinical pharmacology monographs, and synchronized 3D organ hemodynamics in a unified web research environment.
      </p>
      <div class="hero-actions">
        <a href="/app/" class="btn-primary">
          Launch 3D Workstation &rarr;
        </a>
        <a href="/guides/" class="btn-secondary">
          Browse 16 Scientific Guides
        </a>
      </div>
      <div class="quick-chips">
        <span>Quick Modules:</span>
        <a href="/app/library" class="chip">Reaction Library</a>
        <a href="/app/cardio-cath" class="chip">CardioCath 3D</a>
        <a href="/app/neuro-lab" class="chip">NeuroLab 3D</a>
        <a href="/app/pharmacogenomics" class="chip">Pharmacogenomics</a>
        <a href="/app/osce" class="chip">OSCE Board Trainer</a>
      </div>
    </section>

    <!-- Platform Computational Methodology -->
    <section>
      <div class="category-header">
        <h2 class="category-title">Platform Computational Architecture</h2>
        <span class="category-badge">Research Methods</span>
      </div>
      <div class="methodology-grid">
        <div class="methodology-card">
          <h4>Equivariant PaiNN &amp; MACE Force Fields</h4>
          <p>Continuous spatial message-passing neural networks with rotational and translational equivariance, predicting interatomic forces with Mean Absolute Error &lt; 20 meV/&Aring; for rapid transition-state discovery.</p>
        </div>
        <div class="methodology-card">
          <h4>CI-NEB Transition State Optimization</h4>
          <p>Climbing Image Nudged Elastic Band algorithms identifying true index-1 saddle points on potential energy surfaces, computing harmonic vibrational frequencies and zero-point energy corrections.</p>
        </div>
        <div class="methodology-card">
          <h4>CardioCath 3D Fluoroscopy Engine</h4>
          <p>Phase-locked 3D electromechanical heart modeling, Beer-Lambert X-ray contrast advection, Murray's law coronary branching, and synchronized 5-channel bedside telemetry.</p>
        </div>
        <div class="methodology-card">
          <h4>Multi-Organ Biophysical Simulators</h4>
          <p>Integrated WebGL suites including NeuroLab 3D (Circle of Willis autoregulation), NephroLab 3D (glomerular filtration dynamics), and PulmoVent 3D (ARDS mechanical ventilation).</p>
        </div>
      </div>
    </section>

    <!-- Category 1: Clinical Pharmacology & Toxicology -->
    <section class="category-section">
      <div class="category-header">
        <h2 class="category-title">Clinical Pharmacology, Toxicology &amp; Pharmacogenomics</h2>
        <span class="category-badge">7 Monographs</span>
      </div>
      <div class="guides-grid">

        <article class="guide-card">
          <div>
            <span class="card-tag">Pharmacogenomics &middot; Anticoagulation</span>
            <h3>Warfarin: VKORC1 &amp; CYP2C9*2/*3 Kinetics</h3>
            <p>VKORC1 -1639G>A promoter polymorphism, CYP2C9 clearance reduction, Vitamin K epoxide redox cycle kinetics, factor half-life divergence, and IWPC dosing algorithms.</p>
          </div>
          <a href="/guides/warfarin-cyp2c9-vkorc1-dosing.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Microbiology &middot; Antimicrobial Resistance</span>
            <h3>Beta-Lactams: PBP2a &amp; ESBL Resistance</h3>
            <p>PBP transpeptidase acylation kinetics, mecA-encoded PBP2a allosteric resistance in MRSA, Ambler Class A–D beta-lactamases (TEM-52), and avibactam/vaborbactam inhibitors.</p>
          </div>
          <a href="/guides/beta-lactam-resistance-tem52-mrsa.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Cardiovascular Pharmacology &middot; Enzymology</span>
            <h3>HMG-CoA Reductase &amp; Statin Kinetics</h3>
            <p>Mevalonate transition-state mimicry (PDB 1HW8), lipophilic vs hydrophilic statin pharmacokinetics, SREBP-2 LDL receptor upregulation, and pleiotropic isoprenoid depletion.</p>
          </div>
          <a href="/guides/statin-hmg-coa-reductase-kinetics.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Clinical Pharmacology &middot; MBBS</span>
            <h3>Acetylsalicylic Acid: Ser-530 COX Acetylation</h3>
            <p>Structural biology of Cyclooxygenase-1/2, nucleophilic attack of Serine-530, steric occlusion of arachidonic acid, and antiplatelet clinical pharmacology.</p>
          </div>
          <a href="/guides/aspirin-cox-inhibition-mechanism.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Pharmacogenomics &middot; ADME</span>
            <h3>Cytochrome P450 Polymorphic Clearance</h3>
            <p>CYP2D6, CYP2C19, and CYP2C9 genetic variants, Poor vs Extensive metabolizer phenotypes, and CPIC guideline dosing adaptations.</p>
          </div>
          <a href="/guides/cyp450-pharmacogenomics-adme.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Toxicology &middot; Critical Care</span>
            <h3>Acetaminophen NAPQI Toxicity &amp; NAC Rescue</h3>
            <p>CYP2E1 bioactivation, glutathione depletion thresholds, mitochondrial permeability transition pore opening, and Rumack-Matthew nomogram kinetics.</p>
          </div>
          <a href="/guides/acetaminophen-napqi-hepatotoxicity.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Electrophysiology &middot; Cardiology</span>
            <h3>hERG Channel Blockade &amp; Torsades de Pointes</h3>
            <p>Kv11.1 cryo-EM structure (PDB 5VA1), aromatic cavity trapping, Phase 3 repolarization delay, Early Afterdepolarizations, and CiPA screening.</p>
          </div>
          <a href="/guides/herg-channel-qt-prolongation.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

      </div>
    </section>

    <!-- Category 2: Clinical Organ Hemodynamics & Critical Care -->
    <section class="category-section">
      <div class="category-header">
        <h2 class="category-title">Clinical Organ Hemodynamics &amp; Critical Care Physiology</h2>
        <span class="category-badge">5 Monographs</span>
      </div>
      <div class="guides-grid">

        <article class="guide-card">
          <div>
            <span class="card-tag">Neurovascular Physiology &middot; Hemodynamics</span>
            <h3>Circle of Willis &amp; Cerebral Autoregulation</h3>
            <p>Willisian polygon anatomical variants, myogenic Bayliss effect, chemical pCO2 autoregulation, leptomeningeal collaterals, and ischemic penumbra perfusion thresholds.</p>
          </div>
          <a href="/guides/circle-of-willis-cerebral-hemodynamics.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Renal Physiology &middot; Hemodynamics</span>
            <h3>Nephron GFR Dynamics &amp; RAAS Vasoconstriction</h3>
            <p>Starling ultrafiltration forces, macula densa tubuloglomerular feedback, Angiotensin II efferent vasoconstriction, and ACEi/ARB nephroprotection mechanisms.</p>
          </div>
          <a href="/guides/nephron-raas-gfr-filtration-dynamics.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Critical Care Pulmonology &middot; Mechanics</span>
            <h3>ARDS Respiratory Mechanics &amp; Driving Pressure</h3>
            <p>Berlin definition, static respiratory compliance (Crs), driving pressure (&Delta;P &le; 14 cmH2O), baby lung concept, PEEP recruitment, and PROSEVA prone positioning.</p>
          </div>
          <a href="/guides/ards-mechanical-ventilation-lung-mechanics.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Clinical Physiology &middot; Acid-Base</span>
            <h3>Acid-Base Physiology &amp; Anion Gap Kinetics</h3>
            <p>Henderson-Hasselbalch thermodynamic equilibrium, serum anion gap hypoalbuminemia correction, GOLDMARK differential, Winter's formula, and delta-delta ratios.</p>
          </div>
          <a href="/guides/acid-base-anion-gap-henderson-hasselbalch.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Interventional Cardiology &middot; Cath Lab</span>
            <h3>Coronary Bifurcation FFR &amp; Stent Dynamics</h3>
            <p>Navier-Stokes pulsatile coronary flow, Murray's law bifurcation branching, endothelial wall shear stress, and DK-Crush stenting mechanics.</p>
          </div>
          <a href="/guides/coronary-bifurcation-ffr-hemodynamics.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

      </div>
    </section>

    <!-- Category 3: Computational Chemistry & Reaction Kinetics -->
    <section class="category-section">
      <div class="category-header">
        <h2 class="category-title">Computational Chemistry, Reaction Kinetics &amp; Quantum Dynamics</h2>
        <span class="category-badge">4 Monographs</span>
      </div>
      <div class="guides-grid">

        <article class="guide-card">
          <div>
            <span class="card-tag">Physical Organic &middot; Pericyclic Reactions</span>
            <h3>Diels-Alder [4+2] Cycloaddition &amp; FMO Theory</h3>
            <p>Woodward-Hoffmann symmetry rules, frontier molecular orbital HOMO-LUMO gap narrowing, the Alder Endo Rule, and synchronous transition states.</p>
          </div>
          <a href="/guides/diels-alder-pericyclic-frontier-orbitals.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Reaction Kinetics &middot; Pharm-D</span>
            <h3>Nucleophilic Substitution: SN1 vs SN2 Pathways</h3>
            <p>Transition-state geometries, Walden inversion, carbocation lifetime, solvent effects (protic vs aprotic), and Eyring activation entropy signatures.</p>
          </div>
          <a href="/guides/sn1-vs-sn2-reaction-kinetics.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">Quantum Chemistry &middot; Theory</span>
            <h3>Transition-State Theory &amp; Activation Barriers</h3>
            <p>Potential energy surfaces (PES), index-1 saddle points, harmonic TST, and Climbing Image Nudged Elastic Band (CI-NEB) algorithms.</p>
          </div>
          <a href="/guides/transition-state-theory-activation-energy.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

        <article class="guide-card">
          <div>
            <span class="card-tag">AI &amp; Machine Learning &middot; MLIP</span>
            <h3>Equivariant Neural Force Fields vs MMFF94 &amp; DFT</h3>
            <p>E(3)-equivariant message passing architectures (MACE, PaiNN), body-order expansions, and sub-second ab initio force prediction benchmarks.</p>
          </div>
          <a href="/guides/machine-learning-interatomic-potentials.html" class="read-more">Read Full Guide &rarr;</a>
        </article>

      </div>
    </section>

    <!-- SaMD Educational Disclaimer -->
    <div class="disclaimer">
      <strong>Software as a Medical Device (SaMD) Educational Shield:</strong> Quantum Forge is strictly an educational simulation and theoretical computational modeling platform engineered by Dart Nexus Lab. It does not provide medical advice, diagnosis, treatment, or patient-specific recommendations. Clinical decisions must always be made by licensed medical practitioners.
    </div>

  </main>

  <footer>
    <div class="footer-links">
      <a href="/app/">Launch 3D Workstation</a>
      <a href="/guides/">All 16 Scientific Guides</a>
      <a href="/about.html">About</a>
      <a href="/contact.html">Contact</a>
      <a href="/privacy.html">Privacy Policy</a>
      <a href="/terms.html">Terms of Service</a>
      <a href="/sitemap.xml">XML Sitemap</a>
    </div>
    <p>Copyright &copy; 2026 Dart Nexus Lab. All Rights Reserved. Quantum Forge&trade; &mdash; A Product of Dart Nexus Lab &middot; Educational Simulation Platform.</p>
  </footer>

</body>
</html>
"""

with open(homepage_path, "w") as f:
    f.write(html)

print("Generated decoupled editorial homepage at quantum_forge/static_site/index.html!")
