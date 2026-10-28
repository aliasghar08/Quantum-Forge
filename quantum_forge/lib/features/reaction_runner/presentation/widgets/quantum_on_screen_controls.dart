// ============================================================================
// Quantum On-Screen Controls Card — Responsive mobile & desktop control surface
// Directly embedded into the reaction setup flow so every parameter is on-screen
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/state/settings_provider.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/core/algorithms/solvent_properties.dart';
import 'package:quantum_forge/core/services/doi_verification_service.dart';
import 'package:quantum_forge/core/services/url_service.dart';

class QuantumOnScreenControlsCard extends StatefulWidget {
  final ReactionTemplate? activeTemplate;

  const QuantumOnScreenControlsCard({
    super.key,
    this.activeTemplate,
  });

  @override
  State<QuantumOnScreenControlsCard> createState() => _QuantumOnScreenControlsCardState();
}

class _QuantumOnScreenControlsCardState extends State<QuantumOnScreenControlsCard> {
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

  static const _convergences = [
    'Loose',
    'Normal',
    'Tight',
    'Very Tight',
  ];

  static const _exportFormats = ['XYZ', 'PDB', 'JSON'];

  late final TextEditingController _customCatalystController;
  late final TextEditingController _tokenController;
  bool _advancedExpanded = false;

  @override
  void initState() {
    super.initState();
    _customCatalystController = TextEditingController();
    _tokenController = TextEditingController();
  }

  @override
  void dispose() {
    _customCatalystController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<QuantumSettingsNotifier>();
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return ValueListenableBuilder<QuantumSettings>(
      valueListenable: notifier,
      builder: (context, settings, _) {
        if (_customCatalystController.text != settings.customCatalyst) {
          _customCatalystController.text = settings.customCatalyst;
        }
        if (_tokenController.text != settings.hfToken) {
          _tokenController.text = settings.hfToken;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Row ────────────────────────────────────────────────
              _buildHeader(settings, notifier),
              const SizedBox(height: 16),

              // ── Section 1: Electronic Structure (Charge & Spin) ───────────
              _buildElectronicStructureSection(settings, notifier, isSmallScreen),
              const SizedBox(height: 16),

              // ── Section 2: ML Potential & Environment ─────────────────────
              _buildPotentialAndSolventSection(settings, notifier, isSmallScreen),
              const SizedBox(height: 16),

              // ── Section 3: Thermal Kinetic Energy / Temperature Slider ────
              _buildThermalKineticSection(settings, notifier, isSmallScreen),
              const SizedBox(height: 16),

              // ── Section 4: Catalyst Configuration ─────────────────────────
              _buildCatalystSection(settings, notifier, isSmallScreen),
              const SizedBox(height: 16),

              // ── Section 5: Optimizer & Advanced Theory ────────────────────
              _buildAdvancedSection(settings, notifier, isSmallScreen),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(QuantumSettings s, QuantumSettingsNotifier n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF38BDF8)),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantum Simulation Parameters',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Live parameters synchronized across all views',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => n.resetToDefaults(),
          icon: const Icon(Icons.refresh_rounded, size: 13),
          label: const Text('Reset', style: TextStyle(fontSize: 11)),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white54,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: ELECTRONIC STRUCTURE
  // ---------------------------------------------------------------------------
  Widget _buildElectronicStructureSection(
    QuantumSettings s,
    QuantumSettingsNotifier n,
    bool isSmallScreen,
  ) {
    final chargeWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFFBBF24)),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Charge',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Net charge (e⁻)',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          _stepperButton(Icons.remove, () {
            if (s.charge > -5) {
              n.update((q) => q.copyWith(charge: q.charge - 1));
            }
          }),
          Container(
            width: 44,
            alignment: Alignment.center,
            child: Text(
              s.charge >= 0 ? '+${s.charge}' : '${s.charge}',
              style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          _stepperButton(Icons.add, () {
            if (s.charge < 5) {
              n.update((q) => q.copyWith(charge: q.charge + 1));
            }
          }),
        ],
      ),
    );

    final spinWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFA78BFA).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.rotate_right_rounded, size: 18, color: Color(0xFFA78BFA)),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spin Multiplicity',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '2S + 1',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          _stepperButton(Icons.remove, () {
            if (s.spinMultiplicity > 1) {
              n.update((q) => q.copyWith(spinMultiplicity: q.spinMultiplicity - 1));
            }
          }),
          Container(
            width: 44,
            alignment: Alignment.center,
            child: Text(
              '${s.spinMultiplicity}',
              style: const TextStyle(
                color: Color(0xFFA78BFA),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          _stepperButton(Icons.add, () {
            if (s.spinMultiplicity < 7) {
              n.update((q) => q.copyWith(spinMultiplicity: q.spinMultiplicity + 1));
            }
          }),
        ],
      ),
    );

    if (isSmallScreen) {
      return Column(
        children: [
          chargeWidget,
          const SizedBox(height: 10),
          spinWidget,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: chargeWidget),
        const SizedBox(width: 12),
        Expanded(child: spinWidget),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2: ML POTENTIAL & ENVIRONMENT
  // ---------------------------------------------------------------------------
  Widget _buildPotentialAndSolventSection(
    QuantumSettings s,
    QuantumSettingsNotifier n,
    bool isSmallScreen,
  ) {
    final solventData = SolventProperties.lookup(s.solventModel);

    final mlipField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.memory_rounded, size: 14, color: Color(0xFF38BDF8)),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Surrogate MLIP Potential',
                style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey('mlip_${s.mlipModel}'),
          isExpanded: true,
          initialValue: _mlipModels.contains(s.mlipModel) ? s.mlipModel : _mlipModels.first,
          dropdownColor: const Color(0xFF101E27),
          style: const TextStyle(color: Colors.white, fontSize: 12.5),
          iconEnabledColor: const Color(0xFF38BDF8),
          decoration: _dropdownDecoration(),
          items: _mlipModels
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) {
            if (v != null) n.update((q) => q.copyWith(mlipModel: v));
          },
        ),
      ],
    );

    final solventField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.water_drop_outlined, size: 14, color: Color(0xFF34D399)),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Solvation Medium',
                style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey('solvent_${s.solventModel}'),
          isExpanded: true,
          initialValue: _solventModels.contains(s.solventModel) ? s.solventModel : _solventModels.first,
          dropdownColor: const Color(0xFF101E27),
          style: const TextStyle(color: Colors.white, fontSize: 12.5),
          iconEnabledColor: const Color(0xFF34D399),
          decoration: _dropdownDecoration(),
          items: _solventModels
              .map((sol) => DropdownMenuItem(value: sol, child: Text(sol)))
              .toList(),
          onChanged: (v) {
            if (v != null) n.update((q) => q.copyWith(solventModel: v));
          },
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSmallScreen) ...[
          mlipField,
          const SizedBox(height: 12),
          solventField,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: mlipField),
              const SizedBox(width: 12),
              Expanded(child: solventField),
            ],
          ),
        const SizedBox(height: 8),
        // Live Solvent Property Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF101E27),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: solventData.isSolvated
                  ? const Color(0xFF34D399).withValues(alpha: 0.25)
                  : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Icon(
                solventData.isSolvated ? Icons.water_drop_outlined : Icons.air,
                size: 13,
                color: solventData.isSolvated ? const Color(0xFF34D399) : Colors.white54,
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
                    color: const Color(0xFF34D399).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ε = ${solventData.dielectricConstant}',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: THERMAL KINETIC ENERGY & TEMPERATURE SWEEP
  // ---------------------------------------------------------------------------
  Widget _buildThermalKineticSection(
    QuantumSettings s,
    QuantumSettingsNotifier n,
    bool isSmallScreen,
  ) {
    final tK = s.temperatureK.clamp(100.0, 1000.0);
    final tC = tK - 273.15;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7043).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF7043).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thermostat_rounded, size: 16, color: Color(0xFFFF7043)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Thermal Kinetic Sweep:',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${tK.toStringAsFixed(1)} K (${tC.toStringAsFixed(1)} °C)',
                style: const TextStyle(
                  color: Color(0xFFFF7043),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF7043),
              inactiveTrackColor: Colors.white12,
              thumbColor: const Color(0xFFFF7043),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: tK,
              min: 100.0,
              max: 1000.0,
              label: '${tK.toStringAsFixed(1)} K',
              onChanged: (v) => n.update((q) => q.copyWith(temperatureK: v)),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            alignment: WrapAlignment.center,
            children: [
              _buildTempPreset(195.15, '195 K (Dry Ice)', tK, n),
              _buildTempPreset(273.15, '273 K (0 °C)', tK, n),
              _buildTempPreset(298.15, '298 K (Room Temp)', tK, n),
              _buildTempPreset(310.15, '310 K (Body Temp)', tK, n),
              _buildTempPreset(373.15, '373 K (Boiling)', tK, n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempPreset(double targetK, String label, double currentK, QuantumSettingsNotifier n) {
    final isSelected = (currentK - targetK).abs() < 1.0;
    return InkWell(
      onTap: () => n.update((q) => q.copyWith(temperatureK: targetK)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF7043).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7043) : Colors.white12,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF7043) : Colors.white60,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 4: CATALYST CONFIGURATION
  // ---------------------------------------------------------------------------
  Widget _buildCatalystSection(
    QuantumSettings s,
    QuantumSettingsNotifier n,
    bool isSmallScreen,
  ) {
    final template = widget.activeTemplate;
    final hasLiteratureCat = template?.hasLiteratureCatalyst == true;
    final litCatName = template?.defaultCatalystName ?? 'None';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF60A5FA).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 15, color: Color(0xFF60A5FA)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Catalyst Configuration',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (hasLiteratureCat)
                Switch(
                  value: s.applyLiteratureCatalyst,
                  activeThumbColor: const Color(0xFF60A5FA),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) {
                    n.update((q) => q.copyWith(
                      applyLiteratureCatalyst: val,
                      catalyst: val ? litCatName : 'None (Gas-Phase / Intrinsic)',
                    ));
                  },
                ),
            ],
          ),
          if (hasLiteratureCat) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF60A5FA)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Literature: $litCatName',
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (template?.literatureBarrierKcalMol != null)
                          Text(
                            'Published Barrier: ${template!.literatureBarrierKcalMol!.toStringAsFixed(1)} kcal/mol',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  if (template?.literatureDoi != null)
                    InkWell(
                      onTap: () {
                        final doi = template!.literatureDoi!;
                        if (DoiVerificationService.isVerifiedDoi(doi)) {
                          UrlService.launch('https://doi.org/$doi');
                        } else {
                          DoiVerificationService.showUnverifiedDoiDialog(
                            context: context,
                            doi: doi,
                            articleTitle: template.name,
                            journalRef: template.journalRef,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DOI',
                              style: TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.open_in_new, size: 10, color: Color(0xFF60A5FA)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _catalystChip('Gas-Phase / None', s.catalyst == 'None' || s.catalyst == 'None (Gas-Phase / Intrinsic)', () {
                  n.update((q) => q.copyWith(catalyst: 'None (Gas-Phase / Intrinsic)', customCatalyst: ''));
                }),
                _catalystChip('Custom Catalyst', s.catalyst == 'Custom Catalyst' || s.customCatalyst.isNotEmpty, () {
                  n.update((q) => q.copyWith(catalyst: 'Custom Catalyst'));
                }),
              ],
            ),
            if (s.catalyst == 'Custom Catalyst' || s.customCatalyst.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _customCatalystController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Enter custom catalyst SMILES or formula...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF101E27),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                onChanged: (v) {
                  n.update((q) => q.copyWith(customCatalyst: v, catalyst: v.isEmpty ? 'Custom Catalyst' : v));
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _catalystChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF60A5FA).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF60A5FA) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF60A5FA) : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 5: OPTIMIZER & ADVANCED THEORY
  // ---------------------------------------------------------------------------
  Widget _buildAdvancedSection(
    QuantumSettings s,
    QuantumSettingsNotifier n,
    bool isSmallScreen,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _advancedExpanded = !_advancedExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.functions_rounded, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Optimizer, Convergence & Advanced Theory',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _advancedExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_advancedExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Algorithm & Convergence row
                  if (isSmallScreen) ...[
                    _dropdownControl(
                      'Search Algorithm',
                      s.optimizerAlgorithm,
                      _algorithms,
                      (v) => n.update((q) => q.copyWith(optimizerAlgorithm: v)),
                    ),
                    const SizedBox(height: 10),
                    _dropdownControl(
                      'Convergence Threshold',
                      s.convergence,
                      _convergences,
                      (v) => n.update((q) => q.copyWith(convergence: v)),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: _dropdownControl(
                            'Search Algorithm',
                            s.optimizerAlgorithm,
                            _algorithms,
                            (v) => n.update((q) => q.copyWith(optimizerAlgorithm: v)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dropdownControl(
                            'Convergence Threshold',
                            s.convergence,
                            _convergences,
                            (v) => n.update((q) => q.copyWith(convergence: v)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Conformational search switch
                  _switchControl(
                    'Automated Conformational Search (MMFF94)',
                    'Screen conformers prior to quantum TS search',
                    s.conformationalSearch,
                    (val) => n.update((q) => q.copyWith(conformationalSearch: val)),
                  ),
                  const SizedBox(height: 8),

                  // Vibrational modes & IRC verification
                  _switchControl(
                    'Frequency Analysis (ν‡)',
                    'Verify single imaginary frequency at saddle point',
                    s.frequencyAnalysis,
                    (val) => n.update((q) => q.copyWith(frequencyAnalysis: val)),
                  ),
                  const SizedBox(height: 8),

                  _switchControl(
                    'Intrinsic Reaction Coordinate (IRC)',
                    'Follow steepest descent forward & backward',
                    s.runIrc,
                    (val) => n.update((q) => q.copyWith(runIrc: val)),
                  ),
                  const SizedBox(height: 12),

                  // Export format
                  Row(
                    children: [
                      const Text(
                        'Export Format: ',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 6,
                        children: _exportFormats.map((fmt) {
                          final isSelected = s.exportFormat == fmt;
                          return InkWell(
                            onTap: () => n.update((q) => q.copyWith(exportFormat: fmt)),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF38BDF8).withValues(alpha: 0.2) : Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent),
                              ),
                              child: Text(
                                fmt,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF38BDF8) : Colors.white60,
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // HF Token credentials field
                  TextFormField(
                    controller: _tokenController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Hugging Face API Token (Optional)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF101E27),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => n.update((q) => q.copyWith(hfToken: v)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, size: 15, color: Colors.white),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF101E27),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
      ),
    );
  }

  Widget _dropdownControl(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey('${label}_$value'),
          initialValue: items.contains(value) ? value : items.first,
          dropdownColor: const Color(0xFF101E27),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          iconEnabledColor: const Color(0xFF38BDF8),
          decoration: _dropdownDecoration(),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _switchControl(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF38BDF8),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}
