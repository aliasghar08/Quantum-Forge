// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of 'reaction_provider.dart';

extension ReactionProviderSimulationExt on ReactionNotifier {
  // --- Simulation logic for testing UI without backend ---
  Future<void> _simulateReactionProcessing(
    String reactionId,
    String reactantXyz,
    String productXyz, [
    double? referenceEa,
  ]) async {
    // 1. Pending -> Optimizing
    await Future.delayed(const Duration(milliseconds: 400));
    await _repo.updateReaction(reactionId, {
      'state': ReactionState.optimizing.name,
      'message': 'Transformer Attention: Encoding 3D point cloud & covalent topology…',
      'progress': 0.20,
    });

    await Future.delayed(const Duration(milliseconds: 600));
    await _repo.updateReaction(reactionId, {
      'message': 'Max-Pooling: Compressing invariant latent bottleneck features…',
      'progress': 0.55,
    });

    await Future.delayed(const Duration(milliseconds: 600));
    await _repo.updateReaction(reactionId, {
      'message': 'Rebuilding collision-free TS trajectory & vibrational modes…',
      'progress': 0.85,
    });

    final result = TransformerReactionCompressor.process(
      reactantXyz: reactantXyz,
      productXyz: productXyz,
      referenceEa: referenceEa ?? 21.5,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    await _repo.updateReaction(reactionId, {
      'state': ReactionState.completed.name,
      'message': 'TS Search Converged Successfully (Transformer-MP Engine).',
      'progress': 1.0,
      'energy_profile': result.energyProfile,
      'energy_profile_ev': result.energyProfileEv,
      'trajectory_frames': result.trajectoryFrames,
      'max_energy_index': result.maxEnergyIndex,
      'model_used': 'Transformer-MP-TS',
    });
  }
}
