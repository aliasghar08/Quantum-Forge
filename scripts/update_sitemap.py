sitemap_path = "quantum_forge/web/sitemap.xml"

guides = [
    # Category 1: Pharmacology & Toxicology
    "warfarin-cyp2c9-vkorc1-dosing.html",
    "beta-lactam-resistance-tem52-mrsa.html",
    "statin-hmg-coa-reductase-kinetics.html",
    "aspirin-cox-inhibition-mechanism.html",
    "cyp450-pharmacogenomics-adme.html",
    "acetaminophen-napqi-hepatotoxicity.html",
    "herg-channel-qt-prolongation.html",
    # Category 2: Organ Hemodynamics & Physiology
    "circle-of-willis-cerebral-hemodynamics.html",
    "nephron-raas-gfr-filtration-dynamics.html",
    "ards-mechanical-ventilation-lung-mechanics.html",
    "acid-base-anion-gap-henderson-hasselbalch.html",
    "coronary-bifurcation-ffr-hemodynamics.html",
    # Category 3: Computational Chemistry & Kinetics
    "diels-alder-pericyclic-frontier-orbitals.html",
    "sn1-vs-sn2-reaction-kinetics.html",
    "transition-state-theory-activation-energy.html",
    "machine-learning-interatomic-potentials.html"
]

xml = ['<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']

# Root & Guides Hub
xml.append("""  <url>
    <loc>https://quantumforgeapp.com/</loc>
    <lastmod>2026-11-23</lastmod>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://quantumforgeapp.com/guides/</loc>
    <lastmod>2026-11-23</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.9</priority>
  </url>""")

# 16 Guides
for g in guides:
    xml.append(f"""  <url>
    <loc>https://quantumforgeapp.com/guides/{g}</loc>
    <lastmod>2026-11-23</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.9</priority>
  </url>""")

# Static Trust Pages
xml.append("""  <url>
    <loc>https://quantumforgeapp.com/about.html</loc>
    <lastmod>2026-11-23</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://quantumforgeapp.com/contact.html</loc>
    <lastmod>2026-11-23</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://quantumforgeapp.com/privacy.html</loc>
    <lastmod>2026-11-23</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.5</priority>
  </url>
  <url>
    <loc>https://quantumforgeapp.com/terms.html</loc>
    <lastmod>2026-11-23</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.5</priority>
  </url>
</urlset>
""")

with open(sitemap_path, "w") as f:
    f.write("\n".join(xml))

print(f"Updated {sitemap_path} with {len(guides)} guides and lastmod 2026-11-23!")
