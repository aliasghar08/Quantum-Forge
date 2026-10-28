import 'package:flutter/material.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/state/settings_provider.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/views/reaction_workspace_viewmodel.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/core/algorithms/solvent_properties.dart';

class ReactionWorkspaceDesktopView extends StatelessWidget {
  const ReactionWorkspaceDesktopView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReactionWorkspaceViewModel>();
    final palette = context.watch<ThemeNotifier>().palette;

    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Center Workspace (flex: 7)
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Desktop Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.blur_on,
                          color: Colors.cyanAccent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  vm.reactionTitle,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.tealAccent.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'TEMPLATE',
                                    style: TextStyle(
                                      color: Colors.tealAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              vm.reactionSubtitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: vm.isCalculating ? null : vm.executeTsSearch,
                        icon: Icon(
                          vm.isSignedIn ? Icons.science_outlined : Icons.lock_outline,
                          size: 17,
                        ),
                        label: Text(
                          vm.isCalculating
                              ? 'Calculating...'
                              : (vm.isSignedIn
                                  ? 'Execute TS Search'
                                  : 'Execute TS Search (Sign In)'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent.shade700,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status & Model Accuracy Overview Banner
                  _buildStatusOverviewCard(),
                  const SizedBox(height: 20),

                  // Export Actions Wrap
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Export Actions:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _exportButton(
                        Icons.file_download_outlined,
                        'Export .xyz',
                        () => vm.exportFile('xyz'),
                      ),
                      _exportButton(
                        Icons.folder_zip_outlined,
                        'Bundle .zip',
                        () => vm.exportFile('zip'),
                      ),
                      _exportButton(
                        Icons.science_outlined,
                        'Trajectory',
                        () => vm.exportFile('trajectory'),
                      ),
                      _exportButton(
                        Icons.cloud_upload_outlined,
                        'Save to Cloud',
                        () => vm.exportFile('firebase'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Arrhenius Plot Card
                  _buildArrheniusPlotCard(vm),
                  const SizedBox(height: 20),

                  // Comprehensive Thermodynamic Properties Grid
                  _buildThermodynamicsGrid(vm),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Right Desktop Quantum Controls Rail (flex: 3)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: _buildQuantumControlsRail(context, vm, palette),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statusPill(Icons.psychology, "Surrogate MLIP", "tx1-v2 (5x)", Colors.cyanAccent),
          Container(width: 1, height: 28, color: Colors.white10),
          _statusPill(Icons.bolt, "Barrier Accuracy", "2.26 kcal/mol", Colors.greenAccent),
          Container(width: 1, height: 28, color: Colors.white10),
          _statusPill(Icons.shield_outlined, "Calibrated Error", "±1σ & ±2σ", Colors.purpleAccent),
          Container(width: 1, height: 28, color: Colors.white10),
          _statusPill(Icons.cloud_done_outlined, "Backend", "Cloud Run", Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _statusPill(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    );
  }

  Widget _exportButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: Colors.cyanAccent),
      label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFF161B22),
        side: const BorderSide(color: Colors.white12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildArrheniusPlotCard(ReactionWorkspaceViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Arrhenius Reaction Dynamics & Rate Prediction',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Ea = ${vm.activationEnergyEa} ±${vm.eaUncertainty} kcal/mol',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.show_chart, color: Colors.cyanAccent, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Rate Constant: k(T) = ${vm.rateConstant} s⁻¹',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'High-precision Arrhenius plot at T = ${vm.temperature.toStringAsFixed(1)} K',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DesktopTick(temp: '250 K', invT: '4.00'),
                    _DesktopTick(temp: '300 K', invT: '3.33'),
                    _DesktopTick(temp: '350 K', invT: '2.86'),
                    _DesktopTick(temp: '400 K', invT: '2.50'),
                    _DesktopTick(temp: '500 K', invT: '2.00'),
                    _DesktopTick(temp: '600 K', invT: '1.67'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermodynamicsGrid(ReactionWorkspaceViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comprehensive Thermodynamic & Quantum Properties',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.3,
          ),
          itemCount: vm.thermodynamicMetrics.length,
          itemBuilder: (context, i) {
            final m = vm.thermodynamicMetrics[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    m.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        m.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: m.accentColor,
                        ),
                      ),
                      if (m.uncertainty != null)
                        Text(
                          ' ${m.uncertainty}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          m.unit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuantumControlsRail(BuildContext context, ReactionWorkspaceViewModel vm, dynamic palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Colors.cyanAccent, size: 20),
              SizedBox(width: 10),
              Text(
                'Quantum Controls',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _controlField('System Charge', '${vm.systemCharge}'),
          const SizedBox(height: 12),
          _controlField('Spin Multiplicity', vm.spinMultiplicity),
          const SizedBox(height: 12),
          _controlField('MLIP Model', vm.mlipModel),
          const SizedBox(height: 12),
          _controlField('Solvation Model', vm.solvationModel, onTap: () => _selectSolvent(context, vm)),
          const SizedBox(height: 12),
          _controlField('Optimizer', vm.optimizer),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Temperature',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '${vm.temperature.toStringAsFixed(1)} K',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          Slider(
            value: vm.temperature,
            min: 100.0,
            max: 1000.0,
            divisions: 90,
            activeColor: Colors.cyanAccent,
            inactiveColor: Colors.white12,
            onChanged: (val) {
              vm.setTemperature(val);
              try {
                context.read<QuantumSettingsNotifier>().update((q) => q.copyWith(temperatureK: val));
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  Widget _controlField(String label, String value, {VoidCallback? onTap}) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onTap != null ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 16, color: Colors.cyanAccent),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: body,
      );
    }
    return body;
  }

  void _selectSolvent(BuildContext context, ReactionWorkspaceViewModel vm) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Row(
          children: [
            Icon(Icons.water_drop_outlined, color: Colors.cyanAccent, size: 20),
            SizedBox(width: 8),
            Text('Select Solvation Model', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: SolventProperties.all.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (ctx, i) {
              final solvent = SolventProperties.all[i];
              final isSelected = solvent.id == vm.solvationModel;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: const Color(0xFF1F2937),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        solvent.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.cyanAccent : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (solvent.isSolvated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ε = ${solvent.dielectricConstant}',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  solvent.description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                ),
                onTap: () {
                  vm.setSolvationModel(solvent.id);
                  Navigator.pop(dialogCtx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _DesktopTick extends StatelessWidget {
  final String temp;
  final String invT;

  const _DesktopTick({required this.temp, required this.invT});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          temp,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
          ),
        ),
        Text(
          '1000/T: $invT',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
