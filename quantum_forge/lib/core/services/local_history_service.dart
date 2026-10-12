// ============================================================================
// LocalHistoryService — Local persistence for reaction runs
// ----------------------------------------------------------------------------
// Stores past reaction runs in browser localStorage (via AppStorage) so that
// history works reliably for both guest researchers and authenticated users,
// even offline or before cloud sync completes.
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:quantum_forge/core/services/app_storage.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';

class LocalHistoryService {
  LocalHistoryService._();

  static const String _storageKey = 'quantum_forge_reaction_history_v1';
  static const int _maxItems = 60;

  /// Loads all locally cached reactions, newest first.
  static List<ReactionStatusResponse> loadHistory() {
    try {
      final raw = AppStorage.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final list = <ReactionStatusResponse>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            list.add(ReactionStatusResponse.fromJson(item));
          } catch (e) {
            debugPrint('[LocalHistoryService] Skipped corrupted entry: $e');
          }
        } else if (item is Map) {
          try {
            list.add(ReactionStatusResponse.fromJson(Map<String, dynamic>.from(item)));
          } catch (e) {
            debugPrint('[LocalHistoryService] Skipped corrupted entry: $e');
          }
        }
      }

      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return list;
    } catch (e) {
      debugPrint('[LocalHistoryService] Error loading local history: $e');
      return [];
    }
  }

  /// Saves or updates a reaction in the local history.
  static void saveReaction(ReactionStatusResponse response) {
    if (response.reactionId.isEmpty) return;
    try {
      final current = loadHistory();
      // Remove any existing copy with the same ID
      current.removeWhere((r) => r.reactionId == response.reactionId);

      // Ensure createdAt is populated
      final reactionToSave = response.createdAt == null
          ? ReactionStatusResponse(
              reactionId: response.reactionId,
              state: response.state,
              progress: response.progress,
              message: response.message,
              error: response.error,
              energyProfile: response.energyProfile,
              energyProfileEv: response.energyProfileEv,
              trajectoryFrames: response.trajectoryFrames,
              vibrationalModes: response.vibrationalModes,
              maxEnergyIndex: response.maxEnergyIndex,
              createdAt: DateTime.now(),
              dftAttachments: response.dftAttachments,
              fromBackend: response.fromBackend,
              modelUsed: response.modelUsed,
            )
          : response;

      current.insert(0, reactionToSave);

      if (current.length > _maxItems) {
        current.removeRange(_maxItems, current.length);
      }

      final jsonList = current.map((r) => r.toJson()).toList();
      AppStorage.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[LocalHistoryService] Error saving reaction: $e');
    }
  }

  /// Removes a reaction from local history by its ID.
  static void deleteReaction(String reactionId) {
    try {
      final current = loadHistory();
      current.removeWhere((r) => r.reactionId == reactionId);
      final jsonList = current.map((r) => r.toJson()).toList();
      AppStorage.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[LocalHistoryService] Error deleting reaction: $e');
    }
  }

  /// Clears the entire local history.
  static void clearAll() {
    try {
      AppStorage.remove(_storageKey);
    } catch (e) {
      debugPrint('[LocalHistoryService] Error clearing history: $e');
    }
  }
}
