import 'package:flutter/material.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/views/reaction_workspace_viewmodel.dart';

class MobileExportSheet extends StatelessWidget {
  const MobileExportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReactionWorkspaceViewModel>();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: [
        _exportBtn(
          Icons.file_download_outlined,
          'Export .xyz',
          () => vm.exportFile('xyz'),
        ),
        _exportBtn(
          Icons.folder_zip_outlined,
          'Bundle .zip',
          () => vm.exportFile('zip'),
        ),
        _exportBtn(
          Icons.science_outlined,
          'Trajectory',
          () => vm.exportFile('trajectory'),
        ),
        _exportBtn(
          Icons.cloud_upload_outlined,
          'Save to Cloud',
          () => vm.exportFile('firebase'),
        ),
      ],
    );
  }

  Widget _exportBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: Colors.cyanAccent),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.white70),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFF161B22),
        side: const BorderSide(color: Colors.white12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
