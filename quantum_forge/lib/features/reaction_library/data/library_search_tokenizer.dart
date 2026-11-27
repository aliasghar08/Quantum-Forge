import 'dart:math' as math;
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

/// Clinical and chemical synonym clusters
final List<Set<String>> _synonymGroups = [
  {'paracetamol', 'acetaminophen', 'apap', 'tylenol', 'panadol'},
  {'adrenaline', 'epinephrine'},
  {'noradrenaline', 'norepinephrine'},
  {'salbutamol', 'albuterol', 'ventolin'},
  {'frusemide', 'furosemide', 'lasix'},
  {'lidocaine', 'lignocaine', 'xylocaine'},
  {'quetiapine', 'seroquel'},
  {'omeprazole', 'prilosec', 'losec'},
  {'metformin', 'glucophage'},
  {'atorvastatin', 'lipitor'},
  {'acetylsalicylic', 'aspirin'},
  {'morphine', 'ms contin'},
  {'cyp450', 'cytochrome p450', 'cytochrome'},
  {'cyp3a4', 'cytochrome 3a4'},
  {'cyp2e1', 'cytochrome 2e1'},
  {'cyp2d6', 'cytochrome 2d6'},
  {'ace', 'ace-i', 'ace inhibitor', 'acei'},
  {'arb', 'angiotensin receptor blocker'},
  {'nsaid', 'nonsteroidal anti-inflammatory'},
  {'sglt2', 'sglt2 inhibitor', 'gliflozin'},
  {'glp1', 'glp-1', 'incretin'},
  {'hmg', 'coa', 'hmg-coa', 'hmgcoa', 'statin'},
  {'ivermectin', 'stromectol'},
  {'fenbendazole', 'panacur'},
  {'xylazine', 'rompun'},
];

final Map<String, Set<String>> _synonymMap = () {
  final map = <String, Set<String>>{};
  for (final group in _synonymGroups) {
    for (final item in group) {
      map[item.toLowerCase()] = group;
    }
  }
  return map;
}();

const Map<String, String> _soundexMap = {
  'B': '1', 'F': '1', 'P': '1', 'V': '1',
  'C': '2', 'G': '2', 'J': '2', 'K': '2', 'Q': '2', 'S': '2', 'X': '2', 'Z': '2',
  'D': '3', 'T': '3',
  'L': '4',
  'M': '5', 'N': '5',
  'R': '6'
};

/// Computes standard 4-character American Soundex key prefixed with phx_ (e.g. phx_Q315).
String computeSoundex(String word) {
  final clean = word.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
  if (clean.isEmpty) return '';

  final firstChar = clean[0];
  final digits = <String>[];
  String prevCode = _soundexMap[firstChar] ?? '';

  for (int i = 1; i < clean.length; i++) {
    final char = clean[i];
    final code = _soundexMap[char];
    if (code != null) {
      if (code != prevCode) {
        digits.add(code);
      }
      prevCode = code;
    } else {
      prevCode = '';
    }
  }

  final digitsStr = digits.join();
  final soundexCode = ('$firstChar$digitsStr' '000').substring(0, 4);
  return 'phx_$soundexCode';
}

/// Splits text into lowercase alphanumeric words.
List<String> extractQueryWords(String text) {
  if (text.isEmpty) return [];
  final spaced = text.replaceAll('-', ' ').replaceAll('_', ' ').replaceAll('/', ' ');
  return RegExp(r'[a-zA-Z0-9]+')
      .allMatches(spaced)
      .map((m) => m.group(0)!.toLowerCase())
      .where((w) => w.length >= 2)
      .toList();
}

/// Generates prefix edge n-grams (3 to 7 chars).
List<String> generateEdgeNgrams(String token, {int minLen = 3, int maxLen = 7}) {
  if (token.length < minLen) return [];
  final ngrams = <String>[];
  final upper = math.min(token.length, maxLen);
  for (int len = minLen; len <= upper; len++) {
    ngrams.add(token.substring(0, len));
  }
  return ngrams;
}

/// Tokenizes, expands synonyms, attaches Soundex keys, and caps to 10 terms for Firestore.
List<String> tokenizeQuery(String rawQuery) {
  final words = extractQueryWords(rawQuery);
  if (words.isEmpty) return [];

  final result = <String>[];

  void addToken(String t) {
    if (!result.contains(t) && result.length < 10) {
      result.add(t);
    }
  }

  // 1. Exact query terms (highest signal)
  for (final w in words) {
    addToken(w);
  }

  // 2. Phonetic soundex keys for typo tolerance
  for (final w in words) {
    if (w.length >= 4 && !RegExp(r'^[0-9]+$').hasMatch(w)) {
      final phx = computeSoundex(w);
      if (phx.isNotEmpty) addToken(phx);
    }
  }

  // 3. Synonym expansions
  for (final w in words) {
    final synonyms = _synonymMap[w];
    if (synonyms != null) {
      for (final syn in synonyms) {
        for (final sw in extractQueryWords(syn)) {
          addToken(sw);
        }
      }
    }
  }

  // 4. Edge n-grams for prefix matching
  for (final w in words) {
    for (final ng in generateEdgeNgrams(w, minLen: 3, maxLen: 6)) {
      addToken(ng);
    }
  }

  return result.take(10).toList();
}

/// Calculates client-side BM25 + exact-prefix + provenance score and ranks candidates.
List<ReactionTemplate> rankSearchResults(List<ReactionTemplate> candidates, String rawQuery) {
  if (candidates.isEmpty) return [];
  final cleanQ = rawQuery.trim().toLowerCase();
  final queryTerms = extractQueryWords(cleanQ);
  if (queryTerms.isEmpty) return candidates;

  final scored = <MapEntry<ReactionTemplate, double>>[];

  for (final doc in candidates) {
    final nameLower = doc.name.toLowerCase();
    final descLower = doc.description.toLowerCase();
    final tagsLower = doc.tags.map((t) => t.toLowerCase()).toSet();
    final iupacLower = doc.iupacName.toLowerCase();

    double score = 0.0;

    // Term matches across fields
    for (final term in queryTerms) {
      if (nameLower.contains(term)) {
        score += 2.0;
      } else if (tagsLower.contains(term)) {
        score += 1.5;
      } else if (iupacLower.contains(term)) {
        score += 1.0;
      } else if (descLower.contains(term)) {
        score += 0.5;
      }
    }

    // Exact name prefix boost (+3.0)
    if (nameLower.startsWith(cleanQ)) {
      score += 3.0;
    } else if (nameLower.contains(cleanQ)) {
      score += 1.5;
    }

    // Verified DOI / Peer-reviewed literature boost (+2.0)
    if (!doc.isDerived) {
      score += 2.0;
    }

    // Citation count logarithm boost (+0.5 * ln(1 + citation_count))
    final citations = doc.pharmacologyProfile?.citations.length ?? (doc.doi.isNotEmpty ? 1 : 0);
    score += 0.5 * math.log(1.0 + citations);

    scored.add(MapEntry(doc, score));
  }

  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.map((e) => e.key).toList();
}

/// Builds Firestore payload including search_tokens, name_lower, and curriculum facets.
Map<String, dynamic> buildFirestorePayload(ReactionTemplate template) {
  final base = template.toJson();
  final nameWords = extractQueryWords(template.name);
  final tokenSet = <String>{};

  // 1. Name words
  for (final w in nameWords) {
    tokenSet.add(w);
  }

  // 2. Title edge n-grams
  for (final w in nameWords) {
    for (final ng in generateEdgeNgrams(w, minLen: 3, maxLen: 7)) {
      tokenSet.add(ng);
    }
  }

  // 3. Synonyms
  for (final w in nameWords) {
    final syns = _synonymMap[w];
    if (syns != null) {
      for (final s in syns) {
        for (final sw in extractQueryWords(s)) {
          tokenSet.add(sw);
        }
      }
    }
  }

  // 4. Soundex keys
  for (final w in nameWords) {
    if (w.length >= 4 && !RegExp(r'^[0-9]+$').hasMatch(w)) {
      final phx = computeSoundex(w);
      if (phx.isNotEmpty) tokenSet.add(phx);
    }
  }

  // 5. Metadata words (tags, catalyst, doi)
  for (final tag in template.tags) {
    for (final w in extractQueryWords(tag)) {
      tokenSet.add(w);
    }
  }
  if (template.defaultCatalystName != null && template.defaultCatalystName!.isNotEmpty) {
    for (final w in extractQueryWords(template.defaultCatalystName!)) {
      tokenSet.add(w);
    }
  }
  if (template.doi.isNotEmpty) {
    final cleanDoi = template.doi.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    if (cleanDoi.isNotEmpty) tokenSet.add(cleanDoi);
  }

  final combined = '${template.name} ${template.iupacName} ${template.description} ${template.category.name} ${template.tags.join(" ")}'.toLowerCase();

  final isMbbs = combined.contains('mbbs') ||
      combined.contains('usmle') ||
      template.category == ReactionCategory.pharmaceutical ||
      template.category == ReactionCategory.biochemical ||
      ['cardiology', 'neurology', 'nephrology', 'oncology', 'pathology', 'metabolism'].any(combined.contains);

  final isPharmD = combined.contains('pharm-d') ||
      combined.contains('pharmd') ||
      combined.contains('pharmacology') ||
      template.category == ReactionCategory.pharmaceutical ||
      ['prodrug', 'inhibitor', 'mechanism', 'synthesis', 'pharmacokinetics'].any(combined.contains);

  final isDvm = combined.contains('dvm') ||
      combined.contains('veterinary') ||
      template.category == ReactionCategory.veterinary ||
      ['ivermectin', 'fenbendazole', 'xylazine'].any(combined.contains);

  final isPolymer = template.category == ReactionCategory.polymer || combined.contains('polymer');

  base['search_tokens'] = tokenSet.take(40).toList();
  base['name_lower'] = template.name.trim().toLowerCase();
  base['is_mbbs'] = isMbbs;
  base['is_pharm_d'] = isPharmD;
  base['is_dvm'] = isDvm;
  base['is_polymer'] = isPolymer;
  base['specialty'] = template.subfield.toLowerCase().replaceAll(' ', '_');

  return base;
}
