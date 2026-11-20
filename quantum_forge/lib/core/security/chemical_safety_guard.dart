// ============================================================================
// Chemical Safety Guard & CBRN / Controlled Substance Security Gate
// ----------------------------------------------------------------------------
// Deterministically screens user-entered SMILES, InChI, and chemical names
// against international non-proliferation and chemical control standards:
// 1. Chemical Weapons Convention (CWC Schedule 1/2/3 nerve & vesicant agents:
//    Sarin, Soman, Tabun, VX, Novichok, Sulfur/Nitrogen Mustards, Lewisite)
// 2. High Explosives (RDX, HMX, PETN, TNT, TATP)
// 3. DEA Schedule I/II Illicit Narcotics & Critical Weaponized Precursors
//    (Fentanyl, Carfentanil, Heroin, Cocaine, Methamphetamine)
//
// Prevents unauthorized calculation or persistence before any backend or
// database write occurs, returning an explicit regulatory compliance message.
// ============================================================================

class ChemicalSafetyResult {
  final bool isAllowed;
  final String? violationCategory;
  final String? matchedAgent;
  final String? complianceMessage;

  const ChemicalSafetyResult({
    required this.isAllowed,
    this.violationCategory,
    this.matchedAgent,
    this.complianceMessage,
  });

  static const ChemicalSafetyResult allowed = ChemicalSafetyResult(isAllowed: true);
}

class ChemicalSafetyGuard {
  static final List<({String name, String description})> _prohibitedEntities = [
    (name: 'sarin', description: 'CWC Schedule 1 Nerve Agent (G-series / GB)'),
    (name: 'soman', description: 'CWC Schedule 1 Nerve Agent (G-series / GD)'),
    (name: 'tabun', description: 'CWC Schedule 1 Nerve Agent (G-series / GA)'),
    (name: 'vx', description: 'CWC Schedule 1 Nerve Agent (V-series / VX)'),
    (name: 'novichok', description: 'CWC Schedule 1 Fourth-Generation Nerve Agent (A-series)'),
    (name: 'cyclosarin', description: 'CWC Schedule 1 Nerve Agent (GF)'),
    (name: 'mustard gas', description: 'CWC Schedule 1 Vesicant Agent (Sulfur Mustard / HD)'),
    (name: 'sulfur mustard', description: 'CWC Schedule 1 Vesicant Agent (HD)'),
    (name: 'nitrogen mustard', description: 'CWC Schedule 1 Vesicant Agent (HN-1/HN-2/HN-3)'),
    (name: 'lewisite', description: 'CWC Schedule 1 Vesicant Agent (L)'),
    (name: 'chloropicrin', description: 'CWC Schedule 3 Toxic Chemical Agent'),
    (name: 'rdx', description: 'Regulated High Explosive (Cyclotrimethylenetrinitramine)'),
    (name: 'hexogen', description: 'Regulated High Explosive (RDX)'),
    (name: 'hmx', description: 'Regulated High Explosive (Cyclotetramethylenetetranitramine)'),
    (name: 'octogen', description: 'Regulated High Explosive (HMX)'),
    (name: 'petn', description: 'Regulated High Explosive (Pentaerythritol Tetranitrate)'),
    (name: 'tatp', description: 'Regulated Primary Explosive (Triacetone Triperoxide)'),
    (name: 'trinitrotoluene', description: 'Regulated High Explosive (TNT)'),
    (name: 'tnt', description: 'Regulated High Explosive (TNT)'),
    (name: 'fentanyl', description: 'DEA Schedule II / Controlled Opioid Derivative'),
    (name: 'carfentanil', description: 'DEA Schedule II / Ultra-potent Opioid Derivative'),
    (name: 'diacetylmorphine', description: 'DEA Schedule I Illicit Narcotic (Heroin)'),
    (name: 'heroin', description: 'DEA Schedule I Illicit Narcotic'),
    (name: 'methamphetamine', description: 'DEA Schedule II Controlled Stimulant'),
  ];

  static final List<({RegExp pattern, String description})> _prohibitedSmilesPatterns = [
    (
      pattern: RegExp(r'O=P\([^)]+\)\(F\)', caseSensitive: false),
      description: 'CWC Schedule 1 Alkyl Phosphonofluoridate (Sarin/Soman family)',
    ),
    (
      pattern: RegExp(r'P\(=O\)\(F\)', caseSensitive: false),
      description: 'CWC Schedule 1 Fluorophosphonate nerve agent core',
    ),
    (
      pattern: RegExp(r'P\(=O\)\([^)]+\)SCCN', caseSensitive: false),
      description: 'CWC Schedule 1 V-series Phosphonothioate (VX family)',
    ),
    (
      pattern: RegExp(r'ClCCSCCCl', caseSensitive: false),
      description: 'CWC Schedule 1 Sulfur Mustard (Bis(2-chloroethyl) sulfide)',
    ),
    (
      pattern: RegExp(r'ClCCN\([^)]+\)CCCl', caseSensitive: false),
      description: 'CWC Schedule 1 Nitrogen Mustard (HN-series)',
    ),
    (
      pattern: RegExp(r'\[As\]\(Cl\)Cl', caseSensitive: false),
      description: 'CWC Schedule 1 Organoarsenic Vesicant (Lewisite)',
    ),
    (
      pattern: RegExp(r'N\(\[N\+\]\(=O\)\[O-\]\)CN\(\[N\+\]\(=O\)\[O-\]\)', caseSensitive: false),
      description: 'Regulated Cyclic Nitramine High Explosive (RDX/HMX core)',
    ),
    (
      pattern: RegExp(r'C\(CO\[N\+\]\(=O\)\[O-\]\)\(CO\[N\+\]\(=O\)\[O-\]\)', caseSensitive: false),
      description: 'Regulated Pentaerythritol Tetranitrate (PETN core)',
    ),
  ];

  /// Screens a raw SMILES string, InChI, or chemical name.
  static ChemicalSafetyResult screen(String input) {
    if (input.trim().isEmpty) return ChemicalSafetyResult.allowed;

    final normalized = input.trim().toLowerCase();

    // 1. Text token screening
    for (final item in _prohibitedEntities) {
      final reg = RegExp(r'\b' + RegExp.escape(item.name) + r'\b');
      if (reg.hasMatch(normalized) || normalized == item.name) {
        final cat = item.description.contains('CWC')
            ? 'CWC Prohibited Chemical Agent'
            : item.description.contains('Explosive')
                ? 'Regulated High Explosive'
                : 'Controlled Substance / Precursor';
        return ChemicalSafetyResult(
          isAllowed: false,
          violationCategory: cat,
          matchedAgent: item.description,
          complianceMessage:
              'COMPLIANCE BLOCK: The requested chemical entity matches a prohibited compound '
              'under international chemical security protocols (${item.description}). '
              'Computational simulation, reaction planning, and export of this agent are strictly prohibited.',
        );
      }
    }

    // 2. Structural SMILES regex screening
    final compact = input.replaceAll(RegExp(r'\s+'), '');
    for (final rule in _prohibitedSmilesPatterns) {
      if (rule.pattern.hasMatch(compact)) {
        return ChemicalSafetyResult(
          isAllowed: false,
          violationCategory: 'CBRN / Prohibited Structural Scaffold',
          matchedAgent: rule.description,
          complianceMessage:
              'COMPLIANCE BLOCK: Structural screening identified a prohibited chemical scaffold (${rule.description}) '
              'restricted under the Chemical Weapons Convention or DEA Controlled Substances regulations. '
              'Execution halted.',
        );
      }
    }

    return ChemicalSafetyResult.allowed;
  }
}
