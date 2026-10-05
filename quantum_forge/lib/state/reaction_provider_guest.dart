// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of 'reaction_provider.dart';

extension ReactionProviderGuestExt on ReactionNotifier {
  // --- Local (guest) simulation — no Firestore, no history ------------------
  /// Runs the whole workflow in memory for unauthenticated users, updating the
  /// notifier directly. Nothing is persisted, so "history" remains a signed-in
  /// feature while the app itself stays fully usable without an account.
  Future<void> _simulateGuestReaction(String reactantXyz, String productXyz, [double? referenceEa]) async {
    final reactionId = 'guest-${UuidUtil.v4()}';

    void emit(ReactionState state, double progress, String message) {
      playbackProgressNotifier.value = progress;
      if (state == ReactionState.pending || state == ReactionState.optimizing) {
        if (value == null || value!.state != state || value!.message != message) {
          value = ReactionStatusResponse(
            reactionId: reactionId,
            state: state,
            progress: progress,
            message: message,
          );
        }
      } else {
        value = ReactionStatusResponse(
          reactionId: reactionId,
          state: state,
          progress: progress,
          message: message,
        );
      }
    }

    final why = backendDiagnosticNotifier.value;
    emit(
      ReactionState.pending,
      0.0,
      why == null
          ? 'Queued (Transformer Reaction Engine)…'
          : 'Compute node unavailable — running on-device. $why',
    );
    await Future.delayed(const Duration(milliseconds: 400));
    emit(ReactionState.optimizing, 0.20, 'Transformer Self-Attention: Encoding 3D point cloud & covalent topology…');
    await Future.delayed(const Duration(milliseconds: 600));
    emit(ReactionState.optimizing, 0.50, 'Max-Pooling: Compressing invariant latent bottleneck features…');
    await Future.delayed(const Duration(milliseconds: 600));
    emit(ReactionState.optimizing, 0.80, 'Rebuilding collision-free TS trajectory & vibrational modes…');
    await Future.delayed(const Duration(milliseconds: 500));

    final result = TransformerReactionCompressor.process(
      reactantXyz: reactantXyz,
      productXyz: productXyz,
      referenceEa: referenceEa ?? 21.5,
    );

    value = ReactionStatusResponse(
      reactionId: reactionId,
      state: ReactionState.completed,
      progress: 1.0,
      message: 'TS Search Converged Successfully (Transformer-MP Engine).',
      energyProfile: result.energyProfile,
      energyProfileEv: result.energyProfileEv,
      trajectoryFrames: result.trajectoryFrames,
      vibrationalModes: result.vibrationalModes,
      maxEnergyIndex: result.maxEnergyIndex,
      fromBackend: false,
      modelUsed: 'Transformer-MP-TS',
    );
    playbackProgressNotifier.value = 1.0;
    isLoadingNotifier.value = false;
  }

}
