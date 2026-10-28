import 'package:flutter/material.dart';
import 'package:quantum_forge/core/algorithms/solvent_properties.dart';

class ThermodynamicMetric {
  final String label;
  final String value;
  final String unit;
  final String? uncertainty;
  final Color accentColor;

  const ThermodynamicMetric({
    required this.label,
    required this.value,
    required this.unit,
    this.uncertainty,
    required this.accentColor,
  });
}

class ReactionWorkspaceViewModel extends ChangeNotifier {
  // --- Workspace State ---
  String reactionTitle = "Ozonolysis";
  String reactionSubtitle = "Ethylene + Ozone → 1,2,3-Trioxolane";
  bool isTemplateLoaded = true;
  bool isCalculating = false;
  bool isSignedIn = false;

  // --- Quantum Parameters ---
  int systemCharge = 0;
  String spinMultiplicity = "2S+1 = 1";
  String mlipModel = "tx1-v2";
  String solvationModel = "Vacuum";
  double temperature = 298.1;
  String optimizer = "NEB-CI";

  // --- Kinetic & Thermodynamic Results ---
  double activationEnergyEa = 26.0;
  double eaUncertainty = 2.0;
  double gibbsFreeEnergy = 28.0;
  double enthalpy = 25.0;
  String rateConstant = "10⁽⁻⁸˙¹ ± ¹˙²⁾";

  List<ThermodynamicMetric> get thermodynamicMetrics => [
    const ThermodynamicMetric(
      label: "Imaginary Freq. (ν‡)",
      value: "-449",
      unit: "cm⁻¹",
      uncertainty: "±45",
      accentColor: Colors.amber,
    ),
    const ThermodynamicMetric(
      label: "ZPE Correction",
      value: "14.4",
      unit: "kcal·mol⁻¹",
      uncertainty: "±0.3",
      accentColor: Colors.purpleAccent,
    ),
    const ThermodynamicMetric(
      label: "Dipole Moment (μ)",
      value: "2.4",
      unit: "D",
      uncertainty: "±0.3",
      accentColor: Colors.tealAccent,
    ),
    const ThermodynamicMetric(
      label: "HOMO-LUMO Gap",
      value: "5.1",
      unit: "eV",
      uncertainty: "±0.3",
      accentColor: Colors.blueAccent,
    ),
    const ThermodynamicMetric(
      label: "Polarizability (α)",
      value: "45",
      unit: "Bohr³",
      uncertainty: "±4",
      accentColor: Colors.lightGreenAccent,
    ),
    const ThermodynamicMetric(
      label: "RMS Gradient",
      value: "3.4×10⁻⁴",
      unit: "a.u.",
      uncertainty: "±1×10⁻⁴",
      accentColor: Colors.orangeAccent,
    ),
  ];

  // --- Actions ---
  void setSolvationModel(String model) {
    solvationModel = model;
    final solventData = SolventProperties.lookup(model);
    activationEnergyEa = 26.0 * solventData.compressorMultiplier;
    enthalpy = 25.0 * solventData.barrierScaleFactor;
    gibbsFreeEnergy = enthalpy - (temperature * (-12.3 + solventData.entropyShift) / 1000.0);
    notifyListeners();
  }

  void setSystemCharge(int charge) {
    systemCharge = charge;
    notifyListeners();
  }

  void setSpinMultiplicity(String multiplicity) {
    spinMultiplicity = multiplicity;
    notifyListeners();
  }

  void setMlipModel(String model) {
    mlipModel = model;
    notifyListeners();
  }

  void setOptimizer(String opt) {
    optimizer = opt;
    notifyListeners();
  }

  void setTemperature(double temp) {
    temperature = temp;
    notifyListeners();
  }

  Future<void> executeTsSearch() async {
    isCalculating = true;
    notifyListeners();
    // API execution logic
    await Future.delayed(const Duration(seconds: 1));
    isCalculating = false;
    notifyListeners();
  }

  void exportFile(String format) {
    // Export handler logic (.xyz, .zip, trajectory, Firebase)
    debugPrint("Exporting format: $format");
  }

  void toggleSignIn() {
    isSignedIn = !isSignedIn;
    notifyListeners();
  }
}
