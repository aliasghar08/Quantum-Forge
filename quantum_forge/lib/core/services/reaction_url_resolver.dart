// ============================================================================
// Reaction URL Resolver & Deep-Link Synchronization Service
// ----------------------------------------------------------------------------
// Maps reaction templates to human-readable, SEO-friendly URL slugs (e.g.
// /reaction/aspirin-synthesis) and resolves incoming slugs/document IDs back
// to ReactionTemplate objects across local catalogs and Firestore.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/medical_reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/polymer_reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/veterinary_reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/firestore_library_repository.dart';

class ReactionUrlResolver {
  const ReactionUrlResolver._();

  static const String canonicalBaseUrl = 'https://quantumforgeapp.com';

  /// Generates a clean URL-safe slug from a reaction name or identifier.
  static String toSlug(String input) => ReactionTemplate.toSlug(input);

  /// Generates the canonical public shareable URL for a reaction.
  static String getShareUrl(ReactionTemplate template) {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.contains('localhost:0')) {
        return '$origin/reaction/${template.slug}';
      }
    }
    return '$canonicalBaseUrl/reaction/${template.slug}';
  }

  /// Generates the relative path for browser URL synchronization.
  static String getPath(ReactionTemplate template) {
    return '/reaction/${template.slug}';
  }

  /// Synchronously attempts to find a matching template in local curated bundles.
  static ReactionTemplate? findLocal(String slugOrId) {
    final clean = toSlug(slugOrId);
    final rawLower = slugOrId.toLowerCase().trim();

    final allLocal = <ReactionTemplate>[
      ...kMedicalReactionTemplates,
      ...kReactionTemplates,
      ...kPolymerReactionTemplates,
      ...kVeterinaryReactionTemplates,
    ];

    // 1. Exact match on ID, slug, or normalized name
    for (final t in allLocal) {
      if (t.id.toLowerCase() == rawLower ||
          t.slug == clean ||
          toSlug(t.id) == clean ||
          toSlug(t.name) == clean) {
        return t;
      }
    }

    // 2. Fallback prefix or partial match (e.g. 'aspirin' matches 'aspirin-synthesis')
    for (final t in allLocal) {
      if (t.slug.startsWith(clean) ||
          t.id.toLowerCase().startsWith(rawLower) ||
          clean.startsWith(t.slug)) {
        return t;
      }
    }

    return null;
  }

  /// Resolves a template by slug or document ID from local bundles first,
  /// then queries Firestore if not found.
  static Future<ReactionTemplate?> resolve(String slugOrId) async {
    // Check local memory sets first for instantaneous, zero-latency load
    final local = findLocal(slugOrId);
    if (local != null) return local;

    // Check remote Firestore library collection
    try {
      final repo = FirestoreLibraryRepository();
      final remote = await repo.getTemplateBySlugOrId(slugOrId);
      if (remote != null) return remote;
    } catch (e) {
      debugPrint('ReactionUrlResolver remote resolution error: $e');
    }

    return null;
  }
}
