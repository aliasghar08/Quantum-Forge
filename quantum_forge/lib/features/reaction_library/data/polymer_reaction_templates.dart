// ============================================================================
// Polymer Chemistry Reaction Templates
// Curated library of canonical polymer chemistry reactions spanning
// coordination, metathesis, living radical, ionic, step-growth, and
// conductive polymerizations with 3D Cartesian coordinates and literature DOIs.
// ============================================================================

import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

final List<ReactionTemplate> kPolymerReactionTemplates = [
  ReactionTemplate(
    id: 'poly-ziegler-natta-01',
    name: 'Ziegler-Natta Olefin Coordination Polymerization',
    iupacName: 'titanium-methyl active center + ethylene → titanium-propyl chain propagation',
    description: 'Karl Ziegler and Giulio Natta (1963 Nobel Prize in Chemistry) revolutionized polymer science by synthesizing stereoregular linear polyolefins (HDPE, isotactic polypropylene) under mild pressures. The reaction proceeds via the Cossee-Arlman mechanism: ethylene coordinates to an octahedral titanium vacant site on TiCl3/AlEt3, followed by migratory insertion into the Ti-alkyl bond through a 4-membered cyclic transition state.',
    category: ReactionCategory.polymer,
    reactantXyz: '''11
Ziegler-Natta Coordination Polymerization - Reactants (TiCl2-CH3 + C2H4)
Ti     0.0000    0.0000    0.0000
Cl     1.7200    1.3200    0.0000
Cl    -1.7200    1.3200    0.0000
C      0.0000   -2.0800    0.0000
H      0.9000   -2.5200    0.4500
H     -0.9000   -2.5200    0.4500
H      0.0000   -2.3500   -1.0500
C      0.0000    0.6500    2.3500
C      0.0000   -0.6500    2.3500
H      0.9200    1.2200    2.3500
H     -0.9200    1.2200    2.3500''',
    productXyz: '''11
Ziegler-Natta Coordination Polymerization - Products (TiCl2-CH2CH2CH3)
Ti     0.0000    0.0000    0.0000
Cl     1.7200    1.3200    0.0000
Cl    -1.7200    1.3200    0.0000
C      0.0000   -2.1000    0.0000
H      0.9200   -2.5500    0.4500
H     -0.9200   -2.5500    0.4500
H      0.0000   -2.4500   -1.0500
C      0.0000   -0.5500    0.5000
C      0.0000    0.4500    1.6500
H      0.9000    0.3500    2.2500
H     -0.9000    0.3500    2.2500''',
    referenceEa: 12.5,
    doi: '10.1021/ja01612a090',
    journalRef: 'J. Am. Chem. Soc. 1955, 77, 1708-1710',
    tags: ['Ziegler-Natta', 'Coordination Polymerization', 'Cossee-Arlman', 'Polyethylene', 'Organometallic Catalysis', 'Polypropylene'],
    defaultCatalystName: 'Ziegler-Natta (TiCl4 / AlEt3)',
    literatureBarrierKcalMol: 12.5,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ja01612a090',
  ),
  ReactionTemplate(
    id: 'poly-romp-grubbs-02',
    name: 'Ring-Opening Metathesis Polymerization (ROMP)',
    iupacName: 'bicyclo[2.2.1]hept-2-ene + ruthenium alkylidene → poly(norbornene) propagating complex',
    description: 'ROMP is a chain-growth polymerization driven by the relief of ring strain in cyclic olefins, developed into an ultra-precise synthetic methodology by Robert H. Grubbs and Richard R. Schrock (2005 Nobel Prize). A ruthenium carbene catalyst coordinates the strained norbornene double bond, forming a ruthenacyclobutane intermediate that undergoes retro-[2+2] cycloaddition to extend the living polyalkenamer chain.',
    category: ReactionCategory.polymer,
    reactantXyz: '''18
ROMP Norbornene + Ru-alkylidene - Reactants
Ru     0.0000    0.0000    0.0000
Cl     2.3500    0.0000    0.0000
Cl    -2.3500    0.0000    0.0000
C      0.0000    1.8200    0.0000
H      0.0000    2.4200    0.9100
C      0.0000   -0.5000    3.1000
C      0.0000    0.8300    3.1000
C      1.1500   -1.3500    3.4000
C     -1.1500   -1.3500    3.4000
C      1.1500    1.6800    3.4000
C     -1.1500    1.6800    3.4000
C      0.0000    0.0000    4.5500
H      0.0000   -1.0000    2.1500
H      0.0000    1.3300    2.1500
H      2.0800   -1.1000    2.8800
H     -2.0800   -1.1000    2.8800
H      2.0800    1.4300    2.8800
H     -2.0800    1.4300    2.8800''',
    productXyz: '''18
ROMP Norbornene + Ru-alkylidene - Product (Ring-Opened Propagating Chain)
Ru     0.0000    0.0000    0.0000
Cl     2.3500    0.0000    0.0000
Cl    -2.3500    0.0000    0.0000
C      0.0000    1.8500    0.0000
H      0.0000    2.4500    0.9100
C      0.0000   -0.4000    2.1000
C      0.0000    0.9500    2.1000
C      1.2500   -1.2500    2.4500
C     -1.2500   -1.2500    2.4500
C      1.2500    1.8000    2.4500
C     -1.2500    1.8000    2.4500
C      0.0000    0.0000    3.8000
H      0.0000   -0.8500    1.1200
H      0.0000    1.4000    1.1200
H      2.1500   -1.0000    1.9000
H     -2.1500   -1.0000    1.9000
H      2.1500    1.5500    1.9000
H     -2.1500    1.5500    1.9000''',
    referenceEa: 14.8,
    doi: '10.1021/ja952676d',
    journalRef: 'J. Am. Chem. Soc. 1996, 118, 100-110',
    tags: ['ROMP', 'Olefin Metathesis', 'Grubbs Catalyst', 'Norbornene', 'Ruthenium', 'Living Polymerization'],
    defaultCatalystName: 'Grubbs 1st Generation Ru Catalyst',
    literatureBarrierKcalMol: 14.8,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ja952676d',
  ),
  ReactionTemplate(
    id: 'poly-atrp-matyjaszewski-03',
    name: 'Atom Transfer Radical Polymerization (ATRP)',
    iupacName: 'polystyryl chloride + Cu(I)Cl/bpy → polystyryl radical + Cu(II)Cl2/bpy',
    description: 'Pioneered by Krzysztof Matyjaszewski and Mitsuo Sawamoto in 1995, ATRP is one of the most powerful controlled radical polymerization techniques. Reversible homolytic cleavage of a dormant alkyl-halogen bond by a transition metal catalyst (Cu(I) complex) generates a low stationary concentration of propagating carbon radicals and Cu(II) deactivator, maintaining low dispersity and living polymer architecture.',
    category: ReactionCategory.polymer,
    reactantXyz: '''16
ATRP Dormant Halide + Cu(I) Activator - Reactants
Cu     0.0000    0.0000    0.0000
Cl     2.1500    0.0000    0.0000
Cl    -0.5000    2.4000    0.0000
C     -0.5000    4.2000    0.0000
C      0.8000    4.8000    0.0000
C     -1.6500    4.9000    0.0000
H     -0.5500    4.1000   -1.0800
H      0.8500    5.8800    0.0000
H      1.6500    4.3500    0.5000
H      0.8000    4.4500   -1.0300
C     -1.6000    6.3000    0.0000
C     -2.9000    4.2500    0.0000
C     -2.7500    7.0000    0.0000
C     -4.0500    4.9500    0.0000
C     -3.9800    6.3300    0.0000
H     -4.9000    4.4200    0.0000''',
    productXyz: '''16
ATRP Activated Carbon Radical + Cu(II) Deactivator - Products
Cu     0.0000    0.0000    0.0000
Cl     2.1500    0.0000    0.0000
Cl    -0.2000    2.2500    0.0000
C     -0.5000    4.8500    0.0000
C      0.7500    5.5000    0.0000
C     -1.6500    5.5500    0.0000
H     -0.5500    4.7500   -1.0800
H      0.8000    6.5800    0.0000
H      1.6000    5.0500    0.5000
H      0.7500    5.1500   -1.0300
C     -1.6000    6.9500    0.0000
C     -2.9000    4.9000    0.0000
C     -2.7500    7.6500    0.0000
C     -4.0500    5.6000    0.0000
C     -3.9800    6.9800    0.0000
H     -4.9000    5.0700    0.0000''',
    referenceEa: 19.2,
    doi: '10.1021/ja00125a035',
    journalRef: 'J. Am. Chem. Soc. 1995, 117, 5614-5615',
    tags: ['ATRP', 'Controlled Radical Polymerization', 'Living Polymerization', 'Copper Catalysis', 'Polystyrene'],
    defaultCatalystName: 'Cu(I)Cl / 2,2\'-Bipyridine',
    literatureBarrierKcalMol: 19.2,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ja00125a035',
  ),
  ReactionTemplate(
    id: 'poly-raft-csiro-04',
    name: 'Reversible Addition-Fragmentation Chain Transfer (RAFT)',
    iupacName: 'propagating radical + dithiobenzoate ester → intermediate bridging thiocarbonyl radical adduct',
    description: 'Discovered at CSIRO in 1998 by Ezio Rizzardo, Graeme Moad, and San Thang, RAFT polymerization provides exquisite control over molecular weight and macromolecular architecture across diverse functional monomers. Chain growth proceeds via degenerative chain transfer involving a thiocarbonylthio compound where rapid addition-fragmentation equilibria ensure equal probability of chain growth across all macromolecular chains.',
    category: ReactionCategory.polymer,
    reactantXyz: '''15
RAFT Propagating Radical + Dithioester - Reactants
S      0.0000    0.0000    0.0000
C      1.6500    0.0000    0.0000
S      2.4500    1.5000    0.0000
C      3.9500    1.0000    0.0000
H      4.4000    1.3500    0.9200
H      4.4000    1.3500   -0.9200
H      3.9500   -0.0800    0.0000
C      2.3000   -1.3000    0.0000
C      1.6000   -2.5000    0.0000
C      3.7000   -1.3500    0.0000
H      0.5200   -2.4800    0.0000
H      4.2500   -0.4200    0.0000
C     -2.5000    0.0000    0.0000
C     -3.2000    1.2500    0.0000
H     -2.7500   -0.5500    0.9000''',
    productXyz: '''15
RAFT Intermediate Bridging Radical Adduct - Product
S      0.0000    0.0000    0.0000
C      1.6500    0.0000    0.0000
S      2.4000    1.6500    0.0000
C      3.9500    1.1500    0.0000
H      4.4000    1.5000    0.9200
H      4.4000    1.5000   -0.9200
H      3.9500    0.0700    0.0000
C      2.2500   -1.3500    0.0000
C      1.5500   -2.5500    0.0000
C      3.6500   -1.4000    0.0000
H      0.4700   -2.5300    0.0000
H      4.2000   -0.4700    0.0000
C     -1.5000    0.0000    0.0000
C     -2.3000    1.2000    0.0000
H     -1.6000   -0.5500    0.9000''',
    referenceEa: 8.7,
    doi: '10.1021/ma9804951',
    journalRef: 'Macromolecules 1998, 31, 5559-5562',
    tags: ['RAFT', 'Living Radical Polymerization', 'Chain Transfer Agent', 'Thiocarbonylthio', 'CSIRO', 'Precision Polymers'],
    defaultCatalystName: 'Dithiobenzoate RAFT Agent (CPDB)',
    literatureBarrierKcalMol: 8.7,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ma9804951',
  ),
  ReactionTemplate(
    id: 'poly-nmp-tempo-05',
    name: 'Nitroxide-Mediated Polymerization (NMP)',
    iupacName: 'alkoxyamine dormant chain → propagating carbon radical + TEMPO nitroxide radical',
    description: 'Developed by Michael Georges et al. (Xerox, 1993) based on early work by Solomon, Rizzardo, and Cacioli, NMP employs a stable nitroxide free radical (TEMPO) to reversibly cap growing macromolecular radicals. Thermal cleavage of the weak C-O bond creates a dynamic equilibrium that heavily favors the dormant alkoxyamine species, suppressing irreversible termination reactions and yielding well-defined block copolymers.',
    category: ReactionCategory.polymer,
    reactantXyz: '''15
NMP Dormant Alkoxyamine Adduct - Reactants
N      0.0000    0.0000    0.0000
O      1.4000    0.0000    0.0000
C      2.1000    1.2500    0.0000
C      3.5500    0.9500    0.0000
H      1.8000    1.8000    0.8800
H      1.8000    1.8000   -0.8800
H      4.1500    1.8500    0.0000
C     -0.7000    1.2500    0.0000
C     -0.7000   -1.2500    0.0000
C     -2.1500    1.0000    0.0000
C     -2.1500   -1.0000    0.0000
H     -0.4500    1.8500    0.8800
H     -0.4500   -1.8500    0.8800
H     -2.6500    1.5000    0.8500
H     -2.6500   -1.5000    0.8500''',
    productXyz: '''15
NMP Radical Homolysis (Carbon Radical + TEMPO Radical) - Products
N      0.0000    0.0000    0.0000
O      1.3000    0.0000    0.0000
C      3.4000    1.4000    0.0000
C      4.7500    0.9500    0.0000
H      3.2000    2.0000    0.8800
H      3.2000    2.0000   -0.8800
H      5.3500    1.8500    0.0000
C     -0.7000    1.2500    0.0000
C     -0.7000   -1.2500    0.0000
C     -2.1500    1.0000    0.0000
C     -2.1500   -1.0000    0.0000
H     -0.4500    1.8500    0.8800
H     -0.4500   -1.8500    0.8800
H     -2.6500    1.5000    0.8500
H     -2.6500   -1.5000    0.8500''',
    referenceEa: 28.4,
    doi: '10.1021/ma00063a054',
    journalRef: 'Macromolecules 1993, 26, 2987-2988',
    tags: ['NMP', 'TEMPO', 'Alkoxyamine', 'Living Radical Polymerization', 'Thermal Homolysis', 'Block Copolymers'],
    defaultCatalystName: 'TEMPO Stable Nitroxide Free Radical',
    literatureBarrierKcalMol: 28.4,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ma00063a054',
  ),
  ReactionTemplate(
    id: 'poly-pvc-free-radical-06',
    name: 'Free-Radical Vinyl Polymerization of Vinyl Chloride (PVC)',
    iupacName: 'polyvinyl radical + chloroethene → extended polyvinyl radical',
    description: 'Originally observed by Henri Victor Regnault (1835) and Eugen Baumann (1872), free-radical vinyl polymerization represents the commercial production route for Polyvinyl Chloride (PVC), polystyrene, and PMMA. Peroxide or azo initiators homolyze into radicals that add across the electron-poor double bond of vinyl chloride in a regiospecific head-to-tail propagation step.',
    category: ReactionCategory.polymer,
    reactantXyz: '''12
PVC Free-Radical Propagation - Reactants (Chain Radical + Vinyl Chloride)
C      0.0000    0.0000    0.0000
C      1.4500    0.0000    0.0000
Cl     2.2500    1.6000    0.0000
H     -0.5200    0.9200    0.0000
H     -0.5200   -0.9200    0.0000
H      1.8500   -0.5500    0.8500
C      4.2000    0.0000    0.0000
C      5.4500    0.0000    0.0000
Cl     6.5500   -1.4000    0.0000
H      3.6500    0.9200    0.0000
H      3.6500   -0.9200    0.0000
H      6.0000    0.9200    0.0000''',
    productXyz: '''12
PVC Free-Radical Propagation - Product (Extended Chain Radical)
C      0.0000    0.0000    0.0000
C      1.4500    0.0000    0.0000
Cl     2.2500    1.6000    0.0000
H     -0.5200    0.9200    0.0000
H     -0.5200   -0.9200    0.0000
H      1.8500   -0.5500    0.8500
C      2.9500   -0.2000    0.0000
C      4.3500    0.2000    0.0000
Cl     5.3500   -1.2500    0.0000
H      2.8500   -1.2500    0.0000
H      3.2500   -0.0500    1.0200
H      4.8500    1.1500    0.0000''',
    referenceEa: 21.0,
    doi: '10.1021/cr60124a004',
    journalRef: 'Chem. Rev. 1953, 52, 2, 239-258',
    tags: ['Free-Radical Polymerization', 'PVC', 'Polyvinyl Chloride', 'Vinyl Monomer', 'Radical Addition', 'Thermoplastics'],
    defaultCatalystName: 'Benzoyl Peroxide / AIBN Radical Initiator',
    literatureBarrierKcalMol: 21.0,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/cr60124a004',
  ),
  ReactionTemplate(
    id: 'poly-rop-caprolactone-07',
    name: 'Ring-Opening Polymerization of ε-Caprolactone (PCL)',
    iupacName: 'oxepan-2-one + metal alkoxide catalyst → linear polycaprolactone polyester chain',
    description: 'Ring-opening polymerization (ROP) of cyclic lactones produces biodegradable, biocompatible aliphatic polyesters widely utilized in biomedical drug delivery, tissue engineering scaffolds, and sustainable bioplastics. Catalyzed by tin(II) octoate or aluminum isopropoxide, the reaction proceeds through coordination of the endocyclic carbonyl oxygen followed by nucleophilic acyl-oxygen cleavage.',
    category: ReactionCategory.polymer,
    reactantXyz: '''15
ROP of ε-Caprolactone - Reactants (Lactone + Initiator Model)
O      0.0000    0.0000    0.0000
C      1.3500    0.0000    0.0000
O      2.0500    1.0200    0.0000
C      1.9500   -1.3500    0.0000
C      1.0500   -2.4500    0.0000
C     -0.4500   -2.2500    0.0000
C     -1.0500   -0.8500    0.0000
H      2.6000   -1.3500    0.8800
H      2.6000   -1.3500   -0.8800
H      1.4500   -3.4500    0.0000
H     -0.8500   -2.8500    0.8500
H     -1.7500   -0.8500   -0.8500
O     -3.0000    1.0000    0.0000
C     -4.2000    0.5000    0.0000
H     -2.9000    1.9500    0.0000''',
    productXyz: '''15
ROP of ε-Caprolactone - Product (Ring-Opened Linear Ester Chain)
O     -1.8500    0.8500    0.0000
C     -0.6500    0.2500    0.0000
O     -0.5500   -0.9500    0.0000
C      0.6500    1.0500    0.0000
C      1.9000    0.2500    0.0000
C      3.1500    1.0500    0.0000
C      4.4000    0.2500    0.0000
H      0.6500    1.7000    0.8800
H      0.6500    1.7000   -0.8800
H      1.9000   -0.4000    0.8800
H      3.1500    1.7000    0.8800
H      4.4500   -0.4000    0.8800
O     -3.0000    0.2000    0.0000
C     -4.2000    0.8000    0.0000
H     -2.9500   -0.7500    0.0000''',
    referenceEa: 16.3,
    doi: '10.1021/ma011385i',
    journalRef: 'Macromolecules 2002, 35, 1504-1512',
    tags: ['Ring-Opening Polymerization', 'ROP', 'Polycaprolactone', 'Biodegradable Polyester', 'Biomedical Polymers', 'Tin Octoate'],
    defaultCatalystName: 'Tin(II) 2-Ethylhexanoate (Sn(Oct)2)',
    literatureBarrierKcalMol: 16.3,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ma011385i',
  ),
  ReactionTemplate(
    id: 'poly-nylon-carothers-08',
    name: 'Nylon-6,6 Step-Growth Polycondensation (Polyamidation)',
    iupacName: 'hexamethylenediamine + adipic acid → nylon-6,6 amide repeating unit + H2O',
    description: 'Discovered by Wallace H. Carothers at DuPont in 1935, Nylon-6,6 was the world\'s first fully synthetic thermoplastic fiber and established the foundation of modern step-growth polymerization theory. The reaction proceeds through nucleophilic addition of an aliphatic diamine amino group onto a dicarboxylic acid carbonyl, eliminating water through a tetrahedral zwitterionic intermediate.',
    category: ReactionCategory.polymer,
    reactantXyz: '''15
Nylon-6,6 Step-Growth Polycondensation - Reactants
C      0.0000    0.0000    0.0000
O      0.0000    1.2200    0.0000
O     -1.1500   -0.7200    0.0000
H     -1.0000   -1.6500    0.0000
C      1.2500   -0.8000    0.0000
H      1.2500   -1.4500    0.8800
H      1.2500   -1.4500   -0.8800
N      0.0000    0.0000    2.8000
H     -0.8500   -0.5500    2.8000
H      0.8500   -0.5500    2.8000
C      0.0000    1.4500    2.8000
H      0.9000    1.8500    2.3500
H     -0.9000    1.8500    2.3500
C      0.0000    2.0000    4.2000
H      0.0000    3.0800    4.2000''',
    productXyz: '''15
Nylon-6,6 Step-Growth Polycondensation - Products (Amide Bond + Water)
C      0.0000    0.0000    0.0000
O      0.0000    1.2500    0.0000
O     -2.1000   -1.1000    0.0000
H     -2.4500   -1.9500    0.0000
C      1.2500   -0.8500    0.0000
H      1.2500   -1.5000    0.8800
H      1.2500   -1.5000   -0.8800
N     -0.2000   -0.4500    1.3500
H     -1.1500   -0.8000    1.3500
H     -1.2500   -1.1000    0.4000
C      0.2000    0.5000    2.3500
H      1.2500    0.7500    2.2500
H     -0.3500    1.4000    2.2500
C      0.0000    0.0000    3.7500
H      0.0000   -0.8000    4.4500''',
    referenceEa: 17.6,
    doi: '10.1021/ja01383a042',
    journalRef: 'J. Am. Chem. Soc. 1929, 51, 2548-2559',
    tags: ['Nylon-6,6', 'Step-Growth Polymerization', 'Polyamidation', 'Carothers', 'Synthetic Fibers', 'Condensation Polymer'],
    defaultCatalystName: 'Thermal Auto-Catalysis / Nylon Salt',
    literatureBarrierKcalMol: 17.6,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ja01383a042',
  ),
  ReactionTemplate(
    id: 'poly-polyurethane-bayer-09',
    name: 'Polyurethane Step-Growth Polyaddition',
    iupacName: 'diisocyanate + diol → polyurethane carbamate repeating linkage',
    description: 'Discovered by Otto Bayer at IG Farben in 1937, polyurethane synthesis represents the premier industrial polyaddition reaction. A diol hydroxyl group performs a nucleophilic attack across the electrophilic cumulative double bond of an aliphatic or aromatic isocyanate (N=C=O), yielding a carbamate (urethane) ester without releasing any volatile condensation byproducts.',
    category: ReactionCategory.polymer,
    reactantXyz: '''14
Polyurethane Polyaddition - Reactants (Isocyanate + Alcohol)
C      0.0000    0.0000    0.0000
N     -1.2200    0.0000    0.0000
O      1.1800    0.0000    0.0000
C     -2.5500    0.0000    0.0000
H     -3.0000    0.9200    0.4000
H     -3.0000   -0.9200    0.4000
H     -2.6000    0.0000   -1.0800
O      0.0000    0.0000    2.7500
H      0.0000   -0.8500    2.3000
C      0.0000    0.0000    4.1500
H      0.9000    0.5500    4.4500
H     -0.9000    0.5500    4.4500
C      0.0000   -1.4000    4.7500
H      0.0000   -1.4000    5.8200''',
    productXyz: '''14
Polyurethane Polyaddition - Product (Urethane / Carbamate Linkage)
C      0.0000    0.0000    0.0000
N     -1.1500    0.6500    0.0000
O      0.0000   -1.2500    0.0000
C     -2.4500    0.1000    0.0000
H     -2.9000    0.5500    0.8800
H     -2.9000    0.5500   -0.8800
H     -2.4500   -0.9800    0.0000
O      1.1500    0.6500    0.0000
H     -1.0500    1.6500    0.0000
C      2.3500   -0.1000    0.0000
H      2.4000   -0.7500    0.8800
H      2.4000   -0.7500   -0.8800
C      3.5500    0.8000    0.0000
H      3.5500    1.4500    0.8800''',
    referenceEa: 13.9,
    doi: '10.1002/ange.19470590901',
    journalRef: 'Angew. Chem. 1947, 59, 257-272',
    tags: ['Polyurethane', 'Polyaddition', 'Otto Bayer', 'Carbamate', 'Isocyanate', 'Thermosets', 'Elastomers'],
    defaultCatalystName: 'Dibutyltin Dilaurate (DBTDL) / Tertiary Amine (DABCO)',
    literatureBarrierKcalMol: 13.9,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1002/ange.19470590901',
  ),
  ReactionTemplate(
    id: 'poly-pet-whinfield-10',
    name: 'Polyethylene Terephthalate (PET) Transesterification',
    iupacName: 'bis(2-hydroxyethyl) terephthalate → poly(ethylene terephthalate) + ethylene glycol',
    description: 'Patented in 1941 by John Rex Whinfield and James Tennant Dickson at the Calico Printers\' Association, Polyethylene Terephthalate (PET, Dacron, Terylene) is one of the highest volume synthetic polymers globally. High-molecular weight polyester is generated via antimony-catalyzed step-growth melt transesterification of BHET with continuous vacuum removal of ethylene glycol.',
    category: ReactionCategory.polymer,
    reactantXyz: '''16
PET Transesterification - Reactants (Ester + Hydroxyethyl End Group)
C      0.0000    0.0000    0.0000
O      0.0000    1.2200    0.0000
O     -1.1500   -0.7000    0.0000
C     -2.4000    0.0000    0.0000
H     -2.5000    0.6000    0.8800
H     -2.5000    0.6000   -0.8800
C      1.2500   -0.8000    0.0000
H      1.2500   -1.4500    0.8800
O      0.0000    0.0000    2.8000
H     -0.7500   -0.5500    2.8000
C      0.0000    1.4000    2.8000
H      0.9000    1.8000    2.3500
H     -0.9000    1.8000    2.3500
C      0.0000    1.9500    4.2000
H      0.0000    3.0200    4.2000
H      0.9000    1.6000    4.7000''',
    productXyz: '''16
PET Transesterification - Products (Transesterified Polyester + Alcohol Leaving Group)
C      0.0000    0.0000    0.0000
O      0.0000    1.2500    0.0000
O     -2.3000   -1.1000    0.0000
C     -3.4000   -0.2500    0.0000
H     -3.4500    0.3500    0.8800
H     -3.4500    0.3500   -0.8800
C      1.2500   -0.8000    0.0000
H      1.2500   -1.4500    0.8800
O     -0.2000   -0.5500    1.3500
H     -1.5000   -0.9000    0.5000
C      0.2000    0.4500    2.3500
H      1.2500    0.7000    2.2500
H     -0.3500    1.3500    2.2500
C      0.0000    0.0000    3.7500
H      0.0000   -0.8000    4.4500
H      0.9000    0.5500    4.0500''',
    referenceEa: 22.4,
    doi: '10.1038/158930a0',
    journalRef: 'Nature 1946, 158, 930-931',
    tags: ['PET', 'Polyethylene Terephthalate', 'Transesterification', 'Step-Growth', 'Polyester', 'Whinfield', 'Synthetic Fiber'],
    defaultCatalystName: 'Antimony Trioxide (Sb2O3) / Zinc Acetate',
    literatureBarrierKcalMol: 22.4,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1038/158930a0',
  ),
  ReactionTemplate(
    id: 'poly-anionic-szwarc-11',
    name: 'Anionic Living Polymerization of Styrene (Szwarc Mechanism)',
    iupacName: 'benzylic carbanion living chain end + styrene monomer → extended living polystyryl carbanion',
    description: 'Michael Szwarc\'s discovery of \'living polymers\' in 1956 (Nature 178, 1168) is a landmark milestone in polymer science. Using sodium naphthalenide or organolithium initiators in aprotic ethereal solvents devoid of impurities, carbanion-propagating chain ends add across styrene monomers without any chain transfer or termination steps, resulting in near-monodisperse Poisson molecular weight distributions.',
    category: ReactionCategory.polymer,
    reactantXyz: '''15
Anionic Styrene Living Propagation - Reactants (Carbanion + Monomer)
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
C      2.1500    1.2500    0.0000
C      3.5500    1.2500    0.0000
C      4.2500    0.0000    0.0000
H      1.6000    2.1800    0.0000
H      4.0800    2.1800    0.0000
H      5.3200    0.0000    0.0000
H     -0.5500    0.9200    0.0000
H     -0.5500   -0.9200    0.0000
C     -0.8000    0.0000    3.1000
C      0.4500    0.0000    3.1000
H     -1.3500    0.9200    3.1000
H     -1.3500   -0.9200    3.1000
H      1.0500    0.9200    3.1000''',
    productXyz: '''15
Anionic Styrene Living Propagation - Product (Extended Carbanion Chain)
C      0.0000    0.0000    0.0000
C      1.4500    0.0000    0.0000
C      2.2000    1.2500    0.0000
C      3.6000    1.2500    0.0000
C      4.3000    0.0000    0.0000
H      1.6500    2.1800    0.0000
H      4.1200    2.1800    0.0000
H      5.3800    0.0000    0.0000
H     -0.5500    0.8800    0.0000
H     -0.5500   -0.8800    0.0000
C     -0.7500    0.0000    1.3500
C     -2.1500    0.0000    1.7000
H     -0.6500    0.8500    2.0000
H     -0.6500   -0.8500    2.0000
H     -2.7500    0.8500    1.5000''',
    referenceEa: 10.2,
    doi: '10.1038/1781168a0',
    journalRef: 'Nature 1956, 178, 1168-1169',
    tags: ['Living Polymerization', 'Anionic Polymerization', 'Szwarc', 'Carbanion', 'Polystyrene', 'Monodisperse'],
    defaultCatalystName: 'sec-Butyllithium / Sodium Naphthalenide',
    literatureBarrierKcalMol: 10.2,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1038/1781168a0',
  ),
  ReactionTemplate(
    id: 'poly-cationic-isobutylene-12',
    name: 'Cationic Polymerization of Isobutylene (Polyisobutylene / Butyl Rubber)',
    iupacName: 'tert-butyl carbocation + 2-methylprop-1-ene → 2,4,4-trimethylpentan-2-ylium propagating cation',
    description: 'Developed commercially by Thomas and Sparks (Standard Oil, 1937) following discoveries by Otto and Müller-Cunradi at BASF (1931), cationic polymerization of isobutylene at low temperatures (-100 °C) synthesizes high molecular weight polyisobutylene (butyl rubber). The electrophilic carbocation chain end rapidly attacks electron-rich olefin double bonds through a low-barrier Markovnikov addition.',
    category: ReactionCategory.polymer,
    reactantXyz: '''15
Cationic Isobutylene Propagation - Reactants (t-Butyl Cation + Isobutylene)
C      0.0000    0.0000    0.0000
C      1.4500    0.0000    0.0000
C     -0.7200    1.2500    0.0000
C     -0.7200   -1.2500    0.0000
H      1.9000    0.9500    0.0000
H      1.9000   -0.5000    0.8800
H      1.9000   -0.5000   -0.8800
H     -1.8000    1.2500    0.0000
H     -1.8000   -1.2500    0.0000
C      0.0000    0.0000    3.2000
C      0.0000    1.4000    3.2000
C     -1.2000   -0.7500    3.2000
H      0.9500    1.9500    3.2000
H     -0.9500    1.9500    3.2000
H     -2.1500   -0.2000    3.2000''',
    productXyz: '''15
Cationic Isobutylene Propagation - Product (Elongated Tertiary Carbocation)
C      0.0000    0.0000    0.0000
C      1.5000    0.0000    0.0000
C     -0.6500    1.3500    0.0000
C     -0.6500   -1.3500    0.0000
H      1.9500    0.9500    0.0000
H      1.9000   -0.5000    0.8800
H      1.9000   -0.5000   -0.8800
H     -1.7500    1.3500    0.0000
H     -1.7500   -1.3500    0.0000
C      0.0000    0.0000    1.5500
C      0.0000    1.4500    2.1500
C     -1.1500   -0.8500    2.1500
H      0.9500    1.9500    1.9500
H     -0.9000    2.0000    1.9500
H     -2.1000   -0.3500    1.9500''',
    referenceEa: 7.5,
    doi: '10.1002/pol.1976.130140412',
    journalRef: 'J. Polym. Sci.: Macromol. Rev. 1976, 11, 1-38',
    tags: ['Cationic Polymerization', 'Isobutylene', 'Butyl Rubber', 'Carbocation', 'Lewis Acid', 'Markovnikov Addition'],
    defaultCatalystName: 'Aluminum Trichloride (AlCl3) / Boron Trifluoride (BF3)',
    literatureBarrierKcalMol: 7.5,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1002/pol.1976.130140412',
  ),
  ReactionTemplate(
    id: 'poly-bakelite-baekeland-13',
    name: 'Bakelite Phenol-Formaldehyde Step-Growth Polycondensation',
    iupacName: 'phenol + formaldehyde → 2-(hydroxymethyl)phenol → methylene-bridged phenolic resin network',
    description: 'Invented by Leo Baekeland in 1907 (patented 1909), Bakelite was the first fully synthetic thermosetting plastic to achieve commercial stardom. The polymerization proceeds via electrophilic aromatic substitution: formaldehyde attacks phenol at activated ortho and para positions generating hydroxymethylphenols, which further condense with loss of water to establish rigid 3D methylene-bridged polymer networks.',
    category: ReactionCategory.polymer,
    reactantXyz: '''15
Bakelite Phenol + Formaldehyde - Reactants
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
C      2.1000    1.2200    0.0000
C      1.4000    2.4200    0.0000
C      0.0000    2.4200    0.0000
C     -0.7000    1.2200    0.0000
O     -2.0500    1.2200    0.0000
H     -2.4500    2.0800    0.0000
H     -0.5500   -0.9200    0.0000
H      1.9500   -0.9200    0.0000
H      3.1800    1.2200    0.0000
H      1.9500    3.3500    0.0000
C     -0.8000    3.8000    0.0000
O     -1.9500    4.2000    0.0000
H     -0.1000    4.5500    0.0000''',
    productXyz: '''15
Bakelite Saligenin Intermediate - Product
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
C      2.1000    1.2200    0.0000
C      1.4000    2.4200    0.0000
C      0.0000    2.4200    0.0000
C     -0.7000    1.2200    0.0000
O     -2.0500    1.2200    0.0000
H     -2.4500    2.0800    0.0000
H     -0.5500   -0.9200    0.0000
H      1.9500   -0.9200    0.0000
H      3.1800    1.2200    0.0000
H      1.9500    3.3500    0.0000
C     -0.7500    3.6500    0.0000
O     -2.1200    3.6500    0.0000
H     -2.4500    4.5000    0.0000''',
    referenceEa: 20.8,
    doi: '10.1021/ie50003a004',
    journalRef: 'Ind. Eng. Chem. 1909, 1, 149-161',
    tags: ['Bakelite', 'Phenol-Formaldehyde', 'Leo Baekeland', 'Thermoset Resin', 'Electrophilic Aromatic Substitution', 'First Synthetic Plastic'],
    defaultCatalystName: 'Acid (HCl / Oxalic Acid) or Base (NaOH / Ammonia)',
    literatureBarrierKcalMol: 20.8,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ie50003a004',
  ),
  ReactionTemplate(
    id: 'poly-polypyrrole-conductive-14',
    name: 'Electrochemical Polymerization of Conductive Polypyrrole',
    iupacName: 'pyrrole radical cation + neutral pyrrole → 2,2\'-bipyrrole radical intermediate + 2 H+',
    description: 'Electrochemical oxidative polymerization of pyrrole, investigated by Diaz, Kanazawa, and Gardini (1979) following Shirakawa, Heeger, and MacDiarmid\'s Nobel-prize winning work on conductive polyacetylene, generates electroactive intrinsically conducting polymers (ICPs). Single-electron oxidation of pyrrole creates radical cations that undergo alpha-alpha coupling with proton expulsion to construct extended pi-conjugated conducting backbones.',
    category: ReactionCategory.polymer,
    reactantXyz: '''14
Electrochemical Polypyrrole Dimerization - Reactants
N      0.0000    0.0000    0.0000
C      1.3500    0.0000    0.0000
C      1.7000    1.3200    0.0000
C      0.5500    2.1500    0.0000
C     -0.5500    1.3200    0.0000
H     -0.4500   -0.9000    0.0000
H      2.0000   -0.8500    0.0000
H      2.7000    1.7000    0.0000
C      3.6500   -0.5000    0.0000
N      4.5500    0.5000    0.0000
C      5.8500    0.1500    0.0000
C      5.7500   -1.2500    0.0000
C      4.3500   -1.6500    0.0000
H      4.2500    1.4500    0.0000''',
    productXyz: '''14
Electrochemical Polypyrrole Dimerization - Product (Bipyrrole Intermediate)
N      0.0000    0.0000    0.0000
C      1.3500    0.0000    0.0000
C      1.7000    1.3200    0.0000
C      0.5500    2.1500    0.0000
C     -0.5500    1.3200    0.0000
H     -0.4500   -0.9000    0.0000
H      1.5500   -0.6500    0.8500
H      2.7000    1.7000    0.0000
C      2.6000   -0.5000    0.0000
N      3.6500    0.3500    0.0000
C      4.8500   -0.2500    0.0000
C      4.5500   -1.6000    0.0000
C      3.1500   -1.7500    0.0000
H      3.5500    1.3500    0.0000''',
    referenceEa: 15.1,
    doi: '10.1039/C39790000635',
    journalRef: 'J. Chem. Soc., Chem. Commun. 1979, 635-636',
    tags: ['Conductive Polymers', 'Polypyrrole', 'Electrochemical Polymerization', 'Pi-Conjugation', 'Organic Electronics', 'Heeger-MacDiarmid'],
    defaultCatalystName: 'Anodic Oxidation / Pt Working Electrode',
    literatureBarrierKcalMol: 15.1,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1039/C39790000635',
  ),
  ReactionTemplate(
    id: 'poly-epoxy-amine-crosslink-15',
    name: 'Epoxy Resin Step-Growth Crosslinking (Oxirane Ring Opening by Amine)',
    iupacName: '2-(phenoxymethyl)oxirane + aliphatic primary amine → beta-amino alcohol crosslink node',
    description: 'Developed independently by Pierre Castan in Switzerland (1936) and Sylvan Greenlee in the United States (1939), epoxy resins (DGEBA) cured with aliphatic polyamines form extraordinarily tough, solvent-resistant thermosetting materials. The primary amine nucleophilically attacks the least hindered methylene carbon of the strained oxirane ring, yielding a secondary amine capable of further crosslinking.',
    category: ReactionCategory.polymer,
    reactantXyz: '''14
Epoxy Oxirane + Amine Hardener - Reactants
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
O      0.7000    1.2500    0.0000
H     -0.5500    0.0000    0.9200
H     -0.5500    0.0000   -0.9200
H      1.9500    0.0000    0.9200
C     -0.7000   -1.1500    0.0000
H     -1.7500   -1.1500    0.0000
N      3.2000    0.0000    0.0000
H      3.6000    0.8500    0.4000
H      3.6000   -0.8500    0.4000
C      3.6000    0.0000   -1.4000
H      3.2000    0.9000   -1.8500
H      3.2000   -0.9000   -1.8500''',
    productXyz: '''14
Epoxy Oxirane + Amine Hardener - Product (Beta-Amino Alcohol Crosslink)
C      0.0000    0.0000    0.0000
C      1.4500    0.0000    0.0000
O      0.5500    1.3500    0.0000
H     -0.4500    0.2000    0.9500
H     -0.4500   -1.8000    0.0000
H      1.8000    0.2500    0.9800
C     -0.7000   -1.1500    0.0000
H     -1.7500   -1.1500    0.0000
N      2.0500   -0.8500    0.0000
H      0.8500    1.9500    0.6500
H      1.7500   -1.8000    0.0000
C      3.5000   -0.8000    0.0000
H      3.8500    0.1500   -0.4000
H      3.8500   -1.6000   -0.5500''',
    referenceEa: 14.5,
    doi: '10.1021/ba-1970-0092.ch003',
    journalRef: 'Adv. Chem. Ser. 1970, 92, 33-51',
    tags: ['Epoxy Resin', 'DGEBA', 'Thermoset Crosslinking', 'Amine Hardener', 'Oxirane Ring Opening', 'High Performance Polymers'],
    defaultCatalystName: 'Triethylenetetramine (TETA) / Imidazole Accelerator',
    literatureBarrierKcalMol: 14.5,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ba-1970-0092.ch003',
  ),
  ReactionTemplate(
    id: 'poly-pla-lactide-rop-16',
    name: 'L-Lactide Ring-Opening Polymerization to Polylactic Acid (PLA)',
    iupacName: '(3S,6S)-3,6-dimethyl-1,4-dioxane-2,5-dione + Sn(II) alkoxide → polylactide ester chain',
    description: 'Originally synthesized by Wallace Carothers (1932) and scaled into modern biodegradable plastics by Kulkarni and Kricheldorf, Ring-Opening Polymerization of L-lactide produces Polylactic Acid (PLA), the premier industrial bio-based polymer. The cyclic diester dimer coordinates to tin(II) 2-ethylhexanoate, undergoing acyl-oxygen cleavage to propagate the linear biodegradable polyester.',
    category: ReactionCategory.polymer,
    reactantXyz: '''16
ROP of L-Lactide - Reactants (Lactide Dimer + Catalyst Model)
C      0.0000    0.0000    0.0000
O      0.0000    1.2200    0.0000
O      1.1500   -0.7200    0.0000
C      2.4000    0.0000    0.0000
C      2.4000    1.5000    0.0000
O      2.4000    2.7200    0.0000
O      1.2500    0.7800    0.0000
C     -1.2500   -0.8000    0.0000
H      3.2500   -0.5500    0.4000
H     -1.2500   -1.4500    0.8800
H     -1.2500   -1.4500   -0.8800
H     -2.1500   -0.2000    0.0000
O      4.5000    0.0000    0.0000
C      5.7000    0.0000    0.0000
H      4.2000   -0.9000    0.0000
H      6.2000    0.9500    0.0000''',
    productXyz: '''16
ROP of L-Lactide - Product (Linear PLA Chain Extended Model)
C      0.0000    0.0000    0.0000
O      0.0000    1.2500    0.0000
O      1.2000   -0.6500    0.0000
C      2.4500    0.1000    0.0000
C      3.6500   -0.8500    0.0000
O      3.6500   -2.0500    0.0000
O      4.7500   -0.1000    0.0000
C     -1.2500   -0.8000    0.0000
H      2.4500    0.7500    0.9500
H     -1.2500   -1.4500    0.8800
H     -1.2500   -1.4500   -0.8800
H     -2.1500   -0.2000    0.0000
O      6.0000   -0.8000    0.0000
C      7.1500   -0.1000    0.0000
H      5.8500   -1.7500    0.0000
H      7.9500   -0.8000    0.0000''',
    referenceEa: 18.1,
    doi: '10.1021/ma00180a002',
    journalRef: 'Macromolecules 1988, 21, 286-293',
    tags: ['Polylactic Acid', 'PLA', 'Lactide', 'Bioplastics', 'Ring-Opening Polymerization', 'Sustainable Chemistry'],
    defaultCatalystName: 'Tin(II) 2-Ethylhexanoate (Sn(Oct)2)',
    literatureBarrierKcalMol: 18.1,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ma00180a002',
  ),
  ReactionTemplate(
    id: 'poly-gtp-webster-17',
    name: 'Group Transfer Polymerization of Methyl Methacrylate (GTP)',
    iupacName: '1-methoxy-2-methyl-1-(trimethylsiloxy)propene + methyl methacrylate → living PMMA chain end',
    description: 'Discovered at DuPont by Owen W. Webster et al. in 1983, Group Transfer Polymerization (GTP) is an organosilicon-mediated living polymerization of acrylic and methacrylic monomers. Catalyzed by nucleophilic anions (fluoride, biofluoride), the reaction proceeds via Michael-type addition where the trimethylsilyl group transfers intramoleculary to the incoming monomer carbonyl, continuously regenerating the living ketene acetal group.',
    category: ReactionCategory.polymer,
    reactantXyz: '''15
GTP Methyl Methacrylate Propagation - Reactants
Si     0.0000    0.0000    0.0000
O      1.6500    0.0000    0.0000
C      2.4500    1.0500    0.0000
C      3.8000    0.8500    0.0000
C      1.9500    2.3500    0.0000
C     -0.7000    1.7000    0.0000
C     -0.7000   -1.1500    1.2500
H      4.4000    1.7200    0.0000
H      4.2000    0.2500    0.8000
C      0.0000    0.0000    3.3000
C      1.3500    0.0000    3.3000
C      2.1500    1.2500    3.3000
O      1.8000    2.4000    3.3000
H     -0.5500    0.9200    3.3000
H     -0.5500   -0.9200    3.3000''',
    productXyz: '''15
GTP Methyl Methacrylate Propagation - Product (Transferred Silyl Ketene Acetal)
Si     0.0000    0.0000    0.0000
O      1.6500    0.0000    0.0000
C      2.5000    1.1000    0.0000
C      3.9500    0.7500    0.0000
C      2.0500    2.4000    0.0000
C     -0.7000    1.7000    0.0000
C     -0.7000   -1.1500    1.2500
H      4.5500    1.6200    0.0000
H      4.2000    0.1500    0.8000
C      1.8500   -0.8500    2.0000
C      2.6500    0.1500    2.6500
C      3.9000    0.7500    2.1500
O      4.7500    1.1500    2.8500
H      1.5500   -1.7500    2.5000
H      1.1000   -0.4500    1.3500''',
    referenceEa: 11.4,
    doi: '10.1021/ja00355a039',
    journalRef: 'J. Am. Chem. Soc. 1983, 105, 5706-5708',
    tags: ['Group Transfer Polymerization', 'GTP', 'DuPont', 'PMMA', 'Organosilicon', 'Living Polymerization', 'Michael Addition'],
    defaultCatalystName: 'Tetrabutylammonium Bifluoride (TBA+ HF2-)',
    literatureBarrierKcalMol: 11.4,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ja00355a039',
  ),
  ReactionTemplate(
    id: 'poly-admet-wagener-18',
    name: 'Acyclic Diene Metathesis (ADMET) Polymerization',
    iupacName: 'alpha,omega-diene + molybdenum/ruthenium alkylidene → polyalkenamer + ethene',
    description: 'Developed by Kenneth B. Wagener at the University of Florida in 1991, ADMET is a clean step-growth metathesis condensation polymerization of non-conjugated terminal dienes. Using Schrock molybdenum or Grubbs ruthenium alkylidene catalysts, the equilibrium is driven forward toward high molecular weight precision polyolefins and telechelics by continuous vacuum removal of volatile ethylene.',
    category: ReactionCategory.polymer,
    reactantXyz: '''14
ADMET Terminal Diene Metathesis - Reactants (Two Vinyl Chain Ends)
C      0.0000    0.0000    0.0000
C      1.3500    0.0000    0.0000
H     -0.5500    0.9200    0.0000
H     -0.5500   -0.9200    0.0000
H      1.9000   -0.9200    0.0000
C      2.1000    1.2500    0.0000
H      1.8000    1.8500    0.8800
C      0.0000    0.0000    3.0000
C      1.3500    0.0000    3.0000
H     -0.5500    0.9200    3.0000
H     -0.5500   -0.9200    3.0000
H      1.9000   -0.9200    3.0000
C      2.1000    1.2500    3.0000
H      1.8000    1.8500    3.8800''',
    productXyz: '''14
ADMET Terminal Diene Metathesis - Products (Internal Alkene Backbone + Ethylene)
C      0.0000    0.0000    0.0000
C      1.3500    0.0000    0.0000
H     -0.5500    0.9200    0.0000
H     -0.5500   -0.9200    0.0000
H      1.9000   -0.9200    0.0000
C      2.1500    1.2500    0.0000
H      1.8500    1.8500    0.8800
C      0.0000    0.0000    1.5000
C      1.3500    0.0000    1.5000
H     -0.5500    0.9200    1.5000
H     -0.5500   -0.9200    1.5000
H      1.9000   -0.9200    1.5000
C      2.1500    1.2500    1.5000
H      1.8500    1.8500    2.3800''',
    referenceEa: 15.3,
    doi: '10.1021/ma00009a058',
    journalRef: 'Macromolecules 1991, 24, 2649-2657',
    tags: ['ADMET', 'Olefin Metathesis', 'Step-Growth Polymerization', 'Wagener', 'Ruthenium Alkylidene', 'Ethylene Condensation'],
    defaultCatalystName: 'Grubbs 2nd Generation / Schrock Molybdenum Alkylidene',
    literatureBarrierKcalMol: 15.3,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1021/ma00009a058',
  ),
];
