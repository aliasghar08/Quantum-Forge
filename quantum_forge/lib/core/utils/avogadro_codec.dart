// ============================================================================
// Avogadro Structure Codec
// ----------------------------------------------------------------------------
// Reads structures produced by Avogadro 2. Avogadro hands plugins and
// consumers Chemical JSON (CJSON), so that is the primary format; XYZ and CML
// text payloads are supported for the legacy `?import_xyz=` deep link and for
// structures pasted straight out of Avogadro's editor.
//
// Every entry point is defensive: a malformed or hostile payload must never
// take the dashboard down, it must produce a readable error instead.
// ============================================================================

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'avogadro_interchange.dart';
import 'element_data.dart';
import 'molecular.dart';

/// Why a payload could not be converted into atoms.
class AvogadroCodecException implements Exception {
  final String message;
  const AvogadroCodecException(this.message);

  @override
  String toString() => message;
}

/// A structure decoded from an external payload.
class DecodedStructure {
  final String title;
  final List<Atom> atoms;
  final List<PerceivedBond> bonds;

  /// True when the source document carried its own connectivity.
  final bool bondsFromSource;

  const DecodedStructure({
    required this.title,
    required this.atoms,
    required this.bonds,
    this.bondsFromSource = false,
  });

  int get atomCount => atoms.length;
  int get bondCount => bonds.length;
  bool get isEmpty => atoms.isEmpty;

  AvogadroStructure toStructure({double bondTolerance = 1.6}) =>
      AvogadroStructure(
        title: title,
        atoms: atoms,
        bonds: bonds.isEmpty && !bondsFromSource
            ? AvogadroInterchange.perceiveBonds(atoms, tolerance: bondTolerance)
            : bonds,
      );
}

class AvogadroCodec {
  const AvogadroCodec._();

  /// Hard cap on a decoded payload. Quantum Forge is a browser app, so an
  /// unbounded base64 query parameter is a trivial denial-of-service vector.
  static const int maxPayloadBytes = 4 * 1024 * 1024;
  static const int maxAtoms = 20000;

  // ── Public entry points ──────────────────────────────────────────────────

  /// Detects the format of [data] and decodes it.
  ///
  /// [formatHint] may be `cjson`, `xyz`, `cml`, `sdf`/`mol`; when null the
  /// format is sniffed from the content.
  static DecodedStructure decode(
    String data, {
    String? formatHint,
    String title = 'Avogadro structure',
  }) {
    if (data.trim().isEmpty) {
      throw const AvogadroCodecException('The payload is empty.');
    }
    final format = resolveFormat(data, formatHint);
    return switch (format) {
      'cjson' => fromCjson(data, fallbackTitle: title),
      'cml' => fromCml(data, fallbackTitle: title),
      'sdf' => fromSdf(data, fallbackTitle: title),
      'pdb' => fromPdb(data, fallbackTitle: title),
      'cif' => fromCif(data, fallbackTitle: title),
      _ => fromXyz(data, fallbackTitle: title),
    };
  }

  /// Sniffs the structure format from its content.
  static String resolveFormat(String data, String? formatHint) {
    final hint = formatHint?.toLowerCase().trim();
    if (hint != null && hint.isNotEmpty) {
      if (hint.contains('cjson') || hint == 'json') return 'cjson';
      if (hint.contains('cml') || hint == 'xml') return 'cml';
      if (hint == 'sdf' || hint == 'mol' || hint == 'mdl') return 'sdf';
      if (hint == 'xyz') return 'xyz';
      if (hint == 'pdb' || hint == 'ent') return 'pdb';
      if (hint == 'cif' || hint == 'mmcif') return 'cif';
    }
    final trimmed = data.trimLeft();
    if (trimmed.startsWith('{')) return 'cjson';
    if (trimmed.startsWith('<')) return 'cml';
    if (trimmed.contains('V2000') || trimmed.contains('M  END')) return 'sdf';
    if (RegExp(r'^(ATOM  |HETATM)', multiLine: true).hasMatch(data)) {
      return 'pdb';
    }
    if (trimmed.startsWith('data_') || trimmed.contains('_atom_site_')) {
      return 'cif';
    }
    return 'xyz';
  }

  // ── CJSON ────────────────────────────────────────────────────────────────
  static DecodedStructure fromCjson(
    String data, {
    String fallbackTitle = 'Avogadro structure',
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(data);
    } on FormatException catch (e) {
      throw AvogadroCodecException('CJSON is not valid JSON: ${e.message}');
    }
    if (decoded is! Map) {
      throw const AvogadroCodecException('CJSON root must be an object.');
    }
    return fromCjsonMap(
      decoded.cast<String, dynamic>(),
      fallbackTitle: fallbackTitle,
    );
  }

  static DecodedStructure fromCjsonMap(
    Map<String, dynamic> root, {
    String fallbackTitle = 'Avogadro structure',
  }) {
    final atomsBlock = root['atoms'];
    if (atomsBlock is! Map) {
      throw const AvogadroCodecException(
        'CJSON has no "atoms" block — nothing to import.',
      );
    }

    final coordsBlock = atomsBlock['coords'];
    // 3D coordinates use a stride of three (x, y, z); the 2D fallback uses two
    // (x, y) with z implied to be zero.
    final (coords, stride) = switch (coordsBlock) {
      Map m when m['3d'] is List => (m['3d'] as List, 3),
      Map m when m['2d'] is List => (m['2d'] as List, 2),
      List l => (l, 3),
      _ => (null, 3),
    };
    if (coords == null || coords.isEmpty) {
      throw const AvogadroCodecException(
        'CJSON has no 3D coordinates (atoms.coords.3d).',
      );
    }

    final elementsBlock = atomsBlock['elements'];
    final numbers = elementsBlock is Map ? elementsBlock['number'] : null;
    final symbolList =
        elementsBlock is Map ? elementsBlock['symbol'] : null;
    if (numbers is! List && symbolList is! List) {
      throw const AvogadroCodecException(
        'CJSON has no element list (atoms.elements.number).',
      );
    }

    final atomCount = coords.length ~/ stride;
    if (atomCount == 0) {
      throw const AvogadroCodecException('CJSON contains zero atoms.');
    }
    if (atomCount > maxAtoms) {
      throw AvogadroCodecException(
        'Structure has $atomCount atoms; the importer caps at $maxAtoms.',
      );
    }

    final atoms = <Atom>[];
    for (var i = 0; i < atomCount; i++) {
      final symbol = _symbolAt(numbers, symbolList, i);
      final x = _doubleAt(coords, i * stride);
      final y = _doubleAt(coords, i * stride + 1);
      final z = stride == 3 ? _doubleAt(coords, i * stride + 2) : 0.0;
      atoms.add(atomFor(symbol, x, y, z));
    }

    final bonds = _bondsFromCjson(root['bonds'], atomCount);

    return DecodedStructure(
      title: _title(root, fallbackTitle),
      atoms: atoms,
      bonds: bonds,
      bondsFromSource: bonds.isNotEmpty,
    );
  }

  /// Extracts the bonds present in a CJSON document.
  static List<PerceivedBond> _bondsFromCjson(Object? bondsBlock, int atomCount) {
    if (bondsBlock is! Map) return const [];
    final connections = bondsBlock['connections'];
    final index = connections is Map ? connections['index'] : null;
    if (index is! List) return const [];
    final orders = bondsBlock['order'];

    final result = <PerceivedBond>[];
    for (var i = 0; i + 1 < index.length; i += 2) {
      final a = _intOf(index[i]);
      final b = _intOf(index[i + 1]);
      if (a == null || b == null) continue;
      if (a < 0 || b < 0 || a >= atomCount || b >= atomCount || a == b) continue;
      final order = orders is List ? (_intOf(orders[i ~/ 2]) ?? 1) : 1;
      result.add(PerceivedBond(
        a: a,
        b: b,
        order: order.clamp(1, 4),
        length: 0,
      ));
    }
    return result;
  }

  // ── XYZ ──────────────────────────────────────────────────────────────────
  /// Parses the **first frame** of an XYZ document.
  ///
  /// Respecting the declared count matters: a multi-XYZ trajectory (what the
  /// dashboard exports for Avogadro) would otherwise be read as one enormous
  /// "molecule" containing every image.
  static DecodedStructure fromXyz(
    String data, {
    String fallbackTitle = 'Avogadro structure',
  }) {
    final lines = const LineSplitter()
        .convert(data)
        .map((l) => l.trimRight())
        .toList();
    if (lines.isEmpty) {
      throw const AvogadroCodecException('The XYZ payload is empty.');
    }

    // The first non-empty line holds the atom count; the next is the title.
    var cursor = 0;
    while (cursor < lines.length && lines[cursor].trim().isEmpty) {
      cursor++;
    }
    if (cursor >= lines.length) {
      throw const AvogadroCodecException('The XYZ payload has no header.');
    }

    final declared =
        int.tryParse(lines[cursor].trim().split(RegExp(r'\s+')).first);
    var title = fallbackTitle;
    cursor++;
    if (cursor < lines.length) {
      final candidate = lines[cursor].trim();
      if (candidate.isNotEmpty &&
          double.tryParse(candidate.split(RegExp(r'\s+')).first) == null) {
        title = candidate;
      }
      cursor++;
    }

    final atoms = <Atom>[];
    final limit = (declared != null && declared > 0) ? declared : -1;
    for (var i = cursor; i < lines.length; i++) {
      if (limit > 0 && atoms.length >= limit) break;
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 4) continue;
      final x = double.tryParse(parts[1]);
      final y = double.tryParse(parts[2]);
      final z = double.tryParse(parts[3]);
      if (x == null || y == null || z == null) continue;
      atoms.add(atomFor(parts[0], x, y, z));
    }

    if (atoms.isEmpty) {
      throw const AvogadroCodecException(
        'No atom lines could be read from the XYZ payload.',
      );
    }
    if (declared != null && declared > 0 && declared != atoms.length) {
      // Not fatal — plenty of hand-edited files disagree with their header —
      // but the caller deserves to know which count was trusted.
      title = '$title (header said $declared atoms, read ${atoms.length})';
    }
    if (atoms.length > maxAtoms) {
      throw AvogadroCodecException(
        'Structure has ${atoms.length} atoms; the importer caps at $maxAtoms.',
      );
    }

    return DecodedStructure(
      title: title,
      atoms: atoms,
      bonds: AvogadroInterchange.perceiveBonds(atoms),
    );
  }

  // ── CML ──────────────────────────────────────────────────────────────────
  static DecodedStructure fromCml(
    String data, {
    String fallbackTitle = 'Avogadro structure',
  }) {
    final atomRegex = RegExp(r'<atom\b[^>]*>', caseSensitive: false);
    final matches = atomRegex.allMatches(data).toList();
    if (matches.isEmpty) {
      throw const AvogadroCodecException('CML contains no <atom> elements.');
    }
    if (matches.length > maxAtoms) {
      throw AvogadroCodecException(
        'Structure has ${matches.length} atoms; the importer caps at $maxAtoms.',
      );
    }

    final atoms = <Atom>[];
    for (final match in matches) {
      final tag = match.group(0)!;
      final symbol = _attr(tag, 'elementType') ?? _attr(tag, 'elementtype');
      final x = double.tryParse(_attr(tag, 'x3') ?? '');
      final y = double.tryParse(_attr(tag, 'y3') ?? '');
      final z = double.tryParse(_attr(tag, 'z3') ?? '');
      if (symbol == null || x == null || y == null || z == null) continue;
      atoms.add(atomFor(symbol, x, y, z));
    }
    if (atoms.isEmpty) {
      throw const AvogadroCodecException(
        'CML <atom> elements carry no complete x3/y3/z3 coordinates.',
      );
    }

    final nameMatch = RegExp(r'<name>([^<]*)</name>', caseSensitive: false)
        .firstMatch(data);
    final title = (nameMatch?.group(1)?.trim().isNotEmpty ?? false)
        ? nameMatch!.group(1)!.trim()
        : fallbackTitle;

    return DecodedStructure(
      title: title,
      atoms: atoms,
      bonds: AvogadroInterchange.perceiveBonds(atoms),
    );
  }

  // ── SDF / MOL ────────────────────────────────────────────────────────────
  static DecodedStructure fromSdf(
    String data, {
    String fallbackTitle = 'Avogadro structure',
  }) {
    final lines = const LineSplitter().convert(data).map((l) => l.trimRight()).toList();
    if (lines.length < 4) {
      throw const AvogadroCodecException('SDF/MOL payload is too short.');
    }
    final title = lines[0].trim().isEmpty ? fallbackTitle : lines[0].trim();
    final counts = lines[3];
    final atomCount = int.tryParse(counts.length >= 3 ? counts.substring(0, 3).trim() : '');
    if (atomCount == null || atomCount <= 0) {
      throw const AvogadroCodecException('SDF/MOL counts line is malformed.');
    }
    if (atomCount > maxAtoms) {
      throw AvogadroCodecException(
        'Structure has $atomCount atoms; the importer caps at $maxAtoms.',
      );
    }

    final atoms = <Atom>[];
    for (var i = 4; i < 4 + atomCount && i < lines.length; i++) {
      final line = lines[i];
      if (line.length < 34) continue;
      final x = double.tryParse(line.substring(0, 10).trim());
      final y = double.tryParse(line.substring(10, 20).trim());
      final z = double.tryParse(line.substring(20, 30).trim());
      final symbol = line.substring(31, 34).trim();
      if (x == null || y == null || z == null) continue;
      atoms.add(atomFor(symbol, x, y, z));
    }
    if (atoms.isEmpty) {
      throw const AvogadroCodecException('SDF/MOL atom block could not be read.');
    }
    return DecodedStructure(
      title: title,
      atoms: atoms,
      bonds: AvogadroInterchange.perceiveBonds(atoms),
    );
  }

  // ── PDB ──────────────────────────────────────────────────────────────────
  /// Parses a Protein Data Bank (PDB) document.
  static DecodedStructure fromPdb(
    String data, {
    String fallbackTitle = 'PDB structure',
  }) {
    if (data.trim().isEmpty) {
      throw const AvogadroCodecException('The PDB payload is empty.');
    }
    final lines = const LineSplitter()
        .convert(data)
        .map((l) => l.trimRight())
        .toList();
    if (lines.isEmpty) {
      throw const AvogadroCodecException('The PDB payload is empty.');
    }

    final titles = <String>[];
    final atoms = <Atom>[];
    final serialToIndex = <int, int>{};
    final seenAltLoc = <String>{};
    final explicitBondsMap = <(int, int), int>{};
    final atomsWithConect = <int>{};

    for (final line in lines) {
      if (line.startsWith('END') || line.startsWith('ENDMDL')) {
        if (atoms.isNotEmpty) break;
        continue;
      }
      if (line.startsWith('TITLE')) {
        final t = line.length > 10 ? line.substring(10).trim() : '';
        if (t.isNotEmpty) titles.add(t);
        continue;
      }
      if (line.startsWith('ATOM') || line.startsWith('HETATM')) {
        if (atoms.length >= maxAtoms) {
          throw AvogadroCodecException(
            'Structure has ${atoms.length + 1} atoms; the importer caps at $maxAtoms.',
          );
        }

        // Serial: columns 7-11 (chars 6..11)
        final serialStr = line.length >= 11
            ? line.substring(6, 11).trim()
            : (line.length > 6 ? line.substring(6).trim() : '');
        final serial = int.tryParse(serialStr);

        // AltLoc: column 17 (char 16)
        final altLoc = line.length > 16 ? line[16] : ' ';
        final atomName = line.length >= 16 ? line.substring(12, 16).trim() : '';
        final resName = line.length >= 20 ? line.substring(17, 20).trim() : '';
        final chain = line.length >= 22 ? line[21] : ' ';
        final resSeq = line.length >= 26 ? line.substring(22, 26).trim() : '';

        if (altLoc != ' ') {
          final locKey = '$chain:$resSeq:$resName:$atomName';
          if (seenAltLoc.contains(locKey)) {
            continue; // Keep only first altLoc
          }
          seenAltLoc.add(locKey);
        }

        // Coordinates: cols 31-38 (x), 39-46 (y), 47-54 (z)
        if (line.length < 54) {
          throw const AvogadroCodecException(
            'PDB ATOM/HETATM line is shorter than 54 characters (missing coordinates).',
          );
        }
        final xStr = line.substring(30, 38).trim();
        final yStr = line.substring(38, 46).trim();
        final zStr = line.substring(46, 54).trim();
        final x = double.tryParse(xStr);
        final y = double.tryParse(yStr);
        final z = double.tryParse(zStr);
        if (x == null || y == null || z == null) {
          throw AvogadroCodecException(
            'Malformed coordinates in PDB record: "$xStr", "$yStr", "$zStr".',
          );
        }

        // Element: columns 77-78 (chars 76..78)
        String elemSymbol = '';
        if (line.length >= 78) {
          elemSymbol = line.substring(76, 78).trim();
        } else if (line.length >= 77) {
          elemSymbol = line.substring(76, 77).trim();
        }
        if (elemSymbol.isNotEmpty) {
          elemSymbol = ElementData.canonicalSymbol(elemSymbol);
        } else {
          // Fall back to stripping digits and whitespace from atom name
          final stripped = atomName.replaceAll(RegExp(r'[\d\s]+'), '');
          if (stripped.isNotEmpty) {
            elemSymbol = ElementData.canonicalSymbol(stripped);
          } else {
            elemSymbol = 'C';
          }
        }

        final atomIndex = atoms.length;
        atoms.add(atomFor(elemSymbol, x, y, z));
        if (serial != null) {
          serialToIndex[serial] = atomIndex;
        }
        continue;
      }
      if (line.startsWith('CONECT')) {
        final lineLen = line.length;
        final aSerial = int.tryParse(
          lineLen >= 11 ? line.substring(6, 11).trim() : '',
        );
        if (aSerial == null || !serialToIndex.containsKey(aSerial)) continue;
        final aIdx = serialToIndex[aSerial]!;

        for (var col = 11; col + 5 <= lineLen && col < 31; col += 5) {
          final bSerialStr = line.substring(col, col + 5).trim();
          if (bSerialStr.isEmpty) continue;
          final bSerial = int.tryParse(bSerialStr);
          if (bSerial == null || !serialToIndex.containsKey(bSerial)) continue;
          final bIdx = serialToIndex[bSerial]!;
          if (aIdx == bIdx) continue;

          final u = math.min(aIdx, bIdx);
          final v = math.max(aIdx, bIdx);
          explicitBondsMap[(u, v)] = (explicitBondsMap[(u, v)] ?? 0) + 1;
          atomsWithConect.add(aIdx);
          atomsWithConect.add(bIdx);
        }
        continue;
      }
    }

    if (atoms.isEmpty) {
      throw const AvogadroCodecException('No ATOM or HETATM records found in PDB.');
    }

    final List<PerceivedBond> bonds;
    final bool bondsFromSource;

    if (explicitBondsMap.isNotEmpty) {
      bondsFromSource = true;
      final explicitBondsList = <PerceivedBond>[];
      for (final entry in explicitBondsMap.entries) {
        final (u, v) = entry.key;
        final order = entry.value.clamp(1, 4);
        final length = _atomDistance(atoms[u], atoms[v]);
        explicitBondsList.add(PerceivedBond(a: u, b: v, order: order, length: length));
      }

      // Check if there are atoms lacking CONECT records (mixed file)
      final unbondedAtoms = <int>{};
      for (var i = 0; i < atoms.length; i++) {
        if (!atomsWithConect.contains(i)) {
          unbondedAtoms.add(i);
        }
      }

      if (unbondedAtoms.isNotEmpty) {
        final perceivedAll = AvogadroInterchange.perceiveBonds(atoms);
        for (final pb in perceivedAll) {
          if (unbondedAtoms.contains(pb.a) || unbondedAtoms.contains(pb.b)) {
            final key = (math.min(pb.a, pb.b), math.max(pb.a, pb.b));
            if (!explicitBondsMap.containsKey(key)) {
              explicitBondsList.add(pb);
            }
          }
        }
      }
      bonds = explicitBondsList;
    } else {
      bondsFromSource = false;
      bonds = AvogadroInterchange.perceiveBonds(atoms);
    }

    final title = titles.isNotEmpty ? titles.join(' ') : fallbackTitle;
    return DecodedStructure(
      title: title,
      atoms: atoms,
      bonds: bonds,
      bondsFromSource: bondsFromSource,
    );
  }

  // ── CIF ──────────────────────────────────────────────────────────────────
  /// Parses a Crystallographic Information File (CIF).
  static DecodedStructure fromCif(
    String data, {
    String fallbackTitle = 'CIF structure',
  }) {
    if (data.trim().isEmpty) {
      throw const AvogadroCodecException('The CIF payload is empty.');
    }

    final lines = const LineSplitter().convert(data);
    String title = fallbackTitle;

    double? cellA, cellB, cellC;
    double? cellAlpha, cellBeta, cellGamma;

    var inFirstDataBlock = false;
    var foundDataBlock = false;

    int lineIdx = 0;
    while (lineIdx < lines.length) {
      final line = lines[lineIdx];
      final trimmed = line.trim();

      if (trimmed.startsWith('#') || trimmed.isEmpty) {
        lineIdx++;
        continue;
      }

      if (trimmed.toLowerCase().startsWith('data_')) {
        if (!foundDataBlock) {
          foundDataBlock = true;
          inFirstDataBlock = true;
          final blockName = trimmed.substring(5).trim();
          if (blockName.isNotEmpty) {
            title = blockName.replaceAll('_', ' ');
          }
        } else if (inFirstDataBlock) {
          break;
        }
        lineIdx++;
        continue;
      }

      if (trimmed.startsWith('_cell_') || trimmed.startsWith('_cell.')) {
        final tokens = _tokenizeCifLine(trimmed);
        if (tokens.length >= 2) {
          final tag = tokens[0].toLowerCase();
          final val = _parseCifNumber(tokens[1]);
          if (val != null) {
            if (tag == '_cell_length_a' || tag == '_cell.length_a') cellA = val;
            if (tag == '_cell_length_b' || tag == '_cell.length_b') cellB = val;
            if (tag == '_cell_length_c' || tag == '_cell.length_c') cellC = val;
            if (tag == '_cell_angle_alpha' || tag == '_cell.angle_alpha') cellAlpha = val;
            if (tag == '_cell_angle_beta' || tag == '_cell.angle_beta') cellBeta = val;
            if (tag == '_cell_angle_gamma' || tag == '_cell.angle_gamma') cellGamma = val;
          }
        }
      }

      if (trimmed.toLowerCase() == 'loop_') {
        lineIdx++;
        final headerTags = <String>[];
        while (lineIdx < lines.length) {
          final loopLine = lines[lineIdx].trim();
          if (loopLine.startsWith('_')) {
            headerTags.add(loopLine.split(RegExp(r'\s+')).first.toLowerCase());
            lineIdx++;
          } else {
            break;
          }
        }

        final isAtomLoop = headerTags.any(
          (t) => t.startsWith('_atom_site_') || t.startsWith('_atom_site.'),
        );
        if (isAtomLoop) {
          int? typeSymbolIdx;
          int? labelIdx;
          int? cartnXIdx, cartnYIdx, cartnZIdx;
          int? fractXIdx, fractYIdx, fractZIdx;

          for (var i = 0; i < headerTags.length; i++) {
            final t = headerTags[i];
            if (t == '_atom_site_type_symbol' || t == '_atom_site.type_symbol') {
              typeSymbolIdx = i;
            } else if (t == '_atom_site_label' ||
                t == '_atom_site.label' ||
                t == '_atom_site_auth_atom_id') {
              labelIdx ??= i;
            } else if (t == '_atom_site_cartn_x' || t == '_atom_site.cartn_x') {
              cartnXIdx = i;
            } else if (t == '_atom_site_cartn_y' || t == '_atom_site.cartn_y') {
              cartnYIdx = i;
            } else if (t == '_atom_site_cartn_z' || t == '_atom_site.cartn_z') {
              cartnZIdx = i;
            } else if (t == '_atom_site_fract_x' || t == '_atom_site.fract_x') {
              fractXIdx = i;
            } else if (t == '_atom_site_fract_y' || t == '_atom_site.fract_y') {
              fractYIdx = i;
            } else if (t == '_atom_site_fract_z' || t == '_atom_site.fract_z') {
              fractZIdx = i;
            }
          }

          final hasCartn = cartnXIdx != null && cartnYIdx != null && cartnZIdx != null;
          final hasFract = fractXIdx != null && fractYIdx != null && fractZIdx != null;

          if (!hasCartn && !hasFract) {
            throw const AvogadroCodecException(
              'No coordinate columns found in CIF atom_site loop.',
            );
          }

          final atoms = <Atom>[];
          final tokenBuffer = <String>[];
          final colsCount = headerTags.length;

          while (lineIdx < lines.length) {
            final dataLine = lines[lineIdx].trim();
            if (dataLine.isEmpty || dataLine.startsWith('#')) {
              lineIdx++;
              continue;
            }
            if (dataLine.toLowerCase() == 'loop_' ||
                dataLine.startsWith('_') ||
                dataLine.toLowerCase().startsWith('data_')) {
              break;
            }

            final rowTokens = _tokenizeCifLine(dataLine);
            tokenBuffer.addAll(rowTokens);

            while (tokenBuffer.length >= colsCount) {
              final row = tokenBuffer.sublist(0, colsCount);
              tokenBuffer.removeRange(0, colsCount);

              if (atoms.length >= maxAtoms) {
                throw AvogadroCodecException(
                  'Structure has ${atoms.length + 1} atoms; the importer caps at $maxAtoms.',
                );
              }

              String elem = '';
              if (typeSymbolIdx != null && typeSymbolIdx < row.length) {
                elem = row[typeSymbolIdx].replaceAll(RegExp(r'[^a-zA-Z]'), '');
              }
              if (elem.isEmpty && labelIdx != null && labelIdx < row.length) {
                elem = row[labelIdx].replaceAll(RegExp(r'[^a-zA-Z]'), '');
              }
              if (elem.isEmpty) elem = 'C';
              final canonicalElem = ElementData.canonicalSymbol(elem);

              double x, y, z;
              if (cartnXIdx != null && cartnYIdx != null && cartnZIdx != null) {
                final px = _parseCifNumber(row[cartnXIdx]);
                final py = _parseCifNumber(row[cartnYIdx]);
                final pz = _parseCifNumber(row[cartnZIdx]);
                if (px == null || py == null || pz == null) {
                  throw AvogadroCodecException(
                    'Malformed Cartesian coordinates in CIF atom: ${row[cartnXIdx]}, ${row[cartnYIdx]}, ${row[cartnZIdx]}',
                  );
                }
                x = px;
                y = py;
                z = pz;
              } else if (fractXIdx != null && fractYIdx != null && fractZIdx != null) {
                final fx = _parseCifNumber(row[fractXIdx]);
                final fy = _parseCifNumber(row[fractYIdx]);
                final fz = _parseCifNumber(row[fractZIdx]);
                if (fx == null || fy == null || fz == null) {
                  throw AvogadroCodecException(
                    'Malformed fractional coordinates in CIF atom: ${row[fractXIdx]}, ${row[fractYIdx]}, ${row[fractZIdx]}',
                  );
                }
                final (cx, cy, cz) = _fractionalToCartesian(
                  fx, fy, fz,
                  cellA ?? 1.0, cellB ?? 1.0, cellC ?? 1.0,
                  cellAlpha ?? 90.0, cellBeta ?? 90.0, cellGamma ?? 90.0,
                );
                x = cx;
                y = cy;
                z = cz;
              } else {
                throw const AvogadroCodecException(
                  'No coordinate columns found in CIF atom_site loop.',
                );
              }

              atoms.add(atomFor(canonicalElem, x, y, z));
            }

            lineIdx++;
          }

          if (atoms.isEmpty) {
            throw const AvogadroCodecException('CIF contains zero atoms.');
          }

          final bonds = AvogadroInterchange.perceiveBonds(atoms);
          return DecodedStructure(
            title: title,
            atoms: atoms,
            bonds: bonds,
            bondsFromSource: false,
          );
        }
      }

      lineIdx++;
    }

    throw const AvogadroCodecException('No _atom_site loop found in CIF.');
  }

  static double _atomDistance(Atom a, Atom b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final dz = a.z - b.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  static double? _parseCifNumber(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    if (cleaned == '?' || cleaned == '.' || cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static List<String> _tokenizeCifLine(String line) {
    final tokens = <String>[];
    final len = line.length;
    var i = 0;
    while (i < len) {
      while (i < len && (line[i] == ' ' || line[i] == '\t')) {
        i++;
      }
      if (i >= len) break;
      if (line[i] == '#') break;
      if (line[i] == "'" || line[i] == '"') {
        final quote = line[i];
        final start = ++i;
        while (i < len && line[i] != quote) {
          i++;
        }
        tokens.add(line.substring(start, i));
        if (i < len) i++;
      } else {
        final start = i;
        while (i < len && line[i] != ' ' && line[i] != '\t' && line[i] != '#') {
          i++;
        }
        tokens.add(line.substring(start, i));
      }
    }
    return tokens;
  }

  static (double, double, double) _fractionalToCartesian(
    double xf,
    double yf,
    double zf,
    double a,
    double b,
    double c,
    double alpha,
    double beta,
    double gamma,
  ) {
    final alphaRad = alpha * (math.pi / 180.0);
    final betaRad = beta * (math.pi / 180.0);
    final gammaRad = gamma * (math.pi / 180.0);

    final cosAlpha = math.cos(alphaRad);
    final cosBeta = math.cos(betaRad);
    final cosGamma = math.cos(gammaRad);
    final sinGamma = math.sin(gammaRad);

    final vTerm = 1.0 -
        cosAlpha * cosAlpha -
        cosBeta * cosBeta -
        cosGamma * cosGamma +
        2.0 * cosAlpha * cosBeta * cosGamma;
    final v = math.sqrt(math.max(0.0, vTerm));
    final denom = sinGamma == 0.0 ? 1.0 : sinGamma;

    final x = a * xf + b * cosGamma * yf + c * cosBeta * zf;
    final y = b * sinGamma * yf + c * ((cosAlpha - cosBeta * cosGamma) / denom) * zf;
    final z = c * (v / denom) * zf;

    return (x, y, z);
  }

  // ── base64url transport ──────────────────────────────────────────────────
  /// Encodes [payload] as URL-safe base64 without padding.
  static String encodePayload(String payload) {
    final bytes = utf8.encode(payload);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Decodes a URL-safe base64 payload.
  ///
  /// Historically the Avogadro deep link stripped `=` padding on the Python
  /// side; depending on the browser and the payload length that produces an
  /// invalid base64 string, which is why "Export to Quantum Forge Web" used to
  /// fail intermittently. Padding is restored here rather than trusted.
  static String decodePayload(String encoded) {
    var normalized = encoded.trim().replaceAll(' ', '+');
    normalized = normalized.replaceAll('-', '+').replaceAll('_', '/');
    final remainder = normalized.length % 4;
    if (remainder == 2) {
      normalized += '==';
    } else if (remainder == 3) {
      normalized += '=';
    } else if (remainder == 1) {
      throw const AvogadroCodecException(
        'The base64 payload is truncated (invalid length).',
      );
    }

    final Uint8List bytes;
    try {
      bytes = base64Decode(normalized);
    } on FormatException catch (e) {
      throw AvogadroCodecException('The payload is not valid base64: ${e.message}');
    }
    if (bytes.length > maxPayloadBytes) {
      throw AvogadroCodecException(
        'Payload is ${(bytes.length / 1048576).toStringAsFixed(1)} MB; '
        'the importer caps at ${maxPayloadBytes ~/ 1048576} MB.',
      );
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const AvogadroCodecException('The decoded payload is not valid UTF-8.');
    }
  }

  // ── small helpers ────────────────────────────────────────────────────────
  static String _symbolAt(Object? numbers, Object? symbols, int index) {
    if (symbols is List && index < symbols.length && symbols[index] is String) {
      final symbol = symbols[index] as String;
      if (symbol.trim().isNotEmpty) return ElementData.canonicalSymbol(symbol);
    }
    if (numbers is List && index < numbers.length) {
      final z = _intOf(numbers[index]);
      if (z != null && z > 0) return ElementData.symbolForAtomicNumber(z);
    }
    return 'H';
  }

  static double _doubleAt(List<dynamic> list, int index) {
    if (index >= list.length) return 0;
    final value = list[index];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int? _intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String _title(Map<String, dynamic> root, String fallback) {
    final name = root['name'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    return fallback;
  }

  static String? _attr(String tag, String name) {
    final match = RegExp('$name\\s*=\\s*"([^"]*)"', caseSensitive: false)
        .firstMatch(tag);
    return match?.group(1);
  }
}
