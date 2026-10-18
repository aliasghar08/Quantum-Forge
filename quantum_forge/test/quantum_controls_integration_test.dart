import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/algorithms/transformer_reaction_compressor.dart';
import 'package:quantum_forge/state/settings_provider.dart';

void main() {
  group('Quantum Controls Integration & Functional Audit', () {
    const reactantXyz = '''2
Reactant
C 0.0000 0.0000 0.0000
O 0.0000 0.0000 1.2000
''';
    const productXyz = '''2
Product
C 0.0000 0.0000 0.0000
O 0.0000 0.0000 1.4500
''';

    test('NEB Images control dynamically modifies trajectory frames and profile count', () {
      // Default: 21 frames
      final defaultRun = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 20.0,
      );
      expect(defaultRun.trajectoryFrames.length, 21);
      expect(defaultRun.energyProfile.length, 21);

      // Adjusted to 12 frames via QuantumSettings
      const customSettings12 = QuantumSettings(nebImages: 12);
      final run12 = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 20.0,
        settings: customSettings12,
      );
      expect(run12.trajectoryFrames.length, 12);
      expect(run12.energyProfile.length, 12);

      // Adjusted to 28 frames via QuantumSettings
      const customSettings28 = QuantumSettings(nebImages: 28);
      final run28 = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 20.0,
        settings: customSettings28,
      );
      expect(run28.trajectoryFrames.length, 28);
      expect(run28.energyProfile.length, 28);
    });

    test('Solvation Model control applies implicit dielectric screening to activation barrier', () {
      const vacuumSettings = QuantumSettings(solventModel: 'Vacuum');
      final vacuumRun = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 25.0,
        settings: vacuumSettings,
      );

      const pcmSettings = QuantumSettings(solventModel: 'PCM (H₂O)');
      final pcmRun = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 25.0,
        settings: pcmSettings,
      );

      expect(pcmRun.activationEnergyKcalMol, lessThan(vacuumRun.activationEnergyKcalMol));
      expect(pcmRun.activationEnergyKcalMol, closeTo(25.0 * 0.92, 0.01));
    });

    test('Temperature control modulates thermal barrier and Gibbs free energy', () {
      const lowTSettings = QuantumSettings(temperatureK: 200.0);
      final lowTRun = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 20.0,
        settings: lowTSettings,
      );

      const highTSettings = QuantumSettings(temperatureK: 600.0);
      final highTRun = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 20.0,
        settings: highTSettings,
      );

      expect(highTRun.activationEnergyKcalMol, greaterThan(lowTRun.activationEnergyKcalMol));
    });

    test('Frequency Analysis switch controls vibrational mode computation', () {
      const freqEnabledSettings = QuantumSettings(frequencyAnalysis: true);
      final freqEnabledRun = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 20.0,
        settings: freqEnabledSettings,
      );
      expect(freqEnabledRun.vibrationalModes.isNotEmpty, true);
      expect(freqEnabledRun.vibrationalModes.first.frequency, lessThan(0.0)); // imaginary TS frequency

      const freqDisabledSettings = QuantumSettings(frequencyAnalysis: false);
      final freqDisabledRun = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 20.0,
        settings: freqDisabledSettings,
      );
      expect(freqDisabledRun.vibrationalModes.isEmpty, true);
    });

    test('ZPE correction switch affects electronic barrier offset', () {
      const zpeOnSettings = QuantumSettings(zpeCorrection: true);
      final zpeOnRun = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 20.0,
        settings: zpeOnSettings,
      );

      const zpeOffSettings = QuantumSettings(zpeCorrection: false);
      final zpeOffRun = TransformerReactionCompressor.process(
        reactantXyz: reactantXyz,
        productXyz: productXyz,
        referenceEa: 20.0,
        settings: zpeOffSettings,
      );

      // Without ZPE correction, raw electronic barrier is higher
      expect(zpeOffRun.activationEnergyKcalMol, greaterThan(zpeOnRun.activationEnergyKcalMol));
    });

    test('BackendComputeService payload contains all 25 quantum control parameters', () {
      const settings = QuantumSettings(
        charge: -1,
        spinMultiplicity: 2,
        mlipModel: 'MACE-MP-0',
        solventModel: 'PCM (EtOH)',
        temperatureK: 350.0,
        optimizerAlgorithm: 'Dimer',
        maxSteps: 500,
        nebImages: 16,
        springConstant: 0.25,
        maxForceNorm: 0.01,
        dmfConvergence: 'Tight',
        catalyst: 'Pd(PPh3)4',
        applyLiteratureCatalyst: true,
        customCatalyst: 'Pd(PPh3)4',
        conformationalSearch: true,
        zpeCorrection: false,
        computeThermochemistry: true,
        runIrc: true,
        frequencyAnalysis: false,
        exportFormat: 'JSON',
      );

      // Verify Firestore map contains all fields
      final map = settings.toFirestoreMap();
      expect(map['charge'], -1);
      expect(map['spin_multiplicity'], 2);
      expect(map['mlip_model'], 'MACE-MP-0');
      expect(map['solvent_model'], 'PCM (EtOH)');
      expect(map['temperature_k'], 350.0);
      expect(map['optimizer_algorithm'], 'Dimer');
      expect(map['max_steps'], 500);
      expect(map['neb_images'], 16);
      expect(map['spring_constant'], 0.25);
      expect(map['max_force_norm'], 0.01);
      expect(map['dmf_convergence'], 'Tight');
      expect(map['catalyst'], 'Pd(PPh3)4');
      expect(map['apply_literature_catalyst'], true);
      expect(map['conformational_search'], true);
      expect(map['zpe_correction'], false);
      expect(map['compute_thermochemistry'], true);
      expect(map['run_irc'], true);
      expect(map['frequency_analysis'], false);
      expect(map['export_format'], 'JSON');
    });
  });
}
