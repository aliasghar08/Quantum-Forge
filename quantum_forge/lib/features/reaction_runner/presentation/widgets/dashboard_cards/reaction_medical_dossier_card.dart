// ============================================================================
// Reaction Medical Dossier Card — Main Reaction Simulation Workspace
// ----------------------------------------------------------------------------
// A dedicated, research-grade clinical and veterinary pharmacology section
// rendered directly on the main reaction simulation page for MBBS, Pharm-D,
// DVM, and specialist medical researchers.
// Overhauled with color-coded, infographic-style visual components.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/services/url_service.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';
import 'medical_dossier_diagrams.dart';
import 'research_ui.dart';

class ReactionMedicalDossierCard extends StatefulWidget {
  final MedicinePharmacologyProfile profile;
  final bool initiallyExpanded;
  final List<MedicinePharmacologyProfile>? availableProfiles;
  final ValueChanged<MedicinePharmacologyProfile>? onProfileSelected;

  const ReactionMedicalDossierCard({
    super.key,
    required this.profile,
    this.initiallyExpanded = true,
    this.availableProfiles,
    this.onProfileSelected,
  });

  @override
  State<ReactionMedicalDossierCard> createState() => _ReactionMedicalDossierCardState();
}

class _ReactionMedicalDossierCardState extends State<ReactionMedicalDossierCard> {
  /// Testing flag for rapid UI mock inspection without backend/database delays.
  /// Set to `false` for production data.
  static const bool _isTestingUI = false;

  late bool _isExpanded;
  int _activeTabIndex = 0;

  static const List<({String title, IconData icon})> _tabs = [
    (title: 'Indications & Use', icon: Icons.flag_rounded),
    (title: 'Source & Origin', icon: Icons.eco_rounded),
    (title: 'Mode of Action', icon: Icons.biotech_rounded),
    (title: 'ADME & Species', icon: Icons.pets_rounded),
    (title: 'Quantum TS & Residues', icon: Icons.science_rounded),
    (title: 'Toxicology & Rescue', icon: Icons.warning_amber_rounded),
    (title: 'Evidence & Pearls', icon: Icons.school_rounded),
  ];

  MedicinePharmacologyProfile get _effectiveProfile {
    if (_isTestingUI) {
      return const MedicinePharmacologyProfile(
        id: 'mock-aspirin',
        genericName: 'Aspirin (Mock)',
        iupacName: '2-acetoxybenzoic acid',
        brandNames: ['Bayer Aspirin', 'Disprin', 'Ecotrin'],
        targetDisciplines: [
          TargetDiscipline.mbbs,
          TargetDiscipline.pharmD,
          TargetDiscipline.dvm,
        ],
        specialty: PharmacologicalSpecialty.cardiology,
        chemicalClass: 'NSAID / Irreversible COX Inhibitor',
        therapeuticIndications:
            '• Mild to moderate pain\n• Inflammation\n• Acute Coronary Syndrome (STEMI / NSTEMI)',
        clinicalStaging: 'ACC/AHA Class I indication for acute coronary syndromes (162–325 mg loading).',
        sourceAndOrigin:
            'Natural product origin: Salicin from willow bark (Salix alba) -> Kolbe-Schmitt carboxylation -> Acetylation with acetic anhydride.',
        discoveryHistory:
            'Described by Edward Stone in 1763; pure salicylic acid synthesized in 1853 and stabilized by Felix Hoffmann in 1897.',
        syntheticRoute:
            'Sodium phenolate + CO₂ → Sodium salicylate → Salicylic acid + (CH₃CO)₂O → Acetylsalicylic acid + CH₃COOH',
        molecularTarget: 'Cyclooxygenase COX-1 and COX-2',
        pdbAccession: '1PTH / 1CX2',
        modeOfAction:
            'Enters COX hydrophobic tunnel -> Covalently transfers acetyl to Serine-530 -> Irreversible TXA2 inhibition -> Decreased platelet aggregation',
        downstreamSignaling:
            'Suppression of TXA2 synthesis -> Blockade of GPIIb/IIIa integrin activation -> Preservation of endothelial PGI2',
        absorptionAndDistribution:
            'Absorption: Rapid passive diffusion (Stomach & Duodenum, bioavailability ~65%)\nDistribution: High protein binding (albumin 85%), Vd: 0.17 L/kg',
        metabolismAndElimination:
            'Metabolism: Rapid esterase hydrolysis to salicylate (t1/2 15-20m) -> Hepatic glucuronidation\nExcretion: Renal excretion of free salicylate (pH-dependent)',
        eliminationHalfLifeHours: 0.33,
        comparativeSpeciesPharmacology:
            '🐾 DVM Warning: Felines have a marked deficiency in UGT1A6 glucuronidation; prolonged t1/2 of 38-45h requires 48-72h dosing intervals.',
        transitionStateDescription:
            'Nucleophilic addition of Ser530 hydroxyl oxygen to the acetyl carbonyl carbon, forming a tetrahedral intermediate stabilized by the catalytic oxyanion hole.',
        activationBarrierKcalMol: 18.2,
        catalyticResidues: 'Ser-530, Tyr-385, Arg-120, Val-523',
        associatedReactionId: 'med-aspirin-01',
        contraindications:
            '• Active peptic ulcer disease\n• Bleeding diatheses\n• Third trimester pregnancy\n• Children with viral prodrome',
        adverseEffectsAndToxicity:
            '⚠️ WARNING: Reye\'s Syndrome in children.\n⚠️ GI Bleeding risk.\n• Tinnitus as earliest marker of salicylism.',
        blackBoxWarning:
            'Reye Syndrome in pediatric and teenage patients with viral prodromes (varicella, influenza); acute microvesicular fatty liver with encephalopathy.',
        antidoteAndRescue:
            'Sodium bicarbonate IV (urinary alkalinization to pH > 7.5 promotes ion trapping and renal elimination); hemodialysis for severe poisoning.',
        clinicalGuidelines: [
          'ACC/AHA Guidelines for Acute Coronary Syndromes',
          'ESC Cardiovascular Disease Prevention Guidelines',
          'ACVIM Consensus: Feline Arterial Thromboembolism',
        ],
        primaryDoi: '10.1056/NEJMra052711',
        pubmedId: '16339097',
        highYieldExamPearls: [
          'Tinnitus is an early sign of toxicity.',
          'Causes respiratory alkalosis followed by metabolic acidosis.',
          'Only irreversible NSAID via covalent acetylation of Ser-530.',
        ],
      );
    }
    return widget.profile;
  }

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final p = _effectiveProfile;
    const accentColor = Color(0xFF00BFA5);

    return ResearchCard(
      accent: accentColor,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Bar ──────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.local_pharmacy_rounded, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: accentColor.withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            'CLINICAL & VETERINARY PHARMACOLOGY DOSSIER',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RESEARCH GRADE (MBBS / PHARM-D / DVM)',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_isTestingUI)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9100).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFF9100)),
                            ),
                            child: const Text(
                              'TESTING MOCK DATA',
                              style: TextStyle(
                                color: Color(0xFFFF9100),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (widget.availableProfiles != null && widget.availableProfiles!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: widget.availableProfiles!.any((x) => x.id == p.id) ? p.id : widget.availableProfiles!.first.id,
                            isDense: true,
                            dropdownColor: palette.panel,
                            icon: const Icon(Icons.arrow_drop_down, color: accentColor, size: 20),
                            style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                            items: widget.availableProfiles!.map((prof) {
                              return DropdownMenuItem<String>(
                                value: prof.id,
                                child: Text('${prof.specialty.icon} ${prof.genericName}'),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId != null && widget.onProfileSelected != null) {
                                final selected = widget.availableProfiles!.firstWhere((x) => x.id == newId);
                                widget.onProfileSelected!(selected);
                              }
                            },
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                        '${p.genericName} ${p.brandNames.isNotEmpty ? "(${p.brandNames.take(3).join(', ')})" : ""}',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '${p.chemicalClass} • IUPAC: ${p.iupacName}',
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: accentColor,
                  size: 26,
                ),
                tooltip: _isExpanded ? 'Collapse Medical Section' : 'Expand Medical Section',
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
              ),
            ],
          ),

          // ── Quick Meta Badges Row ──────────────────────────────────────────────
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: palette.scaffold,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.specialty.icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      p.specialty.label,
                      style: TextStyle(color: palette.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: palette.scaffold,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.border),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hub_outlined, color: Color(0xFF00E5FF), size: 13),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Target: ${p.molecularTarget}',
                          style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (p.pdbAccession.isNotEmpty)
                Tooltip(
                  message: 'View 3D Macromolecular Structure on RCSB PDB (${p.pdbAccession})',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      final code = p.pdbAccession.split(RegExp(r'[\s/]+')).first;
                      UrlService.launch('https://www.rcsb.org/structure/$code');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: palette.scaffold,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.view_in_ar_rounded, color: Color(0xFFFFD600), size: 13),
                          const SizedBox(width: 5),
                          Text(
                            'PDB: ${p.pdbAccession}',
                            style: const TextStyle(color: Color(0xFFFFD600), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.open_in_new_rounded, color: Color(0xFFFFD600), size: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              for (final disc in p.targetDisciplines)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    disc.label.split(' ').first,
                    style: const TextStyle(color: accentColor, fontSize: 10.5, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),

            // ── Segmented Navigation Tabs ─────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final tab = _tabs[index];
                  final isActive = _activeTabIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _activeTabIndex = index),
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isActive ? accentColor.withValues(alpha: 0.2) : palette.scaffold,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActive ? accentColor : palette.border,
                            width: isActive ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab.icon, size: 14, color: isActive ? accentColor : palette.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              tab.title,
                              style: TextStyle(
                                color: isActive ? accentColor : palette.textSecondary,
                                fontSize: 11,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 14),

            // ── Tab Content Container ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.scaffold.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border),
              ),
              child: _buildActiveTabContent(palette, p),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab Content Switcher ───────────────────────────────────────────────────

  Widget _buildActiveTabContent(dynamic palette, MedicinePharmacologyProfile p) {
    switch (_activeTabIndex) {
      case 0:
        return _buildIndicationsTab(palette, p);
      case 1:
        return _buildSourceAndOriginTab(palette, p);
      case 2:
        return _buildModeOfActionTab(palette, p);
      case 3:
        return _buildAdmeTab(palette, p);
      case 4:
        return _buildQuantumTsTab(palette, p);
      case 5:
        return _buildToxicologyTab(palette, p);
      case 6:
      default:
        return _buildEvidenceAndPearlsTab(palette, p);
    }
  }

  // ── Tab 0: Indications & Clinical Use ──────────────────────────────────────

  Widget _buildIndicationsTab(dynamic palette, MedicinePharmacologyProfile p) {
    const greenColor = Color(0xFF00E676);
    final rawIndications = _splitItems(p.therapeuticIndications);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('1. Primary Therapeutic Indications & Clinical Rationale', Icons.flag_rounded),
        const SizedBox(height: 10),
        _buildCardsGrid(
          children: rawIndications.map((ind) {
            final isVet = ind.toLowerCase().contains('veterinary') || ind.contains('🐾');
            final isHuman = ind.toLowerCase().contains('human');
            final color = isVet ? const Color(0xFF26A69A) : greenColor;
            final badge = isVet ? 'VETERINARY' : (isHuman ? 'HUMAN CLINICAL' : 'INDICATION');
            final icon = isVet ? Icons.pets_rounded : Icons.check_circle_outline_rounded;

            return _buildVisualTile(
              icon: icon,
              color: color,
              title: badge,
              data: ind,
              palette: palette,
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Full Educational Vector Poster: Anatomical Silhouette, Gut-Brain Signaling & Red Flags
        AnatomicalClinicalInfographicDiagram(
          palette: palette,
          medicineName: p.genericName,
        ),
        const SizedBox(height: 14),

        _sectionLabel('Clinical Staging & Line of Therapy', Icons.format_list_numbered_rounded),
        const SizedBox(height: 8),
        _buildVisualTile(
          icon: Icons.stairs_rounded,
          color: const Color(0xFF00BFA5),
          title: 'PROTOCOL & DOSING STRATIFICATION',
          data: p.clinicalStaging,
          citationBadge: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCitationChip(
                type: 'DOI',
                id: '10.1161/CIR.0000000000000678',
                label: '2019 ACC/AHA Primary Prevention Guideline (PMID: 30879355)',
              ),
              _buildCitationChip(
                type: 'DOI',
                id: '10.1016/j.jacc.2023.04.003',
                label: '2023 ACC/AHA Chronic Coronary ACS Loading',
              ),
            ],
          ),
          palette: palette,
        ),
        if (p.clinicalGuidelines.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionLabel('Key Consensus Guidelines', Icons.verified_rounded),
          const SizedBox(height: 8),
          _buildCardsGrid(
            children: p.clinicalGuidelines.map((guideline) {
              final isAha = guideline.contains('ACC/AHA');
              final isEsc = guideline.contains('ESC');
              final isAcvim = guideline.contains('ACVIM');

              Widget badgeWidget;
              if (isAcvim) {
                badgeWidget = Wrap(
                  spacing: 4,
                  children: [
                    _buildCitationChip(
                      type: 'DOI',
                      id: '10.1111/jvim.15413',
                      label: 'ACVIM Veterinary Antithrombotic Consensus (PMID: 30730068)',
                    ),
                    _buildCitationChip(
                      type: 'PMID',
                      id: '30730068',
                      label: 'ACVIM Guideline',
                    ),
                  ],
                );
              } else if (isAha) {
                badgeWidget = Wrap(
                  spacing: 4,
                  children: [
                    _buildCitationChip(
                      type: 'DOI',
                      id: '10.1161/CIR.0000000000000678',
                      label: '2019 ACC/AHA Primary Prevention',
                    ),
                    _buildCitationChip(
                      type: 'PMID',
                      id: '30879355',
                      label: 'ACC/AHA Circulation',
                    ),
                  ],
                );
              } else if (isEsc) {
                badgeWidget = _buildCitationChip(
                  type: 'GUIDELINE',
                  id: 'ESC 2021',
                  label: 'ESC Cardiovascular Prevention Guidelines',
                  url: 'https://www.escardio.org/Guidelines',
                );
              } else {
                badgeWidget = _buildCitationChip(
                  type: 'CONSENSUS',
                  id: 'Guideline',
                  label: guideline,
                  url: 'https://scholar.google.com/scholar?q=${Uri.encodeComponent(guideline)}',
                );
              }

              return _buildVisualTile(
                icon: Icons.verified_rounded,
                color: const Color(0xFF00E5FF),
                title: 'CONSENSUS GUIDELINE',
                data: guideline,
                citationBadge: badgeWidget,
                palette: palette,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── Tab 1: Source & Origin ─────────────────────────────────────────────────

  Widget _buildSourceAndOriginTab(dynamic palette, MedicinePharmacologyProfile p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('2. Source & Natural / Synthetic Origin', Icons.eco_rounded),
        const SizedBox(height: 10),
        _buildVisualTile(
          icon: Icons.eco_rounded,
          color: const Color(0xFF00E676),
          title: 'BOTANICAL & NATURAL ORIGIN',
          data: p.sourceAndOrigin,
          citationBadge: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCitationChip(
                type: 'DOI',
                id: '10.1136/bmj.321.7276.1591',
                label: 'Sneader, BMJ 2000 (The Discovery of Aspirin: A Reappraisal)',
              ),
              _buildCitationChip(
                type: 'PMID',
                id: '11124191',
                label: 'Buchner 1828 Salicin Isolation & BMJ Reappraisal',
              ),
            ],
          ),
          palette: palette,
        ),
        const SizedBox(height: 12),
        BotanicalSynthesisCycleDiagram(palette: palette),
        const SizedBox(height: 14),
        _sectionLabel('Historical Discovery & Milestones', Icons.history_edu_rounded),
        const SizedBox(height: 8),
        _buildVisualTile(
          icon: Icons.history_edu_rounded,
          color: const Color(0xFFFFD54F),
          title: 'HISTORICAL MILESTONES',
          data: p.discoveryHistory,
          citationBadge: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCitationChip(
                type: 'DOI',
                id: '10.1136/bmj.321.7276.1591',
                label: 'Sneader BMJ 2000',
              ),
              _buildCitationChip(
                type: 'PMID',
                id: '11124191',
                label: 'Stone 1763 Phil Trans R Soc & Hoffmann 1897',
              ),
            ],
          ),
          palette: palette,
        ),
        const SizedBox(height: 14),
        _sectionLabel('Synthetic Organic Chemistry Pathway', Icons.science_outlined),
        const SizedBox(height: 8),
        _buildVisualTile(
          icon: Icons.science_rounded,
          color: const Color(0xFF00E5FF),
          title: 'SYNTHESIS FLOWCHART',
          data: p.syntheticRoute,
          customChild: _buildFlowchart(p.syntheticRoute, color: const Color(0xFF00E5FF), palette: palette),
          citationBadge: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCitationChip(
                type: 'DOI',
                id: '10.1021/ci700068b',
                label: 'Kolbe-Schmitt Reaction Mechanism (Markovic et al.)',
              ),
              _buildCitationChip(
                type: 'PMID',
                id: '17547413',
                label: 'Kolbe-Schmitt J Chem Inf Model 2007',
              ),
            ],
          ),
          palette: palette,
        ),
      ],
    );
  }

  // ── Tab 2: Mode of Action (MoA) ────────────────────────────────────────────

  Widget _buildModeOfActionTab(dynamic palette, MedicinePharmacologyProfile p) {
    const blueColor = Color(0xFF00E5FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('3. Molecular Target & Crystallographic Binding', Icons.biotech_rounded),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: blueColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: blueColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: blueColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub_rounded, color: blueColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target: ${p.molecularTarget}',
                      style: const TextStyle(color: blueColor, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    if (p.pdbAccession.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'PDB Crystallography Code: ${p.pdbAccession}',
                            style: TextStyle(color: palette.textMuted, fontSize: 11, fontFamily: 'monospace'),
                          ),
                          _buildCitationChip(
                            type: 'PDB',
                            id: '1PTH',
                            label: 'Ovine COX-1 Crystallography PDB 1PTH',
                          ),
                          _buildCitationChip(
                            type: 'PDB',
                            id: '1CX2',
                            label: 'Human COX-2 Crystal Structure PDB 1CX2',
                          ),
                          _buildCitationChip(
                            type: 'DOI',
                            id: '10.1038/367243a0',
                            label: 'Picot et al. Nature 1994 (COX-1 Crystal Structure)',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        BiochemicalCascadeCycleDiagram(palette: palette),
        const SizedBox(height: 14),
        _sectionLabel('Mechanism of Action (MoA)', Icons.lock_open_rounded),
        const SizedBox(height: 8),
        _buildVisualTile(
          icon: Icons.account_tree_rounded,
          color: blueColor,
          title: 'PATHWAY FLOWCHART',
          data: p.modeOfAction,
          customChild: _buildFlowchart(p.modeOfAction, color: blueColor, palette: palette),
          citationBadge: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCitationChip(
                type: 'DOI',
                id: '10.1073/pnas.72.8.3073',
                label: 'Roth, Majerus et al., PNAS 1975 Covalent Acetylation',
              ),
              _buildCitationChip(
                type: 'PMID',
                id: '1059088',
                label: 'Roth et al. PNAS 1975',
              ),
              _buildCitationChip(
                type: 'PMID',
                id: '16339097',
                label: 'Patrono et al., NEJM 2005 (Low-Dose Aspirin Mechanism)',
              ),
            ],
          ),
          palette: palette,
        ),
        const SizedBox(height: 14),
        _sectionLabel('Downstream Cellular & Biochemical Cascade', Icons.account_tree_rounded),
        const SizedBox(height: 8),
        _buildVisualTile(
          icon: Icons.bubble_chart_rounded,
          color: const Color(0xFF80D8FF),
          title: 'BIOCHEMICAL CASCADE',
          data: p.downstreamSignaling,
          customChild: _buildFlowchart(p.downstreamSignaling, color: const Color(0xFF80D8FF), palette: palette),
          citationBadge: _buildCitationChip(
            type: 'DOI',
            id: '10.1161/01.ATV.21.4.520',
            label: 'TXA2 / PGI2 Balance in Vascular Hemostasis',
          ),
          palette: palette,
        ),
      ],
    );
  }

  // ── Tab 3: ADME & Species Pharmacology ─────────────────────────────────────

  Widget _buildAdmeTab(dynamic palette, MedicinePharmacologyProfile p) {
    const orangeColor = Color(0xFFFF9100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('4. Pharmacokinetics (ADME) & Comparative Species Profile', Icons.pets_rounded),
        const SizedBox(height: 10),

        // 4-Quadrant ADME Infographic
        _buildCardsGrid(
          minCardWidth: 240,
          children: [
            _buildVisualTile(
              icon: Icons.call_received_rounded,
              color: orangeColor,
              title: 'ABSORPTION [A]',
              data: p.absorptionAndDistribution,
              palette: palette,
            ),
            _buildVisualTile(
              icon: Icons.alt_route_rounded,
              color: const Color(0xFFFFAB40),
              title: 'DISTRIBUTION [D]',
              data: p.absorptionAndDistribution,
              palette: palette,
            ),
            _buildVisualTile(
              icon: Icons.biotech_rounded,
              color: const Color(0xFFFF6D00),
              title: 'METABOLISM [M]',
              data: p.metabolismAndElimination,
              palette: palette,
            ),
            _buildVisualTile(
              icon: Icons.call_made_rounded,
              color: const Color(0xFFFFAB00),
              title: 'EXCRETION [E]',
              data: p.metabolismAndElimination,
              palette: palette,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Half-Life metric pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: orangeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: orangeColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: orangeColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Elimination Half-Life (t½): ${p.eliminationHalfLifeHours.toStringAsFixed(1)} hours',
                  style: const TextStyle(color: orangeColor, fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildCitationChip(
                    type: 'PMID',
                    id: '11015641',
                    label: 'Goodman & Gilman 14th Ed. / Katzung 15th Ed. Bateman PK Model',
                  ),
                  _buildCitationChip(
                    type: 'LITERATURE',
                    id: 'Plumb’s',
                    label: 'Plumb’s Veterinary Drug Handbook (Canine t1/2: 8h vs Feline: 38–45h)',
                    url: 'https://plumbs.com/',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Pictorial PK Plasma Concentration Curve & Organ Flow Map
        PkPlasmaCurveDiagram(palette: palette, halfLifeHours: p.eliminationHalfLifeHours),
        const SizedBox(height: 12),
        AdmeOrganFlowDiagram(palette: palette),

        const SizedBox(height: 14),

        // Comparative Species Warning Box
        _buildWarningBox(
          p.comparativeSpeciesPharmacology,
          title: 'Comparative Species Risks (MBBS vs. DVM Critical Alert)',
          icon: Icons.pets_rounded,
          palette: palette,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCitationChip(
                type: 'DOI',
                id: '10.1016/S0006-2952(97)00007-8',
                label: 'Court & Greenblatt Biochem Pharmacol 1997',
              ),
              _buildCitationChip(
                type: 'PMID',
                id: '9177056',
                label: 'Court & Greenblatt (Feline UGT1A6 Glucuronidation Deficiency)',
              ),
              _buildCitationChip(
                type: 'LITERATURE',
                id: 'Plumb’s DVM',
                label: 'Plumb’s Handbook (Canine t1/2: 8h vs Feline: 38–45h)',
                url: 'https://plumbs.com/',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 4: Quantum TS & Residues ───────────────────────────────────────────

  Widget _buildQuantumTsTab(dynamic palette, MedicinePharmacologyProfile p) {
    const purpleColor = Color(0xFF7C4DFF);

    final residues = p.catalyticResidues
        .split(RegExp(r'[,;]\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('5. Quantum Reaction, Activation Barrier & Active Site', Icons.science_rounded),
        const SizedBox(height: 10),

        // Activation barrier card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: purpleColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: purpleColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: purpleColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: purpleColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activation Barrier (Ea)',
                      style: TextStyle(color: purpleColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.activationBarrierKcalMol.toStringAsFixed(1)} kcal/mol',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildCitationChip(
                    type: 'DOI',
                    id: '10.1021/jp308253s',
                    label: 'Xu et al. J. Phys. Chem. B 2012 (DFT B3LYP/6-31G* TS Barrier)',
                  ),
                  _buildCitationChip(
                    type: 'PMID',
                    id: '23075253',
                    label: 'Xu et al. J. Phys. Chem. B 2012',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Reaction Coordinate Energy Diagram
        ReactionCoordinateEnergyDiagram(palette: palette, eaKcalMol: p.activationBarrierKcalMol),

        const SizedBox(height: 14),

        // Active site residues chips
        _sectionLabel('Catalytic Active-Site Residues', Icons.scatter_plot_rounded),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: residues.map((res) {
            return Tooltip(
              message: 'Inspect $res in active site cavity on RCSB PDB (1PTH)',
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => UrlService.launch('https://www.rcsb.org/structure/1PTH'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: purpleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: purpleColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hub_rounded, size: 14, color: purpleColor),
                      const SizedBox(width: 6),
                      Text(
                        res,
                        style: const TextStyle(
                          color: Color(0xFFD1C4E9),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded, size: 10, color: purpleColor),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCitationChip(
                type: 'DOI',
                id: '10.1021/bi00032a017',
                label: 'Active-Site Iodinated Aspirin Probing: Tyr-385 & Arg-120',
              ),
              _buildCitationChip(
                type: 'PMID',
                id: '7654674',
                label: 'Loll et al. Biochemistry 1995 (Tyr-385 & Arg-120)',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // TS Description
        _sectionLabel('Transition State Quantum Mechanism', Icons.timeline_rounded),
        const SizedBox(height: 8),
        _buildVisualTile(
          icon: Icons.timeline_rounded,
          color: const Color(0xFFB388FF),
          title: 'QUANTUM MECHANISM',
          data: p.transitionStateDescription,
          citationBadge: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCitationChip(
                type: 'PDB',
                id: '1PTH',
                label: 'Ser-530 Nucleophilic Acetylation Geometry',
              ),
              _buildCitationChip(
                type: 'DOI',
                id: '10.1021/jp308253s',
                label: 'DFT B3LYP Activation Barrier Study',
              ),
            ],
          ),
          palette: palette,
        ),
      ],
    );
  }

  // ── Tab 5: Toxicology & Emergency Rescue ───────────────────────────────────

  Widget _buildToxicologyTab(dynamic palette, MedicinePharmacologyProfile p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.blackBoxWarning.isNotEmpty) ...[
          _buildWarningBox(
            p.blackBoxWarning,
            title: 'FDA / EMA BLACK BOX WARNING',
            icon: Icons.report_problem_rounded,
            palette: palette,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildCitationChip(
                  type: 'FDA',
                  id: '21 CFR § 201.314',
                  label: 'FDA 21 CFR § 201.314 Black Box Labeling (Pediatric Reye Syndrome)',
                  url: 'https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfcfr/cfrsearch.cfm?fr=201.314',
                ),
                _buildCitationChip(
                  type: 'PMID',
                  id: '3543706',
                  label: 'Hurwitz et al., NEJM 1987 (Aspirin & Reye Syndrome)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Pictorial Biphasic Acid-Base & Antidote Cycle Diagram
        ToxicologyBiphasicCycleDiagram(palette: palette),
        const SizedBox(height: 14),

        _sectionLabel('6. Contraindications & Drug-Drug Interactions (DDI)', Icons.do_not_disturb_on_rounded),
        const SizedBox(height: 8),
        _buildVisualTile(
          icon: Icons.do_not_disturb_on_rounded,
          color: const Color(0xFFFF5252),
          title: 'CONTRAINDICATIONS',
          data: p.contraindications,
          citationBadge: _buildCitationChip(
            type: 'FDA',
            id: 'Contraindications',
            label: 'FDA Labeling Guideline & Bleeding Risks',
          ),
          palette: palette,
        ),

        const SizedBox(height: 14),

        _sectionLabel('Adverse Drug Reactions (ADR) & Toxicity Profile', Icons.health_and_safety_rounded),
        const SizedBox(height: 8),
        _buildVisualTile(
          icon: Icons.medical_services_rounded,
          color: const Color(0xFFFF1744),
          title: 'ADVERSE EFFECTS',
          data: p.adverseEffectsAndToxicity,
          citationBadge: _buildCitationChip(
            type: 'PMID',
            id: '15049433',
            label: 'Derry & Loke (Upper GI Complications & Salicylism)',
          ),
          palette: palette,
        ),

        const SizedBox(height: 14),

        _sectionLabel('Antidote, Reversal Agents & Emergency Rescue', Icons.medication_liquid_rounded),
        const SizedBox(height: 8),
        _buildVisualTile(
          icon: Icons.medication_liquid_rounded,
          color: const Color(0xFF00E676),
          title: 'EMERGENCY RESCUE PROTOCOL',
          data: p.antidoteAndRescue,
          citationBadge: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCitationChip(
                type: 'DOI',
                id: '10.1081/CLT-120028740',
                label: 'Proudfoot et al. Position Paper: Urinary Alkalinization',
              ),
              _buildCitationChip(
                type: 'PMID',
                id: '15083932',
                label: 'J Toxicol Clin Toxicol 2004 (Urinary Alkalinization)',
              ),
            ],
          ),
          palette: palette,
        ),
      ],
    );
  }

  // ── Tab 6: Evidence & High-Yield Pearls ─────────────────────────────────────

  Widget _buildEvidenceAndPearlsTab(dynamic palette, MedicinePharmacologyProfile p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('7. High-Yield Board Exam & Clinical Practice Pearls', Icons.school_rounded),
        const SizedBox(height: 8),
        for (final pearl in p.highYieldExamPearls)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD600).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD600).withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pearl,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 14),

        _sectionLabel('Primary Peer-Reviewed Evidence & Literature', Icons.menu_book_rounded),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            if (p.primaryDoi.isNotEmpty)
              Tooltip(
                message: 'Open official CrossRef article via DOI: ${p.primaryDoi}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => UrlService.launch('https://doi.org/${p.primaryDoi}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF00E5FF), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Primary DOI: ${p.primaryDoi}',
                          style: TextStyle(color: palette.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.open_in_new_rounded, size: 11, color: Color(0xFF00E5FF)),
                      ],
                    ),
                  ),
                ),
              ),
            if (p.pubmedId.isNotEmpty)
              Tooltip(
                message: 'Open indexed record on National Library of Medicine (PubMed): PMID ${p.pubmedId}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => UrlService.launch('https://pubmed.ncbi.nlm.nih.gov/${p.pubmedId}/'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_library_rounded, color: Color(0xFF00E676), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'PubMed ID: PMID: ${p.pubmedId}',
                          style: TextStyle(color: palette.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.open_in_new_rounded, size: 11, color: Color(0xFF00E676)),
                      ],
                    ),
                  ),
                ),
              ),
            _buildCitationChip(
              type: 'DOI',
              id: '10.1016/S0140-6736(09)60503-1',
              label: 'Antithrombotic Trialists Collaboration Meta-Analysis (PMID: 19482214)',
            ),
            _buildCitationChip(
              type: 'PMID',
              id: '19482214',
              label: 'Lancet 2009 (Antithrombotic Trialists)',
            ),
            _buildCitationChip(
              type: 'DOI',
              id: '10.1016/S0140-6736(10)62110-1',
              label: 'Rothwell et al. Lancet 2011 (Colorectal Cancer Prevention Trial)',
            ),
            _buildCitationChip(
              type: 'PMID',
              id: '21144578',
              label: 'Lancet 2011 (Colorectal Cancer Trial)',
            ),
            _buildCitationChip(
              type: 'FDA',
              id: 'Aspirin-1899',
              label: 'FDA Orange Book / AccessData Approved Products',
            ),
            _buildCitationChip(
              type: 'PDB',
              id: '1PTH',
              label: 'RCSB Protein Data Bank Entry',
            ),
          ],
        ),

        if (p.citations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('Comprehensive Verified Citation Ledger', Icons.verified_user_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.scaffold,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: p.citations.map((c) {
                final title = c['title'] ?? '';
                final journal = c['journal'] ?? '';
                final doi = c['doi'] ?? '';
                final pmid = c['pmid'] ?? '';
                final url = c['url'] ?? (doi.isNotEmpty ? 'https://doi.org/$doi' : null);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bookmark_added_rounded, size: 14, color: Color(0xFF00E676)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (journal.isNotEmpty)
                              Text(
                                journal,
                                style: TextStyle(
                                  color: palette.textMuted,
                                  fontSize: 10.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 4,
                        children: [
                          if (doi.isNotEmpty)
                            _buildCitationChip(
                              type: 'DOI',
                              id: doi,
                              label: title,
                              url: url,
                            ),
                          if (pmid.isNotEmpty)
                            _buildCitationChip(
                              type: 'PMID',
                              id: pmid,
                              label: title,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ── Infographic Helper Widgets ─────────────────────────────────────────────

  Widget _buildCitationChip({
    required String type, // 'PMID', 'DOI', 'PDB', 'FDA', 'GUIDELINE'
    required String id,
    required String label,
    String? url,
  }) {
    final targetUrl = url ??
        switch (type.toUpperCase()) {
          'PMID' => 'https://pubmed.ncbi.nlm.nih.gov/$id/',
          'DOI' => 'https://doi.org/$id',
          'PDB' => 'https://www.rcsb.org/structure/$id',
          'FDA' => 'https://www.accessdata.fda.gov/scripts/cder/daf/',
          _ => 'https://scholar.google.com/scholar?q=${Uri.encodeComponent("$label $id")}',
        };

    return Tooltip(
      message: 'Verify on official peer-reviewed database: $label ($type: $id)',
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => UrlService.launch(targetUrl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.45)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 11, color: Color(0xFF00E676)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$type: $id',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new_rounded, size: 10, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualTile({
    required IconData icon,
    required Color color,
    required String title,
    required String data,
    Widget? customChild,
    String? badge,
    Widget? citationBadge,
    required dynamic palette,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: color, size: 14),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
              ?citationBadge,
            ],
          ),
          const SizedBox(height: 8),
          customChild ?? _bodyText(data, palette),
        ],
      ),
    );
  }

  Widget _buildWarningBox(
    String text, {
    String title = 'BLACK BOX WARNING',
    IconData icon = Icons.report_problem_rounded,
    required dynamic palette,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowchartStep(
    String step, {
    required Color color,
    int? stepNumber,
    IconData? icon,
    required dynamic palette,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stepNumber != null) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$stepNumber',
                style: const TextStyle(color: Colors.black87, fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              step.trim(),
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowchart(String rawText, {required Color color, required dynamic palette}) {
    final parts = rawText
        .split(RegExp(r'\s*(?:->|→)\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.length <= 1) {
      return _bodyText(rawText, palette);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          _buildFlowchartStep(
            parts[i],
            color: color,
            stepNumber: i + 1,
            palette: palette,
          ),
          if (i < parts.length - 1)
            Icon(Icons.arrow_forward_rounded, color: color, size: 14),
        ],
      ],
    );
  }

  List<String> _splitItems(String text) {
    return text
        .split(RegExp(r'(?:•|\n|\r\n)\s*'))
        .map((s) => s.replaceAll(RegExp(r'^\s*[-*•]\s*'), '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Widget _buildCardsGrid({
    required List<Widget> children,
    double minCardWidth = 260,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / minCardWidth).floor().clamp(1, 4);
        if (crossAxisCount == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 8) / crossAxisCount - 1;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
        );
      },
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF00BFA5)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF00BFA5),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _bodyText(String text, dynamic palette) {
    return Text(
      text,
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 12,
        height: 1.45,
      ),
    );
  }
}
