// ============================================================================
// LocalHistoryService Unit Tests
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/services/app_storage.dart';
import 'package:quantum_forge/core/services/local_history_service.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';

void main() {
  setUp(AppStorage.clear);
  tearDown(AppStorage.clear);

  group('LocalHistoryService', () {
    test('starts empty when no history has been saved', () {
      final history = LocalHistoryService.loadHistory();
      expect(history, isEmpty);
    });

    test('saves and loads a reaction run', () {
      final reaction = ReactionStatusResponse(
        reactionId: 'test-rxn-1',
        state: ReactionState.completed,
        progress: 1.0,
        message: 'Convergence reached',
        energyProfile: [0.0, 15.2, 5.4],
        createdAt: DateTime(2026, 10, 10, 12, 0),
      );

      LocalHistoryService.saveReaction(reaction);

      final loaded = LocalHistoryService.loadHistory();
      expect(loaded.length, 1);
      expect(loaded.first.reactionId, 'test-rxn-1');
      expect(loaded.first.state, ReactionState.completed);
      expect(loaded.first.energyProfile, [0.0, 15.2, 5.4]);
      expect(loaded.first.message, 'Convergence reached');
    });

    test('deduplicates and updates existing reaction by ID', () {
      final r1 = ReactionStatusResponse(
        reactionId: 'test-rxn-dup',
        state: ReactionState.optimizing,
        progress: 0.5,
        message: 'Optimizing...',
        createdAt: DateTime(2026, 10, 10, 12, 0),
      );
      LocalHistoryService.saveReaction(r1);

      final r2 = ReactionStatusResponse(
        reactionId: 'test-rxn-dup',
        state: ReactionState.completed,
        progress: 1.0,
        message: 'Finished',
        createdAt: DateTime(2026, 10, 10, 12, 5),
      );
      LocalHistoryService.saveReaction(r2);

      final loaded = LocalHistoryService.loadHistory();
      expect(loaded.length, 1);
      expect(loaded.first.state, ReactionState.completed);
      expect(loaded.first.message, 'Finished');
    });

    test('sorts newest reactions first', () {
      final oldRxn = ReactionStatusResponse(
        reactionId: 'old-1',
        state: ReactionState.completed,
        progress: 1.0,
        createdAt: DateTime(2026, 1, 1),
      );
      final newRxn = ReactionStatusResponse(
        reactionId: 'new-1',
        state: ReactionState.completed,
        progress: 1.0,
        createdAt: DateTime(2026, 10, 12),
      );

      LocalHistoryService.saveReaction(oldRxn);
      LocalHistoryService.saveReaction(newRxn);

      final loaded = LocalHistoryService.loadHistory();
      expect(loaded.length, 2);
      expect(loaded[0].reactionId, 'new-1');
      expect(loaded[1].reactionId, 'old-1');
    });

    test('deletes reaction by ID', () {
      final r1 = ReactionStatusResponse(
        reactionId: 'rxn-to-delete',
        state: ReactionState.completed,
        progress: 1.0,
      );
      final r2 = ReactionStatusResponse(
        reactionId: 'rxn-keep',
        state: ReactionState.completed,
        progress: 1.0,
      );

      LocalHistoryService.saveReaction(r1);
      LocalHistoryService.saveReaction(r2);

      expect(LocalHistoryService.loadHistory().length, 2);

      LocalHistoryService.deleteReaction('rxn-to-delete');
      final remaining = LocalHistoryService.loadHistory();
      expect(remaining.length, 1);
      expect(remaining.first.reactionId, 'rxn-keep');
    });

    test('clearAll wipes the history completely', () {
      LocalHistoryService.saveReaction(
        ReactionStatusResponse(reactionId: 'r1', state: ReactionState.completed, progress: 1.0),
      );
      LocalHistoryService.saveReaction(
        ReactionStatusResponse(reactionId: 'r2', state: ReactionState.completed, progress: 1.0),
      );

      expect(LocalHistoryService.loadHistory().length, 2);

      LocalHistoryService.clearAll();
      expect(LocalHistoryService.loadHistory(), isEmpty);
    });
  });
}
