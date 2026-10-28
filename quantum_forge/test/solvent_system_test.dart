import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/algorithms/solvent_properties.dart';
import 'package:quantum_forge/core/algorithms/transformer_reaction_compressor.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/results_summary.dart';
import 'package:quantum_forge/state/settings_provider.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/views/reaction_workspace_viewmodel.dart';

void main() {
  group('SolventProperties Model Tests', () {
    test('contains all 12 standard solvent continuum models', () {
      expect(SolventProperties.all.length, 12);
      final ids = SolventProperties.all.map((s) => s.id).toList();
      expect(ids, containsAll([
        'Vacuum',
        'PCM (H₂O)',
        'PCM (EtOH)',
        'PCM (MeOH)',
        'PCM (DMSO)',
        'PCM (THF)',
        'PCM (DCM)',
        'PCM (Toluene)',
        'PCM (Hexane)',
        'Onsager (ε=78.4)',
        'SMD (H₂O)',
        'SMD (DMSO)',
      ]));
    });

    test('dielectric constants are physically ordered and positive', () {
      final vacuum = SolventProperties.lookup('Vacuum');
      final hexane = SolventProperties.lookup('PCM (Hexane)');
      final toluene = SolventProperties.lookup('PCM (Toluene)');
      final thf = SolventProperties.lookup('PCM (THF)');
      final dcm = SolventProperties.lookup('PCM (DCM)');
      final etoh = SolventProperties.lookup('PCM (EtOH)');
      final meoh = SolventProperties.lookup('PCM (MeOH)');
      final dmso = SolventProperties.lookup('PCM (DMSO)');
      final water = SolventProperties.lookup('PCM (H₂O)');

      expect(vacuum.dielectricConstant, 1.0);
      expect(hexane.dielectricConstant, lessThan(toluene.dielectricConstant));
      expect(toluene.dielectricConstant, lessThan(thf.dielectricConstant));
      expect(thf.dielectricConstant, lessThan(dcm.dielectricConstant));
      expect(dcm.dielectricConstant, lessThan(etoh.dielectricConstant));
      expect(etoh.dielectricConstant, lessThan(meoh.dielectricConstant));
      expect(meoh.dielectricConstant, lessThan(dmso.dielectricConstant));
      expect(dmso.dielectricConstant, lessThan(water.dielectricConstant));
      expect(water.dielectricConstant, 80.1);
    });

    test('Kirkwood-Onsager factor f(ε) matches physical continuum theory', () {
      final vacuum = SolventProperties.lookup('Vacuum');
      expect(vacuum.kirkwoodOnsagerFactor, 0.0);

      final water = SolventProperties.lookup('PCM (H₂O)');
      // (80.1 - 1) / (2 * 80.1 + 1) = 79.1 / 161.2 ≈ 0.4907
      expect(water.kirkwoodOnsagerFactor, closeTo(0.4907, 0.001));

      final hexane = SolventProperties.lookup('PCM (Hexane)');
      // (1.88 - 1) / (2 * 1.88 + 1) = 0.88 / 4.76 ≈ 0.1849
      expect(hexane.kirkwoodOnsagerFactor, closeTo(0.1849, 0.001));
      expect(hexane.kirkwoodOnsagerFactor, lessThan(water.kirkwoodOnsagerFactor));
    });

    test('lookup handles aliases and case-insensitivity robustly', () {
      expect(SolventProperties.lookup('none').id, 'Vacuum');
      expect(SolventProperties.lookup('GAS PHASE').id, 'Vacuum');
      expect(SolventProperties.lookup('water').id, 'PCM (H₂O)');
      expect(SolventProperties.lookup('ethanol').id, 'PCM (EtOH)');
      expect(SolventProperties.lookup('dichloromethane').id, 'PCM (DCM)');
      expect(SolventProperties.lookup('smd water').id, 'SMD (H₂O)');
      expect(SolventProperties.lookup('smd dmso').id, 'SMD (DMSO)');
      expect(SolventProperties.lookup(null).id, 'Vacuum');
    });
  });

  group('TransformerReactionCompressor Differential Solvation Tests', () {
    const reactant = '2\n\nC 0.0 0.0 0.0\nH 0.0 0.0 1.09';
    const product = '2\n\nC 0.0 0.0 0.0\nH 0.0 0.0 1.50';

    test('different solvents produce distinct, physically ordered activation barriers', () {
      final runVacuum = TransformerReactionCompressor.process(
        reactantXyz: reactant,
        productXyz: product,
        referenceEa: 25.0,
        settings: const QuantumSettings(solventModel: 'Vacuum'),
      );

      final runHexane = TransformerReactionCompressor.process(
        reactantXyz: reactant,
        productXyz: product,
        referenceEa: 25.0,
        settings: const QuantumSettings(solventModel: 'PCM (Hexane)'),
      );

      final runThf = TransformerReactionCompressor.process(
        reactantXyz: reactant,
        productXyz: product,
        referenceEa: 25.0,
        settings: const QuantumSettings(solventModel: 'PCM (THF)'),
      );

      final runEtoh = TransformerReactionCompressor.process(
        reactantXyz: reactant,
        productXyz: product,
        referenceEa: 25.0,
        settings: const QuantumSettings(solventModel: 'PCM (EtOH)'),
      );

      final runWater = TransformerReactionCompressor.process(
        reactantXyz: reactant,
        productXyz: product,
        referenceEa: 25.0,
        settings: const QuantumSettings(solventModel: 'PCM (H₂O)'),
      );

      final runSmdWater = TransformerReactionCompressor.process(
        reactantXyz: reactant,
        productXyz: product,
        referenceEa: 25.0,
        settings: const QuantumSettings(solventModel: 'SMD (H₂O)'),
      );

      // Verify that every solvent step is distinct and properly ordered
      expect(runHexane.activationEnergyKcalMol, lessThan(runVacuum.activationEnergyKcalMol));
      expect(runThf.activationEnergyKcalMol, lessThan(runHexane.activationEnergyKcalMol));
      expect(runEtoh.activationEnergyKcalMol, lessThan(runThf.activationEnergyKcalMol));
      expect(runWater.activationEnergyKcalMol, lessThan(runEtoh.activationEnergyKcalMol));
      expect(runSmdWater.activationEnergyKcalMol, lessThan(runWater.activationEnergyKcalMol));
    });
  });

  group('computeResultsSummary Solvent Differential Tests', () {
    final mockProfile = [0.0, 5.0, 15.0, 24.0, 18.0, 2.0];

    test('switching solvents modulates Gibbs free energy, entropy, and polarizability', () {
      final summaryVac = computeResultsSummary(
        settings: const QuantumSettings(solventModel: 'Vacuum'),
        energyProfile: mockProfile,
        isRealData: false,
      );

      final summaryHexane = computeResultsSummary(
        settings: const QuantumSettings(solventModel: 'PCM (Hexane)'),
        energyProfile: mockProfile,
        isRealData: false,
      );

      final summaryWater = computeResultsSummary(
        settings: const QuantumSettings(solventModel: 'PCM (H₂O)'),
        energyProfile: mockProfile,
        isRealData: false,
      );

      // Enthalpy / Barrier decreases with increasing dielectric constant
      expect(
        summaryHexane.byLabel('Activation Energy (Ea)').value,
        lessThan(summaryVac.byLabel('Activation Energy (Ea)').value),
      );
      expect(
        summaryWater.byLabel('Activation Energy (Ea)').value,
        lessThan(summaryHexane.byLabel('Activation Energy (Ea)').value),
      );

      // Polarizability increases with polar solvent continuum
      expect(
        summaryHexane.byLabel('Polarizability (α)').value,
        greaterThan(summaryVac.byLabel('Polarizability (α)').value),
      );
      expect(
        summaryWater.byLabel('Polarizability (α)').value,
        greaterThan(summaryHexane.byLabel('Polarizability (α)').value),
      );

      // Entropy increases in solvated continuum
      expect(
        summaryHexane.byLabel('Entropy (ΔS‡)').value,
        greaterThan(summaryVac.byLabel('Entropy (ΔS‡)').value),
      );
      expect(
        summaryWater.byLabel('Entropy (ΔS‡)').value,
        greaterThan(summaryHexane.byLabel('Entropy (ΔS‡)').value),
      );
    });
  });

  group('ReactionWorkspaceViewModel Solvation Actions Tests', () {
    test('setSolvationModel updates solvationModel and recalculates kinetics', () {
      final vm = ReactionWorkspaceViewModel();
      expect(vm.solvationModel, 'Vacuum');
      final initialEa = vm.activationEnergyEa;

      vm.setSolvationModel('PCM (H₂O)');
      expect(vm.solvationModel, 'PCM (H₂O)');
      expect(vm.activationEnergyEa, lessThan(initialEa));
      expect(vm.activationEnergyEa, closeTo(26.0 * 0.92, 0.01));

      vm.setSolvationModel('PCM (Hexane)');
      expect(vm.solvationModel, 'PCM (Hexane)');
      expect(vm.activationEnergyEa, greaterThan(26.0 * 0.92));
      expect(vm.activationEnergyEa, lessThan(initialEa));
    });
  });
}
