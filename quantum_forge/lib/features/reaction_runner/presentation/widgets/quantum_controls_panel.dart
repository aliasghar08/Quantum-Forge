// ============================================================================
// Quantum Controls Panel — PhD researcher parameter control surface
// Right-rail collapsible panel with System / Optimizer / Analysis tabs
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/state/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

import 'package:quantum_forge/features/reaction_library/presentation/screens/publication_details_screen.dart';
import 'package:quantum_forge/core/algorithms/solvent_properties.dart';
import 'package:quantum_forge/core/services/doi_verification_service.dart';
import 'package:quantum_forge/core/services/url_service.dart';

class QuantumControlsPanel extends StatefulWidget {
  final ReactionTemplate? activeTemplate;

  const QuantumControlsPanel({super.key, this.activeTemplate});

  @override
  State<QuantumControlsPanel> createState() => _QuantumControlsPanelState();
}

class _QuantumControlsPanelState extends State<QuantumControlsPanel> {
  static const _mlipModels = [
    'tx1-fastapi',
    'MACE-MP-0',
    'CHGNet',
    'GFN2-xTB',
  ];
  static const _solventModels = [
    'Vacuum',
    'PCM (H₂O)',
    'PCM (EtOH)',
    'PCM (MeOH)',
    'PCM (DMSO)',
    'PCM (THF)',
    'PCM (DCM)',
    'PCM (Toluene)',
    'PCM (Hexane)',
    'Onsager (ε=78.4)',
    'SMD (H₂O)',
    'SMD (DMSO)',
  ];
  static const _algorithms = [
    'NEB-CI',
    'Growing String Method',
    'Dimer',
    'P-RFO',
  ];
  static const _convergences = ['Loose', 'Normal', 'Tight', 'Very Tight'];
  static const _exportFormats = ['XYZ', 'PDB', 'JSON'];

  TextEditingController? _customCatalystController;

  @override
  void initState() {
    super.initState();
    _customCatalystController = TextEditingController();
  }

  @override
  void dispose() {
    _customCatalystController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<QuantumSettingsNotifier>();

    return ValueListenableBuilder<QuantumSettings>(
      valueListenable: notifier,
      builder: (context, settings, _) {
        // FIX: Use Material instead of Container(BoxDecoration) so that
        // ExpansionTile/ListTile ink splashes and tile backgrounds paint
        // on a real Material surface. The previous DecoratedBox hid them
        // and triggered the "ListTile background color or ink splashes may
        // be invisible" assertion.
        return Material(
          color: Colors.black.withValues(alpha: 0.2),
          child: Column(
            children: [
              _buildPanelHeader(settings, notifier),
              Column(
                children: [
                  _buildExpansionTile(
                    title: 'SYSTEM PARAMETERS',
                    icon: Icons.memory,
                    initiallyExpanded: true,
                    children: _buildSystemContent(settings, notifier),
                  ),
                  _buildExpansionTile(
                    title: 'CATALYST CONFIGURATION',
                    icon: Icons.science_outlined,
                    initiallyExpanded:
                        widget.activeTemplate?.hasLiteratureCatalyst == true,
                    children: _buildCatalystContent(settings, notifier),
                  ),
                  _buildExpansionTile(
                    title: 'QUANTUM THEORY',
                    icon: Icons.functions,
                    children: _buildOptimizerContent(settings, notifier),
                  ),
                  _buildExpansionTile(
                    title: 'POST-TS ANALYSIS',
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
  // SYSTEM CONTENT
  // ---------------------------------------------------------------------------
  List<Widget> _buildSystemContent(
    QuantumSettings s,
    QuantumSettingsNotifier n,
  ) {
    return [
      _sectionLabel('Electronic Structure'),
      const SizedBox(height: 12),

      // Charge spinner
      _labeledRow(
        'Charge',
        Row(
          children: [
            _iconButton(Icons.remove, () {
              if (s.charge > -5) {
                n.update((q) => q.copyWith(charge: q.charge - 1));
              }
            }),
            Container(
              width: 48,
              alignment: Alignment.center,
              child: Text(
                '${s.charge >= 0 ? '+' : ''}${s.charge}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _iconButton(Icons.add, () {
              if (s.charge < 5) {
                n.update((q) => q.copyWith(charge: q.charge + 1));
              }
            }),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Spin multiplicity
      _labeledRow(
        'Spin Mult.',
        Row(
          children: [
            _iconButton(Icons.remove, () {
              if (s.spinMultiplicity > 1) {
                n.update(
                  (q) => q.copyWith(spinMultiplicity: q.spinMultiplicity - 1),
                );
              }
            }),
            Container(
              width: 48,
              alignment: Alignment.center,
              child: Text(
                '${s.spinMultiplicity}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _iconButton(Icons.add, () {
              if (s.spinMultiplicity < 7) {
                n.update(
                  (q) => q.copyWith(spinMultiplicity: q.spinMultiplicity + 1),
                );
              }
            }),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _sectionLabel('ML Potential'),
      const SizedBox(height: 12),

      // MLIP model dropdown
      _dropdownField(
        label: 'MLIP Model',
        value: s.mlipModel,
        items: _mlipModels,
        onChanged: (v) => n.update((q) => q.copyWith(mlipModel: v)),
      ),
      const SizedBox(height: 16),
      _sectionLabel('Environment'),
      const SizedBox(height: 12),

      // Solvent
      _dropdownField(
        label: 'Solvent',
        value: s.solventModel,
        items: _solventModels,
        tooltip:
            'The implicit solvation model used to simulate solvent effects on the reaction.',
        onChanged: (v) => n.update((q) => q.copyWith(solventModel: v)),
      ),
      const SizedBox(height: 6),
      Builder(builder: (context) {
        final solventData = SolventProperties.lookup(s.solventModel);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF101E27),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: solventData.isSolvated
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                  : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Icon(
                solventData.isSolvated ? Icons.water_drop_outlined : Icons.air,
                size: 14,
                color: solventData.isSolvated
                    ? const Color(0xFF38BDF8)
                    : Colors.white54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  solventData.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ),
              if (solventData.isSolvated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ε = ${solventData.dielectricConstant}',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
      const SizedBox(height: 16),

      // Temperature slider
      _labeledWidget(
        'Temperature',
        '${s.temperatureK.toStringAsFixed(0)} K',
        Slider(
          value: s.temperatureK,
          min: 100,
          max: 1000,
          divisions: 90,
          activeColor: const Color(0xFF4FC3F7),
          inactiveColor: Colors.white12,
          onChanged: (v) => n.update((q) => q.copyWith(temperatureK: v)),
        ),
      ),
      const SizedBox(height: 16),
      _sectionLabel('Credentials'),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: s.hfToken,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        obscureText: true,
        decoration: _inputDecoration('Hugging Face API Token'),
        onChanged: (v) => n.update((q) => q.copyWith(hfToken: v)),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // CATALYST CONTENT
  // ---------------------------------------------------------------------------
  List<Widget> _buildCatalystContent(
    QuantumSettings s,
    QuantumSettingsNotifier n,
  ) {
    final template = widget.activeTemplate;
    final hasLiteratureCat = template?.hasLiteratureCatalyst == true;
    final litCatName = template?.defaultCatalystName ?? 'None';

    final catalystModes = [
      if (hasLiteratureCat) 'Literature Default',
      'None (Gas-Phase / Intrinsic)',
      'Custom Catalyst',
    ];

    String selectedMode;
    if (!s.applyLiteratureCatalyst ||
        s.catalyst == 'None' ||
        s.catalyst == 'None (Gas-Phase / Intrinsic)') {
      selectedMode = 'None (Gas-Phase / Intrinsic)';
    } else if (s.catalyst == 'Custom Catalyst' ||
        (s.customCatalyst.isNotEmpty && s.catalyst == s.customCatalyst)) {
      selectedMode = 'Custom Catalyst';
    } else if (hasLiteratureCat &&
        (s.catalyst == 'Literature Default' || s.catalyst == litCatName)) {
      selectedMode = 'Literature Default';
    } else {
      selectedMode = hasLiteratureCat
          ? 'Literature Default'
          : 'None (Gas-Phase / Intrinsic)';
    }

    if (_customCatalystController != null &&
        _customCatalystController!.text != s.customCatalyst) {
      _customCatalystController!.text = s.customCatalyst;
    }

    return [
      if (hasLiteratureCat) ...[
        _switchRow(
          'Apply Literature Catalyst ($litCatName)',
          s.applyLiteratureCatalyst,
          (val) {
            n.update((q) => q.copyWith(
              applyLiteratureCatalyst: val,
              catalyst: val ? litCatName : 'None (Gas-Phase / Intrinsic)',
            ));
          },
          tooltip:
              'When enabled, applies the literature-defined catalyst ($litCatName) to match published experimental barriers.',
        ),
        const SizedBox(height: 12),
      ] else ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.white38),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Gas-phase reaction (no literature catalyst specified)',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      _dropdownField(
        label: 'Catalyst Mode / Override',
        value: selectedMode,
        items: catalystModes,
        tooltip:
            'Select whether to use the literature catalyst, simulate purely intrinsic gas-phase kinetics, or specify a custom catalyst environment.',
        onChanged: (mode) {
          if (mode == 'Literature Default') {
            n.update((q) => q.copyWith(
              applyLiteratureCatalyst: true,
              catalyst: litCatName,
            ));
          } else if (mode == 'None (Gas-Phase / Intrinsic)') {
            n.update((q) => q.copyWith(
              applyLiteratureCatalyst: false,
              catalyst: 'None (Gas-Phase / Intrinsic)',
            ));
          } else if (mode == 'Custom Catalyst') {
            final customVal =
                s.customCatalyst.isNotEmpty ? s.customCatalyst : 'Custom Catalyst';
            n.update((q) => q.copyWith(
              applyLiteratureCatalyst: true,
              catalyst: customVal,
            ));
          }
        },
      ),

      if (selectedMode == 'Custom Catalyst') ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _customCatalystController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: _inputDecoration('Custom Catalyst Formula / Name'),
          onChanged: (val) {
            n.update((q) => q.copyWith(
              customCatalyst: val,
              catalyst: val.isNotEmpty ? val : 'Custom Catalyst',
            ));
          },
        ),
      ],

      if (hasLiteratureCat && s.applyLiteratureCatalyst) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4FC3F7).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: Color(0xFF4FC3F7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Active: $litCatName',
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (template?.literatureBarrierKcalMol != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Literature Barrier: ${template!.literatureBarrierKcalMol!.toStringAsFixed(1)} kcal/mol',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
              if (template?.literatureDoi != null) ...[
                Builder(
                  builder: (context) {
                    final tmpl = template!;
                    final litDoi = tmpl.literatureDoi!;
                    final isVerified = DoiVerificationService.isVerifiedDoi(litDoi);
                    return InkWell(
                      onTap: () {
                        if (isVerified) {
                          UrlService.launch('https://doi.org/$litDoi');
                        } else {
                          DoiVerificationService.showUnverifiedDoiDialog(
                            context: context,
                            doi: litDoi,
                            articleTitle: tmpl.name,
                            journalRef: tmpl.journalRef,
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DOI: $litDoi',
                            style: TextStyle(
                              color: isVerified
                                  ? const Color(0xFF4FC3F7)
                                  : Colors.grey.withValues(alpha: 0.6),
                              fontSize: 9,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          if (!isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.help_outline_rounded, size: 10, color: Colors.amber),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
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
                  if (!DoiVerificationService.isVerifiedDoi(t.doi)) {
                    DoiVerificationService.showUnverifiedDoiDialog(
                      context: context,
                      doi: t.doi,
                      articleTitle: t.name,
                      journalRef: t.journalRef,
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PublicationDetailsScreen(template: t),
                      ),
                    );
                  }
                },
                icon: Icon(
                  DoiVerificationService.isVerifiedDoi(t.doi)
                      ? Icons.open_in_new
                      : Icons.warning_amber_rounded,
                  size: 12,
                  color: DoiVerificationService.isVerifiedDoi(t.doi)
                      ? const Color(0xFF4FC3F7)
                      : Colors.grey,
                ),
                label: Text(
                  DoiVerificationService.isVerifiedDoi(t.doi)
                      ? 'View Publication'
                      : 'View Publication (Unverified)',
                  style: TextStyle(
                    color: DoiVerificationService.isVerifiedDoi(t.doi)
                        ? const Color(0xFF4FC3F7)
                        : Colors.grey,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: DoiVerificationService.isVerifiedDoi(t.doi)
                      ? const Color(0xFF4FC3F7)
                      : Colors.grey,
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

  Widget _labeledRow(String label, Widget trailing, {String? tooltip}) => Row(
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
      trailing,
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

  Widget _iconButton(IconData icon, VoidCallback onPressed) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Icon(icon, size: 16, color: Colors.white70),
    ),
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
