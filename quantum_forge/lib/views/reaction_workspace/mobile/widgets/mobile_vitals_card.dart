import 'package:flutter/material.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import '../../../../viewmodels/reaction_workspace_viewmodel.dart';
import '../../../../core/algorithms/solvent_properties.dart';

class MobileVitalsCard extends StatelessWidget {
  const MobileVitalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReactionWorkspaceViewModel>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Responsive Header (Never Overlaps) ---
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Quantum Parameters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _showConfigurationSheet(context, vm),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Configure',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 14, color: Colors.cyanAccent),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _vitalTile('System Charge', '${vm.systemCharge}'),
              _vitalTile('Multiplicity', vm.spinMultiplicity),
              _vitalTile('MLIP Engine', vm.mlipModel),
              _vitalTile('Solvation', vm.solvationModel),
              _vitalTile('Temperature', '${vm.temperature.toStringAsFixed(1)} K'),
              _vitalTile('Optimizer', vm.optimizer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vitalTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfigurationSheet(BuildContext context, ReactionWorkspaceViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final activeSolvent = SolventProperties.lookup(vm.solvationModel);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Configure Quantum Parameters',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Solvation Model Dropdown
                    const Text(
                      'Solvation Model (Implicit Continuum)',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: SolventProperties.all.any((s) => s.id == vm.solvationModel)
                              ? vm.solvationModel
                              : 'Vacuum',
                          isExpanded: true,
                          dropdownColor: const Color(0xFF161B22),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: SolventProperties.all.map((s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Row(
                                children: [
                                  Icon(
                                    s.isSolvated ? Icons.water_drop_outlined : Icons.air,
                                    size: 14,
                                    color: s.isSolvated ? Colors.cyanAccent : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(s.id, overflow: TextOverflow.ellipsis),
                                  ),
                                  if (s.isSolvated)
                                    Text(
                                      'ε=${s.dielectricConstant}',
                                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              vm.setSolvationModel(val);
                              setSheetState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activeSolvent.description,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                    ),
                    const SizedBox(height: 18),

                    // Temperature Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Temperature (T)',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${vm.temperature.toStringAsFixed(1)} K',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: vm.temperature.clamp(100.0, 1000.0),
                      min: 100,
                      max: 1000,
                      divisions: 90,
                      activeColor: Colors.cyanAccent,
                      inactiveColor: Colors.white12,
                      onChanged: (val) {
                        vm.setTemperature(val);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // MLIP Engine
                    const Text(
                      'Surrogate MLIP Engine',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: vm.mlipModel,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF161B22),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'tx1-v2', child: Text('tx1-v2 (Transformer Rebuilder)')),
                            DropdownMenuItem(value: 'tx1-fastapi', child: Text('tx1-fastapi (FastAPI ASE Bridge)')),
                            DropdownMenuItem(value: 'MACE-MP-0', child: Text('MACE-MP-0 Foundation')),
                            DropdownMenuItem(value: 'CHGNet', child: Text('CHGNet Pretrained')),
                            DropdownMenuItem(value: 'GFN2-xTB', child: Text('GFN2-xTB Semiempirical')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              vm.setMlipModel(val);
                              setSheetState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
