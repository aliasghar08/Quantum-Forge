/// Physical parameters and dielectric continuum properties for implicit solvent models.
///
/// In computational quantum chemistry (e.g. Gaussian, ORCA, Q-Chem), implicit
/// solvent models model the solvent environment as a dielectric continuum with
/// dielectric constant (relative permittivity) ε_r.
///
/// Supported model types:
/// - Gas Phase / Vacuum (ε_r = 1.0)
/// - Polarizable Continuum Model (PCM)
/// - Solvation Model based on Density (SMD) with cavitation, dispersion, and solvent structure
/// - Onsager reaction field dipole spherical cavity model
class SolventData {
  final String id;
  final String displayName;
  final double dielectricConstant; // Relative permittivity ε_r
  final String method; // 'PCM', 'SMD', 'Onsager', 'Gas Phase'
  final double barrierScaleFactor; // Activation barrier scaling factor
  final double compressorMultiplier; // Peak Ea multiplier for trajectory compression
  final double entropyShift; // Entropy contribution ΔS_solv (cal·mol⁻¹·K⁻¹)
  final double polarizabilityShift; // Polarizability contribution Δα_solv (Bohr³)
  final String description;

  const SolventData({
    required this.id,
    required this.displayName,
    required this.dielectricConstant,
    required this.method,
    required this.barrierScaleFactor,
    required this.compressorMultiplier,
    required this.entropyShift,
    required this.polarizabilityShift,
    required this.description,
  });

  /// The Kirkwood-Onsager dielectric reaction field screening factor:
  /// f(ε_r) = (ε_r - 1) / (2ε_r + 1)
  double get kirkwoodOnsagerFactor {
    if (dielectricConstant <= 1.0) return 0.0;
    return (dielectricConstant - 1.0) / (2.0 * dielectricConstant + 1.0);
  }

  /// Whether this model represents an active solvent environment (not vacuum).
  bool get isSolvated => dielectricConstant > 1.001;
}

class SolventProperties {
  SolventProperties._();

  static const SolventData vacuum = SolventData(
    id: 'Vacuum',
    displayName: 'Vacuum (Gas Phase)',
    dielectricConstant: 1.0,
    method: 'Gas Phase',
    barrierScaleFactor: 1.000,
    compressorMultiplier: 1.000,
    entropyShift: 0.0,
    polarizabilityShift: 0.0,
    description: 'Gas phase without solvent polarization (ε_r = 1.0)',
  );

  static const SolventData pcmHexane = SolventData(
    id: 'PCM (Hexane)',
    displayName: 'PCM (Hexane)',
    dielectricConstant: 1.88,
    method: 'PCM',
    barrierScaleFactor: 0.970,
    compressorMultiplier: 0.985,
    entropyShift: 0.3,
    polarizabilityShift: 2.4,
    description: 'Nonpolar alkane solvent (ε_r = 1.88)',
  );

  static const SolventData pcmToluene = SolventData(
    id: 'PCM (Toluene)',
    displayName: 'PCM (Toluene)',
    dielectricConstant: 2.38,
    method: 'PCM',
    barrierScaleFactor: 0.960,
    compressorMultiplier: 0.978,
    entropyShift: 0.5,
    polarizabilityShift: 3.5,
    description: 'Nonpolar aromatic hydrocarbon solvent (ε_r = 2.38)',
  );

  static const SolventData pcmThf = SolventData(
    id: 'PCM (THF)',
    displayName: 'PCM (THF)',
    dielectricConstant: 7.58,
    method: 'PCM',
    barrierScaleFactor: 0.920,
    compressorMultiplier: 0.955,
    entropyShift: 1.1,
    polarizabilityShift: 6.8,
    description: 'Moderately polar cyclic ether solvent (ε_r = 7.58)',
  );

  static const SolventData pcmDcm = SolventData(
    id: 'PCM (DCM)',
    displayName: 'PCM (DCM)',
    dielectricConstant: 8.93,
    method: 'PCM',
    barrierScaleFactor: 0.915,
    compressorMultiplier: 0.950,
    entropyShift: 1.2,
    polarizabilityShift: 7.5,
    description: 'Polar halogenated solvent (ε_r = 8.93)',
  );

  static const SolventData pcmEtoh = SolventData(
    id: 'PCM (EtOH)',
    displayName: 'PCM (EtOH)',
    dielectricConstant: 24.5,
    method: 'PCM',
    barrierScaleFactor: 0.880,
    compressorMultiplier: 0.935,
    entropyShift: 1.6,
    polarizabilityShift: 9.8,
    description: 'Polar protic ethanol solvent (ε_r = 24.5)',
  );

  static const SolventData pcmMeoh = SolventData(
    id: 'PCM (MeOH)',
    displayName: 'PCM (MeOH)',
    dielectricConstant: 32.7,
    method: 'PCM',
    barrierScaleFactor: 0.870,
    compressorMultiplier: 0.930,
    entropyShift: 1.7,
    polarizabilityShift: 10.5,
    description: 'Polar protic methanol solvent (ε_r = 32.7)',
  );

  static const SolventData pcmDmso = SolventData(
    id: 'PCM (DMSO)',
    displayName: 'PCM (DMSO)',
    dielectricConstant: 46.7,
    method: 'PCM',
    barrierScaleFactor: 0.860,
    compressorMultiplier: 0.925,
    entropyShift: 1.9,
    polarizabilityShift: 11.4,
    description: 'Highly polar aprotic dimethyl sulfoxide solvent (ε_r = 46.7)',
  );

  static const SolventData onsager = SolventData(
    id: 'Onsager (ε=78.4)',
    displayName: 'Onsager (ε=78.4)',
    dielectricConstant: 78.4,
    method: 'Onsager',
    barrierScaleFactor: 0.852,
    compressorMultiplier: 0.922,
    entropyShift: 1.95,
    polarizabilityShift: 11.8,
    description: 'Dipolar spherical reaction cavity model (ε_r = 78.4)',
  );

  static const SolventData pcmH2O = SolventData(
    id: 'PCM (H₂O)',
    displayName: 'PCM (H₂O)',
    dielectricConstant: 80.1,
    method: 'PCM',
    barrierScaleFactor: 0.850,
    compressorMultiplier: 0.920,
    entropyShift: 2.0,
    polarizabilityShift: 12.0,
    description: 'Polarizable continuum aqueous solvent (ε_r = 80.1)',
  );

  static const SolventData smdDmso = SolventData(
    id: 'SMD (DMSO)',
    displayName: 'SMD (DMSO)',
    dielectricConstant: 46.7,
    method: 'SMD',
    barrierScaleFactor: 0.845,
    compressorMultiplier: 0.915,
    entropyShift: 2.1,
    polarizabilityShift: 12.2,
    description: 'Density-based continuum with cavitation in DMSO (ε_r = 46.7)',
  );

  static const SolventData smdH2O = SolventData(
    id: 'SMD (H₂O)',
    displayName: 'SMD (H₂O)',
    dielectricConstant: 80.1,
    method: 'SMD',
    barrierScaleFactor: 0.835,
    compressorMultiplier: 0.910,
    entropyShift: 2.3,
    polarizabilityShift: 12.6,
    description: 'Density-based continuum with cavitation & H-bonding in H₂O (ε_r = 80.1)',
  );

  /// Complete list of standard solvent models available in Quantum Forge.
  static const List<SolventData> all = [
    vacuum,
    pcmH2O,
    pcmEtoh,
    pcmMeoh,
    pcmDmso,
    pcmThf,
    pcmDcm,
    pcmToluene,
    pcmHexane,
    onsager,
    smdH2O,
    smdDmso,
  ];

  /// Look up solvent properties by model string (case-insensitive with common aliases).
  static SolventData lookup(String? solventModel) {
    if (solventModel == null) return vacuum;
    final trimmed = solventModel.trim();
    if (trimmed.isEmpty) return vacuum;

    final lower = trimmed.toLowerCase();
    if (lower == 'vacuum' || lower == 'none' || lower == 'gas' || lower == 'gas phase') {
      return vacuum;
    }

    // Direct ID match
    for (final s in all) {
      if (s.id.toLowerCase() == lower || s.displayName.toLowerCase() == lower) {
        return s;
      }
    }

    // Fuzzy & common alias matching
    if (lower.contains('smd') && (lower.contains('h2o') || lower.contains('h₂o') || lower.contains('water'))) {
      return smdH2O;
    }
    if (lower.contains('smd') && lower.contains('dmso')) {
      return smdDmso;
    }
    if (lower.contains('onsager') || lower.contains('78.4')) {
      return onsager;
    }
    if (lower.contains('h2o') || lower.contains('h₂o') || lower.contains('water') || lower.contains('aqueous')) {
      return pcmH2O;
    }
    if (lower.contains('etoh') || lower.contains('ethanol')) {
      return pcmEtoh;
    }
    if (lower.contains('meoh') || lower.contains('methanol')) {
      return pcmMeoh;
    }
    if (lower.contains('dmso')) {
      return pcmDmso;
    }
    if (lower.contains('thf') || lower.contains('tetrahydrofuran')) {
      return pcmThf;
    }
    if (lower.contains('dcm') || lower.contains('dichloromethane') || lower.contains('ch2cl2')) {
      return pcmDcm;
    }
    if (lower.contains('toluene')) {
      return pcmToluene;
    }
    if (lower.contains('hexane')) {
      return pcmHexane;
    }

    // Fallback: If unknown string contains PCM or SMD, default to PCM (H₂O), else vacuum
    if (lower.contains('pcm') || lower.contains('smd')) {
      return pcmH2O;
    }
    return vacuum;
  }
}
