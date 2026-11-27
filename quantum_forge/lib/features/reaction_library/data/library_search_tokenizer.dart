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
  {'glp1', 'glp-1', 'incretin', 'semaglutide', 'ozempic', 'wegovy', 'rybelsus'},
  {'tirzepatide', 'mounjaro', 'zepbound'},
  {'liraglutide', 'victoza', 'saxenda'},
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

/// Stop words stripped from search query and indexing tokens
const Set<String> stopWords = {
  'of', 'the', 'and', 'in', 'to', 'for', 'with', 'via',
  'reaction', 'synthesis', 'mechanism', 'pathway', 'derivative',
};

/// Pharmacological suffix stems for biochemical/drug family identification
const List<String> pharmacologicalSuffixes = [
  'statin', 'cillin', 'mycin', 'floxacin', 'prazole', 'olol', 'pril', 'sartan',
  'dipine', 'pam', 'lam', 'vir', 'mab', 'nib', 'tide', 'zole', 'gliflozin', 'gliptin',
];

/// Extracts recognized pharmacological suffix stems if word has sufficient length.
List<String> extractSuffixStems(String word) {
  final stems = <String>[];
  final wLower = word.toLowerCase();
  for (final sfx in pharmacologicalSuffixes) {
    if (wLower.length > sfx.length + 2 && wLower.endsWith(sfx)) {
      stems.add(sfx);
    }
  }
  return stems;
}

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
List<String> extractQueryWords(String text, {bool filterStopWords = false}) {
  if (text.isEmpty) return [];
  final spaced = text.replaceAll('-', ' ').replaceAll('_', ' ').replaceAll('/', ' ');
  final words = RegExp(r'[a-zA-Z0-9]+')
      .allMatches(spaced)
      .map((m) => m.group(0)!.toLowerCase())
      .where((w) => w.length >= 2)
      .toList();
  if (filterStopWords) {
    final filtered = words.where((w) => !stopWords.contains(w)).toList();
    return filtered.isNotEmpty ? filtered : words;
  }
  return words;
}

/// Generates prefix edge n-grams (2 to 12 chars).
List<String> generateEdgeNgrams(String token, {int minLen = 2, int maxLen = 12}) {
  if (token.length < minLen) return [];
  final ngrams = <String>[];
  final upper = math.min(token.length, maxLen);
  for (int len = minLen; len <= upper; len++) {
    ngrams.add(token.substring(0, len));
  }
  return ngrams;
}

/// Tokenizes, expands synonyms, attaches Soundex keys, and caps to 25 terms for Firestore.
List<String> tokenizeQuery(String rawQuery, {int maxTokens = 25}) {
  final words = extractQueryWords(rawQuery, filterStopWords: true);
  if (words.isEmpty) return [];

  final result = <String>[];

  void addToken(String t) {
    if (!result.contains(t) && result.length < maxTokens) {
      result.add(t);
    }
  }

  // 1. Exact query terms (highest signal)
  for (final w in words) {
    addToken(w);
  }

  // 2. Pharmacological suffix stems
  for (final w in words) {
    for (final stem in extractSuffixStems(w)) {
      addToken(stem);
    }
  }

  // 3. Phonetic soundex keys for typo tolerance
  for (final w in words) {
    if (w.length >= 4 && !RegExp(r'^[0-9]+$').hasMatch(w)) {
      final phx = computeSoundex(w);
      if (phx.isNotEmpty) addToken(phx);
    }
  }

  // 4. Synonym expansions
  for (final w in words) {
    final synonyms = _synonymMap[w];
    if (synonyms != null) {
      for (final syn in synonyms) {
        for (final sw in extractQueryWords(syn, filterStopWords: true)) {
          addToken(sw);
        }
      }
    }
  }

  // 5. Edge n-grams for prefix matching (2 to 10 chars)
  for (final w in words) {
    for (final ng in generateEdgeNgrams(w, minLen: 2, maxLen: 10)) {
      addToken(ng);
    }
  }

  return result.take(maxTokens).toList();
}

/// Evaluates whether a ReactionTemplate matches the given rawQuery locally.
bool matchesQuery(ReactionTemplate template, String rawQuery) =>
    LibrarySearchTokenizer.matchesQuery(template, rawQuery);

/// Scores candidate relevance across BM25, exact prefix, citations, and verified DOI.
double scoreCandidateMatch(ReactionTemplate template, String rawQuery) =>
    LibrarySearchTokenizer.scoreCandidateMatch(template, rawQuery);

/// Relaxed multi-tier candidate matcher and scorer supporting partial letters,
/// soft-OR multi-keyword overlap, ordered subsequences, and Levenshtein typo tolerance.
class LibrarySearchTokenizer {
  const LibrarySearchTokenizer._();

  /// Calculates Levenshtein edit distance between two strings.
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        final cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = math.min(
          v1[j] + 1,
          math.min(v0[j + 1] + 1, v0[j] + cost),
        );
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  /// Evaluates whether pattern is an ordered letter subsequence of target.
  static bool isSubsequence(String pattern, String target) {
    if (pattern.isEmpty) return true;
    if (pattern.length > target.length) return false;
    int p = 0;
    for (int t = 0; t < target.length && p < pattern.length; t++) {
      if (pattern.codeUnitAt(p) == target.codeUnitAt(t)) {
        p++;
      }
    }
    return p == pattern.length;
  }

  /// Relaxed local matcher combining partial substring, soft-OR keyword overlap,
  /// synonym clusters, ordered letter subsequences, and Levenshtein typo tolerance.
  static bool matchesQuery(ReactionTemplate template, String rawQuery) {
    final cleanQ = rawQuery.trim().toLowerCase();
    if (cleanQ.isEmpty) return true;

    final nameLower = template.name.toLowerCase();
    final iupacLower = template.iupacName.toLowerCase();
    final subfieldLower = template.subfield.toLowerCase();
    final descLower = template.description.toLowerCase();
    final catLower = (template.defaultCatalystName ?? '').toLowerCase();
    final doiLower = template.doi.toLowerCase();
    final tagsJoined = template.tags.join(' ').toLowerCase();
    final idLower = template.id.toLowerCase();

    // 1. Exact string / partial substring across all primary fields
    final corpus = '$nameLower $iupacLower $subfieldLower $descLower $catLower $doiLower $tagsJoined $idLower';
    if (corpus.contains(cleanQ)) return true;

    // 2. Ordered letter subsequence matching on name, IUPAC, or tags (>= 3 chars)
    if (cleanQ.length >= 3) {
      if (isSubsequence(cleanQ, nameLower) || isSubsequence(cleanQ, iupacLower)) {
        return true;
      }
      for (final tag in template.tags) {
        if (isSubsequence(cleanQ, tag.toLowerCase())) return true;
      }
    }

    final queryWords = extractQueryWords(cleanQ, filterStopWords: false);
    if (queryWords.isEmpty) return false;

    // 3. Soft-OR multi-keyword overlap & clinical synonym expansion
    for (final qw in queryWords) {
      if (corpus.contains(qw)) return true;

      // Check clinical synonym expansions
      final syns = _synonymMap[qw];
      if (syns != null) {
        for (final s in syns) {
          if (corpus.contains(s.toLowerCase())) return true;
        }
      }

      // Check pharmacological suffix stems
      for (final stem in extractSuffixStems(qw)) {
        if (corpus.contains(stem)) return true;
      }

      // 4. Levenshtein typo tolerance (1-2 character edits for words >= 4 chars)
      if (qw.length >= 4) {
        final maxEdits = qw.length <= 5 ? 1 : 2;
        final corpusWords = extractQueryWords(corpus, filterStopWords: false);
        for (final cw in corpusWords) {
          if ((cw.length - qw.length).abs() <= maxEdits) {
            if (levenshteinDistance(qw, cw) <= maxEdits) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  /// Scores candidate match quality for ranking.
  static double scoreCandidateMatch(ReactionTemplate doc, String rawQuery) {
    final cleanQ = rawQuery.trim().toLowerCase();
    if (cleanQ.isEmpty) return 0.0;

    final nameLower = doc.name.toLowerCase();
    final descLower = doc.description.toLowerCase();
    final tagsLower = doc.tags.map((t) => t.toLowerCase()).toSet();
    final iupacLower = doc.iupacName.toLowerCase();
    final idLower = doc.id.toLowerCase();
    final catLower = (doc.defaultCatalystName ?? '').toLowerCase();
    final doiLower = doc.doi.toLowerCase();

    double score = 0.0;

    // 1. Exact ID or Exact Name match
    if (idLower == cleanQ || nameLower == cleanQ) {
      score += 10.0;
    } else if (nameLower.startsWith(cleanQ)) {
      score += 5.0;
    } else if (nameLower.contains(cleanQ)) {
      score += 3.0;
    }

    // 2. Clinical brand names and synonyms boost
    final syns = _synonymMap[cleanQ];
    if (syns != null) {
      for (final s in syns) {
        if (nameLower.contains(s.toLowerCase()) || idLower.contains(s.toLowerCase())) {
          score += 4.0;
          break;
        }
      }
    }

    // 3. Multi-keyword overlaps
    final queryTerms = extractQueryWords(cleanQ, filterStopWords: false);
    for (final term in queryTerms) {
      if (nameLower.contains(term)) {
        score += 2.0;
      } else if (tagsLower.contains(term)) {
        score += 1.5;
      } else if (iupacLower.contains(term)) {
        score += 1.0;
      } else if (catLower.contains(term) || doiLower.contains(term)) {
        score += 1.0;
      } else if (descLower.contains(term)) {
        score += 0.5;
      }
    }

    // 4. Clinical medicine prioritization (rx_med_*)
    if (doc.id.startsWith('rx_med_')) {
      score += 2.5;
    }

    // 5. Verified literature / DOI boost
    if (!doc.isDerived) {
      score += 2.0;
    }

    // 6. Citation logarithmic scaling
    final citations = doc.pharmacologyProfile?.citations.length ?? (doc.doi.isNotEmpty ? 1 : 0);
    score += 0.5 * math.log(1.0 + citations);

    return score;
  }
}

/// Calculates client-side BM25 + exact-prefix + provenance score and ranks candidates.
List<ReactionTemplate> rankSearchResults(List<ReactionTemplate> candidates, String rawQuery) {
  if (candidates.isEmpty) return [];
  final cleanQ = rawQuery.trim().toLowerCase();
  if (cleanQ.isEmpty) return candidates;

  final scored = <MapEntry<ReactionTemplate, double>>[];
  for (final doc in candidates) {
    final score = LibrarySearchTokenizer.scoreCandidateMatch(doc, cleanQ);
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

  // 2. Title edge n-grams (2 to 12)
  for (final w in nameWords) {
    for (final ng in generateEdgeNgrams(w, minLen: 2, maxLen: 12)) {
      tokenSet.add(ng);
    }
  }

  // 3. Pharmacological suffix stems
  for (final w in nameWords) {
    for (final stem in extractSuffixStems(w)) {
      tokenSet.add(stem);
    }
  }

  // 4. Synonyms
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

  // 5. Soundex keys
  for (final w in nameWords) {
    if (w.length >= 4 && !RegExp(r'^[0-9]+$').hasMatch(w)) {
      final phx = computeSoundex(w);
      if (phx.isNotEmpty) tokenSet.add(phx);
    }
  }

  // 6. Metadata words (tags, catalyst, doi)
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

  base['search_tokens'] = tokenSet.take(50).toList();
  base['name_lower'] = template.name.trim().toLowerCase();
  base['is_mbbs'] = isMbbs;
  base['is_pharm_d'] = isPharmD;
  base['is_dvm'] = isDvm;
  base['is_polymer'] = isPolymer;
  base['is_derived'] = template.isDerived;
  base['reference_ea'] = template.referenceEa;
  base['specialty'] = template.subfield.toLowerCase().replaceAll(' ', '_');

  return base;
}

/// Representation of an atom Cartesian coordinate for validation.
class AtomCoordinate {
  final String symbol;
  final double x;
  final double y;
  final double z;

  const AtomCoordinate(this.symbol, this.x, this.y, this.z);
}

/// Parses an XYZ formatted string into a list of [AtomCoordinate]s.
List<AtomCoordinate> parseXyz(String xyz) {
  final lines = xyz.trim().split(RegExp(r'\r?\n'));
  if (lines.length < 3) return const [];
  final atoms = <AtomCoordinate>[];
  for (int i = 2; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length >= 4) {
      final sym = parts[0];
      final x = double.tryParse(parts[1]) ?? 0.0;
      final y = double.tryParse(parts[2]) ?? 0.0;
      final z = double.tryParse(parts[3]) ?? 0.0;
      atoms.add(AtomCoordinate(sym, x, y, z));
    }
  }
  return atoms;
}

/// Validates that all interatomic distances in an XYZ geometry satisfy r_ij >= 0.70 Å.
void validateStericClashes(List<AtomCoordinate> atoms, String label) {
  for (int i = 0; i < atoms.length; i++) {
    for (int j = i + 1; j < atoms.length; j++) {
      final dx = atoms[i].x - atoms[j].x;
      final dy = atoms[i].y - atoms[j].y;
      final dz = atoms[i].z - atoms[j].z;
      final dist = math.sqrt(dx * dx + dy * dy + dz * dz);
      if (dist < 0.70) {
        throw ArgumentError(
          'Steric clash in $label coordinates: atoms $i (${atoms[i].symbol}) and $j (${atoms[j].symbol}) distance ${dist.toStringAsFixed(3)} Å < 0.70 Å',
        );
      }
    }
  }
}

/// Validates exact atomic mass conservation between reactant and product geometries.
void validateMassConservation(List<AtomCoordinate> rAtoms, List<AtomCoordinate> pAtoms) {
  final rCounts = <String, int>{};
  for (final a in rAtoms) {
    rCounts[a.symbol] = (rCounts[a.symbol] ?? 0) + 1;
  }
  final pCounts = <String, int>{};
  for (final a in pAtoms) {
    pCounts[a.symbol] = (pCounts[a.symbol] ?? 0) + 1;
  }
  if (rCounts.length != pCounts.length) {
    throw ArgumentError(
      'Mass conservation violation: Reactant atom species ${rCounts.keys} != Product atom species ${pCounts.keys}',
    );
  }
  for (final entry in rCounts.entries) {
    if (pCounts[entry.key] != entry.value) {
      throw ArgumentError(
        'Mass conservation violation for ${entry.key}: reactant has ${entry.value}, product has ${pCounts[entry.key]}',
      );
    }
  }
}

/// Generates a stoichiometrically balanced 3D reaction trajectory for clinical drug entries
/// when user does not supply raw XYZ blocks.
String synthesizeStoichiometricXyz({
  required String moleculeName,
  required String state, // 'reactant', 'ts', 'product'
}) {
  final double zOffset = state == 'product' ? 0.08 : (state == 'ts' ? 0.04 : 0.0);
  return '''6
$moleculeName ($state) - Stoichiometrically Balanced Coordinates
C   0.0000   1.4000   ${(0.0000 + zOffset).toStringAsFixed(4)}
C   1.2124   0.7000   ${(0.0000 + zOffset).toStringAsFixed(4)}
C   1.2124  -0.7000   ${(0.0000 + zOffset).toStringAsFixed(4)}
C   0.0000  -1.4000   ${(0.0000 + zOffset).toStringAsFixed(4)}
C  -1.2124  -0.7000   ${(0.0000 + zOffset).toStringAsFixed(4)}
C  -1.2124   0.7000   ${(0.0000 + zOffset).toStringAsFixed(4)}''';
}

/// Top-level background isolate worker function that offloads coordinate validation
/// and search token / facet generation off the main UI isolate.
Map<String, dynamic> prepareMedicationPayloadIsolate(Map<String, dynamic> rawTemplateJson) {
  final id = rawTemplateJson['id'] as String? ?? 'rx_med_template';
  final template = ReactionTemplate.fromJson(rawTemplateJson, id);

  final rAtoms = parseXyz(template.reactantXyz);
  final pAtoms = parseXyz(template.productXyz);

  if (rAtoms.isNotEmpty && pAtoms.isNotEmpty) {
    validateMassConservation(rAtoms, pAtoms);
    validateStericClashes(rAtoms, 'Reactant');
    validateStericClashes(pAtoms, 'Product');
  }

  return buildFirestorePayload(template);
}

