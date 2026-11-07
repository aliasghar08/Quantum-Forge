// ============================================================================
// Quantum Controls Panel — PhD researcher parameter control surface
// Right-rail collapsible panel with System / Optimizer / Analysis tabs
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/state/settings_provider.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

import 'package:quantum_forge/screens/publication_details_screen.dart';
import 'package:quantum_forge/core/services/doi_verification_service.dart';
import 'package:quantum_forge/core/services/url_service.dart';
import 'package:quantum_forge/screens/pharmacogenomics_screen.dart';
import 'package:quantum_forge/screens/osce_sandbox_screen.dart';
import 'package:quantum_forge/screens/ddi_split_screen.dart';
import 'package:quantum_forge/screens/cardio_cath_screen.dart';
import 'package:quantum_forge/features/pharmacopeia/data/pharmacopeia_database.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';

class QuantumControlsPanel extends StatefulWidget {
  final ReactionTemplate? activeTemplate;
  final MedicinePharmacologyProfile? activeMedicineProfile;

  const QuantumControlsPanel({
    super.key,
    this.activeTemplate,
    this.activeMedicineProfile,
  });

  @override
  State<QuantumControlsPanel> createState() => _QuantumControlsPanelState();
}

class _QuantumControlsPanelState extends State<QuantumControlsPanel> {
  static const _algorithms = [
    'NEB-CI',
    'Growing String Method',
    'Dimer',
    'P-RFO',
  ];
  static const _convergences = ['Loose', 'Normal', 'Tight', 'Very Tight'];
  static const _exportFormats = ['XYZ', 'PDB', 'JSON'];

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<QuantumSettingsNotifier>();

    return ValueListenableBuilder<QuantumSettings>(
      valueListenable: notifier,
      builder: (context, settings, _) {
        return Material(
          color: Colors.black.withValues(alpha: 0.2),
          child: Column(
            children: [
              _buildPanelHeader(settings, notifier),
              Column(
                children: [
                  _buildExpansionTile(
                    title: 'CLINICAL & PHARMACOLOGY SYNC',
                    icon: Icons.local_hospital_outlined,
                    initiallyExpanded: true,
                    children: _buildClinicalSyncContent(context),
                  ),
                  _buildExpansionTile(
                    title: 'COMPUTE & CREDENTIALS',
                    icon: Icons.cloud_done_outlined,
                    initiallyExpanded: true,
                    children: _buildCredentialsContent(settings, notifier),
                  ),
                  _buildExpansionTile(
                    title: 'QUANTUM THEORY & CONVERGENCE',
                    icon: Icons.functions,
                    children: _buildOptimizerContent(settings, notifier),
                  ),
                  _buildExpansionTile(
                    title: 'POST-TS ANALYSIS & SPECTROSCOPY',
                    icon: Icons.analytics_outlined,
                    children: _buildAnalysisContent(settings, notifier),
                  ),
                  if (widget.activeTemplate != null)
                    _buildLiteratureRef(widget.activeTemplate!),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanelHeader(QuantumSettings s, QuantumSettingsNotifier n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.tune, color: Color(0xFF4FC3F7), size: 18),
          const SizedBox(width: 8),
          const Text(
            'Quantum Controls',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => n.resetToDefaults(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Reset', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPANSION TILE HELPER
  // ---------------------------------------------------------------------------
  Widget _buildExpansionTile({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        iconColor: const Color(0xFF4FC3F7),
        collapsedIconColor: Colors.white54,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        children: children,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CLINICAL & PHARMACOLOGY SYNC
  // ---------------------------------------------------------------------------
  List<Widget> _buildClinicalSyncContent(BuildContext context) {
    MedicinePharmacologyProfile? med = widget.activeMedicineProfile;
    if (med == null && widget.activeTemplate != null) {
      med = PharmacopeiaDatabase.findByReactionId(widget.activeTemplate!.id);
      if (med == null) {
        final matches = PharmacopeiaDatabase.getAllCuratedProfiles().where((p) {
          final key = p.genericName.toLowerCase().split(' ').first;
          return key.length > 3 && widget.activeTemplate!.name.toLowerCase().contains(key);
        });
        if (matches.isNotEmpty) med = matches.first;
      }
    }

    if (med != null) {
      String metabolizingEnzyme = 'CYP2E1';
      final name = med.genericName.toLowerCase();
      if (name.contains('paracetamol') || name.contains('acetaminophen')) {
        metabolizingEnzyme = 'CYP2E1 / UGT1A6';
      } else if (name.contains('warfarin')) {
        metabolizingEnzyme = 'CYP2C9';
      } else if (name.contains('codeine')) {
        metabolizingEnzyme = 'CYP2D6';
      } else if (name.contains('aspirin')) {
        metabolizingEnzyme = 'UGT1A6';
      } else if (name.contains('statin') || name.contains('atorvastatin')) {
        metabolizingEnzyme = 'CYP3A4';
      }

      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SYNCED: ${med.genericName.toUpperCase()}',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Target: ${med.molecularTarget}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                'Metabolizing Allele: $metabolizingEnzyme',
                style: const TextStyle(color: Color(0xFFFFB300), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionLabel('Clinical Pharmacology Workstations'),
        const SizedBox(height: 8),
        _clinicalActionPill(
          icon: Icons.biotech_rounded,
          color: const Color(0xFF00E5FF),
          label: 'Pharmacogenomics Mutator',
          subtitle: 'CYP450 / UGT allele kinetics ($metabolizingEnzyme)',
          onTap: () => Navigator.of(context).push(PharmacogenomicsScreen.route()),
        ),
        const SizedBox(height: 8),
        _clinicalActionPill(
          icon: Icons.emergency_rounded,
          color: const Color(0xFFFFB300),
          label: 'OSCE Emergency Sandbox',
          subtitle: 'Timed emergency antidote dispatch (120s)',
          onTap: () => Navigator.of(context).push(OsceSandboxScreen.route()),
        ),
        const SizedBox(height: 8),
        _clinicalActionPill(
          icon: Icons.splitscreen_rounded,
          color: const Color(0xFF00E676),
          label: 'Split-Screen DDI & AMR',
          subtitle: 'MRSA / TEM-52 steric clash analysis',
          onTap: () => Navigator.of(context).push(DdiSplitScreen.route()),
        ),
        const SizedBox(height: 8),
        _clinicalActionPill(
          icon: Icons.favorite_rounded,
          color: const Color(0xFFFF5252),
          label: 'CardioCath 3D Lab',
          subtitle: 'Coronary angiography & fluoroscopy simulator',
          onTap: () => Navigator.of(context).push(CardioCathScreen.route()),
        ),
      ];
    }

    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science_outlined, size: 14, color: Color(0xFF4FC3F7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.activeTemplate?.name ?? 'Intrinsic Chemical Coordinate',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select a pharmaceutical or veterinary reaction from the Library to sync live MBBS/Pharm-D pharmacology engines.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, height: 1.3),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _sectionLabel('Quick Medical Explorations'),
      const SizedBox(height: 8),
      _clinicalActionPill(
        icon: Icons.biotech_rounded,
        color: const Color(0xFF00E5FF),
        label: 'Pharmacogenomics Mutator',
        subtitle: 'Model CYP2C9, CYP2D6, CYP2E1, UGT1A6',
        onTap: () => Navigator.of(context).push(PharmacogenomicsScreen.route()),
      ),
      const SizedBox(height: 8),
      _clinicalActionPill(
        icon: Icons.emergency_rounded,
        color: const Color(0xFFFFB300),
        label: 'OSCE Clinical Sandbox',
        subtitle: 'Timed emergencies & antidote rescue',
        onTap: () => Navigator.of(context).push(OsceSandboxScreen.route()),
      ),
      const SizedBox(height: 8),
      _clinicalActionPill(
        icon: Icons.splitscreen_rounded,
        color: const Color(0xFF00E676),
        label: 'Split-Screen DDI & AMR',
        subtitle: 'Superbug bacterial resistance visualizer',
        onTap: () => Navigator.of(context).push(DdiSplitScreen.route()),
      ),
      const SizedBox(height: 8),
      _clinicalActionPill(
        icon: Icons.favorite_rounded,
        color: const Color(0xFFFF5252),
        label: 'CardioCath 3D Lab',
        subtitle: 'C-Arm fluoroscopy & cardiac hemodynamics',
        onTap: () => Navigator.of(context).push(CardioCathScreen.route()),
      ),
    ];
  }

  Widget _clinicalActionPill({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPUTE & CREDENTIALS
  // ---------------------------------------------------------------------------
  List<Widget> _buildCredentialsContent(
    QuantumSettings s,
    QuantumSettingsNotifier n,
  ) {
    return [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF101E27),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cloud Run: us-central1 (Online v2)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'MLIP PyTorch 2.6 • Eyring & ADME Pipeline',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _sectionLabel(
        'Hugging Face API Token',
        tooltip: 'Authentication token for accessing gated MLIP checkpoints.',
      ),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: s.hfToken,
        style: const TextStyle(color: Colors.white, fontSize: 12.5),
        obscureText: true,
        decoration: _inputDecoration('Enter API Token (hf_...)'),
        onChanged: (v) => n.update((q) => q.copyWith(hfToken: v)),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // OPTIMIZER CONTENT
  // ---------------------------------------------------------------------------
  List<Widget> _buildOptimizerContent(
    QuantumSettings s,
    QuantumSettingsNotifier n,
  ) {
    return [
      _sectionLabel(
        'Search Algorithm',
        tooltip: 'Algorithm used to locate the transition state structure.',
      ),
      const SizedBox(height: 12),
      _dropdownField(
        label: 'Method',
        value: s.optimizerAlgorithm,
        items: _algorithms,
        onChanged: (v) => n.update((q) => q.copyWith(optimizerAlgorithm: v)),
      ),
      const SizedBox(height: 16),
      _sectionLabel('Advanced Optimization'),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automated Conformational Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Run MMFF94 sweep prior to DFT.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: s.conformationalSearch,
            onChanged: (v) =>
                n.update((q) => q.copyWith(conformationalSearch: v)),
            activeTrackColor: const Color(0xFF4FC3F7),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // NEB Images (only shown for NEB)
      if (s.optimizerAlgorithm == 'NEB-CI') ...[
        _labeledWidget(
          'NEB Images',
          '${s.nebImages}',
          Slider(
            value: s.nebImages.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            activeColor: const Color(0xFF4FC3F7),
            inactiveColor: Colors.white12,
            onChanged: (v) => n.update((q) => q.copyWith(nebImages: v.round())),
          ),
        ),
        const SizedBox(height: 8),
        _labeledWidget(
          'Spring Constant',
          '${s.springConstant.toStringAsFixed(2)} eV/Å²',
          Slider(
            value: s.springConstant,
            min: 0.01,
            max: 1.0,
            divisions: 99,
            activeColor: const Color(0xFF4FC3F7),
            inactiveColor: Colors.white12,
            onChanged: (v) => n.update((q) => q.copyWith(springConstant: v)),
          ),
        ),
        const SizedBox(height: 8),
      ],

      _sectionLabel(
        'Convergence',
        tooltip:
            'Threshold for the RMS force gradient to consider the TS found.',
      ),
      const SizedBox(height: 12),
      _dropdownField(
        label: 'Threshold',
        value: s.convergence,
        items: _convergences,
        tooltip:
            'Threshold for the RMS force gradient to consider the TS found.',
        onChanged: (v) => n.update((q) => q.copyWith(convergence: v)),
      ),
      const SizedBox(height: 12),
      _dropdownField(
        label: 'DMF Convergence',
        value: s.dmfConvergence,
        items: const ['Loose', 'Normal', 'Tight'],
        onChanged: (v) => n.update((q) => q.copyWith(dmfConvergence: v)),
      ),
      const SizedBox(height: 16),

      _labeledWidget(
        'Max Steps',
        '${s.maxSteps}',
        Slider(
          value: s.maxSteps.toDouble(),
          min: 50,
          max: 2000,
          divisions: 39,
          activeColor: const Color(0xFF4FC3F7),
          inactiveColor: Colors.white12,
          onChanged: (v) => n.update((q) => q.copyWith(maxSteps: v.round())),
        ),
      ),
      const SizedBox(height: 8),
      _labeledWidget(
        'nmove',
        '${s.nmove}',
        Slider(
          value: s.nmove.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: const Color(0xFF4FC3F7),
          inactiveColor: Colors.white12,
          onChanged: (v) => n.update((q) => q.copyWith(nmove: v.round())),
        ),
      ),
      const SizedBox(height: 8),
      _switchRow(
        'Update Teval',
        s.updateTeval,
        (v) => n.update((q) => q.copyWith(updateTeval: v)),
      ),
      const SizedBox(height: 8),

      // Max force norm text field
      _sectionLabel('Force Criterion'),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: s.maxForceNorm.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        keyboardType: TextInputType.number,
        decoration: _inputDecoration('Max Force Norm (eV/Å)'),
        onChanged: (v) {
          final parsed = double.tryParse(v);
          if (parsed != null) {
            n.update((q) => q.copyWith(maxForceNorm: parsed));
          }
        },
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // ANALYSIS CONTENT
  // ---------------------------------------------------------------------------
  List<Widget> _buildAnalysisContent(
    QuantumSettings s,
    QuantumSettingsNotifier n,
  ) {
    return [
      _sectionLabel('Thermochemistry'),
      const SizedBox(height: 12),
      _switchRow(
        'ZPE Correction',
        s.zpeCorrection,
        (v) => n.update((q) => q.copyWith(zpeCorrection: v)),
        tooltip: 'Zero-point vibrational energy correction.',
      ),
      _switchRow(
        'ΔH / ΔG at T',
        s.computeThermochemistry,
        (v) => n.update((q) => q.copyWith(computeThermochemistry: v)),
        tooltip:
            'Verify exactly one imaginary frequency corresponding to the reaction coordinate.',
      ),
      const SizedBox(height: 16),

      _sectionLabel('Post-TS Analysis'),
      const SizedBox(height: 12),
      _switchRow(
        'Intrinsic Reaction Coordinate (IRC)',
        s.runIrc,
        (v) => n.update((q) => q.copyWith(runIrc: v)),
      ),
      _switchRow(
        'Frequency Analysis (ν‡)',
        s.frequencyAnalysis,
        (v) => n.update((q) => q.copyWith(frequencyAnalysis: v)),
      ),
      const SizedBox(height: 16),

      _sectionLabel('Export'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: _exportFormats.map((fmt) {
          final selected = s.exportFormat == fmt;
          return ChoiceChip(
            label: Text(fmt),
            selected: selected,
            selectedColor: const Color(0xFF4FC3F7).withValues(alpha: 0.25),
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF4FC3F7) : Colors.white54,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF4FC3F7)
                  : Colors.white.withValues(alpha: 0.15),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            onSelected: (_) => n.update((q) => q.copyWith(exportFormat: fmt)),
          );
        }).toList(),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // LITERATURE REFERENCE
  // ---------------------------------------------------------------------------
  Widget _buildLiteratureRef(ReactionTemplate t) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bookmark_outline,
                color: Colors.amber.shade300,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Literature Reference',
                style: TextStyle(
                  color: Colors.amber.shade300,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ΔE‡ = ${t.effectiveLiteratureBarrier} kcal·mol⁻¹'
            '${t.hasLiteratureCatalyst && t.defaultCatalystName != null ? ' (${t.defaultCatalystName})' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t.journalRef,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (DoiVerificationService.isVerifiedDoi(t.doi)) {
                      UrlService.launch('https://doi.org/${t.doi}');
                    } else {
                      DoiVerificationService.showUnverifiedDoiDialog(
                        context: context,
                        doi: t.doi,
                        articleTitle: t.name,
                        journalRef: t.journalRef,
                        onViewPublicationDetails: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  PublicationDetailsScreen(template: t),
                            ),
                          );
                        },
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'DOI: ${t.doi}',
                          style: TextStyle(
                            color: DoiVerificationService.isVerifiedDoi(t.doi)
                                ? const Color(0xFF4FC3F7).withValues(alpha: 0.7)
                                : Colors.grey.withValues(alpha: 0.6),
                            fontSize: 10,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!DoiVerificationService.isVerifiedDoi(t.doi)) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.warning_amber_rounded, size: 11, color: Colors.amber),
                      ],
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          PublicationDetailsScreen(template: t),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.open_in_new,
                  size: 12,
                  color: Color(0xFF4FC3F7),
                ),
                label: const Text(
                  'View Publication',
                  style: TextStyle(
                    color: Color(0xFF4FC3F7),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4FC3F7),
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  Widget _infoTooltip(String message) {
    return Tooltip(
      message: message,
      textStyle: const TextStyle(fontSize: 12, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      triggerMode: TooltipTriggerMode.tap,
      child: const Padding(
        padding: EdgeInsets.only(left: 4.0),
        child: Icon(Icons.info_outline, size: 14, color: Colors.white54),
      ),
    );
  }

  Widget _sectionLabel(String label, {String? tooltip}) => Row(
    children: [
      Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      if (tooltip != null) _infoTooltip(tooltip),
    ],
  );

  Widget _labeledWidget(
    String label,
    String value,
    Widget control, {
    String? tooltip,
  }) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
                if (tooltip != null) _infoTooltip(tooltip),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      control,
    ],
  );

  Widget _switchRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    String? tooltip,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
              if (tooltip != null) _infoTooltip(tooltip),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF4FC3F7),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    ),
  );

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    String? tooltip,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          if (tooltip != null) _infoTooltip(tooltip),
        ],
      ),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        key: ValueKey('${label}_$value'),
        initialValue: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
        dropdownColor: const Color(0xFF1A2E3A),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        iconEnabledColor: const Color(0xFF4FC3F7),
        decoration: _inputDecoration(label),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            onChanged(v);
          }
        },
      ),
    ],
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 12,
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
