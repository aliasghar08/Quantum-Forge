import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Robust service for fetching educational & mechanism YouTube videos
/// for chemical, biochemical, and medical reactions.
///
/// Designed to work seamlessly across Flutter Web, Desktop, and Mobile:
/// 1. Queries YouTube Data API v3 if an API key is configured.
/// 2. Seamlessly falls back to an extensive curated bank of verified
///    medical chemistry, organic synthesis, and pharmacology educational videos
///    (Ninja Nerd, Khan Academy, Organic Chemistry Tutor, AK Lectures, Professor Dave Explains, Leah4sci).
/// 3. Intelligently matches based on template ID, reaction name, IUPAC mechanism, or reaction category.
/// 4. Ensures all important mechanism videos are available on the publication page.
class YouTubeService {
  /// Default YouTube API Key from compile-time environment, if supplied.
  static const String _envApiKey = String.fromEnvironment('YOUTUBE_API_KEY');

  /// Curated educational video database for medical & chemical reactions
  static const List<Map<String, String>> _curatedVideoBank = [
    // --- 1. Aspirin (Acetylsalicylic Acid) ---
    {
      'templateId': 'med-aspirin-01',
      'keywords': 'aspirin acetylsalicylic acid cox-1 cox-2 salicylic nsaid antiplatelet esterification',
      'videoId': 'jr64OxTpknM',
      'title': 'Synthesis of Aspirin & Esterification Mechanism',
      'channel': 'Organic Mechanisms',
      'badge': 'Synthesis Mechanism',
    },
    {
      'templateId': 'med-aspirin-01',
      'keywords': 'aspirin synthesis organic chemistry esterification salicylic',
      'videoId': 'YLpFrcUDitE',
      'title': 'Aspirin Synthesis and Testing',
      'channel': 'Professor Dave Explains',
      'badge': 'Organic Chemistry',
    },
    {
      'templateId': 'med-aspirin-01',
      'keywords': 'aspirin nsaid cox mechanism pharmacology medicine antiplatelet',
      'videoId': 'EqBfua_kQ70',
      'title': 'Fischer Esterification Reaction Mechanism',
      'channel': 'The Organic Chemistry Tutor',
      'badge': 'Esterification',
    },

    // --- 2. Paracetamol (Acetaminophen) ---
    {
      'templateId': 'med-paracetamol-01',
      'keywords': 'paracetamol acetaminophen napqi cyp2e1 toxicity nac liver necrosis glutathione',
      'videoId': 'oJhlRYoniyo',
      'title': 'Synthesis of Paracetamol (Acetaminophen) Mechanism',
      'channel': 'sqadia.com',
      'badge': 'Pharm-D Synthesis',
    },
    {
      'templateId': 'med-paracetamol-01',
      'keywords': 'paracetamol synthesis acylation aminophenol pharm d',
      'videoId': 'Arrz1gmJH0k',
      'title': 'Acetaminophen Mechanism of Action & Metabolism',
      'channel': 'Medmastery',
      'badge': 'Clinical Medicine',
    },
    {
      'templateId': 'med-paracetamol-01',
      'keywords': 'paracetamol overdose antidote nac n-acetylcysteine glutathione',
      'videoId': 'S7E6ne2xBJA',
      'title': 'Paracetamol Preparation and Synthesis',
      'channel': 'ChemTube3D',
      'badge': 'Organic Synthesis',
    },

    // --- 3. Penicillin Beta-Lactam Ring ---
    {
      'templateId': 'med-penicillin-01',
      'keywords': 'penicillin beta-lactam transpeptidase antibiotic cell wall pbp crosslinking',
      'videoId': 'EjI1YQrbXgM',
      'title': 'Beta-Lactam Antibiotics Mechanism of Action & Resistance',
      'channel': 'Elsevier India',
      'badge': 'Microbiology & MBBS',
    },
    {
      'templateId': 'med-penicillin-01',
      'keywords': 'penicillin transpeptidase bacterial cell wall pharmacology',
      'videoId': 'PwjK429wtiE',
      'title': 'Penicillin & Beta-Lactam Mechanism',
      'channel': 'Dr Matt & Dr Mike',
      'badge': 'Pharmacology',
    },
    {
      'templateId': 'med-penicillin-01',
      'keywords': 'penicillin cell wall crosslinking transpeptidase',
      'videoId': 'Rfg7VKfD9cQ',
      'title': 'Cell Wall Inhibitors Mechanism',
      'channel': 'Armando Hasudungan',
      'badge': 'Mechanism of Action',
    },

    // --- 4. Acetylcholine Hydrolysis ---
    {
      'templateId': 'med-acetylcholine-01',
      'keywords': 'acetylcholine ache acetylcholinesterase serine esterase organophosphate neuromuscular',
      'videoId': 'tt3VvfbeJ4E',
      'title': 'Acetylcholinesterase Mechanism & Catalytic Triad',
      'channel': 'Dr Aisyah',
      'badge': 'Enzyme Kinetics',
    },
    {
      'templateId': 'med-acetylcholine-01',
      'keywords': 'cholinergic neurotransmission acetylcholine receptors muscarinic nicotinic',
      'videoId': '8Wluv1kKGUM',
      'title': 'Acetylcholinesterase Inhibitors Mechanism',
      'channel': 'Nonstop Neuron',
      'badge': 'Neuropharmacology',
    },
    {
      'templateId': 'med-acetylcholine-01',
      'keywords': 'organophosphate toxicity ache nerve agent sarin',
      'videoId': 'ptN8-aztpuQ',
      'title': 'Organophosphates and AChE Hydrolysis',
      'channel': 'Speed Pharmacology',
      'badge': 'Toxicology',
    },

    // --- 5. Catecholamines: Dopamine, Norepinephrine, Epinephrine ---
    {
      'templateId': 'med-dopamine-01',
      'keywords': 'dopamine norepinephrine dopamine beta hydroxylase catecholamine parkinson',
      'videoId': 'afzWLmd72Rk',
      'title': 'Catecholamine Biosynthesis: Tyrosine to Epinephrine',
      'channel': 'Ninja Nerd',
      'badge': 'Biochemistry & MBBS',
    },
    {
      'templateId': 'med-epinephrine-01',
      'keywords': 'epinephrine adrenaline pnmt phenylethanolamine n-methyltransferase fight or flight',
      'videoId': 'afzWLmd72Rk',
      'title': 'Catecholamine Biosynthesis: Tyrosine to Epinephrine',
      'channel': 'Ninja Nerd',
      'badge': 'Cardiovascular Pharm',
    },

    // --- 6. ATP Hydrolysis & Bioenergetics ---
    {
      'templateId': 'med-atp-01',
      'keywords': 'atp hydrolysis adenosine triphosphate gamma phosphate kinase free energy delta g',
      'videoId': '-KE7jTXwNYs',
      'title': 'ATP Hydrolysis Mechanism & Free Energy',
      'channel': 'Khan Academy',
      'badge': 'Biochemistry',
    },
    {
      'templateId': 'med-atp-01',
      'keywords': 'atp cellular respiration bioenergetics thermodynamics',
      'videoId': 'QnQe0xW_JY4',
      'title': 'ATP Synthase and Cleavage Bioenergetics',
      'channel': 'HarvardX',
      'badge': 'Cellular Bioenergetics',
    },

    // --- 7. Diels-Alder Cycloaddition ---
    {
      'templateId': 'diels_alder',
      'keywords': 'diels alder pericyclic cycloaddition diene dienophile endo exo concerted suprafacial',
      'videoId': 'sBmoP6KwK-8',
      'title': 'Diels-Alder Reaction Mechanism & Stereochemistry',
      'channel': 'The Organic Chemistry Tutor',
      'badge': 'Pericyclic Masterclass',
    },
    {
      'templateId': 'diels_alder',
      'keywords': 'diels alder diene dienophile frontier molecular orbital fmo',
      'videoId': '3IJ_rhqlcHE',
      'title': 'Diels-Alder Cycloaddition Complete Guide',
      'channel': 'Professor Dave Explains',
      'badge': 'Pericyclic Orbitals',
    },
    {
      'templateId': 'retro_da',
      'keywords': 'retro diels alder cracking cyclohexene cracking cyclopentadiene cycloaddition',
      'videoId': '82YDQcvNwYc',
      'title': 'Pericyclic Reactions & Frontier Molecular Orbitals',
      'channel': 'TMP Chem',
      'badge': 'Thermal Cleavage',
    },

    // --- 8. Aldol Addition & Condensation ---
    {
      'templateId': 'aldol-01',
      'keywords': 'aldol addition condensation acetaldehyde enolate hydroxybutanal c-c bond',
      'videoId': 'vGSVpd-VP0Y',
      'title': 'Aldol Condensation Mechanism Step by Step',
      'channel': 'Najam Academy',
      'badge': 'Carbonyl Chemistry',
    },
    {
      'templateId': 'aldol_condensation_bimolecular',
      'keywords': 'aldol condensation bimolecular crotonaldehyde enol enolate',
      'videoId': 'FuS51DIbig8',
      'title': 'Aldol Reaction & Enolate Chemistry',
      'channel': 'Vedantu',
      'badge': 'Enolate Mechanism',
    },
    {
      'templateId': 'aldol-01',
      'keywords': 'aldol dehydration enone condensation',
      'videoId': 'OiJo9evzMAs',
      'title': 'Aldol Addition and Dehydration Mechanisms',
      'channel': 'The Organic Chemistry Tutor',
      'badge': 'Carbonyl Addition',
    },

    // --- 9. Fischer Esterification ---
    {
      'templateId': 'fischer-01',
      'keywords': 'fischer esterification acetic acid methanol methyl acetate condensation ester',
      'videoId': 'EqBfua_kQ70',
      'title': 'Fischer Esterification Mechanism Step-by-Step',
      'channel': 'The Organic Chemistry Tutor',
      'badge': 'Esterification',
    },
    {
      'templateId': 'fisher_esterification',
      'keywords': 'fischer esterification ethanol ethyl acetate proton transfer acid catalysis',
      'videoId': 'jr64OxTpknM',
      'title': 'Synthesis of Aspirin & Esterification Mechanism',
      'channel': 'Organic Mechanisms',
      'badge': 'Acid Catalysis',
    },

    // --- 10. Grignard Addition ---
    {
      'templateId': 'grignard_addition',
      'keywords': 'grignard addition methylmagnesium bromide acetone tert-butoxide organometallic',
      'videoId': 'U8ltC2Kz3Mk',
      'title': 'Grignard Reagents Reaction Mechanism & Synthesis',
      'channel': 'The Organic Chemistry Tutor',
      'badge': 'Organometallics',
    },
    {
      'templateId': 'grignard_addition',
      'keywords': 'grignard nucleophilic carbonyl addition alcohol synthesis',
      'videoId': 'ZeHD7GcPNck',
      'title': 'Grignard Reactions & Organometallic Mechanisms',
      'channel': 'Professor Dave Explains',
      'badge': 'Organometallics',
    },

    // --- 11. Friedel-Crafts Alkylation & Acylation ---
    {
      'templateId': 'friedel_crafts',
      'keywords': 'friedel crafts alkylation benzene chloromethane toluene eas electrophilic aromatic',
      'videoId': 'gz6HnUfS2ow',
      'title': 'Friedel Crafts Alkylation & Acylation Reaction Mechanism',
      'channel': 'The Organic Chemistry Tutor',
      'badge': 'Electrophilic Aromatic',
    },
    {
      'templateId': 'friedel_crafts',
      'keywords': 'friedel crafts eas arenium sigma complex carbocation',
      'videoId': 'IovaWll-kV4',
      'title': 'Electrophilic Aromatic Substitution: Friedel-Crafts',
      'channel': 'Professor Dave Explains',
      'badge': 'EAS Mechanism',
    },

    // --- 12. Suzuki-Miyaura & Heck Cross-Coupling ---
    {
      'templateId': 'suzuki_coupling_simple',
      'keywords': 'suzuki coupling palladium cross coupling boronic acid aryl halide biphenyl',
      'videoId': 'efUk0vVIZow',
      'title': 'Suzuki-Miyaura Cross-Coupling Mechanism',
      'channel': 'Organic Mechanisms',
      'badge': 'Palladium Catalysis',
    },
    {
      'templateId': 'suzuki_coupling_simple',
      'keywords': 'suzuki miyaura oxidative addition transmetalation reductive elimination',
      'videoId': 'GlFOs-qs000',
      'title': 'Suzuki Reaction Catalytic Cycle',
      'channel': 'Total Organic Chemistry',
      'badge': 'Cross Coupling',
    },
    {
      'templateId': 'heck',
      'keywords': 'heck palladium alkene cross coupling migratory insertion',
      'videoId': 'dy09r1Gt9jU',
      'title': 'Heck Reaction Catalytic Cycle',
      'channel': 'Total Organic Chemistry',
      'badge': 'Palladium Cross Coupling',
    },
    {
      'templateId': 'heck',
      'keywords': 'heck reaction palladium catalyst alkene',
      'videoId': 'STlls5uVYwo',
      'title': 'Palladium Catalyzed Heck Cross Coupling',
      'channel': 'Organic Mechanisms',
      'badge': 'Catalysis Cycle',
    },

    // --- 13. Wittig Reaction ---
    {
      'templateId': 'wit-01',
      'keywords': 'wittig phosphonium ylide ketone oxaphosphetane betaine alkene',
      'videoId': 'jxUXIHG1zGc',
      'title': 'Wittig Reaction Mechanism & Oxaphosphetane Intermediate',
      'channel': 'The Organic Chemistry Tutor',
      'badge': 'Alkene Synthesis',
    },
    {
      'templateId': 'wittig_reaction',
      'keywords': 'wittig reaction trimethylmethylenephosphorane isobutene ylide',
      'videoId': 'M8oocLIVqzU',
      'title': 'Wittig Reaction and Ylides',
      'channel': 'Leah4sci',
      'badge': 'Organic Synthesis',
    },

    // --- 14. Ozonolysis ---
    {
      'templateId': 'ozonolysis',
      'keywords': 'ozonolysis ozone oxidative cleavage alkene criegee formaldehyde molozonide',
      'videoId': 'OC5bY9J8T08',
      'title': 'Ozonolysis Mechanism of Alkenes',
      'channel': 'Najam Academy',
      'badge': 'Alkene Cleavage',
    },
    {
      'templateId': 'ozonolysis',
      'keywords': 'ozonolysis criegee intermediate reductive workup dms zn',
      'videoId': 'At3jQNcl5Ho',
      'title': 'Ozonolysis Reaction Mechanism',
      'channel': 'Vineet Khatri',
      'badge': 'Oxidation Mechanism',
    },

    // --- 15. SN1 and SN2 Substitutions ---
    {
      'templateId': 'sn1_tbutyl',
      'keywords': 'sn1 tert butyl carbocation unimolecular nucleophilic substitution rate',
      'videoId': 'VpFGcpYgwy8',
      'title': 'SN1 and SN2 Substitution Mechanism Comparison',
      'channel': 'Najam Academy',
      'badge': 'Nucleophilic Substitution',
    },
    {
      'templateId': 'sn2',
      'keywords': 'sn2 nucleophilic substitution walden inversion bimolecular rate',
      'videoId': 'mYkEO0coOjU',
      'title': 'SN1 vs SN2 Reaction Mechanisms',
      'channel': 'The Organic Chemistry Tutor',
      'badge': 'Nucleophilic Substitution',
    },

    // --- 16. E1 and E2 Elimination ---
    {
      'templateId': 'elimination',
      'keywords': 'e1 e2 elimination zaitsev hoffmann base alkene',
      'videoId': 'L9VtDeIkPCg',
      'title': 'E1 and E2 Elimination Reaction Mechanism',
      'channel': 'Najam Academy',
      'badge': 'Elimination Mechanism',
    },
    {
      'templateId': 'elimination',
      'keywords': 'elimination bimolecular unimolecular carbocation',
      'videoId': 'ZOUS0Q_B4fQ',
      'title': 'Elimination Reactions Mechanism',
      'channel': 'CrashCourse',
      'badge': 'Reaction Kinetics',
    },

    // --- 17. Click Chemistry (CuAAC) ---
    {
      'templateId': 'click',
      'keywords': 'click chemistry copper azide alkyne triazole cuaac cycloaddition',
      'videoId': 'wnHw92hFUas',
      'title': 'Copper-Catalyzed Azide-Alkyne Cycloaddition (CuAAC)',
      'channel': 'YOU Knowledge',
      'badge': 'Click Chemistry',
    },
    {
      'templateId': 'click',
      'keywords': 'sharpless click chemistry bioorthogonal',
      'videoId': 'IdZxOjCT8sg',
      'title': 'Click Chemistry - CuAAC Mechanism',
      'channel': 'Chem Help ASAP',
      'badge': 'Bioorthogonal Chemistry',
    },

    // --- 18. Transition State Theory, NEB & DFT ---
    {
      'templateId': 'neb',
      'keywords': 'neb nudged elastic band dft transition state barrier minimum energy path',
      'videoId': 'smQS4U5Roco',
      'title': 'Nudged Elastic Band (NEB) Method in DFT',
      'channel': 'Materials Square',
      'badge': 'DFT Simulation',
    },
    {
      'templateId': 'transition_state',
      'keywords': 'transition state theory eyring arrhenius activation energy kinetics',
      'videoId': 'zZ7yN4mvvsc',
      'title': 'Transition State Theory & Eyring Equation',
      'channel': 'LearnChemE',
      'badge': 'Reaction Kinetics',
    },
    {
      'templateId': 'transition_state',
      'keywords': 'activated complex potential energy surface kinetics',
      'videoId': '7e0DdbTHQ1s',
      'title': 'Activated Complex & Transition State Theory',
      'channel': 'Yk Star',
      'badge': 'PES Kinetics',
    },
    {
      'templateId': 'neb',
      'keywords': 'quantum espresso transition state dft neb',
      'videoId': '2PotR4_sV_0',
      'title': 'NEB and Reaction Pathways in Quantum ESPRESSO',
      'channel': 'Quantum Mobile',
      'badge': 'Quantum Chemical',
    },

    // --- 19. Enzyme Catalysis ---
    {
      'templateId': 'enzyme',
      'keywords': 'enzyme kinetics michaelis menten catalytic site active site',
      'videoId': '-slPtkO2d9g',
      'title': 'Enzyme Catalysis and Kinetics',
      'channel': 'Lecturio Medical',
      'badge': 'Biocatalysis',
    },
    {
      'templateId': 'enzyme',
      'keywords': 'enzyme inhibition km vmax turnover',
      'videoId': 'Bdogz6Xw4Zc',
      'title': 'Enzyme Kinetics & Michaelis-Menten Equation',
      'channel': 'Medicosis Perfectionalis',
      'badge': 'Enzyme Kinetics',
    },
  ];

  /// Categorical mechanism fallbacks ensuring EVERY reaction has high-yield videos
  static const Map<String, List<Map<String, String>>> _categoryFallbacks = {
    'pericyclic': [
      {
        'videoId': 'sBmoP6KwK-8',
        'title': 'Diels-Alder Reaction Mechanism & Stereochemistry',
        'channel': 'The Organic Chemistry Tutor',
        'badge': 'Pericyclic Masterclass',
      },
      {
        'videoId': '3IJ_rhqlcHE',
        'title': 'Diels-Alder Cycloaddition Complete Guide',
        'channel': 'Professor Dave Explains',
        'badge': 'Pericyclic Orbitals',
      },
    ],
    'nucleophilic': [
      {
        'videoId': 'VpFGcpYgwy8',
        'title': 'SN1 and SN2 Substitution Mechanism Comparison',
        'channel': 'Najam Academy',
        'badge': 'Nucleophilic Masterclass',
      },
      {
        'videoId': 'mYkEO0coOjU',
        'title': 'SN1 vs SN2 Reaction Mechanisms',
        'channel': 'The Organic Chemistry Tutor',
        'badge': 'Carbonyl Addition',
      },
    ],
    'ionic': [
      {
        'videoId': 'vGSVpd-VP0Y',
        'title': 'Aldol Condensation Mechanism Step by Step',
        'channel': 'Najam Academy',
        'badge': 'Ionic Mechanisms',
      },
      {
        'videoId': 'gz6HnUfS2ow',
        'title': 'Friedel Crafts Alkylation & Acylation Mechanism',
        'channel': 'The Organic Chemistry Tutor',
        'badge': 'Electrophilic Chemistry',
      },
    ],
    'organometallic': [
      {
        'videoId': 'efUk0vVIZow',
        'title': 'Suzuki-Miyaura Cross-Coupling Mechanism',
        'channel': 'Organic Mechanisms',
        'badge': 'Organometallics',
      },
      {
        'videoId': 'dy09r1Gt9jU',
        'title': 'Heck Reaction Catalytic Cycle',
        'channel': 'Total Organic Chemistry',
        'badge': 'Catalytic Cycles',
      },
    ],
    'electrochemistry': [
      {
        'videoId': '-KE7jTXwNYs',
        'title': 'ATP Hydrolysis Mechanism & Free Energy',
        'channel': 'Khan Academy',
        'badge': 'Bioenergetics',
      },
    ],
  };

  /// Fetches related YouTube videos using YouTube Data API v3 (if apiKey available)
  /// or matching against our vetted educational database.
  ///
  /// Always returns a reliable list of video objects with:
  /// `videoId`, `title`, `thumbnail`, `channel`, and `badge`.
  static Future<List<Map<String, String>>> fetchRelatedVideos(
    String query, {
    String? templateId,
    String? templateName,
    String? category,
    String? apiKey,
  }) async {
    final effectiveKey = (apiKey != null && apiKey.isNotEmpty) ? apiKey : _envApiKey;

    // 1. Try YouTube Data API v3 if an API key is available
    if (effectiveKey.isNotEmpty) {
      try {
        final cleanSearchQuery = _sanitizeSearchQuery(query, templateName: templateName);
        final results = await _fetchFromYouTubeDataApi(cleanSearchQuery, effectiveKey);
        if (results.isNotEmpty) {
          return results;
        }
      } catch (e) {
        debugPrint('YouTubeService: Data API query failed: $e. Falling back to curated bank.');
      }
    }

    // 2. Curated video matching by templateId, templateName, or sanitized keywords
    final matchedVideos = _matchCuratedVideos(
      query: query,
      templateId: templateId,
      templateName: templateName,
    );

    if (matchedVideos.length >= 2) {
      return matchedVideos;
    }

    // 3. Category Fallback matching
    final List<Map<String, String>> combined = [...matchedVideos];
    if (category != null && category.isNotEmpty) {
      final catKey = category.toLowerCase().trim();
      final catList = _categoryFallbacks[catKey];
      if (catList != null) {
        for (final v in catList) {
          if (!combined.any((item) => item['videoId'] == v['videoId'])) {
            combined.add(v);
          }
        }
      }
    }

    if (combined.isNotEmpty) {
      return combined;
    }

    // 4. Foundational Masterclasses Fallback
    return [
      {
        'videoId': 'sBmoP6KwK-8',
        'title': 'Diels-Alder Reaction Mechanism & Stereochemistry',
        'thumbnail': 'https://i.ytimg.com/vi/sBmoP6KwK-8/hqdefault.jpg',
        'channel': 'The Organic Chemistry Tutor',
        'badge': 'Pericyclic Masterclass',
      },
      {
        'videoId': 'vGSVpd-VP0Y',
        'title': 'Aldol Condensation Mechanism Step by Step',
        'thumbnail': 'https://i.ytimg.com/vi/vGSVpd-VP0Y/hqdefault.jpg',
        'channel': 'Najam Academy',
        'badge': 'Carbonyl Chemistry',
      },
      {
        'videoId': 'jr64OxTpknM',
        'title': 'Synthesis of Aspirin & Esterification Mechanism',
        'thumbnail': 'https://i.ytimg.com/vi/jr64OxTpknM/hqdefault.jpg',
        'channel': 'Organic Mechanisms',
        'badge': 'Medicinal Chemistry',
      },
      {
        'videoId': 'oJhlRYoniyo',
        'title': 'Synthesis of Paracetamol (Acetaminophen) Mechanism',
        'thumbnail': 'https://i.ytimg.com/vi/oJhlRYoniyo/hqdefault.jpg',
        'channel': 'sqadia.com',
        'badge': 'MBBS Toxicology',
      },
      {
        'videoId': '-KE7jTXwNYs',
        'title': 'ATP Hydrolysis: Mechanism & Free Energy of Cleavage',
        'thumbnail': 'https://i.ytimg.com/vi/-KE7jTXwNYs/hqdefault.jpg',
        'channel': 'Khan Academy',
        'badge': 'Biochemistry',
      },
    ];
  }

  /// Sanitizes raw publication titles or queries into clean YouTube search terms.
  static String _sanitizeSearchQuery(String raw, {String? templateName}) {
    if (templateName != null && templateName.trim().isNotEmpty) {
      final base = templateName.replaceAll(RegExp(r'\(.*?\)'), ' ').trim();
      return '$base reaction mechanism';
    }

    String cleaned = raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ') // Remove HTML tags
        .replaceAll(RegExp(r'10\.\d{4,9}/[-._;()/:A-Za-z0-9]+'), ' ') // Remove DOIs
        .replaceAll(RegExp(r'\[.*?\]'), ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.length > 60) {
      cleaned = cleaned.substring(0, 60).trim();
    }

    if (cleaned.isEmpty) {
      cleaned = 'organic reaction mechanism chemistry';
    } else if (!cleaned.toLowerCase().contains('mechanism')) {
      cleaned = '$cleaned mechanism';
    }

    return cleaned;
  }

  /// Queries the official YouTube Data API v3
  static Future<List<Map<String, String>>> _fetchFromYouTubeDataApi(String q, String key) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?'
      'part=snippet&maxResults=5&type=video&q=${Uri.encodeComponent(q)}&key=$key',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      final List<Map<String, String>> out = [];

      for (final item in items) {
        final idObj = item['id'] as Map<String, dynamic>?;
        final videoId = idObj?['videoId']?.toString() ?? '';
        if (videoId.isEmpty) continue;

        final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
        final title = snippet['title']?.toString() ?? 'YouTube Video';
        final channel = snippet['channelTitle']?.toString() ?? 'YouTube';

        out.add({
          'videoId': videoId,
          'title': _unescapeHtml(title),
          'thumbnail': 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
          'channel': channel,
          'badge': 'YouTube',
        });
      }
      return out;
    }
    return [];
  }

  /// Matches curated videos using template ID, name, or keywords
  static List<Map<String, String>> _matchCuratedVideos({
    required String query,
    String? templateId,
    String? templateName,
  }) {
    final List<Map<String, String>> directMatches = [];
    final List<Map<String, String>> keywordMatches = [];

    // 1. Direct template ID match
    if (templateId != null && templateId.isNotEmpty) {
      final cleanId = templateId.trim().toLowerCase();
      for (final v in _curatedVideoBank) {
        if (v['templateId']?.toLowerCase() == cleanId) {
          directMatches.add(_toVideoResult(v));
        }
      }
      if (directMatches.isNotEmpty) {
        return directMatches;
      }
    }

    // 2. Keyword match against query and templateName
    final combinedText = '${templateName ?? ''} $query'.toLowerCase();
    final tokens = combinedText
        .split(RegExp(r'[^a-zA-Z0-9]'))
        .where((t) => t.length > 2 && !_commonStopwords.contains(t))
        .toSet();

    for (final v in _curatedVideoBank) {
      final keywords = (v['keywords'] ?? '').toLowerCase();
      final title = (v['title'] ?? '').toLowerCase();

      int score = 0;
      for (final token in tokens) {
        if (keywords.contains(token)) score += 3;
        if (title.contains(token)) score += 2;
      }

      if (score >= 2) {
        keywordMatches.add(_toVideoResult(v));
      }
    }

    if (keywordMatches.isNotEmpty) {
      return keywordMatches.take(5).toList();
    }

    return [];
  }

  static Map<String, String> _toVideoResult(Map<String, String> raw) {
    final videoId = raw['videoId'] ?? '';
    return {
      'videoId': videoId,
      'title': raw['title'] ?? 'Reaction Mechanism Video',
      'thumbnail': 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
      'channel': raw['channel'] ?? 'Educational',
      'badge': raw['badge'] ?? 'Mechanism',
    };
  }

  static String _unescapeHtml(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'");
  }

  /// Generates a direct YouTube search link for any reaction/topic
  static String buildYouTubeSearchUrl(String query, {String? templateName}) {
    final clean = _sanitizeSearchQuery(query, templateName: templateName);
    return 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(clean)}';
  }

  static const Set<String> _commonStopwords = {
    'the', 'and', 'for', 'with', 'from', 'via', 'into', 'reaction', 'mechanism',
    'synthesis', 'using', 'study', 'density', 'functional', 'theory', 'investigation',
    'chemical', 'acid', 'base', 'system', 'role', 'phase', 'level',
  };
}
