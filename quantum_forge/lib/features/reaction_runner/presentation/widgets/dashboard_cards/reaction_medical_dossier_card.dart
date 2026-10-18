// ============================================================================
// Reaction Medical Dossier Card — Main Reaction Simulation Workspace
// ----------------------------------------------------------------------------
// A dedicated, research-grade clinical and veterinary pharmacology section
// rendered directly on the main reaction simulation page for MBBS, Pharm-D,
// DVM, and specialist medical researchers.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';
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

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final p = widget.profile;
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
                      const Icon(Icons.view_in_ar_rounded, color: Color(0xFFFFD600), size: 13),
                      const SizedBox(width: 5),
                      Text(
                        'PDB: ${p.pdbAccession}',
                        style: const TextStyle(color: Color(0xFFFFD600), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700),
                      ),
                    ],
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

  Widget _buildActiveTabContent(dynamic palette, MedicinePharmacologyProfile p) {
    switch (_activeTabIndex) {
      case 0: // Indications & Use
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('1. Primary Therapeutic Indications & Clinical Rationale', Icons.flag_rounded),
            const SizedBox(height: 6),
            _bodyText(p.therapeuticIndications, palette),
            const SizedBox(height: 14),
            _sectionLabel('Clinical Staging & Line of Therapy', Icons.format_list_numbered_rounded),
            const SizedBox(height: 6),
            _bodyText(p.clinicalStaging, palette),
            if (p.clinicalGuidelines.isNotEmpty) ...[
              const SizedBox(height: 14),
              _sectionLabel('Key Consensus Guidelines', Icons.verified_rounded),
              const SizedBox(height: 6),
              for (final g in p.clinicalGuidelines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Color(0xFF00BFA5), fontSize: 14, fontWeight: FontWeight.bold)),
                      Expanded(child: _bodyText(g, palette)),
                    ],
                  ),
                ),
            ],
          ],
        );

      case 1: // Source & Origin
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('2. Source & Natural / Synthetic Origin', Icons.eco_rounded),
            const SizedBox(height: 6),
            _bodyText(p.sourceAndOrigin, palette),
            const SizedBox(height: 14),
            _sectionLabel('Historical Discovery & Milestones', Icons.history_edu_rounded),
            const SizedBox(height: 6),
            _bodyText(p.discoveryHistory, palette),
            const SizedBox(height: 14),
            _sectionLabel('Synthetic Organic Chemistry Pathway', Icons.science_outlined),
            const SizedBox(height: 6),
            _bodyText(p.syntheticRoute, palette),
          ],
        );

      case 2: // Mode of Action
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('3. Molecular Target & Crystallographic Binding', Icons.biotech_rounded),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hub_rounded, color: Color(0xFF00E5FF), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Target: ${p.molecularTarget} (PDB: ${p.pdbAccession})',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionLabel('Mechanism of Action (MoA)', Icons.lock_open_rounded),
            const SizedBox(height: 6),
            _bodyText(p.modeOfAction, palette),
            const SizedBox(height: 14),
            _sectionLabel('Downstream Cellular & Biochemical Cascade', Icons.account_tree_rounded),
            const SizedBox(height: 6),
            _bodyText(p.downstreamSignaling, palette),
          ],
        );

      case 3: // ADME & Species Pharmacology
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('4. Pharmacokinetics (ADME) & Comparative Species Profile', Icons.pets_rounded),
            const SizedBox(height: 6),
            _keyValRow('Absorption & Distribution', p.absorptionAndDistribution, palette),
            const SizedBox(height: 8),
            _keyValRow('Metabolism & Elimination', p.metabolismAndElimination, palette),
            const SizedBox(height: 8),
            _keyValRow('Elimination Half-Life (t½)', '${p.eliminationHalfLifeHours.toStringAsFixed(1)} hours', palette),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9100).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF9100).withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9100), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Comparative Species Risks (MBBS vs. DVM Critical Alert)',
                        style: TextStyle(color: Color(0xFFFF9100), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.comparativeSpeciesPharmacology,
                    style: TextStyle(color: palette.textPrimary, fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        );

      case 4: // Quantum TS & Residues
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('5. Quantum Reaction, Activation Barrier & Active Site', Icons.science_rounded),
            const SizedBox(height: 6),
            _keyValRow('Activation Barrier (Ea)', '${p.activationBarrierKcalMol.toStringAsFixed(1)} kcal/mol', palette),
            const SizedBox(height: 8),
            _keyValRow('Catalytic Active-Site Residues', p.catalyticResidues, palette),
            const SizedBox(height: 14),
            _sectionLabel('Transition State Quantum Mechanism', Icons.timeline_rounded),
            const SizedBox(height: 6),
            _bodyText(p.transitionStateDescription, palette),
          ],
        );

      case 5: // Toxicology & Rescue
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.blackBoxWarning.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'FDA / EMA BLACK BOX WARNING',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.blackBoxWarning,
                      style: TextStyle(color: palette.textPrimary, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            _sectionLabel('6. Contraindications & Drug-Drug Interactions (DDI)', Icons.do_not_disturb_on_rounded),
            const SizedBox(height: 6),
            _bodyText(p.contraindications, palette),
            const SizedBox(height: 14),
            _sectionLabel('Adverse Drug Reactions (ADR) & Toxicity Profile', Icons.health_and_safety_rounded),
            const SizedBox(height: 6),
            _bodyText(p.adverseEffectsAndToxicity, palette),
            const SizedBox(height: 14),
            _sectionLabel('Antidote, Reversal Agents & Emergency Rescue', Icons.medication_liquid_rounded),
            const SizedBox(height: 6),
            _bodyText(p.antidoteAndRescue, palette),
          ],
        );

      case 6: // Evidence & Pearls
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('7. High-Yield Board Exam & Clinical Practice Pearls', Icons.school_rounded),
            const SizedBox(height: 8),
            for (final pearl in p.highYieldExamPearls)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: _bodyText(pearl, palette)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            _sectionLabel('Primary Peer-Reviewed Evidence & Literature', Icons.menu_book_rounded),
            const SizedBox(height: 6),
            if (p.primaryDoi.isNotEmpty)
              _keyValRow('Primary DOI', p.primaryDoi, palette),
            if (p.pubmedId.isNotEmpty)
              _keyValRow('PubMed ID', 'PMID: ${p.pubmedId}', palette),
          ],
        );
    }
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
        fontSize: 12.5,
        height: 1.5,
      ),
    );
  }

  Widget _keyValRow(String label, String value, dynamic palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 12, height: 1.45, color: palette.textPrimary),
          children: [
            TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.w700, color: palette.textMuted)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
