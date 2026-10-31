import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quantum_forge/core/utils/uuid_util.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';
import 'package:quantum_forge/state/dashboard_viewmodel.dart';
import 'package:quantum_forge/state/settings_provider.dart';

class SharedReactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the base URL for generating public shareable links.
  static String get baseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.contains('localhost:0')) {
        return origin;
      }
    }
    return 'https://quantom-forge.web.app';
  }

  /// Generates a public shareable URL for a reaction template.
  static String getTemplateShareUrl(String templateId) {
    return '$baseUrl/?reaction=$templateId';
  }

  /// Generates a public shareable URL for a stored share ID.
  static String getShareUrl(String shareId) {
    return '$baseUrl/?share=$shareId';
  }

  /// Generates a public shareable URL for a publication details view.
  static String getPublicationShareUrl(String templateId) {
    return '$baseUrl/?publication=$templateId';
  }

  /// Creates a public snapshot of the reaction currently loaded or performed.
  /// Anyone with the returned public URL can view the reaction and its trajectory
  /// completely free of authentication.
  static Future<String> createPublicShare({
    required String reactionName,
    String? templateId,
    double? referenceEa,
    required List<MoleculeEntry> reactants,
    required List<MoleculeEntry> products,
    required List<MoleculeEntry> catalysts,
    QuantumSettings? settings,
    ReactionStatusResponse? status,
  }) async {
    // Generate a clean 12-char unique identifier
    final shareId = UuidUtil.v4().replaceAll('-', '').substring(0, 12);

    final reactantsData = reactants
        .where((e) => e.resolved)
        .map((e) => {
              'name': e.displayName,
              'xyz': e.file?.bytes != null ? utf8.decode(e.file!.bytes!) : '',
            })
        .toList();

    final productsData = products
        .where((e) => e.resolved)
        .map((e) => {
              'name': e.displayName,
              'xyz': e.file?.bytes != null ? utf8.decode(e.file!.bytes!) : '',
            })
        .toList();

    final catalystsData = catalysts
        .where((e) => e.resolved)
        .map((e) => {
              'name': e.displayName,
              'xyz': e.file?.bytes != null ? utf8.decode(e.file!.bytes!) : '',
            })
        .toList();

    Map<String, dynamic>? settingsMap;
    if (settings != null) {
      settingsMap = {
        'mlip_model': settings.mlipModel,
        'temperature_k': settings.temperatureK,
        'solvent_model': settings.solventModel,
        'charge': settings.charge,
        'spin_multiplicity': settings.spinMultiplicity,
        'optimizer_algorithm': settings.optimizerAlgorithm,
      };
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final authorId = currentUser?.uid ?? 'anonymous';

    final data = <String, dynamic>{
      'id': shareId,
      'reaction_name': reactionName,
      'title': reactionName,
      'template_id': ?templateId,
      'reference_ea': ?referenceEa,
      'reactants': reactantsData,
      'products': productsData,
      'catalysts': catalystsData,
      'reactantXyz': reactantsData.isNotEmpty
          ? reactantsData.map((e) => e['xyz'] as String).join('\n')
          : '',
      'productXyz': productsData.isNotEmpty
          ? productsData.map((e) => e['xyz'] as String).join('\n')
          : '',
      'settings': ?settingsMap,
      'status': ?status?.toJson(),
      'created_at': FieldValue.serverTimestamp(),
      'created_by': authorId,
      'authorId': authorId,
    };

    await _firestore.collection('shared_reactions').doc(shareId).set(data);

    return getShareUrl(shareId);
  }

  /// Retrieves a public shared reaction snapshot by its share ID.
  /// Free of authentication (public read enabled in Firestore rules).
  static Future<Map<String, dynamic>?> getSharedReaction(String shareId) async {
    try {
      final doc = await _firestore.collection('shared_reactions').doc(shareId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('[SharedReactionService] Error retrieving shared reaction $shareId: $e');
      return null;
    }
  }
}
