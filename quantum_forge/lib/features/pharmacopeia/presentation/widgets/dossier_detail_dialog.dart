import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/quantum_theme.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';

/// Modal dialog displaying full clinical pharmacology monograph details.
class DossierDetailDialog extends StatelessWidget {
  final MedicinePharmacologyProfile profile;
  final QuantumTheme palette;
  final void Function(String reactionId)? onLoadReaction;

  const DossierDetailDialog({
    super.key,
    required this.profile,
    required this.palette,
    this.onLoadReaction,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.85).clamp(500.0, 950.0);
    final dialogHeight = (screenSize.height * 0.85).clamp(400.0, 800.0);

    return Dialog(
      backgroundColor: palette.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.border),
      ),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: DefaultTabController(
          length: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.scaffold.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  border: Border(bottom: BorderSide(color: palette.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              Text(
                                profile.genericName,
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF00BFA5)),
                                ),
                                child: Text(
                                  profile.specialty.label,
                                  style: const TextStyle(
                                    color: Color(0xFF00BFA5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'IUPAC: ${profile.iupacName}',
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Brands: ${profile.brandNames.join(", ")} | Target: ${profile.molecularTarget} (PDB: ${profile.pdbAccession})',
                            style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: palette.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // TabBar
              TabBar(
                isScrollable: true,
                labelColor: const Color(0xFF00BFA5),
                unselectedLabelColor: palette.textMuted,
                indicatorColor: const Color(0xFF00BFA5),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: '🩺 Indications & Use'),
                  Tab(text: '🌿 Origin & Source'),
                  Tab(text: '🧬 Mode of Action (MoA)'),
                  Tab(text: '🐾 Comparative ADME'),
                  Tab(text: '⚛️ Quantum Transition State'),
                  Tab(text: '⚠️ Toxicology & Warnings'),
                  Tab(text: '📚 Evidence & Pearls'),
                ],
              ),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildIndicationsTab(),
                    _buildOriginTab(),
                    _buildMoaTab(),
                    _buildAdmeTab(),
                    _buildQuantumTab(context),
                    _buildToxicologyTab(),
                    _buildEvidenceTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionBlock({
    required String title,
    required String content,
    IconData? icon,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.scaffold.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color ?? const Color(0xFF00BFA5)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color ?? const Color(0xFF00BFA5),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            content,
            style: TextStyle(color: palette.textSecondary, fontSize: 12.5, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicationsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionBlock(
          title: 'Therapeutic Indications & Clinical Use Cases',
          content: profile.therapeuticIndications,
          icon: Icons.healing_outlined,
          color: const Color(0xFF00E5FF),
        ),
        _buildSectionBlock(
          title: 'Clinical Practice Staging & Guideline Protocols',
          content: profile.clinicalStaging,
          icon: Icons.checklist_rtl_rounded,
          color: const Color(0xFF00E676),
        ),
      ],
    );
  }

  Widget _buildOriginTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionBlock(
          title: 'Natural & Biosynthetic Origin',
          content: profile.sourceAndOrigin,
          icon: Icons.eco_outlined,
          color: const Color(0xFF69F0AE),
        ),
        _buildSectionBlock(
          title: 'Discovery & Pharmaceutical History',
          content: profile.discoveryHistory,
          icon: Icons.history_edu_outlined,
          color: const Color(0xFFFFD54F),
        ),
        _buildSectionBlock(
          title: 'Industrial & Laboratory Chemical Synthetic Route',
          content: profile.syntheticRoute,
          icon: Icons.science_outlined,
          color: const Color(0xFFFF80AB),
        ),
      ],
    );
  }

  Widget _buildMoaTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionBlock(
          title: 'Molecular Target & Crystal PDB Coordinates',
          content: '${profile.molecularTarget} (PDB ID: ${profile.pdbAccession})',
          icon: Icons.scatter_plot_outlined,
          color: const Color(0xFF00E5FF),
        ),
        _buildSectionBlock(
          title: 'Detailed Molecular Mechanism of Action (MoA)',
          content: profile.modeOfAction,
          icon: Icons.biotech_outlined,
          color: const Color(0xFF00BFA5),
        ),
        _buildSectionBlock(
          title: 'Downstream Cellular & Hemodynamic Cascades',
          content: profile.downstreamSignaling,
          icon: Icons.account_tree_outlined,
          color: const Color(0xFF7C4DFF),
        ),
      ],
    );
  }

  Widget _buildAdmeTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionBlock(
          title: 'Absorption, Distribution & Volume of Distribution (Vd)',
          content: profile.absorptionAndDistribution,
          icon: Icons.input_outlined,
          color: const Color(0xFF00B0FF),
        ),
        _buildSectionBlock(
          title: 'Hepatic Metabolism, CYP Isoforms & Renal/Biliary Elimination',
          content: '${profile.metabolismAndElimination}\n\nElimination Half-Life: ${profile.eliminationHalfLifeHours} hours.',
          icon: Icons.refresh_outlined,
          color: const Color(0xFFFFAB40),
        ),
        _buildSectionBlock(
          title: '🐾 Comparative Species Pharmacology (Human vs Canine vs Feline vs Equine vs Bovine)',
          content: profile.comparativeSpeciesPharmacology,
          icon: Icons.pets_outlined,
          color: const Color(0xFFFF5252),
        ),
      ],
    );
  }

  Widget _buildQuantumTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionBlock(
          title: 'Active-Site Catalytic Geometry & Transition State',
          content: profile.transitionStateDescription,
          icon: Icons.blur_on_outlined,
          color: const Color(0xFF00E5FF),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00BFA5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reference Activation Barrier (Ea)', style: TextStyle(color: Color(0xFF00BFA5), fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${profile.activationBarrierKcalMol} kcal·mol⁻¹', style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Catalytic Residues: ${profile.catalyticResidues}', style: TextStyle(color: palette.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              if (onLoadReaction != null && profile.associatedReactionId.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.rocket_launch_outlined, size: 16),
                  label: const Text('Load 3D Rxn in Workspace'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onLoadReaction!(profile.associatedReactionId);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToxicologyTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (profile.blackBoxWarning.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('BLACK BOX WARNING / CRITICAL CLINICAL ALERT', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  profile.blackBoxWarning,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        _buildSectionBlock(
          title: 'Contraindications & High-Risk Patient Populations',
          content: profile.contraindications,
          icon: Icons.block_outlined,
          color: const Color(0xFFFF1744),
        ),
        _buildSectionBlock(
          title: 'Adverse Effects, Target Organ Toxicities & DDI',
          content: profile.adverseEffectsAndToxicity,
          icon: Icons.error_outline,
          color: const Color(0xFFFF9100),
        ),
        _buildSectionBlock(
          title: 'Antidotes, Rescue Protocols & Overdose Management',
          content: profile.antidoteAndRescue,
          icon: Icons.medical_services_outlined,
          color: const Color(0xFF00E676),
        ),
      ],
    );
  }

  Widget _buildEvidenceTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionBlock(
          title: 'Clinical Practice Guidelines & Consensus Statements',
          content: profile.clinicalGuidelines.map((g) => '• $g').join('\n\n'),
          icon: Icons.rule_sharp,
          color: const Color(0xFF2979FF),
        ),
        _buildSectionBlock(
          title: 'High-Yield Board & Licensure Exam Pearls (MBBS / Pharm-D / DVM)',
          content: profile.highYieldExamPearls.map((p) => '⭐ $p').join('\n\n'),
          icon: Icons.star_border_rounded,
          color: const Color(0xFFFFD600),
        ),
        _buildSectionBlock(
          title: 'Primary Literature Citations',
          content: 'DOI: ${profile.primaryDoi}\nPubMed ID: ${profile.pubmedId}',
          icon: Icons.article_outlined,
          color: palette.textMuted,
        ),
      ],
    );
  }
}

