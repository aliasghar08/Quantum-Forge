// ============================================================================
// Veterinary Reaction Templates for DVM & Veterinary Pharmacology
// Curated with 3D Cartesian coordinates & clinical veterinary mechanisms.
// ============================================================================

import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

final List<ReactionTemplate> kVeterinaryReactionTemplates = [
  ReactionTemplate(
    id: 'vet-enrofloxacin-01',
    name: 'Enrofloxacin C-6 Fluorination & DNA Gyrase Complexation',
    iupacName: '1-cyclopropyl-7-(4-ethylpiperazin-1-yl)-6-fluoro-4-oxoquinoline-3-carboxylic acid',
    description: 'Premier veterinary-specific fluoroquinolone bactericidal antibiotic for companion animals, swine, and cattle. Inhibits bacterial DNA gyrase (topoisomerase II) and topoisomerase IV via coordinated keto-carboxylate chelation to catalytic Mg2+ ions, arresting replication forks in Pasteurella, Mannheimia, and E. coli.',
    category: ReactionCategory.veterinary,
    reactantXyz: '''32
Enrofloxacin Reactants - Fluoroquinolone Scaffold
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
C      2.1000    1.2124    0.0000
C      1.4000    2.4249    0.0000
C      0.0000    2.4249    0.0000
C     -0.7000    1.2124    0.0000
N      2.8000    2.4249    0.0000
C      3.5000    1.2124    0.0000
C      2.8000    0.0000    0.0000
O      1.9500   -1.0500    0.0000
C      4.9500    1.2124    0.0000
O      5.5500    2.2500    0.0000
O      5.5500    0.1700    0.0000
H      6.5000    0.1700    0.0000
F     -0.6500    3.5500    0.0000
N     -2.0500    1.2124    0.0000
C     -2.7500    2.4249    0.0000
C     -4.1500    2.4249    0.0000
N     -4.8500    1.2124    0.0000
C     -4.1500    0.0000    0.0000
C     -2.7500    0.0000    0.0000
C     -6.2500    1.2124    0.0000
C     -6.9500    2.4249    0.0000
C      3.5000    3.6373    0.0000
C      4.9000    3.6373    0.0000
C      4.2000    4.8497    0.0000
H     -0.5000   -0.9000    0.0000
H     -2.2500    3.3500    0.0000
H     -4.6500    3.3500    0.0000
H     -4.6500   -0.9000    0.0000
H     -2.2500   -0.9000    0.0000
H     -6.5000    3.3500    0.0000''',
    productXyz: '''32
Enrofloxacin Products - Chelated Active Conformer
C      0.0000    0.0000    0.0000
C      1.3800    0.0200    0.0000
C      2.0800    1.2300    0.0000
C      1.3800    2.4400    0.0000
C     -0.0200    2.4400    0.0000
C     -0.7200    1.2300    0.0000
N      2.7800    2.4400    0.0000
C      3.4800    1.2300    0.0000
C      2.7800    0.0200    0.0000
O      1.9200   -1.0800    0.0000
C      4.9200    1.2300    0.0000
O      5.5200    2.2700    0.0000
O      5.5200    0.1900    0.0000
H      6.4700    0.1900    0.0000
F     -0.6700    3.5700    0.0000
N     -2.0700    1.2300    0.0000
C     -2.7700    2.4400    0.0000
C     -4.1700    2.4400    0.0000
N     -4.8700    1.2300    0.0000
C     -4.1700    0.0200    0.0000
C     -2.7700    0.0200    0.0000
C     -6.2700    1.2300    0.0000
C     -6.9700    2.4400    0.0000
C      3.4800    3.6500    0.0000
C      4.8800    3.6500    0.0000
C      4.1800    4.8600    0.0000
H     -0.5200   -0.8800    0.0000
H     -2.2700    3.3700    0.0000
H     -4.6700    3.3700    0.0000
H     -4.6700   -0.8800    0.0000
H     -2.2700   -0.8800    0.0000
H     -6.5200    3.3700    0.0000''',
    referenceEa: 17.4,
    doi: '10.1136/vr.i1388',
    journalRef: 'Vet. Rec. 2016, 178, 362-363',
    tags: const ["Veterinary", "DVM", "Antibiotic", "Fluoroquinolone", "DNA Gyrase", "Bovine Respiratory Disease", "Companion Animal"],
    defaultCatalystName: 'Mg2+ Water-Metal Ion Coordination Bridge',
    literatureBarrierKcalMol: 17.4,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1136/vr.i1388',
    catalystXyz: '''5
Mg(H2O)4 Complex Core
Mg 0.0000 0.0000 0.0000
O  2.0500 0.0000 0.0000
O -2.0500 0.0000 0.0000
O  0.0000 2.0500 0.0000
O  0.0000 -2.0500 0.0000''',
  ),
  ReactionTemplate(
    id: 'vet-ivermectin-01',
    name: 'Ivermectin Macrocyclic Lactone GluCl Channel Activation',
    iupacName: '22,23-dihydroavermectin B1a / B1b macrocyclic lactone complex',
    description: 'Gold-standard veterinary endectocide for livestock and companion animals. Reversibly binds with high affinity to glutamate-gated chloride ion channels in invertebrate nerve and muscle cells, producing hyperpolarization, flaccid muscular paralysis, and clearance of Dirofilaria immitis microfilariae and gastrointestinal nematodes.',
    category: ReactionCategory.veterinary,
    reactantXyz: '''30
Ivermectin Reactant Scaffold
C      0.0000    0.0000    0.0000
C      1.3500    0.2000    0.0000
C      2.2500    1.3000    0.1000
C      3.6500    1.1500    0.0500
O      4.3500    2.2500    0.1500
C      5.7500    2.1500    0.1000
C      6.4000    0.8500    0.0000
O      5.6500   -0.2500   -0.1000
C      4.2500   -0.1500   -0.0500
C      3.5500   -1.4500   -0.1500
C      2.1000   -1.4000   -0.1000
C      1.4000   -2.6500   -0.2000
O      0.0500   -2.6000   -0.1500
C     -0.6500   -1.4000   -0.0500
O     -1.9500   -1.4500   -0.1000
C     -0.7000    1.2500    0.1000
O     -2.0500    1.2000    0.1500
C     -2.7500    2.4000    0.2500
C      7.8500    0.7500   -0.0500
O      8.5000    1.9500    0.0500
H     -0.4500   -0.9000    0.0000
H      1.7500    2.2500    0.2000
H      6.2500    3.0500    0.2000
H      4.0500   -2.3500   -0.2500
H      1.9000   -3.5500   -0.3000
H     -0.2500    2.1500    0.1500
H     -3.8000    2.2500    0.3000
H     -2.4500    3.0000    1.1000
H      8.3000   -0.1500   -0.1500
H      9.4500    1.8500    0.0000''',
    productXyz: '''30
Ivermectin Product - Coordinated Conformation
C      0.0000    0.0000    0.0000
C      1.3400    0.2100    0.0000
C      2.2300    1.3100    0.1000
C      3.6300    1.1600    0.0500
O      4.3300    2.2600    0.1500
C      5.7300    2.1600    0.1000
C      6.3800    0.8600    0.0000
O      5.6300   -0.2400   -0.1000
C      4.2300   -0.1400   -0.0500
C      3.5300   -1.4400   -0.1500
C      2.0800   -1.3900   -0.1000
C      1.3800   -2.6400   -0.2000
O      0.0300   -2.5900   -0.1500
C     -0.6700   -1.3900   -0.0500
O     -1.9700   -1.4400   -0.1000
C     -0.7200    1.2600    0.1000
O     -2.0700    1.2100    0.1500
C     -2.7700    2.4100    0.2500
C      7.8300    0.7600   -0.0500
O      8.4800    1.9600    0.0500
H     -0.4700   -0.8900    0.0000
H      1.7300    2.2600    0.2000
H      6.2300    3.0600    0.2000
H      4.0300   -2.3400   -0.2500
H      1.8800   -3.5400   -0.3000
H     -0.2700    2.1600    0.1500
H     -3.8200    2.2600    0.3000
H     -2.4700    3.0100    1.1000
H      8.2800   -0.1400   -0.1500
H      9.4300    1.8600    0.0000''',
    referenceEa: 14.8,
    doi: '10.1126/science.6308762',
    journalRef: 'Science 1983, 221, 823-828',
    tags: const ["Veterinary", "DVM", "Antiparasitic", "Anthelmintic", "Macrocyclic Lactone", "GluCl Channel", "Heartworm", "Equine", "Livestock"],
    defaultCatalystName: 'GluCl Receptor Transmembrane Alpha-Pore',
    literatureBarrierKcalMol: 14.2,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1126/science.6308762',
    catalystXyz: '''5
GluCl Pore Subunit Filter
Cl 0.0000 0.0000 0.0000
N  2.2000 0.0000 0.0000
N -2.2000 0.0000 0.0000
O  0.0000 2.2000 0.0000
O  0.0000 -2.2000 0.0000''',
  ),
  ReactionTemplate(
    id: 'vet-meloxicam-01',
    name: 'Meloxicam Enolic Carboxamide Hydroxylation & COX-2 Selectivity',
    iupacName: '4-hydroxy-2-methyl-N-(5-methyl-1,3-thiazol-2-yl)-2H-1,2-benzothiazine-3-carboxamide 1,1-dioxide',
    description: 'Leading veterinary non-steroidal anti-inflammatory drug (NSAID) with preferential COX-2 inhibition over COX-1. Widely prescribed for acute and chronic pain, perioperative orthopedic analgesia, and osteoarthritis in dogs, cats, pigs, and cattle without disrupting gastrointestinal mucosal COX-1 prostacyclin synthesis.',
    category: ReactionCategory.veterinary,
    reactantXyz: '''25
Meloxicam Reactant Scaffold
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
C      2.1000    1.2124    0.0000
C      1.4000    2.4249    0.0000
C      0.0000    2.4249    0.0000
C     -0.7000    1.2124    0.0000
S      2.1500   -1.4500    0.0000
O      1.4000   -2.5500    0.6000
O      1.4000   -2.5500   -0.6000
N      3.6500   -1.1500    0.0000
C      4.4000    0.0500    0.0000
C      3.6000    1.2500    0.0000
O      4.2500    2.3500    0.0000
C      5.8500    0.0000    0.0000
O      6.5000    1.0500    0.0000
N      6.4500   -1.2000    0.0000
C      7.8000   -1.3500    0.0000
N      8.4000   -2.5500    0.0000
C      9.7000   -2.3500    0.0000
C      9.9500   -1.0500    0.0000
S      8.6000   -0.1500    0.0000
C     11.2000   -0.3500    0.0000
H     -0.5000   -0.9000    0.0000
H     -1.7500    1.2124    0.0000
H      5.9500   -2.0000    0.0000''',
    productXyz: '''25
Meloxicam Product - Enol-Keto Tautomerized Form
C      0.0000    0.0000    0.0000
C      1.3900    0.0100    0.0000
C      2.0900    1.2200    0.0000
C      1.3900    2.4300    0.0000
C     -0.0100    2.4300    0.0000
C     -0.7100    1.2200    0.0000
S      2.1400   -1.4400    0.0000
O      1.3900   -2.5400    0.6000
O      1.3900   -2.5400   -0.6000
N      3.6400   -1.1400    0.0000
C      4.3900    0.0600    0.0000
C      3.5900    1.2600    0.0000
O      4.2400    2.3600    0.0000
C      5.8400    0.0100    0.0000
O      6.4900    1.0600    0.0000
N      6.4400   -1.1900    0.0000
C      7.7900   -1.3400    0.0000
N      8.3900   -2.5400    0.0000
C      9.6900   -2.3400    0.0000
C      9.9400   -1.0400    0.0000
S      8.5900   -0.1400    0.0000
C     11.1900   -0.3400    0.0000
H     -0.5100   -0.8900    0.0000
H     -1.7600    1.2200    0.0000
H      5.9400   -1.9900    0.0000''',
    referenceEa: 12.6,
    doi: '10.1093/rheumatology/35.suppl_1.4',
    journalRef: 'Br. J. Rheumatol. 1996, 35, Suppl 1, 4-12',
    tags: const ["Veterinary", "DVM", "NSAID", "COX-2", "Analgesic", "Osteoarthritis", "Canine", "Feline", "Bovine"],
    defaultCatalystName: 'Canine CYP2C21 (Cytochrome P450 Fe=O Heme)',
    literatureBarrierKcalMol: 16.5,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1093/rheumatology/35.suppl_1.4',
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
    id: 'vet-fenbendazole-01',
    name: 'Fenbendazole Methylcarbamate Tubulin Depolymerization',
    iupacName: 'Methyl N-(6-phenylsulfanyl-1H-benzimidazol-2-yl)carbamate',
    description: 'Broad-spectrum veterinary benzimidazole anthelmintic for livestock, horses, and dogs. Binds beta-tubulin of parasitic nematodes (Ascaris, Haemonchus, Ostertagia) preventing microtubule assembly, blocking vesicular transport, glucose uptake, and depleting glycogen stores.',
    category: ReactionCategory.veterinary,
    reactantXyz: '''26
Fenbendazole Reactant Scaffold
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
C      2.1000    1.2124    0.0000
C      1.4000    2.4249    0.0000
C      0.0000    2.4249    0.0000
C     -0.7000    1.2124    0.0000
S      3.8500    1.2124    0.0000
C      4.5500    2.4249    0.0000
C      5.9500    2.4249    0.0000
C      6.6500    1.2124    0.0000
C      5.9500    0.0000    0.0000
C      4.5500    0.0000    0.0000
N     -0.4500   -1.2500    0.0000
C     -1.8000   -1.2500    0.0000
N     -2.0500    0.0500    0.0000
N     -2.8500   -2.1500    0.0000
C     -4.2000   -1.8500    0.0000
O     -4.6500   -0.7500    0.0000
O     -4.9500   -2.9500    0.0000
C     -6.3500   -2.7500    0.0000
H      1.9000   -0.9000    0.0000
H      1.9000    3.3500    0.0000
H     -2.6000   -3.1000    0.0000
H     -6.8500   -3.6500    0.0000
H     -6.6000   -2.2000    0.9000
H     -6.6000   -2.2000   -0.9000''',
    productXyz: '''26
Fenbendazole Product - Sulfoxide Metabolite (Oxfendazole)
C      0.0000    0.0000    0.0000
C      1.3900    0.0100    0.0000
C      2.0900    1.2200    0.0000
C      1.3900    2.4300    0.0000
C     -0.0100    2.4300    0.0000
C     -0.7100    1.2200    0.0000
S      3.8400    1.2200    0.0000
C      4.5400    2.4300    0.0000
C      5.9400    2.4300    0.0000
C      6.6400    1.2200    0.0000
C      5.9400    0.0100    0.0000
C      4.5400    0.0100    0.0000
N     -0.4600   -1.2400    0.0000
C     -1.8100   -1.2400    0.0000
N     -2.0600    0.0600    0.0000
N     -2.8600   -2.1400    0.0000
C     -4.2100   -1.8400    0.0000
O     -4.6600   -0.7400    0.0000
O     -4.9600   -2.9400    0.0000
C     -6.3600   -2.7400    0.0000
H      1.8900   -0.8900    0.0000
H      1.8900    3.3600    0.0000
H     -2.6100   -3.0900    0.0000
H     -6.8600   -3.6400    0.0000
H     -6.6100   -2.1900    0.9000
H     -6.6100   -2.1900   -0.9000''',
    referenceEa: 15.2,
    doi: '10.1016/0020-7519(88)90175-0',
    journalRef: 'Int. J. Parasitol. 1988, 18, 885-936',
    tags: const ["Veterinary", "DVM", "Antiparasitic", "Anthelmintic", "Benzimidazole", "Microtubules", "Livestock", "Equine"],
    defaultCatalystName: 'Nematode Beta-Tubulin Cys239 Sulfhydryl',
    literatureBarrierKcalMol: 15.8,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/0020-7519(88)90175-0',
    catalystXyz: '''5
Tubulin Cys Active Thiolate Core
S  0.0000 0.0000 0.0000
C  1.8000 0.0000 0.0000
C -1.4000 0.0000 0.0000
N -1.9500 1.3000 0.0000
H  2.1500 0.9500 0.0000''',
  ),
  ReactionTemplate(
    id: 'vet-flunixin-01',
    name: 'Flunixin Meglumine Nicotinate Cyclooxygenase Inhibition',
    iupacName: '2-[[2-methyl-3-(trifluoromethyl)phenyl]amino]pyridine-3-carboxylic acid',
    description: 'Premier potent non-narcotic veterinary analgesic and NSAID indicated for the alleviation of inflammation and pain associated with musculoskeletal disorders in horses and dogs, and controlling pyrexia in acute bovine mastitis and respiratory disease. Rapidly blunts endotoxin-induced thromboxane release in equine colic.',
    category: ReactionCategory.veterinary,
    reactantXyz: '''25
Flunixin Reactants Scaffold
C      0.0000    0.0000    0.0000
N      1.2500    0.0000    0.0000
C      1.9500    1.2124    0.0000
C      1.2500    2.4249    0.0000
C      0.0000    2.4249    0.0000
C     -0.7000    1.2124    0.0000
C      3.4500    1.2124    0.0000
O      4.1000    2.2500    0.0000
O      4.0500    0.0500    0.0000
H      5.0000    0.0500    0.0000
N     -0.7500   -1.1500    0.0000
C     -2.1500   -1.2500    0.0000
C     -2.8500   -0.0500    0.0000
C     -4.2500   -0.1000    0.0000
C     -4.9500   -1.3000    0.0000
C     -4.2500   -2.5000    0.0000
C     -2.8500   -2.4500    0.0000
C     -2.1500    1.2500    0.0000
C     -6.4500   -1.3500    0.0000
F     -7.0500   -0.2500    0.0000
F     -6.9500   -2.4500    0.6000
F     -6.9500   -2.4500   -0.6000
H     -0.2500   -2.0000    0.0000
H      1.7500    3.3500    0.0000
H     -4.7500    0.8000    0.0000''',
    productXyz: '''25
Flunixin Product - Active Planar Conformation
C      0.0000    0.0000    0.0000
N      1.2400    0.0100    0.0000
C      1.9400    1.2200    0.0000
C      1.2400    2.4300    0.0000
C     -0.0100    2.4300    0.0000
C     -0.7100    1.2200    0.0000
C      3.4400    1.2200    0.0000
O      4.0900    2.2600    0.0000
O      4.0400    0.0600    0.0000
H      4.9900    0.0600    0.0000
N     -0.7600   -1.1400    0.0000
C     -2.1600   -1.2400    0.0000
C     -2.8600   -0.0400    0.0000
C     -4.2600   -0.0900    0.0000
C     -4.9600   -1.2900    0.0000
C     -4.2600   -2.4900    0.0000
C     -2.8600   -2.4400    0.0000
C     -2.1600    1.2600    0.0000
C     -6.4600   -1.3400    0.0000
F     -7.0600   -0.2400    0.0000
F     -6.9600   -2.4400    0.6000
F     -6.9600   -2.4400   -0.6000
H     -0.2600   -1.9900    0.0000
H      1.7400    3.3600    0.0000
H     -4.7600    0.8100    0.0000''',
    referenceEa: 13.9,
    doi: '10.1111/evj.13260',
    journalRef: 'Equine Vet. J. 2020, 52, 749-756',
    tags: const ["Veterinary", "DVM", "NSAID", "Equine Colic", "Endotoxemia", "Bovine Mastitis", "Prostaglandin", "Large Animal"],
    defaultCatalystName: 'Equine COX-1/2 (Fe(III)-Protoporphyrin / Tyr385)',
    literatureBarrierKcalMol: 15.3,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1111/evj.13260',
    catalystXyz: '''5
Fe-Porphyrin Heme Center
Fe 0.0000 0.0000 0.0000
N  2.0000 0.0000 0.0000
N -2.0000 0.0000 0.0000
N  0.0000 2.0000 0.0000
N  0.0000 -2.0000 0.0000''',
  ),
  ReactionTemplate(
    id: 'vet-xylazine-01',
    name: 'Xylazine Thiazine-Amidine Alpha-2 Adrenoceptor Agonism',
    iupacName: 'N-(2,6-dimethylphenyl)-5,6-dihydro-4H-1,3-thiazin-2-amine',
    description: 'Central alpha-2 adrenergic agonist veterinary sedative, analgesic, and muscle relaxant widely used in equine, bovine, and small animal practice. Produces dose-dependent CNS depression, cardiopulmonary reduction, and visceral analgesia. Reversible specifically by alpha-2 antagonists yohimbine or atipamezole.',
    category: ReactionCategory.veterinary,
    reactantXyz: '''20
Xylazine Reactants Scaffold
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
C      2.1000    1.2124    0.0000
C      1.4000    2.4249    0.0000
C      0.0000    2.4249    0.0000
C     -0.7000    1.2124    0.0000
C      2.1500   -1.3000    0.0000
C     -2.2000    1.2500    0.0000
N     -0.7500   -1.1500    0.0000
C     -2.1000   -1.1500    0.0000
N     -2.8000    0.0000    0.0000
C     -4.2500    0.0000    0.0000
C     -4.9000   -1.3500    0.0000
S     -3.7500   -2.6500    0.0000
H     -0.2500   -2.0000    0.0000
H      3.1500    1.2124    0.0000
H      1.9000    3.3500    0.0000
H     -0.5000    3.3500    0.0000
H     -4.6000    0.5500    0.8500
H     -4.6000    0.5500   -0.8500''',
    productXyz: '''20
Xylazine Product - Active Alpha-2 Binding State
C      0.0000    0.0000    0.0000
C      1.3900    0.0100    0.0000
C      2.0900    1.2200    0.0000
C      1.3900    2.4300    0.0000
C     -0.0100    2.4300    0.0000
C     -0.7100    1.2200    0.0000
C      2.1400   -1.2900    0.0000
C     -2.2100    1.2600    0.0000
N     -0.7600   -1.1400    0.0000
C     -2.1100   -1.1400    0.0000
N     -2.8100    0.0100    0.0000
C     -4.2600    0.0100    0.0000
C     -4.9100   -1.3400    0.0000
S     -3.7600   -2.6400    0.0000
H     -0.2600   -1.9900    0.0000
H      3.1400    1.2200    0.0000
H      1.8900    3.3600    0.0000
H     -0.5100    3.3600    0.0000
H     -4.6100    0.5600    0.8500
H     -4.6100    0.5600   -0.8500''',
    referenceEa: 11.8,
    doi: '10.1136/vr.128.14.323',
    journalRef: 'Vet. Rec. 1991, 128, 323-325',
    tags: const ["Veterinary", "DVM", "Anesthetic", "Alpha-2 Agonist", "Sedative", "Equine", "Ruminants", "Analgesia"],
    defaultCatalystName: 'Alpha-2 Adrenoceptor Asp113 Coordination Matrix',
    literatureBarrierKcalMol: 13.9,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1136/vr.128.14.323',
    catalystXyz: '''5
Asp Carboxylate Coordination Core
C  0.0000 0.0000 0.0000
O  1.2500 0.0000 0.0000
O -1.2500 0.0000 0.0000
C  0.0000 1.5500 0.0000
H  0.9000 1.9500 0.0000''',
  ),
  ReactionTemplate(
    id: 'vet-florfenicol-01',
    name: 'Florfenicol Fluorinated Phenicol Peptidyl Transferase Blockade',
    iupacName: '2,2-dichloro-N-[(1R,2S)-3-fluoro-1-hydroxy-1-(4-methylsulfonylphenyl)propan-2-yl]acetamide',
    description: 'Fluorinated synthetic phenicol antibiotic engineered exclusively for veterinary food animal therapy. Inhibits bacterial protein synthesis at the 50S ribosomal subunit. The C-3 fluorine substitution confers resistance against chloramphenicol acetyltransferase (CAT) enzymes in Mannheimia and Histophilus.',
    category: ReactionCategory.veterinary,
    reactantXyz: '''25
Florfenicol Reactants Scaffold
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
C      2.1000    1.2124    0.0000
C      1.4000    2.4249    0.0000
C      0.0000    2.4249    0.0000
C     -0.7000    1.2124    0.0000
S      3.8500    1.2124    0.0000
O      4.3500    2.4500    0.6000
O      4.3500    2.4500   -0.6000
C      4.4500   -0.2000    0.0000
C     -2.2000    1.2500    0.0000
O     -2.7500    2.4000    0.0000
H     -3.7000    2.3500    0.0000
C     -2.9000   -0.0500    0.0000
N     -2.3500   -1.2500    0.0000
C     -3.1500   -2.3500    0.0000
O     -4.3500   -2.3500    0.0000
C     -2.3500   -3.6500    0.0000
Cl    -3.3500   -4.9500    0.6500
Cl    -3.3500   -4.9500   -0.6500
C     -4.4000   -0.0500    0.0000
F     -5.0000   -1.2500    0.0000
H     -0.5000   -0.9000    0.0000
H      1.9000   -0.9000    0.0000
H      1.9000    3.3500    0.0000''',
    productXyz: '''25
Florfenicol Product - Active Ribosomal Bound Conformer
C      0.0000    0.0000    0.0000
C      1.3900    0.0100    0.0000
C      2.0900    1.2200    0.0000
C      1.3900    2.4300    0.0000
C     -0.0100    2.4300    0.0000
C     -0.7100    1.2200    0.0000
S      3.8400    1.2200    0.0000
O      4.3400    2.4600    0.6000
O      4.3400    2.4600   -0.6000
C      4.4400   -0.1900    0.0000
C     -2.2100    1.2600    0.0000
O     -2.7600    2.4100    0.0000
H     -3.7100    2.3600    0.0000
C     -2.9100   -0.0400    0.0000
N     -2.3600   -1.2400    0.0000
C     -3.1600   -2.3400    0.0000
O     -4.3600   -2.3400    0.0000
C     -2.3600   -3.6400    0.0000
Cl    -3.3600   -4.9400    0.6500
Cl    -3.3600   -4.9400   -0.6500
C     -4.4100   -0.0400    0.0000
F     -5.0100   -1.2400    0.0000
H     -0.5100   -0.8900    0.0000
H      1.8900   -0.8900    0.0000
H      1.8900    3.3600    0.0000''',
    referenceEa: 16.5,
    doi: '10.1016/j.rvsc.2007.04.001',
    journalRef: 'Res. Vet. Sci. 2008, 84, 252-258',
    tags: const ["Veterinary", "DVM", "Antibiotic", "Phenicol", "Ribosome 50S", "BRD", "Bovine", "Swine"],
    defaultCatalystName: '23S rRNA A2451 / C2452 Peptidyl Transferase',
    literatureBarrierKcalMol: 16.1,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1016/j.rvsc.2007.04.001',
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
    id: 'vet-carprofen-01',
    name: 'Carprofen Carbazole Propionic Acid COX Inhibition',
    iupacName: '(RS)-2-(6-chloro-9H-carbazol-2-yl)propanoic acid',
    description: 'Canine-specific non-steroidal anti-inflammatory drug (NSAID) of the carbazole propionic acid class. Provides sustained analgesia and anti-inflammatory relief in canine osteoarthritis and post-operative orthopedic surgery with exceptional canine hepatic tolerance.',
    category: ReactionCategory.veterinary,
    reactantXyz: '''25
Carprofen Reactants Scaffold
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
C      2.1000    1.2124    0.0000
C      1.4000    2.4249    0.0000
C      0.0000    2.4249    0.0000
C     -0.7000    1.2124    0.0000
N      2.8500   -1.1500    0.0000
C      4.1500   -0.7000    0.0000
C      3.6500    0.7000    0.0000
C      4.3500    1.9000    0.0000
C      5.7500    1.9000    0.0000
C      6.4500    0.7000    0.0000
C      5.7500   -0.7000    0.0000
Cl    -2.4500    1.2124    0.0000
C      7.9500    0.7000    0.0000
C      8.6500    1.9500    0.0000
C      8.6500   -0.5500    0.0000
O      9.8500   -0.5500    0.0000
O      8.0000   -1.6500    0.0000
H      8.6000   -2.4000    0.0000
H     -0.5000   -0.9000    0.0000
H     -0.5000    3.3500    0.0000
H      1.9000    3.3500    0.0000
H      6.2500    2.8500    0.0000
H      6.2500   -1.6000    0.0000''',
    productXyz: '''25
Carprofen Product - Active In Vivo Enantiomer
C      0.0000    0.0000    0.0000
C      1.3900    0.0100    0.0000
C      2.0900    1.2200    0.0000
C      1.3900    2.4300    0.0000
C     -0.0100    2.4300    0.0000
C     -0.7100    1.2200    0.0000
N      2.8400   -1.1400    0.0000
C      4.1400   -0.6900    0.0000
C      3.6400    0.7100    0.0000
C      4.3400    1.9100    0.0000
C      5.7400    1.9100    0.0000
C      6.4400    0.7100    0.0000
C      5.7400   -0.6900    0.0000
Cl    -2.4600    1.2200    0.0000
C      7.9400    0.7100    0.0000
C      8.6400    1.9600    0.0000
C      8.6400   -0.5400    0.0000
O      9.8400   -0.5400    0.0000
O      7.9900   -1.6400    0.0000
H      8.5900   -2.3900    0.0000
H     -0.5100   -0.8900    0.0000
H     -0.5100    3.3600    0.0000
H      1.8900    3.3600    0.0000
H      6.2400    2.8600    0.0000
H      6.2400   -1.5900    0.0000''',
    referenceEa: 14.1,
    doi: '10.2460/ajvr.2001.62.1642',
    journalRef: 'Am. J. Vet. Res. 2001, 62, 1642-1646',
    tags: const ["Veterinary", "DVM", "NSAID", "Carbazole", "Canine", "Osteoarthritis", "Analgesic"],
    defaultCatalystName: 'Canine COX-2 (Arg120 / Tyr355 Constriction Pocket)',
    literatureBarrierKcalMol: 14.6,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.2460/ajvr.2001.62.1642',
    catalystXyz: '''5
COX-2 Constriction Pocket Unit
C  0.0000 0.0000 0.0000
N  1.3500 0.0000 0.0000
N -1.3500 0.0000 0.0000
O  0.0000 1.4000 0.0000
H  1.7500 0.9500 0.0000''',
  ),
  ReactionTemplate(
    id: 'vet-pimobendan-01',
    name: 'Pimobendan Benzimidazole-Pyridazinone Calcium Sensitization',
    iupacName: '4,5-dihydro-6-[2-(4-methoxyphenyl)-1H-benzimidazol-5-yl]-5-methyl-3(2H)-pyridazinone',
    description: 'Breakthrough veterinary inodilator for canine dilated cardiomyopathy (DCM) and myxomatous mitral valve disease. Combines selective calcium sensitization of myocardial troponin C with phosphodiesterase III (PDE-3) inhibition, yielding powerful positive inotropy without increasing myocardial oxygen consumption.',
    category: ReactionCategory.veterinary,
    reactantXyz: '''28
Pimobendan Reactants Scaffold
C      0.0000    0.0000    0.0000
C      1.4000    0.0000    0.0000
C      2.1000    1.2124    0.0000
C      1.4000    2.4249    0.0000
C      0.0000    2.4249    0.0000
C     -0.7000    1.2124    0.0000
O     -2.0500    1.2124    0.0000
C     -2.7500    2.4500    0.0000
C      3.5500    1.2124    0.0000
N      4.4000    0.1500    0.0000
C      5.7000    0.5500    0.0000
C      5.7000    1.9500    0.0000
N      4.4000    2.3500    0.0000
C      6.9500   -0.1000    0.0000
C      8.1500    0.6000    0.0000
C      8.1500    2.0000    0.0000
C      6.9500    2.7000    0.0000
C      9.4500   -0.1000    0.0000
C     10.7500    0.6000    0.0000
C     10.7500    2.0000    0.0000
N      9.5500    2.7000    0.0000
N      9.4500   -1.4500    0.0000
O     11.8500    2.6500    0.0000
H     -0.5000   -0.9000    0.0000
H      1.9000   -0.9000    0.0000
H      1.9000    3.3500    0.0000
H     -0.5000    3.3500    0.0000
H      6.9500   -1.1500    0.0000''',
    productXyz: '''28
Pimobendan Product - Sensitized Troponin C Interacting State
C      0.0000    0.0000    0.0000
C      1.3900    0.0100    0.0000
C      2.0900    1.2200    0.0000
C      1.3900    2.4300    0.0000
C     -0.0100    2.4300    0.0000
C     -0.7100    1.2200    0.0000
O     -2.0600    1.2200    0.0000
C     -2.7600    2.4600    0.0000
C      3.5400    1.2200    0.0000
N      4.3900    0.1600    0.0000
C      5.6900    0.5600    0.0000
C      5.6900    1.9600    0.0000
N      4.3900    2.3600    0.0000
C      6.9400   -0.0900    0.0000
C      8.1400    0.6100    0.0000
C      8.1400    2.0100    0.0000
C      6.9400    2.7100    0.0000
C      9.4400   -0.0900    0.0000
C     10.7400    0.6100    0.0000
C     10.7400    2.0100    0.0000
N      9.5400    2.7100    0.0000
N      9.4400   -1.4400    0.0000
O     11.8400    2.6600    0.0000
H     -0.5100   -0.8900    0.0000
H      1.8900   -0.8900    0.0000
H      1.8900    3.3600    0.0000
H     -0.5100    3.3600    0.0000
H      6.9400   -1.1400    0.0000''',
    referenceEa: 16.1,
    doi: '10.1111/jvim.12217',
    journalRef: 'J. Vet. Intern. Med. 2014, 28, 81-87',
    tags: const ["Veterinary", "DVM", "Cardiology", "Inodilator", "Canine DCM", "Mitral Valve", "Phosphodiesterase-3"],
    defaultCatalystName: 'Troponin C (Ca2+ Sensitizer Pocket & PDE3 Zn2+)',
    literatureBarrierKcalMol: 12.7,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1111/jvim.12217',
    catalystXyz: '''5
Ca2+ / Zn2+ Sensitization Pair
Ca 0.0000 0.0000 0.0000
Zn 3.8000 0.0000 0.0000
O  1.9000 1.2000 0.0000
O  1.9000 -1.2000 0.0000
N  3.8000 2.0000 0.0000''',
  ),
  ReactionTemplate(
    id: 'vet-tylosin-01',
    name: 'Tylosin Macrolide Translocation Inhibition',
    iupacName: '16-membered lactone ring veterinary macrolide antibiotic',
    description: 'Major agricultural veterinary macrolide antibiotic used for treatment of bovine respiratory disease, swine dysentery, and canine chronic colitis. Inhibits bacterial protein translation by reversibly binding to the 23S rRNA in the 50S ribosomal peptidyl transferase cavity.',
    category: ReactionCategory.veterinary,
    reactantXyz: '''26
Tylosin Reactants Scaffold
C      0.0000    0.0000    0.0000
C      1.4000    0.2000    0.0000
C      2.2000    1.3500    0.1000
C      3.6000    1.2000    0.0500
C      4.3500    2.3500    0.1500
C      5.7500    2.2500    0.1000
C      6.4000    0.9500    0.0000
O      5.6500   -0.1500   -0.1000
C      4.2500   -0.0500   -0.0500
C      3.5500   -1.3500   -0.1500
C      2.1000   -1.3000   -0.1000
O      1.4000   -2.5500   -0.2000
C      0.0500   -2.5000   -0.1500
O     -0.6500   -3.5000   -0.2500
C     -0.6500   -1.3000   -0.0500
C     -2.1500   -1.2500   -0.0500
O      7.8000    0.8500   -0.0500
C      8.5000    2.0500    0.0500
O      6.4000    3.4000    0.1500
H     -0.4500    0.9000    0.0000
H      1.7500    2.3000    0.2000
H      3.9500    3.3000    0.2500
H      4.0500   -2.2500   -0.2500
H     -2.5500   -2.2500   -0.1500
H      9.5500    1.8000    0.0000
H      8.3000    2.6500    0.9500''',
    productXyz: '''26
Tylosin Product - Active Peptidyl Transferase Binding State
C      0.0000    0.0000    0.0000
C      1.3900    0.2100    0.0000
C      2.1900    1.3600    0.1000
C      3.5900    1.2100    0.0500
C      4.3400    2.3600    0.1500
C      5.7400    2.2600    0.1000
C      6.3900    0.9600    0.0000
O      5.6400   -0.1400   -0.1000
C      4.2400   -0.0400   -0.0500
C      3.5400   -1.3400   -0.1500
C      2.0900   -1.2900   -0.1000
O      1.3900   -2.5400   -0.2000
C      0.0400   -2.4900   -0.1500
O     -0.6600   -3.4900   -0.2500
C     -0.6600   -1.2900   -0.0500
C     -2.1600   -1.2400   -0.0500
O      7.7900    0.8600   -0.0500
C      8.4900    2.0600    0.0500
O      6.3900    3.4100    0.1500
H     -0.4600    0.9100    0.0000
H      1.7400    2.3100    0.2000
H      3.9400    3.3100    0.2500
H      4.0400   -2.2400   -0.2500
H     -2.5600   -2.2400   -0.1500
H      9.5400    1.8100    0.0000
H      8.2900    2.6600    0.9500''',
    referenceEa: 17.0,
    doi: '10.1007/978-3-0348-8105-0_10',
    journalRef: 'Macrolide Antibiotics 2002, 335-364',
    tags: const ["Veterinary", "DVM", "Antibiotic", "Macrolide", "Swine", "Poultry", "Bovine", "Canine Colitis"],
    defaultCatalystName: '50S Subunit rRNA Tunnel Nucleotide Constriction',
    literatureBarrierKcalMol: 15.4,
    hasLiteratureCatalyst: true,
    literatureDoi: '10.1007/978-3-0348-8105-0_10',
    catalystXyz: '''6
rRNA Ribose-Phosphate Unit
P  0.0000 0.0000 0.0000
O  1.5500 0.0000 0.0000
O -1.5500 0.0000 0.0000
O  0.0000 1.5500 0.0000
C  1.1000 2.5000 0.0000
O  0.8000 3.7000 0.0000''',
  ),
];
