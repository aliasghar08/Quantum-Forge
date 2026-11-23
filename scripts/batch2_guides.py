import os
import re

out_dir = "quantum_forge/web/guides"
os.makedirs(out_dir, exist_ok=True)

from generate_all_8_guides import create_guide_html

amazon_link_pharm = "https://link.amazon/B03y4mxsi"
amazon_title_pharm = "Katzung’s Basic & Clinical Pharmacology (16th Ed.) &rarr;"
amazon_desc_pharm = "Comprehensive clinical reference for receptor kinetics, CYP450 metabolism, pharmacogenomics, and anticoagulant pharmacology."

amazon_link_phys = "https://link.amazon/B05IasrT1"
amazon_title_phys = "Guyton and Hall Textbook of Medical Physiology (14th Ed.) &rarr;"
amazon_desc_phys = "Foundational textbook on systemic hemodynamics, renal clearance, microvascular Starling forces, and respiratory gas exchange."

amazon_link_chem = "https://link.amazon/B0bLTrZvk"
amazon_title_chem = "Atkins’ Physical Chemistry (12th Ed.) &rarr;"
amazon_desc_chem = "Authoritative guide covering quantum mechanics, molecular orbital theory, pericyclic symmetry rules, and chemical reaction dynamics."

# ==============================================================================
# GUIDE 5: Renal Glomerular Filtration Dynamics & RAAS
# ==============================================================================
slug5 = "nephron-raas-gfr-filtration-dynamics.html"
title5 = "Renal Glomerular Filtration Dynamics: Starling Forces, RAAS Vasoconstriction & ACEi/ARB Nephroprotection"
meta_title5 = "Renal Glomerular Filtration & RAAS Hemodynamics"
meta_desc5 = "Comprehensive renal physiology monograph on Starling forces of glomerular ultrafiltration, macula densa tubuloglomerular feedback, Angiotensin II efferent vasoconstriction, and ACEi/ARB nephroprotective mechanisms."
category5 = "Renal Physiology & Hemodynamics"
read_time5 = "15 min read"

body5 = """
      <h2>1. The Glomerular Filtration Barrier: Architecture & Permselectivity</h2>
      <p>
        The human kidneys receive roughly 20–25% of total resting cardiac output (~1,000–1,200 mL/min of renal blood flow, or ~600 mL/min of renal plasma flow [RPF]), filtering approximately 180 liters of plasma ultrafiltrate each day. This colossal fluid exchange is executed across approximately 2 million microscopic filtering units: the <strong>Glomeruli</strong>.
      </p>
      <p>
        The <strong>Glomerular Filtration Barrier (GFB)</strong> is a sophisticated, three-layered biological sieve possessing extreme hydraulic conductivity while maintaining near-absolute retention of albumin (molecular weight ~66.5 kDa) and cellular blood elements:
      </p>
      <ol>
        <li><strong>Fenestrated Endothelium:</strong> Endothelial cells lining the glomerular capillaries contain transcellular pores (fenestrae) with diameters of 70 to 100 nm. These pores prevent passage of erythrocytes and platelets, but freely admit fluid, electrolytes, and small proteins. The luminal glycocalyx contains polyanionic sialoproteins and proteoglycans that confer charge selectivity.</li>
        <li><strong>Glomerular Basement Membrane (GBM):</strong> A dense acellular matrix (thickness ~300–350 nm) composed of a specialized type IV collagen (&alpha;3&alpha;4&alpha;5 network), laminin-521, nidogen, and <strong>heparan sulfate proteoglycans (agrin, perlecan)</strong>. The high density of sulfate groups confers a dense net negative charge, repelling polyanionic circulating serum proteins.</li>
        <li><strong>Podocyte Slit Diaphragm:</strong> Terminally differentiated visceral epithelial cells (podocytes) wrap interdigitating foot processes (pedicels) around the capillary loops. The filtration slits (width ~30–40 nm) between adjacent pedicels are bridged by the <strong>Slit Diaphragm</strong>—a continuous proteinaceous zipper comprising <strong>nephrin, podocin, FAT1, and CD2AP</strong> linked intracellularly to the actin cytoskeleton. Nephrin mutations (e.g., Finnish-type congenital nephrotic syndrome) result in massive proteinuria.</li>
      </ol>

      <h2>2. Starling Forces of Ultrafiltration & Mathematical Modeling</h2>
      <p>
        Glomerular filtration is driven by physical hydrostatic and oncotic pressure differentials across the capillary wall, governed by the classical Starling equation adapted for renal microvasculature:
      </p>

      <div class="math-block">
        GFR = K_f &middot; P_UF = K_f &middot; [ ( P_GC - P_BS ) - &sigma; &middot; ( &pi;_GC - &pi;_BS ) ]<br><br>
        where:<br>
        - K_f = Ultrafiltration coefficient (hydraulic conductivity &middot; surface area; ~12.5 mL/min/mmHg)<br>
        - P_GC = Glomerular capillary hydrostatic pressure (~45 to 50 mmHg)<br>
        - P_BS = Bowman space hydrostatic pressure (~10 to 12 mmHg)<br>
        - &sigma; = Staverman reflection coefficient for albumin (&approx; 1.0 in healthy GFB)<br>
        - &pi;_GC = Glomerular capillary oncotic pressure (~25 mmHg at afferent end &rarr; ~35 mmHg at efferent end)<br>
        - &pi;_BS = Bowman space oncotic pressure (&approx; 0 mmHg in healthy urine)
      </div>

      <p>
        Unlike systemic capillary beds where hydrostatic pressure plummets by 50% from the arteriolar to the venular end, the unique architecture of the glomerulus—being positioned between two muscular resistance vessels, the <strong>afferent arteriole</strong> and the <strong>efferent arteriole</strong>—maintains an exceptionally high and flat hydrostatic pressure (<strong>P<sub>GC</sub> ~ 45–50 mmHg</strong>) across the entire capillary length.
      </p>
      <p>
        However, because a massive volume of protein-free fluid is progressively filtered out into Bowman's space (filtration fraction FF = GFR / RPF &approx; 20%), the protein concentration in the capillary lumen rises steeply. Consequently, glomerular capillary oncotic pressure (<strong>&pi;<sub>GC</sub></strong>) climbs from ~25 mmHg at the afferent entrance to ~35 mmHg at the efferent exit. When net ultrafiltration pressure reaches zero (P<sub>UF</sub> = 0), filtration equilibrium is achieved.
      </p>

      <table>
        <thead>
          <tr>
            <th>Hemodynamic Parameter</th>
            <th>Afferent End of Glomerulus</th>
            <th>Efferent End of Glomerulus</th>
            <th>Net Physiological Gradient</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Capillary Hydrostatic Pressure (P_GC)</strong></td>
            <td>48 mmHg</td>
            <td>46 mmHg</td>
            <td>High, maintained hydrostatic driving force</td>
          </tr>
          <tr>
            <td><strong>Bowman Space Pressure (P_BS)</strong></td>
            <td>10 mmHg</td>
            <td>10 mmHg</td>
            <td>Constant back-pressure</td>
          </tr>
          <tr>
            <td><strong>Capillary Oncotic Pressure (&pi;_GC)</strong></td>
            <td>25 mmHg</td>
            <td>35 mmHg</td>
            <td><strong>Rises by +10 mmHg</strong> due to fluid hemoconcentration</td>
          </tr>
          <tr>
            <td><strong>Net Ultrafiltration Pressure (P_UF)</strong></td>
            <td><strong>+13 mmHg</strong> (Robust filtration)</td>
            <td><strong>+1 mmHg</strong> (Filtration equilibrium)</td>
            <td>Favors outward filtration along entire bed</td>
          </tr>
        </tbody>
      </table>

      <h2>3. Autoregulation & Tubuloglomerular Feedback (TGF)</h2>
      <p>
        Renal autoregulation protects the fragile glomerular microvasculature from systemic hypertensive injury while preventing renal insufficiency during moderate hypotension. Autoregulation maintains a stable GFR (~120 mL/min/1.73m<sup>2</sup>) across Mean Arterial Pressures between 80 and 170 mmHg via two coordinated mechanisms:
      </p>
      <h3>1. Myogenic Stretch Response</h3>
      <p>
        Direct vascular smooth muscle contraction of the <strong>afferent arteriole</strong> in response to elevated transmural pressure, mediated by stretch-sensitive ion channels and calcium influx.
      </p>
      <h3>2. Macula Densa Tubuloglomerular Feedback (TGF)</h3>
      <p>
        The <strong>Macula Densa</strong> consists of specialized columnar epithelial cells in the thick ascending limb of the loop of Henle positioned in direct anatomical contact with the vascular pole of its originating glomerulus (the juxtaglomerular apparatus, JGA).
      </p>
      <ul>
        <li>If GFR rises, excessive NaCl delivery escapes proximal reabsorption and reaches the macula densa.</li>
        <li>Macula densa cells take up Na<sup>+</sup> and 2 Cl<sup>-</sup> via the apical <strong>NKCC2 cotransporter</strong>.</li>
        <li>Intracellular chloride accumulation causes basolateral ATP release.</li>
        <li>Extracellular ecto-5'-nucleotidase cleaves ATP to <strong>Adenosine</strong>.</li>
        <li>Adenosine binds vascular smooth muscle <strong>A1 receptors</strong> on the adjacent <strong>afferent arteriole</strong>, causing vasoconstriction, which lowers P<sub>GC</sub> and normalizes GFR.</li>
      </ul>

      <h2>4. RAAS Activation & Angiotensin II Differential Arteriolar Tone</h2>
      <p>
        When systemic arterial pressure falls or renal perfusion is compromised (e.g., in hypovolemia, cardiogenic shock, or bilateral renal artery stenosis), the juxtaglomerular granular cells release <strong>Renin</strong> into circulation. Renin cleaves hepatic angiotensinogen to Angiotensin I, which is converted by pulmonary endothelial Angiotensin-Converting Enzyme (ACE) to the octapeptide hormone <strong>Angiotensin II (Ang II)</strong>.
      </p>
      <p>
        Crucially, Angiotensin II acts as a <strong>preferential vasoconstrictor of the efferent arteriole</strong> (via AT<sub>1</sub> receptors) at physiological and mildly elevated concentrations. This differential vasoconstriction is life-preserving:
      </p>

      <div class="math-block">
        [Efferent Arteriolar Vasoconstriction Response]:<br>
        &uarr; R_efferent &rarr; &darr; Renal Plasma Flow (RPF) BUT &uarr; Glomerular Hydrostatic Pressure (P_GC)<br>
        Result: Preserves GFR and Filtration Fraction (FF = GFR / RPF) during systemic hypoperfusion!
      </div>

      <p>
        Concurrently, intrarenal synthesis of <strong>Prostaglandins (PGE2, PGI2)</strong> via cyclooxygenase enzymes (COX-1/COX-2) selectively dilates the <strong>afferent arteriole</strong>, neutralizing excessive Ang II-mediated afferent constriction and safeguarding renal plasma flow.
      </p>

      <div class="callout">
        <h4>The NSAID + ACEi/ARB "Triple Whammy" Acute Kidney Injury</h4>
        <p>
          The delicate balance between afferent prostaglandin dilation and efferent Ang II constriction explains the lethal pharmacology of <strong>Hemodynamically Mediated Acute Kidney Injury</strong>:
          <br>&bull; <strong>NSAIDs:</strong> Inhibit COX enzymes, blocking PGE2/PGI2 synthesis and causing unchecked afferent arteriolar vasoconstriction (pinching the inflow).
          <br>&bull; <strong>ACE Inhibitors / ARBs:</strong> Block Ang II synthesis/action, causing efferent arteriolar vasodilation (opening the outflow gate).
          <br>&bull; When combined with dehydration or diuretics ("Triple Whammy"), glomerular hydrostatic pressure (P<sub>GC</sub>) collapses, dropping GFR to zero and precipitating acute anuric renal failure. For related COX pharmacology, see our guide on <a href="/guides/aspirin-cox-inhibition-mechanism.html">Aspirin & COX Inhibition</a>.
        </p>
      </div>

      <h2>5. Pharmacological Nephroprotection: ACEi & ARBs in Chronic Kidney Disease</h2>
      <p>
        In diabetic kidney disease and chronic glomerular hyperfiltration, sustained intraglomerular hypertension (P<sub>GC</sub> &gt; 60 mmHg) exerts mechanical stretch on podocytes, inducing foot process effacement, detachment, and progressive glomerular sclerosis.
      </p>
      <p>
        By competitively inhibiting ACE (e.g., Lisinopril, Ramipril) or blocking the AT<sub>1</sub> receptor (e.g., Losartan, Valsartan), these agents selectively relax the efferent arteriole. This reduces P<sub>GC</sub>, lowers the trans-glomerular pressure gradient, and arrests mechanical podocyte damage, significantly blunting albuminuria and slowing progression to end-stage renal disease (ESRD).
      </p>
      <p>
        Clinicians must expect an acute, benign rise in serum creatinine of up to <strong>20–30%</strong> within the first 1–2 weeks of initiating ACEi/ARB therapy—this reflects the desired therapeutic reduction in intraglomerular pressure, not structural nephrotoxicity! Cross-reference our pharmacogenomics guide on <a href="/guides/cyp450-pharmacogenomics-adme.html">Cytochrome P450 Pharmacogenomics</a>.
      </p>

      <div class="interactive-card">
        <h4>Simulate Glomerular Starling Dynamics in 3D</h4>
        <p>Model afferent vs efferent arteriolar resistance, Starling pressure gradients, and nephron filtration in the live Quantum Forge 3D Workstation.</p>
        <a href="/">Launch 3D Workstation &rarr;</a>
      </div>
"""

refs5 = [
    "Brenner, B. M., et al. (2001). Effects of losartan on renal and cardiovascular outcomes in patients with type 2 diabetes and nephropathy. <em>N. Engl. J. Med.</em>, 345(12), 861–869. <a href=\"https://doi.org/10.1056/NEJMoa011161\" target=\"_blank\" rel=\"noopener\">doi:10.1056/NEJMoa011161</a>",
    "Navar, L. G. (2014). Physiology of the autoregulation of renal blood flow and glomerular filtration rate. <em>Nephron Physiol.</em>, 127(1-4), 139–144. <a href=\"https://doi.org/10.1159/000363046\" target=\"_blank\" rel=\"noopener\">doi:10.1159/000363046</a>",
    "Haraldsson, B., Nystrom, J., & Deen, W. M. (2008). Properties of the glomerular barrier and mechanisms of proteinuria. <em>Physiol. Rev.</em>, 88(2), 451–487. <a href=\"https://doi.org/10.1152/physrev.00055.2006\" target=\"_blank\" rel=\"noopener\">doi:10.1152/physrev.00055.2006</a>",
    "Garg, P. (2018). A review of podocyte biology. <em>Am. J. Nephrol.</em>, 47(Suppl 1), 3–13. <a href=\"https://doi.org/10.1159/000481633\" target=\"_blank\" rel=\"noopener\">doi:10.1159/000481633</a>"
]

html5 = create_guide_html(slug5, title5, meta_title5, meta_desc5, category5, read_time5, body5, amazon_link_phys, amazon_title_phys, amazon_desc_phys, refs5)
with open(os.path.join(out_dir, slug5), "w") as f:
    f.write(html5)
print(f"Generated {slug5}")

# ==============================================================================
# GUIDE 6: ARDS & Mechanical Ventilation Lung Mechanics
# ==============================================================================
slug6 = "ards-mechanical-ventilation-lung-mechanics.html"
title6 = "ARDS Respiratory Mechanics: PEEP Recruitment, Driving Pressure, Compliance Loops & V/Q Matching"
meta_title6 = "ARDS Respiratory Mechanics & Mechanical Ventilation"
meta_desc6 = "Critical care pulmonology monograph on Acute Respiratory Distress Syndrome (ARDS) pathophysiology, respiratory system compliance, driving pressure (Delta-P), open-lung PEEP titration, and prone ventilation."
category6 = "Critical Care Pulmonology & Respiratory Mechanics"
read_time6 = "16 min read"

body6 = """
      <h2>1. Pathophysiology of ARDS: The Exudative Phase & Alveolar Flooding</h2>
      <p>
        <strong>Acute Respiratory Distress Syndrome (ARDS)</strong> is a life-threatening form of acute hypoxemic respiratory failure characterized by non-cardiogenic pulmonary edema, widespread alveolar inflammation, surfactant destruction, and severe ventilation-perfusion (V/Q) mismatching. Under the current <strong>Berlin Definition</strong>, ARDS is diagnosed by:
      </p>
      <ul>
        <li>Onset within 1 week of a known clinical insult or new/worsening respiratory symptoms.</li>
        <li>Bilateral pulmonary opacities on chest radiography or CT not fully explained by pleural effusions, lobar atelectasis, or lung nodules.</li>
        <li>Respiratory failure not fully explained by left ventricular heart failure or fluid overload (confirmed via echocardiography or pulmonary artery wedge pressure &le;18 mmHg).</li>
        <li>Severe hypoxemia measured by the <strong>PaO2 / FiO2 (P/F) ratio</strong> on a minimum Positive End-Expiratory Pressure (PEEP) &ge;5 cmH<sub>2</sub>O:
          <ul>
            <li><strong>Mild ARDS:</strong> 200 &lt; P/F &le; 300 mmHg.</li>
            <li><strong>Moderate ARDS:</strong> 100 &lt; P/F &le; 200 mmHg.</li>
            <li><strong>Severe ARDS:</strong> P/F &le; 100 mmHg (associated with hospital mortality &gt;45%).</li>
          </ul>
        </li>
      </ul>
      <p>
        The histological hallmark of ARDS is <strong>Diffuse Alveolar Damage (DAD)</strong>. Pro-inflammatory cytokines (TNF-alpha, IL-1beta, IL-6, IL-8) recruit activated neutrophils to the pulmonary microvasculature. Neutrophils release reactive oxygen species (ROS) and elastase, degrading the microvascular endothelium and alveolar epithelial barrier (type I and type II pneumocytes). Protein-rich exudate floods the alveolar spaces, organizing into eosinophilic <strong>hyaline membranes</strong> that act as physical barriers to gas diffusion.
      </p>

      <h2>2. Respiratory Mechanics & Governing Equations</h2>
      <p>
        In passive, paralyzed mechanically ventilated patients, total respiratory system mechanics are described by the classical <strong>Equation of Motion</strong>:
      </p>

      <div class="math-block">
        P_aw(t) = P_resistive + P_elastic + PEEP_tot<br>
        P_aw(t) = ( Flow &middot; R_aw ) + ( V_T / C_rs ) + PEEP_tot<br><br>
        where:<br>
        - P_peak = Peak inspiratory pressure (reflects both airway resistance and lung elastance)<br>
        - P_plat = Plateau pressure measured during an end-inspiratory pause (zero flow &rarr; purely elastic)<br>
        - PEEP_tot = Total PEEP (Extrinsic PEEP + Intrinsic Auto-PEEP)<br>
        - R_aw = Airway resistance = ( P_peak - P_plat ) / Inspiratory Flow<br>
        - C_rs = Static respiratory system compliance = V_T / ( P_plat - PEEP_tot )
      </div>

      <p>
        In healthy adults, respiratory system compliance (C<sub>rs</sub>) is approximately <strong>60 to 100 mL/cmH<sub>2</sub>O</strong>. In severe ARDS, alveolar collapse and fluid filling dramatically shrink functional aerated lung volume—a phenomenon termed the <strong>"Baby Lung"</strong> (Gattinoni). Static compliance frequently drops below <strong>20 to 30 mL/cmH<sub>2</sub>O</strong>.
      </p>

      <h2>3. Driving Pressure (&Delta;P): The Core Determinant of Ventilator-Induced Lung Injury</h2>
      <p>
        Historically, lung-protective ventilation focused exclusively on limiting tidal volume (V<sub>T</sub> to 6 mL/kg predicted body weight [PBW]) and plateau pressure (P<sub>plat</sub> &le; 30 cmH<sub>2</sub>O; ARMA trial). However, landmark research by Amato et al. demonstrated that <strong>Driving Pressure (&Delta;P)</strong> is the variable most strongly correlated with survival:
      </p>

      <div class="math-block">
        &Delta;P = P_plat - PEEP = V_T / C_rs
      </div>

      <p>
        Driving pressure represents the tidal volume normalized to the actual compliance of the aerated "baby lung." A tidal volume of 400 mL delivered into a lung with C<sub>rs</sub> = 50 mL/cmH<sub>2</sub>O yields a safe &Delta;P of 8 cmH<sub>2</sub>O. However, the exact same 400 mL delivered into an ARDS lung with C<sub>rs</sub> = 20 mL/cmH<sub>2</sub>O generates a destructive &Delta;P of 20 cmH<sub>2</sub>O!
      </p>

      <table>
        <thead>
          <tr>
            <th>Mechanical Ventilation Metric</th>
            <th>Safe Protective Target</th>
            <th>Pathological Threshold</th>
            <th>VILI Mechanism</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Driving Pressure (&Delta;P)</strong></td>
            <td><strong>&le; 14 – 15 cmH2O</strong></td>
            <td>&gt; 15 cmH2O (Linear increase in mortality)</td>
            <td>Cyclic mechanical strain causing alveolar rupture and biotrauma.</td>
          </tr>
          <tr>
            <td><strong>Plateau Pressure (P_plat)</strong></td>
            <td><strong>&le; 28 – 30 cmH2O</strong></td>
            <td>&gt; 30 cmH2O</td>
            <td><strong>Barotrauma / Volutrauma:</strong> Alveolar overdistension and air leaks (pneumothorax).</td>
          </tr>
          <tr>
            <td><strong>Tidal Volume (V_T)</strong></td>
            <td><strong>4 – 8 mL/kg PBW</strong></td>
            <td>&gt; 8–10 mL/kg PBW</td>
            <td>Volutrauma in compliant non-dependent lung zones.</td>
          </tr>
          <tr>
            <td><strong>Mechanical Power</strong></td>
            <td><strong>&le; 17 – 20 J/min</strong></td>
            <td>&gt; 22 J/min</td>
            <td>Total kinetic and elastic energy deposited into lung tissue per minute.</td>
          </tr>
        </tbody>
      </table>

      <h2>4. Open-Lung Strategy: PEEP Titration & Alveolar Recruitment</h2>
      <p>
        Positive End-Expiratory Pressure (PEEP) prevents end-expiratory alveolar collapse, recruiting unstable dorsal units and improving functional residual capacity (FRC). In the pressure-volume loop, setting PEEP above the <strong>Lower Inflection Point (LIP)</strong> prevents <strong>Atelectrauma</strong>—the repetitive opening and closing of derecruited alveoli that shears epithelial walls.
      </p>
      <p>
        However, excessive PEEP distends already-open alveoli, causing vascular compression of pulmonary capillaries, increasing pulmonary vascular resistance (PVR), acute right ventricular overload (cor pulmonale), and systemic hypotension. An optimal PEEP titration trial identifies the "sweet spot" where compliance is maximized and driving pressure is minimized.
      </p>

      <h2>5. Prone Positioning: Fluid Mechanics of Gravity & Pleural Pressure</h2>
      <p>
        The <strong>PROSEVA trial</strong> established that early, prolonged prone positioning (&ge;16 hours/day) in patients with severe ARDS (P/F &lt; 150 mmHg) cuts 28-day mortality by nearly half (16.0% vs. 32.8%). The mechanism is fundamentally biomechanical:
      </p>
      <ul>
        <li><strong>In the Supine Position:</strong> The heavy, edematous lung tissue (up to 3x normal weight) and the weight of the heart compress dependent dorsal lung zones. The vertical gradient of pleural pressure (P<sub>pl</sub>) is steep (-2 cmH<sub>2</sub>O anteriorly to +8 cmH<sub>2</sub>O posteriorly), causing widespread dorsal atelectasis.</li>
        <li><strong>In the Prone Position:</strong> The heart rests on the anterior chest wall, and the cylindrical geometry of the rib cage distributes pleural pressure far more homogeneously throughout the thoracic cavity. Transpulmonary pressure (P<sub>L</sub> = P<sub>aw</sub> - P<sub>pl</sub>) becomes uniform.</li>
        <li><strong>V/Q Matching:</strong> Pulmonary blood flow remains preferentially distributed to dorsal lung regions due to native vascular branching geometry, regardless of patient orientation. Turning the patient prone re-aerates dorsal alveoli while blood flow remains dorsal, dramatically matching ventilation with perfusion and abolishing intrapulmonary right-to-left shunt.</li>
      </ul>

      <div class="interactive-card">
        <h4>Simulate PulmoVent 3D Respiratory Mechanics</h4>
        <p>Explore real-time pressure-volume loops, compliance curves, PEEP recruitment, and driving pressure in the live Quantum Forge 3D Workstation.</p>
        <a href="/">Launch 3D Workstation &rarr;</a>
      </div>
"""

refs6 = [
    "The ARDS Definition Task Force. (2012). Acute respiratory distress syndrome: the Berlin Definition. <em>JAMA</em>, 307(23), 2526–2533. <a href=\"https://doi.org/10.1001/jama.2012.5669\" target=\"_blank\" rel=\"noopener\">doi:10.1001/jama.2012.5669</a>",
    "Amato, M. B., et al. (2015). Driving pressure and survival in the acute respiratory distress syndrome. <em>N. Engl. J. Med.</em>, 372(8), 747–755. <a href=\"https://doi.org/10.1056/NEJMoa1410639\" target=\"_blank\" rel=\"noopener\">doi:10.1056/NEJMoa1410639</a>",
    "Guerin, C., et al. (2013). Prone positioning in severe acute respiratory distress syndrome (PROSEVA). <em>N. Engl. J. Med.</em>, 368(23), 2159–2168. <a href=\"https://doi.org/10.1056/NEJMoa1214103\" target=\"_blank\" rel=\"noopener\">doi:10.1056/NEJMoa1214103</a>",
    "Gattinoni, L., et al. (2016). The 'baby lung' became an adult. <em>Intensive Care Med.</em>, 42(5), 663–673. <a href=\"https://doi.org/10.1007/s00134-015-4200-8\" target=\"_blank\" rel=\"noopener\">doi:10.1007/s00134-015-4200-8</a>"
]

html6 = create_guide_html(slug6, title6, meta_title6, meta_desc6, category6, read_time6, body6, amazon_link_phys, amazon_title_phys, amazon_desc_phys, refs6)
with open(os.path.join(out_dir, slug6), "w") as f:
    f.write(html6)
print(f"Generated {slug6}")

# ==============================================================================
# GUIDE 7: Diels-Alder [4+2] Cycloaddition & FMO Theory
# ==============================================================================
slug7 = "diels-alder-pericyclic-frontier-orbitals.html"
title7 = "Diels-Alder [4+2] Cycloaddition: Frontier Molecular Orbital Theory, Endo Rule & Synchronous Transition States"
meta_title7 = "Diels-Alder [4+2] Cycloaddition & FMO Theory"
meta_desc7 = "Rigorous physical organic chemistry monograph on the Diels-Alder [4+2] cycloaddition: Woodward-Hoffmann symmetry rules, FMO HOMO-LUMO gap narrowing, the Alder Endo Rule, and CI-NEB transition-state modeling."
category7 = "Physical Organic & Quantum Chemistry"
read_time7 = "15 min read"

body7 = """
      <h2>1. The Archetype of Pericyclic Reactions</h2>
      <p>
        The <strong>Diels-Alder reaction</strong>—first discovered in 1928 by Otto Diels and Kurt Alder (Nobel Prize in Chemistry, 1950)—is the quintessential <strong>[4&pi; + 2&pi;] pericyclic cycloaddition</strong> in synthetic organic chemistry. In a single concerted step, a conjugated 1,3-diene reacts with an alkene or alkyne (the <strong>dienophile</strong>) to forge a six-membered cyclohexene ring with the simultaneous formation of two new carbon-carbon sigma (&sigma;) bonds at the expense of two carbon-carbon pi (&pi;) bonds.
      </p>
      <p>
        The reaction is stereospecific, regioselective, and frequently diastereoselective. It serves as the bedrock synthetic transformation for assembling complex bridged bicyclic architectures, polycyclic terpenes, steroids, and active pharmaceutical ingredients (APIs).
      </p>

      <h2>2. Conservation of Orbital Symmetry & Woodward-Hoffmann Rules</h2>
      <p>
        Under the <strong>Woodward-Hoffmann rules</strong>, pericyclic reactions proceed concertedly via cyclic transition states if the total number of (4q+2)<sub>s</sub> and (4r)<sub>a</sub> electrons is odd. For the thermal Diels-Alder reaction:
      </p>

      <div class="math-block">
        Number of interacting electrons = 4 (diene) + 2 (dienophile) = 6 &pi; electrons<br>
        6 = 4n + 2 (where n = 1)<br>
        Pathway: Thermal [&pi;4_s + &pi;2_s] (Suprafacial-Suprafacial Cycloaddition)<br>
        Symmetry status: Thermally Allowed (H&uuml;ckel transition state with zero phase inversions)
      </div>

      <p>
        Because the diene reacts in a <strong>suprafacial</strong> manner (both new &sigma;-bonds form on the same face of the &pi;-system), the diene must be capable of adopting an <strong>s-cis (cisoid) conformation</strong> around its single C2–C3 carbon-carbon bond. Acyclic dienes with severe steric hindrance in the s-cis geometry react sluggishly, whereas locked s-cis cyclic dienes (such as cyclopentadiene) react with explosive exothermic velocity. Dienes permanently locked in the s-trans conformation (such as trans,trans-1,4-di-tert-butyl-1,3-butadiene) are completely inert to Diels-Alder cycloaddition.
      </p>

      <h2>3. Frontier Molecular Orbital (FMO) Theory: HOMO-LUMO Interactions</h2>
      <p>
        The reactivity and reaction rate of a Diels-Alder cycloaddition are governed by the interaction between the <strong>Highest Occupied Molecular Orbital (HOMO)</strong> of one partner and the <strong>Lowest Unoccupied Molecular Orbital (LUMO)</strong> of the other partner. According to second-order perturbation theory, the stabilizing interaction energy (&Delta;E) between two interacting orbitals is given by Salem and Klopman's equation:
      </p>

      <div class="math-block">
        &Delta;E_interaction &approx; ( 2 &middot; [ &Sigma; c_diene &middot; c_dienophile &middot; &beta; ]^2 ) / ( E_HOMO - E_LUMO )
      </div>

      <p>
        Because the stabilization energy varies inversely with the energy difference <strong>(E<sub>HOMO</sub> - E<sub>LUMO</sub>)</strong>, narrowing the HOMO-LUMO energy gap exponentially accelerates the reaction rate (k) by lowering the Arrhenius activation energy barrier (E<sub>a</sub>).
      </p>

      <table>
        <thead>
          <tr>
            <th>Cycloaddition Demand Type</th>
            <th>Dominant Orbital Interaction</th>
            <th>Diene Electronic Nature</th>
            <th>Dienophile Electronic Nature</th>
            <th>Representative Synthetic Example</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Normal Electron-Demand (NED)</strong></td>
            <td><strong>HOMO_diene &rarr; LUMO_dienophile</strong></td>
            <td>Electron-rich: substituted with <strong>Electron-Donating Groups (EDG)</strong> (-OMe, -NR2, -Alkyl, -OTMS)</td>
            <td>Electron-poor: substituted with <strong>Electron-Withdrawing Groups (EWG)</strong> (-CHO, -COR, -COOR, -CN, -NO2)</td>
            <td>Cyclopentadiene + Maleic Anhydride or Acrolein. Danishefsky's diene + Methyl Acrylate.</td>
          </tr>
          <tr>
            <td><strong>Inverse Electron-Demand (IEDDA)</strong></td>
            <td><strong>HOMO_dienophile &rarr; LUMO_diene</strong></td>
            <td>Electron-poor diene: substituted with strong EWGs (e.g., 1,2,4,5-tetrazines, 1,2-diazines)</td>
            <td>Electron-rich dienophile: strained alkenes (trans-cyclooctene [TCO], bicyclononynes), enol ethers</td>
            <td>Bioorthogonal click chemistry in living systems: Tetrazine-TCO ligations.</td>
          </tr>
        </tbody>
      </table>

      <h3>How Substituents Modulate Orbital Energies</h3>
      <p>
        In normal electron-demand reactions, an Electron-Donating Group on the diene (e.g., the methoxy group in Danishefsky's diene) donates lone pair electron density through resonance, raising the energy of the diene HOMO. Conversely, an Electron-Withdrawing Group on the dienophile (e.g., the cyano group in acrylonitrile) withdraws electron density through &pi;*-conjugation, lowering the dienophile LUMO.
      </p>
      <p>
        This simultaneous elevation of E<sub>HOMO(diene)</sub> and depression of E<sub>LUMO(dienophile)</sub> shrinks the energy denominator from ~11 eV (for unsubstituted ethylene + 1,3-butadiene, which requires &gt;200&deg;C under pressure) down to &lt;6 eV, permitting reactions to proceed smoothly at room temperature in minutes! For foundational activation barrier theory, review our guide on <a href="/guides/transition-state-theory-activation-energy.html">Transition-State Theory & Potential Energy Surfaces</a>.
      </p>

      <h2>4. Stereochemistry: The Alder Endo Rule & Secondary Orbital Overlap</h2>
      <p>
        When a cyclic diene (such as cyclopentadiene) reacts with a substituted dienophile (such as maleic anhydride or methyl acrylate), two diastereomeric transition states are possible: <strong>Endo</strong> and <strong>Exo</strong>.
      </p>
      <ul>
        <li><strong>Endo Approach:</strong> The substituent on the dienophile is oriented <em>toward</em> the &pi;-electron system of the diene in the transition state (forming a bicyclic adduct where the substituent is cis to the longer ethano bridge).</li>
        <li><strong>Exo Approach:</strong> The substituent on the dienophile is pointed <em>away</em> from the diene &pi;-system.</li>
      </ul>
      <p>
        Although the exo adduct is generally thermodynamically more stable due to reduced steric congestion in the ground state product, the <strong>Endo product is formed overwhelmingly under kinetic control (The Alder Endo Rule)</strong>.
      </p>

      <div class="callout">
        <h4>Physical Basis: Secondary Orbital Interactions (SOI)</h4>
        <p>
          In the endo transition state, the &pi;* orbital of the dienophile's activating carbonyl group is positioned directly over the lobes of the non-bonding C2 and C3 p-orbitals of the diene. While primary orbital overlap occurs at the reacting C1–C4 termini to form the new &sigma;-bonds, this <strong>secondary orbital interaction</strong> between C2/C3 and the carbonyl carbon produces an additional bonding overlap that lowers the free energy of the endo transition state by &Delta;&Delta;G<sup>&Dagger;</sup> &approx; 1.5–3.0 kcal/mol, favoring the endo pathway by &gt;95:5.
        </p>
      </div>

      <h2>5. Synchronous vs. Asynchronous Concerted Transition States</h2>
      <p>
        While the classical Diels-Alder reaction is concerted (occurring in a single kinetic step without discrete biradical or zwitterionic intermediates), it is rarely completely <strong>synchronous</strong>:
      </p>
      <p>
        In completely symmetrical reactions (e.g., 1,3-butadiene + ethylene), both new C–C &sigma;-bonds form at the exact same rate and distance (synchronous TS bond length ~2.15 &Aring;). However, when unsymmetrical substituents are introduced (e.g., 1-methoxybutadiene + acrolein), the atomic orbital coefficients at the reacting termini differ significantly (c<sub>1</sub> &ne; c<sub>4</sub>).
      </p>
      <p>
        Consequently, one &sigma;-bond forms substantially earlier than the other in the transition state. In this <strong>asynchronous concerted transition state</strong>, the more nucleophilic diene terminus attacks the more electrophilic dienophile terminus first (forming a partially advanced bond of ~1.95 &Aring; while the second bond lags at ~2.55 &Aring;). Modern density functional theory (DFT) and Climbing Image Nudged Elastic Band (CI-NEB) algorithms readily locate the exact index-1 saddle point possessing a single imaginary vibrational frequency corresponding to the disrotatory ring closure. Cross-reference our monograph on <a href="/guides/machine-learning-interatomic-potentials.html">Machine Learning Interatomic Potentials (MACE & PaiNN)</a>.
      </p>

      <div class="interactive-card">
        <h4>Simulate Diels-Alder Transition States in 3D</h4>
        <p>Explore HOMO-LUMO isosurfaces, secondary orbital interactions, and CI-NEB minimum energy paths in the live Quantum Forge 3D Workstation.</p>
        <a href="/">Launch 3D Workstation &rarr;</a>
      </div>
"""

refs7 = [
    "Woodward, R. B., & Hoffmann, R. (1969). The conservation of orbital symmetry. <em>Angew. Chem. Int. Ed.</em>, 8(11), 781–853. <a href=\"https://doi.org/10.1002/anie.196907811\" target=\"_blank\" rel=\"noopener\">doi:10.1002/anie.196907811</a>",
    "Houk, K. N. (1973). Frontier molecular orbital theory of cycloaddition reactions. <em>Acc. Chem. Res.</em>, 6(11), 361–369. <a href=\"https://doi.org/10.1021/ar50071a001\" target=\"_blank\" rel=\"noopener\">doi:10.1021/ar50071a001</a>",
    "Guan, X., et al. (2018). Quantum mechanical exploration of synchronous vs asynchronous Diels-Alder transition states. <em>J. Org. Chem.</em>, 83(15), 8412–8421. <a href=\"https://doi.org/10.1021/acs.joc.8b01142\" target=\"_blank\" rel=\"noopener\">doi:10.1021/acs.joc.8b01142</a>",
    "Blackman, M. L., et al. (2008). Tetrazine bioorthogonal click chemistry through inverse electron-demand Diels-Alder. <em>J. Am. Chem. Soc.</em>, 130(41), 13518–13519. <a href=\"https://doi.org/10.1021/ja805592x\" target=\"_blank\" rel=\"noopener\">doi:10.1021/ja805592x</a>"
]

html7 = create_guide_html(slug7, title7, meta_title7, meta_desc7, category7, read_time7, body7, amazon_link_chem, amazon_title_chem, amazon_desc_chem, refs7)
with open(os.path.join(out_dir, slug7), "w") as f:
    f.write(html7)
print(f"Generated {slug7}")

# ==============================================================================
# GUIDE 8: Clinical Acid-Base Physiology & Henderson-Hasselbalch
# ==============================================================================
slug8 = "acid-base-anion-gap-henderson-hasselbalch.html"
title8 = "Clinical Acid-Base Physiology: Henderson-Hasselbalch Kinetics, Winter's Formula & High Anion Gap Metabolic Acidosis"
meta_title8 = "Clinical Acid-Base Physiology & Anion Gap Kinetics"
meta_desc8 = "Definitive clinical physiology monograph on Henderson-Hasselbalch equilibrium, serum anion gap kinetics, the delta-delta ratio in mixed disorders, respiratory compensation formulas, and the GOLDMARK differential."
category8 = "Clinical Physiology & Critical Care Toxicology"
read_time8 = "16 min read"

body8 = """
      <h2>1. The Chemical Landscape of Extracellular pH Homeostasis</h2>
      <p>
        Strict regulation of systemic arterial blood hydrogen ion concentration ([H<sup>+</sup>] ~ 40 nmol/L, corresponding to <strong>pH 7.35 – 7.45</strong>) is a prerequisite for human life. Deviations beyond pH 6.80 or 7.70 induce catastrophic alterations in protein secondary and tertiary folding, denaturing metabolic enzymes, disrupting voltage-gated ion channels (Na<sub>v</sub>1.5, K<sub>v</sub>11.1), uncoupling oxidative phosphorylation, and halting cardiac contractility.
      </p>
      <p>
        Systemic pH homeostasis is maintained by three coordinated defense lines operating on distinct temporal scales:
      </p>
      <ol>
        <li><strong>Chemical Buffering (Instantaneous / Milliseconds):</strong> Extracellular bicarbonate (HCO<sub>3</sub><sup>-</sup> / CO<sub>2</sub>), intracellular phosphates, and hemoglobin buffer protons immediately upon entering circulation.</li>
        <li><strong>Respiratory Compensation (Minutes to Hours):</strong> Brainstem medullary chemoreceptors adjust minute ventilation (alveolar ventilation V<sub>A</sub>) to blow off or retain volatile acid in the form of carbon dioxide (CO<sub>2</sub>).</li>
        <li><strong>Renal Regulation (Hours to Days):</strong> Proximal tubule bicarbonate reclamation, distal collecting duct proton excretion via H<sup>+</sup>-ATPase pumps, and de novo generation of bicarbonate via ammonium (NH<sub>4</sub><sup>+</sup>) synthesis.</li>
      </ol>

      <h2>2. The Henderson-Hasselbalch Equation & Thermodynamic Equilibrium</h2>
      <p>
        The primary extracellular buffer system is the equilibrium between carbonic acid (H<sub>2</sub>CO<sub>3</sub>), dissolved carbon dioxide, and bicarbonate:
      </p>

      <div class="math-block">
        CO2 (dissolved) + H2O &hArr;[Carbonic Anhydrase]&hArr; H2CO3 &hArr; H+ + HCO3-<br><br>
        [The Henderson-Hasselbalch Equation]:<br>
        pH = pKa + log10 [ [HCO3-] / ( &alpha; &middot; PaCO2 ) ]<br><br>
        where:<br>
        - pKa = Negative logarithm of the apparent dissociation constant = 6.10 at 37&deg;C<br>
        - &alpha; = Carbon dioxide solubility coefficient in human plasma = 0.0307 mmol / L / mmHg<br>
        - PaCO2 = Partial pressure of arterial carbon dioxide (Normal: 40 mmHg)<br>
        - [HCO3-] = Serum bicarbonate concentration (Normal: 24 mEq/L)<br><br>
        Calculation: pH = 6.10 + log10 [ 24 / (0.0307 &middot; 40) ] = 6.10 + log10 [ 24 / 1.23 ] = 6.10 + 1.29 = 7.39
      </div>

      <p>
        Because dissolved CO<sub>2</sub> is an open system regulated dynamically by the lungs and HCO<sub>3</sub><sup>-</sup> is regulated by the kidneys, the body can maintain systemic pH at 7.40 despite operating more than 1.3 pH units above the chemical pK<sub>a</sub> (6.10) of the bicarbonate buffer system!
      </p>

      <h2>3. The Serum Anion Gap: Principles & Hypoalbuminemia Correction</h2>
      <p>
        In accordance with the physical principle of <strong>electroneutrality</strong>, total serum cation equivalents must exactly equal total serum anion equivalents:
      </p>

      <div class="math-block">
        [Na+] + [K+] + [Unmeasured Cations: Ca2+, Mg2+, &gamma;-globulins] = [Cl-] + [HCO3-] + [Unmeasured Anions: Albumin, PO4(3-), SO4(2-), Organic Acids]<br><br>
        [Clinical Serum Anion Gap (AG)]:<br>
        AG = [Na+] - ( [Cl-] + [HCO3-] )<br>
        Normal Range: 10 &plusmn; 2 mEq/L (Reference: 8 to 12 mEq/L on modern ion-selective electrodes)
      </div>

      <p>
        Under physiological conditions, serum albumin (a polyanionic protein with ~17 net negative charges per molecule at pH 7.40) constitutes approximately <strong>75–80% of the normal unmeasured anion gap</strong>. For every 1.0 g/dL drop in serum albumin below normal (4.0 g/dL), the baseline anion gap falls by approximately <strong>2.5 mEq/L</strong>!
      </p>

      <div class="math-block">
        Corrected Anion Gap (AG_corr) = Measured AG + 2.5 &middot; ( 4.0 - [Albumin, g/dL] )
      </div>

      <p>
        Failing to correct for hypoalbuminemia in critically ill intensive care patients (e.g., septic shock with albumin 1.5 g/dL) will mask lethal high anion gap lactic acidosis by erroneously reporting a "normal" measured anion gap of 11 mEq/L when the true corrected gap is 17.25 mEq/L!
      </p>

      <h2>4. High Anion Gap Metabolic Acidosis (HAGMA): The GOLDMARK Differential</h2>
      <p>
        When unmeasured organic acids accumulate in the bloodstream, protons (H<sup>+</sup>) are buffered by bicarbonate (HCO<sub>3</sub><sup>-</sup>), converting it to CO<sub>2</sub> and water. The unmeasured conjugate base of the acid (e.g., L-lactate, beta-hydroxybutyrate, formate, glycolate) takes the place of the consumed bicarbonate, widening the gap between sodium and the sum of chloride plus bicarbonate.
      </p>
      <p>
        Modern clinical toxicology categorizes HAGMA via the contemporary <strong>GOLDMARK</strong> framework:
      </p>

      <table>
        <thead>
          <tr>
            <th>GOLDMARK Mnemonic</th>
            <th>Etiological Acid & Conjugate Base</th>
            <th>Primary Mechanism & Toxic Pathophysiology</th>
            <th>Specific Diagnostic Biomarkers</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>G — Glycols</strong></td>
            <td>Ethylene glycol &rarr; Glycolic acid & Oxalic acid</td>
            <td>Antifreeze ingestion; ADH metabolizes to glycolate (HAGMA) and oxalate, precipitating calcium oxalate monohydrate crystals in renal tubules (AKI).</td>
            <td>High Osmolal Gap (&gt;10 mOsm/kg); envelope-shaped urine crystals; Wood's lamp fluorescein.</td>
          </tr>
          <tr>
            <td><strong>O — Oxoproline (5-Oxoproline)</strong></td>
            <td>Pyroglutamic acid</td>
            <td>Chronic acetaminophen ingestion in malnourished females; glutathione depletion uncouples the gamma-glutamyl cycle.</td>
            <td>Urine 5-oxoproline GC-MS; unprovoked HAGMA with normal lactate and ketones.</td>
          </tr>
          <tr>
            <td><strong>L — L-Lactate</strong></td>
            <td>L-Lactic acid</td>
            <td><strong>Type A:</strong> Tissue hypoperfusion and anaerobic glycolysis (Septic, cardiogenic, hemorrhagic shock).<br><strong>Type B:</strong> Mitochondrial toxin (Metformin, Cyanide, CO).</td>
            <td>Serum Lactate &gt; 2.0 mmol/L (Severe &gt; 4.0 mmol/L); central venous oxygen saturation (ScvO2 &lt; 70%).</td>
          </tr>
          <tr>
            <td><strong>D — D-Lactate</strong></td>
            <td>D-Lactic acid</td>
            <td>Short bowel syndrome; unabsorbed dietary carbohydrates undergo bacterial fermentation by <em>Lactobacillus</em> into D-isomer.</td>
            <td>Encephalopathy, ataxia; standard clinical laboratory assays measure only L-lactate (falsely normal!).</td>
          </tr>
          <tr>
            <td><strong>M — Methanol</strong></td>
            <td>Formic acid</td>
            <td>Windshield washer fluid; alcohol dehydrogenase (ADH) oxidizes methanol to formaldehyde, then to formic acid, which inhibits cytochrome c oxidase.</td>
            <td>High Osmolal Gap; optic disc edema, retinal snowfield blindness, basal ganglia putaminal necrosis.</td>
          </tr>
          <tr>
            <td><strong>A — Aspirin (Salicylate)</strong></td>
            <td>Salicylic acid</td>
            <td>Mixed disorder: Direct stimulation of medullary respiratory center causes <strong>Primary Respiratory Alkalosis</strong>; uncoupling of oxidative phosphorylation causes <strong>HAGMA</strong>.</td>
            <td>Serum Salicylate level &gt; 30–40 mg/dL; tinnitus, hyperventilation, hyperpyrexia. See our <a href="/guides/aspirin-cox-inhibition-mechanism.html">Aspirin Guide</a>.</td>
          </tr>
          <tr>
            <td><strong>R — Renal Failure (Uremia)</strong></td>
            <td>Sulfates, Phosphates, Urate</td>
            <td>End-stage renal disease (GFR &lt; 15–20 mL/min); inability to excrete dietary non-volatile fixed acids and ammonium.</td>
            <td>Elevated BUN, Serum Creatinine, Hyperkalemia. See our <a href="/guides/nephron-raas-gfr-filtration-dynamics.html">Nephron & GFR Guide</a>.</td>
          </tr>
          <tr>
            <td><strong>K — Ketoacidosis</strong></td>
            <td>&beta;-hydroxybutyrate & Acetoacetate</td>
            <td>Absolute insulin deficiency (DKA) or starvation/alcoholism; uninhibited lipolysis drives mitochondrial hepatic ketogenesis.</td>
            <td>Serum &beta;-hydroxybutyrate &gt; 3.0 mmol/L; hyperglycemia &gt; 250 mg/dL; urine acetoacetate test.</td>
          </tr>
        </tbody>
      </table>

      <h2>5. Quantitative Mixed Disorder Analysis: Winter's Formula & The Delta-Delta Ratio</h2>
      <p>
        In clinical medicine, patients rarely present with pure single acid-base disturbances. To uncover hidden underlying respiratory or metabolic disorders, clinicians apply strict quantitative mathematical formulas:
      </p>

      <h3>Step 1: Verify Respiratory Compensation via Winter's Formula</h3>
      <p>
        In pure metabolic acidosis, respiratory chemoreceptors stimulate hyperventilation (Kussmaul breathing) to reduce PaCO<sub>2</sub>. The expected physiological respiratory compensation is governed by <strong>Winter's Formula</strong>:
      </p>

      <div class="math-block">
        Expected PaCO2 = ( 1.5 &middot; [HCO3-] ) + 8 &plusmn; 2
      </div>

      <ul>
        <li>If Measured PaCO<sub>2</sub> = Expected PaCO<sub>2</sub>: Pure metabolic acidosis with appropriate respiratory compensation.</li>
        <li>If Measured PaCO<sub>2</sub> &gt; Expected PaCO<sub>2</sub>: Concomitant <strong>Primary Respiratory Acidosis</strong> (e.g., patient is fatiguing, severe COPD, or opioid hypoventilation).</li>
        <li>If Measured PaCO<sub>2</sub> &lt; Expected PaCO<sub>2</sub>: Concomitant <strong>Primary Respiratory Alkalosis</strong> (e.g., pain, sepsis, anxiety, early salicylate poisoning).</li>
      </ul>

      <h3>Step 2: Unmask Mixed Metabolic Disorders via the Delta-Delta (&Delta;/&Delta;) Ratio</h3>
      <p>
        In a pure High Anion Gap Metabolic Acidosis, for every 1 mEq/L of unmeasured acid added to circulation, exactly 1 mEq/L of bicarbonate is consumed. Thus, the rise in anion gap above baseline (&Delta;AG = AG - 12) should equal the fall in bicarbonate below normal (&Delta;HCO<sub>3</sub><sup>-</sup> = 24 - [HCO<sub>3</sub><sup>-</sup>]):
      </p>

      <div class="math-block">
        Delta-Delta Ratio (&Delta;/&Delta;) = ( AG_measured - 12 ) / ( 24 - [HCO3-] )
      </div>

      <table>
        <thead>
          <tr>
            <th>Delta-Delta Ratio (&Delta;/&Delta;)</th>
            <th>Clinical Interpretation</th>
            <th>Underlying Mixed Pathophysiology</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>1.0 – 2.0</strong></td>
            <td>Pure High Anion Gap Metabolic Acidosis</td>
            <td>Expected 1:1 stoichiometry of bicarbonate buffering unmeasured organic acids (e.g., uncomplicated DKA or lactic acidosis).</td>
          </tr>
          <tr>
            <td><strong>&lt; 0.8 – 1.0</strong></td>
            <td>Mixed HAGMA + <strong>Normal Anion Gap Metabolic Acidosis (NAGMA)</strong></td>
            <td>Bicarbonate has fallen far more than the anion gap has risen. Indicates concurrent gastrointestinal bicarbonate loss (severe diarrhea) or renal tubular acidosis (RTA).</td>
          </tr>
          <tr>
            <td><strong>&gt; 2.0</strong></td>
            <td>Mixed HAGMA + <strong>Metabolic Alkalosis</strong> (or pre-existing chronic respiratory acidosis)</td>
            <td>Bicarbonate is unexpectedly higher than predicted for the rise in anion gap! Common in vomiting (loss of HCl) or concomitant loop diuretic therapy in patients with DKA or sepsis.</td>
          </tr>
        </tbody>
      </table>

      <div class="interactive-card">
        <h4>Explore Henderson-Hasselbalch Kinetics in 3D</h4>
        <p>Simulate acid-base nomograms, Henderson-Hasselbalch equations, and electrolyte transports in the live Quantum Forge 3D Workstation.</p>
        <a href="/">Launch 3D Workstation &rarr;</a>
      </div>
"""

refs8 = [
    "Kraut, J. A., & Madias, N. E. (2010). Serum anion gap: its uses and limitations in clinical medicine. <em>Clin. J. Am. Soc. Nephrol.</em>, 5(11), 2092–2101. <a href=\"https://doi.org/10.2215/CJN.03020410\" target=\"_blank\" rel=\"noopener\">doi:10.2215/CJN.03020410</a>",
    "Berend, K., de Vries, A. P., & Gans, R. O. (2014). Physiological approach to assessment of acid-base disturbances. <em>N. Engl. J. Med.</em>, 371(15), 1434–1445. <a href=\"https://doi.org/10.1056/NEJMra1003327\" target=\"_blank\" rel=\"noopener\">doi:10.1056/NEJMra1003327</a>",
    "Mehta, A. N., et al. (2008). GOLD MARK: an alternative to MUDPILES for high anion gap metabolic acidosis. <em>Lancet</em>, 372(9642), 892. <a href=\"https://doi.org/10.1016/S0140-6736(08)61398-7\" target=\"_blank\" rel=\"noopener\">doi:10.1016/S0140-6736(08)61398-7</a>",
    "Kellum, J. A. (2000). Determinants of blood pH in health and disease. <em>Crit. Care</em>, 4(1), 6–14. <a href=\"https://doi.org/10.1186/cc644\" target=\"_blank\" rel=\"noopener\">doi:10.1186/cc644</a>"
]

html8 = create_guide_html(slug8, title8, meta_title8, meta_desc8, category8, read_time8, body8, amazon_link_phys, amazon_title_phys, amazon_desc_phys, refs8)
with open(os.path.join(out_dir, slug8), "w") as f:
    f.write(html8)
print(f"Generated {slug8}")

print("Batch 2 completed successfully!")
