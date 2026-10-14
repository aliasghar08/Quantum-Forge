// ============================================================================
// ReactionRepository — Abstract interface for reaction CRUD + real-time streaming
//
// Both LocalReactionRepository (JSON files) and FirebaseReactionRepository (Firestore)
// implement this interface. The app only depends on ReactionRepository.
// ============================================================================

import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';

abstract class ReactionRepository {
  /// Create a new reaction document and return its ID.
  Future<String> createReaction(Map<String, dynamic> reactionData);

  /// Stream real-time updates for a specific reaction.
  Stream<ReactionStatusResponse> watchReaction(String reactionId);

  /// Fetch a snapshot of a reaction by ID.
  Future<ReactionStatusResponse?> getReaction(String reactionId);

  /// Find a completed reaction with the exact template ID and settings.
  Future<ReactionStatusResponse?> findCachedTemplateReaction(
    String templateId,
    Map<String, dynamic> settingsMap,
  );

  /// Update fields on an existing reaction document.
  Future<void> updateReaction(String reactionId, Map<String, dynamic> fields);

  /// List all reactions for a user, ordered newest-first.
  Future<List<ReactionStatusResponse>> listReactions(String userId);

  /// Permanently delete a reaction record.
  Future<void> deleteReaction(String reactionId);

  /// Save a completed reaction record directly to the user's history in the repository.
  Future<void> saveCompletedReaction(ReactionStatusResponse response, [String? userId]);

  /// Get the total count of reactions in Firestore root library for a category (or all if omitted).
  Future<int> getCategoryTotalCount([String? categoryName]);
}