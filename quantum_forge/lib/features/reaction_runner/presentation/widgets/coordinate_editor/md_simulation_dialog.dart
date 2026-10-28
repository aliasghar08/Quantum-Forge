import 'package:flutter/material.dart';
import 'package:quantum_forge/core/widgets/reaction_animation_widget.dart';

/// Modal dialog that renders an active Molecular Dynamics (Hybrid ML/MM)
/// simulation trajectory using the 3D viewer.
class MdSimulationDialog extends StatelessWidget {
  final String pdbUrl;
  final String dcdUrl;
  final int frameCount;

  const MdSimulationDialog({
    super.key,
    required this.pdbUrl,
    required this.dcdUrl,
    required this.frameCount,
  });

  static Future<void> show(
    BuildContext context, {
    required String pdbUrl,
    required String dcdUrl,
    required int frameCount,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => MdSimulationDialog(
        pdbUrl: pdbUrl,
        dcdUrl: dcdUrl,
        frameCount: frameCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A1519),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Run Molecular Dynamics (Hybrid ML/MM)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReactionAnimationWidget(
                trajectoryFrames: const [],
                pdbUrl: pdbUrl,
                dcdUrl: dcdUrl,
                mdFrameCount: frameCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
