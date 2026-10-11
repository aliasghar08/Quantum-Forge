import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/reaction_workspace_viewmodel.dart';

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
              onTap: () {},
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
              _vitalTile('Temperature', '${vm.temperature} K'),
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
}
